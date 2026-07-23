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
  url : String?
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
  activating_messages : Array[String]
  mut last_message_from : String?
  mut last_message_to : String?
  style : @core.DocumentStyle
}

///|
fn ParseCtx::new(input : String) -> ParseCtx {
  {
    source: Source::new(@core.preprocess(input)),
    participants: Map([]),
    events: [],
    box_stack: [],
    grouping_depth: 0,
    pending_create: None,
    activating_messages: [],
    last_message_from: None,
    last_message_to: None,
    style: @core.DocumentStyle::empty(),
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
  guard is_new else {
    let participant = self.participants[reference.code]
    self.participants[reference.code] = {
      ..participant,
      boxes: self.box_stack.copy(),
    }
    return
  }
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
    url: declaration.url,
    order,
    boxes: self.box_stack.copy(),
  }
  if declaration.created {
    self.events.push(Create)
    self.pending_create = Some(reference.code)
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
    Url(code, url) => {
      self.ensure_participant(code, code, Participant)
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
fn ParseCtx::ensure_no_pending_create(self : ParseCtx) -> Unit raise ParseError {
  guard self.pending_create is Some(code) else { () }
  self.source.raise_parse_error("after create, send a message to \{code}")
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
          self.source.raise_parse_error(
            "after create, send a message to \{code}",
          )
      }
    None => ()
  }
  match event {
    GroupingStart(_) => self.grouping_depth += 1
    GroupingLeaf(leaf) => {
      guard self.grouping_depth > 0 else {
        self.source.raise_parse_error("group leaf without a group")
      }
      if leaf.is_end {
        self.grouping_depth -= 1
      }
    }
    BoxEnd => {
      guard !self.box_stack.is_empty() else {
        self.source.raise_parse_error("end box without a box")
      }
    }
    _ => ()
  }
}

///|
fn ParseCtx::resolve_event(
  self : ParseCtx,
  event : Event,
) -> Event raise ParseError {
  match event {
    DeactivateLatest =>
      match self.activating_messages.last() {
        Some(participant_code) => {
          let _ = self.activating_messages.pop()
          LifeEvent({ participant_code, event_type: Deactivate, color: None })
        }
        None => {
          let diagnostic = self.source.diagnostic("nothing to deactivate")
          raise SyntaxError(diagnostic.line_number(), diagnostic.message)
        }
      }
    _ => event
  }
}

///|
fn ParseCtx::push_event(
  self : ParseCtx,
  event : Event,
) -> Unit raise ParseError {
  let event = self.resolve_event(event)
  self.validate_event(event)
  self.register_event(event)
  self.events.push(event)
  match event {
    Message(message) => {
      self.last_message_from = Some(message.from_code)
      self.last_message_to = Some(message.to_code)
      match message.activation_spec {
        Some(Activate) | Some(Create) =>
          self.activating_messages.push(message.to_code)
        Some(Deactivate) | Some(Destroy) =>
          if self.activating_messages
            .last()
            .map_or(false, code => code == message.to_code) {
            let _ = self.activating_messages.pop()
          }
        None => ()
      }
    }
    LifeEvent(life) => {
      if life.event_type is Activate &&
        (
          self.last_message_from.map_or(false, code => {
            code == life.participant_code
          }) ||
          self.last_message_to.map_or(false, code => {
            code == life.participant_code
          })
        ) {
        self.activating_messages.push(life.participant_code)
      }
      if life.event_type is Deactivate || life.event_type is Destroy {
        if self.activating_messages
          .last()
          .map_or(false, code => code == life.participant_code) {
          let _ = self.activating_messages.pop()
        }
      }
    }
    _ => ()
  }
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
fn ArrowHead::has_direction(self : ArrowHead) -> Bool {
  !(self is NoneHead)
}
