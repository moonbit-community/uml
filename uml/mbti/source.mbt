///|
/// The PlantUML comment marker that selects the mbti diagram family.
const MBTI_MARKER : String = ".mbti"

///|
/// Returns whether any source line opens the mbti diagram family:
/// `@startuml '.mbti`.
pub fn is_mbti_source(input : String) -> Bool {
  input.split("\n").any(line => has_mbti_marker(line.to_owned()))
}

///|
/// Extract the source between the `@startuml '.mbti` and `@enduml` lines,
/// verbatim. Returns the body and the 1-based source line where it begins so
/// mbti parser diagnostics can be mapped back to the original source.
fn mbti_body(input : String) -> (String, Int)? {
  let lines = input.split("\n").map(StringView::to_owned).to_array()
  let mut start_line = -1
  let mut end_line = lines.length()
  for i, line in lines {
    if start_line < 0 {
      if has_mbti_marker(line) {
        start_line = i
      }
    } else if line.trim().equal_ignore_ascii_case("@enduml") {
      end_line = i
      break
    }
  }
  guard start_line >= 0 else { return None }
  Some((lines[start_line + 1:end_line].join("\n"), start_line + 2))
}

///|
/// Whether a line is the `@startuml '.mbti` header, where `.mbti` is written
/// in a PlantUML apostrophe comment so real PlantUML ignores the marker.
fn has_mbti_marker(line : String) -> Bool {
  let trimmed = line.trim()
  guard trimmed.to_lower().has_prefix("@startuml") else { return false }
  let rest = trimmed[9:].trim().to_owned()
  guard rest.has_prefix("'") else { return false }
  rest[1:].trim() == MBTI_MARKER
}

///|
/// Parse a `@startuml '.mbti` source with the MoonBit .mbti parser and adapt
/// the resulting interface declarations to the shared entity graph.
///
/// Aliases of types declared in the interface merge into the target node.
/// Aliases of undeclared targets are dropped unless `standalone_alias` is
/// set, which keeps a fallback node for them.
///
/// `options` controls which structural connections become graph relations.
pub fn parse(
  input : String,
  standalone_alias? : Bool = false,
  options? : MbtiOptions = MbtiOptions::default(),
) -> MbtiDiagram raise @parse.ParseError {
  match mbti_body(input) {
    None => raise @parse.SyntaxError(1, "expected @startuml '.mbti")
    Some((body, body_line)) => {
      let (mbti, reports) = @mbti_parser.parse_string(body, name="<uml>.mbti")
      match reports {
        [report, ..] =>
          raise @parse.SyntaxError(
            report.loc.start.lnum + body_line - 1,
            report.msg,
          )
        _ => adapt(mbti, standalone_alias, options)
      }
    }
  }
}
