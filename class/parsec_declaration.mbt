///|
fn stereotype_split_parser() -> @talcparsec.StringParser[(String, String)] {
  let terminator = @talcparsec.string(">>")
  let content_character = terminator
    .not_followed_by("stereotype terminator")
    .then(@talcparsec.satisfy("stereotype character", _ => true))
  text_before_parser("<<").bind(prefix => {
    @talcparsec.many_chars(content_character)
    .skip(terminator)
    .map(content => (prefix, "<<" + content + ">>"))
  })
}

///|
fn parse_stereotype_split(body : String) -> (String, String)? {
  match stereotype_split_parser().run(@talcparsec.Input::new(body)) {
    Ok((result, _)) => Some(result)
    Err(_) => None
  }
}

///|
fn generic_content_parser() -> @talcparsec.StringParser[String] {
  let plain = @talcparsec.many_chars1(@talcparsec.none_of("<>"))
  let nested = @talcparsec.char('<')
    .then(@talcparsec.delay(generic_content_parser))
    .skip(@talcparsec.char('>'))
    .map(content => "<" + content + ">")
  nested.attempt().or(plain).many().map(parts => parts.join(""))
}
