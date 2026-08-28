///|
/// The parsing context mirroring `@flow.TimingDiagram` as mutated by the commands.
priv struct TimingParser {
  diagram : @flow.TimingDiagram
  lines : Array[String]
  mut index : Int
}

///|
fn TimingParser::new(input : String) -> TimingParser {
  {
    diagram: {
      players: [],
      clocks: [],
      codes: [],
      messages: [],
      highlights: [],
      time_marks: [],
      now: None,
      last_player: None,
      time_axis: @flow.TimeAxisStrategy::Automatic,
      compact_by_default: false,
      date_format: None,
      scale: None,
      style: @style.DocumentStyle::empty(),
    },
    lines: @tokenizer.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array(),
    index: 0,
  }
}

///|
fn TimingParser::line_number(self : TimingParser) -> Int {
  self.index + 1
}

///|
fn TimingParser::error(
  self : TimingParser,
  message : String,
) -> @tokenizer.ParseError {
  @tokenizer.SyntaxError(self.line_number(), message)
}

///|
fn TimingParser::player(
  self : TimingParser,
  code : String,
) -> @flow.TimingPlayer? {
  self.diagram.player(code)
}

///|
/// Captures the remaining text and consumes it, like the trailing `.*`
/// groups of the compiled regexes.
fn take_rest(cursor : @tokenizer.Cursor) -> String {
  let text = cursor.remaining()
  ignore(cursor.restore(cursor.length()))
  text
}

///|
fn TimingParser::require_player(
  self : TimingParser,
  code : String,
) -> @flow.TimingPlayer raise @tokenizer.ParseError {
  guard self.player(code) is Some(player) else {
    raise self.error("No such participant " + code)
  }
  player
}

///|
/// Replaces or appends a player by code, mirroring the `LinkedHashMap.put`
/// of the Java `players` map: an existing code keeps its position.
fn upsert_player(
  diagram : @flow.TimingDiagram,
  player : @flow.TimingPlayer,
) -> Unit {
  for index in 0..<diagram.players.length() {
    if diagram.players[index].code == player.code {
      diagram.players[index] = player
      return
    }
  }
  diagram.players.push(player)
}

///|
fn upsert_code(
  diagram : @flow.TimingDiagram,
  code : String,
  tick : @flow.TimeTick,
) -> Unit {
  for index in 0..<diagram.codes.length() {
    if diagram.codes[index].0 == code {
      diagram.codes[index] = (code, tick)
      return
    }
  }
  diagram.codes.push((code, tick))
}

///|
/// Adds a time mark to the ruler, mirroring `TimingRuler.addTime`: the mark is
/// kept sorted and deduplicated by value.
fn add_time_mark(diagram : @flow.TimingDiagram, tick : @flow.TimeTick) -> Unit {
  let mut index = 0
  while index < diagram.time_marks.length() {
    let compared = diagram.time_marks[index].compare(tick)
    if compared == 0 {
      return
    }
    if compared > 0 {
      break
    }
    index += 1
  }
  diagram.time_marks.insert(index, tick)
}

///|
fn TimingParser::add_time(
  self : TimingParser,
  tick : @flow.TimeTick,
  code : String?,
) -> Unit {
  self.diagram.now = Some(tick)
  add_time_mark(self.diagram, tick)
  if code is Some(value) {
    upsert_code(self.diagram, value, tick)
  }
}

///|
/// Inserts a timed change keeping the order of the Java `TreeSet`/`TreeMap`
/// collections: sorted by tick; duplicates keep the first entry for state
/// players and are replaced for binary and analog players.
fn insert_change(
  player : @flow.TimingPlayer,
  change : @flow.ChangeState,
  replace_duplicates : Bool,
) -> Unit {
  let mut index = 0
  while index < player.changes.length() {
    let compared = change.when
      .unwrap()
      .compare(player.changes[index].when.unwrap())
    if compared == 0 {
      if replace_duplicates {
        player.changes[index] = change
      }
      return
    }
    if compared > 0 {
      break
    }
    index += 1
  }
  player.changes.insert(index, change)
}

///|
fn decode_state(player : @flow.TimingPlayer, code : String) -> String {
  for item in player.states {
    if item.0 == code {
      return item.1
    }
  }
  code
}

///|
fn convert_binary_state(value : String) -> String {
  if value == "1" || value.equal_ignore_ascii_case("high") {
    "1"
  } else {
    "0"
  }
}

///|
/// Parses a state value for an analog player, mirroring `Double.parseDouble`
/// with a fallback of `0` on failure.
fn parse_analog_value(value : String) -> String {
  match @flow.Decimal::parse(value) {
    Some(decimal) => decimal.to_plain_string()
    None =>
      (@string.parse_double(value.to_string()) catch { _ => 0.0 }).to_string()
  }
}

///|
/// Records a state change on a player, mirroring `Player.setState` of the
/// matching subclass: state players decode codes to labels, binary players
/// convert to `1`/`0`, analog players keep a numeric value and also use it as
/// their initial state when none exists yet.
fn TimingParser::set_player_state(
  self : TimingParser,
  player : @flow.TimingPlayer,
  when : @flow.TimeTick?,
  states : Array[String],
  comment : String?,
  color : String?,
) -> Unit raise @tokenizer.ParseError {
  match player.kind {
    @flow.PlayerKind::Robust
    | @flow.PlayerKind::Concise
    | @flow.PlayerKind::Rectangle => {
      let decoded = states.map(state => decode_state(player, state))
      match when {
        None =>
          player.initial = Some({
            when: None,
            comment: None,
            color,
            states: [decoded[0]],
          })
        Some(tick) =>
          insert_change(
            player,
            { when: Some(tick), comment, color, states: decoded, },
            false,
          )
      }
    }
    @flow.PlayerKind::Binary => {
      let converted = states.map(convert_binary_state)
      match when {
        None =>
          player.initial = Some({
            when: None,
            comment,
            color,
            states: converted,
          })
        Some(tick) =>
          insert_change(
            player,
            { when: Some(tick), comment, color, states: converted, },
            true,
          )
      }
    }
    @flow.PlayerKind::Analog => {
      let value = parse_analog_value(states[0])
      let change : @flow.ChangeState = {
        when,
        comment: None,
        color: None,
        states: [value],
      }
      match when {
        None => player.initial = Some(change)
        Some(tick) => {
          insert_change(player, { ..change, when: Some(tick), }, true)
          if player.initial is None {
            player.initial = Some({ ..change, when: None, })
          }
        }
      }
    }
    @flow.PlayerKind::Clock =>
      raise self.error("unsupported state change on a clock player")
  }
}

///|
/// Consumes a `compact ` prefix, mirroring the optional `(compact) ` group.
fn take_compact(cursor : @tokenizer.Cursor) -> Bool {
  if !match_keyword(cursor, "compact") {
    return false
  }
  guard space_one_or_more(cursor) else { return false }
  true
}

///|
/// Consumes the optional `"FULL" as ` prefix of a player declaration.
fn take_full_as(cursor : @tokenizer.Cursor) -> String? {
  guard cursor.peek() == Some('"') else { return None }
  guard parse_quoted(cursor) is Some(full) else { return None }
  skip_spaces(cursor)
  guard match_keyword(cursor, "as") else { return None }
  guard space_one_or_more(cursor) else { return None }
  Some(full)
}

///|
/// Parses `[\p{L}_][%pLN_.]*`, the `PLAYER_CODE` class.
fn parse_player_code(cursor : @tokenizer.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.peek() is Some(char) && is_player_code_start(char) else {
    return None
  }
  ignore(cursor.advance())
  ignore(cursor.skip_while(is_player_code_char))
  Some(cursor.slice(start, cursor.offset()))
}

///|
/// Parses `[%pLN_.@]+`, the player declaration code class.
fn parse_full_code(cursor : @tokenizer.Cursor) -> String? {
  let code = cursor.take_while(is_code_char)
  if code.length() == 0 {
    None
  } else {
    Some(code)
  }
}

///|
/// Parses the optional stereotype and color tail shared by the player
/// declaration commands.
fn parse_declaration_tail(cursor : @tokenizer.Cursor) -> (String?, String?) {
  skip_spaces(cursor)
  let stereotype = parse_stereotype(cursor)
  skip_spaces(cursor)
  let color = timing_parse_color(cursor)
  skip_spaces(cursor)
  (stereotype, color)
}

///|
/// Creates a player, mirroring `createPlayerRobust` and friends: the new
/// player becomes the current one.
fn TimingParser::declare_player(
  self : TimingParser,
  code : String,
  title : String,
  kind : @flow.PlayerKind,
  compact : Bool,
  stereotype : String?,
  background_color : String?,
) -> @flow.TimingPlayer {
  let compact = self.diagram.compact_by_default || compact
  let player : @flow.TimingPlayer = {
    code,
    title,
    kind,
    compact,
    stereotype,
    background_color,
    states: [],
    initial: None,
    changes: [],
    notes: [],
    constraints: [],
    period: None,
    pulse: None,
    offset: None,
    bounds: None,
    ticks_every: None,
    height: None,
  }
  upsert_player(self.diagram, player)
  self.diagram.last_player = Some(code)
  player
}

///|
/// Consumes the common style blocks and directives, mirroring the commands of
/// `CommonCommands.addCommonCommands1` that the shared style machinery knows.
/// Returns true when the line was consumed.
fn TimingParser::consume_common_directive(
  self : TimingParser,
  line : String,
) -> Bool raise @tokenizer.ParseError {
  let lower = line.to_lower()
  if lower == "skinparam {" {
    self.index += 1
    let closed = @style.consume_skinparam_body(
      () => {
        guard self.index < self.lines.length() else { return None }
        let line = @tokenizer.strip_line_comment(self.lines[self.index])
        self.index += 1
        Some(line)
      },
      directive => self.diagram.style.apply(directive),
    )
    guard closed else {
      raise @tokenizer.SyntaxError(self.line_number(), "unclosed skinparam")
    }
    self.index -= 1
    return true
  }
  if lower == "title" ||
    lower == "caption" ||
    lower == "header" ||
    lower == "footer" ||
    lower == "legend" ||
    lower == "legend left" ||
    lower == "legend right" ||
    lower == "legend top" ||
    lower == "legend bottom" ||
    lower == "mainframe" {
    let kind = if lower.has_prefix("legend") {
      "legend"
    } else if lower == "mainframe" {
      "mainframe"
    } else {
      lower
    }
    self.consume_text_block(kind)
    return true
  }
  if lower == "hide footbox" || lower == "show footbox" {
    return true
  }
  if lower.has_prefix("scale ") {
    // The common `scale X`/`scale X/Y` form; the timing `scale N as N pixel`
    // form is left to the command list.
    if parse_common_scale(line) is Some(value) {
      self.diagram.style.apply(@style.Scale(value))
      return true
    }
    return false
  }
  if @style.parse_style_directive(line) is Some(directive) {
    self.diagram.style.apply(directive)
    return true
  }
  if lower.has_prefix("skinparam ") {
    return true
  }
  false
}

///|
fn parse_common_scale(line : String) -> String? {
  let cursor = @tokenizer.Cursor::new(line)
  guard match_keyword(cursor, "scale") else { return None }
  guard space_one_or_more(cursor) else { return None }
  let scale = cursor.take_while(char => {
    (char >= '0' && char <= '9') || char == '.'
  })
  guard scale.length() > 0 else { return None }
  let checkpoint = cursor.offset()
  if cursor.peek() is Some(char) && char.is_whitespace() {
    skip_spaces(cursor)
  }
  if match_keyword(cursor, "/") {
    skip_spaces(cursor)
    let div = cursor.take_while(char => {
      (char >= '0' && char <= '9') || char == '.'
    })
    guard div.length() > 0 && cursor.is_eof() else {
      ignore(cursor.restore(checkpoint))
      return None
    }
    return Some(scale + "/" + div)
  }
  ignore(cursor.restore(checkpoint))
  if cursor.is_eof() {
    Some(scale)
  } else {
    None
  }
}

///|
fn TimingParser::consume_text_block(
  self : TimingParser,
  kind : String,
) -> Unit raise @tokenizer.ParseError {
  let start = self.index
  let values = []
  self.index += 1
  while self.index < self.lines.length() {
    let line = @tokenizer.strip_line_comment_preserving_indent(
        self.lines[self.index],
      )
      .trim()
      .to_owned()
    if line.equal_ignore_ascii_case("end \{kind}") ||
      line.equal_ignore_ascii_case("end\{kind}") {
      self.diagram.style.apply(@style.TextBlock(kind, values.join("\n")))
      return
    }
    values.push(line)
    self.index += 1
  }
  raise @tokenizer.SyntaxError(start + 1, "unclosed \{kind}")
}

///|
fn TimingParser::parse_line(
  self : TimingParser,
) -> Unit raise @tokenizer.ParseError {
  let trimmed = self.lines[self.index].trim().to_owned()
  let lower = trimmed.to_lower()
  if trimmed.length() == 0 ||
    trimmed.has_prefix("'") ||
    lower == "@startuml" ||
    lower == "@enduml" ||
    @style.is_preprocessor_directive(trimmed) {
    return
  }
  if self.consume_common_directive(trimmed) {
    return
  }
  // Commands are tried in the registration order of
  // `TimingDiagramFactory.initCommandsList`.
  if parse_robust_concise(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_clock(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_analog(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_binary(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_define_state_short(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_define_state_long(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_change_state_by_player_code(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_at_time(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_at_player(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_time_message(self, @tokenizer.Cursor::new(trimmed)) ||
    timing_parse_note(self, @tokenizer.Cursor::new(trimmed)) ||
    timing_parse_note_long(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_constraint(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_scale_pixel(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_hide_time_axis(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_highlight(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_mode_compact(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_ticks(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_pixel_height(self, @tokenizer.Cursor::new(trimmed)) ||
    parse_use_date_format(self, @tokenizer.Cursor::new(trimmed)) {
    return
  }
  raise @tokenizer.SyntaxError(self.line_number(), "Syntax Error?")
}

///|
/// Parse a PlantUML timing diagram source into a `@flow.TimingDiagram`.
///
/// Commands are matched in the registration order of
/// `TimingDiagramFactory.initCommandsList`, and each command follows the
/// regex grammar and side effects of its Java `Command` counterpart.
pub fn parse_timing(
  input : String,
) -> @flow.TimingDiagram raise @tokenizer.ParseError {
  let parser = TimingParser::new(input)
  while parser.index < parser.lines.length() {
    parser.parse_line()
    parser.index += 1
  }
  parser.diagram
}
