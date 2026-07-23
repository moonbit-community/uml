///|
priv enum SequenceLineSyntax {
  ParsedEvent(Event)
  ParsedParticipant(ParticipantDecl)
  ParsedNote(NoteLineSyntax)
  ParsedReference(ReferenceLineSyntax)
  ParsedTitle(SequenceTextSyntax)
}

///|
fn title_line_parser() -> @talcparsec.StringParser[SequenceLineSyntax] {
  keyword_parser("title")
  .then(line_rest_parser("title"))
  .map(rest => {
    match rest.optional_text() {
      Some(text) => ParsedTitle(Inline(text))
      None => ParsedTitle(Multiline)
    }
  })
  .skip(@talcparsec.eof())
}

///|
fn sequence_line_parser() -> @talcparsec.StringParser[SequenceLineSyntax] {
  @talcparsec.choice([
    complete_message_line_parser().attempt().map(event => ParsedEvent(event)),
    note_line_parser().attempt().map(note => ParsedNote(note)),
    reference_line_parser()
    .attempt()
    .map(reference => ParsedReference(reference)),
    simple_event_line_parser().attempt().map(event => ParsedEvent(event)),
    participant_declaration_line_parser()
    .attempt()
    .map(participant => ParsedParticipant(participant)),
    title_line_parser(),
  ])
}

///|
fn parse_sequence_line(line : String) -> SequenceLineSyntax? {
  match sequence_line_parser().parse(@talcparsec.Input::new(line)) {
    Ok(syntax) => Some(syntax)
    Err(_) => None
  }
}

///|
fn ParseCtx::apply_note_syntax(
  self : ParseCtx,
  syntax : NoteLineSyntax,
) -> Unit raise @core.ParseError {
  self.source.skip_line()
  let text = match syntax.text {
    Inline(text) => text
    Multiline =>
      match
        self.source.take_block_text(line => {
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
  self.push_event(
    Note({
      participant_codes: syntax.participant_codes,
      position: syntax.position,
      text,
      note_style: syntax.note_style,
      on_arrow: syntax.on_arrow,
      color: syntax.color,
    }),
  )
}

///|
fn ParseCtx::apply_reference_syntax(
  self : ParseCtx,
  syntax : ReferenceLineSyntax,
) -> Unit raise @core.ParseError {
  self.source.skip_line()
  let label = match syntax.text {
    Inline(text) => text.optional_text()
    Multiline =>
      match
        self.source.take_block_text(line => {
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
    Reference({ participant_codes: syntax.participant_codes, label }),
  )
}

///|
fn ParseCtx::apply_line_syntax(
  self : ParseCtx,
  syntax : SequenceLineSyntax,
) -> Unit raise @core.ParseError {
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
        self.source.take_block_text(line => line == "end title") is None {
        self.source.raise_parse_error("unclosed title")
      }
    }
  }
}
