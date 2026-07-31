///|
/// Geometry for one visible activity instruction.
pub struct ActivityNodeLayout {
  node_index : Int
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Debug)

///|
pub(all) enum ActivityEdgeRoute {
  Forward
  Horizontal
  Goto
  BackwardLeft
  BackwardRight
} derive(Eq, Debug)

///|
/// A directed connector between visible activity instructions.
pub struct ActivityEdgeLayout {
  from_node_index : Int
  to_node_index : Int
  route : ActivityEdgeRoute
  label : String?
} derive(Eq, Debug)

///|
pub(all) enum ActivityRegionKind {
  Partition
  Swimlane
} derive(Eq, Debug)

///|
pub struct ActivityRegionLayout {
  kind : ActivityRegionKind
  label : String
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Debug)

///|
/// Complete geometry emitted by the built-in activity layout stage.
pub struct ActivityLayout {
  nodes : Array[ActivityNodeLayout]
  edges : Array[ActivityEdgeLayout]
  regions : Array[ActivityRegionLayout]
  source_nodes : Array[ActivityNode]
  width : Int
  height : Int
} derive(Eq, Debug)

///|
priv enum Tile {
  Leaf(Int)
  LabelAnchor(Int)
  GotoAnchor(Int)
  Partition(Array[Tile])
  Swimlane(Int)
  IfChain(Array[BranchTiles], Int)
  WhileLoop(Int, Array[Tile], String?, String?)
  RepeatLoop(Int, Array[Tile], Int, String?, String?)
  Parallel(Int, Array[BranchTiles], Int)
  Switch(Int, Array[BranchTiles], Int)
}

///|
priv struct BranchTiles {
  decision : Int?
  tiles : Array[Tile]
  label : String?
}

///|
priv struct TileMeasure {
  width : Int
  height : Int
}

///|
priv struct PlacedTile {
  entry : Int?
  exit : Int?
  outgoing_label : String?
  outgoing_route : ActivityEdgeRoute
}

///|
priv struct PlacedBranch {
  tile : PlacedTile
  label : String?
}

///|
const CANVAS_PADDING : Int = 20

///|
const VERTICAL_GAP : Int = 24

///|
const BRANCH_GAP : Int = 32

///|
const LOOP_ROUTE_MARGIN : Int = 30

///|
const TEXT_PADDING_X : Int = 16

///|
const TEXT_PADDING_Y : Int = 10

///|
const MINIMUM_ACTION_WIDTH : Int = 80

///|
const MINIMUM_DECISION_WIDTH : Int = 76

///|
const DECISION_HEIGHT : Int = 46

///|
const TERMINAL_SIZE : Int = 20

///|
const FORK_WIDTH : Int = 104

///|
const FORK_HEIGHT : Int = 6

///|
const REGION_PADDING : Int = 12

///|
const REGION_HEADER_HEIGHT : Int = 24

///|
const SWIMLANE_GAP : Int = 24

///|
fn add_layout_node(nodes : Array[ActivityNode], node : ActivityNode) -> Int {
  let index = nodes.length()
  nodes.push(node)
  index
}

///|
/// Builds the layout tree from the reduced instruction tree. The emitted node
/// array contains only renderer-facing primitives; command boundaries never
/// become decision nodes merely to carry a branch label.
fn tiles_from_instructions(
  instructions : Array[ActivityInstruction],
  nodes : Array[ActivityNode],
) -> Array[Tile] {
  let tiles = []
  for instruction in instructions {
    match instruction {
      ActivityInstruction::Start =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, ActivityNode::Start)))
      ActivityInstruction::Stop =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, ActivityNode::Stop)))
      ActivityInstruction::End =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, ActivityNode::End)))
      ActivityInstruction::Kill =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, ActivityNode::Kill)))
      ActivityInstruction::Action(label) =>
        tiles.push(
          Tile::Leaf(add_layout_node(nodes, ActivityNode::Action(label))),
        )
      ActivityInstruction::Note(label) =>
        tiles.push(
          Tile::Leaf(add_layout_node(nodes, ActivityNode::Note(label))),
        )
      ActivityInstruction::Edge(label) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(
              nodes,
              ActivityNode::Arrow("-> " + label.text.unwrap_or("")),
            ),
          ),
        )
      ActivityInstruction::IfChain(chain) => {
        guard chain.branches.length() > 0 else { continue }
        let branches = []
        for branch in chain.branches {
          let decision = branch.condition.map(condition => {
            add_layout_node(nodes, ActivityNode::If(condition))
          })
          branches.push({
            decision,
            tiles: tiles_from_instructions(branch.instructions, nodes),
            label: branch.incoming.text,
          })
        }
        let exit = add_layout_node(nodes, ActivityNode::EndIf)
        tiles.push(Tile::IfChain(branches, exit))
      }
      ActivityInstruction::While(while_instruction) => {
        let entry = add_layout_node(
          nodes,
          ActivityNode::While(while_instruction.condition),
        )
        tiles.push(
          Tile::WhileLoop(
            entry,
            tiles_from_instructions(while_instruction.instructions, nodes),
            while_instruction.enter.text,
            while_instruction.exit.text,
          ),
        )
      }
      ActivityInstruction::Repeat(repeat_instruction) => {
        let entry = add_layout_node(nodes, ActivityNode::Repeat)
        let exit = add_layout_node(
          nodes,
          ActivityNode::RepeatWhile(repeat_instruction.condition),
        )
        tiles.push(
          Tile::RepeatLoop(
            entry,
            tiles_from_instructions(repeat_instruction.instructions, nodes),
            exit,
            repeat_instruction.retry.text,
            repeat_instruction.exit.text,
          ),
        )
      }
      ActivityInstruction::Fork(fork) => {
        let entry = add_layout_node(nodes, ActivityNode::Fork)
        let branches = []
        for branch in fork.branches {
          branches.push({
            decision: None,
            tiles: tiles_from_instructions(branch, nodes),
            label: None,
          })
        }
        let exit = add_layout_node(nodes, ActivityNode::EndFork)
        tiles.push(Tile::Parallel(entry, branches, exit))
      }
      ActivityInstruction::Switch(switch) => {
        let entry = add_layout_node(
          nodes,
          ActivityNode::Switch(switch.condition),
        )
        let branches = []
        for branch in switch.branches {
          branches.push({
            decision: None,
            tiles: tiles_from_instructions(branch.instructions, nodes),
            label: branch.incoming.text,
          })
        }
        let exit = add_layout_node(nodes, ActivityNode::EndSwitch)
        tiles.push(Tile::Switch(entry, branches, exit))
      }
      ActivityInstruction::Partition(partition) => {
        add_layout_node(nodes, ActivityNode::Partition(partition.label))
        |> ignore
        tiles.push(
          Tile::Partition(
            tiles_from_instructions(partition.instructions, nodes),
          ),
        )
        add_layout_node(nodes, ActivityNode::EndPartition) |> ignore
      }
      ActivityInstruction::Swimlane(name) =>
        tiles.push(
          Tile::Swimlane(add_layout_node(nodes, ActivityNode::Swimlane(name))),
        )
      ActivityInstruction::Label(name) =>
        tiles.push(
          Tile::LabelAnchor(add_layout_node(nodes, ActivityNode::Label(name))),
        )
      ActivityInstruction::Goto(name) =>
        tiles.push(
          Tile::GotoAnchor(add_layout_node(nodes, ActivityNode::Goto(name))),
        )
    }
  }
  tiles
}

///|
fn node_label(node : ActivityNode) -> String? {
  match node {
    Action(label) | Note(label) => Some(label)
    If(label) | ElseIf(label) | Switch(label) =>
      Some(test_text(label, " then "))
    While(label) => Some(test_text(label, " is"))
    RepeatWhile(label) => Some(test_text(label, " is"))
    _ => None
  }
}

///|
fn test_text(value : String, separator : String) -> String {
  match value.to_lower().find(separator) {
    Some(index) => value[:index].trim().to_owned()
    None => value
  }
}

///|
fn is_decision(node : ActivityNode) -> Bool {
  match node {
    If(_) | While(_) | EndWhile(_) | RepeatWhile(_) | Switch(_) | Case(_) =>
      true
    _ => false
  }
}

///|
fn is_fork(node : ActivityNode) -> Bool {
  match node {
    Fork | EndFork => true
    _ => false
  }
}

///|
fn node_size(
  node : ActivityNode,
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match node {
    Start | Stop | End | Kill | EndIf | Repeat | EndSwitch =>
      { width: TERMINAL_SIZE, height: TERMINAL_SIZE }
    _ if is_fork(node) => { width: FORK_WIDTH, height: FORK_HEIGHT }
    _ if is_decision(node) => {
      let label_width = node_label(node)
        .map(label => @metrics.measure_text_with(label, metrics).width)
        .unwrap_or(0)
      {
        width: (label_width + TEXT_PADDING_X * 2).max(MINIMUM_DECISION_WIDTH),
        height: DECISION_HEIGHT,
      }
    }
    Note(label) => {
      let text = @metrics.measure_text_with(label, metrics)
      {
        width: text.width + TEXT_PADDING_X * 2,
        height: text.height + TEXT_PADDING_Y * 2,
      }
    }
    Action(label) => {
      let text = @metrics.measure_text_with(label, metrics)
      {
        width: (text.width + TEXT_PADDING_X * 2).max(MINIMUM_ACTION_WIDTH),
        height: text.height + TEXT_PADDING_Y * 2,
      }
    }
    _ => { width: 0, height: 0 }
  }
}

///|
fn measure_sequence(
  tiles : Array[Tile],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut height = 0
  let mut found = false
  for tile in tiles {
    let size = measure_tile(tile, nodes, metrics)
    guard size.height > 0 else { continue }
    if found {
      height += VERTICAL_GAP
    }
    width = width.max(size.width)
    height += size.height
    found = true
  }
  { width, height }
}

///|
fn measure_branches(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut height = 0
  for index, branch in branches {
    let size = measure_sequence(branch.tiles, nodes, metrics)
    if index > 0 {
      width += BRANCH_GAP
    }
    width += size.width.max(MINIMUM_ACTION_WIDTH)
    height = height.max(size.height)
  }
  { width, height }
}

///|
fn measure_if_chain(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut decision_height = 0
  let mut body_height = 0
  for index, branch in branches {
    let body = measure_sequence(branch.tiles, nodes, metrics)
    let decision = branch.decision
      .map(index => node_size(nodes[index], metrics))
      .unwrap_or({ width: 0, height: 0 })
    if index > 0 {
      width += BRANCH_GAP
    }
    width += body.width.max(decision.width).max(MINIMUM_ACTION_WIDTH)
    decision_height = decision_height.max(decision.height)
    body_height = body_height.max(body.height)
  }
  {
    width,
    height: decision_height +
    (if body_height > 0 { VERTICAL_GAP + body_height } else { 0 }),
  }
}

///|
fn measure_tile(
  tile : Tile,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match tile {
    Leaf(index) => node_size(nodes[index], metrics)
    LabelAnchor(_) | GotoAnchor(_) => { width: 0, height: 0 }
    Partition(tiles) => measure_sequence(tiles, nodes, metrics)
    Swimlane(index) => {
      let _ = index
      { width: 0, height: 0 }
    }
    IfChain(branches, exit) => {
      let branches_size = measure_if_chain(branches, nodes, metrics)
      let exit_size = node_size(nodes[exit], metrics)
      {
        width: branches_size.width.max(exit_size.width),
        height: branches_size.height + VERTICAL_GAP + exit_size.height,
      }
    }
    Switch(entry, branches, exit) => {
      let entry_size = node_size(nodes[entry], metrics)
      let branches_size = measure_branches(branches, nodes, metrics)
      let exit_size = node_size(nodes[exit], metrics)
      {
        width: entry_size.width.max(branches_size.width).max(exit_size.width),
        height: entry_size.height +
        VERTICAL_GAP +
        branches_size.height +
        VERTICAL_GAP +
        exit_size.height,
      }
    }
    WhileLoop(entry, body, _, _) => {
      let entry_size = node_size(nodes[entry], metrics)
      let body_size = measure_sequence(body, nodes, metrics)
      {
        width: entry_size.width.max(body_size.width),
        height: entry_size.height + VERTICAL_GAP + body_size.height,
      }
    }
    RepeatLoop(entry, body, exit, _, _) => {
      let entry_size = node_size(nodes[entry], metrics)
      let body_size = measure_sequence(body, nodes, metrics)
      let exit_size = node_size(nodes[exit], metrics)
      {
        width: entry_size.width.max(body_size.width).max(exit_size.width),
        height: entry_size.height +
        VERTICAL_GAP +
        body_size.height +
        VERTICAL_GAP +
        exit_size.height,
      }
    }
    Parallel(entry, branches, exit) => {
      let entry_size = node_size(nodes[entry], metrics)
      let branches_size = measure_branches(branches, nodes, metrics)
      let exit_size = node_size(nodes[exit], metrics)
      {
        width: entry_size.width.max(branches_size.width).max(exit_size.width),
        height: entry_size.height +
        VERTICAL_GAP +
        branches_size.height +
        VERTICAL_GAP +
        exit_size.height,
      }
    }
  }
}

///|
fn append_layout_edge(
  edges : Array[ActivityEdgeLayout],
  from_node_index : Int?,
  to_node_index : Int?,
  route : ActivityEdgeRoute,
  label? : String? = None,
) -> Unit {
  match (from_node_index, to_node_index) {
    (Some(from_node_index), Some(to_node_index)) =>
      edges.push({ from_node_index, to_node_index, route, label })
    _ => ()
  }
}

///|
fn goto_target(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
  label : String,
) -> Int? {
  for index, node in nodes {
    guard node is ActivityNode::Label(candidate) && candidate == label else {
      continue
    }
    return layout_for_node(layouts, index)
  }
  None
}

///|
fn append_goto_edges(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Unit {
  for index, node in nodes {
    guard node is Goto(label) else { continue }
    append_layout_edge(
      edges,
      layout_for_node(layouts, index),
      goto_target(nodes, layouts, label),
      Goto,
    )
  }
}

///|
fn layout_for_node(
  layouts : Array[ActivityNodeLayout],
  node_index : Int,
) -> Int? {
  for layout in layouts {
    guard layout.node_index == node_index else { continue }
    return Some(node_index)
  }
  None
}

///|
fn region_for(
  layouts : Array[ActivityNodeLayout],
  kind : ActivityRegionKind,
  label : String,
  select : (ActivityNodeLayout) -> Bool,
) -> ActivityRegionLayout? {
  let mut min_x : Int? = None
  let mut min_y : Int? = None
  let mut max_x : Int? = None
  let mut max_y : Int? = None
  for layout in layouts {
    guard select(layout) else { continue }
    min_x = Some(min_x.map(value => value.min(layout.x)).unwrap_or(layout.x))
    min_y = Some(min_y.map(value => value.min(layout.y)).unwrap_or(layout.y))
    max_x = Some(
      max_x
      .map(value => value.max(layout.x + layout.width))
      .unwrap_or(layout.x + layout.width),
    )
    max_y = Some(
      max_y
      .map(value => value.max(layout.y + layout.height))
      .unwrap_or(layout.y + layout.height),
    )
  }
  match (min_x, min_y, max_x, max_y) {
    (Some(min_x), Some(min_y), Some(max_x), Some(max_y)) =>
      Some({
        kind,
        label,
        x: min_x - REGION_PADDING,
        y: min_y - REGION_HEADER_HEIGHT - REGION_PADDING,
        width: max_x - min_x + REGION_PADDING * 2,
        height: max_y - min_y + REGION_HEADER_HEIGHT + REGION_PADDING * 2,
      })
    _ => None
  }
}

///|
fn region_for_range(
  layouts : Array[ActivityNodeLayout],
  start : Int,
  end : Int,
  kind : ActivityRegionKind,
  label : String,
) -> ActivityRegionLayout? {
  region_for(
    layouts,
    kind,
    label,
    layout => layout.node_index > start && layout.node_index < end,
  )
}

///|
fn swimlane_for_node(nodes : Array[ActivityNode], node_index : Int) -> String? {
  let mut result : String? = None
  for index, node in nodes {
    guard index <= node_index else { break }
    match node {
      ActivityNode::Swimlane(name) => result = Some(name)
      _ => ()
    }
  }
  result
}

///|
fn swimlane_names(nodes : Array[ActivityNode]) -> Array[String] {
  let names = []
  for node in nodes {
    guard node is ActivityNode::Swimlane(name) else { continue }
    guard !names.contains(name) else { continue }
    names.push(name)
  }
  names
}

///|
fn swimlane_index(names : Array[String], name : String) -> Int? {
  for index, candidate in names {
    guard candidate == name else { continue }
    return Some(index)
  }
  None
}

///|
fn reposition_swimlanes(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
) -> Int {
  let names = swimlane_names(nodes)
  guard !names.is_empty() else { return 0 }
  let widths = []
  for _ in names {
    widths.push(MINIMUM_ACTION_WIDTH + REGION_PADDING * 2)
  }
  for layout in layouts {
    guard swimlane_for_node(nodes, layout.node_index) is Some(name) else {
      continue
    }
    guard swimlane_index(names, name) is Some(index) else { continue }
    widths[index] = widths[index].max(layout.width + REGION_PADDING * 2)
  }
  let positions = []
  let mut cursor_x = CANVAS_PADDING
  for width in widths {
    positions.push(cursor_x)
    cursor_x += width + SWIMLANE_GAP
  }
  for index, layout in layouts {
    guard swimlane_for_node(nodes, layout.node_index) is Some(name) else {
      continue
    }
    guard swimlane_index(names, name) is Some(lane_index) else { continue }
    layouts[index] = {
      node_index: layout.node_index,
      x: positions[lane_index] + (widths[lane_index] - layout.width) / 2,
      y: layout.y,
      width: layout.width,
      height: layout.height,
    }
  }
  cursor_x - SWIMLANE_GAP + CANVAS_PADDING
}

///|
fn region_for_swimlane(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
  label : String,
) -> ActivityRegionLayout? {
  region_for(
    layouts,
    ActivityRegionKind::Swimlane,
    label,
    layout =>
      swimlane_for_node(nodes, layout.node_index) is Some(name) && name == label,
  )
}

///|
fn regions_from_nodes(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
) -> Array[ActivityRegionLayout] {
  let regions = []
  let seen_swimlanes = []
  for index, node in nodes {
    match node {
      Swimlane(label) => {
        guard !seen_swimlanes.contains(label) else { continue }
        seen_swimlanes.push(label)
        match region_for_swimlane(nodes, layouts, label) {
          Some(region) => regions.push(region)
          None => ()
        }
      }
      Partition(label) => {
        let mut end = nodes.length()
        for next, candidate in nodes {
          guard next > index else { continue }
          guard candidate is EndPartition else { continue }
          end = next
          break
        }
        match
          region_for_range(
            layouts,
            index,
            end,
            ActivityRegionKind::Partition,
            label,
          ) {
          Some(region) => regions.push(region)
          None => ()
        }
      }
      _ => ()
    }
  }
  regions
}

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
  let size = node_size(nodes[index], metrics)
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
        match branch.decision {
          Some(decision) =>
            decision_height = decision_height.max(
              node_size(nodes[decision], metrics).height,
            )
          None => ()
        }
      }
      let body_y = y + decision_height + VERTICAL_GAP
      let placed = []
      let mut cursor_x = x + (size.width - branches_size.width) / 2
      let mut previous_decision = None
      for branch in branches {
        let body_size = measure_sequence(branch.tiles, nodes, metrics)
        let decision_size = branch.decision
          .map(index => node_size(nodes[index], metrics))
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
      let exit_size = node_size(nodes[exit], metrics)
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
      let entry_size = node_size(nodes[entry], metrics)
      let exit_size = node_size(nodes[exit], metrics)
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
      let entry_size = node_size(nodes[entry], metrics)
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
      let entry_size = node_size(nodes[entry], metrics)
      let body_size = measure_sequence(body, nodes, metrics)
      let exit_size = node_size(nodes[exit], metrics)
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
      let entry_size = node_size(nodes[entry], metrics)
      let exit_size = node_size(nodes[exit], metrics)
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
