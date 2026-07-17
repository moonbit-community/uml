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
  mut grouping_depth : Int
  mut pending_create : String?
}

///|
fn ParseCtx::new(input : String) -> ParseCtx {
  {
    source: Source::new(input),
    participants: Map([]),
    events: [],
    box_stack: [],
    grouping_depth: 0,
    pending_create: None,
  }
}

///|
fn ParseCtx::ensure_participant(
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
fn ParseCtx::declare_participant(
  self : ParseCtx,
  declaration : ParticipantDecl,
) -> Unit raise ParseError {
  self.ensure_no_pending_create()
  let reference = declaration.reference
  let is_new = !self.participants.contains(reference.code)
  self.ensure_participant(reference.code, reference.display, declaration.typ)
  let existing = self.participants[reference.code]
  let color = match declaration.color {
    Some(color) => Some(color)
    None => existing.color
  }
  let order = match declaration.order {
    Some(order) => Some(order)
    None => existing.order
  }
  self.participants[reference.code] = {
    ..existing,
    display: reference.display,
    typ: declaration.typ,
    color,
    order,
    boxes: self.box_stack.copy(),
  }
  if declaration.created {
    self.events.push(Create)
    if is_new {
      self.pending_create = Some(reference.code)
    }
  }
}

///|
fn ParseCtx::register_event(self : ParseCtx, event : Event) -> Unit {
  match event {
    Message(message) => {
      self.ensure_participant(message.from_code, message.from_code, Participant)
      self.ensure_participant(message.to_code, message.to_code, Participant)
      message.multicast.each(code => {
        self.ensure_participant(code, code, Participant)
      })
    }
    MessageExo(message) =>
      self.ensure_participant(
        message.participant_code,
        message.participant_code,
        Participant,
      )
    Note(note) =>
      note.participant_codes.each(code => {
        self.ensure_participant(code, code, Participant)
      })
    LifeEvent(life) =>
      self.ensure_participant(
        life.participant_code,
        life.participant_code,
        Participant,
      )
    BoxStart(box) => self.box_stack.push({ label: box.label, color: box.color })
    BoxEnd => {
      let _ = self.box_stack.pop()
      ()
    }
    _ => ()
  }
}

///|
fn ParseCtx::ensure_no_pending_create(self : ParseCtx) -> Unit raise ParseError {
  guard self.pending_create is Some(code) else { () }
  raise SyntaxError(
    self.source.line_number(),
    "after create, send a message to \{code}",
  )
}

///|
fn ParseCtx::validate_event(
  self : ParseCtx,
  event : Event,
) -> Unit raise ParseError {
  match self.pending_create {
    Some(code) =>
      match event {
        Message(message) if message.to_code == code =>
          self.pending_create = None
        _ =>
          raise SyntaxError(
            self.source.line_number(),
            "after create, send a message to \{code}",
          )
      }
    None => ()
  }
  match event {
    GroupingStart(_) => self.grouping_depth += 1
    GroupingLeaf(leaf) => {
      guard self.grouping_depth > 0 else {
        raise SyntaxError(
          self.source.line_number(),
          "group leaf without a group",
        )
      }
      if leaf.is_end {
        self.grouping_depth -= 1
      }
    }
    BoxEnd => {
      guard !self.box_stack.is_empty() else {
        raise SyntaxError(self.source.line_number(), "end box without a box")
      }
    }
    _ => ()
  }
}

///|
fn ParseCtx::push_event(
  self : ParseCtx,
  event : Event,
) -> Unit raise ParseError {
  self.validate_event(event)
  self.register_event(event)
  self.events.push(event)
}

///|
fn is_inline_whitespace(char : Char) -> Bool {
  char == ' ' || char == '\t' || char == '\r'
}

///|
fn is_ident_char(char : Char) -> Bool {
  char.is_ascii_alphabetic() ||
  char.is_ascii_digit() ||
  char == '_' ||
  char == '.' ||
  char == '@'
}

///|
fn is_arrow_char(char : Char) -> Bool {
  char == '-' ||
  char == '<' ||
  char == '>' ||
  char == 'o' ||
  char == 'x' ||
  char == '\\' ||
  char == '/' ||
  char == '[' ||
  char == ']' ||
  char == '#' ||
  char == '_' ||
  char == '(' ||
  char == ')'
}

///|
fn Source::try_color(self : Source) -> String? {
  let checkpoint = self.save()
  guard self.consume('#') else { return None }
  let color = self.take_while(c => !is_inline_whitespace(c) && c != '\n')
  guard color.length() > 0 else {
    self.restore(checkpoint)
    return None
  }
  Some(color)
}

///|
fn Source::try_anchor(self : Source) -> String? {
  let checkpoint = self.save()
  guard self.consume('{') else { return None }
  let anchor = self.take_while(is_ident_char)
  guard anchor.length() > 0 && self.consume('}') else {
    self.restore(checkpoint)
    return None
  }
  Some(anchor)
}

///|
fn Source::try_quoted_string(self : Source) -> String? {
  let checkpoint = self.save()
  guard self.consume('"') else { return None }
  let value = self.take_while(c => c != '"')
  guard self.consume('"') else {
    self.restore(checkpoint)
    return None
  }
  Some(value)
}

///|
fn ArrowHead::has_direction(self : ArrowHead) -> Bool {
  !(self is NoneHead)
}
