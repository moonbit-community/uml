///|
/// Rendering retains the note's routed contacts without changing StateLayout.
priv struct StateDrawingLayout {
  layout : StateLayout
  note_connections : Array[StateNoteConnection]
  cluster_titles : Map[String, Double]
  document : Array[DocumentTextBlock]
}

///|
priv struct StateNoteConnection {
  note_index : Int
  note_contact : (Double, Double)
  state_contact : (Double, Double)
}

///|
fn StateNoteConnection::shift(
  self : StateNoteConnection,
  dx : Double,
  dy : Double,
) -> StateNoteConnection {
  {
    ..self,
    note_contact: (self.note_contact.0 + dx, self.note_contact.1 + dy),
    state_contact: (self.state_contact.0 + dx, self.state_contact.1 + dy),
  }
}

///|
/// EntityImageNote orients the routed path by proximity to the note center,
/// then uses both contacts for the Opale pointer, independent of edge direction.
fn state_note_connection(
  edge : @graphviz.GraphvizEdge,
  note : StateNoteLayout,
) -> StateNoteConnection? {
  guard relation_edge_endpoint(edge, true) is Some(start) &&
    relation_edge_endpoint(edge, false) is Some(end) else {
    return None
  }
  let center = (note.x + note.width / 2.0, note.y + note.height / 2.0)
  let forward = relation_point_distance_squared(start, center) <=
    relation_point_distance_squared(end, center)
  Some({
    note_index: note.note_index,
    note_contact: if forward {
      start
    } else {
      end
    },
    state_contact: if forward {
      end
    } else {
      start
    },
  })
}

///|
/// EntityImageNote.getOpaleStrategy chooses the closest side in this tie order.
fn StateNoteConnection::side(
  self : StateNoteConnection,
  note : StateNoteLayout,
) -> @flow.StateNotePosition {
  let left = (self.note_contact.0 - note.x).abs()
  let right = (self.note_contact.0 - note.x - note.width).abs()
  let top = (self.note_contact.1 - note.y).abs()
  let bottom = (self.note_contact.1 - note.y - note.height).abs()
  if left <= right && left <= top && left <= bottom {
    NoteLeft
  } else if right <= left && right <= top && right <= bottom {
    NoteRight
  } else if top <= left && top <= right && top <= bottom {
    NoteTop
  } else {
    NoteBottom
  }
}

///|
/// Opale.delta controls the pointer's base; the other vertex is the actual
/// Graphviz contact on the target, not a guessed center or side midpoint.
const STATE_NOTE_POINTER_HALF_BASE : Double = 4.0

///|
/// Opale rounds the three outer corners with half the requested diameter.
/// Verified 2026-09-16: all four pointer directions retain their routed target
/// contact and the same contour arcs. Entity/link notes in TB/LR graphs retain
/// layout, note contacts, and text placement. Temporary property tests removed.
fn state_note_outline(
  note : StateNoteLayout,
  connection : StateNoteConnection?,
  round_corner? : Double = 0.0,
) -> Array[@graphics.PathSegment] {
  let left = note.x
  let right = note.x + note.width
  let top = note.y
  let bottom = note.y + note.height
  let radius = round_corner / 2.0
  let arc = (end : @graphics.Point) => {
    @graphics.PathSegment::ArcTo(
      rx=radius,
      ry=radius,
      rotation=0.0,
      large_arc=false,
      sweep=false,
      end~,
    )
  }
  let side = connection.map(connection => connection.side(note))
  let output : Array[@graphics.PathSegment] = [
    MoveTo({ x: left, y: top + radius, }),
  ]
  if side == Some(@flow.StateNotePosition::NoteLeft) &&
    connection is Some(connection) {
    let y = (connection.note_contact.1 - STATE_NOTE_POINTER_HALF_BASE)
      .max(top)
      .min(bottom - STATE_NOTE_POINTER_HALF_BASE * 2.0)
    output.append([
      LineTo({ x: left, y, }),
      LineTo({ x: connection.state_contact.0, y: connection.state_contact.1, }),
      LineTo({ x: left, y: y + STATE_NOTE_POINTER_HALF_BASE * 2.0, }),
    ])
  }
  output.push(LineTo({ x: left, y: bottom - radius, }))
  if radius > 0.0 {
    output.push(arc({ x: left + radius, y: bottom, }))
  }
  if side == Some(@flow.StateNotePosition::NoteBottom) &&
    connection is Some(connection) {
    let x = (connection.note_contact.0 - STATE_NOTE_POINTER_HALF_BASE)
      .max(left)
      .min(right)
    output.append([
      LineTo({ x, y: bottom, }),
      LineTo({ x: connection.state_contact.0, y: connection.state_contact.1, }),
      LineTo({ x: x + STATE_NOTE_POINTER_HALF_BASE * 2.0, y: bottom, }),
    ])
  }
  output.push(LineTo({ x: right - radius, y: bottom, }))
  if radius > 0.0 {
    output.push(arc({ x: right, y: bottom - radius, }))
  }
  if side == Some(@flow.StateNotePosition::NoteRight) &&
    connection is Some(connection) {
    let y = (connection.note_contact.1 - STATE_NOTE_POINTER_HALF_BASE)
      .max(top + STATE_NOTE_CORNER)
      .min(bottom - STATE_NOTE_POINTER_HALF_BASE * 2.0)
    output.append([
      LineTo({ x: right, y: y + STATE_NOTE_POINTER_HALF_BASE * 2.0, }),
      LineTo({ x: connection.state_contact.0, y: connection.state_contact.1, }),
      LineTo({ x: right, y, }),
    ])
  }
  output.append([
    LineTo({ x: right, y: top + STATE_NOTE_CORNER, }),
    LineTo({ x: right - STATE_NOTE_CORNER, y: top, }),
  ])
  if side == Some(@flow.StateNotePosition::NoteTop) &&
    connection is Some(connection) {
    let x = (connection.note_contact.0 - STATE_NOTE_POINTER_HALF_BASE)
      .max(left)
      .min(right - STATE_NOTE_CORNER)
    output.append([
      LineTo({ x: x + STATE_NOTE_POINTER_HALF_BASE * 2.0, y: top, }),
      LineTo({ x: connection.state_contact.0, y: connection.state_contact.1, }),
      LineTo({ x, y: top, }),
    ])
  }
  if radius > 0.0 {
    output.push(LineTo({ x: left + radius, y: top, }))
    output.push(arc({ x: left, y: top + radius, }))
  }
  output.push(Close)
  output
}

///|
/// Opale.getCorner rounds the fold with a quarter of the corner diameter;
/// the outer contour uses half. The fold remains a separate closed path.
/// Verified 2026-09-16: fold/contour radius ratio, arc direction, closure,
/// and zero-corner paths passed alongside state_note_outline's integration cases.
fn state_note_fold(
  note : StateNoteLayout,
  round_corner : Double,
) -> Array[@graphics.PathSegment] {
  let x = note.x + note.width - STATE_NOTE_CORNER
  let y = note.y + STATE_NOTE_CORNER
  let radius = round_corner / 4.0
  let path : Array[@graphics.PathSegment] = [
    MoveTo({ x, y: note.y, }),
    LineTo({ x, y: y - radius, }),
  ]
  if radius > 0.0 {
    path.push(
      ArcTo(rx=radius, ry=radius, rotation=0.0, large_arc=false, sweep=false, end={
        x: x + radius,
        y,
      }),
    )
  }
  path.push(LineTo({ x: note.x + note.width, y, }))
  path.push(Close)
  path
}
