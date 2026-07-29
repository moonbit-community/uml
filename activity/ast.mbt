///|
/// A command recognized by PlantUML's modern activity-diagram parser.
pub enum ActivityNode {
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
/// Text carried by a control-flow edge rather than by an activity node.
pub struct ActivityEdgeLabel {
  text : String?
} derive(Eq, Debug)

///|
/// A branch in an `if` chain or `switch`. `condition` is present for the initial
/// `if` and every `elseif`; `None` represents the terminal `else` branch.
pub struct ActivityBranch {
  condition : String?
  incoming : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
/// PlantUML's chained conditional instruction.
pub struct ActivityIfChain {
  branches : Array[ActivityBranch]
} derive(Eq, Debug)

///|
/// A `while` instruction with distinct enter and exit edge labels.
pub struct ActivityWhile {
  condition : String
  enter : ActivityEdgeLabel
  exit : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
/// A `repeat` instruction whose terminal condition owns return and exit labels.
pub struct ActivityRepeat {
  condition : String
  retry : ActivityEdgeLabel
  exit : ActivityEdgeLabel
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
/// A parallel fork with independently laid out instruction lists.
pub struct ActivityFork {
  branches : Array[Array[ActivityInstruction]]
} derive(Eq, Debug)

///|
/// A multi-way switch. Case text is an incoming edge label, not a node.
pub struct ActivitySwitch {
  condition : String
  branches : Array[ActivityBranch]
} derive(Eq, Debug)

///|
/// A named activity partition enclosing a flow.
pub struct ActivityPartition {
  label : String
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)

///|
/// A semantic activity instruction corresponding to PlantUML's instruction
/// layer before it is converted to an `Ftile` or `Gtile`.
pub enum ActivityInstruction {
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
/// Parsed activity-diagram source. `nodes` preserves the grammar-level stream;
/// `instructions` is the nested semantic flow consumed by layout.
pub struct ActivityDiagram {
  nodes : Array[ActivityNode]
  instructions : Array[ActivityInstruction]
} derive(Eq, Debug)
