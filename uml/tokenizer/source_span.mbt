///|
/// A source position shared by all diagram parsers.
pub struct SourceSpan {
  offset : Int32
  line : Int32
  column : Int32
} derive(Eq, Debug)

///|
pub extend SourceSpan with Eq::{not_equal, equal}

///|
pub extend SourceSpan with Debug::{to_repr}

///|
pub fn source_span(chars : Array[Char], offset : Int32) -> SourceSpan {
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
  { offset: limit, line, column, }
}

///|
pub fn line_span(line : Int32) -> SourceSpan {
  { offset: 0, line: line.max(1), column: 1, }
}
