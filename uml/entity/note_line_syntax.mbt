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
fn note_position_syntax(cursor : @parse.Cursor) -> NotePosition? {
  let start = cursor.offset()
  guard take_inline_word(cursor) is Some(word) else { return None }
  match note_position(word) {
    Some(position) => Some(position)
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn note_name(cursor : @parse.Cursor) -> String? {
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
  Some(@parse.unquote_identifier(value))
}

///|
fn note_entity_name(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard note_name(cursor) is Some(name) else { return None }
  if name.equal_ignore_ascii_case("of") {
    ignore(cursor.restore(start))
    None
  } else {
    Some(name)
  }
}

///|
fn note_member_name(cursor : @parse.Cursor) -> String? {
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
    Some(@parse.unquote_identifier(value))
  }
}

///|
fn note_metadata_item(cursor : @parse.Cursor) -> NoteMetadataItemSyntax? {
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
  { color, url, stereotype, tags, braced }
}

///|
fn note_metadata(cursor : @parse.Cursor) -> NoteMetadataSyntax {
  let items = []
  while true {
    let item_start = cursor.offset()
    guard cursor.skip_inline_space1() &&
      note_metadata_item(cursor) is Some(item) else {
      ignore(cursor.restore(item_start))
      break
    }
    items.push(item)
  }
  let brace_start = cursor.offset()
  cursor.skip_inline_spaces()
  let braced = cursor.consume('{')
  if !braced {
    ignore(cursor.restore(brace_start))
  }
  note_metadata_from(items, braced)
}

///|
fn note_content(cursor : @parse.Cursor) -> NoteContentSyntax {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  if cursor.consume(':') && cursor.peek() != Some(':') {
    cursor.skip_inline_spaces()
    NoteInline(cursor.take_while(_ => true).trim().to_owned())
  } else {
    ignore(cursor.restore(start))
    NoteBlock
  }
}

///|
fn named_note_tail(cursor : @parse.Cursor) -> NoteLineSyntax? {
  let inline = match cursor.take_quoted_value() {
    Some(text) => {
      let as_start = cursor.offset()
      if cursor.skip_inline_space1() &&
        consume_inline_keyword(cursor, "as") &&
        cursor.skip_inline_space1() {
        match note_name(cursor) {
          Some(code) => Some((code, NoteInline(text)))
          None => {
            ignore(cursor.restore(as_start))
            None
          }
        }
      } else {
        ignore(cursor.restore(as_start))
        None
      }
    }
    None => None
  }
  let value = match inline {
    Some(pair) => Some(pair)
    None => {
      let as_start = cursor.offset()
      if consume_inline_keyword(cursor, "as") && cursor.skip_inline_space1() {
        match note_name(cursor) {
          Some(code) => Some((code, NoteBlock))
          None => {
            ignore(cursor.restore(as_start))
            None
          }
        }
      } else {
        ignore(cursor.restore(as_start))
        None
      }
    }
  }
  match value {
    Some((code, content)) => {
      let metadata = note_metadata(cursor)
      Some({
        target: NoteFloatingTarget(code),
        position: Right,
        content,
        metadata,
      })
    }
    None => None
  }
}

///|
fn link_note_tail(cursor : @parse.Cursor) -> NoteLineSyntax? {
  let start = cursor.offset()
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
    ignore(cursor.restore(start))
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
}

///|
fn member_note_tail(cursor : @parse.Cursor) -> NoteLineSyntax? {
  let start = cursor.offset()
  guard note_position_syntax(cursor) is Some(position) else { return None }
  guard position is Left || position is Right else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "of") &&
    cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard note_entity_name(cursor) is Some(entity) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume_literal("::") else {
    ignore(cursor.restore(start))
    return None
  }
  guard note_member_name(cursor) is Some(entry) else {
    ignore(cursor.restore(start))
    return None
  }
  let metadata = note_metadata(cursor)
  Some({
    target: NoteMemberTarget(entity~, entry~),
    position,
    content: NoteBlock,
    metadata,
  })
}

///|
fn entity_note_target(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  let explicit_start = cursor.offset()
  if cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "of") &&
    cursor.skip_inline_space1() {
    if note_entity_name(cursor) is Some(name) {
      return Some(name)
    }
    ignore(cursor.restore(explicit_start))
  } else {
    ignore(cursor.restore(explicit_start))
  }
  if cursor.skip_inline_space1() {
    if note_entity_name(cursor) is Some(name) {
      return Some(name)
    }
    ignore(cursor.restore(start))
  }
  None
}

///|
fn entity_note_tail(cursor : @parse.Cursor) -> NoteLineSyntax? {
  guard note_position_syntax(cursor) is Some(position) else { return None }
  let target = entity_note_target(cursor)
  let metadata = note_metadata(cursor)
  let content = note_content(cursor)
  Some({ target: NoteEntityTarget(target), position, content, metadata })
}

///|
fn note_line(cursor : @parse.Cursor) -> ClassAnnotationLineSyntax? {
  let start = cursor.offset()
  guard consume_inline_keyword(cursor, "note") && cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
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
  guard tail is Some(note) else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(ParsedClassNote(note))
}

///|
fn link_constraint_line(cursor : @parse.Cursor) -> ClassAnnotationLineSyntax? {
  let start = cursor.offset()
  guard consume_inline_keyword(cursor, "constraint") &&
    cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "on") &&
    cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "links") else {
    ignore(cursor.restore(start))
    return None
  }
  let color_start = cursor.offset()
  let color = if cursor.skip_inline_space1() {
    match cursor.take_color_value() {
      Some(value) => Some(value)
      None => {
        ignore(cursor.restore(color_start))
        None
      }
    }
  } else {
    ignore(cursor.restore(color_start))
    None
  }
  cursor.skip_inline_spaces()
  guard cursor.consume(':') else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  let text = cursor.take_while(_ => true).trim().to_owned()
  Some(ParsedLinkConstraint({ text, color }))
}

///|
fn class_annotation_line(cursor : @parse.Cursor) -> ClassAnnotationLineSyntax? {
  match note_line(cursor) {
    Some(value) => Some(value)
    None => link_constraint_line(cursor)
  }
}

///|
test "class note line grammar accepts complete annotation lines" {
  let lines = [
    "note right of User : authenticated user", "note bottom of User <<warning>> [[https://example.com/note]] #pink {",
    "note right on link #yellow : sync", "note of link", "note left of User::login() #lightblue",
    "note \"shared note\" as N1 $shared <<info>> #yellow", "note as N2 {", "constraint on links #pink : {xor}",
  ]
  for line in lines {
    let cursor = @parse.Cursor::new(line)
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
    let cursor = @parse.Cursor::new(line)
    guard class_annotation_line(cursor) is None else {
      @test.fail("unexpected annotation syntax: \{line}")
    }
  }
}

///|
fn Parser::push_note_syntax(
  self : Parser,
  syntax : NoteLineSyntax,
  text : String,
) -> Unit raise @parse.ParseError {
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
) -> Unit raise @parse.ParseError {
  match syntax.content {
    NoteInline(text) => self.push_note_syntax(syntax, text)
    NoteBlock => {
      let mut index = self.index + 1
      guard @parse.collect_lines_until(
          fn() {
            guard index < self.lines.length() else { return None }
            let line = self.lines[index]
            index += 1
            Some(line)
          },
          line => {
            let normalized = @parse.strip_line_comment(line).to_lower()
            normalized == "end note" ||
            normalized == "endnote" ||
            (syntax.metadata.braced && normalized == "}")
          },
        )
        is Some(lines) else {
        self.raise_parse_error("unclosed note")
      }
      guard !lines.is_empty() else { self.raise_parse_error("no note defined") }
      self.index = index - 1
      self.push_note_syntax(
        syntax,
        lines.map(line => line.trim().to_owned()).join("\n"),
      )
    }
  }
}

///|
fn Parser::apply_annotation_syntax(
  self : Parser,
  syntax : ClassAnnotationLineSyntax,
) -> Unit raise @parse.ParseError {
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
