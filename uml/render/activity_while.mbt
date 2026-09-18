///|
/// FtileWhile.calculateDimensionFtile stacks the condition and body on one
/// axis, with two hexagon half-widths on the left and one on the right.
fn while_columns(
  entry : Int,
  body : Array[Tile],
  exit : Int,
  exit_label : String?,
  enter_label : String?,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int) {
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let body_size = measure_sequence(body, nodes, metrics, small_metrics)
  let body_axis = sequence_axis(body, nodes, metrics, small_metrics)
  let label_width = exit_label.map_or(0, label => {
    small_metrics.measure(label).width
  })
  let left = body_axis
    .max(entry_size.width / 2 + label_width)
    .max(exit_size.width / 2)
  let down_width = enter_label.map_or(0, label => {
    EDGE_LABEL_OFFSET + small_metrics.measure(label).width
  })
  let right = (body_size.width - body_axis)
    .max(down_width)
    .max(entry_size.width - entry_size.width / 2)
    .max(exit_size.width - exit_size.width / 2)
  (left + right + WHILE_BACK_MARGIN * 3, left + WHILE_BACK_MARGIN * 2)
}
