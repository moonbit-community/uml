///|
const QUOTED_CONTENT = re"([^\"\\]|\\.)*"

///|
/// A missing closing quote also accepts a final, unpaired backslash.
const QUOTED_FRAGMENT : Regex = re"\"" + QUOTED_CONTENT + re"(\"|\\?$)"

///|
const URL_TERMINATOR = re"\]\]"

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
/// Consumes exactly one inline whitespace character.
///
/// Distinct from `skip_inline_space1`, which consumes one or more: parsers
/// that need PlantUML's exact `\s` semantics (one whitespace character, for
/// example around multicast ` & name` separators) must call this helper
/// rather than the skip variant, and should not re-implement it locally.
pub fn Cursor::consume_inline_space1(self : Cursor) -> Bool {
  if self.peek() is Some(char) && (char == ' ' || char == '\t' || char == '\r') {
    ignore(self.advance())
    true
  } else {
    false
  }
}

///|
/// Consumes a double-quoted syntax fragment, preserving its quotes and escape
/// sequences. An unclosed quote consumes the remaining input.
pub fn Cursor::take_quoted_text(self : Cursor) -> String? {
  lexmatch self.remaining_view() {
    ((re"^" + QUOTED_FRAGMENT) as quoted, after=_) => {
      self.offset += quoted.char_length()
      Some(quoted.to_owned())
    }
    _ => None
  }
}

///|
/// Consumes a double-quoted value, returning its unquoted content. Unlike
/// `take_quoted_text`, requires a closing quote: an unclosed fragment
/// consumes nothing and restores the original position.
pub fn Cursor::take_quoted_value(self : Cursor) -> String? {
  lexmatch self.remaining_view() {
    ((re"^\"" + (QUOTED_CONTENT as content) + re"\"") as quoted, after=_) => {
      self.offset += quoted.char_length()
      Some(content.to_owned())
    }
    _ => None
  }
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
  lexmatch self.remaining_view() {
    (re"^<<.*?>>" as value, after=_) => {
      self.offset += value.char_length()
      Some(value.to_owned())
    }
    _ => None
  }
}

///|
/// Consumes a `[[...]]` URL value and returns the validated target. An
/// unclosed or invalid fragment consumes nothing and restores the original
/// position.
pub fn Cursor::take_url_value(self : Cursor) -> String? {
  lexmatch self.remaining_view() {
    ((re"^\[\[.*?" + URL_TERMINATOR) as value, after=_) => {
      guard parse_url_target(value.to_owned()) is Some(target) else {
        return None
      }
      self.offset += value.char_length()
      Some(target.target)
    }
    _ => None
  }
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
  self.attempt(self => {
    guard self.consume('#') else { return None }
    self.take_color_token()
  })
}

///|
/// Consumes a `$`-prefixed tag value, returning the token without the
/// marker. Restores the original position when no token follows the marker.
pub fn Cursor::take_tag_value(self : Cursor) -> String? {
  self.attempt(self => {
    guard self.consume('$') else { return None }
    self.take_color_token()
  })
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
