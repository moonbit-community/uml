///|
fn generic_content_parser() -> @talc.StringParser[String] {
  let plain = @talc.many_chars1(@talc.none_of("<>"))
  let nested = @talc.char('<')
    .then(@talc.delay(generic_content_parser))
    .skip(@talc.char('>'))
    .map(content => "<" + content + ">")
  nested.attempt().or(plain).many().map(parts => parts.join(""))
}
