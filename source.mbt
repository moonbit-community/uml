///|
struct Source {
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
fn Source::restore(self : Source, pos : Int) -> Unit {
  self.pos = pos
}

///|
fn Source::eof(self : Source) -> Bool {
  self.pos >= self.chars.length()
}

///|
fn Source::peek(self : Source) -> Char? {
  guard !self.eof() else { None }
  Some(self.chars[self.pos])
}

///|
fn Source::advance(self : Source) -> Char {
  let c = self.chars[self.pos]
  self.pos = self.pos + 1
  c
}

///|
fn Source::consume(self : Source, expected : Char) -> Bool {
  guard self.peek() is Some(c) && c == expected else { false }
  self.pos = self.pos + 1
  true
}

///|
fn Source::try_string(self : Source, s : String) -> Bool {
  let saved = self.save()
  for c in s {
    match self.peek() {
      Some(ch) if ch == c => self.pos = self.pos + 1
      _ => {
        self.restore(saved)
        return false
      }
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
fn Source::try_keyword(self : Source, kw : String) -> Bool {
  guard self.peek_word().equal_ignore_ascii_case(kw) else { false }
  self.skip_word()
  true
}

///|
fn Source::finish_command(self : Source, start : Int) -> Bool {
  for i = start; i < self.pos; i = i + 1 {
    if self.chars[i] == '\n' {
      return true
    }
  }
  self.skip_whitespace()
  match self.peek() {
    Some('\n') => {
      self.pos = self.pos + 1
      true
    }
    None => true
    _ => false
  }
}

///|
fn Source::skip_line(self : Source) -> Unit {
  while self.peek() is Some(c) && c != '\n' {
    self.pos += 1
  }
  let _ = self.consume('\n')
}

///|
fn Source::take_while(self : Source, pred : (Char) -> Bool) -> String {
  let start = self.pos
  while self.peek().map_or(false, pred) {
    self.pos += 1
  }
  let builder = StringBuilder()
  for i = start; i < self.pos; i = i + 1 {
    builder <+ "\{self.chars[i]}"
  }
  builder.to_string()
}

///|
fn Source::peek_word(self : Source) -> String {
  let result = StringBuilder()
  let mut index = self.pos
  while index < self.chars.length() {
    let c = self.chars[index]
    guard is_ident_char(c) else { break }
    result <+ "\{c}"
    index = index + 1
  }
  result.to_string()
}

///|
fn Source::skip_word(self : Source) -> Unit {
  while self.peek() is Some(c) && is_ident_char(c) {
    self.pos = self.pos + 1
  }
}

///|
fn Source::collect_line(self : Source) -> String {
  let result = self.take_while(c => c != '\n')
  let _ = self.consume('\n')
  result
}
