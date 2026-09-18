///|
/// FtileWithNoteOpale.suppSpace.
const NOTE_GAP : Int = 20

///|
/// FtileWithNotes wraps each note in TextBlockUtils.withMargin(opale, 10, 10).
const NOTE_STACK_MARGIN : Int = 10

///|
fn attach_activity_note(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
  note : Int,
) -> Unit {
  for index = tiles.length() - 1; index >= 0; index = index - 1 {
    match tiles[index] {
      FlowAnchor(_) | GotoAnchor(_) | Swimlane => continue
      Leaf(index) if nodes[index]
        is (@flow.ActivityNode::Arrow(_) | @flow.ActivityNode::Kill) => continue
      Noted(_, notes) => notes.push(note)
      body => {
        let child = note_instruction_body(body)
        if child is Some(child) &&
          child.any(tile => {
            !(tile is FlowAnchor(_)) && !tile_is_flow_decoration(tile, nodes)
          }) {
          attach_activity_note(child, nodes, note)
        } else {
          tiles[index] = Noted(body, [note])
        }
      }
    }
    return
  }
  tiles.push(Leaf(note))
}

///|
/// These instructions delegate notes to their current body's last instruction.
/// Closed if/fork instructions instead retain notes on the whole structure.
fn note_instruction_body(tile : Tile) -> Array[Tile]? {
  match tile {
    WhileLoop(_, body, _, _, _)
    | RepeatLoop(_, body, _, _, _)
    | Partition(_, body, _) => Some(body)
    Switch(_, branches, _) => branches.last().map(branch => branch.tiles)
    _ => None
  }
}

///|
/// Column widths include the clearance between the notes and the body.
fn measure_note_columns(
  notes : Array[Int],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (TileMeasure, TileMeasure) {
  let margin = if notes.length() > 1 { NOTE_STACK_MARGIN } else { 0 }
  let mut left : TileMeasure = { width: 0, height: 0, }
  let mut right : TileMeasure = { width: 0, height: 0, }
  for index in notes {
    let size = nodes[index].size(metrics, small_metrics)
    let is_left = nodes[index] is @flow.ActivityNode::Note(_, Left)
    let column = if is_left { left } else { right }
    let column : TileMeasure = {
      width: column.width.max(
        size.width + (if margin > 0 { margin * 2 } else { NOTE_GAP }),
      ),
      height: column.height + size.height + margin * 2,
    }
    if is_left {
      left = column
    } else {
      right = column
    }
  }
  (left, right)
}

///|
fn tile_axis(
  tile : Tile,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  match tile {
    Noted(body, notes) => {
      let (left, _) = measure_note_columns(notes, nodes, metrics, small_metrics)
      left.width + tile_axis(body, nodes, metrics, small_metrics)
    }
    Partition(_, body, _) => {
      let size = measure_tile(tile, nodes, metrics, small_metrics)
      let body_size = measure_sequence(body, nodes, metrics, small_metrics)
      (size.width - body_size.width) / 2 +
      sequence_axis(body, nodes, metrics, small_metrics)
    }
    IfChain(branches, _) if if_vertical_body_index(branches, nodes) is Some(_) => {
      let (_, axis) = if_vertical_columns(
        branches, nodes, metrics, small_metrics,
      )
      axis
    }
    IfChain(branches, _) if is_if_down(branches) => {
      let (_, axis, _, _) = if_columns(branches, nodes, metrics, small_metrics)
      axis
    }
    WhileLoop(entry, body, exit, enter_label, exit_label) => {
      let (_, axis) = while_columns(
        entry, body, exit, exit_label, enter_label, nodes, metrics, small_metrics,
      )
      axis
    }
    RepeatLoop(entry, body, exit, retry_label, exit_label) => {
      let (_, axis) = repeat_columns(
        entry, body, exit, retry_label, exit_label, nodes, metrics, small_metrics,
      )
      axis
    }
    Switch(entry, branches, exit) => {
      let (_, axis, _, _) = switch_columns(
        entry, branches, exit, nodes, metrics, small_metrics,
      )
      axis
    }
    _ => measure_tile(tile, nodes, metrics, small_metrics).width / 2
  }
}

///|
fn sequence_axis(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut axis = 0
  for tile in tiles {
    let size = measure_tile(tile, nodes, metrics, small_metrics)
    guard size.height > 0 else { continue }
    axis = axis.max(tile_axis(tile, nodes, metrics, small_metrics))
  }
  axis
}

///|
fn place_noted(
  body : Tile,
  notes : Array[Int],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let body_size = measure_tile(body, nodes, metrics, small_metrics)
  let (left, right) = measure_note_columns(notes, nodes, metrics, small_metrics)
  let height = body_size.height.max(left.height).max(right.height)
  let placed = place_tile(
    body,
    nodes,
    metrics,
    small_metrics,
    x + left.width,
    y + (height - body_size.height) / 2,
    layouts,
    edges,
  )
  let margin = if notes.length() > 1 { NOTE_STACK_MARGIN } else { 0 }
  let mut left_y = y + (height - left.height) / 2 + margin
  let mut right_y = y + (height - right.height) / 2 + margin
  for index in notes {
    let size = nodes[index].size(metrics, small_metrics)
    let is_left = nodes[index] is @flow.ActivityNode::Note(_, Left)
    let note_x = if margin > 0 {
      let column_x = if is_left { x } else { x + left.width + body_size.width }
      let column_width = if is_left { left.width } else { right.width }
      column_x + (column_width - size.width) / 2
    } else if is_left {
      x + (left.width - NOTE_GAP - size.width) / 2
    } else {
      x +
      left.width +
      body_size.width +
      NOTE_GAP +
      (right.width - NOTE_GAP - size.width) / 2
    }
    layouts.push({
      node_index: index,
      x: note_x,
      y: if is_left {
        left_y
      } else {
        right_y
      },
      width: size.width,
      height: size.height,
    })
    if is_left {
      left_y += size.height + margin * 2
    } else {
      right_y += size.height + margin * 2
    }
  }
  placed
}
