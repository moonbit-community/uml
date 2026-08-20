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
pub extend ActivityNodeLayout with Eq::{not_equal, equal}

///|
pub extend ActivityNodeLayout with Debug::{to_repr}

///|
pub(all) enum ActivityEdgeRoute {
  Forward
  Horizontal
  Goto
  BackwardLeft
  BackwardRight
  IfDownLeft
  IfDownRight
  SwitchLeft
  SwitchRight
  SwitchMiddle
  WhileExitLeft
} derive(Eq, Debug)

///|
pub extend ActivityEdgeRoute with Eq::{not_equal, equal}

///|
pub extend ActivityEdgeRoute with Debug::{to_repr}

///|
/// A directed connector between visible activity instructions.
pub struct ActivityEdgeLayout {
  from_node_index : Int
  to_node_index : Int
  route : ActivityEdgeRoute
  label : String?
} derive(Eq, Debug)

///|
pub extend ActivityEdgeLayout with Eq::{not_equal, equal}

///|
pub extend ActivityEdgeLayout with Debug::{to_repr}

///|
pub(all) enum ActivityRegionKind {
  Partition
  Swimlane
} derive(Eq, Debug)

///|
pub extend ActivityRegionKind with Eq::{not_equal, equal}

///|
pub extend ActivityRegionKind with Debug::{to_repr}

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
pub extend ActivityRegionLayout with Eq::{not_equal, equal}

///|
pub extend ActivityRegionLayout with Debug::{to_repr}

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
pub extend ActivityLayout with Eq::{not_equal, equal}

///|
pub extend ActivityLayout with Debug::{to_repr}

///|
priv enum Tile {
  Leaf(Int)
  LabelAnchor(Int)
  GotoAnchor(Int)
  Partition(Array[Tile])
  Swimlane(Int)
  IfChain(Array[BranchTiles], Int)
  WhileLoop(Int, Array[Tile], Int, String?, String?)
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
/// Canvas margins derived from PlantUML output: content is inset 16px on the
/// left, 15px on the top and about 20px on the right and bottom.
pub const CANVAS_LEFT : Int = 16

///|
const CANVAS_TOP : Int = 15

///|
const CANVAS_RIGHT : Int = 20

///|
const CANVAS_BOTTOM : Int = 20

///|
/// Vertical gap between sequential tiles (PlantUML renders 20px).
const VERTICAL_GAP : Int = 20

///|
/// Sequential gap when the connecting arrow carries a single-line label.
/// PlantUML renders 41.28px for the first line plus the line height per
/// additional line.
const EDGE_LABEL_GAP : Int = 41

///|
const EDGE_LABEL_LINE : Int = 13

///|
/// Box padding on all four sides (skin `activity { Padding 10 }`).
const TEXT_PADDING : Int = 10

///|
/// Round-corner radius of activity boxes (skin `RoundCorner 25`).
const BOX_ROUND : Int = 12

///|
/// Diamond (decision) height: PlantUML draws a 24px-tall hexagon.
const DIAMOND_HEIGHT : Int = 24

///|
/// Horizontal padding added to a decision label inside the diamond.
const DIAMOND_TEXT_PADDING : Int = 24

///|
/// Start-circle diameter.
const TERMINAL_SIZE : Int = 20

///|
/// Stop-circle outer diameter (PlantUML `FtileCircleStop` SIZE 22).
const STOP_SIZE : Int = 22

///|
/// Stop-circle inner diameter.
const STOP_INNER : Int = 6

///|
/// Exit/merge node size (endif/endwhile diamond, 24x24).
const EXIT_SIZE : Int = 24

///|
/// Gap between the decision diamond and a branch body without a down label.
const DIAMOND_BODY_GAP : Int = 10

///|
/// Diamond-to-body gap when the branch label is drawn on the down edge.
/// PlantUML renders 32.14px.
const DOWN_LABEL_GAP : Int = 32

///|
/// Gap between a branch body bottom and the exit node.
const BODY_EXIT_GAP : Int = 6

///|
/// Minimum horizontal gap between adjacent branch columns.
const BRANCH_GAP : Int = 20

///|
/// Margin between a decision diamond's side vertex and a branch column
/// center in the two-branch (FtileIfDown) layout.
const BRANCH_DIAMOND_MARGIN : Int = 10

///|
/// Horizontal clearance of a while back edge beyond the body.
const WHILE_BACK_MARGIN : Int = 12

///|
/// While body-to-exit gap: PlantUML stacks 10px to the back-edge line,
/// 12px to the exit label line, then 20px to the exit node.
const WHILE_EXIT_GAP : Int = 42

///|
/// Fork bar height.
const FORK_BAR_HEIGHT : Int = 6

///|
/// Fork branch column margin (PlantUML `xMargin = 14`).
const FORK_COLUMN_MARGIN : Int = 14

///|
/// Gap between the switch entry diamond and the case columns.
const SWITCH_CASE_GAP : Int = 36

///|
/// Font size used for activity labels. PlantUML's skin sets `FontSize 12`
/// for the real sans-serif font; the built-in metric table is calibrated at
/// 13px, so 13 is the matching emulation size.
const ACTION_FONT : Int = 13

///|
/// Font size used for arrow, branch, and diamond labels (emulates the skin
/// `FontSize 11` with the built-in metric table).
const SMALL_FONT : Int = 12

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
        let exit = add_layout_node(nodes, ActivityNode::EndWhile(""))
        tiles.push(
          Tile::WhileLoop(
            entry,
            tiles_from_instructions(while_instruction.instructions, nodes),
            exit,
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
fn ActivityNode::label(self : ActivityNode) -> String? {
  match self {
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
  guard value.to_lower().find(separator) is Some(index) else { return value }
  value[:index].trim().to_owned()
}

///|
fn ActivityNode::is_decision(self : ActivityNode) -> Bool {
  self
  is (If(_) | While(_) | EndWhile(_) | RepeatWhile(_) | Switch(_) | Case(_))
}

///|
fn ActivityNode::is_fork(self : ActivityNode) -> Bool {
  self is (Fork | EndFork)
}

///|
fn ActivityNode::is_exit(self : ActivityNode) -> Bool {
  self is (EndIf | EndWhile(_) | EndSwitch)
}

///|
fn ActivityNode::size(
  self : ActivityNode,
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match self {
    Start => { width: TERMINAL_SIZE, height: TERMINAL_SIZE }
    Stop | End | Kill => { width: STOP_SIZE, height: STOP_SIZE }
    _ if self.is_exit() => { width: EXIT_SIZE, height: EXIT_SIZE }
    Repeat => { width: 0, height: 0 }
    _ if self.is_fork() => { width: 0, height: FORK_BAR_HEIGHT }
    _ if self.is_decision() => {
      let label_width = self
        .label()
        .map(label => small_metrics.measure(label).width)
        .unwrap_or(0)
      { width: label_width + DIAMOND_TEXT_PADDING, height: DIAMOND_HEIGHT }
    }
    Note(label) => {
      let text = metrics.measure(label)
      {
        width: text.width + TEXT_PADDING * 2,
        height: text.height + TEXT_PADDING * 2,
      }
    }
    Action(label) => {
      let text = metrics.measure(label)
      {
        width: text.width + TEXT_PADDING * 2,
        height: text.height + TEXT_PADDING * 2,
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
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut height = 0
  let mut found = false
  let mut pending_label : String? = None
  for tile in tiles {
    match tile {
      LabelAnchor(_) | GotoAnchor(_) | Swimlane(_) => continue
      Leaf(index) if nodes[index] is ActivityNode::Arrow(value) => {
        pending_label = arrow_label(value).text
        continue
      }
      _ => ()
    }
    let size = measure_tile(tile, nodes, metrics, small_metrics)
    guard size.height > 0 else { continue }
    if found {
      height += match pending_label {
        Some(label) =>
          EDGE_LABEL_GAP + EDGE_LABEL_LINE * (line_count(label) - 1)
        None => VERTICAL_GAP
      }
    }
    width = width.max(size.width)
    height += size.height
    found = true
    pending_label = None
  }
  { width, height }
}

///|
fn line_count(label : String) -> Int {
  label.split("\n").length().max(1)
}

///|
fn measure_branches(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut height = 0
  for index, branch in branches {
    let size = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    if index > 0 {
      width += BRANCH_GAP
    }
    width += size.width
    height = height.max(size.height)
  }
  { width, height }
}

///|
fn measure_if_down(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let decision = branches[0].decision.unwrap()
  let size = nodes[decision].size(metrics, small_metrics)
  let left = measure_sequence(branches[0].tiles, nodes, metrics, small_metrics)
  let right = measure_sequence(branches[1].tiles, nodes, metrics, small_metrics)
  let apart = (BRANCH_GAP + left.width / 2 + right.width / 2).max(
    size.width + BRANCH_DIAMOND_MARGIN * 2,
  )
  {
    width: apart + left.width.max(right.width),
    height: size.height +
    DIAMOND_BODY_GAP +
    left.height.max(right.height) +
    BODY_EXIT_GAP +
    EXIT_SIZE,
  }
}

///|
fn measure_if_chain(
  branches : Array[BranchTiles],
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut decision_height = 0
  let mut body_height = 0
  for index, branch in branches {
    let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    let decision = branch.decision
      .map(index => nodes[index].size(metrics, small_metrics))
      .unwrap_or({ width: 0, height: 0 })
    if index > 0 {
      width += BRANCH_GAP
    }
    width += body.width.max(decision.width)
    decision_height = decision_height.max(decision.height)
    body_height = body_height.max(body.height)
  }
  {
    width,
    height: decision_height +
    (if branches.any(branch => branch.label is Some(_)) {
      DOWN_LABEL_GAP
    } else {
      DIAMOND_BODY_GAP
    }) +
    (if body_height > 0 { body_height } else { 0 }),
  }
}

///|
fn measure_tile(
  tile : Tile,
  nodes : Array[ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match tile {
    Leaf(index) => nodes[index].size(metrics, small_metrics)
    LabelAnchor(_) | GotoAnchor(_) => { width: 0, height: 0 }
    Partition(tiles) => measure_sequence(tiles, nodes, metrics, small_metrics)
    Swimlane(index) => {
      let _ = index
      { width: 0, height: 0 }
    }
    IfChain(branches, _) if is_if_down(branches) => {
      let branches_size = measure_if_down(
        branches, nodes, metrics, small_metrics,
      )
      branches_size
    }
    IfChain(branches, exit) => {
      let branches_size = measure_if_chain(
        branches, nodes, metrics, small_metrics,
      )
      let exit_size = nodes[exit].size(metrics, small_metrics)
      {
        width: branches_size.width.max(exit_size.width),
        height: branches_size.height + BODY_EXIT_GAP + exit_size.height,
      }
    }
    Switch(entry, branches, exit) => {
      let entry_size = nodes[entry].size(metrics, small_metrics)
      let branches_size = measure_branches(
        branches, nodes, metrics, small_metrics,
      )
      let exit_size = nodes[exit].size(metrics, small_metrics)
      {
        width: entry_size.width.max(branches_size.width).max(exit_size.width),
        height: entry_size.height +
        SWITCH_CASE_GAP +
        branches_size.height +
        VERTICAL_GAP +
        exit_size.height,
      }
    }
    WhileLoop(entry, body, exit, enter_label, _) => {
      let entry_size = nodes[entry].size(metrics, small_metrics)
      let body_size = measure_sequence(body, nodes, metrics, small_metrics)
      let exit_size = nodes[exit].size(metrics, small_metrics)
      {
        width: entry_size.width.max(body_size.width).max(exit_size.width) +
        WHILE_BACK_MARGIN * 2,
        height: entry_size.height +
        (if enter_label is Some(_) { DOWN_LABEL_GAP } else { DIAMOND_BODY_GAP }) +
        body_size.height +
        WHILE_EXIT_GAP +
        exit_size.height,
      }
    }
    RepeatLoop(entry, body, exit, _, exit_label) => {
      let _ = entry
      let body_size = measure_sequence(body, nodes, metrics, small_metrics)
      let exit_size = nodes[exit].size(metrics, small_metrics)
      {
        width: body_size.width.max(exit_size.width),
        height: body_size.height +
        VERTICAL_GAP +
        exit_size.height +
        (if exit_label is Some(_) { DOWN_LABEL_GAP } else { DIAMOND_BODY_GAP }),
      }
    }
    Parallel(entry, branches, exit) => {
      let _ = entry
      let _ = exit
      let branches_width = measure_fork_columns(
        branches, nodes, metrics, small_metrics,
      )
      let branches_height = fork_branches_height(
        branches, nodes, metrics, small_metrics,
      )
      {
        width: branches_width + FORK_COLUMN_MARGIN * 2,
        height: FORK_BAR_HEIGHT +
        VERTICAL_GAP +
        branches_height +
        VERTICAL_GAP +
        FORK_BAR_HEIGHT,
      }
    }
  }
}
