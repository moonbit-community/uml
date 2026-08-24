///|
/// `@TIME (as : CODE)?`, mirroring `CommandAtTime`.
fn parse_at_time(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard cursor.consume('@') else { return false }
  guard with_time_expr(cursor, expr => {
      let code = if space_one_or_more(cursor) {
        guard match_keyword(cursor, "as") else { return None }
        guard space_one_or_more(cursor) else { return None }
        guard cursor.consume(':') else { return None }
        let code = cursor.take_while(is_code_dot_char)
        guard code.length() > 0 else { return None }
        Some(code)
      } else {
        None
      }
      skip_spaces(cursor)
      guard cursor.is_eof() else { return None }
      Some((expr, code))
    })
    is Some((expr, code)) else {
    return false
  }
  guard resolve_time_expr(parser, Some(expr)) is Some(tick) else {
    raise parser.error("What time?")
  }
  parser.add_time(tick, code)
  true
}

///|
/// `@CODE`, mirroring `CommandAtPlayer`: selects the current player.
fn parse_at_player(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard cursor.consume('@') else { return false }
  guard parse_player_code(cursor) is Some(code) else { return false }
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  guard parser.player(code) is Some(_) else {
    raise parser.error("No such participant " + code)
  }
  parser.diagram.last_player = Some(code)
  true
}

///|
/// Matches the optional `@TIME` expression of a message or constraint,
/// restoring the cursor when the expression is absent or malformed.
fn parse_optional_time(cursor : @parse.Cursor) -> TimeExpr? {
  let checkpoint = cursor.offset()
  guard cursor.consume('@') else { return None }
  match with_time_expr(cursor, expr => Some(expr)) {
    Some(expr) => Some(expr)
    None => {
      ignore(cursor.restore(checkpoint))
      None
    }
  }
}

///|
/// Matches the `[-]+` body and optional `[...]` style of a message arrow.
fn parse_arrow(cursor : @parse.Cursor) -> (String, String?)? {
  let body = cursor.take_while(char => char == '-')
  guard body.length() > 0 else { return None }
  let style = if cursor.consume('[') {
    guard parse_arrow_style(cursor) is Some(style) else { return None }
    guard cursor.consume(']') else { return None }
    Some(style)
  } else {
    None
  }
  guard cursor.consume('>') else { return None }
  Some((body, style))
}

///|
/// Matches one `LINE_STYLE` item: `#\w+`, a style keyword, or `thickness=\d+`.
fn parse_arrow_style_item(cursor : @parse.Cursor) -> Bool {
  if cursor.consume('#') {
    guard take_word(cursor).length() > 0 else { return false }
    return true
  }
  for
    keyword in [
      "dotted", "dashed", "plain", "bold", "hidden", "norank", "single", "node",
    ] {
    if match_keyword(cursor, keyword) {
      return true
    }
  }
  let checkpoint = cursor.offset()
  guard match_keyword(cursor, "thickness") else { return false }
  guard cursor.consume('=') else {
    ignore(cursor.restore(checkpoint))
    return false
  }
  guard match_ascii_digits(cursor) is Some(_) else {
    ignore(cursor.restore(checkpoint))
    return false
  }
  true
}

///|
/// Matches the comma-separated `LINE_STYLE` list inside `[...]`.
fn parse_arrow_style(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard parse_arrow_style_item(cursor) else { return None }
  while cursor.consume(',') {
    guard parse_arrow_style_item(cursor) else {
      ignore(cursor.restore(start))
      return None
    }
  }
  Some(cursor.slice(start, cursor.offset()))
}

///|
/// `PART1 @TIME1? --> @TIME2? PART2 (: MESSAGE)?`, mirroring
/// `CommandTimeMessage`.
fn parse_time_message(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard parse_player_code(cursor) is Some(part1) else { return false }
  let time1 = parse_optional_time(cursor)
  skip_spaces(cursor)
  guard parse_arrow(cursor) is Some((_, style)) else { return false }
  skip_spaces(cursor)
  guard parse_player_code(cursor) is Some(part2) else { return false }
  let time2 = parse_optional_time(cursor)
  skip_spaces(cursor)
  let label = if cursor.consume(':') {
    skip_spaces(cursor)
    Some(take_rest(cursor))
  } else {
    None
  }
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  guard parser.player(part1) is Some(_) else {
    raise parser.error("No such element: " + part1)
  }
  guard parser.player(part2) is Some(_) else {
    raise parser.error("No such element: " + part2)
  }
  let tick1 = resolve_time_expr(parser, time1)
  let tick2 = resolve_time_expr(parser, time2)
  parser.diagram.messages.push({
    player1: part1,
    tick1,
    player2: part2,
    tick2,
    label,
    style,
  })
  true
}

///|
/// `note (top|bottom) of CODE : NOTE`, mirroring `CommandNote`.
fn parse_note(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard match_keyword(cursor, "note") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard parse_note_position(cursor) is Some(position) else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard match_keyword(cursor, "of") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard with_player_code(cursor, code => {
      skip_spaces(cursor)
      let checkpoint = cursor.offset()
      if parse_tags(cursor) {
        skip_spaces(cursor)
      } else {
        ignore(cursor.restore(checkpoint))
      }
      let stereotype = parse_stereotype(cursor)
      skip_spaces(cursor)
      guard cursor.consume(':') else { return None }
      skip_spaces(cursor)
      let text = take_rest(cursor)
      guard text.length() > 0 else { return None }
      skip_spaces(cursor)
      guard cursor.is_eof() else { return None }
      Some((code, position, stereotype, text))
    })
    is Some((code, position, stereotype, text)) else {
    return false
  }
  guard parser.player(code) is Some(player) else {
    raise parser.error("Unknown \"" + code + "\"")
  }
  player.notes.push({ when: parser.diagram.now, position, text, stereotype })
  true
}

///|
fn parse_note_position(cursor : @parse.Cursor) -> String? {
  if match_keyword(cursor, "top") {
    Some("top")
  } else if match_keyword(cursor, "bottom") {
    Some("bottom")
  } else {
    None
  }
}

///|
/// The multiline `note (top|bottom) of CODE` block, mirroring
/// `CommandNoteLong`: body lines run until `end note`; comment lines are
/// dropped and a common leading indentation is removed from the rest.
fn parse_note_long(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard match_keyword(cursor, "note") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard parse_note_position(cursor) is Some(position) else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard match_keyword(cursor, "of") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard parse_player_code(cursor) is Some(code) else { return false }
  skip_spaces(cursor)
  let stereotype = parse_stereotype(cursor)
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  let lines = []
  let mut index = parser.index + 1
  while index < parser.lines.length() {
    let raw = @parse.strip_line_comment_preserving_indent(parser.lines[index])
    if raw.trim().length() == 0 {
      index += 1
      continue
    }
    if raw.equal_ignore_ascii_case("end note") ||
      raw.equal_ignore_ascii_case("endnote") {
      parser.index = index
      guard parser.player(code) is Some(player) else {
        raise parser.error("Unknown \"" + code + "\"")
      }
      remove_empty_columns(lines)
      player.notes.push({
        when: parser.diagram.now,
        position,
        text: lines.join("\n"),
        stereotype,
      })
      return true
    }
    lines.push(raw)
    index += 1
  }
  raise parser.error("unclosed note")
}

///|
/// Removes common leading space and tab columns from non-empty lines,
/// mirroring `BlocLines.removeEmptyColumns`.
fn remove_empty_columns(lines : Array[String]) -> Unit {
  let removable = () => {
    let mut all_empty = true
    for line in lines {
      if line.length() == 0 {
        continue
      }
      all_empty = false
      if !line.has_prefix(" ") && !line.has_prefix("\t") {
        return false
      }
    }
    !all_empty
  }
  while removable() {
    for index in 0..<lines.length() {
      if lines[index].length() > 0 {
        lines[index] = lines[index][1:].to_owned()
      }
    }
  }
}

///|
/// `PART1? @TIME1 <--[style]--> @TIME2 (: MESSAGE)?`, mirroring
/// `CommandConstraint`: a relative `+time` on the second end is resolved
/// against the first tick.
fn parse_constraint(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  let part1 = if cursor.peek() == Some('@') {
    None
  } else {
    parse_player_code(cursor)
  }
  guard cursor.consume('@') else { return false }
  guard with_time_expr(cursor, expr1 => {
      skip_spaces(cursor)
      guard cursor.consume('<') else { return None }
      let dashes = cursor.take_while(char => char == '-')
      guard dashes.length() > 0 else { return None }
      let style = if cursor.consume('[') {
        guard parse_arrow_style(cursor) is Some(style) else { return None }
        guard cursor.consume(']') else { return None }
        Some(style)
      } else {
        None
      }
      ignore(cursor.skip_while(char => char == '-'))
      guard cursor.consume('>') else { return None }
      skip_spaces(cursor)
      guard cursor.consume('@') else { return None }
      with_time_expr(cursor, expr2 => {
        skip_spaces(cursor)
        let message = if cursor.consume(':') {
          skip_spaces(cursor)
          Some(take_rest(cursor))
        } else {
          None
        }
        skip_spaces(cursor)
        guard cursor.is_eof() else { return None }
        Some((expr1, expr2, style, message))
      })
    })
    is Some((expr1, expr2, style, message)) else {
    return false
  }
  let player = if part1 is Some(code) {
    parser.require_player(code)
  } else {
    guard parser.diagram.last_player is Some(code) else {
      raise parser.error("You have to provide a participant")
    }
    parser.require_player(code)
  }
  guard resolve_time_expr(parser, Some(expr1)) is Some(tick1) else {
    raise parser.error("Unknown time label")
  }
  let saved = parser.diagram.now
  parser.diagram.now = Some(tick1)
  let tick2 = resolve_time_expr(parser, Some(expr2))
  parser.diagram.now = saved
  guard tick2 is Some(value) else { raise parser.error("Unknown time label") }
  player.constraints.push({ tick1, tick2: value, message, style })
  true
}

///|
/// `scale N [unit] as N pixel(s)`, mirroring `CommandScalePixel`.
fn parse_scale_pixel(
  parser : Parser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard match_keyword(cursor, "scale") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard match_ascii_digits(cursor) is Some(tick) else { return false }
  let checkpoint = cursor.offset()
  if cursor.peek() is Some(char) && char.is_whitespace() {
    ignore(cursor.advance())
  }
  let unit = if cursor.peek() is Some(unit_char) &&
    (
      unit_char == 's' ||
      unit_char == 'm' ||
      unit_char == 'h' ||
      unit_char == 'd' ||
      unit_char == 'D' ||
      unit_char == 'y' ||
      unit_char == 'Y'
    ) {
    ignore(cursor.advance())
    Some(unit_char.to_string())
  } else {
    ignore(cursor.restore(checkpoint))
    None
  }
  guard space_one_or_more(cursor) else { return false }
  guard match_keyword(cursor, "as") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard match_ascii_digits(cursor) is Some(pixel) else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard match_keyword(cursor, "pixel") else { return false }
  ignore(cursor.consume('s'))
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  let tick = tick.to_int64() * scale_unit_factor(unit)
  let pixel = pixel.to_int64()
  guard tick > 0L && pixel > 0L else { raise parser.error("Bad value") }
  parser.diagram.scale = Some((tick, pixel))
  true
}

///|
fn scale_unit_factor(unit : String?) -> Int64 {
  match unit {
    None => 1L
    Some("s") => 1L
    Some("m") => 60L
    Some("h") => 3600L
    Some("d") | Some("D") => 86400L
    Some("y") | Some("Y") => 31557600L
    _ => 1L
  }
}

///|
/// `(hide|manual) time.?axis`, mirroring `CommandHideTimeAxis`: the single
/// character between `time` and `axis` is optional.
fn parse_hide_time_axis(parser : Parser, cursor : @parse.Cursor) -> Bool {
  let manual = match_keyword(cursor, "manual")
  if !manual && !match_keyword(cursor, "hide") {
    return false
  }
  guard space_one_or_more(cursor) else { return false }
  guard match_keyword(cursor, "time") else { return false }
  if !match_keyword(cursor, "axis") {
    ignore(cursor.advance())
    guard match_keyword(cursor, "axis") else { return false }
  }
  guard cursor.is_eof() else { return false }
  parser.diagram.time_axis = if manual { Manual } else { Hidden }
  true
}

///|
/// `highlight FROM to TO (#color)? (: CAPTION)?`, mirroring `CommandHighlight`.
fn parse_highlight(parser : Parser, cursor : @parse.Cursor) -> Bool {
  skip_spaces(cursor)
  guard match_keyword(cursor, "highlight") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard with_time_expr(cursor, from => {
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "to") else { return None }
      guard space_one_or_more(cursor) else { return None }
      with_time_expr(cursor, to => {
        skip_spaces(cursor)
        let color = parse_color(cursor)
        skip_spaces(cursor)
        let caption = if cursor.consume(':') {
          skip_spaces(cursor)
          Some(take_rest(cursor))
        } else {
          None
        }
        skip_spaces(cursor)
        guard cursor.is_eof() else { return None }
        Some((from, to, color, caption))
      })
    })
    is Some((from, to, color, caption)) else {
    return false
  }
  let tick_from = resolve_time_expr(parser, Some(from))
  let tick_to = resolve_time_expr(parser, Some(to))
  parser.diagram.highlights.push({
    from: tick_from,
    to: tick_to,
    caption,
    color,
  })
  true
}

///|
/// `mode compact`, mirroring `CommandModeCompact`: every player declared after
/// the command becomes compact.
fn parse_mode_compact(parser : Parser, cursor : @parse.Cursor) -> Bool {
  guard match_keyword(cursor, "mode") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard match_keyword(cursor, "compact") else { return false }
  guard cursor.is_eof() else { return false }
  parser.diagram.compact_by_default = true
  true
}

///|
/// `use date format "FORMAT"`, mirroring `CommandUseDateFormat`.
fn parse_use_date_format(parser : Parser, cursor : @parse.Cursor) -> Bool {
  guard match_keyword(cursor, "use") else { return false }
  skip_spaces(cursor)
  guard match_keyword(cursor, "date") else { return false }
  skip_spaces(cursor)
  guard match_keyword(cursor, "format") else { return false }
  skip_spaces(cursor)
  guard parse_quoted(cursor) is Some(format) else { return false }
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  parser.diagram.date_format = Some(format)
  true
}
