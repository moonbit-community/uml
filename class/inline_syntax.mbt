///|
fn inline_spaces() -> @talc.StringParser[Unit] {
  @talc.satisfy("inline whitespace", char => {
    char == ' ' || char == '\t' || char == '\r'
  })
  .many()
  .map(_ => ())
}

///|
fn inline_space1() -> @talc.StringParser[Unit] {
  @talc.satisfy("inline whitespace", char => {
    char == ' ' || char == '\t' || char == '\r'
  })
  .some()
  .map(_ => ())
}

///|
fn inline_word_parser(label : String) -> @talc.StringParser[String] {
  @talc.many_chars1(
    @talc.satisfy(label, char => {
      char.is_ascii_alphabetic() || char == '_' || char == '/'
    }),
  )
}

///|
fn inline_keyword_parser(keyword : String) -> @talc.StringParser[Unit] {
  inline_word_parser(keyword).bind(word => {
    if word.equal_ignore_ascii_case(keyword) {
      @talc.pure(())
    } else {
      @talc.fail(keyword)
    }
  })
}

///|
fn quoted_value_parser() -> @talc.StringParser[String] {
  let part = @talc.char('\\')
    .then(@talc.satisfy("escaped quoted character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talc.none_of("\"").string_map(char => char.to_string()))
  @talc.char('"')
  .then(part.many().map(parts => parts.join("")))
  .skip(@talc.char('"'))
}

///|
fn stereotype_value_parser() -> @talc.StringParser[String] {
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
fn url_value_parser() -> @talc.StringParser[String] {
  let terminator = @talc.string("]]")
  let character = terminator
    .not_followed_by("URL terminator")
    .then(@talc.satisfy("URL character", _ => true))
  @talc.string("[[")
  .then(@talc.many_chars(character))
  .skip(terminator)
  .bind(content => {
    match @core.parse_url_target("[[" + content + "]]") {
      Some(target) => @talc.pure(target.target)
      None => @talc.fail("URL")
    }
  })
}

///|
fn color_value_parser(label : String) -> @talc.StringParser[String] {
  @talc.char('#').then(
    @talc.many_chars1(
      @talc.satisfy(label, char => !char.is_whitespace()),
    ),
  )
}

///|
fn tag_value_parser(label : String) -> @talc.StringParser[String] {
  @talc.char('$').then(
    @talc.many_chars1(
      @talc.satisfy(label, char => !char.is_whitespace()),
    ),
  )
}
