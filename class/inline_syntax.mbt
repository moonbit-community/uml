///|
fn inline_spaces() -> @talcparsec.StringParser[Unit] {
  @talcparsec.satisfy("inline whitespace", char => {
    char == ' ' || char == '\t' || char == '\r'
  })
  .many()
  .map(_ => ())
}

///|
fn inline_space1() -> @talcparsec.StringParser[Unit] {
  @talcparsec.satisfy("inline whitespace", char => {
    char == ' ' || char == '\t' || char == '\r'
  })
  .some()
  .map(_ => ())
}

///|
fn inline_word_parser(label : String) -> @talcparsec.StringParser[String] {
  @talcparsec.many_chars1(
    @talcparsec.satisfy(label, char => {
      char.is_ascii_alphabetic() || char == '_' || char == '/'
    }),
  )
}

///|
fn inline_keyword_parser(keyword : String) -> @talcparsec.StringParser[Unit] {
  inline_word_parser(keyword).bind(word => {
    if word.equal_ignore_ascii_case(keyword) {
      @talcparsec.pure(())
    } else {
      @talcparsec.fail(keyword)
    }
  })
}

///|
fn quoted_value_parser() -> @talcparsec.StringParser[String] {
  let part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped quoted character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talcparsec.none_of("\"").string_map(char => char.to_string()))
  @talcparsec.char('"')
  .then(part.many().map(parts => parts.join("")))
  .skip(@talcparsec.char('"'))
}

///|
fn stereotype_value_parser() -> @talcparsec.StringParser[String] {
  let terminator = @talcparsec.string(">>")
  let character = terminator
    .not_followed_by("stereotype terminator")
    .then(@talcparsec.satisfy("stereotype character", _ => true))
  @talcparsec.string("<<")
  .then(@talcparsec.many_chars(character))
  .skip(terminator)
  .map(value => "<<" + value + ">>")
}

///|
fn url_value_parser() -> @talcparsec.StringParser[String] {
  let terminator = @talcparsec.string("]]")
  let character = terminator
    .not_followed_by("URL terminator")
    .then(@talcparsec.satisfy("URL character", _ => true))
  @talcparsec.string("[[")
  .then(@talcparsec.many_chars(character))
  .skip(terminator)
  .bind(content => {
    match @core.parse_url_target("[[" + content + "]]") {
      Some(target) => @talcparsec.pure(target.target)
      None => @talcparsec.fail("URL")
    }
  })
}

///|
fn color_value_parser(label : String) -> @talcparsec.StringParser[String] {
  @talcparsec.char('#').then(
    @talcparsec.many_chars1(
      @talcparsec.satisfy(label, char => !char.is_whitespace()),
    ),
  )
}

///|
fn tag_value_parser(label : String) -> @talcparsec.StringParser[String] {
  @talcparsec.char('$').then(
    @talcparsec.many_chars1(
      @talcparsec.satisfy(label, char => !char.is_whitespace()),
    ),
  )
}
