///|
pub fn parse(input : String) -> SequenceDiagram {
  let ctx = ParseCtx::new(input)

  ctx.source.skip_whitespace()
  if ctx.source.try_keyword("@startuml") {
    ctx.source.skip_line()
  }

  let parsers : Array[(Source) -> Event?] = [
    arrow, try_note, try_grouping, try_activate, try_deactivate, try_destroy, try_divider,
    try_delay, try_hspace, try_newpage, try_link_anchor,
  ]

  while true {
    ctx.source.skip_whitespace()
    if ctx.source.eof() {
      break
    }
    match ctx.source.peek() {
      Some(c) if c == '\n' => {
        let _ = ctx.source.advance()
        continue
      }
      _ => ()
    }
    match ctx.source.peek() {
      Some(c) if c == '\'' => {
        ctx.source.skip_line()
        continue
      }
      _ => ()
    }
    if ctx.source.try_keyword("@enduml") {
      ctx.source.skip_line()
      break
    }

    let mut matched = false
    for p in parsers {
      if matched {
        break
      }
      let saved = ctx.source.save()
      match p(ctx.source) {
        Some(event) if ctx.source.finish_command(saved) => {
          ctx.register_event(event)
          ctx.events.push(event)
          matched = true
        }
        Some(_) | None => ctx.source.restore(saved)
      }
    }

    if !matched {
      let saved = ctx.source.save()
      match try_participant_decl(ctx.source) {
        Some(decl) if ctx.source.finish_command(saved) => {
          ctx.get_or_create(
            decl.reference.code,
            decl.reference.display,
            decl.typ,
          )
          if decl.created {
            ctx.events.push(Create(true))
          }
          matched = true
        }
        Some(_) | None => ctx.source.restore(saved)
      }
    }

    if !matched {
      ctx.source.skip_line()
    }
  }

  {
    participants: ctx.participants,
    events: ctx.events,
    auto_number: None,
    autoactivate: false,
    show_footbox: true,
  }
}
