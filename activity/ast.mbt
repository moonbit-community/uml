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
/// Parsed activity-diagram source in command order.
pub struct ActivityDiagram {
  nodes : Array[ActivityNode]
} derive(Eq, Debug)
