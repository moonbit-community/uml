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

pub extend StateKind with Eq::{not_equal, equal}
pub extend StateKind with Debug::{to_repr}


///|
pub(all) enum TransitionDirection {
  Automatic
  Leftward
  Rightward
  Upward
  Downward
} derive(Eq, Debug)

pub extend TransitionDirection with Eq::{not_equal, equal}
pub extend TransitionDirection with Debug::{to_repr}


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

pub extend StateNode with Eq::{not_equal, equal}
pub extend StateNode with Debug::{to_repr}


///|
fn StateNode::has_description(self : StateNode) -> Bool {
  self.description is Some(text) && text.length() > 0
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

pub extend StateTransition with Eq::{not_equal, equal}
pub extend StateTransition with Debug::{to_repr}


///|
pub(all) enum StateRegionSeparator {
  Horizontal
  Vertical
} derive(Eq, Debug)

pub extend StateRegionSeparator with Eq::{not_equal, equal}
pub extend StateRegionSeparator with Debug::{to_repr}


///|
pub struct StateRegion {
  parent : String
  separator : StateRegionSeparator?
  index : Int
} derive(Eq, Debug)

pub extend StateRegion with Eq::{not_equal, equal}
pub extend StateRegion with Debug::{to_repr}


///|
pub(all) enum StateNoteTarget {
  StateNote(String)
  TransitionNote(Int)
} derive(Eq, Debug)

pub extend StateNoteTarget with Eq::{not_equal, equal}
pub extend StateNoteTarget with Debug::{to_repr}


///|
pub struct StateNote {
  target : StateNoteTarget
  text : String
  color : String?
} derive(Eq, Debug)

pub extend StateNote with Eq::{not_equal, equal}
pub extend StateNote with Debug::{to_repr}


///|
pub struct StateDiagram {
  states : Array[StateNode]
  transitions : Array[StateTransition]
  notes : Array[StateNote]
  concurrent_regions : Array[String]
  regions : Array[StateRegion]
  style : @style.DocumentStyle
} derive(Eq, Debug)

pub extend StateDiagram with Eq::{not_equal, equal}
pub extend StateDiagram with Debug::{to_repr}


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