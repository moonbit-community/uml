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
  region_index : Int
  description : String?
  stereotype : String?
  url : String?
  color : String?
} derive(Eq, Debug)

///|
fn StateNode::has_description(self : StateNode) -> Bool {
  match self.description {
    Some(text) => text.length() > 0
    None => false
  }
}

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
pub(all) enum StateRegionSeparator {
  Horizontal
  Vertical
} derive(Eq, Debug)

///|
pub struct StateRegion {
  parent : String
  separator : StateRegionSeparator?
  index : Int
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
  color : String?
} derive(Eq, Debug)

///|
pub struct StateDiagram {
  states : Array[StateNode]
  transitions : Array[StateTransition]
  notes : Array[StateNote]
  concurrent_regions : Array[String]
  regions : Array[StateRegion]
  style : @style.DocumentStyle
} derive(Eq, Debug)

///|
fn StateDiagram::hide_empty_description(self : StateDiagram) -> Bool {
  self.style.property("hide empty description") == Some("true")
}

///|
pub fn StateDiagram::state(self : StateDiagram, code : String) -> StateNode? {
  for state in self.states {
    if state.code == code {
      return Some(state)
    }
  }
  None
}
