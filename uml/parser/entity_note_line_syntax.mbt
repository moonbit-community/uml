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
priv struct EntityNoteLineSyntax {
  target : NoteTargetSyntax
  position : @entity.NotePosition
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
  ParsedClassNote(EntityNoteLineSyntax)
  ParsedLinkConstraint(LinkConstraintLineSyntax)
}

///|
fn note_position_syntax(cursor : @tokenizer.Cursor) -> @entity.NotePosition? {
  cursor.attempt(cursor => {
    guard take_inline_word(cursor) is Some(word) else { return None }
    entity_note_position(word)
  })
}

///|
fn note_name(cursor : @tokenizer.Cursor) -> String? {
  let value = match cursor.take_quoted_value() {
    Some(value) => value
    None => {
      let value = cursor.take_while(char => {
        !char.is_whitespace() &&
        char != ':' &&
        char != '#' &&
        char != '$' &&
        char != '<' &&
        char != '[' &&
        char != '{'
      })
      guard value.length() > 0 else { return None }
      value
    }
  }
  Some(@tokenizer.unquote_identifier(value))
}

///|
fn note_entity_name(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    guard note_name(cursor) is Some(name) else { return None }
    if name.equal_ignore_ascii_case("of") {
      None
    } else {
      Some(name)
    }
  })
}

///|
fn note_member_name(cursor : @tokenizer.Cursor) -> String? {
  let value = cursor.take_while(char => {
    !char.is_whitespace() &&
    char != '#' &&
    char != '$' &&
    char != '<' &&
    char != '[' &&
    char != '{'
  })
  if value.length() == 0 {
    None
  } else {
    Some(@tokenizer.unquote_identifier(value))
  }
}

///|
fn note_metadata_item(cursor : @tokenizer.Cursor) -> NoteMetadataItemSyntax? {
  if cursor.take_url_value() is Some(value) {
    return Some(NoteUrl(value))
  }
  if cursor.take_stereotype_value() is Some(value) {
    return Some(NoteStereotype(value))
  }
  if cursor.take_color_value() is Some(value) {
    return Some(NoteColor(value))
  }
  if cursor.take_tag_value() is Some(value) {
    return Some(NoteTag(value))
  }
  None
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
  { color, url, stereotype, tags, braced, }
}

///|
fn note_metadata(cursor : @tokenizer.Cursor) -> NoteMetadataSyntax {
  let items = collect_repeated(cursor, note_metadata_item)
  cursor.skip_inline_spaces()
  let braced = cursor.consume('{')
  note_metadata_from(items, braced)
}

///|
fn note_content(cursor : @tokenizer.Cursor) -> NoteContentSyntax {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  if cursor.consume(':') && cursor.peek() != Some(':') {
    cursor.skip_inline_spaces()
    NoteInline(cursor.take_rest_trimmed())
  } else {
    ignore(cursor.restore(start))
    NoteBlock
  }
}

///|
/// The shared `as name` suffix. Missing or incomplete aliases consume nothing.
fn note_alias(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    guard consume_inline_keyword(cursor, "as") && cursor.skip_inline_space1() else {
      return None
    }
    note_name(cursor)
  })
}

///|
fn named_note_tail(cursor : @tokenizer.Cursor) -> EntityNoteLineSyntax? {
  // A quoted label remains consumed if its alias fails. The block alternative
  // starts after that label, as in the existing PlantUML-compatible grammar.
  let inline = if cursor.take_quoted_value() is Some(text) {
    cursor.attempt(cursor => {
      guard cursor.skip_inline_space1() else { return None }
      note_alias(cursor).map(code => (code, NoteContentSyntax::NoteInline(text)))
    })
  } else {
    None
  }
  let value = if inline is Some(pair) {
    Some(pair)
  } else {
    note_alias(cursor).map(code => (code, NoteContentSyntax::NoteBlock))
  }
  guard value is Some((code, content)) else { return None }
  let metadata = note_metadata(cursor)
  Some({ target: NoteFloatingTarget(code), position: Right, content, metadata, })
}

///|
fn link_note_tail(cursor : @tokenizer.Cursor) -> EntityNoteLineSyntax? {
  cursor.attempt(cursor => {
    let pos_start = cursor.offset()
    let position = if note_position_syntax(cursor) is Some(value) &&
      cursor.skip_inline_space1() {
      Some(value)
    } else {
      ignore(cursor.restore(pos_start))
      None
    }
    guard (
        consume_inline_keyword(cursor, "on") ||
        consume_inline_keyword(cursor, "of")
      ) &&
      cursor.skip_inline_space1() &&
      consume_inline_keyword(cursor, "link") else {
      return None
    }
    let metadata = note_metadata(cursor)
    let content = note_content(cursor)
    Some({
      target: NoteLinkTarget,
      position: position.unwrap_or(Bottom),
      content,
      metadata,
    })
  })
}

///|
fn member_note_tail(cursor : @tokenizer.Cursor) -> EntityNoteLineSyntax? {
  cursor.attempt(cursor => {
    guard note_position_syntax(cursor) is Some(position) else { return None }
    guard position is Left || position is Right else { return None }
    guard cursor.skip_inline_space1() &&
      consume_inline_keyword(cursor, "of") &&
      cursor.skip_inline_space1() else {
      return None
    }
    guard note_entity_name(cursor) is Some(entity) else { return None }
    guard cursor.consume_literal("::") else { return None }
    guard note_member_name(cursor) is Some(entry) else { return None }
    let metadata = note_metadata(cursor)
    Some({
      target: NoteMemberTarget(entity~, entry~),
      position,
      content: NoteBlock,
      metadata,
    })
  })
}

///|
fn entity_note_target(cursor : @tokenizer.Cursor) -> String? {
  let start = cursor.offset()
  if cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "of") &&
    cursor.skip_inline_space1() &&
    note_entity_name(cursor) is Some(name) {
    return Some(name)
  }
  ignore(cursor.restore(start))
  if cursor.skip_inline_space1() {
    if note_entity_name(cursor) is Some(name) {
      return Some(name)
    }
    ignore(cursor.restore(start))
  }
  None
}

///|
fn entity_note_tail(cursor : @tokenizer.Cursor) -> EntityNoteLineSyntax? {
  guard note_position_syntax(cursor) is Some(position) else { return None }
  let target = entity_note_target(cursor)
  let metadata = note_metadata(cursor)
  let content = note_content(cursor)
  Some({ target: NoteEntityTarget(target), position, content, metadata, })
}

///|
fn note_line(cursor : @tokenizer.Cursor) -> ClassAnnotationLineSyntax? {
  cursor.attempt(cursor => {
    guard consume_inline_keyword(cursor, "note") && cursor.skip_inline_space1() else {
      return None
    }
    let tail = if named_note_tail(cursor) is Some(value) {
      Some(value)
    } else if link_note_tail(cursor) is Some(value) {
      Some(value)
    } else if member_note_tail(cursor) is Some(value) {
      Some(value)
    } else {
      entity_note_tail(cursor)
    }
    guard tail is Some(note) else { return None }
    cursor.skip_inline_spaces()
    guard cursor.is_eof() else { return None }
    Some(ParsedClassNote(note))
  })
}

///|
fn link_constraint_line(
  cursor : @tokenizer.Cursor,
) -> ClassAnnotationLineSyntax? {
  cursor.attempt(cursor => {
    guard consume_inline_keyword(cursor, "constraint") &&
      cursor.skip_inline_space1() &&
      consume_inline_keyword(cursor, "on") &&
      cursor.skip_inline_space1() &&
      consume_inline_keyword(cursor, "links") else {
      return None
    }
    let color = if cursor.skip_inline_space1() {
      cursor.take_color_value()
    } else {
      None
    }
    cursor.skip_inline_spaces()
    guard cursor.consume(':') else { return None }
    cursor.skip_inline_spaces()
    let text = cursor.take_rest_trimmed()
    Some(ParsedLinkConstraint({ text, color, }))
  })
}

///|
fn class_annotation_line(
  cursor : @tokenizer.Cursor,
) -> ClassAnnotationLineSyntax? {
  guard note_line(cursor) is Some(value) else {
    return link_constraint_line(cursor)
  }
  Some(value)
}

///|
test "class note line grammar accepts complete annotation lines" {
  let lines = [
    "note right of User : authenticated user", "note bottom of User <<warning>> [[https://example.com/note]] #pink {",
    "note right on link #yellow : sync", "note of link", "note left of User::login() #lightblue",
    "note \"shared note\" as N1 $shared <<info>> #yellow", "note as N2 {", "constraint on links #pink : {xor}",
  ]
  for line in lines {
    let cursor = @tokenizer.Cursor::new(line)
    guard class_annotation_line(cursor) is Some(_) else {
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
    let cursor = @tokenizer.Cursor::new(line)
    guard class_annotation_line(cursor) is None else {
      @test.fail("unexpected annotation syntax: \{line}")
    }
  }
}

///|
fn EntityParser::push_note_syntax(
  self : EntityParser,
  syntax : EntityNoteLineSyntax,
  text : String,
) -> Unit raise @tokenizer.ParseError {
  let mut target = ""
  let mut target_kind = @entity.NoteTargetKind::EntityNote
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
        None => {
          guard self.last_entity is Some(value) else {
            self.raise_parse_error("nothing to note to")
            ""
          }
          value
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
fn EntityParser::consume_note_syntax(
  self : EntityParser,
  syntax : EntityNoteLineSyntax,
) -> Unit raise @tokenizer.ParseError {
  match syntax.content {
    NoteInline(text) => self.push_note_syntax(syntax, text)
    NoteBlock => {
      let mut index = self.buffer.index + 1
      guard @tokenizer.collect_lines_until(
          () => {
            guard index < self.buffer.lines.length() else { return None }
            let line = self.buffer.lines[index]
            index += 1
            Some(line)
          },
          line => {
            let normalized = @tokenizer.strip_line_comment(line).to_lower()
            normalized == "end note" ||
            normalized == "endnote" ||
            (syntax.metadata.braced && normalized == "}")
          },
        )
        is Some(lines) else {
        self.raise_parse_error("unclosed note")
      }
      guard !lines.is_empty() else { self.raise_parse_error("no note defined") }
      self.buffer.index = index - 1
      self.push_note_syntax(
        syntax,
        lines.map(line => line.trim().to_owned()).join("\n"),
      )
    }
  }
}

///|
fn EntityParser::apply_annotation_syntax(
  self : EntityParser,
  syntax : ClassAnnotationLineSyntax,
) -> Unit raise @tokenizer.ParseError {
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
