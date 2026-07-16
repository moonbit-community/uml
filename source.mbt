///|
struct Source {
  chars : Array[Char]
  mut pos : Int
}

///|
fn Source::new(input : String) -> Source {
  let cs : Array[Char] = []
  for c in input {
    cs.push(c)
  }
  { chars: cs, pos: 0 }
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
  if self.pos >= self.chars.length() {
    None
  } else {
    Some(self.chars[self.pos])
  }
}

///|
fn Source::advance(self : Source) -> Char {
  let c = self.chars[self.pos]
  self.pos = self.pos + 1
  c
}

///|
fn Source::consume(self : Source, expected : Char) -> Bool {
  match self.peek() {
    Some(c) if c == expected => {
      self.pos = self.pos + 1
      true
    }
    _ => false
  }
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
  while true {
    match self.peek() {
      Some(c) if c == ' ' || c == '\t' || c == '\r' => self.pos = self.pos + 1
      _ => break
    }
  }
}

///|
fn Source::try_keyword(self : Source, kw : String) -> Bool {
  if self.peek_word().equal_ignore_ascii_case(kw) {
    self.skip_word()
    true
  } else {
    false
  }
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
  while true {
    match self.peek() {
      Some('\n') => {
        self.pos = self.pos + 1
        break
      }
      Some(_) => self.pos = self.pos + 1
      None => break
    }
  }
}

///|
fn Source::take_while(self : Source, pred : (Char) -> Bool) -> String {
  let start = self.pos
  while true {
    match self.peek() {
      Some(c) if pred(c) => self.pos = self.pos + 1
      _ => break
    }
  }
  let sb = StringBuilder()
  for i = start; i < self.pos; i = i + 1 {
    sb <+ "\{self.chars[i]}"
  }
  sb.to_string()
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
