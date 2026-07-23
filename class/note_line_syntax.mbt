///|
priv enum NoteMetadataItemSyntax {
  NoteColor(String)
  NoteUrl(String)
  NoteStereotype(String)
  NoteTag(String)
}

///|
priv struct NoteMetadataSyntax {
  color : String?
  url : String?
  stereotype : String?
  tags : Array[String]
  braced : Bool
}

///|
priv enum NoteTargetSyntax {
  NoteLinkTarget
  NoteMemberTarget(entity~ : String, entry~ : String)
  NoteEntityTarget(String?)
  NoteFloatingTarget(String)
}

///|
priv enum NoteContentSyntax {
  NoteInline(String)
  NoteBlock
}

///|
priv struct NoteLineSyntax {
  target : NoteTargetSyntax
  position : NotePosition
  content : NoteContentSyntax
  metadata : NoteMetadataSyntax
}

///|
priv struct LinkConstraintLineSyntax {
  text : String
  color : String?
}

///|
priv enum ClassAnnotationLineSyntax {
  ParsedClassNote(NoteLineSyntax)
  ParsedLinkConstraint(LinkConstraintLineSyntax)
}

///|
fn note_position_parser() -> @talcparsec.StringParser[NotePosition] {
  inline_word_parser("note position").bind(word => {
    match note_position(word) {
      Some(position) => @talcparsec.pure(position)
      None => @talcparsec.fail("note position")
    }
  })
}

///|
fn note_name_parser(label : String) -> @talcparsec.StringParser[String] {
  let plain = @talcparsec.many_chars1(
    @talcparsec.satisfy(label, char => {
      !char.is_whitespace() &&
      char != ':' &&
      char != '#' &&
      char != '$' &&
      char != '<' &&
      char != '[' &&
      char != '{'
    }),
  )
  quoted_value_parser().attempt().or(plain).map(normalize_name)
}

///|
fn note_entity_name_parser() -> @talcparsec.StringParser[String] {
  note_name_parser("note entity").bind(name => {
    if name.equal_ignore_ascii_case("of") {
      @talcparsec.fail("note entity")
    } else {
      @talcparsec.pure(name)
    }
  })
}

///|
fn note_member_name_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.many_chars1(
    @talcparsec.satisfy("note member", char => {
      !char.is_whitespace() &&
      char != '#' &&
      char != '$' &&
      char != '<' &&
      char != '[' &&
      char != '{'
    }),
  ).map(normalize_name)
}

///|
fn note_metadata_item_parser() -> @talcparsec.StringParser[
  NoteMetadataItemSyntax,
] {
  @talcparsec.choice([
    url_value_parser().attempt().map(value => NoteUrl(value)),
    stereotype_value_parser().attempt().map(value => NoteStereotype(value)),
    color_value_parser("note color").attempt().map(value => NoteColor(value)),
    tag_value_parser("note tag").map(value => NoteTag(value)),
  ])
}

///|
fn note_metadata_from(
  items : Array[NoteMetadataItemSyntax],
  braced : Bool,
) -> NoteMetadataSyntax {
  let mut color = None
  let mut url = None
  let mut stereotype = None
  let tags = []
  for item in items {
    match item {
      NoteColor(value) => color = Some(value)
      NoteUrl(value) => url = Some(value)
      NoteStereotype(value) => stereotype = Some(value)
      NoteTag(value) => tags.push(value)
    }
  }
  { color, url, stereotype, tags, braced }
}

///|
fn note_metadata_parser() -> @talcparsec.StringParser[NoteMetadataSyntax] {
  inline_space1()
  .then(note_metadata_item_parser())
  .attempt()
  .many()
  .bind(items => {
    inline_spaces()
    .then(@talcparsec.char('{'))
    .attempt()
    .optional()
    .map(brace => note_metadata_from(items, brace is Some(_)))
  })
}

///|
fn note_content_parser() -> @talcparsec.StringParser[NoteContentSyntax] {
  inline_spaces()
  .then(@talcparsec.char(':'))
  .skip(@talcparsec.char(':').not_followed_by("qualified member"))
  .then(
    inline_spaces().then(
      @talcparsec.many_chars(@talcparsec.satisfy("note text", _ => true)),
    ),
  )
  .map(text => NoteInline(text.trim().to_owned()))
  .attempt()
  .optional()
  .map(content => content.unwrap_or(NoteBlock))
}

///|
fn named_note_tail_parser() -> @talcparsec.StringParser[NoteLineSyntax] {
  let multiline = inline_keyword_parser("as")
    .then(inline_space1())
    .then(note_name_parser("named note code"))
    .map(code => (code, NoteBlock))
  let inline = quoted_value_parser().bind(text => {
    inline_space1()
    .then(inline_keyword_parser("as"))
    .then(inline_space1())
    .then(note_name_parser("named note code"))
    .map(code => (code, NoteInline(text)))
  })
  inline
  .attempt()
  .or(multiline)
  .bind(value => {
    let (code, content) = value
    note_metadata_parser().map(metadata => {
      target: NoteFloatingTarget(code),
      position: Right,
      content,
      metadata,
    })
  })
}

///|
fn link_note_tail_parser() -> @talcparsec.StringParser[NoteLineSyntax] {
  note_position_parser()
  .skip(inline_space1())
  .attempt()
  .optional()
  .bind(position => {
    inline_keyword_parser("on")
    .attempt()
    .or(inline_keyword_parser("of"))
    .skip(inline_space1())
    .then(inline_keyword_parser("link"))
    .then(note_metadata_parser())
    .bind(metadata => {
      note_content_parser().map(content => {
        target: NoteLinkTarget,
        position: position.unwrap_or(Bottom),
        content,
        metadata,
      })
    })
  })
}

///|
fn member_note_tail_parser() -> @talcparsec.StringParser[NoteLineSyntax] {
  note_position_parser().bind(position => {
    guard position is Left || position is Right else {
      return @talcparsec.fail("member note position")
    }
    inline_space1()
    .then(inline_keyword_parser("of"))
    .then(inline_space1())
    .then(note_entity_name_parser())
    .bind(entity => {
      @talcparsec.string("::")
      .then(note_member_name_parser())
      .bind(entry => {
        note_metadata_parser().map(metadata => {
          target: NoteMemberTarget(entity~, entry~),
          position,
          content: NoteBlock,
          metadata,
        })
      })
    })
  })
}

///|
fn entity_note_target_parser() -> @talcparsec.StringParser[String?] {
  let explicit = inline_space1()
    .then(inline_keyword_parser("of"))
    .then(inline_space1())
    .then(note_entity_name_parser())
  let implicit = inline_space1().then(note_entity_name_parser())
  explicit.attempt().or(implicit).attempt().optional()
}

///|
fn entity_note_tail_parser() -> @talcparsec.StringParser[NoteLineSyntax] {
  note_position_parser().bind(position => {
    entity_note_target_parser().bind(target => {
      note_metadata_parser().bind(metadata => {
        note_content_parser().map(content => {
          target: NoteEntityTarget(target),
          position,
          content,
          metadata,
        })
      })
    })
  })
}

///|
fn note_line_parser() -> @talcparsec.StringParser[ClassAnnotationLineSyntax] {
  inline_keyword_parser("note")
  .then(inline_space1())
  .then(
    @talcparsec.choice([
      named_note_tail_parser().attempt(),
      link_note_tail_parser().attempt(),
      member_note_tail_parser().attempt(),
      entity_note_tail_parser(),
    ]),
  )
  .skip(inline_spaces())
  .skip(@talcparsec.eof())
  .map(note => ParsedClassNote(note))
}

///|
fn link_constraint_line_parser() -> @talcparsec.StringParser[
  ClassAnnotationLineSyntax,
] {
  inline_keyword_parser("constraint")
  .then(inline_space1())
  .then(inline_keyword_parser("on"))
  .then(inline_space1())
  .then(inline_keyword_parser("links"))
  .then(
    inline_space1()
    .then(color_value_parser("constraint color"))
    .attempt()
    .optional(),
  )
  .bind(color => {
    inline_spaces()
    .then(@talcparsec.char(':'))
    .then(inline_spaces())
    .then(
      @talcparsec.many_chars(@talcparsec.satisfy("constraint text", _ => true)),
    )
    .map(text => ParsedLinkConstraint({ text: text.trim().to_owned(), color }))
  })
  .skip(@talcparsec.eof())
}

///|
fn class_annotation_line_parser() -> @talcparsec.StringParser[
  ClassAnnotationLineSyntax,
] {
  note_line_parser().attempt().or(link_constraint_line_parser())
}

///|
fn parse_class_annotation_line(line : String) -> ClassAnnotationLineSyntax? {
  match class_annotation_line_parser().parse(@talcparsec.Input::new(line)) {
    Ok(syntax) => Some(syntax)
    Err(_) => None
  }
}
