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
fn note_position_parser() -> @talc.StringParser[NotePosition] {
  inline_word_parser("note position").bind(word => {
    match note_position(word) {
      Some(position) => @talc.pure(position)
      None => @talc.fail("note position")
    }
  })
}

///|
fn note_name_parser(label : String) -> @talc.StringParser[String] {
  let plain = @talc.many_chars1(
    @talc.satisfy(label, char => {
      !char.is_whitespace() &&
      char != ':' &&
      char != '#' &&
      char != '$' &&
      char != '<' &&
      char != '[' &&
      char != '{'
    }),
  )
  @core.quoted_value_parser().attempt().or(plain).map(@core.unquote_identifier)
}

///|
fn note_entity_name_parser() -> @talc.StringParser[String] {
  note_name_parser("note entity").bind(name => {
    if name.equal_ignore_ascii_case("of") {
      @talc.fail("note entity")
    } else {
      @talc.pure(name)
    }
  })
}

///|
fn note_member_name_parser() -> @talc.StringParser[String] {
  @talc.many_chars1(
    @talc.satisfy("note member", char => {
      !char.is_whitespace() &&
      char != '#' &&
      char != '$' &&
      char != '<' &&
      char != '[' &&
      char != '{'
    }),
  ).map(@core.unquote_identifier)
}

///|
fn note_metadata_item_parser() -> @talc.StringParser[NoteMetadataItemSyntax] {
  @talc.choice([
    @core.url_value_parser().attempt().map(value => NoteUrl(value)),
    @core.stereotype_value_parser().attempt().map(value => NoteStereotype(value)),
    @core.color_value_parser("note color").attempt().map(value => NoteColor(value)),
    @core.tag_value_parser("note tag").map(value => NoteTag(value)),
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
fn note_metadata_parser() -> @talc.StringParser[NoteMetadataSyntax] {
  inline_space1()
  .then(note_metadata_item_parser())
  .attempt()
  .many()
  .bind(items => {
    inline_spaces()
    .then(@talc.char('{'))
    .attempt()
    .optional()
    .map(brace => note_metadata_from(items, brace is Some(_)))
  })
}

///|
fn note_content_parser() -> @talc.StringParser[NoteContentSyntax] {
  inline_spaces()
  .then(@talc.char(':'))
  .skip(@talc.char(':').not_followed_by("qualified member"))
  .then(
    inline_spaces().then(
      @talc.many_chars(@talc.satisfy("note text", _ => true)),
    ),
  )
  .map(text => NoteInline(text.trim().to_owned()))
  .attempt()
  .optional()
  .map(content => content.unwrap_or(NoteBlock))
}

///|
fn named_note_tail_parser() -> @talc.StringParser[NoteLineSyntax] {
  let multiline = inline_keyword_parser("as")
    .then(inline_space1())
    .then(note_name_parser("named note code"))
    .map(code => (code, NoteBlock))
  let inline = @core.quoted_value_parser().bind(text => {
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
fn link_note_tail_parser() -> @talc.StringParser[NoteLineSyntax] {
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
fn member_note_tail_parser() -> @talc.StringParser[NoteLineSyntax] {
  note_position_parser().bind(position => {
    guard position is Left || position is Right else {
      return @talc.fail("member note position")
    }
    inline_space1()
    .then(inline_keyword_parser("of"))
    .then(inline_space1())
    .then(note_entity_name_parser())
    .bind(entity => {
      @talc.string("::")
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
fn entity_note_target_parser() -> @talc.StringParser[String?] {
  let explicit = inline_space1()
    .then(inline_keyword_parser("of"))
    .then(inline_space1())
    .then(note_entity_name_parser())
  let implicit = inline_space1().then(note_entity_name_parser())
  explicit.attempt().or(implicit).attempt().optional()
}

///|
fn entity_note_tail_parser() -> @talc.StringParser[NoteLineSyntax] {
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
fn note_line_parser() -> @talc.StringParser[ClassAnnotationLineSyntax] {
  inline_keyword_parser("note")
  .then(inline_space1())
  .then(
    @talc.choice([
      named_note_tail_parser().attempt(),
      link_note_tail_parser().attempt(),
      member_note_tail_parser().attempt(),
      entity_note_tail_parser(),
    ]),
  )
  .skip(inline_spaces())
  .skip(@talc.eof())
  .map(note => ParsedClassNote(note))
}

///|
fn link_constraint_line_parser() -> @talc.StringParser[
  ClassAnnotationLineSyntax,
] {
  inline_keyword_parser("constraint")
  .then(inline_space1())
  .then(inline_keyword_parser("on"))
  .then(inline_space1())
  .then(inline_keyword_parser("links"))
  .then(
    inline_space1()
    .then(@core.color_value_parser("constraint color"))
    .attempt()
    .optional(),
  )
  .bind(color => {
    inline_spaces()
    .then(@talc.char(':'))
    .then(inline_spaces())
    .then(@talc.many_chars(@talc.satisfy("constraint text", _ => true)))
    .map(text => ParsedLinkConstraint({ text: text.trim().to_owned(), color }))
  })
  .skip(@talc.eof())
}

///|
fn class_annotation_line_parser() -> @talc.StringParser[
  ClassAnnotationLineSyntax,
] {
  note_line_parser().attempt().or(link_constraint_line_parser())
}

///|
test "class note line grammar accepts complete annotation lines" {
  let lines = [
    "note right of User : authenticated user", "note bottom of User <<warning>> [[https://example.com/note]] #pink {",
    "note right on link #yellow : sync", "note of link", "note left of User::login() #lightblue",
    "note \"shared note\" as N1 $shared <<info>> #yellow", "note as N2 {", "constraint on links #pink : {xor}",
  ]
  for line in lines {
    guard class_annotation_line_parser().parse(@talc.Input::new(line)) is Ok(_) else {
      @test.fail("expected annotation syntax: \{line}")
    }
  }
}

///|
test "class note line grammar rejects trailing or incomplete syntax" {
  let lines = [
    "note right of", "note sideways of User", "note left of User::", "constraint on links #pink",
    "note right of User unexpected metadata",
  ]
  for line in lines {
    guard class_annotation_line_parser().parse(@talc.Input::new(line)) is Err(_) else {
      @test.fail("unexpected annotation syntax: \{line}")
    }
  }
}

///|
fn Parser::push_note_syntax(
  self : Parser,
  syntax : NoteLineSyntax,
  text : String,
) -> Unit raise @core.ParseError {
  let mut target = ""
  let mut target_kind = EntityNote
  let mut relation_index = None
  let mut member_name = None
  let mut code = None
  match syntax.target {
    NoteLinkTarget => {
      guard !self.relations.is_empty() else {
        self.raise_parse_error("no link defined")
      }
      target_kind = LinkNote
      relation_index = Some(self.relations.length() - 1)
    }
    NoteMemberTarget(entity~, entry~) => {
      target = self.resolve(entity)
      guard self.has_entity(target) else {
        self.raise_parse_error("nothing to note to")
      }
      target_kind = MemberTip
      member_name = Some(entry)
    }
    NoteEntityTarget(entity) =>
      target = match entity {
        Some(value) => self.ensure_entity(value)
        None =>
          match self.last_entity {
            Some(value) => value
            None => {
              self.raise_parse_error("nothing to note to")
              ""
            }
          }
      }
    NoteFloatingTarget(note_code) => {
      let existing = self.resolve(note_code)
      guard !self.has_entity(existing) else {
        self.raise_parse_error("note already created: \{note_code}")
      }
      target = self.ensure_entity_as(note_code, NamedNote)
      target_kind = FloatingNote
      code = Some(target)
    }
  }
  self.notes.push({
    target,
    position: syntax.position,
    text,
    target_kind,
    relation_index,
    member_name,
    code,
    color: syntax.metadata.color,
    url: syntax.metadata.url,
    stereotype: syntax.metadata.stereotype,
    tags: syntax.metadata.tags,
  })
}

///|
fn Parser::consume_note_syntax(
  self : Parser,
  syntax : NoteLineSyntax,
) -> Unit raise @core.ParseError {
  match syntax.content {
    NoteInline(text) => self.push_note_syntax(syntax, text)
    NoteBlock => {
      let text = StringBuilder()
      let mut first = true
      self.index += 1
      while self.index < self.lines.length() {
        let line = self.lines[self.index]
        let terminator = @core.strip_line_comment(line).to_lower()
        if terminator == "end note" ||
          terminator == "endnote" ||
          (syntax.metadata.braced && terminator == "}") {
          guard !first else { self.raise_parse_error("no note defined") }
          self.push_note_syntax(syntax, text.to_string())
          return
        }
        if !first {
          text.write_char('\n')
        }
        text.write_string(line.trim().to_owned())
        first = false
        self.index += 1
      }
      self.raise_parse_error("unclosed note")
    }
  }
}

///|
fn Parser::apply_annotation_syntax(
  self : Parser,
  syntax : ClassAnnotationLineSyntax,
) -> Unit raise @core.ParseError {
  match syntax {
    ParsedClassNote(note) => self.consume_note_syntax(note)
    ParsedLinkConstraint(constraint) =>
      if self.relations.length() >= 2 {
        self.constraints.push({
          first_relation: self.relations.length() - 2,
          second_relation: self.relations.length() - 1,
          text: constraint.text,
          color: constraint.color,
        })
      }
  }
}
