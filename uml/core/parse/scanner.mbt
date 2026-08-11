///|
/// Returns whether `literal` starts at the current cursor position without
/// consuming input.
pub fn Cursor::starts_with_literal(self : Cursor, literal : String) -> Bool {
  let start = self.offset()
  let matched = self.consume_literal(literal)
  ignore(self.restore(start))
  matched
}

///|
/// Consumes inline whitespace without crossing a line boundary.
pub fn Cursor::skip_inline_whitespace(self : Cursor) -> Int {
  self.skip_while(char => char == ' ' || char == '\t' || char == '\r')
}

///|
/// Consumes a double-quoted syntax fragment, preserving its quotes and escape
/// sequences. An unclosed quote consumes the remaining input.
pub fn Cursor::take_quoted_text(self : Cursor) -> String? {
  let start = self.offset()
  guard self.consume('"') else { return None }
  while self.advance() is Some(char) {
    if char == '\\' {
      ignore(self.advance())
      continue
    }
    if char == '"' {
      return Some(self.slice(start, self.offset()))
    }
  }
  Some(self.slice(start, self.offset()))
}

///|
/// Consumes text surrounded by `open` and `close`, preserving the delimiters.
/// An unclosed fragment consumes the remaining input.
pub fn Cursor::take_delimited_text(
  self : Cursor,
  open : String,
  close : String,
) -> String? {
  guard open.length() > 0 && close.length() > 0 else { return None }
  let start = self.offset()
  guard self.consume_literal(open) else { return None }
  while !self.is_eof() {
    if self.consume_literal(close) {
      return Some(self.slice(start, self.offset()))
    }
    ignore(self.advance())
  }
  Some(self.slice(start, self.offset()))
}

///|
/// Counts `open` and `close` characters outside double-quoted text.
pub fn unquoted_delimiter_delta(
  value : String,
  open : Char,
  close : Char,
) -> Int {
  let cursor = Cursor::new(value)
  let mut delta = 0
  while !cursor.is_eof() {
    if cursor.peek() == Some('"') {
      ignore(cursor.take_quoted_text())
      continue
    }
    match cursor.advance() {
      Some(char) if char == open => delta += 1
      Some(char) if char == close => delta -= 1
      _ => ()
    }
  }
  delta
}
