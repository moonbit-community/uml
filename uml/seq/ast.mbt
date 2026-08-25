///|
pub(all) enum ParticipantType {
  Participant
  Actor
  Boundary
  Control
  Entity
  Database
  Queue
  Collections
}

///|
pub(all) struct ParticipantBox {
  label : String?
  color : String?
} derive(Eq)

///|
pub extend ParticipantBox with Eq::{not_equal, equal}

///|
pub(all) struct Participant {
  code : String
  display : String
  typ : ParticipantType
  order : Int?
  color : String?
  url : String?
  boxes : Array[ParticipantBox]
}

///|
pub(all) enum ArrowBody {
  Solid
  Dotted
} derive(Eq)

///|
pub extend ArrowBody with Eq::{not_equal, equal}

///|
pub(all) enum ArrowHead {
  Normal
  Async
  CrossX
  NoneHead
}

///|
pub(all) enum ArrowPart {
  Full
  TopPart
  BottomPart
}

///|
pub(all) struct ArrowConfig {
  body : ArrowBody
  head1 : ArrowHead
  head2 : ArrowHead
  part : ArrowPart
  circle_start : Bool
  circle_end : Bool
}

///|
pub(all) enum NotePosition {
  Left
  Right
  Bottom
  Top
  Over
  OverSeveral
  Across
}

///|
pub(all) enum NoteStyle {
  NodeNormal
  Hexagonal
  Box
}

///|
pub(all) enum GroupKeyword {
  Opt
  Alt
  Loop
  Par
  Par2
  Break
  Critical
  Group
  Partition
}

///|
pub(all) enum ActivationSpec {
  Activate
  Deactivate
  Destroy
  Create
}

///|
pub(all) struct GroupingStart {
  keyword : GroupKeyword
  header : String
  back_color_header : String?
  back_color_body : String?
  parallel : Bool
}

///|
pub(all) struct GroupingLeaf {
  is_end : Bool
  label : String?
  back_color : String?
}

///|
pub(all) struct Message {
  from_code : String
  to_code : String
  label : String?
  arrow_config : ArrowConfig
  anchor : String?
  activation_spec : ActivationSpec?
  activation_spec2 : ActivationSpec?
  life_color : String?
  stereotype : String?
  url : String?
}

///|
/// A self-message loops back to the same participant.
pub fn Message::is_self(self : Message) -> Bool {
  self.from_code == self.to_code
}

///|
pub(all) enum MessageExoType {
  FromLeft
  ToLeft
  FromRight
  ToRight
}

///|
pub(all) struct MessageExo {
  participant_code : String
  exo_type : MessageExoType
  label : String?
  arrow_config : ArrowConfig
  short_arrow : Bool
  activation_spec : ActivationSpec?
  life_color : String?
  url : String?
}

///|
pub(all) struct Note {
  participant_codes : Array[String]
  position : NotePosition
  text : String
  note_style : NoteStyle
  on_arrow : Bool
  color : String?
  stereotype : String?
  url : String?
}

///|
pub(all) struct Delay {
  label : String?
}

///|
pub(all) struct Divider {
  title : String
}

///|
pub(all) struct HSpace {
  pixels : Int?
}

///|
pub(all) struct Newpage {
  title : String?
}

///|
pub(all) struct Reference {
  participant_codes : Array[String]
  label : String?
}

///|
pub(all) struct BoxStart {
  label : String?
  color : String?
}

///|
pub(all) struct Autonumber {
  start : String?
  increment : Int?
  format : String?
}

///|
pub(all) struct AutonumberResume {
  increment : Int?
  format : String?
}

///|
pub(all) struct Return {
  value : String?
}

///|
pub(all) struct LifeEvent {
  participant_code : String
  event_type : ActivationSpec
  color : String?
}

///|
pub(all) enum Event {
  Message(Message)
  MessageExo(MessageExo)
  Note(Note)
  Notes(Array[Note])
  GroupingStart(GroupingStart)
  GroupingLeaf(GroupingLeaf)
  LifeEvent(LifeEvent)
  Delay(Delay)
  Divider(Divider)
  HSpace(HSpace)
  Newpage(Newpage)
  Reference(Reference)
  BoxStart(BoxStart)
  BoxEnd
  Autonumber(Autonumber)
  AutonumberStop
  AutonumberResume(AutonumberResume)
  AutonumberIncrement(String?)
  Autoactivate(Bool)
  Footbox(Bool)
  HideUnlinked(Bool)
  LinkAnchor
  Return(Return)
  Create
  Url(String, String)
  DeactivateLatest
  IgnoreNewpage
  AutoNewpage(Int?)
}

///|
pub(all) struct SequenceDiagram {
  participants : Map[String, Participant]
  events : Array[Event]
  autoactivate : Bool
  show_footbox : Bool
  style : @style.DocumentStyle
}
