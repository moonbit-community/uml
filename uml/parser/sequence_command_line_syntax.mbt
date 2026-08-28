///|
/// Matches a participant type keyword.
fn participant_type(cursor : @tokenizer.Cursor) -> @seq.ParticipantType? {
  let start = cursor.offset()
  let word = take_ident(cursor)
  let result = match word.to_lower() {
    "participant" => Some(@seq.Participant)
    "actor" => Some(Actor)
    "boundary" => Some(Boundary)
    "control" => Some(Control)
    "entity" => Some(Entity)
    "database" => Some(Database)
    "collections" => Some(Collections)
    "queue" => Some(Queue)
    _ => None
  }
  guard result is Some(_) else {
    ignore(cursor.restore(start))
    return None
  }
  result
}

///|
/// Matches a group keyword.
fn group_keyword(cursor : @tokenizer.Cursor) -> @seq.GroupKeyword? {
  let start = cursor.offset()
  let word = take_ident(cursor)
  let result = match word.to_lower() {
    "opt" => Some(@seq.Opt)
    "alt" => Some(@seq.Alt)
    "loop" => Some(@seq.Loop)
    "par2" => Some(@seq.Par2)
    "par" => Some(@seq.Par)
    "break" => Some(@seq.Break)
    "critical" => Some(@seq.Critical)
    "group" => Some(@seq.Group)
    "partition" => Some(@seq.Partition)
    _ => None
  }
  guard result is Some(_) else {
    ignore(cursor.restore(start))
    return None
  }
  result
}

///|
/// Matches the `as` alias keyword, which must not be part of an identifier.
fn take_as_keyword(cursor : @tokenizer.Cursor) -> Bool {
  let start = cursor.offset()
  guard cursor.consume_literal("as") else { return false }
  if cursor.peek() is Some(char) && is_ident_char(char) {
    ignore(cursor.restore(start))
    false
  } else {
    true
  }
}

///|
fn take_alias_code(cursor : @tokenizer.Cursor) -> String? {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  guard take_as_keyword(cursor) else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  let code = take_ident(cursor)
  guard code.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  Some(code)
}

///|

///|
fn alias_ref(cursor : @tokenizer.Cursor, name : String) -> PartRef? {
  take_alias_code(cursor).map(code => { code, display: name, })
}

///|
fn participant_decl_ref(cursor : @tokenizer.Cursor) -> PartRef? {
  let start = cursor.offset()
  if cursor.peek() == Some('"') {
    match cursor.take_quoted_value() {
      Some(display) =>
        match take_alias_code(cursor) {
          Some(code) => Some({ code, display, })
          None => Some({ code: display, display, })
        }
      None => {
        ignore(cursor.restore(start))
        None
      }
    }
  } else {
    let name = take_ident(cursor)
    guard name.length() > 0 else {
      ignore(cursor.restore(start))
      return None
    }
    let saved = cursor.offset()
    cursor.skip_inline_spaces()
    let reference = if take_as_keyword(cursor) {
      cursor.skip_inline_spaces()
      if cursor.peek() == Some('"') {
        match cursor.take_quoted_value() {
          Some(display) => Some({ code: name, display, })
          None => {
            ignore(cursor.restore(saved))
            alias_ref(cursor, name)
          }
        }
      } else {
        ignore(cursor.restore(saved))
        alias_ref(cursor, name)
      }
    } else {
      ignore(cursor.restore(saved))
      alias_ref(cursor, name)
    }
    Some(reference.unwrap_or({ code: name, display: name, }))
  }
}

///|
/// Matches an optional `#color` token introduced by a single space.
fn optional_color(cursor : @tokenizer.Cursor) -> String? {
  let saved = cursor.offset()
  if cursor.skip_inline_space1() {
    match cursor.take_color_value() {
      Some(value) => Some(value)
      None => {
        ignore(cursor.restore(saved))
        None
      }
    }
  } else {
    None
  }
}

///|
/// Matches an optional digit run introduced by a single space.
fn optional_digit_run(cursor : @tokenizer.Cursor) -> Int? {
  let saved = cursor.offset()
  if cursor.skip_inline_space1() {
    let digits = cursor.take_while(Char::is_ascii_digit)
    if digits.length() > 0 {
      Some(@string.parse_int(digits) catch { _ => 0 })
    } else {
      ignore(cursor.restore(saved))
      None
    }
  } else {
    None
  }
}

///|
/// Matches an optional alphabetic run introduced by a single space.
fn optional_alpha_run(cursor : @tokenizer.Cursor) -> String? {
  let saved = cursor.offset()
  if cursor.skip_inline_space1() {
    let value = cursor.take_while(Char::is_ascii_alphabetic)
    if value.length() > 0 {
      Some(value)
    } else {
      ignore(cursor.restore(saved))
      None
    }
  } else {
    None
  }
}

///|
/// Matches an optional quoted value introduced by a single space.
fn optional_quoted(cursor : @tokenizer.Cursor) -> String? {
  let saved = cursor.offset()
  if cursor.skip_inline_space1() {
    if cursor.peek() == Some('"') {
      match cursor.take_quoted_value() {
        Some(value) => Some(value)
        None => {
          ignore(cursor.restore(saved))
          None
        }
      }
    } else {
      ignore(cursor.restore(saved))
      None
    }
  } else {
    None
  }
}

///|
fn participant_declaration_tail(
  cursor : @tokenizer.Cursor,
  typ : @seq.ParticipantType,
  reference : PartRef,
  created : Bool,
) -> ParticipantDecl? {
  let start = cursor.offset()
  let order = optional_order(cursor)
  let url = optional_url(cursor)
  let color = optional_color(cursor)
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some({ typ, reference, created, color, url, order, })
}

///|
fn optional_order(cursor : @tokenizer.Cursor) -> Int? {
  let saved = cursor.offset()
  if cursor.skip_inline_space1() &&
    take_keyword(cursor, "order") &&
    cursor.skip_inline_space1() {
    match take_signed_integer(cursor) {
      Some(value) => Some(value)
      None => {
        ignore(cursor.restore(saved))
        None
      }
    }
  } else {
    ignore(cursor.restore(saved))
    None
  }
}

///|
fn optional_url(cursor : @tokenizer.Cursor) -> String? {
  let saved = cursor.offset()
  if cursor.skip_inline_space1() {
    match cursor.take_url_value() {
      Some(value) => Some(value)
      None => {
        ignore(cursor.restore(saved))
        None
      }
    }
  } else {
    None
  }
}

///|
fn participant_declaration_line_syntax(
  cursor : @tokenizer.Cursor,
) -> ParticipantDecl? {
  let start = cursor.offset()
  if take_keyword(cursor, "create") {
    guard cursor.skip_inline_space1() else {
      ignore(cursor.restore(start))
      return None
    }
    let type_saved = cursor.offset()
    let typ = match participant_type(cursor) {
      Some(typ) if cursor.skip_inline_space1() => Some(typ)
      _ => {
        ignore(cursor.restore(type_saved))
        None
      }
    }
    let typ = typ.unwrap_or(@seq.Participant)
    match participant_decl_ref(cursor) {
      None => {
        ignore(cursor.restore(start))
        None
      }
      Some(reference) =>
        match participant_declaration_tail(cursor, typ, reference, true) {
          Some(decl) => Some(decl)
          None => {
            ignore(cursor.restore(start))
            None
          }
        }
    }
  } else {
    match participant_type(cursor) {
      None => {
        ignore(cursor.restore(start))
        None
      }
      Some(typ) => {
        guard cursor.skip_inline_space1() else {
          ignore(cursor.restore(start))
          return None
        }
        match participant_decl_ref(cursor) {
          None => {
            ignore(cursor.restore(start))
            None
          }
          Some(reference) =>
            match participant_declaration_tail(cursor, typ, reference, false) {
              Some(decl) => Some(decl)
              None => {
                ignore(cursor.restore(start))
                None
              }
            }
        }
      }
    }
  }
}

///|
fn life_event_line_syntax(
  cursor : @tokenizer.Cursor,
  keyword : String,
  event_type : @seq.ActivationSpec,
) -> @seq.Event? {
  let start = cursor.offset()
  guard take_keyword(cursor, keyword) else { return None }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  match take_quoted_or_ident(cursor) {
    None => {
      ignore(cursor.restore(start))
      None
    }
    Some(participant_code) => {
      let color = optional_color(cursor)
      cursor.skip_inline_spaces()
      guard cursor.is_eof() else {
        ignore(cursor.restore(start))
        return None
      }
      Some(@seq.LifeEvent({ participant_code, event_type, color, }))
    }
  }
}

///|
fn deactivate_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  if take_keyword(cursor, "deactivate") {
    cursor.skip_inline_spaces()
    if cursor.is_eof() {
      return Some(@seq.DeactivateLatest)
    }
  }
  ignore(cursor.restore(start))
  life_event_line_syntax(cursor, "deactivate", @seq.Deactivate)
}

///|
fn box_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  if take_keyword(cursor, "end") {
    if cursor.skip_inline_space1() && take_keyword(cursor, "box") {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.BoxEnd)
      }
    }
    ignore(cursor.restore(start))
  }
  if !take_keyword(cursor, "box") {
    return None
  }
  cursor.skip_inline_spaces()
  let label = cursor.take_while(char => char != '#')
  let color = cursor.take_color_value()
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(@seq.BoxStart({ label: @tokenizer.normalize_label(label), color, }))
}

///|
fn grouping_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  let parallel = cursor.consume('&')
  cursor.skip_inline_spaces()
  match group_keyword(cursor) {
    Some(keyword) => {
      let back_color_header = optional_color(cursor)
      let back_color_body = optional_color(cursor)
      cursor.skip_inline_spaces()
      let header = cursor.take_rest_trimmed()
      Some(
        @seq.GroupingStart({
          keyword,
          header,
          back_color_header,
          back_color_body,
          parallel,
        }),
      )
    }
    None => {
      ignore(cursor.restore(start))
      if take_keyword(cursor, "else") || take_keyword(cursor, "also") {
        let back_color = optional_color(cursor)
        cursor.skip_inline_spaces()
        let label = cursor.take_rest()
        Some(
          @seq.GroupingLeaf({
            is_end: false,
            label: @tokenizer.normalize_label(label),
            back_color,
          }),
        )
      } else {
        ignore(cursor.restore(start))
        if take_keyword(cursor, "end") {
          ignore(cursor.take_rest())
          Some(
            @seq.GroupingLeaf({ is_end: true, label: None, back_color: None, }),
          )
        } else {
          ignore(cursor.restore(start))
          None
        }
      }
    }
  }
}

///|
fn divider_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  guard cursor.consume_literal("==") else { return None }
  let title = StringBuilder()
  while !cursor.starts_with_literal("==") {
    match cursor.advance() {
      Some(char) => title.write_char(char)
      None => {
        ignore(cursor.restore(start))
        return None
      }
    }
  }
  guard cursor.consume_literal("==") else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(@seq.Divider({ title: title.to_string().trim().to_owned(), }))
}

///|
fn delay_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  let delimiter = if cursor.starts_with_literal("...") {
    Some("...")
  } else if cursor.peek() == Some('…') {
    Some("…")
  } else {
    None
  }
  match delimiter {
    Some(value) => {
      ignore(cursor.consume_literal(value))
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.Delay({ label: None, }))
      }
    }
    None => ()
  }
  ignore(cursor.restore(start))
  guard delimiter is Some(value) else { return None }
  ignore(cursor.consume_literal(value))
  let label = StringBuilder()
  while !cursor.is_eof() && !cursor.starts_with_literal(value) {
    for char in cursor.advance() {
      label.write_char(char)
    }
  }
  guard cursor.consume_literal(value) else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(@seq.Delay({ label: @tokenizer.normalize_label(label.to_string()), }))
}

///|
fn hspace_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  guard cursor.consume_literal("||") else { return None }
  let raw_pixels = cursor.take_while(Char::is_ascii_digit)
  guard cursor.consume('|') else {
    ignore(cursor.restore(start))
    return None
  }
  while cursor.consume('|') {
    ()
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(@seq.HSpace({ pixels: optional_digits(raw_pixels), }))
}

///|
/// Parse an optional digit-run: an empty run means `None`, otherwise the
/// parsed value (callers guarantee the run is digit-only).
fn optional_digits(value : String) -> Int? {
  guard value.length() > 0 else { None }
  Some(@string.parse_int(value) catch { _ => 0 })
}

///|
/// A `stop`/`resume`/`inc` branch that matches its keyword commits the whole
/// autonumber line: trailing junk fails the line instead of falling through
/// to the start branch, mirroring the talc choice followed by `eof`.
fn autonumber_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  if take_keyword(cursor, "autonumber") {
    if cursor.skip_inline_space1() {
      if take_keyword(cursor, "stop") {
        cursor.skip_inline_spaces()
        if cursor.is_eof() {
          return Some(@seq.AutonumberStop)
        }
        ignore(cursor.restore(start))
        return None
      }
      if take_keyword(cursor, "resume") {
        let increment = optional_digit_run(cursor)
        let format = optional_quoted(cursor)
        cursor.skip_inline_spaces()
        if cursor.is_eof() {
          return Some(@seq.AutonumberResume({ increment, format, }))
        }
        ignore(cursor.restore(start))
        return None
      }
      if take_keyword(cursor, "inc") {
        let value = optional_alpha_run(cursor)
        cursor.skip_inline_spaces()
        if cursor.is_eof() {
          return Some(@seq.AutonumberIncrement(value))
        }
        ignore(cursor.restore(start))
        return None
      }
    }
  }
  ignore(cursor.restore(start))
  if take_keyword(cursor, "autonumber") {
    cursor.skip_inline_spaces()
    let start_value = cursor.take_while(char => !is_inline_whitespace(char))
    let start_value = if start_value.length() > 0 {
      Some(start_value)
    } else {
      None
    }
    let increment = optional_digit_run(cursor)
    let format = optional_quoted(cursor)
    cursor.skip_inline_spaces()
    if cursor.is_eof() {
      return Some(@seq.Autonumber({ start: start_value, increment, format, }))
    }
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.restore(start))
  None
}

///|
/// A branch whose pattern matches commits the toggle line: trailing junk
/// fails the whole line instead of retrying later branches, mirroring the
/// talc choice followed by the trailing `inline_spaces` and `eof`.
fn toggle_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  if take_keyword(cursor, "autoactivate") {
    let saved = cursor.offset()
    if cursor.skip_inline_space1() && take_keyword(cursor, "on") {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.Autoactivate(true))
      }
      ignore(cursor.restore(start))
      return None
    }
    ignore(cursor.restore(saved))
    if cursor.skip_inline_space1() && take_keyword(cursor, "off") {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.Autoactivate(false))
      }
      ignore(cursor.restore(start))
      return None
    }
    ignore(cursor.restore(start))
  }
  if take_keyword(cursor, "hide") {
    if cursor.skip_inline_space1() && take_keyword(cursor, "footbox") {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.Footbox(false))
      }
      ignore(cursor.restore(start))
      return None
    }
    ignore(cursor.restore(start))
  }
  if take_keyword(cursor, "footbox") {
    let saved = cursor.offset()
    if cursor.skip_inline_space1() && take_keyword(cursor, "on") {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.Footbox(true))
      }
      ignore(cursor.restore(start))
      return None
    }
    ignore(cursor.restore(saved))
    if cursor.skip_inline_space1() && take_keyword(cursor, "off") {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.Footbox(false))
      }
      ignore(cursor.restore(start))
      return None
    }
    ignore(cursor.restore(start))
  }
  let hidden = if take_keyword(cursor, "hide") {
    Some(true)
  } else if take_keyword(cursor, "show") {
    Some(false)
  } else {
    None
  }
  match hidden {
    Some(hidden) =>
      if cursor.skip_inline_space1() {
        ignore(cursor.consume('@'))
        if take_keyword(cursor, "unlinked") {
          cursor.skip_inline_spaces()
          if cursor.is_eof() {
            return Some(@seq.HideUnlinked(hidden))
          }
          ignore(cursor.restore(start))
          return None
        }
        ignore(cursor.restore(start))
        None
      } else {
        ignore(cursor.restore(start))
        None
      }
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn url_command_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  guard take_keyword(cursor, "url") else { return None }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  if take_keyword(cursor, "of") || take_keyword(cursor, "for") {
    guard cursor.skip_inline_space1() else {
      ignore(cursor.restore(start))
      return None
    }
  }
  match take_quoted_or_ident(cursor) {
    None => {
      ignore(cursor.restore(start))
      None
    }
    Some(code) => {
      guard cursor.skip_inline_space1() else {
        ignore(cursor.restore(start))
        return None
      }
      if take_keyword(cursor, "is") {
        guard cursor.skip_inline_space1() else {
          ignore(cursor.restore(start))
          return None
        }
      }
      match cursor.take_url_value() {
        None => {
          ignore(cursor.restore(start))
          None
        }
        Some(url) => {
          cursor.skip_inline_spaces()
          guard cursor.is_eof() else {
            ignore(cursor.restore(start))
            return None
          }
          Some(@seq.Url(code, url))
        }
      }
    }
  }
}

///|
fn anchor(cursor : @tokenizer.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('{') else { return None }
  let code = take_ident(cursor)
  guard code.length() > 0 && cursor.consume('}') else {
    ignore(cursor.restore(start))
    return None
  }
  Some(code)
}

///|
/// A branch whose pattern matches commits the miscellaneous line: trailing
/// junk fails the whole line instead of retrying later branches, mirroring
/// the talc choice followed by the trailing `inline_spaces` and `eof`.
fn miscellaneous_event_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  if take_keyword(cursor, "ignore") &&
    cursor.skip_inline_space1() &&
    take_keyword(cursor, "newpage") {
    cursor.skip_inline_spaces()
    if cursor.is_eof() {
      return Some(@seq.IgnoreNewpage)
    }
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.restore(start))
  if take_keyword(cursor, "autonewpage") && cursor.skip_inline_space1() {
    let digits = cursor.take_while(Char::is_ascii_digit)
    if digits.length() > 0 {
      cursor.skip_inline_spaces()
      if cursor.is_eof() {
        return Some(@seq.AutoNewpage(optional_digits(digits)))
      }
      ignore(cursor.restore(start))
      return None
    }
  }
  ignore(cursor.restore(start))
  ignore(cursor.consume('&'))
  cursor.skip_inline_spaces()
  if take_keyword(cursor, "return") {
    let value = cursor.take_rest()
    return Some(@seq.Return({ value: @tokenizer.normalize_label(value), }))
  }
  ignore(cursor.restore(start))
  match anchor(cursor) {
    Some(_) => {
      cursor.skip_inline_spaces()
      if cursor.consume_literal("<->") {
        cursor.skip_inline_spaces()
        if anchor(cursor) is Some(_) {
          cursor.skip_inline_spaces()
          if cursor.consume(':') {
            ignore(cursor.take_rest())
          }
          cursor.skip_inline_spaces()
          if cursor.is_eof() {
            return Some(@seq.LinkAnchor)
          }
          ignore(cursor.restore(start))
          return None
        }
        ignore(cursor.restore(start))
        None
      } else {
        ignore(cursor.restore(start))
        None
      }
    }
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn newpage_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  ignore(cursor.consume('@'))
  guard take_keyword(cursor, "newpage") else {
    ignore(cursor.restore(start))
    return None
  }
  let title = cursor.take_rest()
  Some(@seq.Newpage({ title: @tokenizer.normalize_label(title), }))
}

///|
/// Command matching follows `SequenceDiagramFactory` order for the simple
/// commands; each alternative consumes the whole line before succeeding.
fn simple_event_line_syntax(cursor : @tokenizer.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  let event = if box_line_syntax(cursor) is Some(value) {
    value
  } else if grouping_line_syntax(cursor) is Some(value) {
    value
  } else if life_event_line_syntax(cursor, "activate", @seq.Activate)
    is Some(value) {
    value
  } else if deactivate_line_syntax(cursor) is Some(value) {
    value
  } else if life_event_line_syntax(cursor, "destroy", @seq.Destroy)
    is Some(value) {
    value
  } else if divider_line_syntax(cursor) is Some(value) {
    value
  } else if delay_line_syntax(cursor) is Some(value) {
    value
  } else if hspace_line_syntax(cursor) is Some(value) {
    value
  } else if autonumber_line_syntax(cursor) is Some(value) {
    value
  } else if toggle_line_syntax(cursor) is Some(value) {
    value
  } else if url_command_line_syntax(cursor) is Some(value) {
    value
  } else if miscellaneous_event_line_syntax(cursor) is Some(value) {
    value
  } else if newpage_line_syntax(cursor) is Some(value) {
    value
  } else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(event)
}
