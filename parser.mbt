///|
pub fn parse(input : String) -> SequenceDiagram {
  let ctx = ParseCtx::new(input)

  ctx.source.skip_whitespace()
  if ctx.source.try_keyword("@startuml") {
    ctx.source.skip_line()
  }

  let parsers : Array[(Source) -> Event?] = [
    arrow, try_exo_arrow, try_note, try_box, try_grouping, try_activate, try_deactivate,
    try_destroy, try_return, try_divider, try_delay, try_hspace, try_newpage, try_reference,
    try_autonumber, try_autoactivate, try_footbox, try_hide_unlinked, try_url, try_ignore_newpage,
    try_auto_newpage, try_link_anchor,
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
          let participant = ctx.participants[decl.reference.code]
          ctx.participants[decl.reference.code] = {
            ..participant,
            display: decl.reference.display,
            typ: decl.typ,
            color: match decl.color {
              Some(color) => Some(color)
              None => participant.color
            },
            boxes: ctx.box_stack.copy(),
            order: match decl.order {
              Some(order) => Some(order)
              None => participant.order
            },
          }
          if decl.created {
            ctx.events.push(Create)
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

  let mut auto_number = None
  let mut autoactivate = false
  let mut show_footbox = true
  for event in ctx.events {
    match event {
      Autonumber(config) => auto_number = Some(config)
      AutonumberStop => auto_number = None
      Autoactivate(enabled) => autoactivate = enabled
      Footbox(enabled) => show_footbox = enabled
      _ => ()
    }
  }

  {
    participants: ctx.participants,
    events: ctx.events,
    auto_number,
    autoactivate,
    show_footbox,
  }
}
