///|
/// Compare every uml-rendered SVG against its PlantUML reference with the
/// svgdiff visual-semantic engine and print one Markdown summary per fixture.
///
/// With no arguments, every `live/public/examples/<diagram>/<fixture>.uml`
/// is analyzed. Arguments may name individual `.uml` fixtures or diagram
/// directories. A fixture is skipped when no `puml/<fixture>.svg` reference
/// exists next to it.
///
/// `--json` prints the canonical structured report JSON instead of Markdown.
let examples_root : String = "live/public/examples"

///|
enum Outcome {
  Analyzed
  Skipped
  Failed(String)
}

///|
fn main {
  let args = @env.args()[1:]
  let json = args.contains("--json")
  let paths = args.filter(fn(path) { path != "--json" })
  let fixtures = if paths.is_empty() {
    discover_fixtures(examples_root)
  } else {
    let fixtures : Array[String] = []
    for path in paths {
      for fixture in expand_fixture(path) {
        fixtures.push(fixture)
      }
    }
    fixtures
  }
  let mut analyzed = 0
  let mut skipped = 0
  let mut failed = 0
  for fixture in fixtures {
    match compare_fixture(fixture, json~) {
      Analyzed => analyzed += 1
      Skipped => skipped += 1
      Failed(message) => {
        failed += 1
        println("error: \{fixture}: \{message}")
      }
    }
  }
  println("")
  println(
    "profile summary: \{analyzed} analyzed, \{skipped} skipped (missing plantuml reference), \{failed} failed",
  )
  @sys.exit(if failed > 0 { 1 } else { 0 })
}

///|
fn discover_fixtures(root : String) -> Array[String] {
  let fixtures : Array[String] = []
  let categories = @fs.read_dir(root) catch { _ => return fixtures }
  for category in categories {
    if category.has_prefix(".") {
      continue
    }
    let dir = "\{root}/\{category}"
    let files = @fs.read_dir(dir) catch { _ => continue }
    for file in files {
      if file.has_suffix(".uml") {
        fixtures.push("\{dir}/\{file}")
      }
    }
  }
  fixtures.sort_by(fn(left, right) { left.compare(right) })
  fixtures
}

///|
fn expand_fixture(path : String) -> Array[String] {
  let is_dir = @fs.is_dir(path) catch { _ => false }
  if is_dir {
    let files = @fs.read_dir(path) catch { _ => [] }
    files
    .filter(fn(file) { file.has_suffix(".uml") })
    .map(fn(file) { "\{path}/\{file}" })
  } else {
    [path]
  }
}

///|
fn compare_fixture(fixture : String, json~ : Bool) -> Outcome {
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
    println(report.to_compact_json_string())
  } else {
    println("")
    println("## \{fixture}  vs  \{reference}")
    println(@svgdiff.render_markdown_summary(report))
  }
  Analyzed
}

///|
/// The reference SVG lives in the `puml/` directory next to the fixture.
fn reference_path_of(fixture : String) -> String {
  let parts = @parse.split_unquoted(fixture, '/')
  let name = parts[parts.length() - 1]
  let base = if name.has_suffix(".uml") {
    name[:name.length() - 4].to_owned()
  } else {
    name
  }
  let dir = parts[:parts.length() - 1].join("/")
  "\{dir}/puml/\{base}.svg"
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
  let before_dims = svg_dimensions(before)
  let after_dims = svg_dimensions(after)
  match (before_dims, after_dims) {
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
    Some(value) =>
      match viewbox_dimensions(value) {
        Some(dims) => return Some(dims)
        None => ()
      }
    None => ()
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
