///|
priv struct StateDeclarationSyntax {
  code : String
  display : String
  kind : StateKind
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
  direction : TransitionDirection
  line_style : String?
  has_cross_start : Bool
  label : String?
}

///|
priv struct StateEntityNoteSyntax {
  target : String
  color : String?
}

///|
priv struct StateLinkNoteSyntax {
  text : String
  color : String?
}

///|
priv struct TransitionArrowSyntax {
  direction : TransitionDirection
  line_style : String?
  has_cross_start : Bool
  reversed : Bool
}

///|
priv struct TransitionArrowParts {
  direction : TransitionDirection?
  first_style : String?
  second_style : String?
  has_cross_start : Bool
  reversed : Bool
}

///|
priv enum StateLineSyntax {
  Declaration(StateDeclarationSyntax)
  Frame(StateDeclarationSyntax)
  Transition(StateTransitionSyntax)
  EntityNote(StateEntityNoteSyntax)
  LinkNote(StateLinkNoteSyntax)
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
/// to the raw unquoted token, mirroring the talc `quoted.attempt().or(...)`.
fn state_identifier(cursor : @parse.Cursor) -> StateIdentifier? {
  if cursor.peek() == Some('"') {
    match cursor.take_quoted_value() {
      Some(value) => return Some({ value, quoted: true })
      None => ()
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
    Some({ value, quoted: false })
  } else {
    None
  }
}

///|
fn state_stereotype(cursor : @parse.Cursor) -> String? {
  guard cursor.consume_literal("<<") else { return None }
  let start = cursor.offset()
  while !cursor.is_eof() && !cursor.starts_with_literal(">>") {
    ignore(cursor.advance())
  }
  guard cursor.consume_literal(">>") else { return None }
  Some("<<" + cursor.slice(start, cursor.offset() - 2) + ">>")
}

///|
fn state_url(cursor : @parse.Cursor) -> String? {
  guard cursor.consume_literal("[[") else { return None }
  let start = cursor.offset()
  while !cursor.is_eof() && !cursor.starts_with_literal("]]") {
    ignore(cursor.advance())
  }
  guard cursor.consume_literal("]]") else { return None }
  let content = cursor.slice(start, cursor.offset() - 2)
  match @parse.parse_url_target("[[" + content + "]]") {
    Some(target) => Some(target.target)
    None => None
  }
}

///|
fn state_color(cursor : @parse.Cursor) -> String? {
  guard cursor.consume('#') else { return None }
  let token = cursor.take_while(char => !char.is_whitespace())
  guard token.length() > 0 else { return None }
  Some(token)
}

///|
fn state_metadata(cursor : @parse.Cursor) -> StateMetadata? {
  let start = cursor.offset()
  if state_stereotype(cursor) is Some(value) {
    return Some(Stereotype(value))
  }
  ignore(cursor.restore(start))
  if state_url(cursor) is Some(value) {
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
      Stereotype(value) => stereotype = Some(value)
      Url(value) => url = Some(value)
      Color(value) => color = Some(value)
    }
  }
  { stereotype, url, color }
}

///|
fn state_declaration(
  cursor : @parse.Cursor,
  keyword : String,
) -> StateDeclarationSyntax? {
  guard cursor.consume_literal(keyword) else { return None }
  ignore(cursor.skip_inline_whitespace())
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
    Some(cursor.take_while(_ => true).trim().to_owned())
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
  let (code, display) = match alias_value {
    Some(second) =>
      if first.quoted {
        (second.value, first.value)
      } else {
        (first.value, second.value)
      }
    None => (first.value, first.value)
  }
  let kind = match values.stereotype {
    Some(value) if value.equal_ignore_ascii_case("<<choice>>") => Choice
    _ => Normal
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
fn state_endpoint(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  let matched = if cursor.consume_literal("[*]") {
    Some("[*]")
  } else if cursor.consume_literal("[H*]") {
    Some("[H*]")
  } else if cursor.consume_literal("[H]") {
    Some("[H]")
  } else if cursor.consume_literal("==") {
    let name = cursor.take_while(char => char != '=')
    if name.length() > 0 && cursor.consume_literal("==") {
      Some("==" + name + "==")
    } else {
      None
    }
  } else {
    None
  }
  match matched {
    Some(value) => {
      ignore(cursor.skip_inline_whitespace())
      Some(value)
    }
    None => {
      ignore(cursor.restore(start))
      match state_identifier(cursor) {
        Some(identifier) => {
          ignore(cursor.skip_inline_whitespace())
          Some(identifier.value)
        }
        None => {
          ignore(cursor.restore(start))
          None
        }
      }
    }
  }
}

///|
fn transition_direction(cursor : @parse.Cursor) -> TransitionDirection? {
  if cursor.consume_literal("left") {
    return Some(Leftward)
  }
  if cursor.consume_literal("right") {
    return Some(Rightward)
  }
  if cursor.consume_literal("down") {
    return Some(Downward)
  }
  if cursor.consume_literal("up") {
    return Some(Upward)
  }
  if cursor.consume_literal("le") {
    return Some(Leftward)
  }
  if cursor.consume_literal("ri") {
    return Some(Rightward)
  }
  if cursor.consume_literal("do") {
    return Some(Downward)
  }
  if cursor.consume_literal("l") {
    return Some(Leftward)
  }
  if cursor.consume_literal("r") {
    return Some(Rightward)
  }
  if cursor.consume_literal("u") {
    return Some(Upward)
  }
  if cursor.consume_literal("d") {
    return Some(Downward)
  }
  None
}

///|
fn transition_style(cursor : @parse.Cursor) -> String? {
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
  let line_style = match parts.second_style {
    Some(value) => Some(value)
    None => parts.first_style
  }
  {
    direction: parts.direction.unwrap_or(Automatic),
    line_style,
    has_cross_start: parts.has_cross_start,
    reversed: parts.reversed,
  }
}

///|
fn forward_transition_arrow(cursor : @parse.Cursor) -> TransitionArrowParts? {
  let has_cross_start = cursor.consume('x')
  guard cursor.consume('-') else { return None }
  while cursor.consume('-') {
    ()
  }
  let first_style = transition_style(cursor)
  let direction = transition_direction(cursor)
  let second_style = transition_style(cursor)
  while cursor.consume('-') {
    ()
  }
  guard cursor.consume('>') else { return None }
  Some({
    direction,
    first_style,
    second_style,
    has_cross_start,
    reversed: false,
  })
}

///|
fn reverse_transition_arrow(cursor : @parse.Cursor) -> TransitionArrowParts? {
  ignore(cursor.consume('o'))
  guard cursor.consume('<') else { return None }
  guard cursor.consume('-') else { return None }
  while cursor.consume('-') {
    ()
  }
  let first_style = transition_style(cursor)
  let direction = transition_direction(cursor)
  let second_style = transition_style(cursor)
  while cursor.consume('-') {
    ()
  }
  ignore(cursor.consume('x'))
  Some({
    direction,
    first_style,
    second_style,
    has_cross_start: false,
    reversed: true,
  })
}

///|
fn transition_arrow(cursor : @parse.Cursor) -> TransitionArrowSyntax? {
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
fn state_transition(cursor : @parse.Cursor) -> StateTransitionSyntax? {
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
    Some(cursor.take_while(_ => true).trim().to_owned())
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
    line_style: arrow.line_style,
    has_cross_start: arrow.has_cross_start,
    label,
  })
}

///|
fn note_position(cursor : @parse.Cursor) -> Bool {
  if cursor.consume_literal("left") ||
    cursor.consume_literal("right") ||
    cursor.consume_literal("top") ||
    cursor.consume_literal("bottom") {
    ignore(cursor.skip_inline_whitespace())
    true
  } else {
    false
  }
}

///|
/// A trailing inline color must fully match; a bare `#` rejects the note.
fn note_color(cursor : @parse.Cursor) -> String?? {
  match cursor.peek() {
    Some('#') =>
      match state_color(cursor) {
        Some(value) => {
          ignore(cursor.skip_inline_whitespace())
          Some(Some(value))
        }
        None => None
      }
    _ => Some(None)
  }
}

///|
fn entity_note(cursor : @parse.Cursor) -> StateEntityNoteSyntax? {
  let start = cursor.offset()
  guard cursor.consume_literal("note") else { return None }
  ignore(cursor.skip_inline_whitespace())
  guard note_position(cursor) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume_literal("of") else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.skip_inline_whitespace())
  guard state_endpoint(cursor) is Some(target) else {
    ignore(cursor.restore(start))
    return None
  }
  let color = match note_color(cursor) {
    Some(value) => value
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  ignore(cursor.take_while(_ => true))
  Some({ target, color })
}

///|
fn link_note(cursor : @parse.Cursor) -> StateLinkNoteSyntax? {
  let start = cursor.offset()
  guard cursor.consume_literal("note") else { return None }
  ignore(cursor.skip_inline_whitespace())
  guard cursor.consume_literal("on") else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.skip_inline_whitespace())
  guard cursor.consume_literal("link") else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.skip_inline_whitespace())
  let color = match note_color(cursor) {
    Some(value) => value
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  guard cursor.consume(':') else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.skip_inline_whitespace())
  let text = cursor.take_while(_ => true).trim().to_owned()
  Some({ text, color })
}

///|
/// Command matching follows `StateDiagramFactory` order: state and frame
/// declarations, forward and reverse transitions, then entity and link notes.
fn parse_line_syntax(line : String) -> StateLineSyntax? {
  let cursor = @parse.Cursor::new(line)
  if state_declaration(cursor, "state") is Some(syntax) {
    return Some(Declaration(syntax))
  }
  ignore(cursor.restore(0))
  if state_declaration(cursor, "frame") is Some(syntax) {
    return Some(Frame(syntax))
  }
  ignore(cursor.restore(0))
  if state_transition(cursor) is Some(syntax) {
    return Some(Transition(syntax))
  }
  ignore(cursor.restore(0))
  if entity_note(cursor) is Some(syntax) {
    return Some(EntityNote(syntax))
  }
  ignore(cursor.restore(0))
  match link_note(cursor) {
    Some(syntax) => Some(LinkNote(syntax))
    None => None
  }
}
