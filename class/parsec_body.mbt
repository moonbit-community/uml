///|
fn linked_map_arrow_parser() -> @talcparsec.StringParser[(String, String)] {
  let arrow = @talcparsec.char('*').bind(_ => {
    @talcparsec.many_chars1(@talcparsec.char('-')).bind(dashes => {
      @talcparsec.char('_')
      .optional()
      .bind(underscore => {
        @talcparsec.char('>').map(_ => {
          "*" + dashes + underscore.map_or("", _ => "_") + ">"
        })
      })
    })
  })
  let prefix_character = arrow
    .not_followed_by("map link arrow")
    .then(@talcparsec.satisfy("map entry text", _ => true))
  @talcparsec.many_chars(prefix_character).bind(prefix => {
    arrow.map(arrow => (prefix, arrow))
  })
}

///|
fn brace_delta_parser() -> @talcparsec.StringParser[Int] {
  let quoted_part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped JSON character", _ => true))
    .or(@talcparsec.none_of("\""))
  let quoted = @talcparsec.char('"')
    .then(quoted_part.many())
    .skip(@talcparsec.char('"').optional())
    .map(_ => 0)
  let token = quoted
    .attempt()
    .or(@talcparsec.char('{').map(_ => 1))
    .or(@talcparsec.char('}').map(_ => -1))
    .or(@talcparsec.satisfy("JSON character", _ => true).map(_ => 0))
  token
  .many()
  .skip(@talcparsec.eof())
  .map(tokens => tokens.fold(init=0, (sum, value) => sum + value))
}

///|
fn parse_brace_delta(line : String) -> Int {
  match brace_delta_parser().parse(@talcparsec.Input::new(line)) {
    Ok(delta) => delta
    Err(_) => 0
  }
}
