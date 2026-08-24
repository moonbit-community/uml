///|
/// A mutable character cursor for the hand-written PlantUML parsers.
///
/// The cursor stores character offsets rather than string offsets so callers
/// can inspect and consume Unicode text without duplicating index arithmetic.
pub struct Cursor {
  chars : Array[Char]
  mut offset : Int
}

///|
/// Creates a cursor positioned at the beginning of `input`.
pub fn Cursor::new(input : String) -> Cursor {
  { chars: input.to_array(), offset: 0 }
}

///|
/// Returns the current character offset.
pub fn Cursor::offset(self : Cursor) -> Int {
  self.offset
}

///|
/// Returns the number of characters in the input.
pub fn Cursor::length(self : Cursor) -> Int {
  self.chars.length()
}

///|
/// Returns whether the cursor has consumed the complete input.
pub fn Cursor::is_eof(self : Cursor) -> Bool {
  self.offset >= self.chars.length()
}

///|
/// Returns the current character without consuming it.
pub fn Cursor::peek(self : Cursor) -> Char? {
  self.char_at(self.offset)
}

///|
/// Returns a character at an absolute character offset.
pub fn Cursor::char_at(self : Cursor, offset : Int) -> Char? {
  guard offset >= 0 && offset < self.chars.length() else { return None }
  Some(self.chars[offset])
}

///|
/// Returns a character relative to the current cursor position.
pub fn Cursor::peek_ahead(self : Cursor, distance : Int) -> Char? {
  self.char_at(self.offset + distance)
}

///|
/// Consumes and returns the current character.
pub fn Cursor::advance(self : Cursor) -> Char? {
  guard self.peek() is Some(char) else { return None }
  self.offset += 1
  Some(char)
}

///|
/// Consumes `expected` when it is the current character.
pub fn Cursor::consume(self : Cursor, expected : Char) -> Bool {
  guard self.peek() == Some(expected) else { return false }
  self.offset += 1
  true
}

///|
/// Consumes a literal string when it starts at the current position.
pub fn Cursor::consume_literal(self : Cursor, literal : String) -> Bool {
  let chars = literal.to_array()
  guard self.offset + chars.length() <= self.chars.length() else {
    return false
  }
  for index in 0..<chars.length() {
    guard self.chars[self.offset + index] == chars[index] else { return false }
  }
  self.offset += chars.length()
  true
}

///|
/// Consumes characters while `predicate` accepts them and returns the count.
pub fn Cursor::skip_while(self : Cursor, predicate : (Char) -> Bool) -> Int {
  let start = self.offset
  while self.offset < self.chars.length() && predicate(self.chars[self.offset]) {
    self.offset += 1
  }
  self.offset - start
}

///|
/// Consumes characters while `predicate` accepts them and returns the text.
pub fn Cursor::take_while(self : Cursor, predicate : (Char) -> Bool) -> String {
  let start = self.offset
  ignore(self.skip_while(predicate))
  self.slice(start, self.offset)
}

///|
/// Returns the unconsumed text.
pub fn Cursor::remaining(self : Cursor) -> String {
  self.slice(self.offset, self.chars.length())
}

///|
/// Returns a character slice using absolute character offsets.
pub fn Cursor::slice(self : Cursor, start : Int, end : Int) -> String {
  let first = start.max(0).min(self.chars.length())
  let last = end.max(first).min(self.chars.length())
  let output = StringBuilder()
  for index in first..<last {
    output.write_char(self.chars[index])
  }
  output.to_string()
}

///|
/// Restores a previously saved offset. Returns false for an invalid offset.
pub fn Cursor::restore(self : Cursor, offset : Int) -> Bool {
  guard offset >= 0 && offset <= self.chars.length() else { return false }
  self.offset = offset
  true
}

///|
/// Returns the text from the current position up to, but not including, `\n`.
pub fn Cursor::current_line(self : Cursor) -> String {
  let mut end = self.offset
  while end < self.chars.length() && self.chars[end] != '\n' {
    end += 1
  }
  self.slice(self.offset, end)
}

///|
/// Consumes the current line and its newline, if present.
pub fn Cursor::take_line(self : Cursor) -> String {
  let start = self.offset
  ignore(self.skip_while(char => char != '\n'))
  let line = self.slice(start, self.offset)
  ignore(self.consume('\n'))
  line
}

///|
/// Consumes the current line and discards it.
pub fn Cursor::skip_line(self : Cursor) -> Unit {
  ignore(self.take_line())
}

///|
/// Returns a source span at the current offset.
pub fn Cursor::source_span(self : Cursor) -> SourceSpan {
  source_span(self.chars, self.offset)
}

///|
/// Creates a parser diagnostic at the current cursor position.
pub fn Cursor::diagnostic(self : Cursor, message : String) -> ParseDiagnostic {
  diagnostic_at_span(self.source_span(), message)
}

///|
/// Raises a shared PlantUML parse error at the current cursor position.
pub fn Cursor::raise_parse_error(
  self : Cursor,
  message : String,
) -> Unit raise ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}
