///|
/// A syntax or sequence-diagram semantic error reported at a source line.
pub suberror ParseError {
  SyntaxError(Int, String)
} derive(Debug)
