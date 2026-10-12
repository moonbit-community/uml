///|
/// Geometry for one visible activity instruction.
pub(all) struct ActivityNodeLayout {
  node_index : Int32
  note_pointer_offset : Double?
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend ActivityNodeLayout with Eq::{not_equal, equal}

///|
pub extend ActivityNodeLayout with Debug::{to_repr}

///|
pub(all) enum ActivityEdgeRoute {
  Forward
  ForkLane(Double, Double)
  ForkSequence
  ForkSequencePorts(Double, Double)
  Horizontal
  Goto
  BackwardLeft
  BreakLeft(Double, Bool)
  BackwardActionIn(Bool, Double)
  BackwardActionOut
  BackwardRight(Double, Double)
  RepeatBackRight(Double)
  RepeatLaneBack(Double)
  RepeatForward
  IfDownLeft
  IfDownRight
  IfSideTerminal
  IfBypassRight(Double)
  IfEmptyDown
  IfChainMerge
  SwitchLeft
  SwitchRight
  SwitchMiddle
  SwitchSideMerge
  WhileExitLeft(Double)
  WhileEntry
  ForkMerge
} derive(Eq, Debug)

///|
pub extend ActivityEdgeRoute with Eq::{not_equal, equal}

///|
pub extend ActivityEdgeRoute with Debug::{to_repr}

///|
/// A directed connector between visible activity instructions.
pub(all) struct ActivityEdgeLayout {
  from_node_index : Int32
  to_node_index : Int32
  route : ActivityEdgeRoute
  label : String?
  style : String?
  rainbow_separation : Double
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
  group : @flow.ActivityGroup?
  color : String?
  x : Double
  y : Double
  width : Double
  height : Double
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
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend ActivityLayout with Eq::{not_equal, equal}

///|
pub extend ActivityLayout with Debug::{to_repr}

///|
priv enum Tile {
  Leaf(Int32)
  Noted(Tile, Array[Int32])
  LoopWithBreaks(Tile, Array[Int32], Int32, Bool)
  LoopWithBackward(Tile, Int32, Int32, Int32, @flow.ActivityBackward)
  FlowAnchor(Int32)
  GotoAnchor(Int32)
  Partition(Int32, Array[Tile], Int32)
  Swimlane
  IfChain(Array[BranchTiles], Int32)
  WhileLoop(Int32, Array[Tile], Int32, String?, String?)
  RepeatLoop(Int32, Array[Tile], Int32, String?, String?)
  Parallel(Int32, Array[BranchTiles], Int32)
  Switch(Int32, Array[BranchTiles], Int32)
}

///|
priv struct BranchTiles {
  style : String?
  decision : Int32?
  tiles : Array[Tile]
  label : String?
}

///|
priv struct TileMeasure {
  width : Double
  height : Double
}

///|
priv struct PlacedTile {
  entry : Int32?
  exit : Int32?
  outgoing_label : String?
  outgoing_style : String?
  outgoing_route : ActivityEdgeRoute
}

///|
priv struct PlacedBranch {
  tile : PlacedTile
  label : String?
  style : String?
}

///|
/// Canvas margins derived from PlantUML output: content is inset 16px on the
/// left, 15px on the top and about 20px on the right and bottom.
pub const CANVAS_LEFT : Double = 16

///|
const CANVAS_TOP : Double = 15

///|
const CANVAS_RIGHT : Double = 20

///|
const CANVAS_BOTTOM : Double = 20

///|
/// Vertical gap between sequential tiles (PlantUML renders 20px).
const VERTICAL_GAP : Double = 20

///|
/// Sequential gap when the connecting arrow carries a single-line label.
/// PlantUML renders 41.28px for the first line plus the line height per
/// additional line.
const EDGE_LABEL_GAP : Double = 41

///|

///|
/// Snake places a vertical connector's label beside its flow axis.
const EDGE_LABEL_OFFSET : Double = 4

///|
/// Box padding on all four sides (skin `activity { Padding 10 }`).
const TEXT_PADDING : Double = 10

///|
/// Round-corner radius of activity boxes (skin `RoundCorner 25`).
const BOX_ROUND : Double = 12

///|
/// Minimum decision height; taller labels expand the hexagon.
const DIAMOND_HEIGHT : Double = 24

///|
/// Horizontal padding added to a decision label inside the diamond.
const DIAMOND_TEXT_PADDING : Double = 24

///|
/// Start-circle diameter.
const TERMINAL_SIZE : Double = 20

///|
/// Stop-circle outer diameter (PlantUML `FtileCircleStop` SIZE 22).
const STOP_SIZE : Double = 22

///|
/// FtileCircleEndCross.SIZE and its internal cross stroke.
const END_SIZE : Double = 20

///|
const END_CROSS_STROKE : Double = 2.5

///|
/// Stop-circle inner diameter.
const STOP_INNER : Double = 6

///|
/// Exit/merge node size (endif/endwhile diamond, 24x24).
const EXIT_SIZE : Double = 24

///|
/// Gap between the decision diamond and a branch body without a down label.
const DIAMOND_BODY_GAP : Double = 10

///|
/// Diamond-to-body gap when the branch label is drawn on the down edge.
/// PlantUML renders 32.14px.
const DOWN_LABEL_GAP : Double = 32

///|
/// Gap between a branch body bottom and the exit node.
const BODY_EXIT_GAP : Double = 6

///|
/// Minimum horizontal gap between adjacent branch columns.
const BRANCH_GAP : Double = 20

///|
/// Margin between a decision diamond's side vertex and a branch column
/// center in the two-branch (FtileIfDown) layout.
const BRANCH_DIAMOND_MARGIN : Double = 10

///|
/// Horizontal clearance of a while back edge beyond the body.
const WHILE_BACK_MARGIN : Double = 12

///|
/// Clearance below the loop body before the return edge turns outward.
const LOOP_BACK_GAP : Double = 10

///|
/// The vertical route line a `BackwardLeft` edge loops
/// through, left of both nodes.
///
/// The SVG path, the label extent, and the compression pass all derive this
/// x; keep it here instead of re-deriving `from.x.min(to.x)` per file.
fn backward_left_route_x(
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
) -> Double {
  from.x.min(to.x) - WHILE_BACK_MARGIN
}

///|
/// While body-to-port gap: the reference SVG places the return line first,
/// then the exit turn; the following sequence owns its own vertical gap.
const WHILE_EXIT_GAP : Double = LOOP_BACK_GAP + WHILE_BACK_MARGIN

///|
/// Fork bar height.
const FORK_BAR_HEIGHT : Double = 6

///|
/// Fork branch column margin (PlantUML `xMargin = 14`).
const FORK_COLUMN_MARGIN : Double = 14

///|
/// Font size used for activity labels. PlantUML's skin sets `FontSize 12`
/// for the real sans-serif font; the built-in metric table is calibrated at
/// 13px, so 13 is the matching emulation size.
const ACTION_FONT : Int32 = 13

///|
/// Font size used for arrow, branch, and diamond labels (emulates the skin
/// `FontSize 11` with the built-in metric table).
const SMALL_FONT : Int32 = 12

///|
const REGION_PADDING : Double = 12

///|
const REGION_HEADER_HEIGHT : Double = 24

///|
const SWIMLANE_GAP : Double = 24

///|
fn add_layout_node(
  nodes : Array[@flow.ActivityNode],
  node : @flow.ActivityNode,
) -> Int32 {
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
      @flow.ActivityInstruction::Spot(text, color) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(nodes, @flow.ActivityNode::Spot(text, color)),
          ),
        )
      @flow.ActivityInstruction::Start(stereotype) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(nodes, @flow.ActivityNode::Start(stereotype)),
          ),
        )
      @flow.ActivityInstruction::Stop(stereotype) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(nodes, @flow.ActivityNode::Stop(stereotype)),
          ),
        )
      @flow.ActivityInstruction::End(stereotype) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(nodes, @flow.ActivityNode::End(stereotype)),
          ),
        )
      @flow.ActivityInstruction::Backward(_) => ()
      @flow.ActivityInstruction::Break =>
        tiles.push(
          Tile::FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::Break)),
        )
      @flow.ActivityInstruction::Kill =>
        tiles.push(Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::Kill)))
      @flow.ActivityInstruction::Action(label) =>
        tiles.push(
          Tile::Leaf(add_layout_node(nodes, @flow.ActivityNode::Action(label))),
        )
      @flow.ActivityInstruction::StyledAction(action) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(nodes, @flow.ActivityNode::StyledAction(action)),
          ),
        )
      @flow.ActivityInstruction::Note(label, side) => {
        let index = add_layout_node(
          nodes,
          @flow.ActivityNode::Note(label, side),
        )
        attach_activity_note(tiles, nodes, index)
      }
      @flow.ActivityInstruction::StyledNote(note) => {
        let index = add_layout_node(nodes, @flow.ActivityNode::StyledNote(note))
        attach_activity_note(tiles, nodes, index)
      }
      @flow.ActivityInstruction::Edge(label) =>
        tiles.push(
          Tile::Leaf(
            add_layout_node(
              nodes,
              @flow.ActivityNode::Arrow(
                label.style.map_or("->", style => "-[" + style + "]->") +
                " " +
                label.text.unwrap_or("") +
                ";",
              ),
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
        let exit = add_layout_node(
          nodes,
          @flow.ActivityNode::EndIf(chain.merge),
        )
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
              FlowAnchor(
                add_layout_node(nodes, @flow.ActivityNode::EndIf(chain.merge)),
              ),
            )
          }
          {
            decision: decisions[index],
            tiles,
            label,
            style: branch.incoming.style,
          }
        })
        if branches[branches.length() - 1].decision is Some(_) {
          let tiles = if is_long {
            [
              FlowAnchor(
                add_layout_node(nodes, @flow.ActivityNode::EndIf(chain.merge)),
              ),
            ]
          } else {
            []
          }
          branches.push({ decision: None, tiles, label: None, style: None, })
        }
        // ConditionalBuilder keeps two empty branches in the two-column layout.
        if !is_long &&
          branches.all(branch => sequence_is_empty(branch.tiles, nodes)) {
          for branch in branches {
            branch.tiles.push(
              FlowAnchor(
                add_layout_node(nodes, @flow.ActivityNode::EndIf(chain.merge)),
              ),
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
        let body = tiles_from_instructions(
          while_instruction.instructions,
          nodes,
        )
        let loop_tile = Tile::WhileLoop(
          entry,
          body,
          exit,
          while_instruction.enter.text.map(activity_display_text),
          while_instruction.exit.text.map(activity_display_text),
        )
        let loop_tile = activity_backward_tile(
          loop_tile,
          while_instruction.instructions,
          entry,
          exit,
          nodes,
        )
        let breaks = activity_break_points(body, nodes)
        tiles.push(
          if breaks.is_empty() {
            loop_tile
          } else {
            LoopWithBreaks(loop_tile, breaks, exit, false)
          },
        )
      }
      @flow.ActivityInstruction::Repeat(repeat_instruction) => {
        let entry = add_layout_node(
          nodes,
          repeat_instruction.start.map_or(
            @flow.ActivityNode::Repeat(repeat_instruction.entry),
            text => @flow.ActivityNode::RepeatAction(text),
          ),
        )
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
        let loop_tile = Tile::RepeatLoop(
          entry,
          body,
          exit,
          repeat_instruction.retry.text.map(activity_display_text),
          repeat_instruction.exit.text.map(activity_display_text),
        )
        let loop_tile = activity_backward_tile(
          loop_tile,
          repeat_instruction.instructions,
          entry,
          exit,
          nodes,
        )
        let breaks = activity_break_points(body, nodes)
        tiles.push(
          if breaks.is_empty() {
            loop_tile
          } else {
            LoopWithBreaks(
              loop_tile,
              breaks,
              add_layout_node(
                nodes,
                @flow.ActivityNode::EndIf({
                  ..repeat_instruction.condition,
                  text: "",
                }),
              ),
              true,
            )
          },
        )
      }
      @flow.ActivityInstruction::Fork(fork)
      | @flow.ActivityInstruction::Split(fork) => {
        let split = instruction is @flow.ActivityInstruction::Split(_)
        let entry = add_layout_node(
          nodes,
          if split {
            @flow.ActivityNode::Split
          } else {
            @flow.ActivityNode::Fork(fork.stereotype)
          },
        )
        let branches = fork.branches.map(branch => {
          let tiles = tiles_from_instructions(branch, nodes)
          if sequence_is_empty(tiles, nodes) {
            tiles.push(
              FlowAnchor(add_layout_node(nodes, @flow.ActivityNode::ForkAgain)),
            )
          }
          { decision: None, tiles, label: None, style: None, }
        })
        let exit = add_layout_node(
          nodes,
          if split {
            @flow.ActivityNode::EndSplit
          } else if fork.merge {
            @flow.ActivityNode::EndMerge(fork.stereotype)
          } else {
            @flow.ActivityNode::EndFork(fork.label, fork.stereotype)
          },
        )
        tiles.push(Tile::Parallel(entry, branches, exit))
      }
      @flow.ActivityInstruction::Switch(switch) => {
        let entry = add_layout_node(
          nodes,
          @flow.ActivityNode::Switch(switch.condition),
        )
        let exit = add_layout_node(
          nodes,
          @flow.ActivityNode::EndSwitch(switch.merge),
        )
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
          { decision: None, tiles, label, style: branch.incoming.style, }
        })
        tiles.push(Tile::Switch(entry, branches, exit))
      }
      @flow.ActivityInstruction::Partition(partition) => {
        let index = add_layout_node(
          nodes,
          @flow.ActivityNode::Partition(partition.group),
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
    Partition(group) => Some(activity_display_text(group.label))
    Swimlane(lane) =>
      Some(activity_display_text(lane.label.unwrap_or(lane.name)))
    StyledAction(action) | RepeatAction(action) =>
      Some(activity_display_text(action.label))
    StyledNote(note) => Some(activity_display_text(note.text))
    Action(label) | Note(label, _) => Some(activity_display_text(label))
    If(decision)
    | ElseIf(decision)
    | Switch(decision)
    | While(decision)
    | RepeatWhile(decision) => Some(activity_display_text(decision.text))
    _ => None
  }
}

///|
fn @flow.ActivityNode::is_decision(self : @flow.ActivityNode) -> Bool {
  self is (If(_) | While(_) | Repeat(_) | RepeatWhile(_) | Switch(_))
}

///|
fn @flow.ActivityNode::is_parallel_bar(self : @flow.ActivityNode) -> Bool {
  self is (Fork(_) | EndFork(_) | Split | EndSplit)
}

///|
fn @flow.ActivityNode::is_exit(self : @flow.ActivityNode) -> Bool {
  self is (EndIf(_) | EndSwitch(_) | EndMerge(_))
}

///|
fn @flow.ActivityNode::size(
  self : @flow.ActivityNode,
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> TileMeasure {
  match self {
    StyledAction(action) | RepeatAction(action) =>
      activity_action_measure(action)
    StyledNote(note) => activity_styled_note_size(note)
    Spot(_, _) => { width: ACTIVITY_SPOT_SIZE, height: ACTIVITY_SPOT_SIZE, }
    Start(_) => { width: TERMINAL_SIZE, height: TERMINAL_SIZE, }
    Stop(_) => { width: STOP_SIZE, height: STOP_SIZE, }
    End(_) => { width: END_SIZE, height: END_SIZE, }
    Kill => { width: 0, height: 0, }
    _ if self.is_exit() => { width: EXIT_SIZE, height: EXIT_SIZE, }
    Repeat(_) => { width: EXIT_SIZE, height: EXIT_SIZE, }
    _ if self.is_parallel_bar() =>
      { width: 0, height: parallel_bar_height(self), }
    _ if self.is_decision() => {
      let font = self
        .activity_decision()
        .map_or(small_metrics, activity_decision_metrics)
      let text = activity_measure(font, self.label().unwrap_or(""))
      if self.condition_shape() == EmptyDiamond {
        return {
          width: DIAMOND_TEXT_PADDING,
          height: DIAMOND_HEIGHT + text.height,
        }
      }
      if self.condition_shape() == InsideDiamond {
        return {
          width: if text.width == 0 {
            DIAMOND_TEXT_PADDING
          } else {
            text.width + DIAMOND_TEXT_PADDING
          },
          height: if text.width == 0 {
            DIAMOND_HEIGHT
          } else {
            text.height + DIAMOND_HEIGHT
          },
        }
      }
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
      let text = activity_measure(metrics, self.label().unwrap())
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
  let mut left = 0.0
  let mut right = 0.0
  let mut height = 0.0
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
      height += sequence_gap(incoming.unwrap_or(None), small_metrics)
      if label is Some(label) {
        right = right.max(
          EDGE_LABEL_OFFSET + activity_measure(small_metrics, label).width,
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
    right = right.max(
      EDGE_LABEL_OFFSET + activity_measure(small_metrics, label).width,
    )
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
/// Shared by measurement and placement so sequential tiles reserve exactly
/// the space their connecting label needs, independently of node indices.
fn sequence_gap(label : String?, metrics : @metrics.FontMetrics) -> Double {
  label.map_or(VERTICAL_GAP, label => {
    EDGE_LABEL_GAP + activity_extra_lines_height(label, metrics)
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
  let mut width = 0.0
  let mut decision_height = 0.0
  let mut body_height = 0.0
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
    LoopWithBackward(body, backward, _, _, _) => {
      let size = measure_tile(body, nodes, metrics, small_metrics)
      {
        width: size.width + nodes[backward].size(metrics, small_metrics).width,
        height: size.height,
      }
    }
    LoopWithBreaks(body, _, _, repeat) => {
      let size = measure_tile(body, nodes, metrics, small_metrics)
      if repeat {
        {
          width: size.width + REPEAT_SIDE_CLEARANCE,
          height: size.height + VERTICAL_GAP + EXIT_SIZE,
        }
      } else {
        size
      }
    }
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
      let inner_width = activity_group_inner_width(
        tiles, nodes, metrics, small_metrics,
      )
      let title = activity_partition_title(nodes[index], metrics)
      {
        width: inner_width.max(title.width + ACTIVITY_GROUP_MARGIN * 2),
        height: body.height +
        partition_header_height(title.height) +
        ACTIVITY_GROUP_BOTTOM,
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
    Parallel(entry, branches, exit) => {
      let branches_width = measure_fork_columns(
        branches, nodes, metrics, small_metrics,
      )
      let (branches_height, incoming, outgoing) = fork_rows(
        branches, nodes, metrics, small_metrics,
      )
      {
        width: branches_width +
        FORK_COLUMN_MARGIN * 2 +
        activity_fork_label_width(nodes[exit], small_metrics),
        height: parallel_bar_height(nodes[entry]) +
        VERTICAL_GAP +
        incoming +
        branches_height +
        VERTICAL_GAP +
        outgoing +
        (if nodes[entry] is @flow.ActivityNode::Split &&
          !branches.any(branch => sequence_has_exit(branch.tiles, nodes)) {
          0.0
        } else if nodes[exit] is @flow.ActivityNode::EndMerge(_) {
          EXIT_SIZE
        } else {
          parallel_bar_height(nodes[entry])
        }),
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
) -> Double {
  if branch.tiles.all(tile => tile is Swimlane) {
    branch.label.map_or(EXIT_SIZE, label => {
      activity_measure(metrics, label).width.max(EXIT_SIZE)
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
      FlowAnchor(index) => return !(nodes[index] is @flow.ActivityNode::Break)
      GotoAnchor(_) => return false
      Swimlane => continue
      Leaf(index) => {
        if nodes[index] is @flow.ActivityNode::Arrow(_) {
          continue
        }
        return !(nodes[index]
          is (@flow.ActivityNode::Stop(_)
          | @flow.ActivityNode::End(_)
          | @flow.ActivityNode::Kill
          | @flow.ActivityNode::Note(_)
          | @flow.ActivityNode::StyledNote(_)))
      }
      Noted(body, _) => return sequence_has_exit([body], nodes)
      Partition(_, body, _) => return sequence_has_exit(body, nodes)
      IfChain(branches, _) | Switch(_, branches, _) =>
        return branches.any(branch => sequence_has_exit(branch.tiles, nodes))
      Parallel(entry, branches, _) if nodes[entry] is @flow.ActivityNode::Split =>
        return branches.any(branch => sequence_has_exit(branch.tiles, nodes))
      WhileLoop(_)
      | RepeatLoop(_)
      | Parallel(_)
      | LoopWithBreaks(_)
      | LoopWithBackward(_) => return true
    }
  }
  true
}

///|
/// Reserve the title block before placing the partition's child flow.
fn partition_header_height(text_height : Double) -> Double {
  ACTIVITY_GROUP_MIN_HEADER.max(text_height + ACTIVITY_GROUP_BOTTOM)
}

///|
/// Additional lines extend the label block below the condition.
fn decision_body_gap(label : String?, metrics : @metrics.FontMetrics) -> Double {
  label.map_or(DIAMOND_BODY_GAP, text => {
    DOWN_LABEL_GAP + activity_extra_lines_height(text, metrics)
  })
}

///|
/// ParallelBuilderFork.ConnectionIn/ConnectionOut translated bend distances.
const FORK_LANE_OUT_DROP : Double = 4

///|
const FORK_LANE_IN_RISE : Double = 14

///|
fn sequence_incoming_style(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> String?? {
  let mut pending : String?? = None
  for tile in tiles {
    match tile {
      Swimlane => continue
      Leaf(index) if nodes[index] is @flow.ActivityNode::Arrow(value) =>
        pending = Some(@flow.arrow_label(value).style)
      _ =>
        return pending.map_or(tile_incoming_style(tile, nodes), value => {
          Some(value)
        })
    }
  }
  pending
}

///|
fn tile_incoming_style(
  tile : Tile,
  nodes : Array[@flow.ActivityNode],
) -> String?? {
  match tile {
    Partition(_, body, _) => sequence_incoming_style(body, nodes)
    Noted(body, _) => tile_incoming_style(body, nodes)
    _ => None
  }
}

///|
fn sequence_outgoing_style(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> String? {
  guard sequence_has_exit(tiles, nodes) else { return None }
  for index = tiles.length() - 1; index >= 0; index = index - 1 {
    match tiles[index] {
      Swimlane => continue
      Leaf(node) if nodes[node] is @flow.ActivityNode::Arrow(value) =>
        return @flow.arrow_label(value).style
      Partition(_, body, _) => return sequence_outgoing_style(body, nodes)
      Noted(body, _) => return sequence_outgoing_style([body], nodes)
      _ => return None
    }
  }
  None
}

///|
/// Welding points are consumed by their enclosing loop, never an outer loop.
fn activity_break_points(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
) -> Array[Int32] {
  let points = []
  for tile in tiles {
    match tile {
      FlowAnchor(index) if nodes[index] is @flow.ActivityNode::Break =>
        points.push(index)
      Partition(_, body, _) =>
        for point in activity_break_points(body, nodes) {
          points.push(point)
        }
      Noted(body, _) =>
        for point in activity_break_points([body], nodes) {
          points.push(point)
        }
      IfChain(branches, _)
      | Switch(_, branches, _)
      | Parallel(_, branches, _) =>
        for branch in branches {
          for point in activity_break_points(branch.tiles, nodes) {
            points.push(point)
          }
        }
      _ => ()
    }
  }
  points
}

///|
fn activity_backward_tile(
  body : Tile,
  instructions : Array[@flow.ActivityInstruction],
  entry : Int32,
  exit : Int32,
  nodes : Array[@flow.ActivityNode],
) -> Tile {
  let mut backward = None
  for instruction in instructions {
    if instruction is @flow.ActivityInstruction::Backward(value) {
      backward = Some(value)
    }
  }
  match backward {
    None => body
    Some(value) =>
      LoopWithBackward(
        body,
        add_layout_node(nodes, @flow.ActivityNode::StyledAction(value.action)),
        entry,
        exit,
        value,
      )
  }
}

///|
/// Keep geometric arithmetic fractional through placement and compression.
fn activity_measure(
  metrics : @metrics.FontMetrics,
  text : String,
) -> TileMeasure {
  let (width, height) = state_text_size(text, metrics)
  { width, height, }
}

///|
/// FtileThinSplit uses the arrow stroke as its allocated height; fork uses
/// AbstractParallelFtilesBuilder's synchronization-bar height.
const SPLIT_BAR_HEIGHT : Double = 1.5

///|
fn parallel_bar_height(node : @flow.ActivityNode) -> Double {
  if node is (@flow.ActivityNode::Split | @flow.ActivityNode::EndSplit) {
    SPLIT_BAR_HEIGHT
  } else {
    FORK_BAR_HEIGHT
  }
}

///|
fn @flow.ActivityNode::is_parallel_entry(self : @flow.ActivityNode) -> Bool {
  self is (Fork(_) | Split)
}

///|
/// Only synchronization bars carry ignoreForCompression; FtileThinSplit lines
/// remain occupied geometry and therefore keep the space between branches.
fn @flow.ActivityNode::is_fork(self : @flow.ActivityNode) -> Bool {
  self is (Fork(_) | EndFork(_))
}

///|
fn activity_split_extent(
  layout : ActivityLayout,
  node : ActivityNodeLayout,
) -> (Double, Double) {
  let mut first = node.x + node.width / 2.0
  let mut last = first
  let entry = layout.source_nodes[node.node_index] is @flow.ActivityNode::Split
  for edge in layout.edges {
    let endpoint = if entry && edge.from_node_index == node.node_index {
      Some(edge.to_node_index)
    } else if !entry && edge.to_node_index == node.node_index {
      Some(edge.from_node_index)
    } else {
      None
    }
    if endpoint is Some(endpoint) &&
      layout_for(layout, endpoint) is Some(branch) {
      first = first.min(branch.x + branch.width / 2.0)
      last = last.max(branch.x + branch.width / 2.0)
    }
  }
  (first, last)
}

///|
fn activity_extra_lines_height(
  label : String,
  metrics : @metrics.FontMetrics,
) -> Double {
  (activity_measure(metrics, label).height - metrics.line_height.to_double()).max(
    0.0,
  )
}
