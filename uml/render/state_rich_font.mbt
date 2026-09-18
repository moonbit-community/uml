///|
const STATE_MONOSPACED_FAMILY : String = "monospaced"

///|
fn state_monospaced_family(style : @style.DocumentStyle) -> String {
  style.property("DefaultMonospacedFontName").unwrap_or(STATE_MONOSPACED_FAMILY)
}

///|
priv struct StateRichFontTag {
  length : Int
  family : String?
  size : Int?
  color : String?
}

///|
fn state_font_tag_space(char : Char) -> Bool {
  char == ' ' || char == '\u00a0' || char is ('\u0009'..='\u000d')
}

///|
/// CommandCreoleColorAndSizeChange precedes the family command. Repeated size
/// and color captures retain the last value, in either attribute order.
fn state_rich_font_attributes(cursor : @tokenizer.Cursor) -> StateRichFontTag? {
  let mut size = None
  let mut color = None
  let mut seen = false
  while !cursor.is_eof() {
    let spaces = cursor.take_while(state_font_tag_space)
    if seen && cursor.consume_literal(">") {
      return Some({ length: cursor.offset(), family: None, size, color, })
    }
    guard !spaces.is_empty() else { return None }
    let key = cursor.take_while(char => char.is_ascii_alphabetic()).to_lower()
    guard key == "size" || key == "color" else { return None }
    ignore(cursor.take_while(state_font_tag_space))
    guard cursor.consume_literal("=") else { return None }
    ignore(cursor.take_while(state_font_tag_space))
    if cursor.peek() is Some('"' | '\u201c' | '\u201d') {
      ignore(cursor.advance())
    }
    if key == "size" {
      let digits = cursor.take_while(char => char.is_ascii_digit())
      guard !digits.is_empty() else { return None }
      size = Some(@string.parse_int(digits) catch { _ => return None })
    } else if cursor.consume_literal("#") {
      let hex = cursor.take_while(char => {
        char.is_ascii_digit() || char is ('a'..='f') || char is ('A'..='F')
      })
      guard hex.length() == 6 else { return None }
      color = Some("#" + hex)
    } else {
      let name = cursor.take_while(char => {
        char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
      })
      guard !name.is_empty() else { return None }
      color = Some(name)
    }
    if cursor.peek() is Some('"' | '\u201c' | '\u201d') {
      ignore(cursor.advance())
    }
    seen = true
  }
  None
}

///|
fn state_rich_font_open(text : String) -> StateRichFontTag? {
  let cursor = @tokenizer.Cursor::new(text)
  guard cursor.remaining().to_lower().has_prefix("<font") else { return None }
  ignore(cursor.restore("<font".length()))
  if cursor.attempt(state_rich_font_attributes) is Some(tag) {
    return Some(tag)
  }
  guard !cursor
    .take_while(char => {
      char == ':' || char == ' ' || char is ('\u0009'..='\u000d')
    })
    .is_empty() else {
    return None
  }
  let family = cursor.take_while(char => char != '>')
  guard !family.is_empty() && cursor.consume_literal(">") else { return None }
  Some({
    length: cursor.offset(),
    family: Some(family),
    size: None,
    color: None,
  })
}
