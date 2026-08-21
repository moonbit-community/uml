///|
priv struct TextSize {
  width : Int
  height : Int
}

///|
priv struct SequenceTextMetrics {
  participant : @metrics.FontMetrics
  note : @metrics.FontMetrics
  body : @metrics.FontMetrics
  body_bold : @metrics.FontMetrics
  body_italic : @metrics.FontMetrics
  small_bold : @metrics.FontMetrics
}

///|
fn SequenceTextMetrics::new(
  style : @style.DocumentStyle,
) -> SequenceTextMetrics {
  let base_size = style.font_size_value()
  let line_height = base_size + 2
  {
    participant: style.font_metrics(
      font_size=base_size,
      font_weight=700,
      line_height~,
    ),
    note: style.font_metrics(font_size=base_size, line_height~),
    body: style.font_metrics(font_size=(base_size - 1).max(1), line_height~),
    body_bold: style.font_metrics(
      font_size=(base_size - 1).max(1),
      font_weight=700,
      line_height~,
    ),
    body_italic: style.font_metrics(
      font_size=(base_size - 1).max(1),
      font_style=Italic,
      line_height~,
    ),
    small_bold: style.font_metrics(
      font_size=(base_size - 2).max(1),
      font_weight=700,
      line_height~,
    ),
  }
}

///|
priv struct ParticipantLayout {
  participant : Participant
  text_metrics : SequenceTextMetrics
  defaults : @style.SequenceColors
  index : Int
  center_x : Int
  width : Int
  birth_y : Int?
  death_y : Int?
}

///|
priv struct EventPlacement {
  y : Int
  height : Int
  number : String?
  ignored : Bool
}

///|
priv struct ActivationSpan {
  participant_code : String
  caller_code : String?
  depth : Int
  start_y : Int
  end_y : Int
  color : String?
}

///|
priv struct GroupSpan {
  start_y : Int
  end_y : Int
  depth : Int
  keyword : GroupKeyword
  header : String
  color : String?
  header_color : String?
  parallel : Bool
  first_participant : Int?
  last_participant : Int?
  branches : Array[GroupBranch]
}

///|
priv struct GroupBranch {
  start_y : Int
  end_y : Int
  label : String?
  color : String?
}

///|
priv struct DestroyMark {
  participant_code : String
  y : Int
}

///|
priv struct DiagramLayout {
  participants : Array[ParticipantLayout]
  participant_index : Map[String, Int]
  placements : Array[EventPlacement]
  activations : Array[ActivationSpan]
  groups : Array[GroupSpan]
  destroys : Array[DestroyMark]
  auto_page_breaks : Array[Int]
  width : Int
  height : Int
  body_top : Int
  body_bottom : Int
  text_metrics : SequenceTextMetrics
  defaults : @style.SequenceColors
}

///|
let horizontal_margin = 5

///|
let vertical_margin = 5

///|
let participant_edge_gap = 17

///|
fn TextSize::of_with(
  text : String,
  font_metrics : @metrics.FontMetrics,
) -> TextSize {
  let metrics = font_metrics.measure(text)
  { width: metrics.width, height: metrics.height }
}

///|
const MESSAGE_ARROW_OFFSET : Int = 18

///|
const MESSAGE_EVENT_HEIGHT : Int = 14

///|
const SELF_MESSAGE_EVENT_HEIGHT : Int = 42

///|
const SELF_MESSAGE_LOOP_DEPTH : Int = 28

///|
const MESSAGE_VISUAL_CLEARANCE : Int = 6

///|
fn Message::display_label(self : Message) -> String {
  self.label.unwrap_or("")
}

///|
fn Message::label_height(
  self : Message,
  text_metrics : SequenceTextMetrics,
) -> Int {
  match self.label {
    Some(label) if label.length() > 0 =>
      TextSize::of_with(label, text_metrics.body).height
    _ => 0
  }
}

///|
fn ParticipantType::header_height(self : ParticipantType) -> Int {
  self.symbol_height() +
  (match self {
    Actor | Boundary | Control | Entity | Database => 16
    Queue => 26
    Collections => 40
    Participant => 36
  })
}

///|
fn Note::height(self : Note, text_metrics : SequenceTextMetrics) -> Int {
  self.component(text_metrics).height
}

///|
fn Event::height(self : Event, text_metrics : SequenceTextMetrics) -> Int {
  match self {
    Message(message) =>
      if message.is_self() {
        SELF_MESSAGE_EVENT_HEIGHT
      } else {
        MESSAGE_EVENT_HEIGHT
      }
    MessageExo(_) => MESSAGE_EVENT_HEIGHT
    Note(note) => note.height(text_metrics) + 10
    Notes(notes) =>
      notes.fold(init=0, (acc, note) => acc.max(note.height(text_metrics))) + 10
    GroupingStart(_) => 22
    GroupingLeaf(leaf) => if leaf.is_end { 0 } else { 29 }
    LifeEvent(_) => 0
    Delay(_) => 28
    Divider(_) => 34
    HSpace(space) => space.pixels.unwrap_or(0)
    Newpage(_) => 40
    Reference(reference) =>
      (TextSize::of_with(reference.label.unwrap_or("ref"), text_metrics.body).height +
      28).max(42)
    BoxStart(_) | BoxEnd => 0
    Return(return_value) =>
      (TextSize::of_with(return_value.value.unwrap_or(""), text_metrics.body).height +
      24).max(34)
    Create => 0
    Url(_, _) => 0
    DeactivateLatest => 0
    LinkAnchor => 0
    Autonumber(_)
    | AutonumberStop
    | AutonumberResume(_)
    | AutonumberIncrement(_)
    | Autoactivate(_)
    | Footbox(_)
    | HideUnlinked(_)
    | IgnoreNewpage
    | AutoNewpage(_) => 0
  }
}

///|
fn Event::required_gap_before(
  self : Event,
  text_metrics : SequenceTextMetrics,
) -> Int {
  match self {
    Message(message) =>
      if message.is_self() {
        42
      } else if message.activation_spec is Some(Create) {
        message.label_height(text_metrics).max(15) + 44
      } else if message.label_height(text_metrics) > 0 {
        message.label_height(text_metrics) + 14
      } else {
        14
      }
    MessageExo(message) =>
      match message.label {
        Some(label) if label.length() > 0 =>
          TextSize::of_with(label, text_metrics.body).height + 14
        _ => 14
      }
    Note(note) => note.component(text_metrics).height + 18
    Notes(notes) =>
      notes.fold(init=0, (acc, note) => {
        acc.max(note.component(text_metrics).height)
      }) +
      18
    _ => self.height(text_metrics)
  }
}

///|
fn Event::participant_span(
  self : Event,
  participant_index : Map[String, Int],
) -> (Int, Int)? {
  let index_for = (code : String) => participant_index.get(code)
  let between = (first : String, last : String) => {
    match (index_for(first), index_for(last)) {
      (Some(left), Some(right)) => Some((left.min(right), left.max(right)))
      _ => None
    }
  }
  match self {
    Message(message) => between(message.from_code, message.to_code)
    MessageExo(message) =>
      index_for(message.participant_code).map(index => (index, index))
    Note(note) =>
      match (note.participant_codes.get(0), note.participant_codes.last()) {
        (Some(first), Some(last)) => between(first, last)
        _ => None
      }
    Notes(notes) => {
      let mut span : (Int, Int)? = None
      for note in notes {
        match (note.participant_codes.get(0), note.participant_codes.last()) {
          (Some(first), Some(last)) =>
            match between(first, last) {
              Some((left, right)) =>
                span = Some(
                  span.map_or((left, right), pair => {
                    let (span_left, span_right) = pair
                    (span_left.min(left), span_right.max(right))
                  }),
                )
              None => ()
            }
          _ => ()
        }
      }
      span
    }
    Reference(reference) =>
      match
        (reference.participant_codes.get(0), reference.participant_codes.last()) {
        (Some(first), Some(last)) => between(first, last)
        _ => None
      }
    LifeEvent(life) =>
      index_for(life.participant_code).map(index => (index, index))
    _ => None
  }
}

///|
fn GroupSpan::include_participant_span(
  self : GroupSpan,
  span : (Int, Int),
) -> GroupSpan {
  let (first, last) = span
  {
    ..self,
    first_participant: Some(
      self.first_participant.map_or(first, value => value.min(first)),
    ),
    last_participant: Some(
      self.last_participant.map_or(last, value => value.max(last)),
    ),
  }
}

///|
fn event_advances_layout(
  event : Event,
  text_metrics : SequenceTextMetrics,
) -> Bool {
  match event {
    Note(note) => !note.on_arrow
    Notes(notes) => !notes[0].on_arrow
    _ => event.height(text_metrics) > 0
  }
}

///|
fn next_visual_gap(
  events : Array[Event],
  index : Int,
  text_metrics : SequenceTextMetrics,
) -> Int {
  for next_index in (index + 1)..<events.length() {
    let next = events[next_index]
    if event_advances_layout(next, text_metrics) {
      return next.required_gap_before(text_metrics)
    }
  }
  14
}

///|
fn participant_code_index(
  participants : Array[ParticipantLayout],
) -> Map[String, Int] {
  let index : Map[String, Int] = Map([])
  for layout in participants {
    index[layout.participant.code] = layout.index
  }
  index
}

///|
fn Message::gap_requirement(
  self : Message,
  number : String?,
  text_metrics : SequenceTextMetrics,
) -> Int {
  // The participant gap already includes both half-widths and the group margin.
  let activation_lane = match self.activation_spec {
    Some(Activate) | Some(Create) => 10
    _ => 0
  }
  TextSize::of_with(self.rendered_label(number), text_metrics.body).width +
  38 +
  activation_lane
}

///|
fn Message::rendered_label(self : Message, number : String?) -> String {
  number.map_or_else(() => self.display_label(), number => {
    "\{number} \{self.display_label()}"
  })
}

///|
fn ParticipantBox::minimum_width(
  self : ParticipantBox,
  text_metrics : SequenceTextMetrics,
) -> Int {
  self.label.map_or(0, label => {
    TextSize::of_with(label, text_metrics.small_bold).width + 16
  })
}

///|
fn participant_box_horizontal_bounds(
  layouts : Array[ParticipantLayout],
  box : ParticipantBox,
) -> (Int, Int) {
  let first = layouts[0]
  let last = layouts[layouts.length() - 1]
  let mut left = first.center_x - first.width / 2 - 10
  let mut right = last.center_x + last.width / 2 + 10
  let missing = box.minimum_width(first.text_metrics) - (right - left)
  if missing > 0 {
    left -= missing / 2
    right += missing - missing / 2
  }
  (left, right)
}

///|
fn SequenceDiagram::participant_is_linked(
  self : SequenceDiagram,
  code : String,
) -> Bool {
  for event in self.events {
    match event {
      Message(message) =>
        if message.from_code == code || message.to_code == code {
          return true
        }
      MessageExo(message) => if message.participant_code == code { return true }
      Note(note) =>
        for participant in note.participant_codes {
          if participant == code {
            return true
          }
        }
      Notes(notes) =>
        for note in notes {
          for participant in note.participant_codes {
            if participant == code {
              return true
            }
          }
        }
      LifeEvent(life) => if life.participant_code == code { return true }
      Reference(reference) =>
        for participant in reference.participant_codes {
          if participant == code {
            return true
          }
        }
      _ => ()
    }
  }
  false
}

///|
fn SequenceDiagram::hides_unlinked(self : SequenceDiagram) -> Bool {
  self.events.fold(init=false, (hidden, event) => {
    if event is HideUnlinked(value) {
      value
    } else {
      hidden
    }
  })
}

///|
fn SequenceDiagram::minimum_text_width(
  self : SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> Int {
  let mut width = 0
  for event in self.events {
    let measured = match event {
      GroupingStart(group) =>
        TextSize::of_with(
          "\{group.keyword.label()} \{group.header}",
          text_metrics.body_bold,
        ).width +
        84
      GroupingLeaf(leaf) =>
        TextSize::of_with(leaf.label.unwrap_or(""), text_metrics.body_bold).width +
        84
      Divider(divider) =>
        TextSize::of_with(divider.title, text_metrics.body_bold).width + 44
      Newpage(page) =>
        TextSize::of_with(page.title.unwrap_or(""), text_metrics.body_italic).width +
        48
      Delay(delay) =>
        TextSize::of_with(delay.label.unwrap_or(""), text_metrics.body).width +
        56
      Reference(reference) =>
        TextSize::of_with(reference.label.unwrap_or("ref"), text_metrics.body).width +
        72
      Return(value) =>
        TextSize::of_with(value.value.unwrap_or(""), text_metrics.body).width +
        48
      LinkAnchor => 0
      BoxStart(box) =>
        TextSize::of_with(box.label.unwrap_or(""), text_metrics.small_bold).width +
        32
      _ => 0
    }
    width = width.max(measured)
  }
  width
}

///|
