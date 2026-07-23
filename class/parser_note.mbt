///|
fn Parser::push_note_syntax(
  self : Parser,
  syntax : NoteLineSyntax,
  text : String,
) -> Unit raise ParseError {
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
      guard self.entities.any(item => item.qualified_code == target) else {
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
      guard !self.entities.any(item => item.qualified_code == existing) else {
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
) -> Unit raise ParseError {
  match syntax.content {
    NoteInline(text) => self.push_note_syntax(syntax, text)
    NoteBlock => {
      let text = StringBuilder()
      let mut first = true
      self.index += 1
      while self.index < self.lines.length() {
        let line = self.lines[self.index]
        let terminator = strip_comment(line).to_lower()
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
        text.write_string(line)
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
) -> Unit raise ParseError {
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
