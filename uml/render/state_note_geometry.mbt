///|
/// EntityImageNote / Opale text margins and folded corner.
const STATE_NOTE_LEFT_MARGIN : Double = 6.0

///|
const STATE_NOTE_RIGHT_MARGIN : Double = 15.0

///|
const STATE_NOTE_VERTICAL_MARGIN : Double = 5.0

///|
const STATE_NOTE_CORNER : Double = 10.0

///|
/// Rose creates ComponentRoseNote with padding outside its visible outline.
const STATE_LINK_NOTE_PADDING : Double = 5.0

///|
/// Entity notes use SkinParam's digit-only corner setting. Link notes use
/// the style's ValueImpl.asInt, which extracts digits from annotated values.
/// Verified 2026-09-16: integer, unit-annotated, signed, and invalid inputs
/// follow these two accessors. Temporary property tests removed after passing.
fn state_note_round_corner(
  note : @flow.StateNote,
  style : @style.DocumentStyle,
) -> Double {
  guard style.property("RoundCorner") is Some(value) else { return 0.0 }
  if !(note.target is TransitionNote(_)) {
    guard !value.is_empty() && value.iter().all(char => char.is_ascii_digit()) else {
      return 0.0
    }
    return state_style_dimension(value, 0.0)
  }
  let digits = StringBuilder()
  for char in value.iter() {
    if char.is_ascii_digit() {
      digits.write_char(char)
    }
  }
  state_style_dimension(digits.to_string(), 0.0)
}

///|
/// Verified 2026-09-16: note thickness changes outline/fold strokes without
/// altering geometry; inline line flags do not override the note style stroke.
fn state_note_border_thickness(style : @style.DocumentStyle) -> Double {
  style
  .property("NoteBorderThickness")
  .map_or(STATE_THIN_STROKE_WIDTH, value => {
    state_style_dimension(value, STATE_THIN_STROKE_WIDTH)
  })
}

///|
/// CommandFactoryNoteOnEntity applies Position.withRankdir before creating
/// its DOT link; user-facing note directions remain screen directions.
fn @flow.StateNotePosition::with_rankdir(
  self : @flow.StateNotePosition,
  style : @style.DocumentStyle,
) -> @flow.StateNotePosition {
  guard style.layout_direction is Some(LeftToRight) else { return self }
  match self {
    NoteLeft => NoteTop
    NoteRight => NoteBottom
    NoteTop => NoteLeft
    NoteBottom => NoteRight
  }
}

///|
priv struct StateTransitionLabelGeometry {
  width : Double
  height : Double
  text_center : (Double, Double)?
  note : StateNoteLayout?
}

///|
/// Previously verified: empty notes reserve margins only, multiple blank
/// lines retain height, and shared indentation preserves geometry.
fn state_note_size(
  note : @flow.StateNote,
  metrics : @metrics.FontMetrics,
  style : @style.DocumentStyle,
) -> (Double, Double) {
  // EntityImageNote and AbstractTextualComponent use TextBlockEmpty for a
  // single empty line. Multiple blank lines still have normal line geometry.
  let (width, height) = if note.text.is_empty() {
    (0.0, 0.0)
  } else {
    state_text_size(
      note.text,
      metrics,
      literal_newlines=note.text_mode == @flow.BlockText,
      wrap_width=state_wrap_width(style),
      monospaced_family=state_monospaced_family(style),
    )
  }
  (
    width + state_note_left_margin(note, style) + STATE_NOTE_RIGHT_MARGIN,
    height + STATE_NOTE_VERTICAL_MARGIN * 2.0,
  )
}

///|
/// ComponentRoseNote reserves symmetrical margins for centered link notes.
/// EntityImageNote keeps its asymmetric margins for every text alignment.
fn state_note_left_margin(
  note : @flow.StateNote,
  style : @style.DocumentStyle,
) -> Double {
  if note.target is TransitionNote(_) &&
    state_skinparam_alignment(style, "NoteTextAlignment", Start) == Middle {
    STATE_NOTE_RIGHT_MARGIN
  } else {
    STATE_NOTE_LEFT_MARGIN
  }
}

///|
fn state_note_text_alignment(
  style : @style.DocumentStyle,
) -> @graphics.TextAnchor {
  style
  .property("statenotestylealignment")
  .unwrap_or_else(() => {
    style
    .property("NoteTextAlignment")
    .unwrap_or_else(() => {
      style.property("DefaultTextAlignment").unwrap_or("left")
    })
  })
  |> parse_state_text_alignment
  |> Option::unwrap_or(Start)
}

///|
/// ComponentRoseNote's right position uses area width minus padded text
/// width, which is the two outer paddings in EntityImageNoteLink's own area.
fn state_note_text_x(
  note : @flow.StateNote,
  layout : StateNoteLayout,
  style : @style.DocumentStyle,
) -> Double {
  let margin = if note.target is TransitionNote(_) &&
    state_skinparam_alignment(style, "NoteTextAlignment", Start) == End {
    2.0 * STATE_LINK_NOTE_PADDING + state_note_shadow(style)
  } else {
    state_note_left_margin(note, style)
  }
  layout.x + margin
}

///|
/// Link.addNote replaces the previous note on the same transition.
fn @flow.StateDiagram::transition_note(
  self : @flow.StateDiagram,
  transition_index : Int,
) -> (Int, @flow.StateNote)? {
  let mut found = None
  for index, note in self.notes {
    if note.target == @flow.StateNoteTarget::TransitionNote(transition_index) {
      found = Some((index, note))
    }
  }
  found
}

///|
/// SvekEdge merges the text and ComponentRoseNote before requesting a single
/// measured DOT label. Coordinates here are relative to that combined box.
/// Verified before Graphviz 0.1.10: note/message alignment preserves attachment
/// and label boxes in both rank directions; link notes use the final note and
/// retain role-specific margins and source-order style precedence.
fn @flow.StateDiagram::transition_label_geometry(
  self : @flow.StateDiagram,
  transition_index : Int,
) -> StateTransitionLabelGeometry {
  let transition = self.transitions[transition_index]
  let metrics = resolve_state_font(self.style, TransitionLabel).metrics
  let (text_width, text_height) = transition.label.map_or((0.0, 0.0), text => {
    state_text_size(
      text,
      metrics,
      wrap_width=state_transition_wrap_width(self.style),
      monospaced_family=state_monospaced_family(self.style),
    )
  })
  guard self.transition_note(transition_index) is Some((note_index, note)) else {
    return {
      width: text_width,
      height: text_height,
      text_center: transition.label.map(_ => {
        (text_width / 2.0, text_height / 2.0)
      }),
      note: None,
    }
  }
  let (body_width, body_height) = state_note_size(
    note,
    resolve_state_font(self.style, NoteLabel).metrics,
    self.style,
  )
  let shadow = state_note_shadow(self.style)
  let note_width = body_width + STATE_LINK_NOTE_PADDING * 2.0 + shadow
  let note_height = body_height + STATE_LINK_NOTE_PADDING * 2.0 + shadow
  let position = note.position.unwrap_or(@flow.StateNotePosition::NoteBottom)
  let (width, height, text_x, text_y, note_x, note_y) = match position {
    NoteLeft =>
      (
        note_width + text_width,
        note_height.max(text_height),
        note_width + text_width / 2.0,
        note_height.max(text_height) / 2.0,
        0.0,
        (text_height - note_height).max(0.0) / 2.0,
      )
    NoteRight =>
      (
        note_width + text_width,
        note_height.max(text_height),
        text_width / 2.0,
        note_height.max(text_height) / 2.0,
        text_width,
        (text_height - note_height).max(0.0) / 2.0,
      )
    NoteTop =>
      (
        note_width.max(text_width),
        note_height + text_height,
        note_width.max(text_width) / 2.0,
        note_height + text_height / 2.0,
        (text_width - note_width).max(0.0) / 2.0,
        0.0,
      )
    NoteBottom =>
      (
        note_width.max(text_width),
        note_height + text_height,
        note_width.max(text_width) / 2.0,
        text_height / 2.0,
        (text_width - note_width).max(0.0) / 2.0,
        text_height,
      )
  }
  {
    width,
    height,
    text_center: transition.label.map(_ => (text_x, text_y)),
    note: Some({
      note_index,
      x: note_x + STATE_LINK_NOTE_PADDING,
      y: note_y + STATE_LINK_NOTE_PADDING,
      width: body_width,
      height: body_height,
    }),
  }
}
