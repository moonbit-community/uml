///|
priv struct PartRef {
  code : String
  display : String
}

///|
priv struct ParticipantDecl {
  typ : @seq.ParticipantType
  reference : PartRef
  created : Bool
  color : String?
  url : String?
  order : Int?
}

///|
priv struct ParseCtx {
  source : @parse.Cursor
  participants : Map[String, @seq.Participant]
  events : Array[@seq.Event]
  box_stack : Array[@seq.ParticipantBox]
  mut grouping_depth : Int
  mut pending_create : String?
  activating_messages : Array[String]
  mut last_message_from : String?
  mut last_message_to : String?
  style : @style.DocumentStyle
}

///|
fn ParseCtx::new(input : String) -> ParseCtx {
  {
    source: @parse.Cursor::new(@parse.preprocess(input)),
    participants: Map([]),
    events: [],
    box_stack: [],
    grouping_depth: 0,
    pending_create: None,
    activating_messages: [],
    last_message_from: None,
    last_message_to: None,
    style: @style.DocumentStyle::empty(),
  }
}

///|
fn ParseCtx::ensure_participant(
  self : ParseCtx,
  code : String,
  display : String,
  typ : @seq.ParticipantType,
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
) -> Unit raise @parse.ParseError {
  self.ensure_no_pending_create()
  let reference = declaration.reference
  let is_new = !self.participants.contains(reference.code)
  guard is_new else {
    let participant = self.participants[reference.code]
    self.participants[reference.code] = {
      ..participant,
      display: reference.display,
      typ: declaration.typ,
      color: declaration.color.map_or(participant.color, value => Some(value)),
      url: declaration.url.map_or(participant.url, value => Some(value)),
      order: declaration.order.map_or(participant.order, value => Some(value)),
      boxes: self.box_stack.copy(),
    }
    return
  }
  self.ensure_participant(reference.code, reference.display, declaration.typ)
  let existing = self.participants[reference.code]
  let color = declaration.color.map_or(existing.color, value => Some(value))
  let order = declaration.order.map_or(existing.order, value => Some(value))
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
    self.events.push(@seq.Create)
    self.pending_create = Some(reference.code)
  }
}

///|
fn ParseCtx::register_event(self : ParseCtx, event : @seq.Event) -> Unit {
  match event {
    @seq.Message(message) => {
      self.ensure_participant(
        message.from_code,
        message.from_code,
        @seq.Participant,
      )
      self.ensure_participant(
        message.to_code,
        message.to_code,
        @seq.Participant,
      )
    }
    @seq.MessageExo(message) =>
      self.ensure_participant(
        message.participant_code,
        message.participant_code,
        @seq.Participant,
      )
    @seq.Note(note) =>
      note.participant_codes.each(code => {
        self.ensure_participant(code, code, @seq.Participant)
      })
    @seq.LifeEvent(life) =>
      self.ensure_participant(
        life.participant_code,
        life.participant_code,
        @seq.Participant,
      )
    @seq.Url(code, url) => {
      self.ensure_participant(code, code, @seq.Participant)
      let participant = self.participants[code]
      self.participants[code] = { ..participant, url: Some(url) }
    }
    @seq.BoxStart(box) =>
      self.box_stack.push({ label: box.label, color: box.color })
    @seq.BoxEnd => {
      let _ = self.box_stack.pop()
      ()
    }
    _ => ()
  }
}

///|
fn ParseCtx::ensure_no_pending_create(
  self : ParseCtx,
) -> Unit raise @parse.ParseError {
  guard self.pending_create is Some(code) else { () }
  self.source.raise_parse_error("after create, send a message to \{code}")
}

///|
fn ParseCtx::validate_event(
  self : ParseCtx,
  event : @seq.Event,
) -> Unit raise @parse.ParseError {
  if self.pending_create is Some(code) {
    match event {
      @seq.Message(message) if message.to_code == code =>
        self.pending_create = None
      _ =>
        self.source.raise_parse_error("after create, send a message to \{code}")
    }
  }
  match event {
    @seq.GroupingStart(_) => self.grouping_depth += 1
    @seq.GroupingLeaf(leaf) => {
      guard self.grouping_depth > 0 else {
        self.source.raise_parse_error("group leaf without a group")
      }
      if leaf.is_end {
        self.grouping_depth -= 1
      }
    }
    @seq.BoxEnd => {
      guard !self.box_stack.is_empty() else {
        self.source.raise_parse_error("end box without a box")
      }
    }
    _ => ()
  }
}

///|
/// Tracks the activating-message stack for a message activation
/// specifier, mirroring Java's `manageActivations`: `++`/`**` activate
/// the second participant, `--`/`!!` act on the first one.
fn ParseCtx::apply_message_activation(
  self : ParseCtx,
  spec : @seq.ActivationSpec?,
  message : @seq.Message,
) -> Unit {
  let participant = match spec {
    Some(@seq.Activate) | Some(@seq.Create) => message.to_code
    Some(@seq.Deactivate) | Some(@seq.Destroy) => message.from_code
    None => return
  }
  match spec {
    Some(@seq.Activate) | Some(@seq.Create) =>
      self.activating_messages.push(participant)
    Some(@seq.Deactivate) | Some(@seq.Destroy) =>
      if self.activating_messages
        .last()
        .map_or(false, code => code == participant) {
        let _ = self.activating_messages.pop()
      }
    None => ()
  }
}

///|
fn ParseCtx::resolve_event(
  self : ParseCtx,
  event : @seq.Event,
) -> @seq.Event raise @parse.ParseError {
  match event {
    @seq.DeactivateLatest =>
      match self.activating_messages.last() {
        Some(participant_code) => {
          let _ = self.activating_messages.pop()
          @seq.LifeEvent({
            participant_code,
            event_type: @seq.Deactivate,
            color: None,
          })
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
  event : @seq.Event,
) -> Unit raise @parse.ParseError {
  let event = self.resolve_event(event)
  self.validate_event(event)
  self.register_event(event)
  self.events.push(event)
  match event {
    @seq.Message(message) => {
      self.last_message_from = Some(message.from_code)
      self.last_message_to = Some(message.to_code)
      self.apply_message_activation(message.activation_spec, message)
      self.apply_message_activation(message.activation_spec2, message)
    }
    @seq.LifeEvent(life) => {
      if life.event_type is @seq.Activate &&
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
      if life.event_type is @seq.Deactivate || life.event_type is @seq.Destroy {
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
fn @seq.ArrowHead::has_direction(self : @seq.ArrowHead) -> Bool {
  !(self is @seq.NoneHead)
}
