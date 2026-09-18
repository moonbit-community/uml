///|
/// FtileIfNude.widthInner and FtileIfWithDiamonds: branch bodies are padded
/// horizontally, and the condition axis bisects their incoming flow axes.
fn if_columns(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int, Int, Int) {
  let decision = nodes[branches[0].decision.unwrap()].size(
    metrics, small_metrics,
  )
  let left = measure_sequence(branches[0].tiles, nodes, metrics, small_metrics)
  let right = measure_sequence(branches[1].tiles, nodes, metrics, small_metrics)
  let left_axis = sequence_axis(
    branches[0].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let right_axis = sequence_axis(
    branches[1].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let apart = (left.width - left_axis + right_axis + BRANCH_GAP).max(
    decision.width + BRANCH_DIAMOND_MARGIN * 2,
  )
  let left_x = BRANCH_DIAMOND_MARGIN
  let right_x = left_x + left_axis + apart - right_axis
  let axis = left_x + left_axis + apart / 2
  let width = right_x + right.width + BRANCH_DIAMOND_MARGIN
  let left_label = branches[0].label.map_or(0, label => {
    small_metrics.measure(label).width
  })
  let right_label = branches[1].label.map_or(0, label => {
    small_metrics.measure(label).width
  })
  // ConditionalBuilder adds only the margins needed by the side labels.
  let extra_left = (left_label - (axis - decision.width / 2)).max(0)
  let extra_right = (axis +
  decision.width -
  decision.width / 2 +
  right_label -
  width).max(0)
  (
    width + extra_left + extra_right,
    axis + extra_left,
    left_x + extra_left,
    right_x + extra_left,
  )
}

///|
/// FtileIfDown aligns the body and condition, reserving either the empty
/// branch's return corridor or the terminal branch and its label to the right.
fn if_vertical_columns(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int) {
  let body_index = if_vertical_body_index(branches, nodes).unwrap()
  let body = measure_sequence(
    branches[body_index].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let body_axis = sequence_axis(
    branches[body_index].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let decision = nodes[branches[0].decision.unwrap()].size(
    metrics, small_metrics,
  )
  let label_width = branches[1 - body_index].label.map_or(0, label => {
    small_metrics.measure(label).width
  })
  let axis = (body_axis + BRANCH_DIAMOND_MARGIN)
    .max(decision.width / 2)
    .max(EXIT_SIZE / 2)
  let down_width = branches[body_index].label.map_or(0, label => {
    EDGE_LABEL_OFFSET + small_metrics.measure(label).width
  })
  let right = (body.width - body_axis + BRANCH_DIAMOND_MARGIN)
    .max(down_width)
    .max(decision.width - decision.width / 2 + label_width)
    .max(EXIT_SIZE - EXIT_SIZE / 2)
  let side = measure_sequence(
    branches[1 - body_index].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let width = if if_single_terminal(branches[1 - body_index].tiles, nodes) {
    (axis + right + DIAMOND_TEXT_PADDING / 2).max(
      axis +
      decision.width -
      decision.width / 2 +
      if_side_terminal_gap(side.width, label_width) +
      side.width,
    )
  } else {
    axis + right + DIAMOND_TEXT_PADDING / 2
  }
  (width, axis)
}

///|
/// FtileIfLongHorizontal wraps every branch in FtileMinWidthCentered.
const IF_CHAIN_MIN_BRANCH_WIDTH : Int = 30

///|
/// FtileIfLongHorizontal builds each column with FtileAssemblySimple,
/// aligning the condition's axis with its branch before packing columns.
fn if_chain_column(
  branch : BranchTiles,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int) {
  let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
  let padded_width = body.width.max(IF_CHAIN_MIN_BRANCH_WIDTH)
  let body_axis = sequence_axis(branch.tiles, nodes, metrics, small_metrics) +
    (padded_width - body.width) / 2
  let decision = branch.decision.map_or(
    ({ width: 0, height: 0, } : TileMeasure),
    index => nodes[index].size(metrics, small_metrics),
  )
  let empty_width = empty_branch_width(branch, small_metrics)
  let axis = body_axis.max(decision.width / 2).max(empty_width / 2)
  let label_width = branch.label.map_or(0, label => {
    EDGE_LABEL_OFFSET + small_metrics.measure(label).width
  })
  let right = (padded_width - body_axis)
    .max(label_width)
    .max(decision.width - decision.width / 2)
    .max(empty_width - empty_width / 2)
  (axis + right, axis)
}

///|
/// ConditionalBuilder reserves a top margin when side labels exceed the diamond.
fn if_side_label_padding(
  branches : Array[BranchTiles],
  decision_height : Int,
  metrics : @metrics.FontMetrics,
) -> Int {
  let height = branches.fold(init=0, (height, branch) => {
    height.max(branch.label.map_or(0, label => metrics.measure(label).height))
  })
  (height - decision_height).max(0)
}

///|
fn if_chain_body_gap(
  branches : Array[BranchTiles],
  metrics : @metrics.FontMetrics,
) -> Int {
  branches.fold(init=DIAMOND_BODY_GAP, (gap, branch) => {
    gap.max(decision_body_gap(branch.label, metrics))
  })
}

///|
/// ConditionalBuilder.getShape2 uses FtileEmpty when only one branch continues.
fn if_merge_size(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
) -> TileMeasure {
  if branches.all(branch => sequence_has_exit(branch.tiles, nodes)) {
    { width: EXIT_SIZE, height: EXIT_SIZE, }
  } else {
    { width: 0, height: DIAMOND_TEXT_PADDING / 4, }
  }
}

///|
fn place_if_merge(
  index : Int,
  size : TileMeasure,
  center_x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
) -> Unit {
  layouts.push({
    node_index: index,
    x: center_x - size.width / 2,
    y,
    width: size.width,
    height: size.height,
  })
}

///|
/// A single stop/end or killed activity uses ConditionalBuilder's side exit.
fn if_single_terminal(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> Bool {
  let visible = tiles.filter(tile => !tile_is_flow_decoration(tile, nodes))
  match visible {
    [Leaf(index)] =>
      nodes[index] is (@flow.ActivityNode::Stop | @flow.ActivityNode::End)
    [Leaf(index), Leaf(last)] =>
      nodes[index] is @flow.ActivityNode::Action(_) &&
      nodes[last] is @flow.ActivityNode::Kill
    [Noted(Leaf(index), _), Leaf(last)] =>
      nodes[index] is @flow.ActivityNode::Action(_) &&
      nodes[last] is @flow.ActivityNode::Kill
    _ => false
  }
}

///|
fn if_vertical_body_index(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
) -> Int? {
  guard is_if_down(branches) else { return None }
  let left_empty = sequence_is_empty(branches[0].tiles, nodes)
  let right_empty = sequence_is_empty(branches[1].tiles, nodes)
  let left_stop = if_single_terminal(branches[0].tiles, nodes)
  let right_stop = if_single_terminal(branches[1].tiles, nodes)
  if left_stop && !right_stop {
    Some(1)
  } else if right_stop && !left_stop {
    Some(0)
  } else if left_empty {
    Some(1)
  } else if right_empty {
    Some(0)
  } else {
    None
  }
}

///|
fn if_vertical_merge_size(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
) -> TileMeasure {
  let body_index = if_vertical_body_index(branches, nodes).unwrap()
  if if_single_terminal(branches[1 - body_index].tiles, nodes) {
    { width: 0, height: 0, }
  } else {
    if_merge_size(branches, nodes)
  }
}

///|
/// FtileIfDown.getAdditionalWidth separates the side terminal from its label.
fn if_side_terminal_gap(width : Int, label_width : Int) -> Int {
  width.max(label_width + width / 2)
}
