///|
priv struct StateDisplay {
  text : String
  alignment : @graphics.TextAnchor?
}

///|
/// Display.getWithNewlines leaves backslashes inside math, latex and URL
/// spans untouched. These markers change its raw mode and remain in the text.
fn state_display_raw_boundary(cursor : @tokenizer.Cursor) -> (String, Bool)? {
  for
    (marker, raw) in [
      ("<math>", true),
      ("<latex>", true),
      ("[[", true),
      ("</math>", false),
      ("</latex>", false),
      ("]]", false),
    ] {
    if cursor.consume_literal(marker) {
      return Some((marker, raw))
    }
  }
  None
}

///|
/// Mirror Display.getWithNewlines at the presentation boundary. The AST keeps
/// source text, so measurement and drawing each decode it exactly once.
/// Previously verified: escaped/physical newlines give equivalent geometry;
/// literal and protected backslashes survive, and natural alignment stays
/// inside the measured title block.
fn state_display(
  text : String,
  literal_newlines? : Bool = false,
) -> StateDisplay {
  if literal_newlines {
    return { text, alignment: None, }
  }
  let cursor = @tokenizer.Cursor::new(text)
  let output = StringBuilder()
  let mut raw = false
  let mut alignment = None
  while !cursor.is_eof() {
    if state_display_raw_boundary(cursor) is Some((marker, mode)) {
      output.write_string(marker)
      raw = mode
      continue
    }
    guard cursor.advance() is Some(char) else { break }
    guard !raw && char == '\\' && cursor.advance() is Some(escaped) else {
      output.write_char(char)
      continue
    }
    match escaped {
      'n' => output.write_char('\n')
      'l' => {
        alignment = Some(@graphics.TextAnchor::Start)
        output.write_char('\n')
      }
      'r' => {
        alignment = Some(@graphics.TextAnchor::End)
        output.write_char('\n')
      }
      't' => output.write_char('\t')
      '\\' => output.write_char('\\')
      _ => {
        output.write_char(char)
        output.write_char(escaped)
      }
    }
  }
  { text: output.to_string(), alignment, }
}

///|
fn state_text_anchor_offset(
  anchor : @graphics.TextAnchor,
  width : Double,
) -> Double {
  match anchor {
    Start => 0.0
    Middle => width / 2.0
    End => width
  }
}

///|
/// Natural line alignment changes the text anchor inside the existing block;
/// it does not move the block from its centered or left-aligned compartment.
fn StateDisplay::anchor_position(
  self : StateDisplay,
  x : Double,
  anchor : @graphics.TextAnchor,
  metrics : @metrics.FontMetrics,
  line_alignment? : @graphics.TextAnchor? = None,
) -> (Double, @graphics.TextAnchor) {
  let alignment = self.alignment.unwrap_or(line_alignment.unwrap_or(anchor))
  guard alignment != anchor else { return (x, anchor) }
  let width = metrics.measure(self.text).width.to_double()
  (
    x -
    state_text_anchor_offset(anchor, width) +
    state_text_anchor_offset(alignment, width),
    alignment,
  )
}
