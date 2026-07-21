///|
priv struct SpecialNoteHeader {
  target : String
  position : NotePosition
  target_kind : NoteTargetKind
  relation_index : Int?
  member_name : String?
  code : String?
  color : String?
  url : String?
  stereotype : String?
  braced : Bool
}

///|
fn note_header_metadata(
  raw : String,
) -> (String, String?, String?, String?, Bool) {
  let braced = raw.trim().has_suffix("{")
  let raw = if braced {
    raw.trim()[0:raw.trim().length() - 1].trim().to_owned()
  } else {
    raw.trim().to_owned()
  }
  let (target, color, url, stereotype) = relation_suffix(raw)
  (target, color, url, stereotype, braced)
}

///|
fn parse_link_note_header(line : String) -> (SpecialNoteHeader, String?)? {
  let colon = find_substring(line, ":")
  let header = match colon {
    Some(index) => line[0:index].trim().to_owned()
    None => line.trim().to_owned()
  }
  let text = match colon {
    Some(index) => Some(line[index + 1:].trim().to_owned())
    None => None
  }
  let tokens = words(header)
  guard tokens.length() >= 3 && tokens[0].to_lower() == "note" else {
    return None
  }
  let (position, connector_index) = match note_position(tokens[1]) {
    Some(position) => (position, 2)
    None => (Bottom, 1)
  }
  guard connector_index + 1 < tokens.length() &&
    (
      tokens[connector_index].to_lower() == "on" ||
      tokens[connector_index].to_lower() == "of"
    ) &&
    tokens[connector_index + 1].to_lower() == "link" else {
    return None
  }
  let metadata = tokens[connector_index + 2:].join(" ")
  let (_, color, url, stereotype, braced) = note_header_metadata(metadata)
  Some(
    (
      {
        target: "",
        position,
        target_kind: LinkNote,
        relation_index: None,
        member_name: None,
        code: None,
        color,
        url,
        stereotype,
        braced,
      },
      text,
    ),
  )
}

///|
fn parse_member_tip_header(line : String) -> SpecialNoteHeader? {
  let tokens = words(line)
  guard tokens.length() >= 4 && tokens[0].to_lower() == "note" else {
    return None
  }
  guard note_position(tokens[1]) is Some(position) &&
    (position is Left || position is Right) &&
    tokens[2].to_lower() == "of" else {
    return None
  }
  let rest = tokens[3:].join(" ")
  guard find_substring(rest, "::") is Some(separator) else { return None }
  let entity = normalize_name(rest[0:separator].trim().to_owned())
  let (member_name, color, url, stereotype, braced) = note_header_metadata(
    rest[separator + 2:].to_owned(),
  )
  guard entity.length() > 0 && member_name.length() > 0 else { return None }
  Some({
    target: entity,
    position,
    target_kind: MemberTip,
    relation_index: None,
    member_name: Some(normalize_name(member_name)),
    code: None,
    color,
    url,
    stereotype,
    braced,
  })
}

///|
fn parse_entity_note_header(line : String) -> SpecialNoteHeader? {
  guard find_substring(line, " : ") is None else { return None }
  let tokens = words(line)
  guard tokens.length() >= 4 && tokens[0].to_lower() == "note" else {
    return None
  }
  guard note_position(tokens[1]) is Some(position) &&
    tokens[2].to_lower() == "of" else {
    return None
  }
  let (target, color, url, stereotype, braced) = note_header_metadata(
    tokens[3:].join(" "),
  )
  guard target.length() > 0 else { return None }
  Some({
    target,
    position,
    target_kind: EntityNote,
    relation_index: None,
    member_name: None,
    code: None,
    color,
    url,
    stereotype,
    braced,
  })
}

///|
fn parse_named_note(line : String) -> (SpecialNoteHeader, String?)? {
  let lower = line.to_lower()
  guard lower.has_prefix("note ") else { return None }
  if lower.has_prefix("note as ") {
    let (code, color, url, stereotype, braced) = note_header_metadata(
      line[8:].to_owned(),
    )
    guard code.length() > 0 else { return None }
    return Some(
      (
        {
          target: code,
          position: Right,
          target_kind: FloatingNote,
          relation_index: None,
          member_name: None,
          code: Some(code),
          color,
          url,
          stereotype,
          braced,
        },
        None,
      ),
    )
  }
  let chars = line.to_array()
  guard chars.length() > 6 && chars[5] == '"' else { return None }
  guard quoted_end(chars, 5) is Some(end) else { return None }
  let text = line[6:end].to_owned()
  let tail = line[end + 1:].trim().to_owned()
  guard tail.to_lower().has_prefix("as ") else { return None }
  let (code, color, url, stereotype, braced) = note_header_metadata(
    tail[3:].to_owned(),
  )
  guard code.length() > 0 else { return None }
  Some(
    (
      {
        target: code,
        position: Right,
        target_kind: FloatingNote,
        relation_index: None,
        member_name: None,
        code: Some(code),
        color,
        url,
        stereotype,
        braced,
      },
      Some(text),
    ),
  )
}

///|
fn Parser::push_special_note(
  self : Parser,
  header : SpecialNoteHeader,
  text : String,
) -> Unit raise ParseError {
  let mut header = header
  match header.target_kind {
    LinkNote => {
      guard !self.relations.is_empty() else {
        self.raise_parse_error("no link defined")
      }
      header = { ..header, relation_index: Some(self.relations.length() - 1) }
    }
    MemberTip => {
      let target = self.resolve(header.target)
      guard self.entities.any(entity => entity.qualified_code == target) else {
        self.raise_parse_error("nothing to note to")
      }
      header = { ..header, target, }
    }
    EntityNote => {
      let target = self.ensure_entity(header.target)
      header = { ..header, target, }
    }
    FloatingNote => {
      let target = self.ensure_entity_as(header.target, NamedNote)
      header = { ..header, target, code: Some(target) }
    }
  }
  self.notes.push({
    target: header.target,
    position: header.position,
    text,
    target_kind: header.target_kind,
    relation_index: header.relation_index,
    member_name: header.member_name,
    code: header.code,
    color: header.color,
    url: header.url,
    stereotype: header.stereotype,
  })
}

///|
fn Parser::consume_special_note(
  self : Parser,
  header : SpecialNoteHeader,
) -> Unit raise ParseError {
  let text = StringBuilder()
  let mut first = true
  self.index += 1
  while self.index < self.lines.length() {
    let line = self.lines[self.index]
    let terminator = strip_comment(line).to_lower()
    if terminator == "end note" ||
      terminator == "endnote" ||
      (header.braced && terminator == "}") {
      guard !first else { self.raise_parse_error("no note defined") }
      self.push_special_note(header, text.to_string())
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

///|
fn parse_link_constraint(
  line : String,
  relation_count : Int,
) -> LinkConstraint? {
  let lower = line.to_lower()
  guard lower.has_prefix("constraint on links") else { return None }
  guard find_substring(line, ":") is Some(separator) else { return None }
  guard relation_count >= 2 else { return None }
  let header = line[0:separator].trim().to_owned()
  let color = declaration_color(header)
  Some({
    first_relation: relation_count - 2,
    second_relation: relation_count - 1,
    text: line[separator + 1:].trim().to_owned(),
    color,
  })
}
