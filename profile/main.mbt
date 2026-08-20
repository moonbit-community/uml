///|
/// Compare every uml-rendered SVG against its PlantUML reference with the
/// svgdiff visual-semantic engine and write one interactive HTML report per
/// fixture plus an index page.
///
/// With no arguments, every `live/public/examples/<diagram>/<fixture>.uml`
/// is analyzed. Arguments may name individual `.uml` fixtures or diagram
/// directories. A fixture is skipped when no `puml/<fixture>.svg` reference
/// exists next to it.
///
/// Reports are written under `--output <dir>` when given, and otherwise to
/// `profiles/uml-vs-plantuml/`. One JSON summary per diagram category is
/// written next to the HTML reports as `<report_dir>/<category>/<category>.json`.
let examples_root : String = "live/public/examples"

///|
enum Outcome {
  /// The comparison succeeded; the second component is the svgdiff report.
  Analyzed(String, @svgdiff.StructuredReport)
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
  let analyzed : Array[(String, String)] = []
  let results : Array[(String, Outcome)] = []
  let mut skipped = 0
  let mut failed = 0
  for fixture in fixtures {
    let outcome = compare_fixture(fixture)
    match outcome {
      Analyzed(html, _) => analyzed.push((fixture, html))
      Skipped => skipped += 1
      Failed(message) => {
        failed += 1
        println("error: \{fixture}: \{message}")
      }
    }
    results.push((fixture, outcome))
  }
  let report_dir = match matches.values.get("output") {
    Some([path]) => path
    _ => {
      ignore(@fs.create_dir("profiles") catch { _ => () })
      default_output_path()
    }
  }
  ignore(@fs.create_dir(report_dir) catch { _ => () })
  for pair in analyzed {
    let (fixture, html) = pair
    let path = html_path_of(report_dir, fixture)
    let slash = path.rev_find("/").unwrap_or(-1)
    if slash >= 0 {
      ignore(@fs.create_dir(path[:slash].to_owned()) catch { _ => () })
    }
    @fs.write_string_to_file(path, html) catch {
      IOError(message) => {
        println("error: failed to write \{path}: \{message}")
        @sys.exit(1)
      }
    }
  }
  let index = index_page(
    analyzed.map(pair => {
      let page = html_path_of(report_dir, pair.0)
      page[report_dir.length() + 1:].to_owned()
    }),
  )
  @fs.write_string_to_file("\{report_dir}/index.html", index) catch {
    IOError(message) => {
      println("error: failed to write \{report_dir}/index.html: \{message}")
      @sys.exit(1)
    }
  }
  write_json_summaries(report_dir, results)
  println(summary_line(analyzed.length(), skipped, failed))
  println("reports written to \{report_dir}/")
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
        about="Write the report directory to this path.",
      ),
    ],
  )
}

///|
fn summary_line(analyzed : Int, skipped : Int, failed : Int) -> String {
  "profile summary: \{analyzed} analyzed, \{skipped} skipped (missing plantuml reference), \{failed} failed"
}

///|
fn default_output_path() -> String {
  "profiles/uml-vs-plantuml"
}

///|
fn html_path_of(report_dir : String, fixture : String) -> String {
  let prefix = examples_root + "/"
  let relative = if fixture.has_prefix(prefix) {
    fixture[prefix.length():]
  } else {
    let slash = fixture.rev_find("/").unwrap_or(-1)
    fixture[slash + 1:]
  }
  "\{report_dir}/\{relative[:relative.length() - 4]}.html"
}

///|
fn index_page(pages : Array[String]) -> String {
  let categories : Array[String] = []
  let groups : Map[String, Array[String]] = Map([])
  for page in pages {
    let slash = page.find("/").unwrap_or(-1)
    let category = if slash >= 0 { page[:slash].to_owned() } else { "other" }
    if !categories.contains(category) {
      categories.push(category)
    }
    groups.set(category, groups.get_or_default(category, []) + [page])
  }
  let sections = categories
    .map(category => {
      let hrefs = groups.get_or_default(category, [])
      // String::compare is shortlex (shorter strings sort first); use the
      // lexicographic comparator for filename ordering.
      hrefs.sort_by(fn(left, right) { left.lexical_compare(right) })
      let items = hrefs
        .map(href => {
          let slash = href.rev_find("/").unwrap_or(-1)
          let name = href[slash + 1:href.length() - 5]
          "<li><a href=\"\{href}\">\{name}</a></li>"
        })
        .join("\n")
      "<h2>\{category}</h2>\n<ul>\n\{items}\n</ul>"
    })
    .join("\n")
  let html =
    $|
    $|<!doctype html>
    $|<html lang="en"><head><meta charset="utf-8">
    $|<title>uml vs plantuml</title>
    $|</head><body>
    $|<h1>uml vs plantuml</h1>
    $|\{sections}
    $|</body></html>
  html
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
  files.filter(file => file.has_suffix(".uml")).map(file => "\{dir}/\{file}")
}

///|
fn compare_fixture(fixture : String) -> Outcome {
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
  Analyzed(@svgdiff.render_html_report(uml_svg, puml_svg, report, None), report)
}

///|
/// The reference SVG lives in the `puml/` directory next to the fixture.
fn reference_path_of(fixture : String) -> String {
  let slash = fixture.rev_find("/").unwrap_or(-1)
  let dir = if slash >= 0 { fixture[:slash] } else { "." }
  let base = fixture[slash + 1:].to_owned()
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

///|
/// One fixture inside a category summary.
struct FixtureSummary {
  fixture : String
  status : String
  error : String?
  analysis_status : String?
  atomic_difference_count : Int?
  event_count : Int?
  diagnostic_count : Int?
  canvas_status : String?
  impact_status : String?
} derive(ToJson)

///|
struct CategorySummary {
  category : String
  analyzed : Int
  matched : Int
  inconclusive : Int
  differ : Int
  failed : Int
  skipped : Int
  fixtures : Array[FixtureSummary]
} derive(ToJson)

///|
/// Write one JSON file per diagram category into the report directory,
/// mirroring the HTML report layout: `<dir>/<category>/<category>.json`.
fn write_json_summaries(
  dir : String,
  results : Array[(String, Outcome)],
) -> Unit {
  for summary in category_summaries(results) {
    let path = "\{dir}/\{summary.category}/\{summary.category}.json"
    let slash = path.rev_find("/").unwrap_or(-1)
    if slash >= 0 {
      ignore(@fs.create_dir(path[:slash].to_owned()) catch { _ => () })
    }
    @fs.write_string_to_file(path, ToJson::to_json(summary).stringify(indent=2)) catch {
      IOError(message) => {
        println("error: failed to write \{path}: \{message}")
        @sys.exit(1)
      }
    }
    println("json report written to \{path}")
  }
}

///|
/// Group every fixture by diagram category and summarize each group.
fn category_summaries(
  results : Array[(String, Outcome)],
) -> Array[CategorySummary] {
  let categories : Array[String] = []
  let groups : Map[String, Array[(String, Outcome)]] = Map([])
  for pair in results {
    let (fixture, _) = pair
    let category = fixture_category(fixture)
    if !categories.contains(category) {
      categories.push(category)
    }
    groups.set(category, groups.get_or_default(category, []) + [pair])
  }
  categories.sort_by(fn(left, right) { left.lexical_compare(right) })
  categories.map(category => {
    let entries = groups.get_or_default(category, [])
    let counts = status_counts(entries)
    CategorySummary::{
      category,
      analyzed: counts.get_or_default("analyzed", 0),
      matched: counts.get_or_default("matched", 0),
      inconclusive: counts.get_or_default("inconclusive", 0),
      differ: counts.get_or_default("differ", 0),
      failed: counts.get_or_default("failed", 0),
      skipped: counts.get_or_default("skipped", 0),
      fixtures: entries.map(pair => fixture_summary(pair.0, pair.1)),
    }
  })
}

///|
fn status_counts(entries : Array[(String, Outcome)]) -> Map[String, Int] {
  let counts : Map[String, Int] = Map([])
  for pair in entries {
    let key = outcome_status(pair.1)
    counts.set(key, counts.get_or_default(key, 0) + 1)
    counts.set("analyzed", counts.get_or_default("analyzed", 0) + 1)
  }
  counts
}

///|
fn fixture_summary(fixture : String, outcome : Outcome) -> FixtureSummary {
  let name = relative_fixture(fixture)
  match outcome {
    Skipped =>
      FixtureSummary::{
        fixture: name,
        status: "skipped",
        error: None,
        analysis_status: None,
        atomic_difference_count: None,
        event_count: None,
        diagnostic_count: None,
        canvas_status: None,
        impact_status: None,
      }
    Failed(message) =>
      FixtureSummary::{
        fixture: name,
        status: "failed",
        error: Some(message),
        analysis_status: None,
        atomic_difference_count: None,
        event_count: None,
        diagnostic_count: None,
        canvas_status: None,
        impact_status: None,
      }
    Analyzed(_, report) =>
      FixtureSummary::{
        fixture: name,
        status: summary_status(report),
        error: None,
        analysis_status: Some(report.analysis_status),
        atomic_difference_count: Some(report.atomic_differences.length()),
        event_count: Some(report.events.length()),
        diagnostic_count: Some(report.diagnostics.length()),
        canvas_status: Some(report.canvas_outcome.status),
        impact_status: Some(report.impact_assessment.status),
      }
  }
}

///|
/// A fixture matches when svgdiff found no atomic differences under a complete
/// analysis; an empty difference list under partial analysis is inconclusive.
fn summary_status(report : @svgdiff.StructuredReport) -> String {
  if report.atomic_differences.is_empty() &&
    report.analysis_status == "complete" {
    "matched"
  } else if report.atomic_differences.is_empty() {
    "inconclusive"
  } else {
    "differ"
  }
}

///|
fn outcome_status(outcome : Outcome) -> String {
  match outcome {
    Skipped => "skipped"
    Failed(_) => "failed"
    Analyzed(_, report) => summary_status(report)
  }
}

///|
fn relative_fixture(fixture : String) -> String {
  let prefix = examples_root + "/"
  if fixture.has_prefix(prefix) {
    fixture[prefix.length():].to_owned()
  } else {
    let slash = fixture.rev_find("/").unwrap_or(-1)
    fixture[slash + 1:].to_owned()
  }
}

///|
/// The diagram category is the first path component under the examples root.
fn fixture_category(fixture : String) -> String {
  let relative = relative_fixture(fixture)
  match relative.find("/") {
    Some(slash) => relative[:slash].to_owned()
    None => "other"
  }
}
