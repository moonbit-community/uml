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
