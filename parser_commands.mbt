///|
fn try_keyword(src : Source, kw : String) -> Bool {
  src.try_keyword(kw)
}

///|
fn parse_participant_type(src : Source) -> ParticipantType? {
  let keyword = src.peek_word().to_lower()
  let variant = match keyword {
    "participant" => Participant
    "actor" => Actor
    "boundary" => Boundary
    "control" => Control
    "entity" => Entity
    "database" => Database
    "collections" => Collections
    "queue" => Queue
    _ => return None
  }
  src.skip_word()
  Some(variant)
}

///|
fn parse_group_start_keyword(src : Source) -> GroupKeyword? {
  let keyword = src.peek_word().to_lower()
  let variant = match keyword {
    "opt" => Opt
    "alt" => Alt
    "loop" => Loop
    "par2" => Par2
    "par" => Par
    "break" => Break
    "critical" => Critical
    "group" => Group
    "partition" => Partition
    _ => return None
  }
  src.skip_word()
  Some(variant)
}

///|
fn parse_note_position(src : Source) -> NotePosition? {
  let keyword = src.peek_word().to_lower()
  let variant = match keyword {
    "left" => Left
    "right" => Right
    "over" => Over
    "across" => Across
    "bottom" => Bottom
    "top" => Top
    _ => return None
  }
  src.skip_word()
  Some(variant)
}

///|
fn split_participant_list(raw : StringView) -> Array[String] {
  raw
  .split(",")
  .map(c => c.trim())
  .filter(c => c.length() > 0)
  .map(c => c.to_owned())
  .to_array()
}

///|
fn try_participant_decl(src : Source) -> ParticipantDecl? {
  let saved = src.save()
  let created = try_keyword(src, "create")
  if created {
    src.skip_whitespace()
  }
  let typ = match parse_participant_type(src) {
    Some(typ) => typ
    None =>
      if created {
        Participant
      } else {
        src.restore(saved)
        return None
      }
  }
  src.skip_whitespace()
  guard try_participant_ref(src) is Some(reference) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  if try_keyword(src, "order") {
    src.skip_whitespace()
    let _ = src.take_while(c => c == '-' || c.is_ascii_digit())
  }
  if src.consume('#') {
    let _ = src.take_while(is_ident_char)
  }
  Some({ typ, reference, created })
}

///|
fn try_note(src : Source) -> Event? {
  let saved = src.save()

  let note_style = if src.try_keyword("note") {
    NoteStyle::Normal
  } else if src.try_keyword("hnote") {
    Hexagonal
  } else if src.try_keyword("rnote") {
    Box
  } else {
    return None
  }

  src.skip_whitespace()
  let pos_raw = parse_note_position(src)

  match pos_raw {
    Some(pos) => {
      src.skip_whitespace()
      let on_arrow : Bool = match pos {
        Left | Right | Bottom | Top =>
          match src.peek() {
            Some(c) if c == ':' => true
            _ => false
          }
        _ => false
      }

      if on_arrow {
        let _ = src.consume(':')
        let text = src.collect_line().trim().to_owned()
        return Some(
          Note({
            participant_codes: [],
            position: pos,
            text,
            note_style,
            on_arrow: true,
            color: None,
          }),
        )
      }

      let _ = match pos {
        Across => false
        _ => try_keyword(src, "of")
      }
      src.skip_whitespace()
      let part_text = src.take_while(c => c != ':' && c != '\n').trim()
      let codes = split_participant_list(part_text)
      src.skip_whitespace()
      let text = if src.consume(':') {
        src.collect_line().trim().to_owned()
      } else {
        ""
      }
      Some(
        Note({
          participant_codes: codes,
          position: pos,
          text,
          note_style,
          on_arrow: false,
          color: None,
        }),
      )
    }
    None => {
      src.restore(saved)
      None
    }
  }
}

///|
fn make_else_event(src : Source) -> Event {
  let text = src.collect_line().trim()
  GroupingLeaf({
    is_end: false,
    label: if text.length() > 0 {
      Some(text.to_owned())
    } else {
      None
    },
    back_color: None,
  })
}

///|
fn try_grouping(src : Source) -> Event? {
  let saved = src.save()
  let _ = src.consume('&')
  let kw = parse_group_start_keyword(src)

  match kw {
    Some(k) =>
      Some(
        GroupingStart({
          keyword: k,
          header: src.collect_line().trim().to_owned(),
          label: None,
          back_color_header: None,
          back_color_body: None,
          parallel: false,
        }),
      )
    None =>
      if src.try_keyword("else") {
        Some(make_else_event(src))
      } else if src.try_keyword("also") {
        Some(make_else_event(src))
      } else if src.try_keyword("end") {
        Some(GroupingLeaf({ is_end: true, label: None, back_color: None }))
      } else {
        src.restore(saved)
        None
      }
  }
}

///|
fn try_life_event(src : Source, kw : String, typ : ActivationSpec) -> Event? {
  let saved = src.save()
  guard try_keyword(src, kw) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let code = src.take_while(is_ident_char)
  guard code.length() > 0 else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let color : String? = if src.consume('#') {
    Some(src.take_while(is_ident_char))
  } else {
    None
  }
  Some(LifeEvent({ participant_code: code, event_type: typ, color }))
}

///|
fn try_activate(src : Source) -> Event? {
  try_life_event(src, "activate", Activate)
}

///|
fn try_deactivate(src : Source) -> Event? {
  try_life_event(src, "deactivate", Deactivate)
}

///|
fn try_destroy(src : Source) -> Event? {
  try_life_event(src, "destroy", Destroy)
}

///|
fn try_divider(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_string("==") else {
    src.restore(saved)
    return None
  }
  let title = src.take_while(c => c != '=').trim().to_owned()
  let _ = src.take_while(c => c == '=')
  Some(Divider({ title, }))
}

///|
fn try_delay(src : Source) -> Event? {
  let saved = src.save()
  let dots = src.take_while(c => c == '.')
  if dots.length() < 3 {
    src.restore(saved)
    return None
  }
  let line = src.collect_line().trim()
  let label : String? = if line.length() > 0 {
    let s = if line.has_suffix("...") {
      line[:line.length() - 3].trim().to_owned()
    } else {
      line.to_owned()
    }
    if s.length() > 0 {
      Some(s)
    } else {
      None
    }
  } else {
    None
  }
  Some(Delay({ label, }))
}

///|
fn try_hspace(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_string("||") else {
    src.restore(saved)
    return None
  }
  let n_str = src.take_while(c => c >= '0' && c <= '9')
  guard src.consume('|') else {
    src.restore(saved)
    return None
  }
  let _ = src.take_while(c => c == '|')
  Some(
    HSpace({
      pixels: if n_str.length() > 0 {
        Some(@string.parse_int(n_str) catch { _ => 0 })
      } else {
        None
      },
    }),
  )
}

///|
fn try_newpage(src : Source) -> Event? {
  let saved = src.save()
  guard try_keyword(src, "newpage") else {
    src.restore(saved)
    return None
  }
  let t = src.collect_line().trim()
  Some(
    Newpage({ title: if t.length() > 0 { Some(t.to_owned()) } else { None } }),
  )
}

///|
fn try_link_anchor(src : Source) -> Event? {
  let saved = src.save()
  if !src.consume('{') {
    src.restore(saved)
    return None
  }
  let a1 = src.take_while(is_ident_char)
  if !src.consume('}') || a1.length() == 0 {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  if !src.consume('<') || !src.consume('-') || !src.consume('>') {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  if !src.consume('{') {
    src.restore(saved)
    return None
  }
  let a2 = src.take_while(is_ident_char)
  if !src.consume('}') || a2.length() == 0 {
    src.restore(saved)
    return None
  }
  Some(LinkAnchor(a1, a2))
}
