///|
priv struct Source {
  chars : Array[Char]
  mut pos : Int
}

///|
fn Source::new(input : String) -> Source {
  { chars: input.to_array(), pos: 0 }
}

///|
fn Source::eof(self : Source) -> Bool {
  self.pos >= self.chars.length()
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
fn Source::collect_line(self : Source) -> String {
  let line = self.current_line()
  self.pos += line.to_array().length()
  if self.pos < self.chars.length() && self.chars[self.pos] == '\n' {
    self.pos += 1
  }
  line
}

///|
fn Source::skip_line(self : Source) -> Unit {
  ignore(self.collect_line())
}

///|
fn Source::diagnostic(self : Source, message : String) -> @core.ParseDiagnostic {
  @core.diagnostic_at_span(@core.source_span(self.chars, self.pos), message)
}

///|
fn Source::raise_parse_error(
  self : Source,
  message : String,
) -> Unit raise @core.ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}
