///|
/// Character classes mirroring the PlantUML regex classes used by the timing
/// grammars: `%pL` letters, `%pLN` letters and numbers, `\w` ASCII word chars.

///|
fn is_letter(char : Char) -> Bool {
  @unicode.is_unicode_letter(char)
}

///|
/// `[%pLN_.@]`: letters, numbers, underscore, dot and at-sign.
fn is_code_char(char : Char) -> Bool {
  @unicode.is_identifier_char(char) || char == '.' || char == '@'
}

///|
/// `[%pLN_.@]`: letters, numbers, underscore and dot.
fn is_code_dot_char(char : Char) -> Bool {
  @unicode.is_identifier_char(char) || char == '.'
}

///|
/// `[-%pLN_.@]`: the state literal class of `CommandDefineStateShort`.
fn is_state_decl_char(char : Char) -> Bool {
  char == '-' || is_code_char(char)
}

///|
/// `[\p{L}_]`: the first character of `PLAYER_CODE`.
fn is_player_code_start(char : Char) -> Bool {
  is_letter(char) || char == '_'
}

///|
/// `[%pLN_.]`: continuation characters of `PLAYER_CODE`.
fn is_player_code_char(char : Char) -> Bool {
  is_code_dot_char(char)
}

///|
/// `[-%pLN_]`: the first character of `STATE_CODE`.
fn is_state_code_start(char : Char) -> Bool {
  char == '-' || @unicode.is_identifier_char(char)
}

///|
/// `[-%pLN_.]`: continuation characters of `STATE_CODE`.
fn is_state_code_char(char : Char) -> Bool {
  char == '-' || is_code_dot_char(char)
}

///|
/// `\w`: ASCII letters, digits and underscore.
fn is_word_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_'
}

///|
fn skip_spaces(cursor : @parse.Cursor) -> Unit {
  ignore(cursor.skip_while(char => char.is_whitespace()))
}

///|
fn space_one_or_more(cursor : @parse.Cursor) -> Bool {
  let start = cursor.offset()
  skip_spaces(cursor)
  cursor.offset() > start
}

///|
fn match_literal(cursor : @parse.Cursor, literal : String) -> Bool {
  let chars = literal.to_array()
  guard cursor.offset() + chars.length() <= cursor.length() else {
    return false
  }
  for index in 0..<chars.length() {
    if cursor.char_at(cursor.offset() + index) != Some(chars[index]) {
      return false
    }
  }
  ignore(cursor.restore(cursor.offset() + chars.length()))
  true
}

///|
/// Lowercases an ASCII character, the case folding used by the compiled
/// `Pattern.CASE_INSENSITIVE` regexes.
fn lower_ascii(char : Char) -> Char {
  if char >= 'A' && char <= 'Z' {
    (char.to_int() + 32).to_char().unwrap()
  } else {
    char
  }
}

///|
/// Matches `keyword` case-insensitively, like the compiled PlantUML regexes.
fn match_keyword(cursor : @parse.Cursor, keyword : String) -> Bool {
  let chars = keyword.to_array()
  guard cursor.offset() + chars.length() <= cursor.length() else {
    return false
  }
  for index in 0..<chars.length() {
    let current = cursor.char_at(cursor.offset() + index)
    if current is None ||
      lower_ascii(current.unwrap()) != lower_ascii(chars[index]) {
      return false
    }
  }
  ignore(cursor.restore(cursor.offset() + chars.length()))
  true
}

///|
/// Matches a non-empty double-quoted string and returns its content without
/// the quotes, mirroring `[%g]([^%g]+)[%g]`.
fn parse_quoted(cursor : @parse.Cursor) -> String? {
  guard parse_quoted_any(cursor) is Some(value) && value.length() > 0 else {
    return None
  }
  Some(value)
}

///|
/// Matches a double-quoted string, empty content allowed, mirroring
/// `[%g]([^%g]*)[%g]`.
fn parse_quoted_any(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('"') else { return None }
  let content_start = cursor.offset()
  while !cursor.is_eof() && cursor.peek() != Some('"') {
    ignore(cursor.advance())
  }
  guard cursor.consume('"') else {
    ignore(cursor.restore(start))
    return None
  }
  Some(cursor.slice(content_start, cursor.offset() - 1))
}

///|
/// Matches `<<.+?>>` and returns the whole stereotype text.
fn parse_stereotype(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard match_literal(cursor, "<<") else { return None }
  let content_start = cursor.offset()
  while !cursor.is_eof() &&
        !(cursor.peek() == Some('>') && cursor.peek_ahead(1) == Some('>')) {
    ignore(cursor.advance())
  }
  guard cursor.offset() > content_start && match_literal(cursor, ">>") else {
    ignore(cursor.restore(start))
    return None
  }
  Some(cursor.slice(start, cursor.offset()))
}

///|
/// Tries every `PLAYER_CODE` prefix, longest first, feeding the match to
/// `continue_with`. The retries mirror the greedy regex backtracking when the
/// rest of a line does not fit the longest code.
fn[T] with_player_code(
  cursor : @parse.Cursor,
  continue_with : (String) -> T?,
) -> T? {
  let start = cursor.offset()
  guard cursor.peek() is Some(char) && is_player_code_start(char) else {
    return None
  }
  let mut end = start + 1
  while cursor.char_at(end) is Some(char) && is_player_code_char(char) {
    end += 1
  }
  let mut length = end - start
  while length >= 1 {
    ignore(cursor.restore(start + length))
    if continue_with(cursor.slice(start, start + length)) is Some(result) {
      return Some(result)
    }
    length -= 1
  }
  ignore(cursor.restore(start))
  None
}

///|
/// Tries every `[%pLN_.@]+` prefix, longest first, mirroring the greedy regex
/// backtracking of the declaration code class.
fn[T] with_full_code(
  cursor : @parse.Cursor,
  continue_with : (String) -> T?,
) -> T? {
  let start = cursor.offset()
  let mut end = start
  while cursor.char_at(end) is Some(char) && is_code_char(char) {
    end += 1
  }
  let mut length = end - start
  while length >= 1 {
    ignore(cursor.restore(start + length))
    if continue_with(cursor.slice(start, start + length)) is Some(result) {
      return Some(result)
    }
    length -= 1
  }
  ignore(cursor.restore(start))
  None
}

///|
/// Matches `[-%pLN_][-%pLN_.]*`, the `STATE_CODE` class.
fn parse_state_code(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.peek() is Some(char) && is_state_code_start(char) else {
    return None
  }
  ignore(cursor.advance())
  ignore(cursor.skip_while(is_state_code_char))
  Some(cursor.slice(start, cursor.offset()))
}

///|
/// Tries every alternative of `CommandChangeState.getStateOrHidden` at the
/// current position: quoted state, `STATE_CODE`, `{hidden}`, `{...}`, `{-}`,
/// `{?}` and the `{code,code}` pair. The alternatives are retried when the
/// continuation rejects a match, mirroring the regex backtracking.
fn[T] with_state_spec(
  cursor : @parse.Cursor,
  continue_with : (Array[String]) -> T?,
) -> T? {
  for branch in 0..<7 {
    let checkpoint = cursor.offset()
    let states = match branch {
      0 =>
        match parse_quoted_any(cursor) {
          Some(text) => Some([text])
          None => None
        }
      1 =>
        match parse_state_code(cursor) {
          Some(text) => Some([text])
          None => None
        }
      2 =>
        if match_literal(cursor, "{hidden}") {
          Some(["{hidden}"])
        } else {
          None
        }
      3 => if match_literal(cursor, "{...}") { Some(["{...}"]) } else { None }
      4 => if match_literal(cursor, "{-}") { Some(["{-}"]) } else { None }
      5 => if match_literal(cursor, "{?}") { Some(["{?}"]) } else { None }
      _ =>
        if match_literal(cursor, "{") &&
          parse_state_code(cursor) is Some(first) &&
          match_literal(cursor, ",") &&
          parse_state_code(cursor) is Some(second) &&
          match_literal(cursor, "}") {
          Some([first, second])
        } else {
          None
        }
    }
    if states is Some(value) {
      if continue_with(value) is Some(result) {
        return Some(result)
      }
    }
    ignore(cursor.restore(checkpoint))
  }
  None
}

///|
/// Matches a Java `\w+` run.
fn take_word(cursor : @parse.Cursor) -> String {
  cursor.take_while(is_word_char)
}

///|
/// Matches `\w+[-\\|/]?\w+`, the color payload of the simple color form.
fn take_color_word(cursor : @parse.Cursor) -> String? {
  let first = take_word(cursor)
  guard first.length() > 0 else { return None }
  match cursor.peek() {
    Some(char) if char == '-' || char == '|' || char == '/' => {
      let separator = cursor.offset()
      ignore(cursor.advance())
      let second = take_word(cursor)
      guard second.length() > 0 else {
        ignore(cursor.restore(separator))
        return Some(first)
      }
      Some(first + char.to_string() + second)
    }
    _ => Some(first)
  }
}

///|
/// Matches `#\w+[-\\|/]?\w+`, the simple color form of `COLOR_REGEXP`.
fn match_simple_color(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('#') else { return None }
  guard take_color_word(cursor) is Some(word) else {
    ignore(cursor.restore(start))
    return None
  }
  Some("#" + word)
}

///|
/// Matches the keyword part of the multi-color form of `PART2`.
fn match_color_keyword(cursor : @parse.Cursor) -> String? {
  let keywords = [
    "text", "back", "header", "line", "line.dashed", "line.dotted", "line.bold",
    "shadowing",
  ]
  for keyword in keywords {
    let start = cursor.offset()
    if match_keyword(cursor, keyword) {
      return Some(keyword)
    }
    ignore(cursor.restore(start))
  }
  None
}

///|
/// Matches `#(?:(\w+[-\\|/]?\w+);)?(?:(text|back|header|line|...)(?::(\w+[-\\|/]?\w+))?(?:;|(?![\\w;:.])))+`,
/// the multi-color form of `PART2`.
fn match_multi_color(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('#') else { return None }
  let try_prefix = fn(prefix : Bool) -> Bool {
    if prefix {
      guard take_color_word(cursor) is Some(_) else { return false }
      guard cursor.consume(';') else { return false }
    }
    let mut matched = false
    while match_color_keyword(cursor) is Some(_) {
      matched = true
      if cursor.peek() == Some(':') {
        ignore(cursor.advance())
        guard take_color_word(cursor) is Some(_) else {
          ignore(cursor.restore(start))
          return false
        }
      }
      if cursor.consume(';') {
        continue
      }
      guard cursor.peek() is None ||
        !(is_word_char(cursor.peek().unwrap()) ||
        cursor.peek().unwrap() == ';' ||
        cursor.peek().unwrap() == ':' ||
        cursor.peek().unwrap() == '.') else {
        ignore(cursor.restore(start))
        return false
      }
      break
    }
    matched
  }
  if try_prefix(true) {
    return Some(cursor.slice(start, cursor.offset()))
  }
  ignore(cursor.restore(start + 1))
  guard try_prefix(false) else { return None }
  Some(cursor.slice(start, cursor.offset()))
}

///|
/// Matches a color expression, mirroring `ColorParser.COLORS_REGEXP`: the
/// multi-color form first, then the simple `#\w+[-\\|/]?\w+` form.
fn parse_color(cursor : @parse.Cursor) -> String? {
  let checkpoint = cursor.offset()
  match match_multi_color(cursor) {
    Some(color) => Some(color)
    None => {
      ignore(cursor.restore(checkpoint))
      match_simple_color(cursor)
    }
  }
}

///|
/// Matches `$tag` tokens, mirroring `Stereotag.pattern()`.
fn parse_tags(cursor : @parse.Cursor) -> Bool {
  let start = cursor.offset()
  guard cursor.consume('$') else { return false }
  let first = cursor.take_while(char => {
    !char.is_whitespace() &&
    char != '{' &&
    char != '}' &&
    char != '"' &&
    char != '<' &&
    char != '>' &&
    char != '$'
  })
  guard first.length() > 0 else {
    ignore(cursor.restore(start))
    return false
  }
  let mut matched = true
  while cursor.peek() is Some(char) &&
        char.is_whitespace() &&
        cursor.peek_ahead(1) == Some('$') {
    skip_spaces(cursor)
    ignore(cursor.consume('$'))
    let tag = cursor.take_while(char => {
      !char.is_whitespace() &&
      char != '{' &&
      char != '}' &&
      char != '"' &&
      char != '<' &&
      char != '>' &&
      char != '$'
    })
    guard tag.length() > 0 else {
      ignore(cursor.restore(start))
      return false
    }
    matched = true
  }
  matched
}
