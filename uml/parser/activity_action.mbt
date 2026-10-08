///|
/// The first semicolon followed by a complete stereogroup suffix
/// terminates an activity; earlier semicolons remain in its display text.
fn activity_action_tail(value : String) -> String? {
  let cursor = @tokenizer.Cursor::new(value)
  cursor.skip_inline_spaces()
  let labels = StringBuilder()
  while cursor.take_stereotype_value() is Some(label) {
    labels.write_string(label)
    cursor.skip_inline_spaces()
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else { return None }
  let stereotype = labels.to_string()
  Some(stereotype)
}

///|
fn parse_activity_action(
  buffer : LineBuffer,
  style : @style.DocumentStyle,
) -> @flow.ActivityNode raise @tokenizer.ParseError {
  let start = buffer.line_number()
  let cursor = @tokenizer.Cursor::new(buffer.current_clean())
  if cursor.consume('#') {
    ignore(cursor.take_while(char => char != ':' && !char.is_whitespace()))
  }
  cursor.skip_inline_spaces()
  while cursor.take_stereotype_value() is Some(_) {
    cursor.skip_inline_spaces()
  }
  guard cursor.consume(':') else {
    raise SyntaxError(start, "missing activity colon")
  }
  let mut text = cursor.take_rest()
  while !buffer.at_end() {
    let scan = @tokenizer.Cursor::new(text)
    while scan.advance() is Some(char) {
      if char == ';' &&
        activity_action_tail(scan.remaining()) is Some(stereotype) {
        let label = scan.slice(0, scan.offset() - 1).trim().to_owned()
        guard !stereotype.is_empty() else { return @flow.Action(label) }
        return @flow.StyledAction({
          label,
          stereotype: Some(stereotype),
          style,
        })
      }
    }
    buffer.advance()
    guard !buffer.at_end() else { break }
    text += "\n" + buffer.current_stripped()
  }
  raise SyntaxError(start, "unclosed activity")
}
