///|
pub(all) enum StateKind {
  Normal
  Initial
  Final
  History
  DeepHistory
  Synchronization
  Choice
} derive(Eq, Debug)

///|
pub(all) enum TransitionDirection {
  Automatic
  Leftward
  Rightward
  Upward
  Downward
} derive(Eq, Debug)

///|
pub struct StateNode {
  code : String
  display : String
  kind : StateKind
  parent : String?
  description : String?
  stereotype : String?
  url : String?
  color : String?
} derive(Eq, Debug)

///|
pub struct StateTransition {
  source : String
  target : String
  label : String?
  direction : TransitionDirection
  line_style : String?
  has_cross_start : Bool
} derive(Eq, Debug)

///|
pub(all) enum StateNoteTarget {
  StateNote(String)
  TransitionNote(Int)
} derive(Eq, Debug)

///|
pub struct StateNote {
  target : StateNoteTarget
  text : String
} derive(Eq, Debug)

///|
pub struct StateDiagram {
  states : Array[StateNode]
  transitions : Array[StateTransition]
  notes : Array[StateNote]
  concurrent_regions : Array[String]
} derive(Eq, Debug)

///|
pub fn StateDiagram::state(self : StateDiagram, code : String) -> StateNode? {
  for state in self.states {
    if state.code == code {
      return Some(state)
    }
  }
  None
}
