///|
/// A command recognized by PlantUML's modern activity-diagram parser.
pub(all) enum ActivityNode {
  Start
  Stop
  End
  Kill
  Action(String)
  Arrow(String)
  If(String)
  ElseIf(String)
  Else(String)
  EndIf
  While(String)
  EndWhile(String)
  Repeat
  RepeatWhile(String)
  Fork
  ForkAgain
  EndFork
  Switch(String)
  Case(String)
  EndSwitch
  Swimlane(String)
  Partition(String)
  EndPartition
  Note(String)
  Label(String)
  Goto(String)
} derive(Eq, Debug)

///|
pub extend ActivityNode with Eq::{not_equal, equal}

///|
pub extend ActivityNode with Debug::{to_repr}

///|
/// Text carried by a control-flow edge rather than by an activity node.
pub(all) struct ActivityEdgeLabel {
  text : String?
} derive(Eq, Debug)

///|
pub extend ActivityEdgeLabel with Eq::{not_equal, equal}

///|
pub extend ActivityEdgeLabel with Debug::{to_repr}

///|
/// A branch in an `if` chain or `switch`. `condition` is present for the initial
/// `if` and every `elseif`; `None` represents the terminal `else` branch.
pub(all) struct ActivityBranch {
  condition : String?
  incoming : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
pub extend ActivityBranch with Eq::{not_equal, equal}

///|
pub extend ActivityBranch with Debug::{to_repr}

///|
/// PlantUML's chained conditional instruction.
pub(all) struct ActivityIfChain {
  branches : Array[ActivityBranch]
} derive(Eq, Debug)

///|
pub extend ActivityIfChain with Eq::{not_equal, equal}

///|
pub extend ActivityIfChain with Debug::{to_repr}

///|
/// A `while` instruction with distinct enter and exit edge labels.
pub(all) struct ActivityWhile {
  condition : String
  enter : ActivityEdgeLabel
  exit : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
pub extend ActivityWhile with Eq::{not_equal, equal}

///|
pub extend ActivityWhile with Debug::{to_repr}

///|
/// A `repeat` instruction whose terminal condition owns return and exit labels.
pub(all) struct ActivityRepeat {
  condition : String
  retry : ActivityEdgeLabel
  exit : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
pub extend ActivityRepeat with Eq::{not_equal, equal}

///|
pub extend ActivityRepeat with Debug::{to_repr}

///|
/// A parallel fork with independently laid out instruction lists.
pub(all) struct ActivityFork {
  branches : Array[Array[ActivityInstruction]]
} derive(Eq, Debug)

///|
pub extend ActivityFork with Eq::{not_equal, equal}

///|
pub extend ActivityFork with Debug::{to_repr}

///|
/// A multi-way switch. Case text is an incoming edge label, not a node.
pub(all) struct ActivitySwitch {
  condition : String
  branches : Array[ActivityBranch]
} derive(Eq, Debug)

///|
pub extend ActivitySwitch with Eq::{not_equal, equal}

///|
pub extend ActivitySwitch with Debug::{to_repr}

///|
/// A named activity partition enclosing a flow.
pub(all) struct ActivityPartition {
  label : String
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
pub extend ActivityPartition with Eq::{not_equal, equal}

///|
pub extend ActivityPartition with Debug::{to_repr}

///|
/// A semantic activity instruction corresponding to PlantUML's instruction
/// layer before it is converted to an `Ftile` or `Gtile`.
pub(all) enum ActivityInstruction {
  Start
  Stop
  End
  Kill
  Action(String)
  Note(String)
  Edge(ActivityEdgeLabel)
  IfChain(ActivityIfChain)
  While(ActivityWhile)
  Repeat(ActivityRepeat)
  Fork(ActivityFork)
  Switch(ActivitySwitch)
  Partition(ActivityPartition)
  Swimlane(String)
  Label(String)
  Goto(String)
} derive(Eq, Debug)

///|
pub extend ActivityInstruction with Eq::{not_equal, equal}

///|
pub extend ActivityInstruction with Debug::{to_repr}

///|
/// Parsed activity-diagram source. `nodes` preserves the grammar-level stream;
/// `instructions` is the nested semantic flow consumed by layout.
pub(all) struct ActivityDiagram {
  nodes : Array[ActivityNode]
  instructions : Array[ActivityInstruction]
  style : @style.DocumentStyle
} derive(Eq, Debug)

///|
pub extend ActivityDiagram with Eq::{not_equal, equal}

///|
pub extend ActivityDiagram with Debug::{to_repr}
