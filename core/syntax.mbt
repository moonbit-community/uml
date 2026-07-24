///|
/// Remove a PlantUML apostrophe comment while preserving apostrophes inside
/// quoted strings.
pub fn strip_line_comment(line : String) -> String {
  match line_without_comment_parser().run(@talc.Input::new(line)) {
    Ok((content, _)) => content.trim().to_owned()
    Err(_) => ""
  }
}

///|
/// Split a PlantUML command into whitespace-delimited words.
pub fn syntax_words(line : String) -> Array[String] {
  match syntax_words_parser().parse(@talc.Input::new(line)) {
    Ok(words) => words
    Err(_) => []
  }
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
  match literal_prefix_parser(needle).run(@talc.Input::new(haystack)) {
    Ok((prefix, _)) => Some(prefix.length())
    Err(_) => None
  }
}

///|
/// Find a literal substring outside double-quoted text.
pub fn find_unquoted_literal(haystack : String, needle : String) -> Int? {
  guard needle.length() > 0 else { return Some(0) }
  match unquoted_literal_prefix_parser(needle).run(@talc.Input::new(haystack)) {
    Ok((prefix, _)) => Some(prefix.length())
    Err(_) => None
  }
}

///|
/// Split on a delimiter outside quoted strings.
pub fn split_unquoted(value : String, delimiter : Char) -> Array[String] {
  match split_unquoted_parser(delimiter).parse(@talc.Input::new(value)) {
    Ok(parts) => parts
    Err(_) => [value]
  }
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
