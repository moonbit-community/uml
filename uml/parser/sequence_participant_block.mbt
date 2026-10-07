///|
fn ParseCtx::consume_participant_block(
  self : ParseCtx,
  line : String,
) -> Bool raise @tokenizer.ParseError {
  let line = line.trim().to_owned()
  guard line.to_lower().has_prefix("participant ") && line.has_suffix("[") else {
    return false
  }
  let cursor = @tokenizer.Cursor::new(
    line[:line.length() - 1].trim_end().to_owned(),
  )
  guard participant_declaration_line_syntax(cursor) is Some(declaration) else {
    return false
  }
  self.source.skip_line()
  let lines : Array[String] = []
  while !self.source.is_eof() {
    let text = self.source.take_line()
    if text.trim().has_suffix("]") {
      let display = state_note_block_text(lines)
      self.declare_participant({
        ..declaration,
        reference: { ..declaration.reference, display, },
        // CommandParticipantMultilines accepts the background token but
        // does not apply it to the declared participant.
        color: None,
      })
      return true
    }
    lines.push(text)
  }
  raise SyntaxError(
    self.source.diagnostic("").line_number(),
    "unclosed participant",
  )
}
