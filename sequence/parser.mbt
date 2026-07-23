///|
fn ParseCtx::try_style_directive(self : ParseCtx) -> Bool raise ParseError {
  let line = self.source.current_line()
  if line.trim().to_lower() == "skinparam {" {
    self.source.skip_line()
    while !self.source.eof() {
      let property = self.source.collect_line()
      if property.trim() == "}" {
        return true
      }
      match @core.parse_style_property(property) {
        Some(directive) => self.style.apply(directive)
        None => ()
      }
    }
    self.source.raise_parse_error("unclosed skinparam")
  }
  match @core.parse_style_directive(line) {
    Some(directive) => {
      self.source.skip_line()
      self.style.apply(directive)
      true
    }
    None => false
  }
}

///|
fn diagram_options(events : Array[Event]) -> (Autonumber?, Bool, Bool) {
  let mut auto_number = None
  let mut autoactivate = false
  let mut show_footbox = true
  for event in events {
    match event {
      Autonumber(config) => auto_number = Some(config)
      AutonumberStop => auto_number = None
      Autoactivate(enabled) => autoactivate = enabled
      Footbox(enabled) => show_footbox = enabled
      _ => ()
    }
  }
  (auto_number, autoactivate, show_footbox)
}

///|
fn skip_ignored_line(source : Source) -> Bool {
  let line = source.current_line().trim()
  if line.length() == 0 || line.has_prefix("'") {
    source.skip_line()
    true
  } else {
    false
  }
}

///|
/// Parse a PlantUML sequence diagram string into a `SequenceDiagram`.
///
/// Parameters:
///
/// - `input`: the raw PlantUML source text, optionally wrapped with `@startuml` / `@enduml`.
///
/// Returns a `SequenceDiagram` containing the parsed participants and events.
pub fn parse(input : String) -> SequenceDiagram raise ParseError {
  let ctx = ParseCtx::new(input)

  if ctx.source.current_line().trim().equal_ignore_ascii_case("@startuml") {
    ctx.source.skip_line()
  }

  while !ctx.source.eof() {
    guard !skip_ignored_line(ctx.source) else { continue }
    if ctx.source.current_line().trim().equal_ignore_ascii_case("@enduml") {
      ctx.source.skip_line()
      break
    }
    if ctx.try_style_directive() {
      continue
    }
    let directive = ctx.source.current_line()
    if @core.is_preprocessor_directive(directive) {
      ctx.source.skip_line()
      continue
    }
    let line = ctx.source.current_line().trim().to_owned()
    guard parse_sequence_line(line) is Some(syntax) else {
      let diagnostic = ctx.source.diagnostic(ctx.source.current_line())
      raise SyntaxError(diagnostic.line_number(), diagnostic.message)
    }
    ctx.apply_line_syntax(syntax)
    continue
  }

  ctx.ensure_no_pending_create()
  guard ctx.grouping_depth == 0 else {
    let diagnostic = ctx.source.diagnostic("unclosed group")
    raise SyntaxError(diagnostic.line_number(), diagnostic.message)
  }
  guard ctx.box_stack.is_empty() else {
    let diagnostic = ctx.source.diagnostic("unclosed box")
    raise SyntaxError(diagnostic.line_number(), diagnostic.message)
  }

  let (auto_number, autoactivate, show_footbox) = diagram_options(ctx.events)
  {
    participants: ctx.participants,
    events: ctx.events,
    auto_number,
    autoactivate,
    show_footbox,
    style: ctx.style,
  }
}
