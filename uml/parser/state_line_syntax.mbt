///|
priv struct StateDeclarationSyntax {
  code : String
  display : String?
  kind : @flow.StateKind
  description : String?
  stereotype : String?
  url : String?
  color : String?
  opens_group : Bool
}

///|
priv struct StateTransitionSyntax {
  source : String
  target : String
  direction : @flow.TransitionDirection
  length : Int
  line_style : String?
  has_cross_start : Bool
  has_circle_end : Bool
  label : String?
}

///|
priv struct StateEntityNoteSyntax {
  position : @flow.StateNotePosition
  target : String?
  color : String?
  body : StateNoteBody
}

///|
priv struct StateLinkNoteSyntax {
  body : StateNoteBody
  color : String?
  position : @flow.StateNotePosition?
}

///|
priv enum StateNoteBody {
  Inline(String)
  Resolved(String, @flow.StateNoteTextMode)
  Block
  BracedBlock
}

///|
priv struct TransitionArrowSyntax {
  direction : @flow.TransitionDirection
  length : Int
  line_style : String?
  has_cross_start : Bool
  has_circle_end : Bool
  reversed : Bool
}

///|
priv struct TransitionArrowParts {
  direction : @flow.TransitionDirection?
  length : Int
  first_style : String?
  second_style : String?
  has_cross_start : Bool
  has_circle_end : Bool
  reversed : Bool
}

///|
priv enum StateLineSyntax {
  Declaration(StateDeclarationSyntax)
  Frame(StateDeclarationSyntax)
  Field(code~ : String, text~ : String)
  Transition(StateTransitionSyntax)
  EntityNote(StateEntityNoteSyntax)
  LinkNote(StateLinkNoteSyntax)
}

///|
/// CommandAddField accepts quoted names or Unicode letters/numbers, dots,
/// and underscores, followed by a colon and one description line.
fn state_field(cursor : @tokenizer.Cursor) -> StateLineSyntax? {
  let code = if cursor.peek() == Some('"') {
    guard cursor.take_quoted_value() is Some(code) else { return None }
    code
  } else {
    cursor.take_while(char => {
      @identifier.is_identifier_char(char) || char == '.'
    })
  }
  guard !code.is_empty() else { return None }
  ignore(cursor.skip_inline_whitespace())
  guard cursor.consume(':') else { return None }
  ignore(cursor.skip_inline_whitespace())
  Some(Field(code~, text=cursor.take_rest_trimmed()))
}

///|
priv struct StateIdentifier {
  value : String
  quoted : Bool
}

///|
priv enum StateMetadata {
  Stereotype(String)
  Url(String)
  Color(String)
}

///|
priv struct StateMetadataValues {
  stereotype : String?
  url : String?
  color : String?
}

///|
/// Matches a quoted or unquoted state name. An unterminated quote falls back
/// to the raw unquoted token, mirroring the entity `quoted.attempt().or(...)`
/// grammar.
fn state_identifier(cursor : @tokenizer.Cursor) -> StateIdentifier? {
  if cursor.peek() == Some('"') {
    if cursor.take_quoted_value() is Some(value) {
      return Some({ value, quoted: true, })
    }
  }
  let value = cursor.take_while(char => {
    !char.is_whitespace() &&
    char != ':' &&
    char != '{' &&
    char != '#' &&
    char != '['
  })
  if value.length() > 0 {
    Some({ value, quoted: false, })
  } else {
    None
  }
}

///|
fn state_color(cursor : @tokenizer.Cursor) -> String? {
  cursor.take_color_value()
}

///|
fn state_metadata(cursor : @tokenizer.Cursor) -> StateMetadata? {
  let start = cursor.offset()
  if cursor.take_stereotype_value() is Some(value) {
    return Some(Stereotype(value))
  }
  ignore(cursor.restore(start))
  if cursor.take_url_value() is Some(value) {
    return Some(Url(value))
  }
  ignore(cursor.restore(start))
  match state_color(cursor) {
    Some(value) => Some(Color(value))
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn metadata_values(metadata : Array[StateMetadata]) -> StateMetadataValues {
  let mut stereotype = None
  let mut url = None
  let mut color = None
  for entry in metadata {
    match entry {
      Stereotype(value) => stereotype = Some(stereotype.unwrap_or("") + value)
      Url(value) => url = Some(value)
      Color(value) => color = Some(value)
    }
  }
  { stereotype, url, color, }
}

///|
fn state_declaration(
  cursor : @tokenizer.Cursor,
  keyword : String,
) -> StateDeclarationSyntax? {
  guard cursor.consume_literal(keyword) && cursor.skip_inline_whitespace() > 0 else {
    return None
  }
  guard state_identifier(cursor) is Some(first) else { return None }
  ignore(cursor.skip_inline_whitespace())
  let alias_value : StateIdentifier? = if cursor.consume_literal("as") {
    ignore(cursor.skip_inline_whitespace())
    guard state_identifier(cursor) is Some(second) else { return None }
    ignore(cursor.skip_inline_whitespace())
    Some(second)
  } else {
    None
  }
  let metadata = []
  while true {
    let saved = cursor.offset()
    guard state_metadata(cursor) is Some(entry) else {
      ignore(cursor.restore(saved))
      break
    }
    metadata.push(entry)
    ignore(cursor.skip_inline_whitespace())
  }
  let opens_group = if cursor.consume_literal("{") ||
    cursor.consume_literal("begin") {
    ignore(cursor.skip_inline_whitespace())
    true
  } else {
    false
  }
  let description = if cursor.consume(':') {
    ignore(cursor.skip_inline_whitespace())
    Some(cursor.take_rest_trimmed())
  } else {
    None
  }
  guard cursor.is_eof() else { return None }
  Some(
    declaration_syntax(first, alias_value, metadata, description, opens_group),
  )
}

///|
fn declaration_syntax(
  first : StateIdentifier,
  alias_value : StateIdentifier?,
  metadata : Array[StateMetadata],
  description : String?,
  opens_group : Bool,
) -> StateDeclarationSyntax {
  let values = metadata_values(metadata)
  let (code, display) = alias_value.map_or((first.value, None), second => {
    if first.quoted {
      (second.value, Some(first.value))
    } else {
      (first.value, Some(second.value))
    }
  })
  // Group declarations use CommandCreatePackage2 rather than the leaf
  // pseudo-state factory, even when their stereotype names match one.
  let kind = if opens_group {
    @flow.StateKind::Normal
  } else {
    state_stereotype_kind(values.stereotype)
  }
  {
    code,
    display,
    kind,
    description,
    stereotype: values.stereotype,
    url: values.url,
    color: values.color,
    opens_group,
  }
}

///|
/// Matches `[*]`, `[H*]`, `[H]`, `==name==`, or a state identifier, consuming
/// trailing inline whitespace like the talc `symbol`/`lexeme` wrappers.
fn state_endpoint(cursor : @tokenizer.Cursor) -> String? {
  let start = cursor.offset()
  let matched = if cursor.consume_literal("[*]") {
    Some("[*]")
  } else if cursor.consume_literal("[H*]") {
    Some("[H*]")
  } else if cursor.consume_literal("[H]") {
    Some("[H]")
  } else if cursor.consume_literal("==") {
    ignore(cursor.skip_while(char => char == '='))
    let name = cursor.take_while(char => char != '=')
    if name.length() > 0 && cursor.consume_literal("==") {
      ignore(cursor.skip_while(char => char == '='))
      Some("==" + name + "==")
    } else {
      None
    }
  } else {
    None
  }
  if matched is Some(value) {
    ignore(cursor.skip_inline_whitespace())
    return Some(value)
  }
  ignore(cursor.restore(start))
  guard state_identifier(cursor) is Some(identifier) else {
    ignore(cursor.restore(start))
    return None
  }
  let suffix = if cursor.consume_literal("[H*]") {
    "[H*]"
  } else if cursor.consume_literal("[H]") {
    "[H]"
  } else {
    ""
  }
  ignore(cursor.skip_inline_whitespace())
  Some(identifier.value + suffix)
}

///|
fn transition_direction(
  cursor : @tokenizer.Cursor,
) -> @flow.TransitionDirection? {
  // CommandLinkState's regex and StringUtils.getQueueDirection both ignore
  // case. Keep that normalization local so state names and labels retain it.
  let remaining = cursor.remaining().to_lower()
  for
    (keyword, direction) in [
      ("left", @flow.TransitionDirection::Leftward),
      ("right", @flow.TransitionDirection::Rightward),
      ("down", @flow.TransitionDirection::Downward),
      ("up", @flow.TransitionDirection::Upward),
      ("le", @flow.TransitionDirection::Leftward),
      ("ri", @flow.TransitionDirection::Rightward),
      ("do", @flow.TransitionDirection::Downward),
      ("l", @flow.TransitionDirection::Leftward),
      ("r", @flow.TransitionDirection::Rightward),
      ("u", @flow.TransitionDirection::Upward),
      ("d", @flow.TransitionDirection::Downward),
    ] {
    if remaining.has_prefix(keyword) {
      ignore(cursor.restore(cursor.offset() + keyword.length()))
      return Some(direction)
    }
  }
  None
}

///|
fn transition_style(cursor : @tokenizer.Cursor) -> String? {
  guard cursor.consume('[') else { return None }
  let start = cursor.offset()
  while !cursor.is_eof() && !cursor.starts_with_literal("]") {
    ignore(cursor.advance())
  }
  guard cursor.consume(']') else { return None }
  Some(cursor.slice(start, cursor.offset() - 1))
}

///|
fn transition_arrow_from(parts : TransitionArrowParts) -> TransitionArrowSyntax {
  let line_style = parts.second_style.map_or(parts.first_style, value => {
    Some(value)
  })
  let direction = parts.direction.unwrap_or(
    if parts.reversed {
      @flow.TransitionDirection::Leftward
    } else {
      @flow.TransitionDirection::Automatic
    },
  )
  {
    direction,
    length: if direction
      is (@flow.TransitionDirection::Leftward
      | @flow.TransitionDirection::Rightward) {
      1
    } else {
      parts.length
    },
    line_style,
    has_cross_start: parts.has_cross_start,
    has_circle_end: parts.has_circle_end,
    reversed: parts.reversed,
  }
}

///|
fn forward_transition_arrow(
  cursor : @tokenizer.Cursor,
) -> TransitionArrowParts? {
  let has_cross_start = cursor.consume('x')
  guard cursor.consume('-') else { return None }
  let first_length = 1 + cursor.skip_while(char => char == '-')
  let first_style = transition_style(cursor)
  let direction = transition_direction(cursor)
  let second_style = transition_style(cursor)
  let second_length = cursor.skip_while(char => char == '-')
  guard cursor.consume('>') else { return None }
  let arrow_end = cursor.offset()
  let has_circle_end = if cursor.consume('o') {
    match cursor.peek() {
      Some(char) if !char.is_whitespace() => {
        ignore(cursor.restore(arrow_end))
        false
      }
      _ => true
    }
  } else {
    false
  }
  Some({
    direction,
    length: first_length + second_length,
    first_style,
    second_style,
    has_cross_start,
    has_circle_end,
    reversed: false,
  })
}

///|
fn reverse_transition_arrow(
  cursor : @tokenizer.Cursor,
) -> TransitionArrowParts? {
  let has_circle_end = cursor.consume('o')
  if has_circle_end {
    ignore(cursor.skip_inline_whitespace())
  }
  guard cursor.consume('<') else { return None }
  guard cursor.consume('-') else { return None }
  let first_length = 1 + cursor.skip_while(char => char == '-')
  let first_style = transition_style(cursor)
  let direction = transition_direction(cursor)
  let second_style = transition_style(cursor)
  let second_length = cursor.skip_while(char => char == '-')
  let has_cross_start = cursor.consume('x')
  Some({
    direction,
    length: first_length + second_length,
    first_style,
    second_style,
    has_cross_start,
    has_circle_end,
    reversed: true,
  })
}

///|
/// Previously verified: direction casing preserves semantic endpoints,
/// reverse arrows, decorations, styles, and mixed-case labels.
fn transition_arrow(cursor : @tokenizer.Cursor) -> TransitionArrowSyntax? {
  let start = cursor.offset()
  match forward_transition_arrow(cursor) {
    Some(parts) => Some(transition_arrow_from(parts))
    None => {
      ignore(cursor.restore(start))
      match reverse_transition_arrow(cursor) {
        Some(parts) => Some(transition_arrow_from(parts))
        None => {
          ignore(cursor.restore(start))
          None
        }
      }
    }
  }
}

///|
fn state_transition(cursor : @tokenizer.Cursor) -> StateTransitionSyntax? {
  let start = cursor.offset()
  ignore(cursor.skip_inline_whitespace())
  guard state_endpoint(cursor) is Some(first) else {
    ignore(cursor.restore(start))
    return None
  }
  guard transition_arrow(cursor) is Some(arrow) else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.skip_inline_whitespace())
  guard state_endpoint(cursor) is Some(second) else {
    ignore(cursor.restore(start))
    return None
  }
  let label = if cursor.consume(':') {
    ignore(cursor.skip_inline_whitespace())
    Some(cursor.take_rest_trimmed())
  } else {
    None
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  let (source, target) = if arrow.reversed {
    (second, first)
  } else {
    (first, second)
  }
  Some({
    source,
    target,
    direction: arrow.direction,
    length: arrow.length,
    line_style: arrow.line_style,
    has_cross_start: arrow.has_cross_start,
    has_circle_end: arrow.has_circle_end,
    label,
  })
}

///|
/// Pattern2 compiles note command keywords case-insensitively. Consume only
/// the keyword so state identifiers, colors, and body text retain their case.
fn state_note_keyword(cursor : @tokenizer.Cursor, keyword : String) -> Bool {
  guard cursor.remaining().to_lower().has_prefix(keyword) else { return false }
  cursor.restore(cursor.offset() + keyword.length())
}

///|
fn state_note_position(cursor : @tokenizer.Cursor) -> @flow.StateNotePosition? {
  if state_note_keyword(cursor, "left") {
    Some(@flow.StateNotePosition::NoteLeft)
  } else if state_note_keyword(cursor, "right") {
    Some(@flow.StateNotePosition::NoteRight)
  } else if state_note_keyword(cursor, "top") {
    Some(@flow.StateNotePosition::NoteTop)
  } else if state_note_keyword(cursor, "bottom") {
    Some(@flow.StateNotePosition::NoteBottom)
  } else {
    None
  }
}

///|
/// Note block terminators accept zero or one whitespace character between
/// end and note, including a tab (CommandFactoryNoteOnEntity/Link END).
fn state_note_end(line : String) -> Bool {
  let cursor = @tokenizer.Cursor::new(line)
  guard state_note_keyword(cursor, "end") else { return false }
  ignore(cursor.consume_inline_space1())
  state_note_keyword(cursor, "note") && cursor.is_eof()
}

///|
/// ColorParser uses ASCII regex word characters for color components.
fn note_color_word(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
}

///|
/// ColorParser's word color or two-color gradient, without its leading #.
/// Unlike a whitespace token, this stops before the note body's colon/brace.
fn note_color_value(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    let start = cursor.offset()
    let first = cursor.take_while(note_color_word)
    guard !first.is_empty() else { return None }
    if cursor
      .peek()
      .map_or(false, char => {
        char == '-' || char == '\\' || char == '|' || char == '/'
      }) {
      ignore(cursor.advance())
      let second = cursor.take_while(note_color_word)
      guard !second.is_empty() else { return None }
    } else {
      // COLOR_REGEXP has two required word runs even without a separator.
      guard first.length() >= 2 else { return None }
    }
    Some(cursor.slice(start, cursor.offset()))
  })
}

///|
/// ColorParser's compound alternative allows an initial background color
/// followed by semicolon-separated field colors and line/shadow flags.
fn note_compound_color(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    let start = cursor.offset()
    if note_color_value(cursor) is None || !cursor.consume(';') {
      ignore(cursor.restore(start))
    }
    let mut last_field_end = None
    while !cursor.is_eof() {
      let field = [
        "line.dashed", "line.dotted", "line.bold", "shadowing", "header", "text",
        "back", "line",
      ].any(keyword => state_note_keyword(cursor, keyword))
      guard field else { break }
      if cursor.consume(':') && note_color_value(cursor) is None {
        break
      }
      if cursor.consume(';') {
        last_field_end = Some(cursor.offset())
        continue
      }
      guard !cursor
        .peek()
        .map_or(false, char => {
          note_color_word(char) || char == ';' || char == ':' || char == '.'
        }) else {
        break
      }
      last_field_end = Some(cursor.offset())
      break
    }
    guard last_field_end is Some(end) else { return None }
    ignore(cursor.restore(end))
    Some(cursor.slice(start, end))
  })
}

///|
/// A trailing inline color must match ColorParser; a bare # rejects the note.
fn note_color(cursor : @tokenizer.Cursor) -> String?? {
  guard cursor.peek() == Some('#') else { return Some(None) }
  ignore(cursor.advance())
  let color = if note_compound_color(cursor) is Some(value) {
    Some(value)
  } else {
    note_color_value(cursor)
  }
  guard color is Some(value) else { return None }
  ignore(cursor.skip_inline_whitespace())
  Some(Some(value))
}

///|
/// Entity notes accept an inline body, an end-note block, or a braced block.
/// Link notes share the first two forms. Reject trailing tokens instead of
/// swallowing them and subsequently consuming unrelated lines as a note.
fn state_note_body(
  cursor : @tokenizer.Cursor,
  allow_braces~ : Bool,
) -> StateNoteBody? {
  if cursor.consume(':') {
    ignore(cursor.skip_inline_whitespace())
    return Some(Inline(cursor.take_rest_trimmed()))
  }
  let body = if allow_braces && cursor.consume('{') {
    BracedBlock
  } else {
    Block
  }
  guard cursor.take_rest_trimmed().is_empty() else { return None }
  Some(body)
}

///|
/// Previously verified: note keyword case, required whitespace, colors and
/// body delimiters preserve entity/link targets and reject malformed headers.
fn entity_note(cursor : @tokenizer.Cursor) -> StateEntityNoteSyntax? {
  let start = cursor.offset()
  guard state_note_keyword(cursor, "note") && cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard state_note_position(cursor) is Some(position) else {
    ignore(cursor.restore(start))
    return None
  }
  let spaced = cursor.skip_inline_space1()
  let target = if spaced && state_note_keyword(cursor, "of") {
    guard cursor.skip_inline_space1() && state_endpoint(cursor) is Some(target) else {
      ignore(cursor.restore(start))
      return None
    }
    Some(target)
  } else {
    None
  }
  guard note_color(cursor) is Some(color) &&
    state_note_body(cursor, allow_braces=true) is Some(body) else {
    ignore(cursor.restore(start))
    return None
  }
  Some({ position, target, color, body, })
}

///|
fn link_note(cursor : @tokenizer.Cursor) -> StateLinkNoteSyntax? {
  let start = cursor.offset()
  guard state_note_keyword(cursor, "note") && cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  let position = state_note_position(cursor)
  cursor.skip_inline_spaces()
  guard (state_note_keyword(cursor, "on") || state_note_keyword(cursor, "of")) &&
    cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard state_note_keyword(cursor, "link") else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.skip_inline_whitespace())
  guard note_color(cursor) is Some(color) else {
    ignore(cursor.restore(start))
    return None
  }
  guard state_note_body(cursor, allow_braces=false) is Some(body) else {
    ignore(cursor.restore(start))
    return None
  }
  Some({ body, color, position, })
}

///|
/// StateDiagramFactory handles link notes on pass two and entity notes on
/// pass three, so "note left of link" must resolve to the link-note command.
fn parse_line_syntax(line : String) -> StateLineSyntax? {
  let cursor = @tokenizer.Cursor::new(line)
  if state_declaration(cursor, "state") is Some(syntax) {
    return Some(Declaration(syntax))
  }
  ignore(cursor.restore(0))
  if state_declaration(cursor, "frame") is Some(syntax) && syntax.opens_group {
    return Some(Frame(syntax))
  }
  ignore(cursor.restore(0))
  if state_field(cursor) is Some(syntax) {
    return Some(syntax)
  }
  ignore(cursor.restore(0))
  if state_transition(cursor) is Some(syntax) {
    return Some(Transition(syntax))
  }
  ignore(cursor.restore(0))
  if link_note(cursor) is Some(syntax) {
    return Some(LinkNote(syntax))
  }
  ignore(cursor.restore(0))
  entity_note(cursor).map(syntax => EntityNote(syntax))
}
