///|
fn place_sequence(
  tiles : Array[Tile],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  let size = measure_sequence(tiles, nodes, metrics)
  let mut cursor_y = y
  let mut entry = None
  let mut previous : PlacedTile? = None
  let mut pending_label : String? = None
  for tile in tiles {
    match tile {
      LabelAnchor(index) | GotoAnchor(index) => {
        layouts.push({ node_index: index, x, y: cursor_y, width: 0, height: 0 })
        continue
      }
      Swimlane(index) => {
        let _ = index
        continue
      }
      Leaf(index) if nodes[index] is ActivityNode::Arrow(value) => {
        pending_label = arrow_label(value).text
        continue
      }
      _ => ()
    }
    let tile_size = measure_tile(tile, nodes, metrics)
    guard tile_size.height > 0 else { continue }
    if previous is Some(_) {
      cursor_y += VERTICAL_GAP
    }
    let placed = place_tile(
      tile,
      nodes,
      metrics,
      x + (size.width - tile_size.width) / 2,
      cursor_y,
      layouts,
      edges,
    )
    match previous {
      Some(previous) =>
        match pending_label {
          Some(label) =>
            append_layout_edge(
              edges,
              previous.exit,
              placed.entry,
              previous.outgoing_route,
              label=Some(label),
            )
          None =>
            append_layout_edge(
              edges,
              previous.exit,
              placed.entry,
              previous.outgoing_route,
              label=previous.outgoing_label,
            )
        }
      None => ()
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
    None => { entry, exit: None, outgoing_label: None, outgoing_route: Forward }
  }
}

///|
fn place_branches(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Array[PlacedBranch] {
  let placed = []
  let mut cursor_x = x
  for branch in branches {
    let branch_size = measure_sequence(branch.tiles, nodes, metrics)
    let branch_width = branch_size.width.max(MINIMUM_ACTION_WIDTH)
    placed.push({
      tile: place_sequence(
        branch.tiles,
        nodes,
        metrics,
        cursor_x,
        y,
        layouts,
        edges,
      ),
      label: branch.label,
    })
    cursor_x += branch_width + BRANCH_GAP
  }
  placed
}

///|
fn place_leaf(
  index : Int,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
) -> PlacedTile {
  let size = nodes[index].size(metrics)
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
fn place_tile(
  tile : Tile,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> PlacedTile {
  match tile {
    Leaf(index) => place_leaf(index, nodes, metrics, x, y, layouts)
    LabelAnchor(_) | GotoAnchor(_) =>
      { entry: None, exit: None, outgoing_label: None, outgoing_route: Forward }
    Partition(tiles) =>
      place_sequence(tiles, nodes, metrics, x, y, layouts, edges)
    Swimlane(index) => {
      let _ = index
      { entry: None, exit: None, outgoing_label: None, outgoing_route: Forward }
    }
    IfChain(branches, exit) => {
      let size = measure_tile(tile, nodes, metrics)
      let branches_size = measure_if_chain(branches, nodes, metrics)
      let mut decision_height = 0
      for branch in branches {
        guard branch.decision is Some(decision) else { continue }
        decision_height = decision_height.max(
          nodes[decision].size(metrics).height,
        )
      }
      let body_y = y + decision_height + VERTICAL_GAP
      let placed = []
      let mut cursor_x = x + (size.width - branches_size.width) / 2
      let mut previous_decision = None
      for branch in branches {
        let body_size = measure_sequence(branch.tiles, nodes, metrics)
        let decision_size = branch.decision
          .map(index => nodes[index].size(metrics))
          .unwrap_or({ width: 0, height: 0 })
        let branch_width = body_size.width
          .max(decision_size.width)
          .max(MINIMUM_ACTION_WIDTH)
        let decision = match branch.decision {
          Some(decision) =>
            place_leaf(
              decision,
              nodes,
              metrics,
              cursor_x + (branch_width - decision_size.width) / 2,
              y,
              layouts,
            )
          None =>
            {
              entry: None,
              exit: None,
              outgoing_label: None,
              outgoing_route: Forward,
            }
        }
        let body = place_sequence(
          branch.tiles,
          nodes,
          metrics,
          cursor_x + (branch_width - body_size.width) / 2,
          body_y,
          layouts,
          edges,
        )
        match decision.entry {
          Some(decision) => {
            append_layout_edge(
              edges,
              previous_decision,
              Some(decision),
              Horizontal,
            )
            append_layout_edge(
              edges,
              Some(decision),
              body.entry,
              Forward,
              label=branch.label,
            )
            previous_decision = Some(decision)
          }
          None =>
            append_layout_edge(
              edges,
              previous_decision,
              body.entry,
              Forward,
              label=branch.label,
            )
        }
        placed.push({ tile: body, label: branch.label })
        cursor_x += branch_width + BRANCH_GAP
      }
      let exit_size = nodes[exit].size(metrics)
      let exit_placed = place_leaf(
        exit,
        nodes,
        metrics,
        x + (size.width - exit_size.width) / 2,
        y + branches_size.height + VERTICAL_GAP,
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
    Switch(entry, branches, exit) => {
      let size = measure_tile(tile, nodes, metrics)
      let entry_size = nodes[entry].size(metrics)
      let exit_size = nodes[exit].size(metrics)
      let entry_placed = place_leaf(
        entry,
        nodes,
        metrics,
        x + (size.width - entry_size.width) / 2,
        y,
        layouts,
      )
      let branches_y = y + entry_size.height + VERTICAL_GAP
      let branches_size = measure_branches(branches, nodes, metrics)
      let branch_placed = place_branches(
        branches,
        nodes,
        metrics,
        x + (size.width - branches_size.width) / 2,
        branches_y,
        layouts,
        edges,
      )
      let exit_y = branches_y + branches_size.height + VERTICAL_GAP
      let exit_placed = place_leaf(
        exit,
        nodes,
        metrics,
        x + (size.width - exit_size.width) / 2,
        exit_y,
        layouts,
      )
      for branch in branch_placed {
        append_layout_edge(
          edges,
          entry_placed.entry,
          branch.tile.entry,
          Forward,
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
    WhileLoop(entry, body, enter_label, exit_label) => {
      let size = measure_tile(tile, nodes, metrics)
      let entry_size = nodes[entry].size(metrics)
      let body_size = measure_sequence(body, nodes, metrics)
      let entry_placed = place_leaf(
        entry,
        nodes,
        metrics,
        x + (size.width - entry_size.width) / 2,
        y,
        layouts,
      )
      let body_placed = place_sequence(
        body,
        nodes,
        metrics,
        x + (size.width - body_size.width) / 2,
        y + entry_size.height + VERTICAL_GAP,
        layouts,
        edges,
      )
      append_layout_edge(
        edges,
        entry_placed.entry,
        body_placed.entry,
        Forward,
        label=enter_label,
      )
      append_layout_edge(
        edges,
        body_placed.exit,
        entry_placed.entry,
        BackwardLeft,
      )
      {
        entry: entry_placed.entry,
        exit: entry_placed.exit,
        outgoing_label: exit_label,
        outgoing_route: BackwardLeft,
      }
    }
    RepeatLoop(entry, body, exit, retry_label, exit_label) => {
      let size = measure_tile(tile, nodes, metrics)
      let entry_size = nodes[entry].size(metrics)
      let body_size = measure_sequence(body, nodes, metrics)
      let exit_size = nodes[exit].size(metrics)
      let entry_placed = place_leaf(
        entry,
        nodes,
        metrics,
        x + (size.width - entry_size.width) / 2,
        y,
        layouts,
      )
      let body_placed = place_sequence(
        body,
        nodes,
        metrics,
        x + (size.width - body_size.width) / 2,
        y + entry_size.height + VERTICAL_GAP,
        layouts,
        edges,
      )
      let exit_placed = place_leaf(
        exit,
        nodes,
        metrics,
        x + (size.width - exit_size.width) / 2,
        y + entry_size.height + VERTICAL_GAP + body_size.height + VERTICAL_GAP,
        layouts,
      )
      append_layout_edge(edges, entry_placed.entry, body_placed.entry, Forward)
      append_layout_edge(edges, body_placed.exit, exit_placed.entry, Forward)
      append_layout_edge(
        edges,
        exit_placed.exit,
        entry_placed.entry,
        BackwardRight,
        label=retry_label,
      )
      {
        entry: entry_placed.entry,
        exit: exit_placed.exit,
        outgoing_label: exit_label,
        outgoing_route: Forward,
      }
    }
    Parallel(entry, branches, exit) => {
      let size = measure_tile(tile, nodes, metrics)
      let entry_size = nodes[entry].size(metrics)
      let exit_size = nodes[exit].size(metrics)
      let entry_placed = place_leaf(
        entry,
        nodes,
        metrics,
        x + (size.width - entry_size.width) / 2,
        y,
        layouts,
      )
      let branches_y = y + entry_size.height + VERTICAL_GAP
      let branches_size = measure_branches(branches, nodes, metrics)
      let branch_placed = place_branches(
        branches,
        nodes,
        metrics,
        x + (size.width - branches_size.width) / 2,
        branches_y,
        layouts,
        edges,
      )
      let exit_placed = place_leaf(
        exit,
        nodes,
        metrics,
        x + (size.width - exit_size.width) / 2,
        branches_y + branches_size.height + VERTICAL_GAP,
        layouts,
      )
      for branch in branch_placed {
        append_layout_edge(
          edges,
          entry_placed.entry,
          branch.tile.entry,
          Forward,
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
  }
}

///|
/// Lay out activity control flow as nested tiles. This follows PlantUML's
/// `InstructionIf`, `InstructionWhile`, and `InstructionFork` decomposition:
/// branches are horizontal siblings, their exits join, and loops own a back
/// edge to the controlling decision.
pub fn ActivityDiagram::layout(self : ActivityDiagram) -> ActivityLayout {
  let metrics = self.style.font_metrics()
  let source_nodes = []
  let tiles = tiles_from_instructions(self.instructions, source_nodes)
  let content = measure_sequence(tiles, source_nodes, metrics)
  let layouts = []
  let edges = []
  let content_x = CANVAS_PADDING + LOOP_ROUTE_MARGIN
  let top_padding = if source_nodes.any(node => {
      node is ActivityNode::Partition(_) || node is ActivityNode::Swimlane(_)
    }) {
    CANVAS_PADDING + REGION_HEADER_HEIGHT + REGION_PADDING
  } else {
    CANVAS_PADDING
  }
  let _ = place_sequence(
    tiles, source_nodes, metrics, content_x, top_padding, layouts, edges,
  )
  let swimlane_width = reposition_swimlanes(source_nodes, layouts)
  append_goto_edges(source_nodes, layouts, edges)
  let regions = regions_from_nodes(source_nodes, layouts)
  {
    nodes: layouts,
    edges,
    regions,
    source_nodes,
    width: (content.width + (CANVAS_PADDING + LOOP_ROUTE_MARGIN) * 2).max(
      swimlane_width,
    ),
    height: content.height + top_padding + CANVAS_PADDING,
  }
}
