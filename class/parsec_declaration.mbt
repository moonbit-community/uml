///|
fn generic_content_parser() -> @talcparsec.StringParser[String] {
  let plain = @talcparsec.many_chars1(@talcparsec.none_of("<>"))
  let nested = @talcparsec.char('<')
    .then(@talcparsec.delay(generic_content_parser))
    .skip(@talcparsec.char('>'))
    .map(content => "<" + content + ">")
  nested.attempt().or(plain).many().map(parts => parts.join(""))
}
