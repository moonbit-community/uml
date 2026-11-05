///|
#derive(Eq, Debug)
pub(all) enum StateKind {
  Normal
  LegacyActivity
  Frame
  Initial
  Final
  History
  DeepHistory
  Synchronization
  Choice
}

///|
pub extend StateKind with Eq::{not_equal, equal}

///|
pub extend StateKind with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum TransitionDirection {
  Automatic
  Leftward
  Rightward
  Upward
  Downward
}

///|
pub extend TransitionDirection with Eq::{not_equal, equal}

///|
pub extend TransitionDirection with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StateNode {
  code : String
  display : String
  kind : StateKind
  parent : String?
  region_index : Int32
  description : String?
  embedded : @entity.Entity?
  standalone_note : StateNote?
  tags : Array[String]
  is_removed : Bool
  is_hidden : Bool
  stereotype : String?
  url : String?
  color : String?
}

///|
pub extend StateNode with Eq::{not_equal, equal}

///|
pub extend StateNode with Debug::{to_repr}

///|
pub fn StateNode::has_description(self : StateNode) -> Bool {
  self.description is Some(text) && text.length() > 0
}

///|
#derive(Eq, Debug)
pub(all) struct StateTransition {
  source : String
  target : String
  source_port : String?
  target_port : String?
  label : String?
  target_label : String?
  direction : TransitionDirection
  /// PlantUML link queue length, with horizontal directions reduced to one.
  length : Int32
  line_style : String?
  has_cross_start : Bool
  has_circle_end : Bool
}

///|
pub extend StateTransition with Eq::{not_equal, equal}

///|
pub extend StateTransition with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StateRegionSeparator {
  Horizontal
  Vertical
}

///|
pub extend StateRegionSeparator with Eq::{not_equal, equal}

///|
pub extend StateRegionSeparator with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StateRegion {
  parent : String
  /// Effective separator direction of the containing state; None for its
  /// initial region. All later regions share the container's orientation.
  separator : StateRegionSeparator?
  index : Int32
}

///|
pub extend StateRegion with Eq::{not_equal, equal}

///|
pub extend StateRegion with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StateNoteTarget {
  StateNote(String)
  NoteNote(Int32)
  TransitionNote(Int32)
}

///|
pub extend StateNoteTarget with Eq::{not_equal, equal}

///|
pub extend StateNoteTarget with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StateNotePosition {
  NoteLeft
  NoteRight
  NoteTop
  NoteBottom
}

///|
pub extend StateNotePosition with Eq::{not_equal, equal}

///|
pub extend StateNotePosition with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StateNoteTextMode {
  InlineText
  BlockText
}

///|
pub extend StateNoteTextMode with Eq::{not_equal, equal}

///|
pub extend StateNoteTextMode with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StateNote {
  target : StateNoteTarget
  /// Notes belong to their declaration scope, which may differ from the target.
  parent : String?
  region_index : Int32
  /// Block notes preserve backslash escapes; inline notes decode them for display.
  text_mode : StateNoteTextMode
  text : String
  color : String?
  position : StateNotePosition?
}

///|
pub extend StateNote with Eq::{not_equal, equal}

///|
pub extend StateNote with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StateDiagram {
  states : Array[StateNode]
  transitions : Array[StateTransition]
  notes : Array[StateNote]
  concurrent_regions : Array[String]
  regions : Array[StateRegion]
  style : @style.DocumentStyle
}

///|
pub extend StateDiagram with Eq::{not_equal, equal}

///|
pub extend StateDiagram with Debug::{to_repr}

///|
pub fn StateDiagram::hide_empty_description(self : StateDiagram) -> Bool {
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
