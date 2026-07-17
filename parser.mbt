///|
fn ParseCtx::try_event(
  self : ParseCtx,
  parsers : Array[(Source) -> Event?],
) -> Bool {
  for parser in parsers {
    let start = self.source.save()
    match parser(self.source) {
      Some(event) if self.source.finish_command(start) => {
        self.push_event(event)
        return true
      }
      Some(_) | None => self.source.restore(start)
    }
  }
  false
}

///|
fn ParseCtx::try_participant_declaration(self : ParseCtx) -> Bool {
  let start = self.source.save()
  match try_participant_decl(self.source) {
    Some(declaration) if self.source.finish_command(start) => {
      self.declare_participant(declaration)
      true
    }
    Some(_) | None => {
      self.source.restore(start)
      false
    }
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
  match source.peek() {
    Some('\n') => {
      let _ = source.advance()
      true
    }
    Some('\'') => {
      source.skip_line()
      true
    }
    _ => false
  }
}

///|
pub fn parse(input : String) -> SequenceDiagram {
  let ctx = ParseCtx::new(input)
  let parsers : Array[(Source) -> Event?] = [
    arrow, try_exo_arrow, try_note, try_box, try_grouping, try_activate, try_deactivate,
    try_destroy, try_return, try_divider, try_delay, try_hspace, try_newpage, try_reference,
    try_autonumber, try_autoactivate, try_footbox, try_hide_unlinked, try_url, try_ignore_newpage,
    try_auto_newpage, try_link_anchor,
  ]

  ctx.source.skip_whitespace()
  if ctx.source.try_keyword("@startuml") {
    ctx.source.skip_line()
  }

  while !ctx.source.eof() {
    ctx.source.skip_whitespace()
    guard !ctx.source.eof() else { break }
    guard !skip_ignored_line(ctx.source) else { continue }
    if ctx.source.try_keyword("@enduml") {
      ctx.source.skip_line()
      break
    }
    if ctx.try_event(parsers) || ctx.try_participant_declaration() {
      continue
    }
    ctx.source.skip_line()
  }

  let (auto_number, autoactivate, show_footbox) = diagram_options(ctx.events)
  {
    participants: ctx.participants,
    events: ctx.events,
    auto_number,
    autoactivate,
    show_footbox,
  }
}
