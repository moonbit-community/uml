///|
/// A parser diagnostic independent of a particular diagram family.
pub struct ParseDiagnostic {
  span : SourceSpan
  message : String
} derive(Eq, Debug)

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
