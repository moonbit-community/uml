///|
priv enum SequenceTextSyntax {
  Inline(String)
  Multiline
}

///|
priv struct NoteLineSyntax {
  participant_codes : Array[String]
  position : NotePosition
  note_style : NoteStyle
  on_arrow : Bool
  color : String?
  text : SequenceTextSyntax
}

///|
priv struct ReferenceLineSyntax {
  participant_codes : Array[String]
  text : SequenceTextSyntax
}

///|
fn parsed_note_position(
  position : NotePosition,
  participants : Array[String],
) -> NotePosition {
  if position is Over && participants.length() > 1 {
    OverSeveral
  } else {
    position
  }
}

///|
fn sequence_text_parser() -> @talcparsec.StringParser[SequenceTextSyntax] {
  @talcparsec.char(':')
  .then(line_rest_parser("inline text"))
  .map(text => Inline(text.trim().to_owned()))
  .or(@talcparsec.pure(Multiline))
}

///|
fn note_on_arrow_tail_parser(
  position : NotePosition,
  note_style : NoteStyle,
) -> @talcparsec.StringParser[NoteLineSyntax] {
  sequence_text_parser().map(text => {
    participant_codes: [],
    position,
    note_style,
    on_arrow: true,
    color: None,
    text,
  })
}

///|
fn participant_note_tail_parser(
  position : NotePosition,
  note_style : NoteStyle,
  require_of : Bool,
) -> @talcparsec.StringParser[NoteLineSyntax] {
  let connector = if require_of {
    keyword_parser("of").skip(inline_space1())
  } else {
    keyword_parser("of").skip(inline_space1()).attempt().optional().map(_ => ())
  }
  connector
  .then(participant_list_prefix_parser())
  .bind(participant_codes => {
    let valid = match position {
      Left | Right => participant_codes.length() == 1
      Over => participant_codes.length() >= 1 && participant_codes.length() <= 2
      _ => false
    }
    guard valid else { return @talcparsec.fail("note participants") }
    inline_space1()
    .then(color_parser())
    .attempt()
    .optional()
    .bind(color => {
      inline_spaces()
      .then(sequence_text_parser())
      .map(text => {
        participant_codes,
        position: parsed_note_position(position, participant_codes),
        note_style,
        on_arrow: false,
        color,
        text,
      })
    })
  })
}

///|
fn across_note_tail_parser(
  note_style : NoteStyle,
) -> @talcparsec.StringParser[NoteLineSyntax] {
  inline_space1()
  .then(color_parser())
  .attempt()
  .optional()
  .bind(color => {
    inline_spaces()
    .then(sequence_text_parser())
    .map(text => {
      participant_codes: [],
      position: Across,
      note_style,
      on_arrow: false,
      color,
      text,
    })
  })
}

///|
fn note_line_parser() -> @talcparsec.StringParser[NoteLineSyntax] {
  @talcparsec.char('&')
  .optional()
  .then(@talcparsec.char('/').optional())
  .then(inline_spaces())
  .then(note_style_parser())
  .bind(note_style => {
    inline_space1()
    .then(note_position_parser())
    .bind(position => {
      inline_spaces().then(
        match position {
          Top | Bottom => note_on_arrow_tail_parser(position, note_style)
          Left | Right =>
            participant_note_tail_parser(position, note_style, true)
            .attempt()
            .or(note_on_arrow_tail_parser(position, note_style))
          Over => participant_note_tail_parser(position, note_style, false)
          Across => across_note_tail_parser(note_style)
          OverSeveral => @talcparsec.fail("note position")
        },
      )
    })
  })
  .skip(@talcparsec.eof())
}

///|
fn reference_line_parser() -> @talcparsec.StringParser[ReferenceLineSyntax] {
  keyword_parser("ref")
  .then(inline_space1())
  .then(keyword_parser("over"))
  .then(inline_space1())
  .then(participant_list_prefix_parser())
  .bind(participant_codes => {
    inline_spaces()
    .then(sequence_text_parser())
    .map(text => { participant_codes, text })
  })
  .skip(@talcparsec.eof())
}

///|
fn Source::take_block_text(
  self : Source,
  terminator : (String) -> Bool,
) -> String? {
  let output = StringBuilder()
  let mut first = true
  while !self.eof() {
    let line = self.current_line()
    if terminator(line.trim().to_lower().to_owned()) {
      self.skip_line()
      return Some(output.to_string())
    }
    if !first {
      output.write_char('\n')
    }
    output.write_string(line)
    first = false
    self.skip_line()
  }
  None
}
