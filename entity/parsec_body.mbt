///|
fn linked_map_arrow_parser() -> @talc.StringParser[(String, String)] {
  let arrow = @talc.char('*').bind(_ => {
    @talc.many_chars1(@talc.char('-')).bind(dashes => {
      @talc.char('_')
      .optional()
      .bind(underscore => {
        @talc.char('>').map(_ => {
          "*" + dashes + underscore.map_or("", _ => "_") + ">"
        })
      })
    })
  })
  let prefix_character = arrow
    .not_followed_by("map link arrow")
    .then(@talc.satisfy("map entry text", _ => true))
  @talc.many_chars(prefix_character).bind(prefix => {
    arrow.map(arrow => (prefix, arrow))
  })
}

///|
fn brace_delta_parser() -> @talc.StringParser[Int] {
  let quoted_part = @talc.char('\\')
    .then(@talc.satisfy("escaped JSON character", _ => true))
    .or(@talc.none_of("\""))
  let quoted = @talc.char('"')
    .then(quoted_part.many())
    .skip(@talc.char('"').optional())
    .map(_ => 0)
  let token = quoted
    .attempt()
    .or(@talc.char('{').map(_ => 1))
    .or(@talc.char('}').map(_ => -1))
    .or(@talc.satisfy("JSON character", _ => true).map(_ => 0))
  token
  .many()
  .skip(@talc.eof())
  .map(tokens => tokens.fold(init=0, (sum, value) => sum + value))
}

///|
fn parse_brace_delta(line : String) -> Int {
  match brace_delta_parser().parse(@talc.Input::new(line)) {
    Ok(delta) => delta
    Err(_) => 0
  }
}
