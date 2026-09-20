///|
/// One player's frame, left panel, and waveform allocation.
pub(all) struct TimingPlayerLayout {
  index : Int
  frame_y : Double
  panel_y : Double
  height : Double
  left_width : Double
  wave_y : Double
  wave_height : Double
  constraint_height : Double
  top_notes : Double
  bottom_notes : Double
  states : Array[String]
  minimum : Double
  maximum : Double
  ticks : Array[Double]
}

///|
/// TimingDiagram's shared ruler and vertically stacked player panels.
pub(all) struct TimingLayout {
  ruler : TimingRulerLayout
  players : Array[TimingPlayerLayout]
  wave_x : Double
  inner_height : Double
  width : Double
  height : Double
  messages : Array[TimingMessageLayout]
}

///|
fn timing_text_size(
  text : String,
  appearance : TimingAppearance,
) -> (Double, Double) {
  guard !text.is_empty() else { return (0.0, 0.0) }
  state_text_size(text, appearance.metrics)
}

///|
fn timing_states(player : @flow.TimingPlayer) -> Array[String] {
  let states = player.states.map(state => state.1).rev()
  if player.initial is Some(initial) && !states.contains(initial.states[0]) {
    states.push(initial.states[0])
  }
  for change in player.changes {
    guard change.states[0] != "{hidden}" else { continue }
    for state in change.states {
      if !states.contains(state) {
        states.push(state)
      }
    }
  }
  states
}

///|
fn TimingPlayerLayout::state_y(
  self : TimingPlayerLayout,
  state : String,
) -> Double {
  for index, candidate in self.states {
    guard candidate == state else { continue }
    return (self.states.length() - 1 - index).to_double() * self.wave_height
  }
  self.states.length().to_double() * self.wave_height
}

///|
fn timing_state_at(player : @flow.TimingPlayer, time : Double) -> String? {
  let mut state = player.initial.map(change => change.states[0])
  for change in player.changes {
    guard timing_tick(change.when.unwrap()) <= time else { break }
    state = Some(change.states[0])
  }
  state
}

///|
fn timing_constraint_delta(
  player : @flow.TimingPlayer,
  panel : TimingPlayerLayout,
  constraint : @flow.TimeConstraint,
) -> Double {
  guard player.kind is @flow.PlayerKind::Robust else { return 0.0 }
  let start = timing_tick(constraint.tick1)
  let end = timing_tick(constraint.tick2)
  let first = timing_state_at(player, start).map_or_else(
    () => player.changes.get(0).map_or("", change => change.states[0]),
    value => value,
  )
  player.changes.fold(init=panel.state_y(first), (y, change) => {
    let time = timing_tick(change.when.unwrap())
    if time > start && time < end {
      y.min(panel.state_y(change.states[0]))
    } else {
      y
    }
  })
}

///|
fn timing_note_size(
  note : @flow.TimingNote,
  style : @style.DocumentStyle,
) -> (Double, Double) {
  let text = timing_text_size(note.text, timing_appearance(style, "note"))
  (
    text.0 + STATE_NOTE_LEFT_MARGIN + STATE_NOTE_RIGHT_MARGIN,
    text.1 + STATE_NOTE_VERTICAL_MARGIN * 2.0,
  )
}

///|
fn timing_player_layout(
  diagram : @flow.TimingDiagram,
  index : Int,
  y : Double,
) -> TimingPlayerLayout {
  let player = diagram.players[index]
  let appearance = timing_appearance(diagram.style, timing_kind(player.kind))
  let states = timing_states(player)
  let suggested = player.height.unwrap_or(0).to_double()
  let wave_height = match player.kind {
    Robust =>
      if suggested > 0.0 && states.length() > 1 {
        suggested / (states.length() - 1).to_double()
      } else {
        TIMING_ROBUST_STEP
      }
    Concise | Rectangle =>
      if suggested > 0.0 {
        suggested
      } else {
        TIMING_RIBBON_HEIGHT
      }
    Binary | Clock =>
      if suggested > 0.0 {
        suggested
      } else {
        TIMING_BINARY_HEIGHT
      }
    Analog => if suggested > 0.0 { suggested } else { TIMING_ANALOG_HEIGHT }
  }
  let frame_height = timing_text_size(
      player.title,
      timing_appearance(diagram.style, "title"),
    ).1 +
    (if player.compact { -1.0 } else { 1.0 })
  let minimum = player.bounds.map_or_else(
    () => {
      player.changes.fold(init=0.0, (value, change) => {
        value.min(timing_number(change.states[0], 0.0))
      })
    },
    bounds => timing_number(bounds.0, 0.0),
  )
  let maximum = player.bounds.map_or_else(
    () => {
      let value = player.changes.fold(init=0.0, (value, change) => {
        value.max(timing_number(change.states[0], 0.0))
      })
      if value == 0.0 {
        10.0
      } else {
        value
      }
    },
    bounds => timing_number(bounds.1, 10.0),
  )
  let ticks = []
  if player.kind is @flow.PlayerKind::Analog {
    if player.ticks_every is Some(step) && step > 0 {
      for value = minimum.ceil().to_int()
          value <= maximum.floor().to_int()
          value = value + 1 {
        if value % step == 0 {
          ticks.push(value.to_double())
        }
      }
    } else {
      ticks.push(minimum)
      ticks.push(maximum)
    }
  }
  let left_width = match player.kind {
    Robust =>
      states.fold(init=0.0, (width, state) => {
        width.max(timing_text_size(state, appearance).0)
      }) +
      (if player.initial is Some(_) { TIMING_ROBUST_INITIAL } else { 0.0 })
    Concise | Rectangle =>
      player.initial.map_or(0.0, change => {
        timing_text_size(change.states[0], appearance).0 + TIMING_MARGIN_X * 2.0
      })
    Analog =>
      TIMING_SIDE +
      ticks.fold(init=0.0, (width, tick) => {
        width.max(
          timing_text_size(timing_analog_label(player, tick), appearance).0,
        )
      })
    Binary | Clock => TIMING_SIDE
  }
  let panel : TimingPlayerLayout = {
    index,
    frame_y: y,
    panel_y: y + frame_height,
    height: 0.0,
    left_width,
    wave_y: y + frame_height,
    wave_height,
    constraint_height: 0.0,
    top_notes: 0.0,
    bottom_notes: 0.0,
    states,
    minimum,
    maximum,
    ticks,
  }
  let constraint_height = player.constraints.fold(init=0.0, (height, constraint) => {
    height.max(
      timing_text_size(
        constraint.message.unwrap_or(""),
        timing_appearance(diagram.style, "constraintArrow"),
      ).1 +
      TIMING_CONSTRAINT_MARGIN -
      timing_constraint_delta(player, panel, constraint),
    )
  })
  let constraint_height = match player.kind {
    Robust => constraint_height.max(TIMING_MARGIN)
    Concise | Rectangle => constraint_height.max(TIMING_SIDE)
    Clock => 0.0
    _ => constraint_height
  }
  let notes_height = (position : String) => {
    guard player.kind
      is (@flow.PlayerKind::Concise
      | @flow.PlayerKind::Rectangle
      | @flow.PlayerKind::Binary) else {
      return 0.0
    }
    player.notes.fold(init=0.0, (height, note) => {
      if note.position == position {
        height.max(timing_note_size(note, diagram.style).1 + TIMING_NOTE_MARGIN)
      } else {
        height
      }
    })
  }
  let top_notes = notes_height("top")
  let bottom_notes = notes_height("bottom")
  let comment_height = if player.kind
    is (@flow.PlayerKind::Concise | @flow.PlayerKind::Rectangle) {
    player.changes.fold(init=0.0, (height, change) => {
      height.max(timing_text_size(change.comment.unwrap_or(""), appearance).1)
    })
  } else {
    0.0
  }
  let content = match player.kind {
    Robust =>
      wave_height * (states.length() - 1).max(0).to_double() +
      TIMING_ROBUST_BOTTOM
    Concise | Rectangle => wave_height + TIMING_BOTTOM
    _ => wave_height
  }
  {
    ..panel,
    wave_y: panel.panel_y + constraint_height + top_notes + comment_height,
    constraint_height,
    top_notes,
    bottom_notes,
    height: frame_height +
    constraint_height +
    top_notes +
    comment_height +
    content +
    bottom_notes,
  }
}

///|
fn timing_analog_label(player : @flow.TimingPlayer, value : Double) -> String {
  // Explicit bounds supply the decimal precision, as TimeSeries/DeduceFormat.
  let precision = player.bounds.map_or(1, bounds => {
    [bounds.0, bounds.1].fold(init=0, (digits, bound) => {
      bound
      .find(".")
      .map_or(digits, dot => digits.max(bound.length() - dot - 1))
    })
  })
  let factor = @math.pow(10.0, precision.to_double())
  let rounded = (value * factor).round() / factor
  let text = rounded.to_string()
  if precision == 0 {
    rounded.to_int64().to_string()
  } else {
    text
  }
}

///|
/// Allocate TimingRuler and each player's distinct Panels geometry.
pub fn layout_timing(diagram : @flow.TimingDiagram) -> TimingLayout {
  let ruler = timing_ruler(diagram)
  let players = []
  let mut y = TIMING_MARGIN
  let mut left = 0.0
  for index in 0..<diagram.players.length() {
    let panel = timing_player_layout(diagram, index, y)
    y += panel.height
    left = left.max(panel.left_width)
    players.push(panel)
  }
  let layout = {
    ruler,
    players,
    wave_x: TIMING_MARGIN + TIMING_SIDE + left,
    inner_height: y - TIMING_MARGIN,
    width: left + ruler.width + TIMING_SIDE * 2.0 + TIMING_MARGIN * 2.0,
    height: y +
    timing_text_size("0", timing_appearance(diagram.style, "timeline")).1 +
    TIMING_MARGIN,
    messages: [],
  }
  { ..layout, messages: timing_messages(diagram, layout), }
}
