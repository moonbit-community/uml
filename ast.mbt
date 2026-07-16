///|
enum ParticipantType {
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
struct Participant {
  code : String
  display : String
  typ : ParticipantType
  order : Int?
  stereotype : String?
  color : String?
  url : String?
  style : String?
}

///|
enum ArrowBody {
  Solid
  Dotted
  Hidden
}

///|
enum ArrowHead {
  Normal
  Async
  CrossX
  NoneHead
}

///|
enum ArrowPart {
  Full
  TopPart
  BottomPart
}

///|
struct ArrowConfig {
  body : ArrowBody
  head1 : ArrowHead
  head2 : ArrowHead
  part : ArrowPart
  circle_start : Bool
  circle_end : Bool
}

///|
enum NotePosition {
  Left
  Right
  Over
  OverSeveral
  Bottom
  Top
  Across
}

///|
enum NoteStyle {
  Normal
  Hexagonal
  Box
}

///|
enum GroupKeyword {
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
enum ActivationSpec {
  Activate
  Deactivate
  Destroy
  Create
}

///|
struct GroupingStart {
  keyword : GroupKeyword
  header : String
  label : String?
  back_color_header : String?
  back_color_body : String?
  parallel : Bool
}

///|
struct GroupingLeaf {
  is_end : Bool
  label : String?
  back_color : String?
}

///|
struct Message {
  from_code : String
  to_code : String
  label : String?
  arrow_config : ArrowConfig
  parallel : Bool
  anchor : String?
  multicast : Array[String]
  activation_spec : ActivationSpec?
  life_color : String?
  stereotype : String?
  url : String?
}

///|
enum MessageExoType {
  FromLeft
  ToLeft
  FromRight
  ToRight
}

///|
struct MessageExo {
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
struct Note {
  participant_codes : Array[String]
  position : NotePosition
  text : String
  note_style : NoteStyle
  on_arrow : Bool
  color : String?
}

///|
struct Delay {
  label : String?
}

///|
struct Divider {
  title : String
}

///|
struct HSpace {
  pixels : Int?
}

///|
struct Newpage {
  title : String?
}

///|
struct Reference {
  participant_codes : Array[String]
  label : String?
}

///|
struct BoxStart {
  label : String?
  color : String?
}

///|
struct Autonumber {
  start : Int?
  increment : Int?
  format : String?
}

///|
struct AutonumberResume {
  message_number : String?
  format : String?
}

///|
struct Return {
  value : String?
}

///|
struct LifeEvent {
  participant_code : String
  event_type : ActivationSpec
  color : String?
}

///|
enum Event {
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
  AutonumberIncrement(Int)
  Autoactivate(Bool)
  Footbox(Bool)
  HideUnlinked
  LinkAnchor(String, String)
  Return(Return)
  Create(Bool)
  UrlOf(String, String)
  IgnoreNewpage
  AutoNewpage(Int?)
}

///|
struct SequenceDiagram {
  participants : Map[String, Participant]
  events : Array[Event]
  auto_number : Autonumber?
  autoactivate : Bool
  show_footbox : Bool
}

///|
fn ArrowConfig::default() -> ArrowConfig {
  {
    body: Solid,
    head1: NoneHead,
    head2: NoneHead,
    part: Full,
    circle_start: false,
    circle_end: false,
  }
}

///|
fn ArrowConfig::with_body(self : ArrowConfig, body : ArrowBody) -> ArrowConfig {
  { ..self, body, }
}

///|
fn ArrowConfig::with_head1(self : ArrowConfig, head : ArrowHead) -> ArrowConfig {
  { ..self, head1: head }
}

///|
fn ArrowConfig::with_head2(self : ArrowConfig, head : ArrowHead) -> ArrowConfig {
  { ..self, head2: head }
}

///|
fn ArrowConfig::with_circle_start(self : ArrowConfig, v : Bool) -> ArrowConfig {
  { ..self, circle_start: v }
}

///|
fn ArrowConfig::with_circle_end(self : ArrowConfig, v : Bool) -> ArrowConfig {
  { ..self, circle_end: v }
}
