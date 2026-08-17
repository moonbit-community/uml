///|
/// Compare every uml-rendered SVG against its PlantUML reference with the
/// svgdiff visual-semantic engine and write one report per run.
///
/// With no arguments, every `live/public/examples/<diagram>/<fixture>.uml`
/// is analyzed. Arguments may name individual `.uml` fixtures or diagram
/// directories. A fixture is skipped when no `puml/<fixture>.svg` reference
/// exists next to it.
///
/// The report is written to `--output <file>` when given, and otherwise to
/// `profiles/uml-vs-plantuml.md` (or `.json` with `--json`). `--json` writes
/// the canonical structured report JSON instead of Markdown.
let examples_root : String = "live/public/examples"

///|
enum Outcome {
  Analyzed
  Skipped
  Failed(String)
}

///|
fn main {
  let matches = @argparse.parse(
    uml_profile_command(),
    argv=@env.args()[1:],
    env=Map([]),
  ) catch {
    err => {
      println(err)
      @sys.exit(2)
      abort("usage error")
    }
  }
  let requested = matches.values.get("fixtures").unwrap_or([])
  let fixtures = if requested.is_empty() {
    discover_fixtures(examples_root)
  } else {
    requested.map(expand_fixture).flatten()
  }
  let report = StringBuilder()
  let mut analyzed = 0
  let mut skipped = 0
  let mut failed = 0
  for fixture in fixtures {
    match compare_fixture(
      fixture,
      json=matches.flags.get("json").unwrap_or(false),
      report,
    ) {
      Analyzed => analyzed += 1
      Skipped => skipped += 1
      Failed(message) => {
        failed += 1
        report.write_string("error: \{fixture}: \{message}\n")
      }
    }
  }
  report.write_string("\n")
  report.write_string(summary_line(analyzed, skipped, failed))
  report.write_string("\n")
  let output = match matches.values.get("output") {
    Some([path]) => path
    _ => {
      ignore(@fs.create_dir("profiles") catch { _ => () })
      default_output_path(json=matches.flags.get("json").unwrap_or(false))
    }
  }
  @fs.write_string_to_file(output, report.to_string()) catch {
    IOError(message) => {
      println("error: failed to write \{output}: \{message}")
      @sys.exit(1)
    }
  }
  println(summary_line(analyzed, skipped, failed))
  println("report written to \{output}")
  @sys.exit(if failed > 0 { 1 } else { 0 })
}

///|
fn uml_profile_command() -> @argparse.Command {
  Command(
    "uml_profile",
    about="Compare uml-rendered SVGs against their PlantUML references.",
    positionals=[
      PositionArg(
        "fixtures",
        about=".uml fixture paths or diagram directories.",
        num_args=@argparse.ValueRange(lower=0),
      ),
    ],
    options=[
      OptionArg(
        "output",
        short='o',
        long="output",
        about="Write the report to this file.",
      ),
    ],
    flags=[
      FlagArg(
        "json",
        long="json",
        about="Write the canonical structured report JSON instead of Markdown.",
        action=@argparse.FlagAction::SetTrue,
      ),
    ],
  )
}

///|
fn summary_line(analyzed : Int, skipped : Int, failed : Int) -> String {
  "profile summary: \{analyzed} analyzed, \{skipped} skipped (missing plantuml reference), \{failed} failed"
}

///|
fn default_output_path(json~ : Bool) -> String {
  if json {
    "profiles/uml-vs-plantuml.json"
  } else {
    "profiles/uml-vs-plantuml.md"
  }
}

///|
fn discover_fixtures(root : String) -> Array[String] {
  let categories = @fs.read_dir(root) catch { _ => return [] }
  let fixtures = categories
    .filter(category => !category.has_prefix("."))
    .map(category => uml_files_in("\{root}/\{category}"))
    .flatten()
  fixtures.sort_by(fn(left, right) { left.compare(right) })
  fixtures
}

///|
/// Expand a `.uml` fixture path, or every `.uml` file inside a directory.
fn expand_fixture(path : String) -> Array[String] {
  let is_dir = @fs.is_dir(path) catch { _ => false }
  if is_dir {
    uml_files_in(path)
  } else {
    [path]
  }
}

///|
fn uml_files_in(dir : String) -> Array[String] {
  let files = @fs.read_dir(dir) catch { _ => return [] }
  files
  .filter(file => file.has_suffix(".uml"))
  .map(file => "\{dir}/\{file}")
}

///|
fn compare_fixture(
  fixture : String,
  json~ : Bool,
  sink : StringBuilder,
) -> Outcome {
  let source = @fs.read_file_to_string(fixture) catch {
    IOError(message) => return Failed("read: \{message}")
  }
  let uml_svg = @api.render_svg(source) catch {
    err => return Failed("render: \{err}")
  }
  let reference = reference_path_of(fixture)
  if !@fs.path_exists(reference) {
    return Skipped
  }
  let puml_svg = @fs.read_file_to_string(reference) catch {
    IOError(message) => return Failed("reference \{reference}: \{message}")
  }
  let report = @svgdiff.compare(
    uml_svg,
    puml_svg,
    comparison_profile(uml_svg, puml_svg),
  )
  if json {
    sink.write_string(report.to_compact_json_string())
    sink.write_string("\n")
  } else {
    sink.write_string("\n## \{fixture}  vs  \{reference}\n")
    sink.write_string(@svgdiff.render_markdown_summary(report))
    sink.write_string("\n")
  }
  Analyzed
}

///|
/// The reference SVG lives in the `puml/` directory next to the fixture.
fn reference_path_of(fixture : String) -> String {
  let slash = fixture.rev_find("/").unwrap_or(-1)
  let dir = if slash >= 0 { fixture[:slash] } else { "." }
  let base = fixture[slash + 1 :].to_owned()
  let name = if base.has_suffix(".uml") {
    base[:base.length() - 4]
  } else {
    base
  }
  "\{dir}/puml/\{name}.svg"
}

///|
/// Render both sides into one viewport sized for the larger canvas so that
/// neither side is shrunk below its natural extent.
fn comparison_profile(
  before : String,
  after : String,
) -> @svgdiff.ComparisonProfile {
  let default = @svgdiff.ComparisonProfile::v1_default()
  match viewport_dimensions(before, after) {
    Some((width, height)) =>
      { ..default, viewport_width: width, viewport_height: height }
    None => default
  }
}

///|
fn viewport_dimensions(before : String, after : String) -> (Int, Int)? {
  match (svg_dimensions(before), svg_dimensions(after)) {
    (Some((width1, height1)), Some((width2, height2))) =>
      Some((width1.max(width2), height1.max(height2)))
    (Some(dims), None) => Some(dims)
    (None, Some(dims)) => Some(dims)
    (None, None) => None
  }
}

///|
/// Prefer the drawing region (`viewBox`) and fall back to `width`/`height`.
fn svg_dimensions(svg : String) -> (Int, Int)? {
  match attr_value(svg, "viewBox") {
    Some(value) if viewbox_dimensions(value) is Some(dims) => return Some(dims)
    _ => ()
  }
  match (attr_value(svg, "width"), attr_value(svg, "height")) {
    (Some(width), Some(height)) =>
      match (parse_dimension(width), parse_dimension(height)) {
        (Some(width), Some(height)) => Some((width, height))
        _ => None
      }
    _ => None
  }
}

///|
/// The root element always opens before any child, so the first occurrence of
/// the attribute on the whole document is the root attribute.
fn attr_value(source : String, name : String) -> String? {
  let spaced = " \{name}=\""
  let offset = match @parse.find_literal(source, spaced) {
    Some(offset) => offset
    None =>
      match @parse.find_literal(source, "<svg \{name}=\"") {
        Some(offset) => offset
        None => return None
      }
  }
  let value_start = offset + spaced.length()
  let rest = source[value_start:].to_owned()
  match @parse.find_literal(rest, "\"") {
    Some(end) => Some(rest[:end].to_owned())
    None => None
  }
}

///|
fn viewbox_dimensions(value : String) -> (Int, Int)? {
  let words = @parse.syntax_words(value)
  guard words.length() == 4 else { return None }
  match (parse_dimension(words[2]), parse_dimension(words[3])) {
    (Some(width), Some(height)) => Some((width, height))
    _ => None
  }
}

///|
/// Parse the leading integer of an SVG length such as `189` or `173px`.
fn parse_dimension(value : String) -> Int? {
  let digits = StringBuilder()
  for index in 0..<value.length() {
    let char = value[index].unsafe_to_char()
    if char.is_ascii_digit() {
      digits.write_char(char)
    } else if digits.is_empty() {
      continue
    } else {
      break
    }
  }
  guard !digits.is_empty() else { return None }
  let parsed = @string.parse_int(digits.to_string()) catch { _ => return None }
  Some(parsed)
}
