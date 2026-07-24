///|
fn inline_spaces() -> @talc.StringParser[Unit] {
  @talc.satisfy("inline whitespace", is_inline_whitespace).many().map(_ => ())
}

///|
fn identifier_word_parser() -> @talc.StringParser[String] {
  @talc.many_chars1(@talc.satisfy("identifier word", is_ident_char))
}

///|
fn participant_type_parser() -> @talc.StringParser[ParticipantType] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "participant" => @talc.pure(Participant)
      "actor" => @talc.pure(Actor)
      "boundary" => @talc.pure(Boundary)
      "control" => @talc.pure(Control)
      "entity" => @talc.pure(Entity)
      "database" => @talc.pure(Database)
      "collections" => @talc.pure(Collections)
      "queue" => @talc.pure(Queue)
      _ => @talc.fail("participant type")
    }
  })
}

///|
fn group_keyword_parser() -> @talc.StringParser[GroupKeyword] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "opt" => @talc.pure(Opt)
      "alt" => @talc.pure(Alt)
      "loop" => @talc.pure(Loop)
      "par2" => @talc.pure(Par2)
      "par" => @talc.pure(Par)
      "break" => @talc.pure(Break)
      "critical" => @talc.pure(Critical)
      "group" => @talc.pure(Group)
      "partition" => @talc.pure(Partition)
      _ => @talc.fail("group keyword")
    }
  })
}

///|
fn note_style_parser() -> @talc.StringParser[NoteStyle] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "note" => @talc.pure(NodeNormal)
      "hnote" => @talc.pure(Hexagonal)
      "rnote" => @talc.pure(Box)
      _ => @talc.fail("note style")
    }
  })
}

///|
fn note_position_parser() -> @talc.StringParser[NotePosition] {
  identifier_word_parser().bind(word => {
    match word.to_lower() {
      "left" => @talc.pure(Left)
      "right" => @talc.pure(Right)
      "bottom" => @talc.pure(Bottom)
      "top" => @talc.pure(Top)
      "over" => @talc.pure(Over)
      "across" => @talc.pure(Across)
      _ => @talc.fail("note position")
    }
  })
}

///|
fn participant_list_prefix_parser() -> @talc.StringParser[Array[String]] {
  let participant = inline_spaces().then(
    quoted_participant().attempt().or(participant_identifier()),
  )
  let separator = inline_spaces()
    .then(@talc.char(','))
    .skip(inline_spaces())
    .attempt()
  participant.sep_by1(separator)
}

///|
fn participant_identifier() -> @talc.StringParser[String] {
  @talc.many_chars1(@talc.satisfy("participant identifier", is_ident_char))
}

///|
fn quoted_participant() -> @talc.StringParser[String] {
  @talc.char('"')
  .then(@talc.many_chars(@talc.none_of("\"")))
  .skip(@talc.char('"'))
}

///|
fn as_keyword() -> @talc.StringParser[Unit] {
  @talc.string("as")
  .skip(
    @talc.satisfy("identifier character", is_ident_char).not_followed_by(
      "identifier character",
    ),
  )
  .map(_ => ())
}

///|
fn participant_alias_code() -> @talc.StringParser[String] {
  inline_spaces()
  .then(as_keyword())
  .then(inline_spaces())
  .then(participant_identifier())
}

///|
fn participant_alias_display() -> @talc.StringParser[String] {
  inline_spaces()
  .then(as_keyword())
  .then(inline_spaces())
  .then(quoted_participant().attempt().or(participant_identifier()))
}

///|
fn participant_ref_parser() -> @talc.StringParser[PartRef] {
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
fn participant_decl_ref_parser() -> @talc.StringParser[PartRef] {
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
  let unquoted = participant_identifier().bind(name => {
    let quoted_display = inline_spaces()
      .then(as_keyword())
      .then(inline_spaces())
      .then(quoted_participant())
      .map(display => { code: name, display })
    let alias_code = participant_alias_code()
      .attempt()
      .map(participant_code => { code: participant_code, display: name })
    quoted_display
    .attempt()
    .or(alias_code)
    .optional()
    .map(reference => reference.unwrap_or({ code: name, display: name }))
  })
  quoted.attempt().or(unquoted)
}

///|
fn participant_code_parser() -> @talc.StringParser[String] {
  quoted_participant().attempt().or(participant_identifier())
}

///|
fn optional_arrow_index() -> @talc.StringParser[Unit] {
  @talc.char('(')
  .then(@talc.ascii_digit().many())
  .skip(@talc.char(')'))
  .attempt()
  .optional()
  .map(_ => ())
}

///|
fn left_arrow_head() -> @talc.StringParser[(ArrowHead, ArrowPart)] {
  let left = @talc.char('<').bind(_ => {
    @talc.char('<')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, Full))
  })
  let top = @talc.char('/').bind(_ => {
    @talc.char('/')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, TopPart))
  })
  let bottom = @talc.char('\\').bind(_ => {
    @talc.char('\\')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, BottomPart))
  })
  @talc.choice([left, top, bottom]).or(@talc.pure((NoneHead, Full)))
}

///|
fn right_arrow_head() -> @talc.StringParser[(ArrowHead, ArrowPart)] {
  let right = @talc.char('>').bind(_ => {
    @talc.char('>')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, Full))
  })
  let bottom = @talc.char('/').bind(_ => {
    @talc.char('/')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, BottomPart))
  })
  let top = @talc.char('\\').bind(_ => {
    @talc.char('\\')
    .optional()
    .map(next => (if next is Some(_) { Async } else { Normal }, TopPart))
  })
  @talc.choice([right, bottom, top]).or(@talc.pure((NoneHead, Full)))
}

///|
fn left_dressing_parser() -> @talc.StringParser[DressingResult] {
  @talc.char('o')
  .optional()
  .bind(circle => {
    @talc.char('x')
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
fn right_dressing_parser() -> @talc.StringParser[DressingResult] {
  @talc.char('_')
  .optional()
  .bind(_ => {
    right_arrow_head().bind(head_and_part => {
      @talc.char('o')
      .optional()
      .bind(circle => {
        @talc.char('x')
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
fn arrow_dressing_parser() -> @talc.StringParser[
  (DressingResult, ArrowBody, DressingResult),
] {
  let dashes = @talc.many_chars(@talc.char('-'))
  let style = @talc.char('[')
    .then(@talc.many_chars(@talc.none_of("]")))
    .skip(@talc.char(']'))
    .attempt()
    .optional()
  left_dressing_parser().bind(left => {
    dashes.bind(first => {
      style
      .then(dashes)
      .bind(second => {
        guard first.length() + second.length() > 0 else {
          return @talc.fail("arrow body")
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
fn activation_spec_parser() -> @talc.StringParser[ActivationSpec] {
  @talc.choice([
    @talc.string("++").map(_ => Activate),
    @talc.string("--").map(_ => Deactivate),
    @talc.string("!!").map(_ => Destroy),
    @talc.string("**").map(_ => Create),
  ])
}

///|
fn multicast_parser() -> @talc.StringParser[Array[String]] {
  @talc.char('&')
  .then(inline_spaces())
  .then(participant_identifier())
  .skip(inline_spaces())
  .some()
}

///|
fn color_parser() -> @talc.StringParser[String] {
  @talc.char('#').then(
    @talc.many_chars1(
      @talc.satisfy("color", char => !is_inline_whitespace(char) && char != '\n'),
    ),
  )
}

///|
fn anchor_parser() -> @talc.StringParser[String] {
  @talc.char('{').then(participant_identifier()).skip(@talc.char('}'))
}

///|
fn quoted_string_parser() -> @talc.StringParser[String] {
  @talc.char('"')
  .then(@talc.many_chars(@talc.none_of("\"")))
  .skip(@talc.char('"'))
}
