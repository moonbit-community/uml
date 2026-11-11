///|
#derive(Eq, Debug)
pub(all) enum ActivityNoteSide {
  Left
  Right
}

///|
pub extend ActivityNoteSide with Eq::{not_equal, equal}

///|
pub extend ActivityNoteSide with Debug::{to_repr}

///|
/// A command recognized by PlantUML's modern activity-diagram parser.
#derive(Eq, Debug)
pub(all) enum ActivityNode {
  Start(String?)
  Spot(String, String?)
  Stop(String?)
  End(String?)
  Kill
  Break
  Backward(ActivityBackward)
  Action(String)
  StyledAction(ActivityAction)
  Arrow(String)
  If(ActivityDecision)
  ElseIf(ActivityDecision)
  Else(String)
  EndIf(ActivityDecision)
  While(ActivityDecision)
  EndWhile(String)
  Repeat(ActivityDecision)
  RepeatAction(ActivityAction)
  RepeatWhile(ActivityDecision)
  Fork(String?)
  ForkAgain
  EndFork(String?, String?)
  EndMerge(String?)
  Split
  SplitAgain
  EndSplit
  Switch(ActivityDecision)
  Case(String)
  EndSwitch(ActivityDecision)
  Swimlane(ActivitySwimlane)
  Partition(ActivityGroup)
  EndPartition
  Note(String, ActivityNoteSide)
  StyledNote(ActivityNote)
  Label(String)
  Goto(String)
}

///|
pub extend ActivityNode with Eq::{not_equal, equal}

///|
pub extend ActivityNode with Debug::{to_repr}

///|
/// Text carried by a control-flow edge rather than by an activity node.
#derive(Eq, Debug)
pub(all) struct ActivityEdgeLabel {
  text : String?
  style : String?
}

///|
pub extend ActivityEdgeLabel with Eq::{not_equal, equal}

///|
pub extend ActivityEdgeLabel with Debug::{to_repr}

///|
/// A branch in an `if` chain or `switch`. `condition` is present for the initial
/// `if` and every `elseif`; `None` represents the terminal `else` branch.
#derive(Eq, Debug)
pub(all) struct ActivityBranch {
  condition : ActivityDecision?
  incoming : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
}

///|
pub extend ActivityBranch with Eq::{not_equal, equal}

///|
pub extend ActivityBranch with Debug::{to_repr}

///|
/// PlantUML's chained conditional instruction.
#derive(Eq, Debug)
pub(all) struct ActivityIfChain {
  merge : ActivityDecision
  branches : Array[ActivityBranch]
}

///|
pub extend ActivityIfChain with Eq::{not_equal, equal}

///|
pub extend ActivityIfChain with Debug::{to_repr}

///|
/// A `while` instruction with distinct enter and exit edge labels.
#derive(Eq, Debug)
pub(all) struct ActivityWhile {
  condition : ActivityDecision
  enter : ActivityEdgeLabel
  exit : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
}

///|
pub extend ActivityWhile with Eq::{not_equal, equal}

///|
pub extend ActivityWhile with Debug::{to_repr}

///|
/// A `repeat` instruction whose terminal condition owns return and exit labels.
#derive(Eq, Debug)
pub(all) struct ActivityRepeat {
  entry : ActivityDecision
  start : ActivityAction?
  condition : ActivityDecision
  retry : ActivityEdgeLabel
  exit : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
}

///|
pub extend ActivityRepeat with Eq::{not_equal, equal}

///|
pub extend ActivityRepeat with Debug::{to_repr}

///|
/// A parallel fork with independently laid out instruction lists.
#derive(Eq, Debug)
pub(all) struct ActivityFork {
  stereotype : String?
  label : String?
  merge : Bool
  branches : Array[Array[ActivityInstruction]]
}

///|
pub extend ActivityFork with Eq::{not_equal, equal}

///|
pub extend ActivityFork with Debug::{to_repr}

///|
/// A multi-way switch. Case text is an incoming edge label, not a node.
#derive(Eq, Debug)
pub(all) struct ActivitySwitch {
  merge : ActivityDecision
  condition : ActivityDecision
  branches : Array[ActivityBranch]
}

///|
pub extend ActivitySwitch with Eq::{not_equal, equal}

///|
pub extend ActivitySwitch with Debug::{to_repr}

///|
/// A named activity partition enclosing a flow.
#derive(Eq, Debug)
pub(all) struct ActivityPartition {
  group : ActivityGroup
  instructions : Array[ActivityInstruction]
}

///|
pub extend ActivityPartition with Eq::{not_equal, equal}

///|
pub extend ActivityPartition with Debug::{to_repr}

///|
/// A semantic activity instruction corresponding to PlantUML's instruction
/// layer before it is converted to an `Ftile` or `Gtile`.
#derive(Eq, Debug)
pub(all) enum ActivityInstruction {
  Start(String?)
  Spot(String, String?)
  Stop(String?)
  End(String?)
  Kill
  Break
  Backward(ActivityBackward)
  Action(String)
  StyledAction(ActivityAction)
  Note(String, ActivityNoteSide)
  StyledNote(ActivityNote)
  Edge(ActivityEdgeLabel)
  IfChain(ActivityIfChain)
  While(ActivityWhile)
  Repeat(ActivityRepeat)
  Fork(ActivityFork)
  Split(ActivityFork)
  Switch(ActivitySwitch)
  Partition(ActivityPartition)
  Swimlane(ActivitySwimlane)
  Label(String)
  Goto(String)
}

///|
pub extend ActivityInstruction with Eq::{not_equal, equal}

///|
pub extend ActivityInstruction with Debug::{to_repr}

///|
/// Parsed activity-diagram source. `nodes` preserves the grammar-level stream;
/// `instructions` is the nested semantic flow consumed by layout.
#derive(Eq, Debug)
pub(all) struct ActivityDiagram {
  nodes : Array[ActivityNode]
  instructions : Array[ActivityInstruction]
  style : @style.DocumentStyle
}

///|
pub extend ActivityDiagram with Eq::{not_equal, equal}

///|
pub extend ActivityDiagram with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ActivityAction {
  box_style : String?
  label : String
  stereotype : String?
  style : @style.DocumentStyle
}

///|
pub extend ActivityAction with Eq::{not_equal, equal}

///|
pub extend ActivityAction with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ActivityNote {
  text : String
  side : ActivityNoteSide
  floating : Bool
  color : String?
  stereotype : String?
  style : @style.DocumentStyle
}

///|
pub extend ActivityNote with Eq::{not_equal, equal}

///|
pub extend ActivityNote with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ActivityBackward {
  action : ActivityAction
  incoming : ActivityEdgeLabel
  outgoing : ActivityEdgeLabel
}

///|
pub extend ActivityBackward with Eq::{not_equal, equal}

///|
pub extend ActivityBackward with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ActivitySwimlane {
  name : String
  label : String?
  color : String?
}

///|
#derive(Eq, Debug)
pub(all) struct ActivityGroup {
  label : String
  symbol : ActivityGroupSymbol
  color : String?
  stereotype : String?
  style : @style.DocumentStyle
}

///|
#derive(Eq, Debug)
pub(all) enum ActivityGroupSymbol {
  Partition
  Package
  Rectangle
  Card
  Group
}

///|
pub extend ActivityGroupSymbol with Eq::{not_equal, equal}

///|
pub extend ActivityGroupSymbol with Debug::{to_repr}

///|
pub extend ActivityGroup with Eq::{not_equal, equal}

///|
pub extend ActivityGroup with Debug::{to_repr}

///|
pub extend ActivitySwimlane with Eq::{not_equal, equal}

///|
pub extend ActivitySwimlane with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct ActivityDecision {
  text : String
  stereotype : String?
  color : String?
  style : @style.DocumentStyle
}

///|
pub extend ActivityDecision with Eq::{not_equal, equal}

///|
pub extend ActivityDecision with Debug::{to_repr}
