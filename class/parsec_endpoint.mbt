///|
fn text_before_parser(separator : String) -> @talcparsec.StringParser[String] {
  let quoted = raw_quoted_value_parser()
  let text = @talcparsec.string(separator)
    .not_followed_by("separator")
    .then(@talcparsec.satisfy("text", char => char != '"'))
    .string_map(char => char.to_string())
  quoted
  .attempt()
  .or(text)
  .many()
  .map(parts => parts.join(""))
  .skip(@talcparsec.string(separator))
}
