///|
/// The measured geometry shared by the constraint pass and SVG renderer.
priv struct NoteComponent {
  width : Int
  height : Int
  text_x : Int
  text_y : Int
  fold : Int
}

///|
priv struct NoteGeometry {
  x : Int
  y : Int
  component : NoteComponent
}

///|
fn Note::component(self : Note) -> NoteComponent {
  let text = TextSize::of(self.text)
  match self.note_style {
    NodeNormal =>
      {
        // PlantUML's Rose note has 10px horizontal and 5px vertical padding.
        // Its folded corner is part of the component, not extra outer margin.
        width: (text.width + 20).max(56),
        height: text.height + 10,
        text_x: 6,
        text_y: 18,
        fold: 10,
      }
    Hexagonal =>
      {
        width: (text.width + 26).max(56),
        height: text.height + 8,
        text_x: 12,
        text_y: 17,
        fold: 10,
      }
    Box =>
      {
        width: (text.width + 8).max(56),
        height: text.height + 8,
        text_x: 4,
        text_y: 17,
        fold: 0,
      }
  }
}

///|
fn DiagramLayout::participant_segment(
  self : DiagramLayout,
  participant_code : String,
  y : Int,
) -> (Int, Int) {
  let center = self
    .participant_at(participant_code)
    .map_or(self.width / 2, participant => participant.center_x)
  let mut left = center
  let mut right = center
  match self.participant_at(participant_code) {
    Some(participant) if participant.birth_y is Some(birth_y) && birth_y <= y => {
      left = center - 5
      right = center + 5
    }
    _ => ()
  }
  for activation in self.activations {
    if activation.participant_code == participant_code &&
      activation.start_y <= y &&
      y <= activation.end_y {
      let activation_left = center - 5 + activation.depth * 8
      left = left.min(activation_left)
      right = right.max(activation_left + 10)
    }
  }
  (left, right)
}

///|
fn DiagramLayout::note_geometry(
  self : DiagramLayout,
  note : Note,
  placement : EventPlacement,
  arrow_anchor : Message?,
) -> NoteGeometry {
  let component = note.component()
  let center = self.note_anchor_center(note, arrow_anchor)
  let x = if note.on_arrow {
    match note.position {
      Left => center - component.width
      Right => center
      Bottom | Top | Over | OverSeveral => center - component.width / 2
      Across => 24
    }
  } else {
    match note.position {
      Left =>
        match note.participant_codes.get(0) {
          Some(code) =>
            self.participant_segment(code, placement.y).0 - component.width
          None => center - component.width
        }
      Right =>
        match note.participant_codes.get(0) {
          Some(code) => self.participant_segment(code, placement.y).1
          None => center
        }
      Bottom | Top | Over => center - component.width / 2
      OverSeveral =>
        match (note.participant_codes.get(0), note.participant_codes.last()) {
          (Some(first), Some(last)) => {
            let start = self
              .participant_at(first)
              .map_or(center, p => p.center_x)
            let end = self.participant_at(last).map_or(center, p => p.center_x)
            (start + end) / 2 - component.width / 2
          }
          _ => center - component.width / 2
        }
      Across => 24
    }
  }
  let component = if note.position is Across {
    { ..component, width: self.width - 48 }
  } else {
    component
  }
  { x, y: placement.y, component }
}
