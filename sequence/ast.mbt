///|
#warnings("-unused_value")
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
#warnings("-unused_value")
priv struct ParticipantBox {
  label : String?
  color : String?
} derive(Eq)

///|
#warnings("-unused_value")
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
#warnings("-unused_value")
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
#warnings("-unused_value")
priv enum ArrowPart {
  Full
  TopPart
  BottomPart
}

///|
#warnings("-unused_value")
priv struct ArrowConfig {
  body : ArrowBody
  head1 : ArrowHead
  head2 : ArrowHead
  part : ArrowPart
  circle_start : Bool
  circle_end : Bool
}

///|
#warnings("-unused_value")
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
#warnings("-unused_value")
priv enum NoteStyle {
  NodeNormal
  Hexagonal
  Box
}

///|
#warnings("-unused_value")
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
#warnings("-unused_value")
priv enum ActivationSpec {
  Activate
  Deactivate
  Destroy
  Create
}

///|
#warnings("-unused_value")
priv struct GroupingStart {
  keyword : GroupKeyword
  header : String
  back_color_header : String?
  back_color_body : String?
  parallel : Bool
}

///|
#warnings("-unused_value")
priv struct GroupingLeaf {
  is_end : Bool
  label : String?
  back_color : String?
}

///|
#warnings("-unused_value")
priv struct Message {
  from_code : String
  to_code : String
  label : String?
  arrow_config : ArrowConfig
  parallel : Bool
  anchor : String?
  multicast : Array[String]
  activation_spec : ActivationSpec?
  life_color : String?
}

///|
#warnings("-unused_value")
priv enum MessageExoType {
  FromLeft
  ToLeft
  FromRight
  ToRight
}

///|
#warnings("-unused_value")
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
#warnings("-unused_value")
priv struct Note {
  participant_codes : Array[String]
  position : NotePosition
  text : String
  note_style : NoteStyle
  on_arrow : Bool
  color : String?
}

///|
#warnings("-unused_value")
priv struct Delay {
  label : String?
}

///|
#warnings("-unused_value")
priv struct Divider {
  title : String
}

///|
#warnings("-unused_value")
priv struct HSpace {
  pixels : Int?
}

///|
#warnings("-unused_value")
priv struct Newpage {
  title : String?
}

///|
#warnings("-unused_value")
priv struct Reference {
  participant_codes : Array[String]
  label : String?
}

///|
#warnings("-unused_value")
priv struct BoxStart {
  label : String?
  color : String?
}

///|
#warnings("-unused_value")
priv struct Autonumber {
  start : String?
  increment : Int?
  format : String?
}

///|
#warnings("-unused_value")
priv struct AutonumberResume {
  increment : Int?
  format : String?
}

///|
#warnings("-unused_value")
priv struct Return {
  value : String?
}

///|
#warnings("-unused_value")
priv struct LifeEvent {
  participant_code : String
  event_type : ActivationSpec
  color : String?
}

///|
#warnings("-unused_value")
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
  LinkAnchor(String, String, String?)
  Return(Return)
  Create
  Url(String, String)
  DeactivateLatest
  IgnoreNewpage
  AutoNewpage(Int?)
}

///|
#warnings("-unused_value")
struct SequenceDiagram {
  participants : Map[String, Participant]
  events : Array[Event]
  auto_number : Autonumber?
  autoactivate : Bool
  show_footbox : Bool
  style : @core.DocumentStyle
}
