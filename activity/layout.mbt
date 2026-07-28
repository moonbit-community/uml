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
  BackwardLeft
  BackwardRight
} derive(Eq, Debug)

///|
/// A directed connector between visible activity instructions.
pub struct ActivityEdgeLayout {
  from_node_index : Int
  to_node_index : Int
  route : ActivityEdgeRoute
} derive(Eq, Debug)

///|
/// Complete geometry emitted by the built-in activity layout stage.
pub struct ActivityLayout {
  nodes : Array[ActivityNodeLayout]
  edges : Array[ActivityEdgeLayout]
  width : Int
  height : Int
} derive(Eq, Debug)

///|
priv enum Boundary {
  ElseIf
  Else
  EndIf
  EndWhile
  RepeatWhile
  ForkAgain
  EndFork
  Case
  EndSwitch
  EndPartition
}

///|
priv enum Tile {
  Leaf(Int)
  Sequence(Array[Tile])
  Conditional(Int, Array[Array[Tile]], Int)
  WhileLoop(Int, Array[Tile])
  RepeatLoop(Int, Array[Tile], Int)
  Parallel(Int, Array[Array[Tile]], Int)
  Switch(Int, Array[Array[Tile]], Int)
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
fn node_label(node : ActivityNode) -> String? {
  match node {
    Action(label)
    | If(label)
    | While(label)
    | EndWhile(label)
    | RepeatWhile(label)
    | Switch(label)
    | Case(label)
    | Note(label) => Some(label)
    _ => None
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
fn matches_boundary(node : ActivityNode, boundary : Boundary) -> Bool {
  match (node, boundary) {
    (ElseIf(_), ElseIf)
    | (Else(_), Else)
    | (EndIf, EndIf)
    | (EndWhile(_), EndWhile)
    | (RepeatWhile(_), RepeatWhile)
    | (ForkAgain, ForkAgain)
    | (EndFork, EndFork)
    | (Case(_), Case)
    | (EndSwitch, EndSwitch)
    | (EndPartition, EndPartition) => true
    _ => false
  }
}

///|
fn at_boundary(node : ActivityNode, boundaries : Array[Boundary]) -> Bool {
  boundaries.any(boundary => matches_boundary(node, boundary))
}

///|
fn parse_flow(
  nodes : Array[ActivityNode],
  start : Int,
  boundaries : Array[Boundary],
) -> (Array[Tile], Int) {
  let tiles = []
  let mut index = start
  while index < nodes.length() {
    let node = nodes[index]
    guard !at_boundary(node, boundaries) else { break }
    match node {
      If(_) => {
        let branches = []
        let mut cursor = index + 1
        while cursor < nodes.length() {
          let (branch, next) = parse_flow(nodes, cursor, [ElseIf, Else, EndIf])
          branches.push(branch)
          guard next < nodes.length() else { break }
          match nodes[next] {
            ElseIf(_) | Else(_) => cursor = next + 1
            EndIf => {
              tiles.push(Tile::Conditional(index, branches, next))
              index = next + 1
              break
            }
            _ => ()
          }
        }
      }
      While(_) => {
        let (body, end) = parse_flow(nodes, index + 1, [EndWhile])
        if end < nodes.length() {
          tiles.push(Tile::WhileLoop(index, body))
          index = end + 1
        } else {
          tiles.push(Leaf(index))
          index += 1
        }
      }
      Repeat => {
        let (body, end) = parse_flow(nodes, index + 1, [RepeatWhile])
        if end < nodes.length() {
          tiles.push(RepeatLoop(index, body, end))
          index = end + 1
        } else {
          tiles.push(Leaf(index))
          index += 1
        }
      }
      Fork => {
        let branches = []
        let mut cursor = index + 1
        while cursor < nodes.length() {
          let (branch, next) = parse_flow(nodes, cursor, [ForkAgain, EndFork])
          branches.push(branch)
          guard next < nodes.length() else { break }
          match nodes[next] {
            ForkAgain => cursor = next + 1
            EndFork => {
              tiles.push(Parallel(index, branches, next))
              index = next + 1
              break
            }
            _ => ()
          }
        }
      }
      Switch(_) => {
        let branches = []
        let mut cursor = index + 1
        while cursor < nodes.length() {
          guard nodes[cursor] is Case(_) else { break }
          let case_index = cursor
          let (body, next) = parse_flow(nodes, cursor + 1, [Case, EndSwitch])
          branches.push([Tile::Leaf(case_index), ..body])
          guard next < nodes.length() else { break }
          match nodes[next] {
            Case(_) => cursor = next
            EndSwitch => {
              tiles.push(Switch(index, branches, next))
              index = next + 1
              break
            }
            _ => ()
          }
        }
      }
      Partition(_) => {
        let (body, end) = parse_flow(nodes, index + 1, [EndPartition])
        tiles.push(Sequence(body))
        index = if end < nodes.length() { end + 1 } else { end }
      }
      _ => {
        tiles.push(Leaf(index))
        index += 1
      }
    }
  }
  (tiles, index)
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
  branches : Array[Array[Tile]],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut height = 0
  for index, branch in branches {
    let size = measure_sequence(branch, nodes, metrics)
    if index > 0 {
      width += BRANCH_GAP
    }
    width += size.width.max(MINIMUM_ACTION_WIDTH)
    height = height.max(size.height)
  }
  { width, height }
}

///|
fn measure_tile(
  tile : Tile,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match tile {
    Leaf(index) => node_size(nodes[index], metrics)
    Sequence(tiles) => measure_sequence(tiles, nodes, metrics)
    Conditional(entry, branches, exit) | Switch(entry, branches, exit) => {
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
    WhileLoop(entry, body) => {
      let entry_size = node_size(nodes[entry], metrics)
      let body_size = measure_sequence(body, nodes, metrics)
      {
        width: entry_size.width.max(body_size.width),
        height: entry_size.height + VERTICAL_GAP + body_size.height,
      }
    }
    RepeatLoop(entry, body, exit) => {
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
) -> Unit {
  match (from_node_index, to_node_index) {
    (Some(from_node_index), Some(to_node_index)) =>
      edges.push({ from_node_index, to_node_index, route })
    _ => ()
  }
}

///|
fn nearest_layout_before(
  layouts : Array[ActivityNodeLayout],
  node_index : Int,
) -> Int? {
  let mut result = None
  for layout in layouts {
    guard layout.node_index < node_index else { continue }
    result = Some(layout.node_index)
  }
  result
}

///|
fn first_layout_after(
  layouts : Array[ActivityNodeLayout],
  node_index : Int,
) -> Int? {
  let mut result : Int? = None
  for layout in layouts {
    guard layout.node_index > node_index else { continue }
    match result {
      Some(candidate) if candidate < layout.node_index => ()
      _ => result = Some(layout.node_index)
    }
  }
  result
}

///|
fn goto_target(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
  label : String,
) -> Int? {
  for index, node in nodes {
    guard node is Label(candidate) && candidate == label else { continue }
    return first_layout_after(layouts, index)
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
      nearest_layout_before(layouts, index),
      goto_target(nodes, layouts, label),
      BackwardLeft,
    )
  }
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
  let mut previous = None
  for tile in tiles {
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
    append_layout_edge(edges, previous, placed.entry, Forward)
    if entry is None {
      entry = placed.entry
    }
    if placed.exit is Some(exit) {
      previous = Some(exit)
    }
    cursor_y += tile_size.height
  }
  { entry, exit: previous }
}

///|
fn place_branches(
  branches : Array[Array[Tile]],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  x : Int,
  y : Int,
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Array[PlacedTile] {
  let placed = []
  let mut cursor_x = x
  for branch in branches {
    let branch_size = measure_sequence(branch, nodes, metrics)
    let branch_width = branch_size.width.max(MINIMUM_ACTION_WIDTH)
    placed.push(
      place_sequence(branch, nodes, metrics, cursor_x, y, layouts, edges),
    )
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
  guard size.height > 0 else { return { entry: None, exit: None } }
  layouts.push({
    node_index: index,
    x,
    y,
    width: size.width,
    height: size.height,
  })
  { entry: Some(index), exit: Some(index) }
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
    Sequence(tiles) =>
      place_sequence(tiles, nodes, metrics, x, y, layouts, edges)
    Conditional(entry, branches, exit) | Switch(entry, branches, exit) => {
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
        append_layout_edge(edges, entry_placed.entry, branch.entry, Forward)
        append_layout_edge(edges, branch.exit, exit_placed.entry, Forward)
      }
      { entry: entry_placed.entry, exit: exit_placed.exit }
    }
    WhileLoop(entry, body) => {
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
      append_layout_edge(edges, entry_placed.entry, body_placed.entry, Forward)
      append_layout_edge(
        edges,
        body_placed.exit,
        entry_placed.entry,
        BackwardLeft,
      )
      { entry: entry_placed.entry, exit: body_placed.exit }
    }
    RepeatLoop(entry, body, exit) => {
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
      )
      { entry: entry_placed.entry, exit: exit_placed.exit }
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
        append_layout_edge(edges, entry_placed.entry, branch.entry, Forward)
        append_layout_edge(edges, branch.exit, exit_placed.entry, Forward)
      }
      { entry: entry_placed.entry, exit: exit_placed.exit }
    }
  }
}

///|
/// Lay out activity control flow as nested tiles. This follows PlantUML's
/// `InstructionIf`, `InstructionWhile`, and `InstructionFork` decomposition:
/// branches are horizontal siblings, their exits join, and loops own a back
/// edge to the controlling decision.
pub fn ActivityDiagram::layout(self : ActivityDiagram) -> ActivityLayout {
  let metrics = @metrics.FontMetrics::from_defaults()
  let (tiles, _) = parse_flow(self.nodes, 0, [])
  let content = measure_sequence(tiles, self.nodes, metrics)
  let layouts = []
  let edges = []
  let content_x = CANVAS_PADDING + LOOP_ROUTE_MARGIN
  let _ = place_sequence(
    tiles,
    self.nodes,
    metrics,
    content_x,
    CANVAS_PADDING,
    layouts,
    edges,
  )
  append_goto_edges(self.nodes, layouts, edges)
  {
    nodes: layouts,
    edges,
    width: content.width + (CANVAS_PADDING + LOOP_ROUTE_MARGIN) * 2,
    height: content.height + CANVAS_PADDING * 2,
  }
}
