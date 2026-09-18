///|
fn place_sequence(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let axis = sequence_axis(tiles, nodes, metrics, small_metrics)
  let mut cursor_y = y
  let mut entry = None
  let mut previous : PlacedTile? = None
  let mut pending_label : String?? = None
  for tile in tiles {
    match tile {
      Swimlane(_) => continue
      Leaf(index) if nodes[index] is @flow.ActivityNode::Kill => {
        previous = previous.map(tile => { ..tile, exit: None, })
        continue
      }
      Leaf(index) if nodes[index] is @flow.ActivityNode::Arrow(value) => {
        pending_label = Some(
          @flow.arrow_label(value).text.map(activity_display_text),
        )
        continue
      }
      _ => ()
    }
    let tile_size = measure_tile(tile, nodes, metrics, small_metrics)
    guard tile_size.height > 0 || tile is (FlowAnchor(_) | GotoAnchor(_)) else {
      continue
    }
    let incoming = pending_label.map_or(tile_incoming_override(tile, nodes), label => {
      Some(label)
    })
    if previous is Some(_) {
      cursor_y += sequence_gap(incoming.unwrap_or(None))
    }
    let placed = place_tile(
      tile,
      nodes,
      metrics,
      small_metrics,
      x + axis - tile_axis(tile, nodes, metrics, small_metrics),
      cursor_y,
      layouts,
      edges,
    )
    if previous is Some(previous) {
      // Assembly connects the fork's central ports, unlike its branch links.
      let route = if previous.outgoing_route is Forward &&
        (
          previous.exit.map_or(false, index => nodes[index].is_fork()) ||
          placed.entry.map_or(false, index => nodes[index].is_fork())
        ) {
        ForkSequence
      } else {
        previous.outgoing_route
      }
      append_layout_edge(
        edges,
        previous.exit,
        placed.entry,
        route,
        label=incoming.unwrap_or(previous.outgoing_label),
      )
    }
    pending_label = None
    if entry is None {
      entry = placed.entry
    }
    previous = Some(placed)
    cursor_y += tile_size.height
  }
  match previous {
    Some(previous) =>
      {
        entry,
        exit: previous.exit,
        outgoing_label: sequence_outgoing_label(tiles, nodes),
        outgoing_route: previous.outgoing_route,
      }
    None =>
      { entry, exit: None, outgoing_label: None, outgoing_route: Forward, }
  }
}

///|
fn place_switch_branches(
  branches : Array[BranchTiles],
  positions : Array[Int],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Array[PlacedBranch] {
  let placed = []
  for index, branch in branches {
    placed.push({
      tile: place_sequence(
        branch.tiles,
        nodes,
        metrics,
        small_metrics,
        x + positions[index],
        y + switch_label_height(branch, small_metrics),
        layouts,
        edges,
      ),
      label: branch.label,
    })
  }
  placed
}

///|
fn place_leaf(
  index : Int,
  nodes : Array[@flow.ActivityNode],
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
    entry: if nodes[index] is @flow.ActivityNode::Note(_) {
      None
    } else {
      Some(index)
    },
    exit: if nodes[index]
      is (@flow.ActivityNode::Stop
      | @flow.ActivityNode::End
      | @flow.ActivityNode::Note(_)) {
      None
    } else {
      Some(index)
    },
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
  nodes : Array[@flow.ActivityNode],
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
    Noted(body, notes) =>
      place_noted(
        body, notes, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
    FlowAnchor(index) | GotoAnchor(index) => {
      layouts.push({ node_index: index, x, y, width: 0, height: 0, })
      {
        entry: Some(index),
        exit: if tile is GotoAnchor(_) {
          None
        } else {
          Some(index)
        },
        outgoing_label: None,
        outgoing_route: Forward,
      }
    }
    Partition(index, tiles, end) => {
      let size = measure_tile(tile, nodes, metrics, small_metrics)
      let body = measure_sequence(tiles, nodes, metrics, small_metrics)
      let title = metrics.measure(nodes[index].label().unwrap())
      layouts.push({
        node_index: index,
        x,
        y,
        width: size.width,
        height: size.height,
      })
      let placed = place_sequence(
        tiles,
        nodes,
        metrics,
        small_metrics,
        x + (size.width - body.width) / 2,
        y + partition_header_height(title.height),
        layouts,
        edges,
      )
      if placed.entry is None && sequence_has_exit(tiles, nodes) {
        layouts.push({
          node_index: end,
          x: x + size.width / 2,
          y: y + partition_header_height(title.height),
          width: 0,
          height: 0,
        })
        { ..placed, entry: Some(end), exit: Some(end), }
      } else {
        placed
      }
    }
    Swimlane(_) =>
      {
        entry: None,
        exit: None,
        outgoing_label: None,
        outgoing_route: Forward,
      }
    IfChain(branches, exit) if if_vertical_body_index(branches, nodes)
      is Some(_) =>
      place_if_vertical(
        branches, exit, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
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
    RepeatLoop(entry, body, exit, retry_label, exit_label) =>
      place_repeat(
        entry, body, exit, retry_label, exit_label, nodes, metrics, small_metrics,
        x, y, layouts, edges,
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
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let decision = branches[0].decision.unwrap()
  let size = nodes[decision].size(metrics, small_metrics)
  let y = y + if_side_label_padding(branches, size.height, small_metrics)
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
  let (_, axis, left_x, right_x) = if_columns(
    branches, nodes, metrics, small_metrics,
  )
  let center_x = x + axis
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
    x + left_x,
    body_y,
    layouts,
    edges,
  )
  let right_body = place_sequence(
    branches[1].tiles,
    nodes,
    metrics,
    small_metrics,
    x + right_x,
    body_y,
    layouts,
    edges,
  )
  let exit_size = if_merge_size(branches, nodes)
  let body_bottom = body_y + left_size.height.max(right_size.height)
  let has_exit = branches.any(branch => sequence_has_exit(branch.tiles, nodes))
  if has_exit {
    place_if_merge(
      exit,
      exit_size,
      center_x,
      body_bottom + BODY_EXIT_GAP,
      layouts,
    )
  }
  let merge = if has_exit { Some(exit) } else { None }
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
  append_layout_edge(
    edges,
    left_body.exit,
    merge,
    IfEmptyDown,
    label=left_body.outgoing_label,
  )
  append_layout_edge(
    edges,
    right_body.exit,
    merge,
    IfEmptyDown,
    label=right_body.outgoing_label,
  )
  {
    entry: decision_placed.entry,
    exit: merge,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
/// `elseif` chain layout: every non-terminal branch gets its own diamond,
/// branch labels ride the down edges, and the columns are packed side by
/// side above a shared exit node. False paths connect successive decisions
/// horizontally, then turn down into the final else branch.
fn place_if_chain(
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let branches_size = measure_if_chain(branches, nodes, metrics, small_metrics)
  let mut decision_height = 0
  for branch in branches {
    guard branch.decision is Some(decision) else { continue }
    decision_height = decision_height.max(
      nodes[decision].size(metrics, small_metrics).height,
    )
  }
  let body_y = y + decision_height + if_chain_body_gap(branches, small_metrics)
  let placed = []
  let mut cursor_x = x
  let mut previous_decision : Int? = None
  let mut previous_decision_x = x
  for branch in branches {
    let decision_size = branch.decision.map_or(
      ({ width: 0, height: 0, } : TileMeasure),
      index => nodes[index].size(metrics, small_metrics),
    )
    let (branch_width, axis) = if_chain_column(
      branch, nodes, metrics, small_metrics,
    )
    if branch.decision is Some(decision) {
      place_leaf(
        decision,
        nodes,
        metrics,
        small_metrics,
        cursor_x + axis - decision_size.width / 2,
        y + decision_height / 2 - decision_size.height / 2,
        layouts,
      )
      |> ignore
    }
    let body = place_sequence(
      branch.tiles,
      nodes,
      metrics,
      small_metrics,
      cursor_x +
      axis -
      sequence_axis(branch.tiles, nodes, metrics, small_metrics),
      body_y,
      layouts,
      edges,
    )
    if branch.decision is Some(decision) {
      append_layout_edge(edges, previous_decision, Some(decision), Horizontal)
      previous_decision = Some(decision)
      previous_decision_x = cursor_x + axis - decision_size.width / 2
      append_layout_edge(
        edges,
        Some(decision),
        Some(body.entry.unwrap_or(exit)),
        if body.entry is Some(_) {
          Forward
        } else {
          IfEmptyDown
        },
        label=branch.label,
      )
    } else {
      append_layout_edge(
        edges,
        previous_decision,
        Some(body.entry.unwrap_or(exit)),
        if body.entry is Some(_) {
          IfDownRight
        } else {
          IfBypassRight(cursor_x + branch_width - previous_decision_x)
        },
        label=branch.label,
      )
    }
    placed.push({ tile: body, label: branch.label, })
    cursor_x += branch_width + BRANCH_GAP
  }
  let exit_y = body_y +
    measure_branches_height(branches, nodes, metrics, small_metrics) +
    BODY_EXIT_GAP
  let has_exit = branches.any(branch => sequence_has_exit(branch.tiles, nodes))
  if has_exit {
    place_tile(
      FlowAnchor(exit),
      nodes,
      metrics,
      small_metrics,
      x + branches_size.width / 2,
      exit_y,
      layouts,
      edges,
    )
    |> ignore
  }
  let merge = if has_exit { Some(exit) } else { None }
  for branch in placed {
    append_layout_edge(
      edges,
      branch.tile.exit,
      merge,
      IfChainMerge,
      label=branch.tile.outgoing_label,
    )
  }
  {
    entry: branches[0].decision,
    exit: merge,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
/// Max body height across the branch columns.
fn measure_branches_height(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
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
fn place_switch(
  entry : Int,
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let (_, axis, positions, wide_condition) = switch_columns(
    entry, branches, exit, nodes, metrics, small_metrics,
  )
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let (gap, branch_height) = switch_rows(
    branches,
    entry_size.height,
    wide_condition,
    nodes,
    metrics,
    small_metrics,
  )
  let entry_placed = place_leaf(
    entry,
    nodes,
    metrics,
    small_metrics,
    x + axis - entry_size.width / 2,
    y,
    layouts,
  )
  let case_y = y + entry_size.height + gap
  let case_placed = place_switch_branches(
    branches, positions, nodes, metrics, small_metrics, x, case_y, layouts, edges,
  )
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let exit_y = case_y + branch_height + VERTICAL_GAP
  let has_exit = branches.any(branch => sequence_has_exit(branch.tiles, nodes))
  if has_exit {
    place_leaf(
      exit,
      nodes,
      metrics,
      small_metrics,
      x + axis - exit_size.width / 2,
      exit_y,
      layouts,
    )
    |> ignore
  }
  let merge = if has_exit { Some(exit) } else { None }
  let mut first_exit = None
  let mut last_exit = None
  for branch in case_placed {
    guard branch.tile.exit is Some(exit) else { continue }
    if first_exit is None {
      first_exit = Some(exit)
    }
    last_exit = Some(exit)
  }
  for index, branch in case_placed {
    let route = if branches.length() == 1 {
      SwitchMiddle
    } else if index == 0 {
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
    let merge_route = if branches.length() > 1 &&
      (branch.tile.exit == first_exit || branch.tile.exit == last_exit) {
      SwitchSideMerge
    } else {
      Forward
    }
    append_layout_edge(
      edges,
      branch.tile.exit,
      merge,
      merge_route,
      label=branch.tile.outgoing_label,
    )
  }
  {
    entry: entry_placed.entry,
    exit: merge,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
fn place_while(
  entry : Int,
  body : Array[Tile],
  exit : Int,
  enter_label : String?,
  exit_label : String?,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let (width, axis) = while_columns(
    entry, body, exit, exit_label, enter_label, nodes, metrics, small_metrics,
  )
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let body_size = measure_sequence(body, nodes, metrics, small_metrics)
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let entry_placed = place_leaf(
    entry,
    nodes,
    metrics,
    small_metrics,
    x + axis - entry_size.width / 2,
    y,
    layouts,
  )
  let body_y = y +
    entry_size.height +
    decision_body_gap(enter_label, small_metrics)
  let body_placed = place_sequence(
    body,
    nodes,
    metrics,
    small_metrics,
    x + axis - sequence_axis(body, nodes, metrics, small_metrics),
    body_y,
    layouts,
    edges,
  )
  let exit_placed = place_tile(
    FlowAnchor(exit),
    nodes,
    metrics,
    small_metrics,
    x + axis - exit_size.width / 2,
    body_y + body_size.height + WHILE_EXIT_GAP,
    layouts,
    edges,
  )
  let return_offset = width - axis + entry_size.width / 2
  if body_size.width == 0 || body_size.height == 0 {
    // FtileWhile.ConnectionBackEmpty connects the decision back to itself.
    let drop = body_y +
      body_size.height -
      y -
      entry_size.height +
      DIAMOND_TEXT_PADDING / 2
    append_layout_edge(
      edges,
      entry_placed.entry,
      entry_placed.entry,
      BackwardRight(return_offset, drop),
      label=enter_label,
    )
  } else {
    append_layout_edge(
      edges,
      entry_placed.entry,
      body_placed.entry,
      WhileEntry,
      label=enter_label,
    )
    let return_drop = layouts.fold(init=LOOP_BACK_GAP, (drop, node) => {
      if Some(node.node_index) == body_placed.exit {
        body_y + body_size.height - node.y - node.height + LOOP_BACK_GAP
      } else {
        drop
      }
    })
    append_layout_edge(
      edges,
      body_placed.exit,
      entry_placed.entry,
      BackwardRight(return_offset, return_drop),
      label=body_placed.outgoing_label,
    )
  }
  append_layout_edge(
    edges,
    entry_placed.entry,
    exit_placed.entry,
    WhileExitLeft(WHILE_BACK_MARGIN + entry_size.width / 2 - axis),
    label=exit_label,
  )
  {
    entry: entry_placed.entry,
    exit: exit_placed.exit,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
fn place_repeat(
  entry : Int,
  body : Array[Tile],
  exit : Int,
  retry_label : String?,
  exit_label : String?,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let entry_size = nodes[entry].size(metrics, small_metrics)
  let body_size = measure_sequence(body, nodes, metrics, small_metrics)
  let exit_size = nodes[exit].size(metrics, small_metrics)
  let (width, axis) = repeat_columns(
    entry, body, exit, retry_label, exit_label, nodes, metrics, small_metrics,
  )
  let entry_placed = place_leaf(
    entry,
    nodes,
    metrics,
    small_metrics,
    x + axis - entry_size.width / 2,
    y,
    layouts,
  )
  let body_y = y + entry_size.height + VERTICAL_GAP
  let body_placed = place_sequence(
    body,
    nodes,
    metrics,
    small_metrics,
    x + axis - sequence_axis(body, nodes, metrics, small_metrics),
    body_y,
    layouts,
    edges,
  )
  let exit_y = body_y + body_size.height + VERTICAL_GAP
  let exit_placed = place_leaf(
    exit,
    nodes,
    metrics,
    small_metrics,
    x + axis - exit_size.width / 2,
    exit_y,
    layouts,
  )
  append_layout_edge(
    edges,
    entry_placed.exit,
    body_placed.entry,
    RepeatForward,
    label=sequence_incoming_label(body, nodes),
  )
  append_layout_edge(
    edges,
    body_placed.exit,
    exit_placed.entry,
    RepeatForward,
    label=body_placed.outgoing_label,
  )
  append_layout_edge(
    edges,
    exit_placed.entry,
    entry_placed.entry,
    if swimlane_names(nodes).length() > 1 &&
      swimlane_for_node(nodes, entry) != swimlane_for_node(nodes, exit) {
      RepeatLaneBack(
        exit_size.width / 2 + body_size.width / 2 + DIAMOND_TEXT_PADDING / 2,
      )
    } else {
      RepeatBackRight(width - axis + entry_size.width / 2)
    },
    label=retry_label,
  )
  {
    entry: entry_placed.entry,
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
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let columns = measure_fork_columns(branches, nodes, metrics, small_metrics)
  let block_width = columns + FORK_COLUMN_MARGIN * 2
  let (branches_height, incoming, outgoing) = fork_rows(
    branches, nodes, metrics, small_metrics,
  )
  let branches_y = y + FORK_BAR_HEIGHT + VERTICAL_GAP + incoming
  let mut cursor_x = x
  let placed = []
  for branch in branches {
    let branch_size = fork_branch_size(branch, nodes, metrics, small_metrics)
    let column_width = branch_size.width + FORK_COLUMN_MARGIN * 2
    placed.push({
      tile: place_sequence(
        branch.tiles,
        nodes,
        metrics,
        small_metrics,
        cursor_x + FORK_COLUMN_MARGIN,
        branches_y + (branches_height - branch_size.height) / 2,
        layouts,
        edges,
      ),
      label: sequence_incoming_label(branch.tiles, nodes),
    })
    cursor_x += column_width
  }
  let exit_y = branches_y + branches_height + VERTICAL_GAP + outgoing
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
    append_layout_edge(
      edges,
      Some(entry),
      branch.tile.entry,
      Forward,
      label=branch.label,
    )
    append_layout_edge(
      edges,
      branch.tile.exit,
      Some(exit),
      Forward,
      label=branch.tile.outgoing_label,
    )
  }
  {
    entry: Some(entry),
    exit: Some(exit),
    outgoing_label: None,
    outgoing_route: Forward,
  }
}

///|
fn fork_rows(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int, Int) {
  let mut height = 0
  let mut incoming = 0
  let mut outgoing = 0
  for branch in branches {
    height = height.max(
      measure_sequence(branch.tiles, nodes, metrics, small_metrics).height,
    )
    incoming = incoming.max(
      sequence_incoming_label(branch.tiles, nodes).map_or(0, text => {
        small_metrics.measure(text).height
      }),
    )
    outgoing = outgoing.max(
      sequence_outgoing_label(branch.tiles, nodes).map_or(0, text => {
        small_metrics.measure(text).height
      }),
    )
  }
  (height, incoming, outgoing)
}

///|
fn fork_branch_size(
  branch : BranchTiles,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
  let axis = sequence_axis(branch.tiles, nodes, metrics, small_metrics)
  let incoming = sequence_incoming_label(branch.tiles, nodes).map_or(0, text => {
    EDGE_LABEL_OFFSET + small_metrics.measure(text).width
  })
  { ..body, width: body.width.max(axis + incoming), }
}

///|
fn measure_fork_columns(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut width = 0
  for index, branch in branches {
    let size = fork_branch_size(branch, nodes, metrics, small_metrics)
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
fn @flow.ActivityDiagram::layout(
  self : @flow.ActivityDiagram,
) -> ActivityLayout {
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
  let lane_names = swimlane_names(source_nodes)
  let use_swimlanes = lane_names.length() > 1
  let mut title_height = REGION_HEADER_HEIGHT
  for name in lane_names {
    title_height = title_height.max(
      metrics.measure(activity_display_text(name)).height,
    )
  }
  let top_padding = if use_swimlanes {
    CANVAS_TOP + title_height + REGION_PADDING
  } else {
    CANVAS_TOP
  }
  let _ = place_sequence(
    tiles, source_nodes, metrics, small_metrics, content_x, top_padding, layouts,
    edges,
  )
  let regions = reposition_swimlanes(
    source_nodes,
    layouts,
    edges,
    metrics,
    small_metrics,
    content.height + top_padding - CANVAS_TOP + REGION_PADDING,
  )
  for region in partition_regions(source_nodes, layouts) {
    regions.push(region)
  }
  append_goto_edges(source_nodes, layouts, edges)
  let mut result : ActivityLayout = {
    nodes: layouts,
    edges,
    regions,
    source_nodes,
    width: 0,
    height: content.height + top_padding + CANVAS_BOTTOM,
  }
  if !use_swimlanes {
    result = result.compress_x(small_metrics~)
  }
  let content_right = layout_content_right(
    result.nodes,
    result.edges,
    result.source_nodes,
    small_metrics,
  )
  let mut right = content_right
  for region in result.regions {
    right = right.max(region.x + region.width)
  }
  { ..result, width: right + CANVAS_RIGHT, }
}

///|
/// Rightmost extent of the placed content, including arrow labels and back
/// edges that stick out of the flow column.
fn layout_content_right(
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
  nodes : Array[@flow.ActivityNode],
  small_metrics : @metrics.FontMetrics,
) -> Int {
  let mut right = 0
  for layout in layouts {
    right = right.max(layout.x + layout.width)
  }
  for edge in edges {
    if edge_label_extent(edge, layouts, nodes, small_metrics) is Some(end) {
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
  nodes : Array[@flow.ActivityNode],
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
  guard from is Some(from) else { return None }
  guard to is Some(to) else { return None }
  let label_right = edge.label.map(label => {
    let (_, right) = activity_edge_label_bounds(
      edge, label, from, to, nodes, small_metrics,
    )
    right
  })
  let (_, route_right) = activity_edge_x_bounds(edge, from, to, nodes)
  Some(label_right.map_or(route_right, right => right.max(route_right)))
}

///|
/// Calculate PlantUML-style activity-diagram geometry without rendering it.
pub fn layout_activity(diagram : @flow.ActivityDiagram) -> ActivityLayout {
  diagram.layout()
}

///|
/// FtileIfDown places the main branch below the condition. Its other branch
/// either bypasses the body or terminates to the right of the condition.
fn place_if_vertical(
  branches : Array[BranchTiles],
  exit : Int,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let body_index = if_vertical_body_index(branches, nodes).unwrap()
  let branch = branches[body_index]
  let decision = branches[0].decision.unwrap()
  let decision_size = nodes[decision].size(metrics, small_metrics)
  let exit_size = if_vertical_merge_size(branches, nodes)
  let size = measure_if_vertical(branches, nodes, metrics, small_metrics)
  let (_, axis) = if_vertical_columns(branches, nodes, metrics, small_metrics)
  let center_x = x + axis
  let decision_x = center_x - decision_size.width / 2
  let entry = place_leaf(
    decision, nodes, metrics, small_metrics, decision_x, y, layouts,
  )
  let body_y = y +
    decision_size.height +
    decision_body_gap(branch.label, small_metrics)
  let body = place_sequence(
    branch.tiles,
    nodes,
    metrics,
    small_metrics,
    center_x - sequence_axis(branch.tiles, nodes, metrics, small_metrics),
    body_y,
    layouts,
    edges,
  )
  let side = branches[1 - body_index]
  let has_exit = branches.any(branch => sequence_has_exit(branch.tiles, nodes))
  let merge = if has_exit {
    place_if_merge(
      exit,
      exit_size,
      center_x,
      y + size.height - exit_size.height,
      layouts,
    )
    Some(exit)
  } else {
    None
  }
  append_layout_edge(
    edges,
    entry.exit,
    Some(body.entry.unwrap_or(exit)),
    Forward,
    label=branch.label,
  )
  append_layout_edge(
    edges,
    body.exit,
    merge,
    IfEmptyDown,
    label=body.outgoing_label,
  )
  if if_single_terminal(side.tiles, nodes) {
    let side_size = measure_sequence(side.tiles, nodes, metrics, small_metrics)
    let label_width = side.label.map_or(0, text => {
      small_metrics.measure(text).width
    })
    let side_placed = place_sequence(
      side.tiles,
      nodes,
      metrics,
      small_metrics,
      decision_x +
      decision_size.width +
      if_side_terminal_gap(side_size.width, label_width),
      y + (decision_size.height - side_size.height) / 2,
      layouts,
      edges,
    )
    append_layout_edge(
      edges,
      entry.exit,
      side_placed.entry,
      IfSideTerminal,
      label=side.label,
    )
  } else {
    append_layout_edge(
      edges,
      entry.exit,
      merge,
      IfBypassRight(x + size.width - decision_x),
      label=side.label,
    )
  }
  {
    entry: entry.entry,
    exit: merge,
    outgoing_label: None,
    outgoing_route: Forward,
  }
}
