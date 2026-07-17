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
  let created = src.try_keyword("create")
  if created {
    src.skip_whitespace()
  }
  let typ = match parse_participant_type(src) {
    Some(typ) => typ
    None => {
      guard !created else { Participant }
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
  let order = if src.try_keyword("order") {
    src.skip_whitespace()
    let raw_order = src.take_while(c => c == '-' || c.is_ascii_digit())
    guard raw_order.length() != 0 else { None }
    Some(@string.parse_int(raw_order) catch { _ => 0 })
  } else {
    None
  }
  if src.consume('#') {
    let color = src.take_while(c => !is_inline_whitespace(c) && c != '\n')
    guard color.length() > 0 else {
      src.restore(saved)
      return None
    }
    return Some({ typ, reference, created, color: Some(color), order })
  }
  Some({ typ, reference, created, color: None, order })
}

///|
fn try_note(src : Source) -> Event? {
  let saved = src.save()

  let _ = src.consume('&')
  let _ = src.consume('/')
  src.skip_whitespace()

  let note_style = match src.peek_word().to_lower() {
    "note" => NodeNormal
    "hnote" => Hexagonal
    "rnote" => Box
    _ => return None
  }
  src.skip_word()

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
        _ => src.try_keyword("of")
      }
      src.skip_whitespace()
      let part_text = src
        .take_while(c => c != ':' && c != '#' && c != '\n')
        .trim()
      let codes = split_participant_list(part_text)
      src.skip_whitespace()
      let color = try_color(src)
      src.skip_whitespace()
      let text = if src.consume(':') {
        src.collect_line().trim().to_owned()
      } else {
        ""
      }
      let position = if pos is Over && codes.length() > 1 {
        OverSeveral
      } else {
        pos
      }
      Some(
        Note({
          participant_codes: codes,
          position,
          text,
          note_style,
          on_arrow: false,
          color,
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
  src.skip_whitespace()
  let back_color = try_color(src)
  src.skip_whitespace()
  let text = src.collect_line().trim()
  GroupingLeaf({
    is_end: false,
    label: if text.length() > 0 {
      Some(text.to_owned())
    } else {
      None
    },
    back_color,
  })
}

///|
fn try_grouping(src : Source) -> Event? {
  let saved = src.save()
  let parallel = src.consume('&')
  if parallel {
    src.skip_whitespace()
  }
  let kw = parse_group_start_keyword(src)

  match kw {
    Some(k) => {
      src.skip_whitespace()
      let back_color_header = try_color(src)
      src.skip_whitespace()
      let back_color_body = if back_color_header is Some(_) {
        try_color(src)
      } else {
        None
      }
      src.skip_whitespace()
      Some(
        GroupingStart({
          keyword: k,
          header: src.collect_line().trim().to_owned(),
          back_color_header,
          back_color_body,
          parallel,
        }),
      )
    }
    None =>
      if src.try_keyword("else") {
        Some(make_else_event(src))
      } else if src.try_keyword("also") {
        Some(make_else_event(src))
      } else if src.try_keyword("end") {
        let _ = src.collect_line()
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
  guard src.try_keyword(kw) else {
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
  guard src.try_string("==") else {
    src.restore(saved)
    return None
  }
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
  let _ = src.consume('@')
  guard src.try_keyword("newpage") else {
    src.restore(saved)
    return None
  }
  let t = src.collect_line().trim()
  Some(
    Newpage({ title: if t.length() > 0 { Some(t.to_owned()) } else { None } }),
  )
}

///|
fn try_autonumber(src : Source) -> Event? {
  guard src.try_keyword("autonumber") else { return None }
  src.skip_whitespace()
  if src.try_keyword("stop") {
    return Some(AutonumberStop)
  }
  if src.try_keyword("resume") {
    src.skip_whitespace()
    let increment = src.take_while(Char::is_ascii_digit)
    src.skip_whitespace()
    let format = try_quoted_string(src)
    return Some(
      AutonumberResume({
        increment: if increment.length() == 0 {
          None
        } else {
          Some(@string.parse_int(increment) catch { _ => 0 })
        },
        format,
      }),
    )
  }
  if src.try_keyword("inc") {
    src.skip_whitespace()
    let position = src.take_while(Char::is_ascii_alphabetic)
    return Some(
      AutonumberIncrement(
        if position.length() == 0 {
          None
        } else {
          Some(position)
        },
      ),
    )
  }

  let start = if src.peek() is Some('"') {
    None
  } else {
    let value = src.take_while(c => !is_inline_whitespace(c) && c != '\n')
    if value.length() == 0 {
      None
    } else {
      Some(value)
    }
  }
  src.skip_whitespace()
  let increment = src.take_while(Char::is_ascii_digit)
  src.skip_whitespace()
  let format = try_quoted_string(src)
  Some(
    Autonumber({
      start,
      increment: if increment.length() == 0 {
        None
      } else {
        Some(@string.parse_int(increment) catch { _ => 0 })
      },
      format,
    }),
  )
}

///|
fn try_autoactivate(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("autoactivate") else { return None }
  src.skip_whitespace()
  if src.try_keyword("on") {
    Some(Autoactivate(true))
  } else if src.try_keyword("off") {
    Some(Autoactivate(false))
  } else {
    src.restore(saved)
    None
  }
}

///|
fn try_footbox(src : Source) -> Event? {
  let saved = src.save()
  if src.try_keyword("footbox") {
    src.skip_whitespace()
    if src.try_keyword("on") {
      return Some(Footbox(true))
    }
    if src.try_keyword("off") {
      return Some(Footbox(false))
    }
  } else if src.try_keyword("hide") {
    src.skip_whitespace()
    if src.try_keyword("footbox") {
      return Some(Footbox(false))
    }
  }
  src.restore(saved)
  None
}

///|
fn try_hide_unlinked(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("hide") else { return None }
  src.skip_whitespace()
  guard src.try_keyword("unlinked") else {
    src.restore(saved)
    return None
  }
  Some(HideUnlinked)
}

///|
fn try_box(src : Source) -> Event? {
  let saved = src.save()
  if src.try_keyword("end") {
    src.skip_whitespace()
    if src.try_keyword("box") {
      return Some(BoxEnd)
    }
  }
  src.restore(saved)
  guard src.try_keyword("box") else { return None }
  src.skip_whitespace()
  let color = try_color(src)
  if color is Some(_) {
    src.skip_whitespace()
  }
  let label = src.collect_line().trim()
  Some(
    BoxStart({
      label: if label.length() == 0 {
        None
      } else {
        Some(label.to_owned())
      },
      color,
    }),
  )
}

///|
fn try_reference(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("ref") else { return None }
  src.skip_whitespace()
  guard src.try_keyword("over") else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let participants = split_participant_list(
    src.take_while(c => c != ':' && c != '\n'),
  )
  guard participants.length() > 0 && src.consume(':') else {
    src.restore(saved)
    return None
  }
  let label = src.collect_line().trim()
  Some(
    Reference({
      participant_codes: participants,
      label: if label.length() == 0 {
        None
      } else {
        Some(label.to_owned())
      },
    }),
  )
}

///|
fn try_return(src : Source) -> Event? {
  let saved = src.save()
  let _ = src.consume('&')
  src.skip_whitespace()
  guard src.try_keyword("return") else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let _ = try_color(src)
  src.skip_whitespace()
  let value = src.collect_line().trim()
  Some(
    Return({
      value: if value.length() == 0 {
        None
      } else {
        Some(value.to_owned())
      },
    }),
  )
}

///|
fn try_url(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("url") else { return None }
  src.skip_whitespace()
  let _ = src.try_keyword("of") || src.try_keyword("for")
  src.skip_whitespace()
  guard try_participant_ref(src) is Some(reference) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let _ = src.try_keyword("is")
  src.skip_whitespace()
  let url = src.collect_line().trim()
  guard url.length() > 0 else {
    src.restore(saved)
    return None
  }
  Some(UrlOf(reference.code, url.to_owned()))
}

///|
fn try_ignore_newpage(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("ignore") else { return None }
  src.skip_whitespace()
  guard src.try_keyword("newpage") else {
    src.restore(saved)
    return None
  }
  Some(IgnoreNewpage)
}

///|
fn try_auto_newpage(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("auto") else { return None }
  src.skip_whitespace()
  guard src.try_keyword("newpage") else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let size = src.take_while(Char::is_ascii_digit)
  Some(
    AutoNewpage(
      if size.length() == 0 {
        None
      } else {
        Some(@string.parse_int(size) catch { _ => 0 })
      },
    ),
  )
}

///|
fn try_link_anchor(src : Source) -> Event? {
  let saved = src.save()
  guard try_anchor(src) is Some(a1) else { return None }
  src.skip_whitespace()
  if !src.consume('<') || !src.consume('-') || !src.consume('>') {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  guard try_anchor(src) is Some(a2) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let label = if src.consume(':') {
    Some(src.collect_line().trim().to_owned())
  } else {
    None
  }
  Some(LinkAnchor(a1, a2, label))
}
