///|
/// Message contacts selected from each waveform's TimeProjected endpoints.
pub(all) struct TimingMessageLayout {
  index : Int
  start : @graphics.Point
  end : @graphics.Point
}

///|
fn timing_projection(
  player : @flow.TimingPlayer,
  panel : TimingPlayerLayout,
  layout : TimingLayout,
  tick : @flow.TimeTick?,
) -> Array[@graphics.Point]? {
  guard tick is Some(tick) else { return None }
  let time = timing_tick(tick)
  let x = layout.wave_x + layout.ruler.position(time)
  let point = y => ({ x, y, } : @graphics.Point)
  match player.kind {
    Robust => {
      guard !player.changes.is_empty() else { return None }
      for index, change in player.changes {
        let when = timing_tick(change.when.unwrap())
        if when == time {
          let previous = if index == 0 {
            player.initial.map_or(change.states[0], initial => initial.states[0])
          } else {
            player.changes[index - 1].states[0]
          }
          return Some([
            point(panel.wave_y + panel.state_y(previous)),
            point(panel.wave_y + panel.state_y(change.states[0])),
          ])
        }
        if when > time {
          let state = player.changes[(index - 1).max(0)].states[0]
          return Some([point(panel.wave_y + panel.state_y(state))])
        }
      }
      Some([
        point(
          panel.wave_y +
          panel.state_y(player.changes[player.changes.length() - 1].states[0]),
        ),
      ])
    }
    Concise | Rectangle =>
      if player.changes.any(change => timing_tick(change.when.unwrap()) == time) {
        Some([point(panel.wave_y + panel.wave_height / 2.0)])
      } else {
        Some([point(panel.wave_y), point(panel.wave_y + panel.wave_height)])
      }
    Binary => Some([point(panel.wave_y + TIMING_MARGIN_Y)])
    Clock => {
      let period = timing_number(player.period.unwrap_or("0"), 0.0)
      let offset = timing_number(player.offset.unwrap_or("0"), 0.0)
      let pulse = timing_number(player.pulse.unwrap_or("0"), 0.0)
      let pulse = if pulse == 0.0 { period / 2.0 } else { pulse }
      let high = period > 0.0 &&
        time >= offset &&
        (time - offset) % period < pulse
      Some([
        point(
          panel.wave_y +
          (if high {
            TIMING_MARGIN_Y
          } else {
            panel.wave_height - TIMING_MARGIN_Y
          }),
        ),
      ])
    }
    Analog => {
      guard !player.changes.is_empty() else { return None }
      let mut previous = player.changes[0]
      for change in player.changes {
        let when = timing_tick(change.when.unwrap())
        let value = timing_number(change.states[0], 0.0)
        if when >= time {
          let before = timing_tick(previous.when.unwrap())
          let interpolated = if before == when {
            value
          } else {
            let first = timing_number(previous.states[0], 0.0)
            first + (value - first) * (time - before) / (when - before)
          }
          return Some([point(timing_analog_y(panel, interpolated))])
        }
        previous = change
      }
      Some([
        point(timing_analog_y(panel, timing_number(previous.states[0], 0.0))),
      ])
    }
  }
}

///|
fn timing_messages(
  diagram : @flow.TimingDiagram,
  layout : TimingLayout,
) -> Array[TimingMessageLayout] {
  let result = []
  let panel_for = (code : String) => {
    for panel in layout.players {
      if diagram.players[panel.index].code == code {
        return Some(panel)
      }
    }
    None
  }
  for index, message in diagram.messages {
    guard panel_for(message.player1) is Some(first) &&
      panel_for(message.player2) is Some(second) else {
      continue
    }
    guard timing_projection(
        diagram.players[first.index],
        first,
        layout,
        message.tick1,
      )
      is Some(starts) &&
      timing_projection(
        diagram.players[second.index],
        second,
        layout,
        message.tick2,
      )
      is Some(ends) else {
      continue
    }
    let mut start = starts[0]
    let mut end = ends[0]
    let distance = (a : @graphics.Point, b : @graphics.Point) => {
      (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
    }
    for a in starts {
      for b in ends {
        if distance(a, b) <= distance(start, end) {
          start = a
          end = b
        }
      }
    }
    result.push({ index, start, end, })
  }
  result
}

///|
fn timing_link_paint(
  appearance : TimingAppearance,
  style : String?,
) -> @graphics.DrawingStyle {
  let mut paint = appearance.paint()
  guard style is Some(style) else { return paint }
  for part in style.trim(chars="[]").split(",") {
    let word = part.trim().to_owned()
    match word.to_lower() {
      "dashed" => paint = { ..paint, dash: Some([7.0, 7.0]), }
      "dotted" => paint = { ..paint, dash: Some([1.0, 3.0]), }
      "bold" => paint = { ..paint, stroke_width: Some(2.0), }
      "plain" => paint = { ..paint, dash: None, }
      "hidden" => paint = { ..paint, stroke: None, }
      _ =>
        if word.has_prefix("thickness=") {
          paint = {
            ..paint,
            stroke_width: Some(
              timing_number(word[10:].to_owned(), appearance.thickness),
            ),
          }
        } else if word.has_prefix("#") {
          paint = {
            ..paint,
            stroke: Color(@svg.svg_color(Some(word), appearance.line)),
          }
        }
    }
  }
  paint
}

///|
fn draw_timing_messages(
  drawing : TimingDrawing,
  diagram : @flow.TimingDiagram,
  layout : TimingLayout,
) -> Unit {
  for route in layout.messages {
    let message = diagram.messages[route.index]
    let appearance = timing_appearance(drawing.style, "arrow")
    let (a, b) = drawing.arrow(
      route.start,
      route.end,
      timing_link_paint(appearance, message.style),
    )
    if message.label is Some(label) {
      let y = (a.y + b.y) / 2.0 -
        (if route.start.y < route.end.y {
          timing_text_size(label, appearance).1
        } else {
          0.0
        })
      drawing.text(label, (a.x + b.x) / 2.0, y, "arrow")
    }
  }
}

///|
fn draw_timing_constraints(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  guard !(player.kind is @flow.PlayerKind::Clock) else { return }
  let appearance = timing_appearance(drawing.style, "constraintArrow")
  let inset = match player.kind {
    Analog | Concise | Rectangle => 1.0
    _ => TIMING_CONSTRAINT_INSET
  }
  for constraint in player.constraints {
    let paint = timing_link_paint(appearance, constraint.style)
    let x1 = layout.wave_x +
      layout.ruler.position(timing_tick(constraint.tick1)) +
      inset
    let x2 = layout.wave_x +
      layout.ruler.position(timing_tick(constraint.tick2)) -
      inset
    let y = panel.panel_y +
      (match player.kind {
        Robust =>
          panel.constraint_height -
          TIMING_CONSTRAINT_MARGIN +
          timing_constraint_delta(player, panel, constraint)
        Concise | Rectangle => panel.constraint_height / 2.0
        _ => panel.constraint_height
      })
    let outward = x2 - x1 > TIMING_ROBUST_STEP
    let tip = (x : Double, sign : Double) => {
      drawing.polygon(
        [
          { x, y, },
          {
            x: x + sign * TIMING_ARROW_LENGTH,
            y: y - TIMING_ARROW_HALF_HEIGHT,
          },
          {
            x: x + sign * TIMING_ARROW_LENGTH,
            y: y + TIMING_ARROW_HALF_HEIGHT,
          },
        ],
        { ..paint, fill: paint.stroke, stroke_width: Some(1.0), dash: None, },
        class_name="timing-constraint-arrow",
      )
    }
    drawing.line(
      x1 + (if outward { 3.0 } else { -1.0 }),
      y,
      x2 + (if outward { -3.0 } else { 1.0 }),
      y,
      paint,
      class_name="timing-constraint",
    )
    tip(x1, if outward { 1.0 } else { -1.0 })
    tip(x2, if outward { -1.0 } else { 1.0 })
    if constraint.message is Some(label) {
      drawing.text(
        label,
        (x1 + x2) / 2.0,
        y - timing_text_size(label, appearance).1 - TIMING_CONSTRAINT_MARGIN,
        "constraintArrow",
        anchor=Middle,
      )
    }
  }
}

///|
fn draw_timing_notes(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  guard player.kind
    is (@flow.PlayerKind::Concise
    | @flow.PlayerKind::Rectangle
    | @flow.PlayerKind::Binary) else {
    return
  }
  let appearance = timing_appearance(drawing.style, "note")
  for note in player.notes {
    let x = layout.wave_x +
      note.when.map_or(0.0, tick => layout.ruler.position(timing_tick(tick)))
    let y = if player.kind is @flow.PlayerKind::Binary {
      if note.position == "top" {
        panel.panel_y + TIMING_MARGIN_Y
      } else {
        panel.panel_y +
        panel.constraint_height +
        panel.top_notes +
        panel.wave_height -
        TIMING_MARGIN_Y / 2.0 +
        TIMING_NOTE_MARGIN / 2.0
      }
    } else if note.position == "top" {
      panel.panel_y
    } else {
      panel.panel_y +
      panel.constraint_height +
      panel.wave_height +
      panel.top_notes +
      TIMING_NOTE_MARGIN / 2.0
    }
    let (width, height) = timing_note_size(note, drawing.style)
    let corner = STATE_NOTE_CORNER
    drawing.polygon(
      [
        { x, y, },
        { x: x + width - corner, y, },
        { x: x + width, y: y + corner, },
        { x: x + width, y: y + height, },
        { x, y: y + height, },
      ],
      appearance.paint(fill=true),
      class_name="timing-note",
    )
    drawing.polygon(
      [
        { x: x + width - corner, y, },
        { x: x + width - corner, y: y + corner, },
        { x: x + width, y: y + corner, },
      ],
      appearance.paint(),
      closed=false,
      class_name="timing-note-fold",
    )
    drawing.text(
      note.text,
      x + STATE_NOTE_LEFT_MARGIN,
      y + STATE_NOTE_VERTICAL_MARGIN,
      "note",
    )
  }
}
