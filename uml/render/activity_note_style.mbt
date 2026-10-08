///|
fn activity_note_state(note : @flow.ActivityNote) -> @flow.StateNote {
  {
    text: note.text,
    text_mode: @flow.InlineText,
    target: @flow.StateNote(""),
    parent: None,
    region_index: 0,
    color: note.color,
    position: Some(if note.side is Left { NoteLeft } else { NoteRight }),
  }
}

///|
fn activity_styled_note_size(note : @flow.ActivityNote) -> TileMeasure {
  let style = note.style.with_stereotypes(note.stereotype)
  let (width, height) = state_note_size(
    activity_note_state(note),
    resolve_state_font(style, NoteLabel).metrics,
    style,
  )
  { width, height, }
}

///|
fn @flow.ActivityNode::note_left(self : @flow.ActivityNode) -> Bool {
  match self {
    Note(_, Left) => true
    StyledNote(note) => note.side is Left
    _ => false
  }
}

///|
fn @flow.ActivityNode::is_note(self : @flow.ActivityNode) -> Bool {
  self is (Note(_, _) | StyledNote(_))
}

///|
fn draw_activity_styled_note(
  output : @graphics.Graphic,
  note : @flow.ActivityNote,
  placement : ActivityNodeLayout,
) -> Unit {
  let style = note.style.with_stereotypes(note.stereotype)
  let layout : StateNoteLayout = {
    note_index: placement.node_index,
    x: placement.x,
    y: placement.y,
    width: placement.width,
    height: placement.height,
  }
  let connection = placement.note_pointer_offset.map(offset => {
    let x = if note.side is Left {
      placement.x + placement.width
    } else {
      placement.x
    }
    let y = placement.y + placement.height / 2.0
    StateNoteConnection::{
      note_index: placement.node_index,
      note_contact: (x, y),
      state_contact: (x + offset, y),
    }
  })
  let state_note = activity_note_state(note)
  let paint = state_paint(
    Color(note_background_color(state_note, style)),
    Color(note_border_color(state_note, style)),
    state_note_border_thickness(style),
  )
  output
  .with_style(paint)
  .draw(
    Path(state_note_outline(layout, connection)),
    metadata=activity_class("activity-note"),
  )
  output.with_style(paint).draw(Path(state_note_fold(layout, 0.0)))
  let font = resolve_state_font(style, NoteLabel)
  append_state_text_at_top(
    output.with_style({ ..Default::default(), fill: Color(font.color), }),
    note.text,
    layout.x + STATE_NOTE_LEFT_MARGIN,
    layout.y + STATE_NOTE_VERTICAL_MARGIN,
    "activity-label",
    font.metrics,
    anchor=Start,
    font_family=Some(font.family),
  )
}
