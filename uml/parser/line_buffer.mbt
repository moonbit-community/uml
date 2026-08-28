///|
/// A line-indexed source buffer for the line-based diagram parsers.
///
/// The state, entity, timing, and activity parsers each walk preprocessed
/// lines by index; keep that plumbing here so preprocessing, index stepping,
/// comment stripping, and the 1-based line numbers are defined once instead
/// of being re-implemented per parser. New line-based parsers should embed a
/// `LineBuffer` rather than carrying their own `lines` array and `index`.
priv struct LineBuffer {
  lines : Array[String]
  mut index : Int
}

///|
fn LineBuffer::new(input : String) -> LineBuffer {
  {
    lines: @tokenizer.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array(),
    index: 0,
  }
}

///|
/// The 1-based number of the current line.
fn LineBuffer::line_number(self : LineBuffer) -> Int {
  self.index + 1
}

///|
/// The total number of lines in the buffer.
fn LineBuffer::length(self : LineBuffer) -> Int {
  self.lines.length()
}

///|
fn LineBuffer::at_end(self : LineBuffer) -> Bool {
  self.index >= self.lines.length()
}

///|
/// The current line without consuming it.
fn LineBuffer::current(self : LineBuffer) -> String {
  self.lines[self.index]
}

///|
/// The current line with its trailing comment stripped, without consuming.
fn LineBuffer::current_stripped(self : LineBuffer) -> String {
  @tokenizer.strip_line_comment(self.lines[self.index])
}

///|
/// The current line with its trailing comment stripped and trimmed.
fn LineBuffer::current_clean(self : LineBuffer) -> String {
  self.current_stripped().trim().to_owned()
}

///|
/// Moves to the next line.
fn LineBuffer::advance(self : LineBuffer) -> Unit {
  self.index += 1
}

///|
/// Consumes the current line and returns it with its trailing comment
/// stripped, or `None` at the end of input. Matches the `next_line` closures
/// the shared block readers (`consume_lines_until`) expect.
fn LineBuffer::take_next(self : LineBuffer) -> String? {
  guard self.index < self.lines.length() else { return None }
  let line = @tokenizer.strip_line_comment(self.lines[self.index])
  self.index += 1
  Some(line)
}
