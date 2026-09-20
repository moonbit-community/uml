///|
fn timing_analog_y(panel : TimingPlayerLayout, value : Double) -> Double {
  let span = panel.maximum - panel.minimum
  let fraction = if span == 0.0 { 0.0 } else { (value - panel.minimum) / span }
  panel.wave_y +
  panel.wave_height -
  TIMING_MARGIN_Y -
  fraction * (panel.wave_height - TIMING_MARGIN_Y * 2.0)
}

///|
fn draw_timing_analog(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  let appearance = timing_appearance(drawing.style, "analog")
  let paint = appearance.paint()
  for tick in panel.ticks {
    let y = timing_analog_y(panel, tick)
    let label = timing_analog_label(player, tick)
    drawing.text(
      label,
      layout.wave_x - 2.0,
      y - timing_text_size(label, appearance).1 / 2.0,
      "analog",
      anchor=End,
    )
    if player.ticks_every is Some(_) {
      drawing.line(
        layout.wave_x,
        y,
        layout.wave_x + layout.ruler.width,
        y,
        { ..paint, dash: Some([3.0, 5.0]), stroke_width: Some(0.5), },
        class_name="timing-grid",
      )
    }
  }
  let mut x = layout.wave_x
  let mut y = timing_analog_y(
    panel,
    player.initial.map_or(0.0, change => timing_number(change.states[0], 0.0)),
  )
  for change in player.changes {
    let next_x = layout.wave_x +
      layout.ruler.position(timing_tick(change.when.unwrap()))
    let next_y = timing_analog_y(panel, timing_number(change.states[0], 0.0))
    drawing.line(x, y, next_x, next_y, paint)
    x = next_x
    y = next_y
  }
  drawing.line(x, y, layout.wave_x + layout.ruler.width, y, paint)
}

///|
fn draw_timing_binary(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  let paint = timing_appearance(drawing.style, "binary").paint()
  let high = panel.wave_y + TIMING_MARGIN_Y
  let low = panel.wave_y + panel.wave_height - TIMING_MARGIN_Y
  let state_y = (states : Array[String]) => {
    if states[0] == "0" {
      low
    } else {
      high
    }
  }
  let mut states = player.initial.map_or(["0"], change => change.states)
  let mut x = layout.wave_x
  for change in player.changes {
    let next_x = layout.wave_x +
      layout.ruler.position(timing_tick(change.when.unwrap()))
    if states.length() == 1 {
      drawing.line(x, state_y(states), next_x, state_y(states), paint)
    } else {
      for hatch = x; hatch < next_x; hatch = hatch + TIMING_HATCH_STEP {
        drawing.line(hatch, high, hatch, low, paint)
      }
    }
    if states != change.states {
      drawing.line(next_x, high, next_x, low, paint)
    }
    if change.comment is Some(comment) {
      drawing.text(comment, next_x + 2.0, high, "binary")
    }
    x = next_x
    states = change.states
  }
  drawing.line(
    x,
    state_y(states),
    layout.wave_x + layout.ruler.width,
    state_y(states),
    paint,
  )
}

///|
fn draw_timing_clock(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  let paint = timing_appearance(drawing.style, "clock").paint()
  let high = panel.wave_y + TIMING_MARGIN_Y
  let low = panel.wave_y + panel.wave_height - TIMING_MARGIN_Y
  let period = timing_number(player.period.unwrap_or("0"), 0.0)
  guard period > 0.0 else { return }
  let pulse = timing_number(player.pulse.unwrap_or("0"), 0.0)
  let pulse = if pulse == 0.0 { period / 2.0 } else { pulse }
  let offset = timing_number(player.offset.unwrap_or("0"), 0.0)
  let x_of = time => layout.wave_x + layout.ruler.position(time)
  let end = layout.wave_x + layout.ruler.width
  let mut time = offset
  if offset != 0.0 {
    drawing.line(x_of(0.0), low, x_of(offset).min(end), low, paint)
  }
  guard x_of(time) <= end else { return }
  drawing.line(x_of(time), high, x_of(time), low, paint)
  for _ in 0..<TIMING_MAX_TICKS {
    drawing.line(x_of(time), high, x_of(time + pulse).min(end), high, paint)
    time += pulse
    guard x_of(time) <= end else { break }
    drawing.line(x_of(time), high, x_of(time), low, paint)
    drawing.line(
      x_of(time),
      low,
      x_of(time + period - pulse).min(end),
      low,
      paint,
    )
    time += period - pulse
    guard x_of(time) <= end else { break }
    drawing.line(x_of(time), high, x_of(time), low, paint)
  }
}

///|
fn draw_timing_robust(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  let appearance = timing_appearance(drawing.style, "robust")
  let paint = appearance.paint()
  let y_of = state => panel.wave_y + panel.state_y(state)
  let available = layout.wave_x - TIMING_MARGIN - TIMING_SIDE
  let labels_x = TIMING_MARGIN +
    TIMING_SIDE +
    available -
    panel.left_width -
    (if available > panel.left_width + TIMING_SIDE { TIMING_SIDE } else { 0.0 })
  for state in panel.states {
    drawing.text(
      state,
      labels_x,
      y_of(state) - timing_text_size(state, appearance).1 / 2.0 + 1.0,
      "robust",
    )
  }
  guard !player.changes.is_empty() else { return }
  if player.initial is Some(initial) {
    let x = layout.wave_x +
      layout.ruler.position(timing_tick(player.changes[0].when.unwrap()))
    let y = y_of(initial.states[0])
    drawing.line(layout.wave_x - TIMING_ROBUST_INITIAL, y, x, y, paint)
    drawing.line(x, y, x, y_of(player.changes[0].states[0]), paint)
  }
  for index, change in player.changes {
    let x = layout.wave_x +
      layout.ruler.position(timing_tick(change.when.unwrap()))
    let next_x = if index + 1 < player.changes.length() {
      layout.wave_x +
      layout.ruler.position(
        timing_tick(player.changes[index + 1].when.unwrap()),
      )
    } else {
      layout.wave_x + layout.ruler.width
    }
    let ys = change.states.map(y_of)
    if change.states[0] != "{hidden}" {
      if ys.length() > 1 {
        let top = ys[0].min(ys[1])
        let bottom = ys[0].max(ys[1])
        drawing.rect(
          x,
          top,
          next_x - x,
          bottom - top,
          timing_wave_paint(appearance, change.color),
        )
        for hatch = x; hatch < next_x; hatch = hatch + TIMING_HATCH_STEP {
          drawing.line(hatch, top, hatch, bottom, paint)
        }
      }
      for y in ys {
        drawing.line(x, y, next_x, y, paint)
      }
    }
    if index > 0 &&
      change.states[0] != "{hidden}" &&
      player.changes[index - 1].states[0] != "{hidden}" {
      let all = [..ys, ..player.changes[index - 1].states.map(y_of)]
      drawing.line(
        x,
        all.fold(init=ys[0], (a, b) => a.min(b)),
        x,
        all.fold(init=ys[0], (a, b) => a.max(b)),
        paint,
      )
    }
    if change.comment is Some(comment) {
      drawing.text(
        comment,
        x + 2.0,
        ys[0] - timing_text_size(comment, appearance).1,
        "robust",
      )
    }
  }
}

///|
priv enum TimingRibbonEnd {
  Both
  OpenStart
  OpenEnd
  OpenBoth
}

///|
fn draw_timing_ribbon(
  drawing : TimingDrawing,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  rectangle : Bool,
  ends : TimingRibbonEnd,
  paint : @graphics.DrawingStyle,
) -> Unit {
  let p = (dx : Double, dy : Double) => {
    ({ x: x + dx, y: y + dy, } : @graphics.Point)
  }
  let start_open = ends is (OpenStart | OpenBoth)
  let end_open = ends is (OpenEnd | OpenBoth)
  let left = if start_open || rectangle { 0.0 } else { TIMING_MARGIN_X }
  let right = if end_open || rectangle {
    width
  } else {
    width - TIMING_MARGIN_X
  }
  let points = [
    p(left, 0.0),
    p(right, 0.0),
    ..if !rectangle && !end_open {
      [p(width, height / 2.0)]
    },
    p(right, height),
    p(left, height),
    ..if !rectangle && !start_open {
      [p(0.0, height / 2.0)]
    },
  ]
  drawing.polygon(points, { ..paint, stroke: paint.fill, })
  drawing.line(x + left, y, x + right, y, paint)
  drawing.line(x + left, y + height, x + right, y + height, paint)
  if !start_open {
    if rectangle {
      drawing.line(x, y, x, y + height, paint)
    } else {
      drawing.polygon(
        [p(left, 0.0), p(0.0, height / 2.0), p(left, height)],
        { ..paint, fill: None, },
        closed=false,
      )
    }
  }
  if !end_open {
    if rectangle {
      drawing.line(x + width, y, x + width, y + height, paint)
    } else {
      drawing.polygon(
        [p(right, 0.0), p(width, height / 2.0), p(right, height)],
        { ..paint, fill: None, },
        closed=false,
      )
    }
  }
}

///|
fn draw_timing_concise(
  drawing : TimingDrawing,
  layout : TimingLayout,
  panel : TimingPlayerLayout,
  player : @flow.TimingPlayer,
) -> Unit {
  let role = timing_kind(player.kind)
  let appearance = timing_appearance(drawing.style, role)
  let y = panel.wave_y
  let height = panel.wave_height
  let rectangle = player.kind is @flow.PlayerKind::Rectangle
  if player.initial is Some(initial) {
    let x = layout.wave_x - panel.left_width
    let end = player.changes
      .get(0)
      .map_or(layout.wave_x + layout.ruler.width, change => {
        layout.wave_x + layout.ruler.position(timing_tick(change.when.unwrap()))
      })
    let paint = timing_wave_paint(appearance, initial.color)
    if initial.states[0] == "{-}" {
      drawing.line(x, y + height / 2.0, end, y + height / 2.0, paint)
    } else {
      draw_timing_ribbon(
        drawing,
        x,
        y,
        end - x,
        height,
        rectangle,
        if player.changes.is_empty() {
          OpenBoth
        } else {
          OpenStart
        },
        paint,
      )
      drawing.text(
        initial.states[0],
        layout.wave_x - TIMING_MARGIN_X,
        y + (height - timing_text_size(initial.states[0], appearance).1) / 2.0,
        role,
        anchor=End,
      )
    }
  }
  for index, change in player.changes {
    let x = layout.wave_x +
      layout.ruler.position(timing_tick(change.when.unwrap()))
    let last = index + 1 == player.changes.length()
    let end = if last {
      layout.wave_x + layout.ruler.width
    } else {
      layout.wave_x +
      layout.ruler.position(
        timing_tick(player.changes[index + 1].when.unwrap()),
      )
    }
    let state = change.states[0]
    let paint = timing_wave_paint(appearance, change.color)
    if state == "{-}" {
      drawing.line(x, y + height / 2.0, end, y + height / 2.0, paint)
    } else if state != "{hidden}" {
      draw_timing_ribbon(
        drawing,
        x,
        y,
        end - x,
        height,
        rectangle,
        if last {
          OpenEnd
        } else {
          Both
        },
        paint,
      )
      if state != "{...}" {
        drawing.text(
          state,
          if last {
            x + TIMING_MARGIN_X
          } else {
            (x + end) / 2.0
          },
          y + (height - timing_text_size(state, appearance).1) / 2.0,
          role,
          anchor=if last { Start } else { Middle },
        )
      }
    }
    if change.comment is Some(comment) {
      drawing.text(
        comment,
        x + TIMING_MARGIN_X,
        y - timing_text_size(comment, appearance).1,
        role,
      )
    }
  }
}
