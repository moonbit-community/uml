///|
priv struct StateScope {
  code : String
  region_index : Int
}

///|
priv struct Parser {
  buffer : LineBuffer
  states : Array[@flow.StateNode]
  state_names : Array[StateName]
  pending_commands : Array[ScopedStateCommand]
  transitions : Array[@flow.StateTransition]
  notes : Array[@flow.StateNote]
  mut last_entity : @flow.StateNoteTarget?
  stack : Array[StateScope]
  concurrent_regions : Array[String]
  regions : Array[@flow.StateRegion]
  style : @style.DocumentStyle
}

///|
fn Parser::new(input : String) -> Parser {
  {
    buffer: LineBuffer::new(input),
    states: [],
    state_names: [state_root_name()],
    pending_commands: [],
    transitions: [],
    notes: [],
    last_entity: None,
    stack: [],
    concurrent_regions: [],
    regions: [],
    style: @style.DocumentStyle::empty(),
  }
}

///|
fn Parser::line_number(self : Parser) -> Int {
  self.buffer.line_number()
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
  separator : @flow.StateRegionSeparator?,
) -> Int {
  let index = self.regions.length()
  self.regions.push({ parent, separator, index, })
  index
}

///|
priv enum EndpointRole {
  TransitionSource
  TransitionTarget
}

///|
fn endpoint_kind(value : String, role : EndpointRole) -> @flow.StateKind {
  match value {
    "[*]" =>
      match role {
        TransitionSource => @flow.StateKind::Initial
        TransitionTarget => @flow.StateKind::Final
      }
    "[H]" => @flow.StateKind::History
    "[H*]" => @flow.StateKind::DeepHistory
    _ if value.has_suffix("[H]") => @flow.StateKind::History
    _ if value.has_suffix("[H*]") => @flow.StateKind::DeepHistory
    _ if value.has_prefix("==") && value.has_suffix("==") =>
      @flow.StateKind::Synchronization
    _ => @flow.StateKind::Normal
  }
}

///|
fn Parser::ensure_endpoint(
  self : Parser,
  raw : String,
  role : EndpointRole,
) -> String raise @tokenizer.ParseError {
  let kind = endpoint_kind(raw, role)
  let location = match kind {
    @flow.StateKind::Normal => {
      let name = self.resolve_state_name(raw, allow_current=true)
      self.state_name_location(name, raw, create_parents=false)
    }
    @flow.StateKind::Synchronization => {
      let value = raw[2:raw.length() - 2].to_owned()
      let name = self.resolve_state_name(value, allow_current=false)
      self.state_name_location(
        name,
        "__synchronization_" + value,
        create_parents=false,
      )
    }
    _ => self.pseudo_state_location(raw, kind)
  }
  let code = location.code
  if kind == @flow.StateKind::Normal {
    self.check_state_reference(code)
  }
  if !self.states.any(state => state.code == code) {
    self.states.push({
      code,
      display: location.display,
      kind,
      parent: location.parent,
      region_index: location.region_index,
      description: None,
      stereotype: None,
      url: None,
      color: None,
    })
  }
  code
}

///|
fn Parser::upsert_state(
  self : Parser,
  state : @flow.StateNode,
  group? : Bool = false,
) -> Unit {
  for index, existing in self.states {
    if existing.code == state.code {
      self.states[index] = {
        ..state,
        // Reusing a Quark updates the existing entity without moving it to
        // the scope of a later declaration (CommandCreateState.executeArg).
        parent: existing.parent,
        region_index: existing.region_index,
        kind: if group {
          state.kind
        } else {
          existing.kind
        },
        description: append_state_description(
          existing.description,
          state.description,
        ),
      }
      return
    }
  }
  self.states.push(state)
}

///|
/// CommandCreateState and CommandAddField both append to the same body.
fn append_state_description(previous : String?, line : String?) -> String? {
  guard line is Some(line) else { return previous }
  Some(previous.map_or(line, previous => previous + "\n" + line))
}

///|
fn Parser::add_state_field(
  self : Parser,
  raw : String,
  text : String,
) -> Unit raise @tokenizer.ParseError {
  let name = self.resolve_state_name(raw, allow_current=true)
  let location = self.state_name_location(name, raw, create_parents=false)
  let code = location.code
  if self.states.search_by(state => state.code == code) is Some(index) {
    let state = self.states[index]
    self.states[index] = {
      ..state,
      description: append_state_description(state.description, Some(text)),
    }
  } else {
    self.states.push({
      code,
      display: location.display,
      kind: @flow.StateKind::Normal,
      parent: location.parent,
      region_index: location.region_index,
      description: Some(text),
      stereotype: None,
      url: None,
      color: None,
    })
  }
}

///|
fn Parser::consume_entity_note(
  self : Parser,
  note : StateEntityNoteSyntax,
) -> Unit raise @tokenizer.ParseError {
  let target = if note.target is Some(raw) {
    let name = self.resolve_state_name(raw, allow_current=false)
    guard self.state_names[name].code is Some(code) else {
      raise SyntaxError(
        self.line_number(),
        "state note refers to an unknown state",
      )
    }
    @flow.StateNote(code)
  } else {
    guard self.last_entity is Some(target) else {
      raise SyntaxError(
        self.line_number(),
        "state note needs a preceding entity",
      )
    }
    target
  }
  let (text, text_mode) = self.consume_note_body(note.body)
  self.last_entity = Some(@flow.NoteNote(self.notes.length()))
  self.notes.push({
    target,
    parent: self.parent(),
    region_index: self.region_index(),
    text,
    text_mode,
    color: note.color,
    position: Some(note.position),
  })
}

///|
fn Parser::consume_note_body(
  self : Parser,
  body : StateNoteBody,
  allow_empty_block? : Bool = true,
) -> (String, @flow.StateNoteTextMode) raise @tokenizer.ParseError {
  let terminates = match body {
    Inline(text) => return (text, @flow.InlineText)
    Resolved(text, mode) => return (text, mode)
    Block => state_note_end
    BracedBlock => (line : String) => line == "}"
  }
  let mut index = self.buffer.index + 1
  guard @tokenizer.collect_lines_until(
      () => {
        guard index < self.buffer.lines.length() else { return None }
        let line = self.buffer.lines[index]
        index += 1
        Some(line)
      },
      line => terminates(line.trim().to_owned()),
    )
    is Some(text) else {
    raise SyntaxError(self.line_number(), "unclosed note")
  }
  guard allow_empty_block || !text.is_empty() else {
    raise SyntaxError(self.line_number(), "empty link note block")
  }
  self.buffer.index = index - 1
  (state_note_block_text(text), @flow.BlockText)
}

///|
fn Parser::apply_line_syntax(
  self : Parser,
  line : String,
) -> Bool raise @tokenizer.ParseError {
  guard parse_line_syntax(line) is Some(syntax) else { return false }
  match syntax {
    Field(code~, text~) => {
      self.add_state_field(code, text)
      true
    }
    Declaration(syntax) => {
      let name = self.resolve_state_name(syntax.code, allow_current=false)
      let location = self.state_name_location(
        name,
        syntax.code,
        create_parents=true,
      )
      if !syntax.opens_group {
        self.check_state_reference(location.code)
      }
      self.upsert_state(
        {
          code: location.code,
          display: syntax.display.unwrap_or_else(() => {
            if syntax.opens_group {
              self
              .existing_state_display(location.code)
              .unwrap_or(location.display)
            } else {
              location.display
            }
          }),
          kind: syntax.kind,
          parent: location.parent,
          region_index: location.region_index,
          description: syntax.description,
          stereotype: syntax.stereotype,
          url: syntax.url,
          color: syntax.color,
        },
        group=syntax.opens_group,
      )
      if syntax.opens_group {
        self.open_state_scope(location.code)
      } else {
        self.queue_state_command(Focus(location.code))
      }
      true
    }
    Frame(syntax) => {
      let name = self.resolve_state_name(syntax.code, allow_current=false)
      let location = self.state_name_location(
        name,
        syntax.code,
        create_parents=true,
      )
      self.upsert_state(
        {
          code: location.code,
          // CommandCreatePackage2 relies on gotoGroup, which sets the title
          // only when the group is first created.
          display: self
          .existing_state_display(location.code)
          .unwrap_or_else(() => syntax.display.unwrap_or(location.display)),
          kind: @flow.Frame,
          parent: location.parent,
          region_index: location.region_index,
          description: syntax.description,
          stereotype: syntax.stereotype,
          url: syntax.url,
          color: syntax.color,
        },
        group=true,
      )
      self.open_state_scope(location.code)
      true
    }
    Transition(syntax) => {
      self.queue_state_command(Transition(syntax))
      true
    }
    EntityNote(note) => {
      self.queue_state_command(EntityNote(note))
      true
    }
    LinkNote(note) => {
      self.queue_state_command(LinkNote(note))
      true
    }
  }
}

///|
fn Parser::parse_line(
  self : Parser,
  line : String,
) -> Unit raise @tokenizer.ParseError {
  let lower = line.to_lower()
  if line.length() == 0 ||
    lower == "@startuml" ||
    lower == "@enduml" ||
    @style.is_preprocessor_directive(line) {
    return
  }
  if self.consume_state_document(line) {
    return
  }
  if self.consume_state_scale(line) {
    return
  }
  match @style.parse_style_directive(line) {
    Some(directive) => {
      self.apply_state_style(directive)
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
    let region_index = self.open_concurrent_region(
      parent,
      if line == "||" {
        @flow.StateRegionSeparator::Vertical
      } else {
        @flow.StateRegionSeparator::Horizontal
      },
    )
    if self.stack.last() is Some(scope) {
      self.stack[self.stack.length() - 1] = { ..scope, region_index, }
    }
    return
  }
  raise SyntaxError(self.line_number(), "unsupported state command")
}

///|
/// Parse the command family registered by PlantUML's `StateDiagramFactory`.
/// The AST preserves state-specific pseudo-states and composite-state scope.
/// Previously verified: redeclarations preserve ownership and append fields;
/// forward note targets resolve, invalid targets fail, and note/style block
/// closers resume parsing without consuming the containing state scope.
pub fn parse_state(
  input : String,
) -> @flow.StateDiagram raise @tokenizer.ParseError {
  let parser = Parser::new(input)
  while !parser.buffer.at_end() {
    let line = parser.buffer.current_clean()
    if state_skinparam_prefix(line) is Some(prefix) {
      parser.buffer.consume_skinparam(
        parser.style,
        parser.buffer.line_number(),
        prefix~,
        apply=Some(directive => parser.apply_state_style(directive)),
      )
      continue
    }
    parser.parse_line(line)
    parser.buffer.advance()
  }
  guard parser.stack.is_empty() else {
    raise SyntaxError(parser.buffer.length(), "unclosed composite state")
  }
  parser.resolve_state_commands()
  parser.validate_state_links()
  {
    states: parser.states,
    transitions: parser.transitions,
    notes: parser.notes,
    concurrent_regions: parser.concurrent_regions,
    regions: parser.regions,
    style: parser.style,
  }
}
