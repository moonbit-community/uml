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
