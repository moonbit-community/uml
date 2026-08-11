///|
/// Remove a PlantUML apostrophe comment while preserving apostrophes inside
/// quoted strings.
pub fn strip_line_comment(line : String) -> String {
  line_without_comment(line).trim().to_owned()
}

///|
/// Remove a PlantUML apostrophe comment while preserving leading indentation.
pub fn strip_line_comment_preserving_indent(line : String) -> String {
  line_without_comment(line).trim_end().to_owned()
}

///|
/// Split a PlantUML command into whitespace-delimited words.
pub fn syntax_words(line : String) -> Array[String] {
  let cursor = Cursor::new(line)
  let words = []
  ignore(cursor.skip_while(Char::is_whitespace))
  while !cursor.is_eof() {
    let word = StringBuilder()
    while cursor.peek() is Some(char) && !char.is_whitespace() {
      match cursor.take_quoted_text() {
        Some(quoted) => word.write_string(quoted)
        None => {
          word.write_char(char)
          ignore(cursor.advance())
        }
      }
    }
    words.push(word.to_string())
    ignore(cursor.skip_while(Char::is_whitespace))
  }
  words
}

///|
/// Remove one pair of double quotes around an identifier or display name.
pub fn unquote_identifier(raw : String) -> String {
  let value = raw.trim()
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value.to_owned()
  }
}

///|
/// Find a literal substring and return its character offset.
pub fn find_literal(haystack : String, needle : String) -> Int? {
  guard needle.length() > 0 else { return Some(0) }
  let cursor = Cursor::new(haystack)
  while !cursor.is_eof() {
    if cursor.starts_with_literal(needle) {
      return Some(cursor.offset())
    }
    ignore(cursor.advance())
  }
  None
}

///|
/// Find a literal substring outside double-quoted text.
pub fn find_unquoted_literal(haystack : String, needle : String) -> Int? {
  guard needle.length() > 0 else { return Some(0) }
  let cursor = Cursor::new(haystack)
  while !cursor.is_eof() {
    if cursor.take_quoted_text() is Some(_) {
      continue
    }
    if cursor.starts_with_literal(needle) {
      return Some(cursor.offset())
    }
    ignore(cursor.advance())
  }
  None
}

///|
/// Split on a delimiter outside quoted strings.
pub fn split_unquoted(value : String, delimiter : Char) -> Array[String] {
  let cursor = Cursor::new(value)
  let parts = []
  let mut start = 0
  while !cursor.is_eof() {
    if cursor.take_quoted_text() is Some(_) {
      continue
    }
    if cursor.consume(delimiter) {
      parts.push(cursor.slice(start, cursor.offset() - 1))
      start = cursor.offset()
      continue
    }
    ignore(cursor.advance())
  }
  parts.push(cursor.slice(start, cursor.length()))
  parts
}

///|
/// Split `name as alias` at the first separator outside quoted identifiers.
pub fn parse_alias_identifier(value : String) -> (String, String)? {
  guard find_unquoted_literal(value, " as ") is Some(index) else { return None }
  let cursor = Cursor::new(value)
  Some((cursor.slice(0, index), cursor.slice(index + 4, cursor.length())))
}

///|
fn line_without_comment(line : String) -> String {
  let cursor = Cursor::new(line)
  while !cursor.is_eof() {
    if cursor.peek() == Some('\'') {
      break
    }
    if cursor.take_quoted_text() is Some(_) {
      continue
    }
    if cursor.take_delimited_text("[[", "]]") is Some(_) {
      continue
    }
    ignore(cursor.advance())
  }
  cursor.slice(0, cursor.offset())
}

///|
/// Return the closing line for a shared PlantUML definition block.
pub fn common_block_terminator(line : String) -> String? {
  let value = line.trim().to_lower()
  if value.has_prefix("sprite ") && value.has_suffix("{") {
    Some("}")
  } else if value == "<style>" {
    Some("</style>")
  } else {
    None
  }
}

///|
/// Parse `set namespaceSeparator ...`; `none` and `null` disable splitting.
pub fn parse_namespace_separator(line : String) -> String?? {
  let words = syntax_words(line)
  guard words.length() == 3 && words[0].equal_ignore_ascii_case("set") else {
    return None
  }
  let key = words[1].to_lower()
  guard key == "namespaceseparator" || key == "namespace_separator" else {
    return None
  }
  let value = words[2]
  if value.equal_ignore_ascii_case("none") ||
    value.equal_ignore_ascii_case("null") {
    Some(None)
  } else {
    Some(Some(value))
  }
}
