///|
/// Remove a PlantUML apostrophe comment while preserving apostrophes inside
/// quoted strings.
pub fn strip_line_comment(line : String) -> String {
  let mut quoted = false
  let mut in_url = false
  let result = StringBuilder()
  let chars = line.to_array()
  for index in 0..<chars.length() {
    let char = chars[index]
    if char == '"' {
      quoted = !quoted
    }
    if !quoted &&
      index + 1 < chars.length() &&
      char == '[' &&
      chars[index + 1] == '[' {
      in_url = true
    } else if !quoted &&
      in_url &&
      index + 1 < chars.length() &&
      char == ']' &&
      chars[index + 1] == ']' {
      in_url = false
    }
    if char == '\'' && !quoted && !in_url {
      break
    }
    result.write_char(char)
  }
  result.to_string().trim().to_owned()
}

///|
/// Split a PlantUML command into whitespace-delimited words.
pub fn syntax_words(line : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = StringBuilder()
  let mut quoted = false
  let mut escaped = false
  for char in line {
    if escaped {
      current.write_char(char)
      escaped = false
      continue
    }
    if quoted && char == '\\' {
      current.write_char(char)
      escaped = true
      continue
    }
    if char == '"' {
      quoted = !quoted
      current.write_char(char)
    } else if !quoted && char.is_whitespace() {
      if current.to_string().length() > 0 {
        result.push(current.to_string())
        current = StringBuilder()
      }
    } else {
      current.write_char(char)
    }
  }
  if current.to_string().length() > 0 {
    result.push(current.to_string())
  }
  result
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
  let source = haystack.to_array()
  let target = needle.to_array()
  guard target.length() <= source.length() else { return None }
  for start in 0..<(source.length() - target.length() + 1) {
    let mut matches = true
    for offset in 0..<target.length() {
      if source[start + offset] != target[offset] {
        matches = false
        break
      }
    }
    if matches {
      return Some(start)
    }
  }
  None
}

///|
/// Find a literal substring outside double-quoted text.
pub fn find_unquoted_literal(haystack : String, needle : String) -> Int? {
  let source = haystack.to_array()
  let target = needle.to_array()
  guard target.length() <= source.length() else { return None }
  let mut quoted = false
  let mut escaped = false
  for start in 0..<(source.length() - target.length() + 1) {
    if escaped {
      escaped = false
      continue
    }
    if quoted && source[start] == '\\' {
      escaped = true
      continue
    }
    if source[start] == '"' {
      quoted = !quoted
      continue
    }
    guard !quoted else { continue }
    let mut matches = true
    for offset in 0..<target.length() {
      if source[start + offset] != target[offset] {
        matches = false
        break
      }
    }
    if matches {
      return Some(start)
    }
  }
  None
}

///|
/// Split on a delimiter outside quoted strings.
pub fn split_unquoted(value : String, delimiter : Char) -> Array[String] {
  let result : Array[String] = []
  let mut current = StringBuilder()
  let mut quoted = false
  for char in value {
    if char == '"' {
      quoted = !quoted
    }
    if char == delimiter && !quoted {
      result.push(current.to_string())
      current = StringBuilder()
    } else {
      current.write_char(char)
    }
  }
  result.push(current.to_string())
  result
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
