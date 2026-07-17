///|
#warnings("-unused_value")
priv struct Source {
  chars : Array[Char]
  mut pos : Int
}

///|
fn Source::new(input : String) -> Source {
  { chars: input.to_array(), pos: 0 }
}

///|
fn Source::save(self : Source) -> Int {
  self.pos
}

///|
fn Source::restore(self : Source, checkpoint : Int) -> Unit {
  self.pos = checkpoint
}

///|
fn Source::eof(self : Source) -> Bool {
  self.pos >= self.chars.length()
}

///|
fn Source::peek(self : Source) -> Char? {
  if self.eof() {
    None
  } else {
    Some(self.chars[self.pos])
  }
}

///|
fn Source::advance(self : Source) -> Char {
  let char = self.chars[self.pos]
  self.pos += 1
  char
}

///|
fn Source::consume(self : Source, expected : Char) -> Bool {
  guard self.peek() is Some(char) && char == expected else { false }
  self.pos += 1
  true
}

///|
fn Source::try_string(self : Source, expected : String) -> Bool {
  let checkpoint = self.save()
  for char in expected {
    guard self.consume(char) else {
      self.restore(checkpoint)
      return false
    }
  }
  true
}

///|
fn Source::skip_whitespace(self : Source) -> Unit {
  while self.peek().map_or(false, is_inline_whitespace) {
    self.pos += 1
  }
}

///|
fn Source::take_while(self : Source, predicate : (Char) -> Bool) -> String {
  let start = self.pos
  while self.peek().map_or(false, predicate) {
    self.pos += 1
  }
  let output = StringBuilder()
  for index in start..<self.pos {
    output.write_char(self.chars[index])
  }
  output.to_string()
}

///|
fn Source::peek_word(self : Source) -> String {
  let output = StringBuilder()
  let mut index = self.pos
  while index < self.chars.length() && is_ident_char(self.chars[index]) {
    output.write_char(self.chars[index])
    index += 1
  }
  output.to_string()
}

///|
fn Source::skip_word(self : Source) -> Unit {
  let _ = self.take_while(is_ident_char)
}

///|
fn Source::try_keyword(self : Source, keyword : String) -> Bool {
  guard self.peek_word().equal_ignore_ascii_case(keyword) else { false }
  self.skip_word()
  true
}

///|
fn Source::collect_line(self : Source) -> String {
  let line = self.take_while(c => c != '\n')
  let _ = self.consume('\n')
  line
}

///|
fn Source::skip_line(self : Source) -> Unit {
  let _ = self.collect_line()
}

///|
fn Source::finish_command(self : Source, start : Int) -> Bool {
  for index in start..<self.pos {
    guard self.chars[index] != '\n' else { return true }
  }
  self.skip_whitespace()
  match self.peek() {
    Some('\n') => {
      self.pos += 1
      true
    }
    None => true
    _ => false
  }
}
