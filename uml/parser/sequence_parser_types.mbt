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
  order : Int32?
  stereotype : String?
}

///|
priv struct ParseCtx {
  source : @tokenizer.Cursor
  participants : Map[String, @seq.Participant]
  events : Array[@seq.Event]
  box_stack : Array[@seq.ParticipantBox]
  mut grouping_depth : Int32
  mut pending_create : String?
  activating_messages : Array[(@seq.Event, String)]
  mut last_message : @seq.Event?
  mut autoactivate : Bool
  mut next_participant_position : Int32
  mut last_message_from : String?
  mut last_message_to : String?
  style : @style.DocumentStyle
}

///|
fn ParseCtx::new(input : String) -> ParseCtx {
  {
    source: @tokenizer.Cursor::new(@tokenizer.preprocess(input)),
    participants: Map([]),
    events: [],
    box_stack: [],
    grouping_depth: 0,
    pending_create: None,
    activating_messages: [],
    last_message: None,
    autoactivate: false,
    next_participant_position: 0,
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
    position: self.next_participant_position,
    stereotype: None,
  }
  self.next_participant_position += 1
}

///|
fn ParseCtx::declare_participant(
  self : ParseCtx,
  declaration : ParticipantDecl,
) -> Unit raise @tokenizer.ParseError {
  self.ensure_no_pending_create()
  let reference = declaration.reference
  let is_new = !self.participants.contains(reference.code)
  guard is_new else {
    let participant = self.participants[reference.code]
    self.participants[reference.code] = {
      ..participant,
      position: self.next_participant_position,
    }
    self.next_participant_position += 1
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
    stereotype: declaration.stereotype,
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
        message.from_display,
        @seq.Participant,
      )
      self.ensure_participant(
        message.to_code,
        message.to_display,
        @seq.Participant,
      )
      for code in message.multicast {
        self.ensure_participant(code, code, @seq.Participant)
      }
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
      self.participants[code] = { ..participant, url: Some(url), }
    }
    @seq.BoxStart(box) =>
      self.box_stack.push({ label: box.label, color: box.color, })
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
) -> Unit raise @tokenizer.ParseError {
  guard self.pending_create is Some(code) else { () }
  self.source.raise_parse_error("after create, send a message to \{code}")
}

///|
fn ParseCtx::validate_event(
  self : ParseCtx,
  event : @seq.Event,
) -> Unit raise @tokenizer.ParseError {
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
    Some(@seq.Activate) | Some(@seq.Create) | Some(@seq.Destroy) =>
      message.to_code
    Some(@seq.Deactivate) => message.from_code
    None => return
  }
  match spec {
    Some(@seq.Activate) =>
      self.activating_messages.push((@seq.Message(message), participant))
    Some(@seq.Create) => ()
    Some(@seq.Deactivate) | Some(@seq.Destroy) =>
      if self.activating_messages
        .last()
        .map_or(false, pair => pair.1 == participant) {
        let _ = self.activating_messages.pop()
      }
    None => ()
  }
}

///|
fn ParseCtx::resolve_event(
  self : ParseCtx,
  event : @seq.Event,
) -> @seq.Event raise @tokenizer.ParseError {
  match event {
    @seq.Message(message) if self.pending_create == Some(message.to_code) =>
      @seq.Message({
        ..message,
        activation_spec: Some(@seq.Create),
        activation_spec2: message.activation_spec,
      })
    @seq.Return(value) => self.resolve_return(value)
    @seq.DeactivateLatest =>
      match self.activating_messages.last() {
        Some((_, participant_code)) => {
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
) -> Unit raise @tokenizer.ParseError {
  // CommandReturn already deactivates its activating call. Automatic arrow
  // activation is a CommandArrow behavior and must not run a second time.
  let returning = event is @seq.Return(_)
  let event = self.resolve_event(event)
  self.validate_event(event)
  self.register_event(event)
  self.events.push(event)
  match event {
    @seq.Message(message) => {
      self.last_message = Some(event)
      self.last_message_from = Some(message.from_code)
      self.last_message_to = Some(message.to_code)
      self.apply_message_activation(message.activation_spec, message)
      self.apply_message_activation(message.activation_spec2, message)
    }
    @seq.Autoactivate(enabled) => self.autoactivate = enabled
    @seq.MessageExo(message) => {
      self.last_message = Some(event)
      if message.activation_spec is Some(@seq.Activate) {
        self.activating_messages.push((event, message.participant_code))
      }
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
        if self.last_message is Some(message) {
          self.activating_messages.push((message, life.participant_code))
        }
      }
      if life.event_type is @seq.Deactivate || life.event_type is @seq.Destroy {
        if self.activating_messages
          .last()
          .map_or(false, pair => pair.1 == life.participant_code) {
          let _ = self.activating_messages.pop()
        }
      }
    }
    _ => ()
  }
  if !returning &&
    event is @seq.Message(message) &&
    self.autoactivate &&
    (
      message.arrow_config.head2 is @seq.Normal ||
      message.arrow_config.head2 is @seq.Async
    ) {
    let dotted = message.arrow_config.body is @seq.Dotted
    self.push_event(
      @seq.LifeEvent({
        participant_code: if dotted {
          message.from_code
        } else {
          message.to_code
        },
        event_type: if dotted {
          @seq.Deactivate
        } else {
          @seq.Activate
        },
        color: if dotted {
          None
        } else {
          message.life_color
        },
      }),
    )
  }
}

///|
fn is_ident_char(char : Char) -> Bool {
  @identifier.is_identifier_char(char) || char == '.' || char == '@'
}

///|
fn @seq.ArrowHead::has_direction(self : @seq.ArrowHead) -> Bool {
  !(self is @seq.NoneHead)
}
