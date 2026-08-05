///|
priv enum ParticipantType {
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
priv struct ParticipantBox {
  label : String?
  color : String?
} derive(Eq)

///|
priv struct Participant {
  code : String
  display : String
  typ : ParticipantType
  order : Int?
  color : String?
  url : String?
  boxes : Array[ParticipantBox]
}

///|
priv enum ArrowBody {
  Solid
  Dotted
} derive(Eq)

///|
priv enum ArrowHead {
  Normal
  Async
  CrossX
  NoneHead
}

///|
priv enum ArrowPart {
  Full
  TopPart
  BottomPart
}

///|
priv struct ArrowConfig {
  body : ArrowBody
  head1 : ArrowHead
  head2 : ArrowHead
  part : ArrowPart
  circle_start : Bool
  circle_end : Bool
}

///|
priv enum NotePosition {
  Left
  Right
  Bottom
  Top
  Over
  OverSeveral
  Across
}

///|
priv enum NoteStyle {
  NodeNormal
  Hexagonal
  Box
}

///|
priv enum GroupKeyword {
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
priv enum ActivationSpec {
  Activate
  Deactivate
  Destroy
  Create
}

///|
priv struct GroupingStart {
  keyword : GroupKeyword
  header : String
  back_color_header : String?
  back_color_body : String?
  parallel : Bool
}

///|
priv struct GroupingLeaf {
  is_end : Bool
  label : String?
  back_color : String?
}

///|
priv struct Message {
  from_code : String
  to_code : String
  label : String?
  arrow_config : ArrowConfig
  anchor : String?
  activation_spec : ActivationSpec?
  life_color : String?
}

///|
/// A self-message loops back to the same participant.
fn Message::is_self(self : Message) -> Bool {
  self.from_code == self.to_code
}

///|
priv enum MessageExoType {
  FromLeft
  ToLeft
  FromRight
  ToRight
}

///|
priv struct MessageExo {
  participant_code : String
  exo_type : MessageExoType
  label : String?
  arrow_config : ArrowConfig
  short_arrow : Bool
  activation_spec : ActivationSpec?
  life_color : String?
}

///|
priv struct Note {
  participant_codes : Array[String]
  position : NotePosition
  text : String
  note_style : NoteStyle
  on_arrow : Bool
  color : String?
}

///|
priv struct Delay {
  label : String?
}

///|
priv struct Divider {
  title : String
}

///|
priv struct HSpace {
  pixels : Int?
}

///|
priv struct Newpage {
  title : String?
}

///|
priv struct Reference {
  participant_codes : Array[String]
  label : String?
}

///|
priv struct BoxStart {
  label : String?
  color : String?
}

///|
priv struct Autonumber {
  start : String?
  increment : Int?
  format : String?
}

///|
priv struct AutonumberResume {
  increment : Int?
  format : String?
}

///|
priv struct Return {
  value : String?
}

///|
priv struct LifeEvent {
  participant_code : String
  event_type : ActivationSpec
  color : String?
}

///|
priv enum Event {
  Message(Message)
  MessageExo(MessageExo)
  Note(Note)
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
struct SequenceDiagram {
  participants : Map[String, Participant]
  events : Array[Event]
  autoactivate : Bool
  show_footbox : Bool
  style : @style.DocumentStyle
}
