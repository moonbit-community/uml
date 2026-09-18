///|
/// Previously verified: scale commands validate the entire expression.
fn Parser::consume_state_scale(
  self : Parser,
  line : String,
) -> Bool raise @tokenizer.ParseError {
  let cursor = @tokenizer.Cursor::new(line)
  let keyword = cursor.take_while(char => char.is_ascii_alphabetic())
  guard keyword.equal_ignore_ascii_case("scale") && cursor.skip_inline_space1() else {
    return false
  }
  let value = cursor.remaining().trim().to_owned()
  guard @style.parse_diagram_scale(value) is Some(_) else {
    raise @tokenizer.SyntaxError(self.line_number(), "invalid scale")
  }
  self.apply_state_style(@style.Scale(value))
  true
}
