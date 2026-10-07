///|
/// FtileSwitchWithDiamonds.SUPP15.
const SWITCH_SIDE_GAP : Double = 15

///|
/// FtileSwitchWithManyLinks.ConnectionHorizontalThenVertical uses the
/// hexagon's side width to turn outside a right-hand case that folds inward.
fn switch_right_route_x(from : ActivityNodeLayout, target_x : Double) -> Double {
  let right = from.x + from.width
  if target_x < right {
    right + DIAMOND_TEXT_PADDING / 2
  } else {
    target_x
  }
}

///|
/// Width, flow axis, case column origins and wide-condition mode for the SMALL_DIAMOND and
/// BIG_DIAMOND layouts in FtileSwitchWithDiamonds.
fn switch_columns(
  entry : Int,
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Double, Double, Array[Double], Bool) {
  let entry_width = nodes[entry].size(metrics, small_metrics).width
  let exit_width = nodes[exit].size(metrics, small_metrics).width
  let sizes = branches.map(branch => {
    let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    let axis = sequence_axis(branch.tiles, nodes, metrics, small_metrics)
    let label_width = branch.label.map_or(0.0, label => {
      activity_measure(small_metrics, label).width
    })
    // Incoming labels extend the right side; body measurement includes outgoing labels.
    { ..body, width: body.width.max(axis + label_width), }
  })
  if branches.length() > 1 {
    let first = sizes[0]
    let last = sizes[sizes.length() - 1]
    let first_axis = sequence_axis(
      branches[0].tiles,
      nodes,
      metrics,
      small_metrics,
    )
    let last_axis = sequence_axis(
      branches[branches.length() - 1].tiles,
      nodes,
      metrics,
      small_metrics,
    )
    let spanning_width = entry_width - (first.width - first_axis) - last_axis
    let mut middle_width = 0.0
    for index in 1..<(sizes.length() - 1) {
      middle_width += sizes[index].width
    }
    if spanning_width > middle_width {
      let positions = []
      let mut cursor = 0.0
      for index in 0..<(sizes.length() - 1) {
        positions.push(
          cursor +
          (spanning_width - middle_width) *
          index.to_double() /
          (sizes.length() - 1).to_double(),
        )
        cursor += sizes[index].width
      }
      let last_x = first.width + spanning_width + SWITCH_SIDE_GAP * 2
      positions.push(last_x)
      return (
        last_x + last.width,
        first_axis + SWITCH_SIDE_GAP + entry_width / 2,
        positions,
        true,
      )
    }
  }
  let packed = sizes.fold(init=0.0, (width, size) => width + size.width) +
    (sizes.length() - 1).max(0).to_double() * BRANCH_GAP
  let axis = (packed / 2).max(entry_width / 2).max(exit_width / 2)
  let width = axis +
    (packed - packed / 2)
    .max(entry_width - entry_width / 2)
    .max(exit_width - exit_width / 2)
  let positions = []
  let mut cursor = axis - packed / 2
  for size in sizes {
    positions.push(cursor)
    cursor += size.width + BRANCH_GAP
  }
  (width, axis, positions, false)
}

///|
/// FtileSwitchWithManyLinks.getYdelta1a and FtileDecorateInLabel.addTop.
const SWITCH_LABEL_GAP : Double = 10

///|
fn switch_label_height(
  branch : BranchTiles,
  small_metrics : @metrics.FontMetrics,
) -> Double {
  branch.label.map_or(0.0, label => {
    activity_measure(small_metrics, label).height
  })
}

///|
/// Gap above the decorated columns, and height including their label padding.
fn switch_rows(
  branches : Array[BranchTiles],
  entry_height : Double,
  wide_condition : Bool,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Double, Double) {
  let mut label_height = SWITCH_LABEL_GAP
  let mut height = 0.0
  for branch in branches {
    let label = switch_label_height(branch, small_metrics)
    label_height = label_height.max(label)
    let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    let outgoing_height = sequence_outgoing_label(branch.tiles, nodes).map_or(
      0.0,
      text => activity_measure(small_metrics, text).height,
    )
    height = height.max(label + body.height + outgoing_height)
  }
  let gap = if branches.length() == 1 {
    SWITCH_LABEL_GAP * 2
  } else {
    label_height +
    SWITCH_LABEL_GAP +
    (if wide_condition { entry_height / 2 } else { 0 })
  }
  (gap, height)
}

///|
/// FtileSwitchWithManyLinks.ConnectionVerticalThenHorizontal right-side detour.
const SWITCH_MERGE_APPROACH : Double = 10

///|
const SWITCH_MERGE_CLEARANCE : Double = 8

///|
const SWITCH_MERGE_DETOUR : Double = 12
