///|
fn ParseCtx::consume_style_directive(
  self : ParseCtx,
) -> Bool raise @parse.ParseError {
  let line = @parse.strip_line_comment(self.source.current_line())
  let lower = line.trim().to_lower()
  guard lower != "newpage" && !lower.has_prefix("newpage ") else {
    return false
  }
  if line.trim().to_lower() == "skinparam {" {
    self.source.skip_line()
    let closed = @style.consume_skinparam_body(
      () => {
        guard !self.source.is_eof() else { return None }
        Some(@parse.strip_line_comment(self.source.take_line()))
      },
      directive => self.style.apply(directive),
    )
    guard closed else { self.source.raise_parse_error("unclosed skinparam") }
    return true
  }
  guard @style.parse_style_directive(line) is Some(directive) else {
    return false
  }
  self.source.skip_line()
  self.style.apply(directive)
  true
}

///|
priv struct DiagramOptions {
  autoactivate : Bool
  show_footbox : Bool
}

///|
fn diagram_options(events : Array[@seq.Event]) -> DiagramOptions {
  let mut autoactivate = false
  let mut show_footbox = true
  for event in events {
    match event {
      @seq.Autoactivate(enabled) => autoactivate = enabled
      @seq.Footbox(enabled) => show_footbox = enabled
      _ => ()
    }
  }
  { autoactivate, show_footbox, }
}

///|
fn skip_ignored_line(source : @parse.Cursor) -> Bool {
  let line = source.current_line().trim()
  if line.length() == 0 || line.has_prefix("'") {
    source.skip_line()
    true
  } else {
    false
  }
}

///|
/// Parse a PlantUML sequence diagram string into a `@seq.SequenceDiagram`.
///
/// Parameters:
///
/// - `input`: the raw PlantUML source text, optionally wrapped with `@startuml` / `@enduml`.
///
/// Returns a `@seq.SequenceDiagram` containing the parsed participants and events.
pub fn parse_sequence(
  input : String,
) -> @seq.SequenceDiagram raise @parse.ParseError {
  let ctx = ParseCtx::new(input)

  while !ctx.source.is_eof() {
    guard !skip_ignored_line(ctx.source) else { continue }
    let raw_line = ctx.source.current_line()
    let line = @parse.strip_line_comment(raw_line)
    if line.trim().equal_ignore_ascii_case("@startuml") {
      ctx.source.skip_line()
      continue
    }
    if line.trim().equal_ignore_ascii_case("@enduml") {
      ctx.source.skip_line()
      break
    }
    if ctx.consume_style_directive() {
      continue
    }
    let directive = line
    if @style.is_preprocessor_directive(directive) {
      ctx.source.skip_line()
      continue
    }
    let line = line.trim().to_owned()
    guard line.length() > 0 else { continue }
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

  let options = diagram_options(ctx.events)
  {
    participants: ctx.participants,
    events: ctx.events,
    autoactivate: options.autoactivate,
    show_footbox: options.show_footbox,
    style: ctx.style,
  }
}
