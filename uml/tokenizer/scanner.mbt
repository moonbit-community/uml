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
/// Consumes zero or more inline whitespace characters.
pub fn Cursor::skip_inline_spaces(self : Cursor) -> Unit {
  ignore(self.skip_inline_whitespace())
}

///|
/// Consumes one or more inline whitespace characters.
pub fn Cursor::skip_inline_space1(self : Cursor) -> Bool {
  self.skip_inline_whitespace() > 0
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
/// Consumes a double-quoted value, returning its unquoted content. Unlike
/// `take_quoted_text`, requires a closing quote: an unclosed fragment
/// consumes nothing and restores the original position.
pub fn Cursor::take_quoted_value(self : Cursor) -> String? {
  guard self.peek() == Some('"') else { return None }
  let start = self.offset
  ignore(self.advance())
  while self.advance() is Some(char) {
    if char == '\\' {
      ignore(self.advance())
      continue
    }
    if char == '"' {
      return Some(self.slice(start + 1, self.offset - 1))
    }
  }
  ignore(self.restore(start))
  None
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
/// Consumes a `<<...>>` stereotype value, including the markers. An unclosed
/// fragment consumes nothing and restores the original position.
pub fn Cursor::take_stereotype_value(self : Cursor) -> String? {
  let start = self.offset()
  guard self.consume_literal("<<") else { return None }
  while !self.is_eof() && !self.starts_with_literal(">>") {
    ignore(self.advance())
  }
  guard self.consume_literal(">>") else {
    ignore(self.restore(start))
    return None
  }
  Some(self.slice(start, self.offset()))
}

///|
/// Consumes a `[[...]]` URL value and returns the validated target. An
/// unclosed or invalid fragment consumes nothing and restores the original
/// position.
pub fn Cursor::take_url_value(self : Cursor) -> String? {
  let start = self.offset()
  guard self.consume_literal("[[") else { return None }
  let content_start = self.offset()
  while !self.is_eof() && !self.starts_with_literal("]]") {
    ignore(self.advance())
  }
  guard self.consume_literal("]]") else {
    ignore(self.restore(start))
    return None
  }
  let content = self.slice(content_start, self.offset() - 2)
  guard parse_url_target("[[" + content + "]]") is Some(target) else {
    ignore(self.restore(start))
    return None
  }
  Some(target.target)
}

///|
/// Consumes a non-whitespace token, requiring at least one character.
pub fn Cursor::take_color_token(self : Cursor) -> String? {
  let value = self.take_while(char => !char.is_whitespace())
  if value.length() == 0 {
    None
  } else {
    Some(value)
  }
}

///|
/// Consumes a `#`-prefixed color value, returning the token without the
/// marker. Restores the original position when no token follows the marker.
pub fn Cursor::take_color_value(self : Cursor) -> String? {
  let start = self.offset()
  guard self.consume('#') else { return None }
  guard self.take_color_token() is Some(value) else {
    ignore(self.restore(start))
    return None
  }
  Some(value)
}

///|
/// Consumes a `$`-prefixed tag value, returning the token without the
/// marker. Restores the original position when no token follows the marker.
pub fn Cursor::take_tag_value(self : Cursor) -> String? {
  let start = self.offset()
  guard self.consume('$') else { return None }
  guard self.take_color_token() is Some(value) else {
    ignore(self.restore(start))
    return None
  }
  Some(value)
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
