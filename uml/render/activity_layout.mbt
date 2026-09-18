///|
/// Geometry for one visible activity instruction.
pub(all) struct ActivityNodeLayout {
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
  ForkLane(Int, Int)
  ForkSequence
  ForkSequencePorts(Int, Int)
  Horizontal
  Goto
  BackwardLeft
  BackwardRight(Int, Int)
  RepeatBackRight(Int)
  RepeatLaneBack(Int)
  RepeatForward
  IfDownLeft
  IfDownRight
  IfSideTerminal
  IfBypassRight(Int)
  IfEmptyDown
  IfChainMerge
  SwitchLeft
  SwitchRight
  SwitchMiddle
  SwitchSideMerge
  WhileExitLeft(Int)
  WhileEntry
} derive(Eq, Debug)

///|
pub extend ActivityEdgeRoute with Eq::{not_equal, equal}

///|
pub extend ActivityEdgeRoute with Debug::{to_repr}

///|
/// A directed connector between visible activity instructions.
pub(all) struct ActivityEdgeLayout {
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
pub(all) struct ActivityRegionLayout {
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
pub(all) struct ActivityLayout {
  nodes : Array[ActivityNodeLayout]
  edges : Array[ActivityEdgeLayout]
  regions : Array[ActivityRegionLayout]
  source_nodes : Array[@flow.ActivityNode]
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
  Noted(Tile, Array[Int])
  FlowAnchor(Int)
  GotoAnchor(Int)
  Partition(Int, Array[Tile], Int)
  Swimlane
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
/// Snake places a vertical connector's label beside its flow axis.
const EDGE_LABEL_OFFSET : Int = 4

///|
/// Box padding on all four sides (skin `activity { Padding 10 }`).
const TEXT_PADDING : Int = 10

///|
/// Round-corner radius of activity boxes (skin `RoundCorner 25`).
const BOX_ROUND : Int = 12

///|
/// Minimum decision height; taller labels expand the hexagon.
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
/// FtileCircleEndCross.SIZE and its internal cross stroke.
const END_SIZE : Int = 20

///|
const END_CROSS_STROKE : Double = 2.5

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
/// Clearance below the loop body before the return edge turns outward.
const LOOP_BACK_GAP : Int = 10

///|
/// The vertical route line a `BackwardLeft` edge loops
/// through, left of both nodes.
///
/// The SVG path, the label extent, and the compression pass all derive this
/// x; keep it here instead of re-deriving `from.x.min(to.x)` per file.
fn backward_left_route_x(
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
) -> Int {
  from.x.min(to.x) - WHILE_BACK_MARGIN
}

///|
/// While body-to-port gap: the reference SVG places the return line first,
/// then the exit turn; the following sequence owns its own vertical gap.
const WHILE_EXIT_GAP : Int = LOOP_BACK_GAP + WHILE_BACK_MARGIN

///|
/// Fork bar height.
const FORK_BAR_HEIGHT : Int = 6

///|
/// Fork branch column margin (PlantUML `xMargin = 14`).
const FORK_COLUMN_MARGIN : Int = 14

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
fn add_layout_node(
  nodes : Array[@flow.ActivityNode],
  node : @flow.ActivityNode,
) -> Int {
  let index = nodes.length()
  nodes.push(node)
  index
}

///|
/// Builds the layout tree from the reduced instruction tree. The emitted node
/// array contains only renderer-facing primitives; command boundaries never
/// become decision nodes merely to carry a branch label.
fn tiles_from_instructions(
  instructions : Array[@flow.ActivityInstruction],
  nodes : Array[@flow.ActivityNode],
) -> Array[Tile] {
  let tiles = []
  for instruction in instructions {
    match instruction {
      @flow.ActivityInstruction::Start =>
        tiles.push(
          Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::Start)),
        )
      @flow.ActivityInstruction::Stop =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::Stop)))
      @flow.ActivityInstruction::End =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::End)))
      @flow.ActivityInstruction::Kill =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::Kill)))
      @flow.ActivityInstruction::Action(label) =>
        tiles.push(
          Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::Action(label))),
        )
      @flow.ActivityInstruction::Note(label, side) => {
        let index = add_layout_node(
          nodes,
          @flow.ActivityNode::Note(label, side),
        )
        attach_activity_note(tiles, nodes, index)
      }
      @flow.ActivityInstruction::Edge(label) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(
              nodes,
              @flow.ActivityNode::Arrow("-> " + label.text.unwrap_or("") + ";"),
            ),
          ),
        )
      @flow.ActivityInstruction::IfChain(chain) => {
        guard chain.branches.length() > 0 else { continue }
        // Conditions and the merge belong to the chain's entry swimlane.
        // Allocate them before branch-local swimlane changes enter the stream.
        let decisions = chain.branches.map(branch => {
          branch.condition.map(condition => {
            add_layout_node(nodes, @flow.ActivityNode::If(condition))
          })
        })
        let exit = add_layout_node(nodes, @flow.ActivityNode::EndIf)
        let is_long = decisions.filter(decision => decision is Some(_)).length() >
          1
        let branches = chain.branches.mapi((index, branch) => {
          let tiles = tiles_from_instructions(branch.instructions, nodes)
          let label = sequence_incoming_label(tiles, nodes).map_or(
            branch.incoming.text.map(activity_display_text),
            label => Some(label),
          )
          if is_long && sequence_is_empty(tiles, nodes) {
            tiles.push(
              FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::EndIf)),
            )
          }
          { decision: decisions[index], tiles, label, }
        })
        if branches[branches.length() - 1].decision is Some(_) {
          let tiles = if is_long {
            [FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::EndIf))]
          } else {
            []
          }
          branches.push({ decision: None, tiles, label: None, })
        }
        // ConditionalBuilder keeps two empty branches in the two-column layout.
        if !is_long &&
          branches.all(branch => sequence_is_empty(branch.tiles, nodes)) {
          for branch in branches {
            branch.tiles.push(
              FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::EndIf)),
            )
          }
        }
        tiles.push(Tile::IfChain(branches, exit))
      }
      @flow.ActivityInstruction::While(while_instruction) => {
        let entry = add_layout_node(
          nodes,
          @flow.ActivityNode::While(while_instruction.condition),
        )
        let exit = add_layout_node(nodes, @flow.ActivityNode::EndWhile(""))
        tiles.push(
          Tile::WhileLoop(
            entry,
            tiles_from_instructions(while_instruction.instructions, nodes),
            exit,
            while_instruction.enter.text.map(activity_display_text),
            while_instruction.exit.text.map(activity_display_text),
          ),
        )
      }
      @flow.ActivityInstruction::Repeat(repeat_instruction) => {
        let entry = add_layout_node(nodes, @flow.ActivityNode::Repeat)
        let body = tiles_from_instructions(
          repeat_instruction.instructions,
          nodes,
        )
        // FtileEmpty preserves separate entry and exit links in an empty repeat.
        if sequence_is_empty(body, nodes) {
          body.push(
            FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::EndWhile(""))),
          )
        }
        let exit = add_layout_node(
          nodes,
          @flow.ActivityNode::RepeatWhile(repeat_instruction.condition),
        )
        tiles.push(
          Tile::RepeatLoop(
            entry,
            body,
            exit,
            repeat_instruction.retry.text.map(activity_display_text),
            repeat_instruction.exit.text.map(activity_display_text),
          ),
        )
      }
      @flow.ActivityInstruction::Fork(fork) => {
        let entry = add_layout_node(nodes, @flow.ActivityNode::Fork)
        let branches = fork.branches.map(branch => {
          let tiles = tiles_from_instructions(branch, nodes)
          if sequence_is_empty(tiles, nodes) {
            tiles.push(
              FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::ForkAgain)),
            )
          }
          { decision: None, tiles, label: None, }
        })
        let exit = add_layout_node(nodes, @flow.ActivityNode::EndFork)
        tiles.push(Tile::Parallel(entry, branches, exit))
      }
      @flow.ActivityInstruction::Switch(switch) => {
        let entry = add_layout_node(
          nodes,
          @flow.ActivityNode::Switch(switch.condition),
        )
        let exit = add_layout_node(nodes, @flow.ActivityNode::EndSwitch)
        let branches = switch.branches.map(branch => {
          let tiles = tiles_from_instructions(branch.instructions, nodes)
          let label = sequence_incoming_label(tiles, nodes).map_or(
            branch.incoming.text.map(activity_display_text),
            label => Some(label),
          )
          // InstructionList.createFtile preserves an empty branch as FtileEmpty.
          if sequence_is_empty(tiles, nodes) {
            tiles.push(
              FlowAnchor(
                add_layout_node(
                  nodes,
                  @flow.ActivityNode::Case(label.unwrap_or("")),
                ),
              ),
            )
          }
          { decision: None, tiles, label, }
        })
        tiles.push(Tile::Switch(entry, branches, exit))
      }
      @flow.ActivityInstruction::Partition(partition) => {
        let index = add_layout_node(
          nodes,
          @flow.ActivityNode::Partition(partition.label),
        )
        let body = tiles_from_instructions(partition.instructions, nodes)
        let end = add_layout_node(nodes, @flow.ActivityNode::EndPartition)
        tiles.push(Tile::Partition(index, body, end))
      }
      @flow.ActivityInstruction::Swimlane(name) => {
        add_layout_node(nodes, @flow.ActivityNode::Swimlane(name)) |> ignore
        tiles.push(Tile::Swimlane)
      }
      @flow.ActivityInstruction::Label(name) =>
        tiles.push(
          Tile::FlowAnchor(
            add_layout_node(nodes, @flow.ActivityNode::Label(name)),
          ),
        )
      @flow.ActivityInstruction::Goto(name) =>
        tiles.push(
          Tile::GotoAnchor(
            add_layout_node(nodes, @flow.ActivityNode::Goto(name)),
          ),
        )
    }
  }
  tiles
}

///|
/// Arrow and swimlane declarations decorate the flow without adding an instruction.
fn tile_is_flow_decoration(
  tile : Tile,
  nodes : Array[@flow.ActivityNode],
) -> Bool {
  match tile {
    Swimlane => true
    Leaf(index) => nodes[index] is @flow.ActivityNode::Arrow(_)
    _ => false
  }
}

///|
fn sequence_is_empty(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> Bool {
  tiles.all(tile => tile_is_flow_decoration(tile, nodes))
}

///|
fn activity_display_text(value : String) -> String {
  value.replace_all(old="\\n", new="\n")
}

///|
fn @flow.ActivityNode::label(self : @flow.ActivityNode) -> String? {
  match self {
    Action(label)
    | Note(label, _)
    | Partition(label)
    | Swimlane(label)
    | If(label)
    | ElseIf(label)
    | Switch(label)
    | While(label)
    | RepeatWhile(label) => Some(activity_display_text(label))
    _ => None
  }
}

///|
fn @flow.ActivityNode::is_decision(self : @flow.ActivityNode) -> Bool {
  self is (If(_) | While(_) | Repeat | RepeatWhile(_) | Switch(_))
}

///|
fn @flow.ActivityNode::is_fork(self : @flow.ActivityNode) -> Bool {
  self is (Fork | EndFork)
}

///|
fn @flow.ActivityNode::is_exit(self : @flow.ActivityNode) -> Bool {
  self is (EndIf | EndSwitch)
}

///|
fn @flow.ActivityNode::size(
  self : @flow.ActivityNode,
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match self {
    Start => { width: TERMINAL_SIZE, height: TERMINAL_SIZE, }
    Stop => { width: STOP_SIZE, height: STOP_SIZE, }
    End => { width: END_SIZE, height: END_SIZE, }
    Kill => { width: 0, height: 0, }
    _ if self.is_exit() => { width: EXIT_SIZE, height: EXIT_SIZE, }
    Repeat => { width: EXIT_SIZE, height: EXIT_SIZE, }
    _ if self.is_fork() => { width: 0, height: FORK_BAR_HEIGHT, }
    _ if self.is_decision() => {
      let text = small_metrics.measure(self.label().unwrap_or(""))
      {
        width: if text.width == 0 {
          DIAMOND_TEXT_PADDING
        } else {
          text.width.max(DIAMOND_TEXT_PADDING) + DIAMOND_TEXT_PADDING
        },
        height: text.height.max(DIAMOND_HEIGHT),
      }
    }
    Note(_, _) | Action(_) => {
      let text = metrics.measure(self.label().unwrap())
      {
        width: text.width + TEXT_PADDING * 2,
        height: text.height + TEXT_PADDING * 2,
      }
    }
    _ => { width: 0, height: 0, }
  }
}

///|
fn measure_sequence(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut left = 0
  let mut right = 0
  let mut height = 0
  let mut found = false
  let mut pending_label : String?? = None
  let mut outgoing_label : String? = None
  for tile in tiles {
    match tile {
      Swimlane(_) => continue
      Leaf(index) if nodes[index] is @flow.ActivityNode::Arrow(value) => {
        pending_label = Some(
          @flow.arrow_label(value).text.map(activity_display_text),
        )
        continue
      }
      _ => ()
    }
    let size = measure_tile(tile, nodes, metrics, small_metrics)
    guard size.height > 0 || tile is (FlowAnchor(_) | GotoAnchor(_)) else {
      continue
    }
    let incoming = pending_label.map_or(tile_incoming_override(tile, nodes), label => {
      Some(label)
    })
    let label = incoming.unwrap_or(outgoing_label)
    if found {
      height += sequence_gap(incoming.unwrap_or(None))
      if label is Some(label) {
        right = right.max(
          EDGE_LABEL_OFFSET + small_metrics.measure(label).width,
        )
      }
    }
    let axis = tile_axis(tile, nodes, metrics, small_metrics)
    left = left.max(axis)
    right = right.max(size.width - axis)
    height += size.height
    found = true
    outgoing_label = sequence_outgoing_label([tile], nodes)
    pending_label = None
  }
  if found && sequence_outgoing_label(tiles, nodes) is Some(label) {
    right = right.max(EDGE_LABEL_OFFSET + small_metrics.measure(label).width)
  }
  { width: left + right, height, }
}

///|
/// InstructionList.decorateOut makes the final explicit arrow override the
/// nested tile's outgoing label; notes and partitions preserve that boundary.
fn sequence_outgoing_label(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> String? {
  guard sequence_has_exit(tiles, nodes) else { return None }
  for index = tiles.length() - 1; index >= 0; index = index - 1 {
    match tiles[index] {
      Swimlane(_) => continue
      Leaf(node) if nodes[node] is @flow.ActivityNode::Arrow(value) =>
        return @flow.arrow_label(value).text.map(activity_display_text)
      RepeatLoop(_, _, _, _, label) => return label
      Partition(_, body, _) => return sequence_outgoing_label(body, nodes)
      Noted(body, _) => return sequence_outgoing_label([body], nodes)
      _ => return None
    }
  }
  None
}

///|
/// The outer option distinguishes an absent arrow from an explicit empty label.
fn sequence_incoming_override(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> String?? {
  let mut pending : String?? = None
  for tile in tiles {
    match tile {
      Swimlane(_) => continue
      Leaf(index) if nodes[index] is @flow.ActivityNode::Arrow(value) =>
        pending = Some(@flow.arrow_label(value).text.map(activity_display_text))
      _ => {
        guard pending is None else { return pending }
        return tile_incoming_override(tile, nodes)
      }
    }
  }
  pending
}

///|
fn tile_incoming_override(
  tile : Tile,
  nodes : Array[@flow.ActivityNode],
) -> String?? {
  match tile {
    Partition(_, body, _) => sequence_incoming_override(body, nodes)
    Noted(body, _) => tile_incoming_override(body, nodes)
    _ => None
  }
}

///|
fn sequence_incoming_label(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> String? {
  sequence_incoming_override(tiles, nodes).unwrap_or(None)
}

///|
fn line_count(label : String) -> Int {
  label.split("\n").length().max(1)
}

///|
/// Shared by measurement and placement so sequential tiles reserve exactly
/// the space their connecting label needs, independently of node indices.
fn sequence_gap(label : String?) -> Int {
  label.map_or(VERTICAL_GAP, label => {
    EDGE_LABEL_GAP + EDGE_LABEL_LINE * (line_count(label) - 1)
  })
}

///|
fn measure_if_down(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let decision = branches[0].decision.unwrap()
  let size = nodes[decision].size(metrics, small_metrics)
  let left = measure_sequence(branches[0].tiles, nodes, metrics, small_metrics)
  let right = measure_sequence(branches[1].tiles, nodes, metrics, small_metrics)
  let (width, _, _, _) = if_columns(branches, nodes, metrics, small_metrics)
  {
    width,
    height: if_side_label_padding(branches, size.height, small_metrics) +
    size.height +
    DIAMOND_BODY_GAP +
    left.height.max(right.height) +
    (if branches.any(branch => sequence_has_exit(branch.tiles, nodes)) {
      BODY_EXIT_GAP + if_merge_size(branches, nodes).height
    } else {
      0
    }),
  }
}

///|
fn measure_if_chain(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let mut width = 0
  let mut decision_height = 0
  let mut body_height = 0
  for index, branch in branches {
    let body = measure_sequence(branch.tiles, nodes, metrics, small_metrics)
    let decision = branch.decision.map_or(
      ({ width: 0, height: 0, } : TileMeasure),
      index => nodes[index].size(metrics, small_metrics),
    )
    if index > 0 {
      width += BRANCH_GAP
    }
    let (column_width, _) = if_chain_column(
      branch, nodes, metrics, small_metrics,
    )
    width += column_width
    decision_height = decision_height.max(decision.height)
    body_height = body_height.max(body.height)
  }
  {
    width,
    height: decision_height +
    if_chain_body_gap(branches, small_metrics) +
    (if body_height > 0 { body_height } else { 0 }),
  }
}

///|
fn measure_tile(
  tile : Tile,
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match tile {
    Leaf(index) => nodes[index].size(metrics, small_metrics)
    Noted(body, notes) => {
      let body_size = measure_tile(body, nodes, metrics, small_metrics)
      let (left, right) = measure_note_columns(
        notes, nodes, metrics, small_metrics,
      )
      {
        width: body_size.width + left.width + right.width,
        height: body_size.height.max(left.height).max(right.height),
      }
    }
    FlowAnchor(_) | GotoAnchor(_) => { width: 0, height: 0, }
    Partition(index, tiles, _) => {
      let body = measure_sequence(tiles, nodes, metrics, small_metrics)
      let title = metrics.measure(nodes[index].label().unwrap())
      {
        width: body.width.max(title.width) + TEXT_PADDING * 2,
        height: body.height +
        partition_header_height(title.height) +
        REGION_PADDING,
      }
    }
    Swimlane(_) => { width: 0, height: 0, }
    IfChain(branches, _) if if_vertical_body_index(branches, nodes) is Some(_) =>
      measure_if_vertical(branches, nodes, metrics, small_metrics)
    IfChain(branches, _) if is_if_down(branches) => {
      let branches_size = measure_if_down(
        branches, nodes, metrics, small_metrics,
      )
      branches_size
    }
    IfChain(branches, _) => {
      let branches_size = measure_if_chain(
        branches, nodes, metrics, small_metrics,
      )
      {
        width: branches_size.width,
        height: branches_size.height +
        (if branches.any(branch => sequence_has_exit(branch.tiles, nodes)) {
          BODY_EXIT_GAP
        } else {
          0
        }),
      }
    }
    Switch(entry, branches, exit) => {
      let entry_size = nodes[entry].size(metrics, small_metrics)
      let exit_size = nodes[exit].size(metrics, small_metrics)
      let (width, _, _, wide_condition) = switch_columns(
        entry, branches, exit, nodes, metrics, small_metrics,
      )
      let (gap, branch_height) = switch_rows(
        branches,
        entry_size.height,
        wide_condition,
        nodes,
        metrics,
        small_metrics,
      )
      {
        width,
        height: entry_size.height +
        gap +
        branch_height +
        (if branches.any(branch => sequence_has_exit(branch.tiles, nodes)) {
          VERTICAL_GAP + exit_size.height
        } else {
          0
        }),
      }
    }
    WhileLoop(entry, body, exit, enter_label, exit_label) => {
      let entry_size = nodes[entry].size(metrics, small_metrics)
      let body_size = measure_sequence(body, nodes, metrics, small_metrics)
      let exit_size = nodes[exit].size(metrics, small_metrics)
      let (width, _) = while_columns(
        entry, body, exit, exit_label, enter_label, nodes, metrics, small_metrics,
      )
      {
        width,
        height: entry_size.height +
        decision_body_gap(enter_label, small_metrics) +
        body_size.height +
        WHILE_EXIT_GAP +
        exit_size.height,
      }
    }
    RepeatLoop(entry, body, exit, retry_label, exit_label) => {
      let entry_size = nodes[entry].size(metrics, small_metrics)
      let body_size = measure_sequence(body, nodes, metrics, small_metrics)
      let exit_size = nodes[exit].size(metrics, small_metrics)
      let (width, _) = repeat_columns(
        entry, body, exit, retry_label, exit_label, nodes, metrics, small_metrics,
      )
      {
        width,
        height: entry_size.height +
        VERTICAL_GAP +
        body_size.height +
        VERTICAL_GAP +
        exit_size.height +
        repeat_exit_padding(exit_label, small_metrics),
      }
    }
    Parallel(_, branches, _) => {
      let branches_width = measure_fork_columns(
        branches, nodes, metrics, small_metrics,
      )
      let (branches_height, incoming, outgoing) = fork_rows(
        branches, nodes, metrics, small_metrics,
      )
      {
        width: branches_width + FORK_COLUMN_MARGIN * 2,
        height: FORK_BAR_HEIGHT +
        VERTICAL_GAP +
        incoming +
        branches_height +
        VERTICAL_GAP +
        outgoing +
        FORK_BAR_HEIGHT,
      }
    }
  }
}

///|
fn measure_if_vertical(
  branches : Array[BranchTiles],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  let body_index = if_vertical_body_index(branches, nodes).unwrap()
  let body = measure_sequence(
    branches[body_index].tiles,
    nodes,
    metrics,
    small_metrics,
  )
  let decision = nodes[branches[0].decision.unwrap()].size(
    metrics, small_metrics,
  )
  let (width, _) = if_vertical_columns(branches, nodes, metrics, small_metrics)
  {
    width,
    height: decision.height +
    decision_body_gap(branches[body_index].label, small_metrics) +
    body.height +
    BODY_EXIT_GAP +
    if_vertical_merge_size(branches, nodes).height,
  }
}

///|
fn empty_branch_width(
  branch : BranchTiles,
  metrics : @metrics.FontMetrics,
) -> Int {
  if branch.tiles.all(tile => tile is Swimlane) {
    branch.label.map_or(EXIT_SIZE, label => {
      metrics.measure(label).width.max(EXIT_SIZE)
    })
  } else {
    0
  }
}

///|
/// Match the final child's output geometry when assembling instructions.
/// Empty branches have a through path; conditional branches retain an output
/// only when at least one child branch can continue.
fn sequence_has_exit(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> Bool {
  for index = tiles.length() - 1; index >= 0; index = index - 1 {
    match tiles[index] {
      FlowAnchor(_) => return true
      GotoAnchor(_) => return false
      Swimlane => continue
      Leaf(index) => {
        if nodes[index] is @flow.ActivityNode::Arrow(_) {
          continue
        }
        return !(nodes[index]
          is (@flow.ActivityNode::Stop
          | @flow.ActivityNode::End
          | @flow.ActivityNode::Kill
          | @flow.ActivityNode::Note(_)))
      }
      Noted(body, _) => return sequence_has_exit([body], nodes)
      Partition(_, body, _) => return sequence_has_exit(body, nodes)
      IfChain(branches, _) | Switch(_, branches, _) =>
        return branches.any(branch => sequence_has_exit(branch.tiles, nodes))
      WhileLoop(_) | RepeatLoop(_) | Parallel(_) => return true
    }
  }
  true
}

///|
/// Reserve the title block before placing the partition's child flow.
fn partition_header_height(text_height : Int) -> Int {
  REGION_HEADER_HEIGHT.max(text_height) + REGION_PADDING
}

///|
/// Additional lines extend the label block below the condition.
fn decision_body_gap(label : String?, metrics : @metrics.FontMetrics) -> Int {
  label.map_or(DIAMOND_BODY_GAP, text => {
    DOWN_LABEL_GAP + (line_count(text) - 1) * metrics.line_height
  })
}

///|
/// ParallelBuilderFork.ConnectionIn/ConnectionOut translated bend distances.
const FORK_LANE_OUT_DROP : Int = 4

///|
const FORK_LANE_IN_RISE : Int = 14
