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
  {
    source: Source::new(input),
    participants: Map([]),
    auto_order: 0,
    events: [],
  }
}

///|
fn ParseCtx::get_or_create(
  self : ParseCtx,
  code : String,
  display : String,
  typ : ParticipantType,
) -> Unit {
  guard !self.participants.contains(code) else { return }
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
      note.participant_codes.each(code => {
        self.get_or_create(code, code, Participant)
      })
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
fn is_inline_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\r'
}

///|
fn is_ident_char(c : Char) -> Bool {
  c.is_ascii_alphabetic() ||
  c.is_ascii_digit() ||
  c == '_' ||
  c == '.' ||
  c == '@'
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
fn ArrowHead::has_direction(self : ArrowHead) -> Bool {
  !(self is NoneHead)
}
