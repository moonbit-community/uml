///|
fn note_position(word : String) -> NotePosition? {
  match word.to_lower() {
    "left" => Some(Left)
    "right" => Some(Right)
    "top" => Some(Top)
    "bottom" => Some(Bottom)
    _ => None
  }
}

///|
fn text_block_end(line : String, keyword : String) -> Bool {
  match line.to_lower() {
    value if value == "end " + keyword || value == "end" + keyword => true
    _ => false
  }
}

///|
fn Parser::consume_text_block(
  self : Parser,
  keyword : String,
) -> Unit raise @core.ParseError {
  self.index += 1
  let text = StringBuilder()
  let mut first = true
  while self.index < self.lines.length() {
    if text_block_end(strip_comment(self.lines[self.index]), keyword) {
      self.style.apply(TextBlock(keyword, text.to_string()))
      return
    }
    if !first {
      text.write_char('\n')
    }
    text.write_string(self.lines[self.index])
    first = false
    self.index += 1
  }
  self.raise_parse_error("unclosed \{keyword}")
}

///|
fn Parser::consume_braced_block(
  self : Parser,
  kind : String,
) -> Unit raise @core.ParseError {
  let package_depth = self.package_stack.length()
  self.index += 1
  while self.index < self.lines.length() {
    let line = strip_comment(self.lines[self.index])
    if line == "}" && self.package_stack.length() == package_depth {
      return
    }
    let reference = normalize_name(line)
    let existing_reference = @core.syntax_words(line).length() == 1 &&
      (self.has_entity(self.resolve(reference)) || self.has_entity(reference))
    if !existing_reference {
      self.parse_line(self.lines[self.index])
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed \{kind}")
}

///|
fn Parser::consume_skinparam_block(
  self : Parser,
) -> Unit raise @core.ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    let property = strip_comment(self.lines[self.index])
    if property == "}" {
      return
    }
    match @core.parse_style_property(property) {
      Some(directive) => self.style.apply(directive)
      None => ()
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed skinparam")
}

///|
fn Parser::consume_common_block(
  self : Parser,
  terminator : String,
) -> Unit raise @core.ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    if strip_comment(self.lines[self.index]).to_lower() == terminator {
      return
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed common definition block")
}

///|
