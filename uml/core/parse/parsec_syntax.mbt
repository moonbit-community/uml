///|
/// One character inside a double-quoted PlantUML value: a backslash-escaped
/// pair kept verbatim, or any character that is not a closing quote.
fn quoted_character_parser() -> @talc.StringParser[String] {
  @talc.char('\\')
  .then(@talc.satisfy("escaped quoted character", _ => true))
  .map(char => "\\" + char.to_string())
  .or(@talc.none_of("\"").string_map(char => char.to_string()))
}

///|
/// Parse a quoted PlantUML value and return its unquoted content.
pub fn quoted_value_parser() -> @talc.StringParser[String] {
  @talc.char('"')
  .then(quoted_character_parser().many().map(parts => parts.join("")))
  .skip(@talc.char('"'))
}

///|
/// Parse a PlantUML stereotype value, including the surrounding markers.
pub fn stereotype_value_parser() -> @talc.StringParser[String] {
  let terminator = @talc.string(">>")
  let character = terminator
    .not_followed_by("stereotype terminator")
    .then(@talc.satisfy("stereotype character", _ => true))
  @talc.string("<<")
  .then(@talc.many_chars(character))
  .skip(terminator)
  .map(value => "<<" + value + ">>")
}

///|
/// Parse a PlantUML URL token and return the target URL.
pub fn url_value_parser() -> @talc.StringParser[String] {
  let terminator = @talc.string("]]")
  let character = terminator
    .not_followed_by("URL terminator")
    .then(@talc.satisfy("URL character", _ => true))
  @talc.string("[[")
  .then(@talc.many_chars(character))
  .skip(terminator)
  .bind(content => {
    match parse_url_target("[[" + content + "]]") {
      Some(target) => @talc.pure(target.target)
      None => @talc.fail("URL")
    }
  })
}

///|
pub fn color_token_parser(label : String) -> @talc.StringParser[String] {
  @talc.many_chars1(@talc.satisfy(label, char => !char.is_whitespace()))
}

///|
pub fn color_value_parser(label : String) -> @talc.StringParser[String] {
  @talc.char('#').then(color_token_parser(label))
}

///|
pub fn tag_value_parser(label : String) -> @talc.StringParser[String] {
  @talc.char('$').then(
    @talc.many_chars1(@talc.satisfy(label, char => !char.is_whitespace())),
  )
}
