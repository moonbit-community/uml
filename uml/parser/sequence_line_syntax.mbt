///|
priv enum SequenceLineSyntax {
  ParsedEvent(@seq.Event)
  ParsedParticipant(ParticipantDecl)
  ParsedNote(NoteLineSyntax)
  ParsedReference(ReferenceLineSyntax)
  ParsedTitle(SequenceTextSyntax)
}

///|
fn take_block_text(
  source : @parse.Cursor,
  terminator : (String) -> Bool,
) -> String? {
  @parse.collect_lines_until(
    () => {
      guard !source.is_eof() else { return None }
      Some(source.take_line())
    },
    line => terminator(line.trim().to_lower().to_owned()),
  ).map(lines => lines.join("\n"))
}

///|
/// Consumes one or more identifier characters, or nothing.
fn take_ident(cursor : @parse.Cursor) -> String {
  cursor.take_while(is_ident_char)
}

///|
/// Matches a whole identifier word against `keyword`, ignoring case.
fn take_keyword(cursor : @parse.Cursor, keyword : String) -> Bool {
  let start = cursor.offset()
  let word = take_ident(cursor)
  if word.length() > 0 && word.equal_ignore_ascii_case(keyword) {
    true
  } else {
    ignore(cursor.restore(start))
    false
  }
}

///|
/// Matches a quoted value, falling back to an unquoted identifier token.
fn take_quoted_or_ident(cursor : @parse.Cursor) -> String? {
  if cursor.peek() == Some('"') {
    if cursor.take_quoted_value() is Some(value) {
      return Some(value)
    }
  }
  let value = take_ident(cursor)
  if value.length() > 0 {
    Some(value)
  } else {
    None
  }
}

///|
/// Matches an optionally negative run of digits.
fn take_signed_integer(cursor : @parse.Cursor) -> Int? {
  let start = cursor.offset()
  let sign = if cursor.consume('-') { "-" } else { "" }
  let digits = cursor.take_while(Char::is_ascii_digit)
  guard digits.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  Some(@string.parse_int(sign + digits) catch { _ => 0 })
}

///|
fn title_line_syntax(cursor : @parse.Cursor) -> SequenceTextSyntax? {
  guard take_keyword(cursor, "title") else { return None }
  let rest = cursor.take_while(_ => true)
  @parse.normalize_label(rest).map_or(Some(Multiline), text => {
    Some(Inline(text))
  })
}

///|
/// Command matching follows `SequenceDiagramFactory` order, with message
/// arrows tried before the other Cursor-based commands.
fn parse_sequence_line(line : String) -> SequenceLineSyntax? {
  let cursor = @parse.Cursor::new(line)
  if complete_message_line_syntax(cursor) is Some(event) {
    return Some(ParsedEvent(event))
  }
  ignore(cursor.restore(0))
  if note_line_syntax(cursor) is Some(note) {
    return Some(ParsedNote(note))
  }
  ignore(cursor.restore(0))
  if reference_line_syntax(cursor) is Some(reference) {
    return Some(ParsedReference(reference))
  }
  ignore(cursor.restore(0))
  if simple_event_line_syntax(cursor) is Some(event) {
    return Some(ParsedEvent(event))
  }
  ignore(cursor.restore(0))
  if participant_declaration_line_syntax(cursor) is Some(participant) {
    return Some(ParsedParticipant(participant))
  }
  ignore(cursor.restore(0))
  title_line_syntax(cursor).map(text => ParsedTitle(text))
}

///|
/// Whether any preceding event can carry an on-arrow note, mirroring Java's
/// `getLastEventWithNote` plus the carrier's `addNote` position rules:
/// messages and exo arrows carry every on-arrow position, while references
/// and group leaves carry only left/right notes (a top/bottom note attached
/// to them is dropped with a warning).
fn ParseCtx::has_event_with_note(self : ParseCtx, top_or_bottom : Bool) -> Bool {
  self.events.fold(init=false, (carried, event) => {
    if event is @seq.Message(_) || event is @seq.MessageExo(_) {
      true
    } else if event is @seq.Reference(_) || event is @seq.GroupingLeaf(_) {
      !top_or_bottom
    } else {
      carried
    }
  })
}

///|
fn ParseCtx::apply_note_syntax(
  self : ParseCtx,
  syntax : NoteLineSyntax,
) -> Unit raise @parse.ParseError {
  if syntax.misspelled_across {
    self.source.raise_parse_error("Use 'across' instead of 'accross'")
  }
  self.source.skip_line()
  let text = match syntax.text {
    Inline(text) => text
    Multiline =>
      match
        take_block_text(self.source, line => {
          line == "end note" ||
          line == "endnote" ||
          line == "end hnote" ||
          line == "end rnote"
        }) {
        Some(text) => text
        None => {
          self.source.raise_parse_error("unclosed note")
          ""
        }
      }
  }
  let note : @seq.Note = {
    participant_codes: syntax.participant_codes,
    position: syntax.position,
    text,
    note_style: syntax.note_style,
    on_arrow: syntax.on_arrow,
    color: syntax.color,
    stereotype: syntax.stereotype,
    url: syntax.url,
  }
  // Java silently drops an on-arrow note when no preceding event can carry
  // it (`FactorySequenceNoteOnArrowCommand.executeInternal` does nothing
  // when `getLastEventWithNote` returns null), and top/bottom notes are
  // dropped when the carrier only accepts left/right positions.
  if note.on_arrow &&
    !self.has_event_with_note(
      note.position is @seq.Top || note.position is @seq.Bottom,
    ) {
    return
  }
  self.push_event(@seq.Note(note))
  if syntax.merge && self.events.length() > 1 {
    match self.events.pop() {
      Some(@seq.Note(popped)) =>
        match self.events[self.events.length() - 1] {
          @seq.Note(previous) =>
            self.events[self.events.length() - 1] = @seq.Notes([
              previous, popped,
            ])
          @seq.Notes(list) => list.push(popped)
          _ => self.events.push(@seq.Note(popped))
        }
      _ => ()
    }
  }
}

///|
fn ParseCtx::apply_reference_syntax(
  self : ParseCtx,
  syntax : ReferenceLineSyntax,
) -> Unit raise @parse.ParseError {
  self.source.skip_line()
  let label = match syntax.text {
    Inline(text) => @parse.normalize_label(text)
    Multiline =>
      match
        take_block_text(self.source, line => {
          line == "end ref" || line == "endref"
        }) {
        Some(text) => Some(text)
        None => {
          self.source.raise_parse_error("unclosed reference")
          None
        }
      }
  }
  self.push_event(
    @seq.Reference({ participant_codes: syntax.participant_codes, label, }),
  )
}

///|
fn ParseCtx::apply_line_syntax(
  self : ParseCtx,
  syntax : SequenceLineSyntax,
) -> Unit raise @parse.ParseError {
  match syntax {
    ParsedEvent(event) => {
      self.source.skip_line()
      self.push_event(event)
    }
    ParsedParticipant(participant) => {
      self.source.skip_line()
      self.declare_participant(participant)
    }
    ParsedNote(note) => self.apply_note_syntax(note)
    ParsedReference(reference) => self.apply_reference_syntax(reference)
    ParsedTitle(text) => {
      self.source.skip_line()
      if text is Multiline &&
        take_block_text(self.source, line => line == "end title") is None {
        self.source.raise_parse_error("unclosed title")
      }
    }
  }
}
