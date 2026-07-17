///|
fn take_optional_decimal(src : Source) -> Int? {
  src.take_while(Char::is_ascii_digit).optional_integer()
}

///|
fn parse_participant_type(src : Source) -> ParticipantType? {
  let typ = match src.peek_word().to_lower() {
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
  Some(typ)
}

///|
fn parse_group_keyword(src : Source) -> GroupKeyword? {
  let keyword = match src.peek_word().to_lower() {
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
  Some(keyword)
}

///|
fn parse_note_style(src : Source) -> NoteStyle? {
  let style = match src.peek_word().to_lower() {
    "note" => NodeNormal
    "hnote" => Hexagonal
    "rnote" => Box
    _ => return None
  }
  src.skip_word()
  Some(style)
}

///|
fn parse_note_position(src : Source) -> NotePosition? {
  let position = match src.peek_word().to_lower() {
    "left" => Left
    "right" => Right
    "over" => Over
    "across" => Across
    "bottom" => Bottom
    "top" => Top
    _ => return None
  }
  src.skip_word()
  Some(position)
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
fn note_is_on_arrow(position : NotePosition, src : Source) -> Bool {
  match position {
    Left | Right | Bottom | Top => src.peek() is Some(':')
    Over | OverSeveral | Across => false
  }
}

///|
fn note_position_for(
  position : NotePosition,
  participants : Array[String],
) -> NotePosition {
  if position is Over && participants.length() > 1 {
    OverSeveral
  } else {
    position
  }
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
      guard created else { return None }
      Participant
    }
  }
  src.skip_whitespace()
  guard src.try_participant_ref() is Some(reference) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let order = if src.try_keyword("order") {
    src.skip_whitespace()
    src.take_while(c => c == '-' || c.is_ascii_digit()).optional_integer()
  } else {
    None
  }
  src.skip_whitespace()
  let color = src.try_color()
  Some({ typ, reference, created, color, order })
}

///|
fn try_note(src : Source) -> Event? {
  let saved = src.save()
  let _ = src.consume('&')
  let _ = src.consume('/')
  src.skip_whitespace()
  guard parse_note_style(src) is Some(note_style) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  guard parse_note_position(src) is Some(position) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  if note_is_on_arrow(position, src) {
    let _ = src.consume(':')
    return Some(
      Note({
        participant_codes: [],
        position,
        text: src.collect_line().trim().to_owned(),
        note_style,
        on_arrow: true,
        color: None,
      }),
    )
  }
  if !(position is Across) {
    let _ = src.try_keyword("of")
  }
  src.skip_whitespace()
  let participants = split_participant_list(
    src.take_while(c => c != ':' && c != '#' && c != '\n').trim(),
  )
  src.skip_whitespace()
  let color = src.try_color()
  src.skip_whitespace()
  let text = if src.consume(':') {
    src.collect_line().trim().to_owned()
  } else {
    ""
  }
  Some(
    Note({
      participant_codes: participants,
      position: note_position_for(position, participants),
      text,
      note_style,
      on_arrow: false,
      color,
    }),
  )
}

///|
fn try_group_leaf(src : Source) -> Event? {
  if src.try_keyword("else") || src.try_keyword("also") {
    src.skip_whitespace()
    let back_color = src.try_color()
    src.skip_whitespace()
    return Some(
      GroupingLeaf({
        is_end: false,
        label: src.collect_line().optional_text(),
        back_color,
      }),
    )
  }
  guard src.try_keyword("end") else { return None }
  let _ = src.collect_line()
  Some(GroupingLeaf({ is_end: true, label: None, back_color: None }))
}

///|
fn try_grouping(src : Source) -> Event? {
  let saved = src.save()
  let parallel = src.consume('&')
  if parallel {
    src.skip_whitespace()
  }
  guard parse_group_keyword(src) is Some(keyword) else {
    src.restore(saved)
    return try_group_leaf(src)
  }
  src.skip_whitespace()
  let header_color = src.try_color()
  src.skip_whitespace()
  let body_color = if header_color is Some(_) { src.try_color() } else { None }
  src.skip_whitespace()
  Some(
    GroupingStart({
      keyword,
      header: src.collect_line().trim().to_owned(),
      back_color_header: header_color,
      back_color_body: body_color,
      parallel,
    }),
  )
}

///|
fn try_life_event(
  src : Source,
  keyword : String,
  event_type : ActivationSpec,
) -> Event? {
  let saved = src.save()
  guard src.try_keyword(keyword) else { return None }
  src.skip_whitespace()
  let participant_code = src.take_while(is_ident_char)
  guard participant_code.length() > 0 else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  Some(LifeEvent({ participant_code, event_type, color: src.try_color() }))
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
  guard src.try_string("==") else { return None }
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
  guard src.take_while(c => c == '.').length() >= 3 else {
    src.restore(saved)
    return None
  }
  let text = src.collect_line().trim()
  let label = if text.has_suffix("...") {
    text[:text.length() - 3].to_owned().optional_text()
  } else {
    text.to_owned().optional_text()
  }
  Some(Delay({ label, }))
}

///|
fn try_hspace(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_string("||") else { return None }
  let pixels = src.take_while(Char::is_ascii_digit).optional_integer()
  guard src.consume('|') else {
    src.restore(saved)
    return None
  }
  let _ = src.take_while(c => c == '|')
  Some(HSpace({ pixels, }))
}

///|
fn try_newpage(src : Source) -> Event? {
  let saved = src.save()
  let _ = src.consume('@')
  guard src.try_keyword("newpage") else {
    src.restore(saved)
    return None
  }
  Some(Newpage({ title: src.collect_line().optional_text() }))
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
    let increment = take_optional_decimal(src)
    src.skip_whitespace()
    return Some(
      AutonumberResume({ increment, format: src.try_quoted_string() }),
    )
  }
  if src.try_keyword("inc") {
    src.skip_whitespace()
    return Some(
      AutonumberIncrement(
        src.take_while(Char::is_ascii_alphabetic).optional_text(),
      ),
    )
  }
  let start = match src.peek() {
    Some('"') => None
    _ =>
      src.take_while(c => !is_inline_whitespace(c) && c != '\n').optional_text()
  }
  src.skip_whitespace()
  let increment = take_optional_decimal(src)
  src.skip_whitespace()
  Some(Autonumber({ start, increment, format: src.try_quoted_string() }))
}

///|
fn try_autoactivate(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("autoactivate") else { return None }
  src.skip_whitespace()
  let enabled = if src.try_keyword("on") {
    Some(true)
  } else if src.try_keyword("off") {
    Some(false)
  } else {
    None
  }
  guard enabled is Some(enabled) else {
    src.restore(saved)
    return None
  }
  Some(Autoactivate(enabled))
}

///|
fn try_footbox(src : Source) -> Event? {
  let saved = src.save()
  if src.try_keyword("hide") {
    src.skip_whitespace()
    guard src.try_keyword("footbox") else {
      src.restore(saved)
      return None
    }
    return Some(Footbox(false))
  }
  guard src.try_keyword("footbox") else { return None }
  src.skip_whitespace()
  let enabled = if src.try_keyword("on") {
    Some(true)
  } else if src.try_keyword("off") {
    Some(false)
  } else {
    None
  }
  guard enabled is Some(enabled) else {
    src.restore(saved)
    return None
  }
  Some(Footbox(enabled))
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
    src.restore(saved)
  }
  guard src.try_keyword("box") else { return None }
  src.skip_whitespace()
  let color = src.try_color()
  if color is Some(_) {
    src.skip_whitespace()
  }
  Some(BoxStart({ label: src.collect_line().optional_text(), color }))
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
  let participant_codes = split_participant_list(
    src.take_while(c => c != ':' && c != '\n'),
  )
  guard participant_codes.length() > 0 && src.consume(':') else {
    src.restore(saved)
    return None
  }
  Some(
    Reference({ participant_codes, label: src.collect_line().optional_text() }),
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
  let _ = src.try_color()
  src.skip_whitespace()
  Some(Return({ value: src.collect_line().optional_text() }))
}

///|
fn try_url(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_keyword("url") else { return None }
  src.skip_whitespace()
  let _ = src.try_keyword("of") || src.try_keyword("for")
  src.skip_whitespace()
  guard src.try_participant_ref() is Some(reference) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let _ = src.try_keyword("is")
  src.skip_whitespace()
  let parsed_url = src.collect_line().optional_text()
  guard parsed_url is Some(url) else {
    src.restore(saved)
    return None
  }
  Some(UrlOf(reference.code, url))
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
  Some(AutoNewpage(take_optional_decimal(src)))
}

///|
fn try_link_anchor(src : Source) -> Event? {
  let saved = src.save()
  guard src.try_anchor() is Some(from) else { return None }
  src.skip_whitespace()
  guard src.try_string("<->") else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  guard src.try_anchor() is Some(to) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let label = if src.consume(':') {
    src.collect_line().optional_text()
  } else {
    None
  }
  Some(LinkAnchor(from, to, label))
}
