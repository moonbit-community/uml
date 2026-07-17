///|
#warnings("-unused_value")
priv struct PartRef {
  code : String
  display : String
}

///|
#warnings("-unused_value")
priv struct ParticipantDecl {
  typ : ParticipantType
  reference : PartRef
  created : Bool
  color : String?
  order : Int?
}

///|
#warnings("-unused_value")
priv struct DressingResult {
  head : ArrowHead
  circle : Bool
  cross : Bool
  has_dir : Bool
  part : ArrowPart
}

///|
#warnings("-unused_value")
priv struct ParseCtx {
  source : Source
  participants : Map[String, Participant]
  events : Array[Event]
  box_stack : Array[ParticipantBox]
}

///|
fn ParseCtx::new(input : String) -> ParseCtx {
  {
    source: Source::new(input),
    participants: Map([]),
    events: [],
    box_stack: [],
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
  self.participants[code] = {
    code,
    display,
    typ,
    order: Some(0),
    color: None,
    url: None,
    boxes: self.box_stack.copy(),
  }
}

///|
fn ParseCtx::register_event(self : ParseCtx, event : Event) -> Unit {
  match event {
    Message(message) => {
      self.get_or_create(message.from_code, message.from_code, Participant)
      self.get_or_create(message.to_code, message.to_code, Participant)
      message.multicast.each(code => self.get_or_create(code, code, Participant))
    }
    MessageExo(message) =>
      self.get_or_create(
        message.participant_code,
        message.participant_code,
        Participant,
      )
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
    UrlOf(code, url) => {
      self.get_or_create(code, code, Participant)
      let participant = self.participants[code]
      self.participants[code] = { ..participant, url: Some(url) }
    }
    BoxStart(box) => self.box_stack.push({ label: box.label, color: box.color })
    BoxEnd => {
      let _ = self.box_stack.pop()
      ()
    }
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
fn try_color(src : Source) -> String? {
  let saved = src.save()
  guard src.consume('#') else { return None }
  let color = src.take_while(c => !is_inline_whitespace(c) && c != '\n')
  guard color.length() > 0 else {
    src.restore(saved)
    return None
  }
  Some(color)
}

///|
fn try_anchor(src : Source) -> String? {
  let saved = src.save()
  guard src.consume('{') else { return None }
  let anchor = src.take_while(is_ident_char)
  guard anchor.length() > 0 && src.consume('}') else {
    src.restore(saved)
    return None
  }
  Some(anchor)
}

///|
fn try_quoted_string(src : Source) -> String? {
  let saved = src.save()
  guard src.consume('"') else { return None }
  let value = src.take_while(c => c != '"')
  guard src.consume('"') else {
    src.restore(saved)
    return None
  }
  Some(value)
}

///|
fn ArrowHead::has_direction(self : ArrowHead) -> Bool {
  !(self is NoneHead)
}
