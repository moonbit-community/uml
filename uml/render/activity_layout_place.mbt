///|
fn place_sequence(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let axis = sequence_axis(tiles, nodes, metrics, small_metrics)
  let mut cursor_y = y
  let mut entry = None
  let mut previous : PlacedTile? = None
  let mut pending_label : String?? = None
  let mut pending_style : String?? = None
  for tile in tiles {
    match tile {
      Swimlane(_) => continue
      Leaf(index) if nodes[index] is @flow.ActivityNode::Kill => {
        previous = previous.map(tile => { ..tile, exit: None, })
        continue
      }
      Leaf(index) if nodes[index] is @flow.ActivityNode::Arrow(value) => {
        pending_style = Some(@flow.arrow_label(value).style)
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
      cursor_y += sequence_gap(incoming.unwrap_or(None), small_metrics)
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
          previous.exit.map_or(false, index => nodes[index].is_parallel_bar()) ||
          placed.entry.map_or(false, index => nodes[index].is_parallel_bar())
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
        style=pending_style.unwrap_or(
          tile_incoming_style(tile, nodes).unwrap_or(previous.outgoing_style),
        ),
      )
    }
    pending_label = None
    pending_style = None
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
        outgoing_style: sequence_outgoing_style(tiles, nodes),
        outgoing_route: previous.outgoing_route,
      }
    None =>
      {
        entry,
        exit: None,
        outgoing_label: None,
        outgoing_style: None,
        outgoing_route: Forward,
      }
  }
}

///|
fn place_switch_branches(
  branches : Array[BranchTiles],
  positions : Array[Double],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Double,
  y : Double,
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
      style: sequence_incoming_style(branch.tiles, nodes).unwrap_or(
        branch.style,
      ),
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
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
) -> PlacedTile {
  let size = nodes[index].size(metrics, small_metrics)
  guard size.height > 0 else {
    return {
      entry: None,
      exit: None,
      outgoing_label: None,
      outgoing_style: None,
      outgoing_route: Forward,
    }
  }
  layouts.push({
    node_index: index,
    note_pointer_offset: None,
    x,
    y,
    width: size.width,
    height: size.height,
  })
  {
    entry: if nodes[index].is_note() {
      None
    } else {
      Some(index)
    },
    exit: if nodes[index]
      is (@flow.ActivityNode::Stop(_)
      | @flow.ActivityNode::End(_)
      | @flow.ActivityNode::Note(_)
      | @flow.ActivityNode::StyledNote(_)) {
      None
    } else {
      Some(index)
    },
    outgoing_label: None,
    outgoing_style: None,
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
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  match tile {
    LoopWithBackward(body, backward, entry, exit, spec) =>
      place_loop_backward(
        body, backward, entry, exit, spec, nodes, metrics, small_metrics, x, y, layouts,
        edges,
      )
    LoopWithBreaks(body, breaks, target, repeat) =>
      place_loop_breaks(
        body, breaks, target, repeat, nodes, metrics, small_metrics, x, y, layouts,
        edges,
      )
    Leaf(index) =>
      place_leaf(index, nodes, metrics, small_metrics, x, y, layouts)
    Noted(body, notes) =>
      place_noted(
        body, notes, nodes, metrics, small_metrics, x, y, layouts, edges,
      )
    FlowAnchor(index) | GotoAnchor(index) => {
      layouts.push({
        node_index: index,
        note_pointer_offset: None,
        x,
        y,
        width: 0,
        height: 0,
      })
      {
        entry: Some(index),
        exit: if tile is GotoAnchor(_) ||
          nodes[index] is @flow.ActivityNode::Break {
          None
        } else {
          Some(index)
        },
        outgoing_label: None,
        outgoing_style: None,
        outgoing_route: Forward,
      }
    }
    Partition(index, tiles, end) => {
      let size = measure_tile(tile, nodes, metrics, small_metrics)
      let inner_width = activity_group_inner_width(
        tiles, nodes, metrics, small_metrics,
      )
      let title = activity_partition_title(nodes[index], metrics)
      layouts.push({
        node_index: index,
        note_pointer_offset: None,
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
        x + (size.width - inner_width) / 2 + ACTIVITY_GROUP_MARGIN,
        y + partition_header_height(title.height),
        layouts,
        edges,
      )
      if placed.entry is None && sequence_has_exit(tiles, nodes) {
        layouts.push({
          node_index: end,
          note_pointer_offset: None,
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
        outgoing_style: None,
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
  x : Double,
  y : Double,
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
    style=sequence_incoming_style(branches[0].tiles, nodes).unwrap_or(
      branches[0].style,
    ),
  )
  append_layout_edge(
    edges,
    decision_placed.entry,
    right_body.entry,
    IfDownRight,
    label=branches[1].label,
    style=sequence_incoming_style(branches[1].tiles, nodes).unwrap_or(
      branches[1].style,
    ),
  )
  append_layout_edge(
    edges,
    left_body.exit,
    merge,
    IfEmptyDown,
    label=left_body.outgoing_label,
    style=left_body.outgoing_style,
  )
  append_layout_edge(
    edges,
    right_body.exit,
    merge,
    IfEmptyDown,
    label=right_body.outgoing_label,
    style=right_body.outgoing_style,
  )
  {
    entry: decision_placed.entry,
    exit: merge,
    outgoing_label: None,
    outgoing_style: None,
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
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let branches_size = measure_if_chain(branches, nodes, metrics, small_metrics)
  let mut decision_height = 0.0
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
        style=sequence_incoming_style(branch.tiles, nodes).unwrap_or(
          branch.style,
        ),
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
        style=sequence_incoming_style(branch.tiles, nodes).unwrap_or(
          branch.style,
        ),
      )
    }
    placed.push({
      tile: body,
      label: branch.label,
      style: sequence_incoming_style(branch.tiles, nodes).unwrap_or(
        branch.style,
      ),
    })
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
      style=branch.tile.outgoing_style,
    )
  }
  {
    entry: branches[0].decision,
    exit: merge,
    outgoing_label: None,
    outgoing_style: None,
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
) -> Double {
  let mut height = 0.0
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
  x : Double,
  y : Double,
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
      style=branch.style,
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
      style=branch.tile.outgoing_style,
    )
  }
  {
    entry: entry_placed.entry,
    exit: merge,
    outgoing_label: None,
    outgoing_style: None,
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
  x : Double,
  y : Double,
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
      style=sequence_incoming_style(body, nodes).unwrap_or(None),
    )
  } else {
    append_layout_edge(
      edges,
      entry_placed.entry,
      body_placed.entry,
      WhileEntry,
      label=enter_label,
      style=sequence_incoming_style(body, nodes).unwrap_or(None),
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
      style=body_placed.outgoing_style,
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
    outgoing_style: None,
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
  x : Double,
  y : Double,
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
    style=body_placed.outgoing_style,
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
    outgoing_style: None,
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
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let columns = measure_fork_columns(branches, nodes, metrics, small_metrics)
  let block_width = columns + FORK_COLUMN_MARGIN * 2
  let (branches_height, incoming, outgoing) = fork_rows(
    branches, nodes, metrics, small_metrics,
  )
  let bar_height = parallel_bar_height(nodes[entry])
  let has_exit = !(nodes[entry] is @flow.ActivityNode::Split) ||
    branches.any(branch => sequence_has_exit(branch.tiles, nodes))
  let branches_y = y + bar_height + VERTICAL_GAP + incoming
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
      style: sequence_incoming_style(branch.tiles, nodes).unwrap_or(
        branch.style,
      ),
    })
    cursor_x += column_width
  }
  let merge = nodes[exit] is @flow.ActivityNode::EndMerge(_)
  let exit_y = branches_y + branches_height + VERTICAL_GAP + outgoing
  layouts.push({
    node_index: entry,
    note_pointer_offset: None,
    x,
    y,
    width: block_width,
    height: bar_height,
  })
  if has_exit {
    layouts.push({
      node_index: exit,
      note_pointer_offset: None,
      x: if merge {
        x + (block_width - EXIT_SIZE) / 2
      } else {
        x
      },
      y: exit_y,
      width: if merge {
        EXIT_SIZE
      } else {
        block_width
      },
      height: if merge {
        EXIT_SIZE
      } else {
        bar_height
      },
    })
  }
  for branch in placed {
    append_layout_edge(
      edges,
      Some(entry),
      branch.tile.entry,
      Forward,
      label=branch.label,
      style=branch.style,
    )
    append_layout_edge(
      edges,
      branch.tile.exit,
      if has_exit {
        Some(exit)
      } else {
        None
      },
      if merge {
        ForkMerge
      } else {
        Forward
      },
      label=branch.tile.outgoing_label,
      style=branch.tile.outgoing_style,
    )
  }
  {
    entry: Some(entry),
    exit: if has_exit {
      Some(exit)
    } else {
      None
    },
    outgoing_label: None,
    outgoing_style: None,
    outgoing_route: Forward,
  }
}

///|
fn fork_rows(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> (Double, Double, Double) {
  let mut height = 0.0
  let mut incoming = 0.0
  let mut outgoing = 0.0
  for branch in branches {
    height = height.max(
      measure_sequence(branch.tiles, nodes, metrics, small_metrics).height,
    )
    incoming = incoming.max(
      sequence_incoming_label(branch.tiles, nodes).map_or(0.0, text => {
        activity_measure(small_metrics, text).height
      }),
    )
    outgoing = outgoing.max(
      sequence_outgoing_label(branch.tiles, nodes).map_or(0.0, text => {
        activity_measure(small_metrics, text).height
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
  let incoming = sequence_incoming_label(branch.tiles, nodes).map_or(0.0, text => {
    EDGE_LABEL_OFFSET + activity_measure(small_metrics, text).width
  })
  let outgoing = sequence_outgoing_label(branch.tiles, nodes).map_or(0.0, text => {
    EDGE_LABEL_OFFSET + activity_measure(small_metrics, text).width
  })
  { ..body, width: body.width.max(axis + incoming.max(outgoing)), }
}

///|
fn measure_fork_columns(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Double {
  let mut width = 0.0
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
  let metrics = activity_font_metrics(style, false)
  let small_metrics = activity_font_metrics(style, true)
  let source_nodes = []
  let tiles = tiles_from_instructions(self.instructions, source_nodes)
  let content = measure_sequence(tiles, source_nodes, metrics, small_metrics)
  let layouts = []
  let edges = []
  let content_x = CANVAS_LEFT
  let lane_names = swimlane_names(source_nodes)
  let use_swimlanes = lane_names.length() > 1
  let lane_metrics = activity_role_metrics(style, "Swimlane", 18)
  let mut title_height = REGION_HEADER_HEIGHT
  for name in lane_names {
    title_height = title_height.max(
      activity_measure(
        lane_metrics,
        activity_display_text(
          activity_lane(source_nodes, name).label.unwrap_or(name),
        ),
      ).height,
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
    lane_metrics,
    small_metrics,
    content.height + top_padding - CANVAS_TOP + REGION_PADDING,
  )
  for region in partition_regions(source_nodes, layouts) {
    regions.push(region)
  }
  append_goto_edges(source_nodes, layouts, edges)
  let separation = style
    .property("ColorArrowSeparationSpace")
    .map_or(0.0, value => @string.parse_double(value) catch { _ => 0.0 })
  for index, edge in edges {
    edges[index] = { ..edge, rainbow_separation: separation, }
  }
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
) -> Double {
  let mut right = 0.0
  for layout in layouts {
    right = right.max(
      activity_node_drawn_right(nodes[layout.node_index], layout, small_metrics),
    )
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
) -> Double? {
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
  x : Double,
  y : Double,
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
    style=sequence_incoming_style(branch.tiles, nodes).unwrap_or(branch.style),
  )
  append_layout_edge(
    edges,
    body.exit,
    merge,
    IfEmptyDown,
    label=body.outgoing_label,
    style=body.outgoing_style,
  )
  if if_single_terminal(side.tiles, nodes) {
    let side_size = measure_sequence(side.tiles, nodes, metrics, small_metrics)
    let label_width = side.label.map_or(0.0, text => {
      activity_measure(small_metrics, text).width
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
      style=sequence_incoming_style(side.tiles, nodes).unwrap_or(None),
    )
  } else {
    append_layout_edge(
      edges,
      entry.exit,
      merge,
      IfBypassRight(x + size.width - decision_x),
      label=side.label,
      style=sequence_incoming_style(side.tiles, nodes).unwrap_or(None),
    )
  }
  {
    entry: entry.entry,
    exit: merge,
    outgoing_label: None,
    outgoing_style: None,
    outgoing_route: Forward,
  }
}

///|
/// FtileFactoryDelegatorRepeat assembles an extra exit diamond and a shared
/// left corridor; while welding points join the existing left exit corridor.
fn place_loop_breaks(
  body : Tile,
  breaks : Array[Int],
  target : Int,
  repeat : Bool,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let margin = if repeat { REPEAT_SIDE_CLEARANCE } else { 0 }
  let placed = place_tile(
    body,
    nodes,
    metrics,
    small_metrics,
    x + margin,
    y,
    layouts,
    edges,
  )
  if repeat {
    let size = measure_tile(body, nodes, metrics, small_metrics)
    let axis = tile_axis(body, nodes, metrics, small_metrics) + margin
    let finish = place_leaf(
      target,
      nodes,
      metrics,
      small_metrics,
      x + axis - EXIT_SIZE / 2,
      y + size.height + VERTICAL_GAP,
      layouts,
    )
    append_layout_edge(
      edges,
      placed.exit,
      finish.entry,
      Forward,
      label=placed.outgoing_label,
      style=placed.outgoing_style,
    )
  }
  let target_x = layouts[layouts
    .search_by(node => node.node_index == target)
    .unwrap()].x
  let corridor = x + (if repeat { 0 } else { DIAMOND_TEXT_PADDING / 2 })
  for index, point in breaks {
    append_layout_edge(
      edges,
      Some(point),
      Some(target),
      BreakLeft(corridor - target_x, repeat && index == 0),
    )
  }
  {
    ..placed,
    exit: Some(target),
    outgoing_label: if repeat {
      None
    } else {
      placed.outgoing_label
    },
    outgoing_style: if repeat {
      None
    } else {
      placed.outgoing_style
    },
  }
}

///|
/// FtileWhile/FtileRepeat put the backward activity at the right edge, centered
/// vertically; the upward return traverses its bottom and top contacts.
fn place_loop_backward(
  body : Tile,
  backward : Int,
  entry : Int,
  exit : Int,
  spec : @flow.ActivityBackward,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  x : Double,
  y : Double,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let start = edges.length()
  let placed = place_tile(
    body, nodes, metrics, small_metrics, x, y, layouts, edges,
  )
  let size = measure_tile(body, nodes, metrics, small_metrics)
  let backward_size = nodes[backward].size(metrics, small_metrics)
  let _ = place_leaf(
    backward,
    nodes,
    metrics,
    small_metrics,
    x + size.width,
    y + (size.height - backward_size.height) / 2,
    layouts,
  )
  let repeat = nodes[exit] is @flow.ActivityNode::RepeatWhile(_)
  for index in start..<edges.length() {
    let edge = edges[index]
    guard edge.to_node_index == entry &&
      edge.route is (BackwardRight(_) | RepeatBackRight(_) | RepeatLaneBack(_)) else {
      continue
    }
    let drop = match edge.route {
      BackwardRight(_, drop) => drop
      _ => 0
    }
    edges[index] = {
      ..edge,
      to_node_index: backward,
      route: BackwardActionIn(repeat, drop),
      label: spec.incoming.text.map_or(edge.label, value => {
        Some(activity_display_text(value))
      }),
      style: spec.incoming.style.map_or(edge.style, value => Some(value)),
    }
    append_layout_edge(
      edges,
      Some(backward),
      Some(entry),
      BackwardActionOut,
      label=spec.outgoing.text.map(activity_display_text),
      style=spec.outgoing.style,
    )
    break
  }
  placed
}
