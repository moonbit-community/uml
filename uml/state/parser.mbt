///|
priv struct StateScope {
  code : String
  region_index : Int
}

///|
priv struct Parser {
  lines : Array[String]
  states : Array[StateNode]
  transitions : Array[StateTransition]
  notes : Array[StateNote]
  stack : Array[StateScope]
  concurrent_regions : Array[String]
  regions : Array[StateRegion]
  style : @style.DocumentStyle
  mut index : Int
}

///|
fn Parser::new(input : String) -> Parser {
  {
    lines: @parse.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array(),
    states: [],
    transitions: [],
    notes: [],
    stack: [],
    concurrent_regions: [],
    regions: [],
    style: @style.DocumentStyle::empty(),
    index: 0,
  }
}

///|
fn Parser::line_number(self : Parser) -> Int {
  self.index + 1
}

///|
fn Parser::parent(self : Parser) -> String? {
  self.stack.last().map(scope => scope.code)
}

///|
fn Parser::region_index(self : Parser) -> Int {
  self.stack.last().map_or(-1, scope => scope.region_index)
}

///|
fn Parser::open_region(
  self : Parser,
  parent : String,
  separator : StateRegionSeparator?,
) -> Int {
  let index = self.regions.length()
  self.regions.push({ parent, separator, index })
  index
}

///|
priv enum EndpointRole {
  TransitionSource
  TransitionTarget
}

///|
fn endpoint_kind(value : String, role : EndpointRole) -> StateKind {
  match value {
    "[*]" =>
      match role {
        TransitionSource => Initial
        TransitionTarget => Final
      }
    "[H]" => History
    "[H*]" => DeepHistory
    _ if value.has_prefix("==") && value.has_suffix("==") => Synchronization
    _ => Normal
  }
}

///|
fn endpoint_code(value : String, role : EndpointRole) -> String {
  match value {
    "[*]" =>
      match role {
        TransitionSource => "__initial__"
        TransitionTarget => "__final__"
      }
    "[H]" => "__history__"
    "[H*]" => "__deep_history__"
    _ if value.has_prefix("==") && value.has_suffix("==") =>
      "__synchronization_" + value[2:value.length() - 2].to_owned()
    _ => value
  }
}

///|
fn Parser::ensure_endpoint(
  self : Parser,
  raw : String,
  role : EndpointRole,
) -> String {
  let base_code = endpoint_code(raw, role)
  let code = match self.parent() {
    Some(parent) if raw == "[*]" ||
      raw == "[H]" ||
      raw == "[H*]" ||
      (raw.has_prefix("==") && raw.has_suffix("==")) => base_code + parent
    _ => base_code
  }
  if !self.states.any(state => state.code == code) {
    self.states.push({
      code,
      display: raw,
      kind: endpoint_kind(raw, role),
      parent: self.parent(),
      region_index: self.region_index(),
      description: None,
      stereotype: None,
      url: None,
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
fn Parser::consume_entity_note(
  self : Parser,
  target : String,
  color : String?,
) -> Unit raise @parse.ParseError {
  guard target.length() > 0 else {
    raise SyntaxError(self.line_number(), "state note needs a target")
  }
  let mut index = self.index + 1
  guard @parse.collect_lines_until(
      fn() {
        guard index < self.lines.length() else { return None }
        let line = @parse.strip_line_comment(self.lines[index])
          .trim()
          .to_owned()
        index += 1
        Some(line)
      },
      line => line.equal_ignore_ascii_case("end note"),
    )
    is Some(text) else {
    raise SyntaxError(self.line_number(), "unclosed note")
  }
  self.index = index - 1
  self.notes.push({ target: StateNote(target), text: text.join("\n"), color })
}

///|
fn Parser::apply_line_syntax(
  self : Parser,
  line : String,
) -> Bool raise @parse.ParseError {
  guard parse_line_syntax(line) is Some(syntax) else { return false }
  match syntax {
    Declaration(syntax) => {
      self.upsert_state({
        code: syntax.code,
        display: syntax.display,
        kind: syntax.kind,
        parent: self.parent(),
        region_index: self.region_index(),
        description: syntax.description,
        stereotype: syntax.stereotype,
        url: syntax.url,
        color: syntax.color,
      })
      if syntax.opens_group {
        let region_index = self.open_region(syntax.code, None)
        self.stack.push({ code: syntax.code, region_index })
      }
      true
    }
    Frame(syntax) => {
      self.upsert_state({
        code: syntax.code,
        display: syntax.display,
        kind: syntax.kind,
        parent: self.parent(),
        region_index: self.region_index(),
        description: syntax.description,
        stereotype: syntax.stereotype,
        url: syntax.url,
        color: syntax.color,
      })
      let region_index = self.open_region(syntax.code, None)
      self.stack.push({ code: syntax.code, region_index })
      true
    }
    Transition(syntax) => {
      let source = self.ensure_endpoint(syntax.source, TransitionSource)
      let target = self.ensure_endpoint(syntax.target, TransitionTarget)
      self.transitions.push({
        source,
        target,
        label: syntax.label,
        direction: syntax.direction,
        line_style: syntax.line_style,
        has_cross_start: syntax.has_cross_start,
      })
      true
    }
    EntityNote(note) => {
      self.consume_entity_note(note.target, note.color)
      true
    }
    LinkNote(note) => {
      guard self.transitions.length() > 0 else {
        raise SyntaxError(self.line_number(), "link note without transition")
      }
      self.notes.push({
        target: TransitionNote(self.transitions.length() - 1),
        text: note.text,
        color: note.color,
      })
      true
    }
  }
}

///|
fn Parser::parse_line(
  self : Parser,
  line : String,
) -> Unit raise @parse.ParseError {
  let lower = line.to_lower()
  if line.length() == 0 ||
    lower == "@startuml" ||
    lower == "@enduml" ||
    @style.is_preprocessor_directive(line) {
    return
  }
  match @style.parse_style_directive(line) {
    Some(directive) => {
      self.style.apply(directive)
      return
    }
    None => ()
  }
  if self.apply_line_syntax(line) {
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
    let region_index = self.open_region(
      parent,
      Some(if line == "||" { Vertical } else { Horizontal }),
    )
    match self.stack.last() {
      Some(scope) =>
        self.stack[self.stack.length() - 1] = { ..scope, region_index, }
      None => ()
    }
    return
  }
  raise SyntaxError(self.line_number(), "unsupported state command")
}

///|
/// Parse the command family registered by PlantUML's `StateDiagramFactory`.
/// The AST preserves state-specific pseudo-states and composite-state scope.
pub fn parse(input : String) -> StateDiagram raise @parse.ParseError {
  let parser = Parser::new(input)
  while parser.index < parser.lines.length() {
    let line = @parse.strip_line_comment(parser.lines[parser.index])
      .trim()
      .to_owned()
    if line.to_lower() == "skinparam {" {
      parser.index += 1
      let closed = @style.consume_skinparam_body(
        fn() {
          guard parser.index < parser.lines.length() else { return None }
          let line = @parse.strip_line_comment(parser.lines[parser.index])
          parser.index += 1
          Some(line)
        },
        fn(directive) { parser.style.apply(directive) },
      )
      guard closed else {
        raise SyntaxError(parser.lines.length(), "unclosed skinparam")
      }
      continue
    }
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
    regions: parser.regions,
    style: parser.style,
  }
}
