///|
priv struct Parser {
  lines : Array[String]
  states : Array[StateNode]
  transitions : Array[StateTransition]
  notes : Array[StateNote]
  stack : Array[String]
  concurrent_regions : Array[String]
  mut index : Int
}

///|
fn Parser::new(input : String) -> Parser {
  {
    lines: @core.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array(),
    states: [],
    transitions: [],
    notes: [],
    stack: [],
    concurrent_regions: [],
    index: 0,
  }
}

///|
fn Parser::line_number(self : Parser) -> Int {
  self.index + 1
}

///|
fn Parser::parent(self : Parser) -> String? {
  self.stack.last()
}

///|
fn trim_quotes(value : String) -> String {
  let value = value.trim().to_owned()
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value
  }
}

///|
fn split_description(line : String) -> (String, String?) {
  match @core.find_unquoted_literal(line, " : ") {
    Some(index) =>
      (line[:index].trim().to_owned(), Some(line[index + 3:].trim().to_owned()))
    None => (line, None)
  }
}

///|
fn take_stereotype(value : String) -> (String, String?) {
  match @core.find_unquoted_literal(value, "<<") {
    Some(start) =>
      match @core.find_unquoted_literal(value[start + 2:].to_owned(), ">>") {
        Some(end) =>
          (
            (value[:start] + value[start + end + 4:]).trim().to_owned(),
            Some(value[start:start + end + 4].to_owned()),
          )
        None => (value, None)
      }
    None => (value, None)
  }
}

///|
fn take_color(value : String) -> (String, String?) {
  let words = value.split(" ").filter(word => word.length() > 0).to_array()
  let retained = []
  let mut color = None
  for word in words {
    if word.has_prefix("#") {
      color = Some(word[1:].to_owned())
    } else {
      retained.push(word.to_owned())
    }
  }
  (retained.join(" "), color)
}

///|
fn parse_state_declaration(
  line : String,
) -> (String, String, StateKind, String?, String?, String?, Bool) raise @core.ParseError {
  let (without_description, description) = split_description(
    line[5:].trim().to_owned(),
  )
  let opens_group = without_description.has_suffix("{") ||
    without_description.to_lower().has_suffix(" begin")
  let declaration = if without_description.has_suffix("{") {
    without_description[:without_description.length() - 1].trim().to_owned()
  } else if without_description.to_lower().has_suffix(" begin") {
    without_description[:without_description.length() - 6].trim().to_owned()
  } else {
    without_description
  }
  let (without_stereotype, stereotype) = take_stereotype(declaration)
  let (identity, color) = take_color(without_stereotype)
  let as_parts = identity.split(" as ").map(StringView::to_owned).to_array()
  let (code, display) = if as_parts.length() == 2 {
    let left = trim_quotes(as_parts[0])
    let right = trim_quotes(as_parts[1])
    if identity.trim().has_prefix("\"") {
      (right, left)
    } else {
      (left, right)
    }
  } else {
    let value = trim_quotes(identity)
    (value, value)
  }
  guard code.length() > 0 else {
    raise SyntaxError(0, "state declaration needs a name")
  }
  let kind = match stereotype {
    Some(value) if value.equal_ignore_ascii_case("<<choice>>") => Choice
    _ => Normal
  }
  (code, display, kind, description, stereotype, color, opens_group)
}

///|
fn endpoint_kind(value : String, source : Bool) -> StateKind {
  match value {
    "[*]" => if source { Initial } else { Final }
    "[H]" => History
    "[H*]" => DeepHistory
    _ if value.has_prefix("=") && value.has_suffix("=") => Synchronization
    _ => Normal
  }
}

///|
fn endpoint_code(value : String, source : Bool) -> String {
  match value {
    "[*]" => if source { "__initial__" } else { "__final__" }
    "[H]" => "__history__"
    "[H*]" => "__deep_history__"
    _ if value.has_prefix("=") && value.has_suffix("=") =>
      "__synchronization_" + value[1:value.length() - 1].to_owned()
    _ => value
  }
}

///|
fn Parser::ensure_endpoint(
  self : Parser,
  raw : String,
  source : Bool,
) -> String {
  let code = endpoint_code(raw, source)
  let mut exists = false
  for state in self.states {
    if state.code == code {
      exists = true
    }
  }
  if !exists {
    self.states.push({
      code,
      display: raw,
      kind: endpoint_kind(raw, source),
      parent: self.parent(),
      description: None,
      stereotype: None,
      color: None,
    })
  }
  code
}

///|
fn Parser::upsert_state(self : Parser, state : StateNode) -> Unit {
  for index, existing in self.states {
    if existing.code == state.code {
      self.states[index] = state
      return
    }
  }
  self.states.push(state)
}

///|
fn direction_of(arrow : String) -> TransitionDirection {
  let lower = arrow.to_lower()
  if lower.contains("left") || lower.contains("le") {
    Leftward
  } else if lower.contains("right") || lower.contains("ri") {
    Rightward
  } else if lower.contains("up") {
    Upward
  } else if lower.contains("down") || lower.contains("do") {
    Downward
  } else {
    Automatic
  }
}

///|
fn line_style_of(arrow : String) -> String? {
  match @core.find_unquoted_literal(arrow, "[") {
    Some(start) =>
      match @core.find_unquoted_literal(arrow[start + 1:].to_owned(), "]") {
        Some(end) => Some(arrow[start + 1:start + end + 1].to_owned())
        None => None
      }
    None => None
  }
}

///|
fn Parser::parse_transition(self : Parser, line : String) -> Bool {
  let (without_label, label) = split_description(line)
  let parts = without_label
    .split(" ")
    .filter(word => word.length() > 0)
    .to_array()
  guard parts.length() == 3 else { return false }
  let arrow = parts[1].to_owned()
  guard arrow.contains("->") || arrow.contains("<-") else { return false }
  let reverse = arrow.contains("<-")
  let source_raw = if reverse {
    parts[2].to_owned()
  } else {
    parts[0].to_owned()
  }
  let target_raw = if reverse {
    parts[0].to_owned()
  } else {
    parts[2].to_owned()
  }
  let source = self.ensure_endpoint(source_raw, true)
  let target = self.ensure_endpoint(target_raw, false)
  self.transitions.push({
    source,
    target,
    label,
    direction: direction_of(arrow),
    line_style: line_style_of(arrow),
    has_cross_start: arrow.has_prefix("x"),
  })
  true
}

///|
fn Parser::parse_note(
  self : Parser,
  line : String,
) -> Bool raise @core.ParseError {
  let lower = line.to_lower()
  guard lower.has_prefix("note ") else { return false }
  if lower.has_prefix("note on link") {
    let text = match @core.find_unquoted_literal(line, " : ") {
      Some(index) => line[index + 3:].trim().to_owned()
      None => raise SyntaxError(self.line_number(), "link note needs text")
    }
    guard self.transitions.length() > 0 else {
      raise SyntaxError(self.line_number(), "link note without transition")
    }
    self.notes.push({
      target: TransitionNote(self.transitions.length() - 1),
      text,
    })
    return true
  }
  guard lower.contains(" of ") else { return false }
  let target = match @core.find_unquoted_literal(line, " of ") {
    Some(index) =>
      line[index + 4:].trim().to_owned().split(" ").to_array()[0].to_owned()
    None => ""
  }
  guard target.length() > 0 else {
    raise SyntaxError(self.line_number(), "state note needs a target")
  }
  let text = []
  self.index += 1
  while self.index < self.lines.length() {
    let content = @core.strip_line_comment(self.lines[self.index])
      .trim()
      .to_owned()
    if content.equal_ignore_ascii_case("end note") {
      self.notes.push({ target: StateNote(target), text: text.join("\n") })
      return true
    }
    text.push(content)
    self.index += 1
  }
  raise SyntaxError(self.line_number(), "unclosed note")
}

///|
fn Parser::parse_line(
  self : Parser,
  line : String,
) -> Unit raise @core.ParseError {
  let lower = line.to_lower()
  if line.length() == 0 ||
    lower == "@startuml" ||
    lower == "@enduml" ||
    @core.is_preprocessor_directive(line) ||
    @core.parse_style_directive(line) is Some(_) ||
    lower.has_prefix("skinparam ") {
    return
  }
  if self.parse_note(line) {
    return
  }
  if line == "}" || lower == "end state" {
    guard self.stack.pop() is Some(_) else {
      raise SyntaxError(self.line_number(), "end state without composite state")
    }
    return
  }
  if line == "--" || line == "||" {
    guard self.parent() is Some(parent) else {
      raise SyntaxError(
        self.line_number(),
        "concurrent region outside composite state",
      )
    }
    self.concurrent_regions.push(parent)
    return
  }
  if lower.has_prefix("frame ") {
    let (code, _, _, _, _, _, opens_group) = parse_state_declaration(
      "state " + line[6:].trim().to_owned(),
    )
    guard opens_group else {
      raise SyntaxError(self.line_number(), "frame needs an opening brace")
    }
    self.stack.push(code)
    return
  }
  if lower.has_prefix("state ") {
    let (code, display, kind, description, stereotype, color, opens_group) = parse_state_declaration(
      line,
    )
    self.upsert_state({
      code,
      display,
      kind,
      parent: self.parent(),
      description,
      stereotype,
      color,
    })
    if opens_group {
      self.stack.push(code)
    }
    return
  }
  guard self.parse_transition(line) else {
    raise SyntaxError(self.line_number(), "unsupported state command")
  }
}

///|
/// Parse the command family registered by PlantUML's `StateDiagramFactory`.
/// The AST preserves state-specific pseudo-states and composite-state scope.
pub fn parse(input : String) -> StateDiagram raise @core.ParseError {
  let parser = Parser::new(input)
  while parser.index < parser.lines.length() {
    let line = @core.strip_line_comment(parser.lines[parser.index])
      .trim()
      .to_owned()
    parser.parse_line(line)
    parser.index += 1
  }
  guard parser.stack.is_empty() else {
    raise SyntaxError(parser.lines.length(), "unclosed composite state")
  }
  {
    states: parser.states,
    transitions: parser.transitions,
    notes: parser.notes,
    concurrent_regions: parser.concurrent_regions,
  }
}
