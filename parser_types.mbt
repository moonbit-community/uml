///|
struct PartRef {
  code : String
  display : String
}

///|
struct ParticipantDecl {
  typ : ParticipantType
  reference : PartRef
  created : Bool
}

///|
struct DressingResult {
  head : ArrowHead
  circle : Bool
  cross : Bool
  has_dir : Bool
  part : ArrowPart
  inclination : Int
}

///|
struct ParseCtx {
  source : Source
  participants : Map[String, Participant]
  mut auto_order : Int
  events : Array[Event]
}

///|
fn ParseCtx::new(input : String) -> ParseCtx {
  { source: Source::new(input), participants: {}, auto_order: 0, events: [] }
}

///|
fn ParseCtx::get_or_create(
  self : ParseCtx,
  code : String,
  display : String,
  typ : ParticipantType,
) -> Unit {
  if self.participants.contains(code) {
    return
  }
  self.auto_order = self.auto_order + 1
  self.participants[code] = {
    code,
    display,
    typ,
    order: Some(self.auto_order),
    stereotype: None,
    color: None,
    url: None,
    style: None,
  }
}

///|
fn ParseCtx::register_event(self : ParseCtx, event : Event) -> Unit {
  match event {
    Message(message) => {
      self.get_or_create(message.from_code, message.from_code, Participant)
      self.get_or_create(message.to_code, message.to_code, Participant)
    }
    Note(note) =>
      for code in note.participant_codes {
        self.get_or_create(code, code, Participant)
      }
    LifeEvent(life) =>
      self.get_or_create(
        life.participant_code,
        life.participant_code,
        Participant,
      )
    _ => ()
  }
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_ident_char(c : Char) -> Bool {
  is_alpha(c) || is_digit(c) || c == '_' || c == '.' || c == '@'
}

///|
fn is_arrow_char(c : Char) -> Bool {
  c == '-' ||
  c == '<' ||
  c == '>' ||
  c == 'o' ||
  c == 'x' ||
  c == '\\' ||
  c == '/' ||
  c == '[' ||
  c == ']' ||
  c == '#' ||
  c == '_' ||
  c == '(' ||
  c == ')'
}

///|
fn is_none_head(h : ArrowHead) -> Bool {
  match h {
    NoneHead => true
    _ => false
  }
}
