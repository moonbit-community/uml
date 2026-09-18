///|
/// FtileRepeat.getLeft/getRight align both diamonds with the body's flow axis;
/// calculateDimensionInternal reserves the return corridor on the right.
fn repeat_columns(
  entry : Int,
  body : Array[Tile],
  exit : Int,
  retry_label : String?,
  exit_label : String?,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int) {
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let body_size = measure_sequence(body, nodes, metrics, small_metrics)
  let body_axis = sequence_axis(body, nodes, metrics, small_metrics)
  let axis = body_axis.max(entry_size.width / 2).max(exit_size.width / 2)
  let label_width = retry_label.map_or(0, label => {
    small_metrics.measure(label).width
  })
  let down_width = exit_label.map_or(0, label => {
    EDGE_LABEL_OFFSET + small_metrics.measure(label).width
  })
  let incoming_width = sequence_incoming_label(body, nodes).map_or(0, label => {
    EDGE_LABEL_OFFSET + small_metrics.measure(label).width
  })
  let right = (body_size.width - body_axis)
    .max(incoming_width)
    .max(down_width)
    .max(entry_size.width - entry_size.width / 2)
    .max(exit_size.width - exit_size.width / 2 + label_width)
  (axis + right + WHILE_BACK_MARGIN * 2, axis)
}

///|
/// The outgoing label belongs to the repeat condition; the next sequence
/// contributes its usual gap after this label padding.
fn repeat_exit_padding(label : String?, metrics : @metrics.FontMetrics) -> Int {
  label.map_or(0, text => {
    DOWN_LABEL_GAP - VERTICAL_GAP + (line_count(text) - 1) * metrics.line_height
  })
}

///|
/// ConnectionBackComplex1 uses a short clearance if the body is narrower
/// than its condition; otherwise its body width determines the outer turn.
const REPEAT_SIDE_CLEARANCE : Int = 10

///|
fn repeat_lane_return(
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
  offset : Int,
) -> (Int, Int) {
  let start_x = from.x + from.width
  let target_right = to.x + to.width
  if target_right < start_x {
    let corridor = from.x + offset
    (
      if corridor > start_x {
        corridor
      } else {
        start_x + REPEAT_SIDE_CLEARANCE
      },
      target_right,
    )
  } else {
    ((start_x + to.x * 3) / 4, to.x)
  }
}

///|
/// ConnectionOut.drawTranslate attaches its label to the final vertical segment.
/// ConnectionIn and untranslated connections keep the label at the source.
fn repeat_forward_label_position(
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
  nodes : Array[@flow.ActivityNode],
) -> (Int, Int) {
  let source_bottom = from.y + from.height
  if swimlane_names(nodes).length() > 1 &&
    nodes[to.node_index] is @flow.ActivityNode::RepeatWhile(_) &&
    swimlane_for_node(nodes, from.node_index) !=
    swimlane_for_node(nodes, to.node_index) {
    (to.x + to.width / 2 + EDGE_LABEL_OFFSET, (source_bottom + to.y) / 2 + 21)
  } else {
    (
      from.x + from.width / 2 + EDGE_LABEL_OFFSET,
      source_bottom +
      (if nodes[from.node_index].is_decision() { 11 } else { 21 }),
    )
  }
}
