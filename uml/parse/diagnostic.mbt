///|
/// A parser diagnostic independent of a particular diagram family.
pub struct ParseDiagnostic {
  span : SourceSpan
  message : String
} derive(Eq, Debug)

///|
pub extend ParseDiagnostic with Eq::{not_equal, equal}

///|
pub extend ParseDiagnostic with Debug::{to_repr}

///|
/// A syntax or semantic parsing error reported at a source line.
///
/// This is shared by every PlantUML diagram parser so callers can handle
/// malformed source independently of the selected diagram family.
pub(all) suberror ParseError {
  SyntaxError(Int, String)
} derive(Debug)

///|
pub extend ParseError with Debug::{to_repr}

///|
pub fn ParseDiagnostic::line_number(self : ParseDiagnostic) -> Int {
  self.span.line
}

///|
pub fn diagnostic_at_line(line : Int, message : String) -> ParseDiagnostic {
  { span: line_span(line), message }
}

///|
pub fn diagnostic_at_span(
  span : SourceSpan,
  message : String,
) -> ParseDiagnostic {
  { span, message }
}
