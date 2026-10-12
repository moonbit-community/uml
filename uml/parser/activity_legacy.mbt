///|
/// The legacy language is a Cuca/DOT graph. Its explicit links must never be
/// reduced to modern activity tiles or mistaken for parenthesized use cases.
pub fn is_legacy_activity(input : String) -> Bool {
  input
  .split("\n")
  .any(line => {
    let line = line.trim()
    !line.has_prefix("'") &&
    (
      @tokenizer.find_unquoted_literal(line.to_owned(), "(*)") is Some(_) ||
      @tokenizer.find_unquoted_literal(line.to_owned(), "(*top)") is Some(_) ||
      (line.contains("==") && line.contains("->")) ||
      line.has_prefix("if \"")
    )
  })
}

///|
priv struct LegacyActivityParser {
  state : Parser
  mut last : String?
  conditions : Array[String]
  mut sequence : Int32
}

///|
priv struct LegacyActivityArrow {
  direction : @flow.TransitionDirection
  length : Int32
  label : String?
  style : String?
}

///|
fn LegacyActivityParser::node(
  self : LegacyActivityParser,
  code : String,
  text : String,
  kind : @flow.StateKind,
  stereotype : String?,
  color : String?,
) -> String raise @tokenizer.ParseError {
  let name = self.state.resolve_state_name(code, allow_current=false)
  let location = self.state.state_name_location(name, code, create_parents=true)
  if self.state.states.search_by(node => node.code == location.code)
    is Some(index) {
    let node = self.state.states[index]
    self.state.states[index] = {
      ..node,
      stereotype: stereotype.map_or(node.stereotype, value => Some(value)),
      color: color.map_or(node.color, value => Some(value)),
    }
  } else {
    self.state.upsert_state({
      code: location.code,
      display: text,
      kind,
      parent: location.parent,
      region_index: location.region_index,
      description: None,
      embedded: None,
      standalone_note: None,
      tags: [],
      is_removed: false,
      is_hidden: false,
      stereotype,
      url: None,
      color,
    })
  }
  location.code
}

///|
fn LegacyActivityParser::endpoint(
  self : LegacyActivityParser,
  cursor : @tokenizer.Cursor,
  source : Bool,
) -> String raise @tokenizer.ParseError {
  cursor.skip_inline_spaces()
  if !source && cursor.consume('{') {
    self.sequence += 1
    let code = "__activity_inner_" + self.sequence.to_string()
    ignore(self.state.apply_line_syntax("frame " + code + " {"))
    return self.state.stack.last().unwrap().code
  }
  let (code, text, kind) = if cursor.consume_literal("(*") {
    let suffix = cursor.take_while(char => char != ')')
    guard cursor.consume(')') else {
      raise SyntaxError(self.state.line_number(), "unclosed activity terminal")
    }
    if source {
      ("start", "", @flow.Initial)
    } else {
      (
        "end" + (if suffix.is_empty() { "" } else { "$" + suffix }),
        "",
        @flow.Final,
      )
    }
  } else if cursor.consume_literal("==") {
    ignore(cursor.skip_while(char => char == '='))
    let code = cursor.take_while(char => char != '=').trim().to_owned()
    guard cursor.consume_literal("==") else {
      raise SyntaxError(
        self.state.line_number(),
        "unclosed activity synchronization",
      )
    }
    ignore(cursor.skip_while(char => char == '='))
    (code, "", @flow.Synchronization)
  } else if cursor.take_quoted_value() is Some(text) {
    cursor.skip_inline_spaces()
    let code = if cursor.consume_literal("as") {
      cursor.skip_inline_spaces()
      cursor.take_while(char => {
        @identifier.is_identifier_char(char) || char == '.'
      })
    } else {
      text
    }
    (code, text, @flow.LegacyActivity)
  } else {
    let mut code = cursor.take_while(char => {
      @identifier.is_identifier_char(char) || char == '.'
    })
    guard !code.is_empty() else {
      raise SyntaxError(
        self.state.line_number(),
        "missing legacy activity endpoint",
      )
    }
    if !source {
      let remaining = cursor.remaining()
      let trimmed = remaining.trim_start()
      if !trimmed.is_empty() &&
        !trimmed.has_prefix("<<") &&
        !trimmed.has_prefix("#") &&
        !trimmed.has_prefix("in ") {
        let mut end = remaining.length()
        for marker in ["<<", " in ", " #"] {
          if @tokenizer.find_unquoted_literal(remaining, marker) is Some(index) {
            end = end.min(index)
          }
        }
        code += remaining[:end].trim_end().to_owned()
        ignore(cursor.restore(cursor.offset() + end))
      }
    }
    (code, code, @flow.LegacyActivity)
  }
  cursor.skip_inline_spaces()
  let stereotype = cursor.take_stereotype_value()
  cursor.skip_inline_spaces()
  let mut color = cursor.take_color_value()
  cursor.skip_inline_spaces()
  let partition = if !source && cursor.consume_literal("in") {
    cursor.skip_inline_spaces()
    state_identifier(cursor).map(name => name.value)
  } else {
    None
  }
  cursor.skip_inline_spaces()
  if color is None {
    color = cursor.take_color_value()
  }
  let saved = self.state.stack.copy()
  if partition is Some(partition) {
    self.state.apply_line_syntax("frame \"" + partition + "\" {") |> ignore
  }
  let result = self.node(code, text, kind, stereotype, color)
  if partition is Some(_) {
    self.state.stack.clear()
    self.state.stack.append(saved)
  }
  result
}

///|
fn legacy_activity_arrow(cursor : @tokenizer.Cursor) -> LegacyActivityArrow? {
  let body1 = cursor.take_while(char => char == '-' || char == '.')
  guard !body1.is_empty() else { return None }
  let first_style = transition_style(cursor)
  let unconstrained = cursor.consume('*')
  let direction = transition_direction(cursor).unwrap_or(@flow.Automatic)
  let second_style = transition_style(cursor)
  let body2 = cursor.take_while(char => char == '-' || char == '.')
  guard cursor.consume('>') else { return None }
  cursor.skip_inline_spaces()
  let label = if cursor.consume('[') {
    let value = cursor.take_while(char => char != ']')
    guard cursor.consume(']') else { return None }
    Some(value)
  } else {
    None
  }
  cursor.skip_inline_spaces()
  let mut styles = first_style
    .map_or(second_style, value => Some(value))
    .unwrap_or("")
  if body1.contains(".") || body2.contains(".") {
    styles += ",dotted"
  }
  if unconstrained {
    styles += ",norank"
  }
  {
    direction,
    length: if unconstrained {
      2
    } else if direction is (@flow.Leftward | @flow.Rightward) {
      1
    } else {
      body1.length() + body2.length()
    },
    label,
    style: if styles.is_empty() {
      None
    } else {
      Some(styles)
    },
  }
  |> Some
}

///|
fn LegacyActivityParser::link(
  self : LegacyActivityParser,
  source : String,
  target : String,
  arrow : LegacyActivityArrow,
  target_label : String?,
) -> Unit {
  self.state.transitions.push({
    source,
    target,
    source_port: None,
    target_port: None,
    label: arrow.label,
    target_label,
    direction: arrow.direction,
    length: arrow.length,
    line_style: arrow.style,
    has_cross_start: false,
    has_circle_end: false,
  })
  self.last = Some(target)
  self.state.last_entity = Some(@flow.StateNote(target))
}

///|
fn LegacyActivityParser::conditional(
  self : LegacyActivityParser,
  cursor : @tokenizer.Cursor,
  source : String,
  arrow : LegacyActivityArrow,
) -> Unit raise @tokenizer.ParseError {
  guard cursor.consume_literal("if") else {
    raise SyntaxError(self.state.line_number(), "invalid legacy condition")
  }
  cursor.skip_inline_spaces()
  let (label, code_alias) = if cursor.take_quoted_value() is Some(label) {
    cursor.skip_inline_spaces()
    let code_alias = if cursor.consume_literal("as") {
      cursor.skip_inline_spaces()
      Some(
        cursor.take_while(char => {
          @identifier.is_identifier_char(char) || char == '.'
        }),
      )
    } else {
      None
    }
    cursor.skip_inline_spaces()
    ignore(cursor.consume_literal("then"))
    (label, code_alias)
  } else {
    let label = cursor.take_rest_trimmed()
    (
      if label.has_suffix("then") {
        label[:label.length() - 4].trim_end().to_owned()
      } else {
        label
      },
      None,
    )
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    raise SyntaxError(
      self.state.line_number(),
      "invalid legacy condition suffix",
    )
  }
  self.sequence += 1
  let branch = self.node(
    code_alias.unwrap_or("__activity_condition_" + self.sequence.to_string()),
    "",
    @flow.Choice,
    None,
    None,
  )
  self.conditions.push(branch)
  self.link(source, branch, arrow, Some(label))
}

///|
fn LegacyActivityParser::parse_line(
  self : LegacyActivityParser,
  line : String,
) -> Unit raise @tokenizer.ParseError {
  let lower = line.to_lower()
  if lower == "else" {
    guard self.conditions.last() is Some(branch) else {
      raise SyntaxError(self.state.line_number(), "else without if")
    }
    self.last = Some(branch)
    self.state.last_entity = Some(@flow.StateNote(branch))
    return
  }
  if lower == "endif" || lower == "end if" {
    guard self.conditions.pop() is Some(_) else {
      raise SyntaxError(self.state.line_number(), "endif without if")
    }
    return
  }
  if lower.has_prefix("partition ") {
    let declaration = "frame " +
      line["partition ".length():].to_owned() +
      (if line.has_suffix("{") { "" } else { " {" })
    guard self.state.apply_line_syntax(declaration) else {
      raise SyntaxError(self.state.line_number(), "invalid activity partition")
    }
    return
  }
  if lower == "end partition" || line == "}" {
    self.state.parse_line("}")
    return
  }
  if parse_line_syntax(line) is Some(EntityNote(note)) {
    self.state.consume_entity_note(note)
    return
  }
  if parse_line_syntax(line) is Some(LinkNote(note)) {
    guard !self.state.transitions.is_empty() else {
      raise SyntaxError(
        self.state.line_number(),
        "link note without activity link",
      )
    }
    let (text, text_mode) = self.state.consume_note_body(note.body)
    self.state.notes.push({
      target: @flow.TransitionNote(self.state.transitions.length() - 1),
      parent: self.state.parent(),
      region_index: self.state.region_index(),
      text,
      text_mode,
      color: note.color,
      position: note.position,
    })
    return
  }
  if self.state.consume_state_control(line) ||
    self.state.consume_state_document(line) {
    return
  }
  if @style.parse_style_directive(line) is Some(directive) {
    self.state.apply_state_style(directive)
    return
  }
  let cursor = @tokenizer.Cursor::new(line)
  let implied = lower.has_prefix("if ") ||
    lower.has_prefix("if\"") ||
    cursor.starts_with_literal("-") ||
    cursor.starts_with_literal(".")
  let source = if implied {
    guard self.last is Some(last) else {
      raise SyntaxError(self.state.line_number(), "no preceding activity")
    }
    last
  } else {
    self.endpoint(cursor, true)
  }
  cursor.skip_inline_spaces()
  cursor.skip_inline_spaces()
  let arrow = if cursor.remaining().has_prefix("if") {
    LegacyActivityArrow::{
      direction: @flow.Automatic,
      length: 2,
      label: None,
      style: None,
    }
  } else {
    guard legacy_activity_arrow(cursor) is Some(arrow) else {
      raise SyntaxError(self.state.line_number(), "invalid activity arrow")
    }
    arrow
  }
  if cursor.remaining().has_prefix("if") {
    self.conditional(cursor, source, arrow)
    return
  }
  let target = self.endpoint(cursor, false)
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    raise SyntaxError(
      self.state.line_number(),
      "invalid legacy activity suffix",
    )
  }
  self.link(source, target, arrow, None)
}

///|
fn legacy_unclosed_quote(line : String) -> Bool {
  let mut quoted = false
  let mut escaped = false
  for char in line {
    if escaped {
      escaped = false
    } else if char == '\\' {
      escaped = true
    } else if char == '"' {
      quoted = !quoted
    }
  }
  quoted
}

///|
pub fn parse_legacy_activity(
  input : String,
) -> @flow.StateDiagram raise @tokenizer.ParseError {
  let parser : LegacyActivityParser = {
    state: Parser::new(input),
    last: None,
    conditions: [],
    sequence: 0,
  }
  parser.state.style.apply(Property("LegacyActivity", "true"))
  let buffer = parser.state.buffer
  while !buffer.at_end() {
    let mut line = buffer.current_clean()
    let start = buffer.line_number()
    while legacy_unclosed_quote(line) {
      buffer.advance()
      guard !buffer.at_end() else {
        raise SyntaxError(start, "unclosed legacy activity text")
      }
      line += "\n" + buffer.current_stripped()
    }
    if line.is_empty() ||
      line.has_prefix("@start") ||
      line.has_prefix("@end") ||
      @style.is_preprocessor_directive(line) {
      buffer.advance()
      continue
    }
    if line.to_lower() == "<style>" {
      buffer.advance()
      guard @style.consume_style_body(() => buffer.take_next(), directive => {
        parser.state.apply_state_style(directive)
      }) else {
        raise SyntaxError(start, "unclosed style")
      }
      continue
    }
    if state_skinparam_prefix(line) is Some(prefix) {
      buffer.consume_skinparam(parser.state.style, start, prefix~)
      continue
    }
    parser.parse_line(line)
    buffer.advance()
  }
  guard parser.conditions.is_empty() && parser.state.stack.is_empty() else {
    raise SyntaxError(buffer.line_number(), "unclosed legacy activity block")
  }
  parser.state.apply_state_removals()
  {
    states: parser.state.states,
    transitions: parser.state.transitions,
    notes: parser.state.notes,
    concurrent_regions: [],
    regions: parser.state.regions,
    style: parser.state.style,
  }
}
