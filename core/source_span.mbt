///|
/// A source position shared by all diagram parsers.
pub struct SourceSpan {
  offset : Int
  line : Int
  column : Int
} derive(Eq, Debug)

///|
pub fn source_span(chars : Array[Char], offset : Int) -> SourceSpan {
  let limit = offset.min(chars.length())
  let mut line = 1
  let mut column = 1
  for index in 0..<limit {
    if chars[index] == '\n' {
      line += 1
      column = 1
    } else {
      column += 1
    }
  }
  { offset: limit, line, column }
}

///|
pub fn line_span(line : Int) -> SourceSpan {
  { offset: 0, line: line.max(1), column: 1 }
}
