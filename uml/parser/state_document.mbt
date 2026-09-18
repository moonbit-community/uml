///|
/// Preserve the positioning commands separately from their text. The public
/// document style already carries generic properties, so no AST variant is needed.
fn Parser::set_state_document_text(
  self : Parser,
  kind : String,
  text : String,
  alignment : String,
  position : String,
) -> Unit {
  self.style.apply(@style.TextBlock(kind, text))
  self.style.apply(@style.Property("document" + kind + "alignment", alignment))
  self.style.apply(@style.Property("document" + kind + "position", position))
}

///|
/// StateDiagramFactory registers both the single-line and multiline document
/// commands. Consume their bodies before they can be mistaken for state syntax.
/// Previously verified: inline/multiline document blocks preserve placement,
/// replacement order and following state commands.
fn Parser::consume_state_document(
  self : Parser,
  line : String,
) -> Bool raise @tokenizer.ParseError {
  let cursor = @tokenizer.Cursor::new(line)
  let first = cursor.take_while(char => char.is_ascii_alphabetic()).to_lower()
  let (kind, explicit_alignment) = if first == "left" ||
    first == "right" ||
    first == "center" {
    cursor.skip_inline_spaces()
    let kind = cursor.take_while(char => char.is_ascii_alphabetic()).to_lower()
    guard kind == "header" || kind == "footer" else { return false }
    (kind, Some(first))
  } else {
    guard ["title", "caption", "legend", "header", "footer"].contains(first) else {
      return false
    }
    (first, None)
  }
  guard cursor.is_eof() ||
    cursor.peek().map_or(false, char => char == ':' || char.is_whitespace()) else {
    return false
  }
  cursor.skip_inline_spaces()
  let colon = cursor.consume(':')
  cursor.skip_inline_spaces()
  let remaining = cursor.remaining()
  let default_alignment = if kind == "header" || kind == "footer" {
    self.style
    .property("DefaultTextAlignment")
    .map(value => value.to_lower())
    .unwrap_or(if kind == "header" { "right" } else { "center" })
  } else {
    "center"
  }
  let mut alignment = explicit_alignment.unwrap_or(default_alignment)
  let mut position = "bottom"
  let mut multiline = !colon && remaining.is_empty()
  if kind == "legend" && !colon && !remaining.is_empty() {
    let words = @tokenizer.syntax_words(remaining.to_lower())
    match words {
      [vertical] if vertical == "top" || vertical == "bottom" => {
        position = vertical
        multiline = true
      }
      [horizontal] if horizontal == "left" ||
        horizontal == "right" ||
        horizontal == "center" => {
        alignment = horizontal
        multiline = true
      }
      [vertical, horizontal] if (vertical == "top" || vertical == "bottom") &&
        (
          horizontal == "left" ||
          horizontal == "right" ||
          horizontal == "center"
        ) => {
        position = vertical
        alignment = horizontal
        multiline = true
      }
      _ => ()
    }
  }
  if !multiline {
    guard !remaining.is_empty() else {
      raise @tokenizer.SyntaxError(self.line_number(), "empty document text")
    }
    let text = if remaining.has_prefix("\"") &&
      remaining.has_suffix("\"") &&
      remaining.length() >= 2 {
      remaining[1:remaining.length() - 1].to_owned()
    } else {
      remaining
    }
    self.set_state_document_text(kind, text, alignment, position)
    return true
  }
  let start = self.line_number()
  let lines : Array[String] = []
  self.buffer.advance()
  while !self.buffer.at_end() {
    let raw = self.buffer.current()
    let trimmed = raw.trim().to_owned()
    if trimmed.equal_ignore_ascii_case("end " + kind) ||
      trimmed.equal_ignore_ascii_case("end" + kind) {
      guard !lines.is_empty() else {
        raise @tokenizer.SyntaxError(start, "empty document block")
      }
      let text = if kind == "header" || kind == "footer" {
        lines.map(line => line.trim().to_owned()).join("\n")
      } else {
        state_note_block_text(lines)
      }
      self.set_state_document_text(kind, text, alignment, position)
      return true
    }
    lines.push(raw)
    self.buffer.advance()
  }
  raise @tokenizer.SyntaxError(start, "unclosed document block")
}
