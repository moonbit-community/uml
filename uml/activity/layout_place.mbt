///|
fn place_sequence(
  tiles : Array[Tile],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let size = measure_sequence(tiles, nodes, metrics, small_metrics)
  let mut cursor_y = y
  let mut entry = None
  let mut previous : PlacedTile? = None
  let mut pending_label : String? = None
  for tile in tiles {
    match tile {
      LabelAnchor(index) | GotoAnchor(index) => {
        layouts.push({ node_index: index, x, y: cursor_y, width: 0, height: 0, })
        continue
      }
      Swimlane(_) => continue
      Leaf(index) if nodes[index] is ActivityNode::Arrow(value) => {
        pending_label = arrow_label(value).text
        continue
      }
      _ => ()
    }
    let tile_size = measure_tile(tile, nodes, metrics, small_metrics)
    guard tile_size.height > 0 else { continue }
    if previous is Some(_) {
      cursor_y += sequence_gap(previous, pending_label, x, layouts)
    }
    let placed = place_tile(
      tile,
      nodes,
      metrics,
      small_metrics,
      x + (size.width - tile_size.width) / 2,
      cursor_y,
      layouts,
      edges,
    )
    if previous is Some(previous) {
      append_layout_edge(
        edges,
        previous.exit,
        placed.entry,
        previous.outgoing_route,
        label=pending_label.map_or(previous.outgoing_label, label => Some(label)),
      )
    }
    pending_label = None
    if entry is None {
      entry = placed.entry
    }
    if placed.exit is Some(_) {
      previous = Some(placed)
    }
    cursor_y += tile_size.height
  }
  match previous {
    Some(previous) =>
      {
        entry,
        exit: previous.exit,
        outgoing_label: previous.outgoing_label,
        outgoing_route: previous.outgoing_route,
      }
    None =>
      { entry, exit: None, outgoing_label: None, outgoing_route: Forward, }
  }
}

///|
/// Vertical gap before the tile that follows `previous`. A labeled edge adds
/// the label block height; an exit shifted away from the flow column doubles
/// the gap so the S-shaped connector fits.
fn sequence_gap(
  previous : PlacedTile?,
  pending_label : String?,
  x : Int,
  layouts : Array[ActivityNodeLayout],
) -> Int {
  let base = match previous {
    Some(previous) =>
      match previous.exit {
        Some(exit) =>
          match layout_for_node(layouts, exit) {
            Some(exit_x) =>
              if exit_x == x {
                VERTICAL_GAP
              } else {
                VERTICAL_GAP * 2
              }
            None => VERTICAL_GAP
          }
        None => VERTICAL_GAP
      }
    None => VERTICAL_GAP
  }
  pending_label.map_or(base, label => {
    base +
    EDGE_LABEL_GAP -
    VERTICAL_GAP +
    EDGE_LABEL_LINE * (line_count(label) - 1)
  })
}

///|
fn place_branches(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Array[PlacedBranch] {
  let placed = []
  let mut cursor_x = x
  for branch in branches {
    let branch_size = measure_sequence(
      branch.tiles,
      nodes,
      metrics,
      small_metrics,
    )
    placed.push({
      tile: place_sequence(
        branch.tiles,
        nodes,
        metrics,
        small_metrics,
        cursor_x,
        y,
        layouts,
        edges,
      ),
      label: branch.label,
    })
    cursor_x += branch_size.width + BRANCH_GAP
  }
  placed
}

///|
fn place_leaf(
  index : Int,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
) -> PlacedTile {
  let size = nodes[index].size(metrics, small_metrics)
  guard size.height > 0 else {
    return {
      entry: None,
      exit: None,
      outgoing_label: None,
      outgoing_route: Forward,
    }
  }
  layouts.push({
    node_index: index,
    x,
    y,
    width: size.width,
    height: size.height,
  })
  {
    entry: Some(index),
    exit: Some(index),
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
/// Whether the branch list is the classic `if/else` pair (a single decision
/// followed by a plain else body), laid out like PlantUML `FtileIfDown`.
fn is_if_down(branches : Array[BranchTiles]) -> Bool {
  branches.length() == 2 &&
  branches[0].decision is Some(_) &&
  branches[1].decision is None
}

///|
fn place_tile(
  tile : Tile,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  match tile {
    Leaf(index) =>
      place_leaf(index, nodes, metrics, small_metrics, x, y, layouts)
    LabelAnchor(_) | GotoAnchor(_) =>
      {
        entry: None,
        exit: None,
        outgoing_label: None,
        outgoing_route: Forward,
      }
    Partition(tiles) =>
      place_sequence(tiles, nodes, metrics, small_metrics, x, y, layouts, edges)
    Swimlane(_) =>
      {
        entry: None,
        exit: None,
        outgoing_label: None,
        outgoing_route: Forward,
      }
    IfChain(branches, exit) if is_if_down(branches) =>
      place_if_down(
        branches, exit, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
    IfChain(branches, exit) =>
      place_if_chain(
        branches, exit, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
    Switch(entry, branches, exit) =>
      place_switch(
        entry, branches, exit, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
    WhileLoop(entry, body, exit, enter_label, exit_label) =>
      place_while(
        entry, body, exit, enter_label, exit_label, nodes, metrics, small_metrics,
        x, y, layouts, edges,
      )
    RepeatLoop(body, exit, retry_label, exit_label) =>
      place_repeat(
        body, exit, retry_label, exit_label, nodes, metrics, small_metrics, x, y,
        layouts, edges,
      )
    Parallel(entry, branches, exit) =>
      place_parallel(
        entry, branches, exit, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
  }
}

///|
/// Classic `if (cond) then ... else ...` layout: a single decision diamond
/// centered between the two branch columns, labels beside the diamond.
fn place_if_down(
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let decision = branches[0].decision.unwrap()
  let size = nodes[decision].size(metrics, small_metrics)
  let left_size = measure_sequence(
    branches[0].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let right_size = measure_sequence(
    branches[1].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let tile_size = measure_if_down(branches, nodes, metrics, small_metrics)
  let center_x = x + tile_size.width / 2
  let apart = (BRANCH_GAP + left_size.width / 2 + right_size.width / 2).max(
    size.width + BRANCH_DIAMOND_MARGIN * 2,
  )
  let decision_placed = place_leaf(
    decision,
    nodes,
    metrics,
    small_metrics,
    center_x - size.width / 2,
    y,
    layouts,
  )
  let body_y = y + size.height + DIAMOND_BODY_GAP
  let left_body = place_sequence(
    branches[0].tiles,
    nodes,
    metrics,
    small_metrics,
    center_x - apart / 2 - left_size.width / 2,
    body_y,
    layouts,
    edges,
  )
  let right_body = place_sequence(
    branches[1].tiles,
    nodes,
    metrics,
    small_metrics,
    center_x + apart / 2 - right_size.width / 2,
    body_y,
    layouts,
    edges,
  )
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let body_bottom = body_y + left_size.height.max(right_size.height)
  let exit_placed = place_leaf(
    exit,
    nodes,
    metrics,
    small_metrics,
    center_x - exit_size.width / 2,
    body_bottom + BODY_EXIT_GAP,
    layouts,
  )
  append_layout_edge(
    edges,
    decision_placed.entry,
    left_body.entry,
    IfDownLeft,
    label=branches[0].label,
  )
  append_layout_edge(
    edges,
    decision_placed.entry,
    right_body.entry,
    IfDownRight,
    label=branches[1].label,
  )
  append_layout_edge(edges, left_body.exit, exit_placed.entry, Forward)
  append_layout_edge(edges, right_body.exit, exit_placed.entry, Forward)
  {
    entry: decision_placed.entry,
    exit: exit_placed.exit,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
/// `elseif` chain layout: every non-terminal branch gets its own diamond,
/// branch labels ride the down edges, and the columns are packed side by
/// side below a shared exit node.
fn place_if_chain(
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let branches_size = measure_if_chain(branches, nodes, metrics, small_metrics)
  let chain_width = measure_chain_width(branches, nodes, metrics, small_metrics)
  let mut decision_height = 0
  for branch in branches {
    guard branch.decision is Some(decision) else { continue }
    decision_height = decision_height.max(
      nodes[decision].size(metrics, small_metrics).height,
    )
  }
  let body_y = y +
    decision_height +
    (if branches.any(branch => branch.label is Some(_)) {
      DOWN_LABEL_GAP
    } else {
      DIAMOND_BODY_GAP
    })
  let placed = []
  let mut cursor_x = x + (branches_size.width - chain_width) / 2
  for branch in branches {
    let body_size = measure_sequence(
      branch.tiles,
      nodes,
      metrics,
      small_metrics,
    )
    let decision_size = branch.decision.map_or({ width: 0, height: 0, }, index => {
      nodes[index].size(metrics, small_metrics)
    })
    let branch_width = body_size.width.max(decision_size.width)
    if branch.decision is Some(decision) {
      place_leaf(
        decision,
        nodes,
        metrics,
        small_metrics,
        cursor_x + (branch_width - decision_size.width) / 2,
        y,
        layouts,
      )
      |> ignore
    }
    let body = place_sequence(
      branch.tiles,
      nodes,
      metrics,
      small_metrics,
      cursor_x + (branch_width - body_size.width) / 2,
      body_y,
      layouts,
      edges,
    )
    if branch.decision is Some(decision) {
      append_layout_edge(
        edges,
        Some(decision),
        body.entry,
        Forward,
        label=branch.label,
      )
    }
    placed.push({ tile: body, label: branch.label, })
    cursor_x += branch_width + BRANCH_GAP
  }
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let exit_y = body_y +
    measure_branches_height(branches, nodes, metrics, small_metrics) +
    BODY_EXIT_GAP
  let exit_placed = place_leaf(
    exit,
    nodes,
    metrics,
    small_metrics,
    x + (branches_size.width - exit_size.width) / 2,
    exit_y,
    layouts,
  )
  for branch in placed {
    append_layout_edge(edges, branch.tile.exit, exit_placed.entry, Forward)
  }
  {
    entry: branches[0].decision,
    exit: exit_placed.exit,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
/// Max body height across the branch columns.
fn measure_branches_height(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut height = 0
  for branch in branches {
    let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    height = height.max(body.height)
  }
  height
}

///|
/// Sum of branch column widths plus the gaps between them.
fn measure_chain_width(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut width = 0
  for index, branch in branches {
    let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    let decision = branch.decision.map_or({ width: 0, height: 0, }, index => {
      nodes[index].size(metrics, small_metrics)
    })
    if index > 0 {
      width += BRANCH_GAP
    }
    width += body.width.max(decision.width)
  }
  width
}

///|
fn place_switch(
  entry : Int,
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let branches_size = measure_branches(branches, nodes, metrics, small_metrics)
  let entry_placed = place_leaf(
    entry,
    nodes,
    metrics,
    small_metrics,
    x + (branches_size.width - entry_size.width) / 2,
    y,
    layouts,
  )
  let case_y = y + entry_size.height + SWITCH_CASE_GAP
  let case_placed = place_branches(
    branches,
    nodes,
    metrics,
    small_metrics,
    x +
    (
      branches_size.width -
      measure_branches_width(branches, nodes, metrics, small_metrics)
    ) /
    2,
    case_y,
    layouts,
    edges,
  )
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let exit_y = case_y + branches_size.height + VERTICAL_GAP
  let exit_placed = place_leaf(
    exit,
    nodes,
    metrics,
    small_metrics,
    x + (branches_size.width - exit_size.width) / 2,
    exit_y,
    layouts,
  )
  for index, branch in case_placed {
    let route = if index == 0 {
      SwitchLeft
    } else if index == branches.length() - 1 {
      SwitchRight
    } else {
      SwitchMiddle
    }
    append_layout_edge(
      edges,
      entry_placed.entry,
      branch.tile.entry,
      route,
      label=branch.label,
    )
    append_layout_edge(edges, branch.tile.exit, exit_placed.entry, Forward)
  }
  {
    entry: entry_placed.entry,
    exit: exit_placed.exit,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
/// Width of the packed case columns (gaps included, without the entry node).
fn measure_branches_width(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut width = 0
  for index, branch in branches {
    let size = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    if index > 0 {
      width += BRANCH_GAP
    }
    width += size.width
  }
  width
}

///|
fn place_while(
  entry : Int,
  body : Array[Tile],
  exit : Int,
  enter_label : String?,
  exit_label : String?,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let size = measure_tile(
    WhileLoop(entry, body, exit, enter_label, exit_label),
    nodes,
    metrics,
    small_metrics,
  )
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let body_size = measure_sequence(body, nodes, metrics, small_metrics)
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let entry_placed = place_leaf(
    entry,
    nodes,
    metrics,
    small_metrics,
    x + (size.width - entry_size.width) / 2,
    y,
    layouts,
  )
  let body_y = y +
    entry_size.height +
    (if enter_label is Some(_) { DOWN_LABEL_GAP } else { DIAMOND_BODY_GAP })
  let body_placed = place_sequence(
    body,
    nodes,
    metrics,
    small_metrics,
    x + (size.width - body_size.width) / 2,
    body_y,
    layouts,
    edges,
  )
  let exit_placed = place_leaf(
    exit,
    nodes,
    metrics,
    small_metrics,
    x + (size.width - exit_size.width) / 2,
    body_y + body_size.height + WHILE_EXIT_GAP,
    layouts,
  )
  append_layout_edge(
    edges,
    entry_placed.entry,
    body_placed.entry,
    Forward,
    label=enter_label,
  )
  append_layout_edge(edges, body_placed.exit, entry_placed.entry, BackwardRight)
  append_layout_edge(
    edges,
    entry_placed.entry,
    exit_placed.entry,
    WhileExitLeft,
    label=exit_label,
  )
  append_layout_edge(edges, exit_placed.exit, body_placed.entry, Forward)
  {
    entry: entry_placed.entry,
    exit: exit_placed.exit,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
fn place_repeat(
  body : Array[Tile],
  exit : Int,
  retry_label : String?,
  exit_label : String?,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let body_size = measure_sequence(body, nodes, metrics, small_metrics)
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let body_placed = place_sequence(
    body, nodes, metrics, small_metrics, x, y, layouts, edges,
  )
  let exit_y = y + body_size.height + VERTICAL_GAP
  let exit_placed = place_leaf(
    exit,
    nodes,
    metrics,
    small_metrics,
    x + (body_size.width - exit_size.width) / 2,
    exit_y,
    layouts,
  )
  append_layout_edge(edges, body_placed.exit, exit_placed.entry, Forward)
  append_layout_edge(
    edges,
    exit_placed.entry,
    body_placed.entry,
    BackwardRight,
    label=retry_label,
  )
  {
    entry: body_placed.entry,
    exit: exit_placed.exit,
    outgoing_label: exit_label,
    outgoing_route: Forward,
  }
}

///|
fn place_parallel(
  entry : Int,
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let columns = measure_fork_columns(branches, nodes, metrics, small_metrics)
  let block_width = columns + FORK_COLUMN_MARGIN * 2
  let branches_y = y + FORK_BAR_HEIGHT + VERTICAL_GAP
  let mut cursor_x = x
  let placed = []
  for branch in branches {
    let branch_size = measure_sequence(
      branch.tiles,
      nodes,
      metrics,
      small_metrics,
    )
    let column_width = branch_size.width + FORK_COLUMN_MARGIN * 2
    placed.push({
      tile: place_sequence(
        branch.tiles,
        nodes,
        metrics,
        small_metrics,
        cursor_x + FORK_COLUMN_MARGIN,
        branches_y,
        layouts,
        edges,
      ),
      label: None,
    })
    cursor_x += column_width
  }
  let branches_height = fork_branches_height(
    branches, nodes, metrics, small_metrics,
  )
  let exit_y = branches_y + branches_height + VERTICAL_GAP
  layouts.push({
    node_index: entry,
    x,
    y,
    width: block_width,
    height: FORK_BAR_HEIGHT,
  })
  layouts.push({
    node_index: exit,
    x,
    y: exit_y,
    width: block_width,
    height: FORK_BAR_HEIGHT,
  })
  for branch in placed {
    append_layout_edge(edges, Some(entry), branch.tile.entry, Forward)
    append_layout_edge(edges, branch.tile.exit, Some(exit), Forward)
  }
  {
    entry: Some(entry),
    exit: Some(exit),
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
fn fork_branches_height(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut height = 0
  for branch in branches {
    let size = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    height = height.max(size.height)
  }
  height
}

///|
fn measure_fork_columns(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut width = 0
  for index, branch in branches {
    let size = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    if index > 0 {
      width += FORK_COLUMN_MARGIN * 2
    }
    width += size.width
  }
  width
}

///|
/// Lay out activity control flow as nested tiles. This follows PlantUML's
/// `InstructionIf`, `InstructionWhile`, and `InstructionFork` decomposition:
/// branches are horizontal siblings, their exits join, and loops own a back
/// edge to the controlling decision.
pub fn ActivityDiagram::layout(self : ActivityDiagram) -> ActivityLayout {
  let style = self.style
  let family = style.font_family()
  let metrics = style.font_metrics_for(family, font_size=ACTION_FONT)
  let small_metrics = style.font_metrics_for(family, font_size=SMALL_FONT)
  let source_nodes = []
  let tiles = tiles_from_instructions(self.instructions, source_nodes)
  let content = measure_sequence(tiles, source_nodes, metrics, small_metrics)
  let layouts = []
  let edges = []
  let content_x = CANVAS_LEFT
  let top_padding = if source_nodes.any(node => {
      node is ActivityNode::Partition(_) || node is ActivityNode::Swimlane(_)
    }) {
    CANVAS_TOP + REGION_HEADER_HEIGHT + REGION_PADDING
  } else {
    CANVAS_TOP
  }
  let _ = place_sequence(
    tiles, source_nodes, metrics, small_metrics, content_x, top_padding, layouts,
    edges,
  )
  let swimlane_width = reposition_swimlanes(source_nodes, layouts)
  append_goto_edges(source_nodes, layouts, edges)
  let regions = regions_from_nodes(source_nodes, layouts)
  let mut result : ActivityLayout = {
    nodes: layouts,
    edges,
    regions,
    source_nodes,
    width: 0,
    height: content.height + top_padding + CANVAS_BOTTOM,
  }
  let has_swimlanes = source_nodes.any(node => node is ActivityNode::Swimlane(_))
  if !has_swimlanes {
    result = result.compress_x()
  }
  let content_right = layout_content_right(
    result.nodes,
    result.edges,
    small_metrics,
  )
  { ..result, width: (content_right + CANVAS_RIGHT).max(swimlane_width), }
}

///|
/// Rightmost extent of the placed content, including arrow labels and back
/// edges that stick out of the flow column.
fn layout_content_right(
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut right = 0
  for layout in layouts {
    right = right.max(layout.x + layout.width)
  }
  for edge in edges {
    if edge_label_extent(edge, layouts, small_metrics) is Some(end) {
      right = right.max(end)
    }
  }
  right
}

///|
/// Right edge of the space an edge label occupies, or of the back-edge route
/// when the edge carries no label.
fn edge_label_extent(
  edge : ActivityEdgeLayout,
  layouts : Array[ActivityNodeLayout],
  small_metrics : @metrics.FontMetrics,
) -> Int? {
  let from_index = edge.from_node_index
  let to_index = edge.to_node_index
  let mut from : ActivityNodeLayout? = None
  let mut to : ActivityNodeLayout? = None
  for layout in layouts {
    if layout.node_index == from_index {
      from = Some(layout)
    }
    if layout.node_index == to_index {
      to = Some(layout)
    }
  }
  match (from, to) {
    (Some(from), Some(to)) => {
      let route_x = (from.x + from.width).max(to.x + to.width) +
        WHILE_BACK_MARGIN
      match (edge.label, edge.route) {
        (Some(label), BackwardRight) =>
          Some(route_x + small_metrics.measure(label).width / 2)
        (Some(label), _) =>
          match edge.route {
            IfDownLeft
            | IfDownRight
            | SwitchLeft
            | SwitchRight
            | SwitchMiddle
            | WhileExitLeft => None
            _ =>
              Some(
                from.x + from.width / 2 + 4 + small_metrics.measure(label).width,
              )
          }
        (None, BackwardRight) => Some(route_x)
        (None, _) => None
      }
    }
    _ => None
  }
}
