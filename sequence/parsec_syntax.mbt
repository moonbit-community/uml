///|
fn inline_spaces() -> @talcparsec.StringParser[Unit] {
  @talcparsec.satisfy("inline whitespace", is_inline_whitespace)
  .many()
  .map(_ => ())
}

///|
fn identifier_word_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.many_chars1(@talcparsec.satisfy("identifier word", is_ident_char))
}

///|
fn participant_type_parser() -> @talcparsec.StringParser[ParticipantType] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "participant" => @talcparsec.pure(Participant)
      "actor" => @talcparsec.pure(Actor)
      "boundary" => @talcparsec.pure(Boundary)
      "control" => @talcparsec.pure(Control)
      "entity" => @talcparsec.pure(Entity)
      "database" => @talcparsec.pure(Database)
      "collections" => @talcparsec.pure(Collections)
      "queue" => @talcparsec.pure(Queue)
      _ => @talcparsec.fail("participant type")
    }
  })
}

///|
fn group_keyword_parser() -> @talcparsec.StringParser[GroupKeyword] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "opt" => @talcparsec.pure(Opt)
      "alt" => @talcparsec.pure(Alt)
      "loop" => @talcparsec.pure(Loop)
      "par2" => @talcparsec.pure(Par2)
      "par" => @talcparsec.pure(Par)
      "break" => @talcparsec.pure(Break)
      "critical" => @talcparsec.pure(Critical)
      "group" => @talcparsec.pure(Group)
      "partition" => @talcparsec.pure(Partition)
      _ => @talcparsec.fail("group keyword")
    }
  })
}

///|
fn note_style_parser() -> @talcparsec.StringParser[NoteStyle] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "note" => @talcparsec.pure(NodeNormal)
      "hnote" => @talcparsec.pure(Hexagonal)
      "rnote" => @talcparsec.pure(Box)
      _ => @talcparsec.fail("note style")
    }
  })
}

///|
fn note_position_parser() -> @talcparsec.StringParser[NotePosition] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "left" => @talcparsec.pure(Left)
      "right" => @talcparsec.pure(Right)
      "bottom" => @talcparsec.pure(Bottom)
      "top" => @talcparsec.pure(Top)
      "over" => @talcparsec.pure(Over)
      "across" => @talcparsec.pure(Across)
      _ => @talcparsec.fail("note position")
    }
  })
}

///|
fn participant_list_parser() -> @talcparsec.StringParser[Array[String]] {
  let participant = inline_spaces()
    .then(quoted_participant().attempt().or(participant_identifier()))
    .skip(inline_spaces())
  participant.sep_by(@talcparsec.char(',')).skip(@talcparsec.eof())
}

///|
fn participant_identifier() -> @talcparsec.StringParser[String] {
  @talcparsec.many_chars1(
    @talcparsec.satisfy("participant identifier", is_ident_char),
  )
}

///|
fn quoted_participant() -> @talcparsec.StringParser[String] {
  @talcparsec.char('"')
  .then(@talcparsec.many_chars(@talcparsec.none_of("\"")))
  .skip(@talcparsec.char('"'))
}

///|
fn as_keyword() -> @talcparsec.StringParser[Unit] {
  @talcparsec.string("as")
  .skip(
    @talcparsec.satisfy("identifier character", is_ident_char).not_followed_by(
      "identifier character",
    ),
  )
  .map(_ => ())
}

///|
fn participant_alias_code() -> @talcparsec.StringParser[String] {
  inline_spaces()
  .then(as_keyword())
  .then(inline_spaces())
  .then(participant_identifier())
}

///|
fn participant_alias_display() -> @talcparsec.StringParser[String] {
  inline_spaces()
  .then(as_keyword())
  .then(inline_spaces())
  .then(quoted_participant().attempt().or(participant_identifier()))
}

///|
fn participant_ref_parser() -> @talcparsec.StringParser[PartRef] {
  let quoted = quoted_participant().bind(display => {
    participant_alias_code()
    .attempt()
    .optional()
    .map(reference_code => {
      match reference_code {
        Some(code) => { code, display }
        None => { code: display, display }
      }
    })
  })
  let unquoted = participant_identifier().bind(code => {
    participant_alias_display()
    .attempt()
    .optional()
    .map(reference_display => {
      match reference_display {
        Some(display) => { code, display }
        None => { code, display: code }
      }
    })
  })
  quoted.attempt().or(unquoted)
}

///|
fn participant_decl_ref_parser() -> @talcparsec.StringParser[PartRef] {
  let quoted = quoted_participant().bind(display => {
    participant_alias_code()
    .attempt()
    .optional()
    .map(reference_code => {
      match reference_code {
        Some(code) => { code, display }
        None => { code: display, display }
      }
    })
  })
  let unquoted = participant_identifier().bind(display => {
    participant_alias_display()
    .attempt()
    .optional()
    .map(reference_code => {
      match reference_code {
        Some(code) => { code, display }
        None => { code: display, display }
      }
    })
  })
  quoted.attempt().or(unquoted)
}

///|
fn participant_code_parser() -> @talcparsec.StringParser[String] {
  quoted_participant().attempt().or(participant_identifier())
}

///|
fn optional_arrow_index() -> @talcparsec.StringParser[Unit] {
  @talcparsec.char('(')
  .then(@talcparsec.ascii_digit().many())
  .skip(@talcparsec.char(')'))
  .attempt()
  .optional()
  .map(_ => ())
}

///|
fn left_arrow_head() -> @talcparsec.StringParser[(ArrowHead, ArrowPart)] {
  let left = @talcparsec.char('<').bind(_ => {
    @talcparsec.char('<')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, Full))
  })
  let top = @talcparsec.char('/').bind(_ => {
    @talcparsec.char('/')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, TopPart))
  })
  let bottom = @talcparsec.char('\\').bind(_ => {
    @talcparsec.char('\\')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, BottomPart))
  })
  @talcparsec.choice([left, top, bottom]).or(@talcparsec.pure((NoneHead, Full)))
}

///|
fn right_arrow_head() -> @talcparsec.StringParser[(ArrowHead, ArrowPart)] {
  let right = @talcparsec.char('>').bind(_ => {
    @talcparsec.char('>')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, Full))
  })
  let bottom = @talcparsec.char('/').bind(_ => {
    @talcparsec.char('/')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, BottomPart))
  })
  let top = @talcparsec.char('\\').bind(_ => {
    @talcparsec.char('\\')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, TopPart))
  })
  @talcparsec.choice([right, bottom, top]).or(
    @talcparsec.pure((NoneHead, Full)),
  )
}

///|
fn left_dressing_parser() -> @talcparsec.StringParser[DressingResult] {
  @talcparsec.char('o')
  .optional()
  .bind(circle => {
    @talcparsec.char('x')
    .optional()
    .bind(cross => {
      left_arrow_head().bind(head_and_part => {
        optional_arrow_index().map(_ => {
          let (head, part) = head_and_part
          {
            head,
            circle: circle is Some(_),
            cross: cross is Some(_),
            has_dir: head.has_direction(),
            part,
          }
        })
      })
    })
  })
}

///|
fn right_dressing_parser() -> @talcparsec.StringParser[DressingResult] {
  @talcparsec.char('_')
  .optional()
  .bind(_ => {
    right_arrow_head().bind(head_and_part => {
      @talcparsec.char('o')
      .optional()
      .bind(circle => {
        @talcparsec.char('x')
        .optional()
        .bind(cross => {
          optional_arrow_index().map(_ => {
            let (head, part) = head_and_part
            {
              head,
              circle: circle is Some(_),
              cross: cross is Some(_),
              has_dir: head.has_direction(),
              part,
            }
          })
        })
      })
    })
  })
}

///|
fn arrow_dressing_parser() -> @talcparsec.StringParser[
  (DressingResult, ArrowBody, DressingResult),
] {
  let dashes = @talcparsec.many_chars(@talcparsec.char('-'))
  let style = @talcparsec.char('[')
    .then(@talcparsec.many_chars(@talcparsec.none_of("]")))
    .skip(@talcparsec.char(']'))
    .attempt()
    .optional()
  left_dressing_parser().bind(left => {
    dashes.bind(first => {
      style
      .then(dashes)
      .bind(second => {
        guard first.length() + second.length() > 0 else {
          return @talcparsec.fail("arrow body")
        }
        right_dressing_parser().map(right => {
          let body = if first.length() + second.length() > 1 {
            Dotted
          } else {
            Solid
          }
          (left, body, right)
        })
      })
    })
  })
}

///|
fn activation_spec_parser() -> @talcparsec.StringParser[ActivationSpec] {
  @talcparsec.choice([
    @talcparsec.string("++").map(_ => Activate),
    @talcparsec.string("--").map(_ => Deactivate),
    @talcparsec.string("!!").map(_ => Destroy),
    @talcparsec.string("**").map(_ => Create),
  ])
}

///|
fn multicast_parser() -> @talcparsec.StringParser[Array[String]] {
  @talcparsec.char('&')
  .then(inline_spaces())
  .then(participant_identifier())
  .skip(inline_spaces())
  .some()
}

///|
fn color_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.char('#').then(
    @talcparsec.many_chars1(
      @talcparsec.satisfy("color", char => {
        !is_inline_whitespace(char) && char != '\n'
      }),
    ),
  )
}

///|
fn anchor_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.char('{')
  .then(participant_identifier())
  .skip(@talcparsec.char('}'))
}

///|
fn quoted_string_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.char('"')
  .then(@talcparsec.many_chars(@talcparsec.none_of("\"")))
  .skip(@talcparsec.char('"'))
}
