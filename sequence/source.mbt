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
  if expected == '\n' {
    guard self.peek() is Some('\n') else { return false }
    self.pos += 1
    return true
  }
  self.try_parsec(@talcparsec.char(expected)) is Some(_)
}

///|
fn Source::try_string(self : Source, expected : String) -> Bool {
  self.try_parsec(@talcparsec.string(expected)) is Some(_)
}

///|
fn Source::skip_whitespace(self : Source) -> Unit {
  ignore(
    self.try_parsec(
      @talcparsec.satisfy("inline whitespace", is_inline_whitespace).many(),
    ),
  )
}

///|
fn Source::take_while(self : Source, predicate : (Char) -> Bool) -> String {
  self
  .try_parsec(@talcparsec.take_while("matching character", predicate))
  .unwrap_or("")
}

///|
fn Source::peek_word(self : Source) -> String {
  match
    identifier_word_parser().run(@talcparsec.Input::new(self.current_line())) {
    Ok((word, _)) => word
    Err(_) => ""
  }
}

///|
fn Source::try_keyword(self : Source, keyword : String) -> Bool {
  let checkpoint = self.save()
  match self.try_parsec(identifier_word_parser()) {
    Some(word) if word.equal_ignore_ascii_case(keyword) => true
    _ => {
      self.restore(checkpoint)
      false
    }
  }
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
fn Source::diagnostic(self : Source, message : String) -> @core.ParseDiagnostic {
  @core.diagnostic_at_span(@core.source_span(self.chars, self.pos), message)
}

///|
fn Source::raise_parse_error(
  self : Source,
  message : String,
) -> Unit raise ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}

///|
fn Source::current_line(self : Source) -> String {
  let mut end = self.pos
  while end < self.chars.length() && self.chars[end] != '\n' {
    end += 1
  }
  let output = StringBuilder()
  for index in self.pos..<end {
    output.write_char(self.chars[index])
  }
  output.to_string()
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

///|
/// Run a stateless line grammar and advance this source by its consumed input.
fn[T] Source::try_parsec(
  self : Source,
  parser : @talcparsec.StringParser[T],
) -> T? {
  let line = self.current_line()
  match parser.run(@talcparsec.Input::new(line)) {
    Ok((value, rest)) => {
      let consumed = line.length() - rest.remaining().length()
      self.pos += line[0:consumed].to_array().length()
      Some(value)
    }
    Err(_) => None
  }
}

///|
fn Source::try_url_target(self : Source) -> @core.UrlTarget? {
  let line = self.current_line()
  match @core.parse_url_target_prefix(line) {
    Some((target, remaining)) => {
      let consumed = line.length() - remaining.length()
      self.pos += line[0:consumed].to_array().length()
      Some(target)
    }
    None => None
  }
}
