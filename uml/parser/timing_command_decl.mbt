///|
/// `robust`, `concise` and `rectangle` player declarations, mirroring
/// `CommandRobustConcise`.
fn parse_robust_concise(parser : TimingParser, cursor : @parse.Cursor) -> Bool {
  let compact = take_compact(cursor)
  let kind = if match_keyword(cursor, "robust") {
    @flow.PlayerKind::Robust
  } else if match_keyword(cursor, "concise") {
    @flow.PlayerKind::Concise
  } else if match_keyword(cursor, "rectangle") {
    @flow.PlayerKind::Rectangle
  } else {
    return false
  }
  guard space_one_or_more(cursor) else { return false }
  let mut title = ""
  let mut stereotype = None
  if cursor.peek() == Some('"') {
    guard parse_quoted(cursor) is Some(full) else { return false }
    title = full
    skip_spaces(cursor)
    if parse_stereotype(cursor) is Some(st) {
      stereotype = Some(st)
      skip_spaces(cursor)
    }
    guard match_keyword(cursor, "as") else { return false }
    guard space_one_or_more(cursor) else { return false }
  }
  guard parse_full_code(cursor) is Some(code) else { return false }
  let (stereotype2, color) = parse_declaration_tail(cursor)
  guard cursor.is_eof() else { return false }
  let stereotype = stereotype.map_or(stereotype2, value => Some(value))
  ignore(parser.declare_player(code, title, kind, compact, stereotype, color))
  true
}

///|
/// Matches `[0-9]+(\.[0-9]+)?`, the clock period/pulse/offset literals.
fn parse_positive_decimal(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  let whole = cursor.take_while(char => char >= '0' && char <= '9')
  guard whole.length() > 0 else { return None }
  if cursor.consume('.') {
    let fraction = cursor.take_while(char => char >= '0' && char <= '9')
    guard fraction.length() > 0 else {
      ignore(cursor.restore(start))
      return None
    }
  }
  Some(cursor.slice(start, cursor.offset()))
}

///|
/// `clock` player declarations, mirroring `CommandClock`.
///
/// A clock adds its period as a time mark and otherwise behaves like every
/// other player declaration.
fn parse_clock(parser : TimingParser, cursor : @parse.Cursor) -> Bool {
  let compact = take_compact(cursor)
  guard match_keyword(cursor, "clock") else { return false }
  guard space_one_or_more(cursor) else { return false }
  let mut title = ""
  if cursor.peek() == Some('"') {
    guard take_full_as(cursor) is Some(full) else { return false }
    title = full
  }
  guard with_full_code(cursor, code => {
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "with") else { return None }
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "period") else { return None }
      guard space_one_or_more(cursor) else { return None }
      guard parse_positive_decimal(cursor) is Some(period) else { return None }
      let mut pulse = None
      let checkpoint = cursor.offset()
      if space_one_or_more(cursor) {
        if match_keyword(cursor, "pulse") {
          guard space_one_or_more(cursor) else { return None }
          guard parse_positive_decimal(cursor) is Some(value) else {
            return None
          }
          pulse = Some(value)
        } else {
          ignore(cursor.restore(checkpoint))
        }
      }
      let mut offset = None
      if space_one_or_more(cursor) {
        if match_keyword(cursor, "offset") {
          guard space_one_or_more(cursor) else { return None }
          guard parse_positive_decimal(cursor) is Some(value) else {
            return None
          }
          offset = Some(value)
        } else {
          ignore(cursor.restore(checkpoint))
        }
      }
      Some((code, period, pulse, offset))
    })
    is Some((code, period, pulse, offset)) else {
    return false
  }
  skip_spaces(cursor)
  let stereotype = parse_stereotype(cursor)
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  // A clock is a regular player: its `compact` flag applies and it becomes
  // the current player, like every other declaration. (The Java
  // `createPlayerClock` drops both by mistake.)
  let compact = parser.diagram.compact_by_default || compact
  let player : @flow.TimingPlayer = {
    code,
    title,
    kind: @flow.PlayerKind::Clock,
    compact,
    stereotype,
    background_color: None,
    states: [],
    initial: None,
    changes: [],
    notes: [],
    constraints: [],
    period: Some(period),
    pulse,
    offset,
    bounds: None,
    ticks_every: None,
    height: None,
  }
  upsert_player(parser.diagram, player)
  parser.diagram.clocks.push(code)
  parser.diagram.last_player = Some(code)
  let time = tick(
    @flow.Decimal::parse(period).unwrap(),
    @flow.TimingFormat::Decimal,
  )
  // The period becomes a ruler mark but, unlike `@time`, does not move the
  // current time forward.
  add_time_mark(parser.diagram, time)
  true
}

///|
/// Matches `-?[0-9]*\.?[0-9]+`, the analog bound literals.
fn parse_bound_number(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  ignore(cursor.consume('-'))
  let whole = cursor.take_while(char => char >= '0' && char <= '9')
  ignore(cursor.consume('.'))
  let fraction = cursor.take_while(char => char >= '0' && char <= '9')
  if whole.length() == 0 && fraction.length() == 0 {
    ignore(cursor.restore(start))
    None
  } else {
    Some(cursor.slice(start, cursor.offset()))
  }
}

///|
/// `analog` player declarations, mirroring `CommandAnalog`.
fn parse_analog(parser : TimingParser, cursor : @parse.Cursor) -> Bool {
  let compact = take_compact(cursor)
  guard match_keyword(cursor, "analog") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard parse_quoted(cursor) is Some(title) else { return false }
  skip_spaces(cursor)
  let mut stereotype = None
  if parse_stereotype(cursor) is Some(st) {
    stereotype = Some(st)
    skip_spaces(cursor)
  }
  let mut bounds = None
  if match_keyword(cursor, "between") || match_keyword(cursor, "from") {
    guard space_one_or_more(cursor) else { return false }
    guard parse_bound_number(cursor) is Some(start) else { return false }
    guard space_one_or_more(cursor) else { return false }
    if !match_keyword(cursor, "and") && !match_keyword(cursor, "to") {
      return false
    }
    guard space_one_or_more(cursor) else { return false }
    guard parse_bound_number(cursor) is Some(end) else { return false }
    guard space_one_or_more(cursor) else { return false }
    bounds = Some((start, end))
  }
  guard match_keyword(cursor, "as") else { return false }
  guard space_one_or_more(cursor) else { return false }
  guard parse_full_code(cursor) is Some(code) else { return false }
  skip_spaces(cursor)
  let stereotype2 = parse_stereotype(cursor)
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  let stereotype = stereotype.map_or(stereotype2, value => Some(value))
  let player = parser.declare_player(
    code,
    title,
    @flow.PlayerKind::Analog,
    compact,
    stereotype,
    None,
  )
  if bounds is Some(value) {
    player.bounds = Some(value)
  }
  true
}

///|
/// `binary` player declarations, mirroring `CommandBinary`.
fn parse_binary(parser : TimingParser, cursor : @parse.Cursor) -> Bool {
  let compact = take_compact(cursor)
  guard match_keyword(cursor, "binary") else { return false }
  guard space_one_or_more(cursor) else { return false }
  let mut title = ""
  let mut stereotype = None
  if cursor.peek() == Some('"') {
    guard parse_quoted(cursor) is Some(full) else { return false }
    title = full
    skip_spaces(cursor)
    if parse_stereotype(cursor) is Some(st) {
      stereotype = Some(st)
      skip_spaces(cursor)
    }
    guard match_keyword(cursor, "as") else { return false }
    guard space_one_or_more(cursor) else { return false }
  }
  guard parse_full_code(cursor) is Some(code) else { return false }
  skip_spaces(cursor)
  let stereotype2 = parse_stereotype(cursor)
  skip_spaces(cursor)
  guard cursor.is_eof() else { return false }
  let stereotype = stereotype.map_or(stereotype2, value => Some(value))
  ignore(
    parser.declare_player(
      code,
      title,
      @flow.PlayerKind::Binary,
      compact,
      stereotype,
      None,
    ),
  )
  true
}

///|
/// `CODE has STATE(,STATE)*`, mirroring `CommandDefineStateShort`.
fn parse_define_state_short(
  parser : TimingParser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard with_player_code(cursor, code => {
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "has") else { return None }
      guard space_one_or_more(cursor) else { return None }
      let first = cursor.take_while(is_state_decl_char)
      guard first.length() > 0 else { return None }
      let states = [first]
      while cursor.consume(',') {
        let state = cursor.take_while(is_state_decl_char)
        guard state.length() > 0 else { return None }
        states.push(state)
      }
      guard cursor.is_eof() else { return None }
      Some((code, states))
    })
    is Some((code, states)) else {
    return false
  }
  guard parser.player(code) is Some(player) else {
    raise parser.error("Unknown " + code)
  }
  guard player.is_state_player() else {
    raise parser.error("unsupported state definition on this player kind")
  }
  for state in states {
    player.states.push((state, state))
  }
  true
}

///|
/// `CODE has "LABEL" as STATE`, mirroring `CommandDefineStateLong`.
fn parse_define_state_long(
  parser : TimingParser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard with_player_code(cursor, code => {
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "has") else { return None }
      guard space_one_or_more(cursor) else { return None }
      guard parse_quoted(cursor) is Some(label) else { return None }
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "as") else { return None }
      guard space_one_or_more(cursor) else { return None }
      let state = cursor.take_while(is_code_char)
      guard state.length() > 0 else { return None }
      guard cursor.is_eof() else { return None }
      Some((code, state, label))
    })
    is Some((code, state, label)) else {
    return false
  }
  guard parser.player(code) is Some(player) else {
    raise parser.error("Unknown " + code)
  }
  guard player.is_state_player() else {
    raise parser.error("unsupported state definition on this player kind")
  }
  player.states.push((state, label))
  true
}

///|
/// Parses the shared tail of the change-state commands: optional color,
/// optional `: comment`, end of line.
fn parse_change_state_tail(cursor : @parse.Cursor) -> (String?, String?)? {
  skip_spaces(cursor)
  let color = timing_parse_color(cursor)
  skip_spaces(cursor)
  let comment = if cursor.consume(':') {
    skip_spaces(cursor)
    Some(take_rest(cursor))
  } else {
    None
  }
  skip_spaces(cursor)
  guard cursor.is_eof() else { return None }
  Some((color, comment))
}

///|
/// `CODE is STATE`, mirroring `CommandChangeStateByPlayerCode`: the change is
/// recorded at the current diagram time, which makes it the initial state
/// before any time mark exists.
fn parse_change_state_by_player_code(
  parser : TimingParser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard with_player_code(cursor, code => {
      skip_spaces(cursor)
      guard match_keyword(cursor, "is") else { return None }
      skip_spaces(cursor)
      with_state_spec(cursor, states => {
        guard parse_change_state_tail(cursor) is Some((color, comment)) else {
          return None
        }
        Some((code, states, color, comment))
      })
    })
    is Some((code, states, color, comment)) else {
    return false
  }
  guard parser.player(code) is Some(player) else {
    raise parser.error("Unknown \"" + code + "\"")
  }
  parser.set_player_state(player, parser.diagram.now, states, comment, color)
  true
}

///|
/// `CODE ticks (every|num on multiple) N`, mirroring `CommandTicks`: the
/// interval only applies to analog players and is silently ignored otherwise.
fn parse_ticks(
  parser : TimingParser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard with_full_code(cursor, code => {
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "ticks") else { return None }
      guard space_one_or_more(cursor) else { return None }
      if !match_keyword(cursor, "every") {
        guard match_keyword(cursor, "num") else { return None }
        guard space_one_or_more(cursor) else { return None }
        guard match_keyword(cursor, "on") else { return None }
        guard space_one_or_more(cursor) else { return None }
        guard match_keyword(cursor, "multiple") else { return None }
      }
      guard space_one_or_more(cursor) else { return None }
      let digits = cursor.take_while(char => char >= '0' && char <= '9')
      guard digits.length() > 0 else { return None }
      guard cursor.is_eof() else { return None }
      Some((code, digits))
    })
    is Some((code, digits)) else {
    return false
  }
  guard parser.player(code) is Some(player) else {
    raise parser.error("No such participant " + code)
  }
  if player.kind is @flow.PlayerKind::Analog {
    player.ticks_every = Some(parse_positive_int(digits))
  }
  true
}

///|
/// `CODE is N pixel(s) height`, mirroring `CommandPixelHeight`.
fn parse_pixel_height(
  parser : TimingParser,
  cursor : @parse.Cursor,
) -> Bool raise @parse.ParseError {
  guard with_full_code(cursor, code => {
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "is") else { return None }
      guard space_one_or_more(cursor) else { return None }
      let digits = cursor.take_while(char => char >= '0' && char <= '9')
      guard digits.length() > 0 else { return None }
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "pixel") else { return None }
      ignore(cursor.consume('s'))
      guard space_one_or_more(cursor) else { return None }
      guard match_keyword(cursor, "height") else { return None }
      guard cursor.is_eof() else { return None }
      Some((code, digits))
    })
    is Some((code, digits)) else {
    return false
  }
  guard parser.player(code) is Some(player) else {
    raise parser.error("No such participant " + code)
  }
  player.height = Some(parse_positive_int(digits))
  true
}
