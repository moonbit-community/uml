///|
priv struct TextSize {
  width : Int
  height : Int
}

///|
pub(all) struct SequenceTextMetrics {
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
pub(all) struct ParticipantLayout {
  participant : @seq.Participant
  text_metrics : SequenceTextMetrics
  defaults : @style.SequenceColors
  index : Int
  center_x : Int
  width : Int
  birth_y : Int?
  death_y : Int?
}

///|
pub(all) struct EventPlacement {
  y : Int
  height : Int
  number : String?
  ignored : Bool
}

///|
pub(all) struct ActivationSpan {
  participant_code : String
  caller_code : String?
  depth : Int
  start_y : Int
  end_y : Int
  color : String?
}

///|
pub(all) struct GroupSpan {
  start_y : Int
  end_y : Int
  depth : Int
  keyword : @seq.GroupKeyword
  header : String
  color : String?
  header_color : String?
  parallel : Bool
  first_participant : Int?
  last_participant : Int?
  branches : Array[GroupBranch]
}

///|
pub(all) struct GroupBranch {
  start_y : Int
  end_y : Int
  label : String?
  color : String?
}

///|
pub(all) struct DestroyMark {
  participant_code : String
  y : Int
}

///|
pub(all) struct DiagramLayout {
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
  { width: metrics.width, height: metrics.height, }
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
fn @seq.Message::display_label(self : @seq.Message) -> String {
  self.label.unwrap_or("")
}

///|
fn @seq.Message::label_height(
  self : @seq.Message,
  text_metrics : SequenceTextMetrics,
) -> Int {
  match self.label {
    Some(label) if label.length() > 0 =>
      TextSize::of_with(label, text_metrics.body).height
    _ => 0
  }
}

///|
fn @seq.ParticipantType::header_height(self : @seq.ParticipantType) -> Int {
  self.symbol_height() +
  (match self {
    Actor | Boundary | Control | Entity | Database => 16
    Queue => 26
    Collections => 40
    @seq.Participant => 36
  })
}

///|
fn @seq.Note::height(
  self : @seq.Note,
  text_metrics : SequenceTextMetrics,
) -> Int {
  self.component(text_metrics).height
}

///|
fn @seq.Event::height(
  self : @seq.Event,
  text_metrics : SequenceTextMetrics,
) -> Int {
  match self {
    @seq.Message(message) =>
      if message.is_self() {
        SELF_MESSAGE_EVENT_HEIGHT
      } else {
        MESSAGE_EVENT_HEIGHT
      }
    @seq.MessageExo(_) => MESSAGE_EVENT_HEIGHT
    @seq.Note(note) => note.height(text_metrics) + 10
    @seq.Notes(notes) =>
      notes.fold(init=0, (acc, note) => acc.max(note.height(text_metrics))) + 10
    @seq.GroupingStart(_) => 22
    @seq.GroupingLeaf(leaf) => if leaf.is_end { 0 } else { 29 }
    @seq.LifeEvent(_) => 0
    @seq.Delay(_) => 28
    @seq.Divider(_) => 34
    @seq.HSpace(space) => space.pixels.unwrap_or(0)
    @seq.Newpage(_) => 40
    @seq.Reference(reference) =>
      (TextSize::of_with(reference.label.unwrap_or("ref"), text_metrics.body).height +
      28).max(42)
    @seq.BoxStart(_) | @seq.BoxEnd => 0
    @seq.Return(return_value) =>
      (TextSize::of_with(return_value.value.unwrap_or(""), text_metrics.body).height +
      24).max(34)
    @seq.Create => 0
    @seq.Url(_, _) => 0
    @seq.DeactivateLatest => 0
    @seq.LinkAnchor => 0
    @seq.Autonumber(_)
    | @seq.AutonumberStop
    | @seq.AutonumberResume(_)
    | @seq.AutonumberIncrement(_)
    | @seq.Autoactivate(_)
    | @seq.Footbox(_)
    | @seq.HideUnlinked(_)
    | @seq.IgnoreNewpage
    | @seq.AutoNewpage(_) => 0
  }
}

///|
fn @seq.Event::required_gap_before(
  self : @seq.Event,
  text_metrics : SequenceTextMetrics,
) -> Int {
  match self {
    @seq.Message(message) =>
      if message.is_self() {
        42
      } else if message.activation_spec is Some(@seq.Create) {
        message.label_height(text_metrics).max(15) + 44
      } else if message.label_height(text_metrics) > 0 {
        message.label_height(text_metrics) + 14
      } else {
        14
      }
    @seq.MessageExo(message) =>
      match message.label {
        Some(label) if label.length() > 0 =>
          TextSize::of_with(label, text_metrics.body).height + 14
        _ => 14
      }
    @seq.Note(note) => note.component(text_metrics).height + 18
    @seq.Notes(notes) =>
      notes.fold(init=0, (acc, note) => {
        acc.max(note.component(text_metrics).height)
      }) +
      18
    _ => self.height(text_metrics)
  }
}

///|
fn @seq.Event::participant_span(
  self : @seq.Event,
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
    @seq.Message(message) => between(message.from_code, message.to_code)
    @seq.MessageExo(message) =>
      index_for(message.participant_code).map(index => (index, index))
    @seq.Note(note) =>
      match (note.participant_codes.get(0), note.participant_codes.last()) {
        (Some(first), Some(last)) => between(first, last)
        _ => None
      }
    @seq.Notes(notes) => {
      let mut span : (Int, Int)? = None
      for note in notes {
        if (note.participant_codes.get(0), note.participant_codes.last())
          is (Some(first), Some(last)) {
          if between(first, last) is Some((left, right)) {
            span = Some(
              span.map_or((left, right), pair => {
                let (span_left, span_right) = pair
                (span_left.min(left), span_right.max(right))
              }),
            )
          }
        }
      }
      span
    }
    @seq.Reference(reference) =>
      match
        (reference.participant_codes.get(0), reference.participant_codes.last()) {
        (Some(first), Some(last)) => between(first, last)
        _ => None
      }
    @seq.LifeEvent(life) =>
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
  event : @seq.Event,
  text_metrics : SequenceTextMetrics,
) -> Bool {
  match event {
    @seq.Note(note) => !note.on_arrow
    @seq.Notes(notes) => !notes[0].on_arrow
    _ => event.height(text_metrics) > 0
  }
}

///|
fn next_visual_gap(
  events : Array[@seq.Event],
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
fn @seq.Message::gap_requirement(
  self : @seq.Message,
  number : String?,
  text_metrics : SequenceTextMetrics,
) -> Int {
  // The participant gap already includes both half-widths and the group margin.
  let activation_lane = match self.activation_spec {
    Some(@seq.Activate) | Some(@seq.Create) => 10
    _ => 0
  }
  TextSize::of_with(self.rendered_label(number), text_metrics.body).width +
  38 +
  activation_lane
}

///|
fn @seq.Message::rendered_label(
  self : @seq.Message,
  number : String?,
) -> String {
  number.map_or_else(() => self.display_label(), number => {
    "\{number} \{self.display_label()}"
  })
}

///|
fn @seq.ParticipantBox::minimum_width(
  self : @seq.ParticipantBox,
  text_metrics : SequenceTextMetrics,
) -> Int {
  self.label.map_or(0, label => {
    TextSize::of_with(label, text_metrics.small_bold).width + 16
  })
}

///|
fn participant_box_horizontal_bounds(
  layouts : Array[ParticipantLayout],
  box : @seq.ParticipantBox,
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
/// The maximum participant-box nesting depth across the layouts.
///
/// Shared by the participant-box painters and constrains; do not re-fold the
/// depths locally.
fn max_participant_box_depth(layouts : Array[ParticipantLayout]) -> Int {
  layouts.fold(init=0, (depth, layout) => {
    depth.max(layout.participant.boxes.length())
  })
}

///|
/// Walk one box depth, invoking `run` for each maximal run of layouts that
/// share the same box at that depth.
///
/// The box painters, the content-bounds pass, and the gap constrains all
/// need this run-length split; keep it here rather than re-implementing it.
fn for_each_participant_box_run(
  layouts : Array[ParticipantLayout],
  depth : Int,
  run : (Int, Int, @seq.ParticipantBox) -> Unit,
) -> Unit {
  let mut active : @seq.ParticipantBox? = None
  let mut start = 0
  for index, layout in layouts {
    let current = layout.participant.boxes.get(depth)
    if current != active {
      if active is Some(box) {
        run(start, index, box)
      }
      active = current
      start = index
    }
  }
  if active is Some(box) {
    run(start, layouts.length(), box)
  }
}

///|
fn @seq.SequenceDiagram::participant_is_linked(
  self : @seq.SequenceDiagram,
  code : String,
) -> Bool {
  for event in self.events {
    match event {
      @seq.Message(message) =>
        if message.from_code == code || message.to_code == code {
          return true
        }
      @seq.MessageExo(message) =>
        if message.participant_code == code {
          return true
        }
      @seq.Note(note) =>
        for participant in note.participant_codes {
          if participant == code {
            return true
          }
        }
      @seq.Notes(notes) =>
        for note in notes {
          for participant in note.participant_codes {
            if participant == code {
              return true
            }
          }
        }
      @seq.LifeEvent(life) => if life.participant_code == code { return true }
      @seq.Reference(reference) =>
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
fn @seq.SequenceDiagram::hides_unlinked(self : @seq.SequenceDiagram) -> Bool {
  self.events.fold(init=false, (hidden, event) => {
    if event is @seq.HideUnlinked(value) {
      value
    } else {
      hidden
    }
  })
}

///|
fn @seq.SequenceDiagram::minimum_text_width(
  self : @seq.SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> Int {
  let mut width = 0
  for event in self.events {
    let measured = match event {
      @seq.GroupingStart(group) =>
        TextSize::of_with(
          "\{group.keyword.label()} \{group.header}",
          text_metrics.body_bold,
        ).width +
        84
      @seq.GroupingLeaf(leaf) =>
        TextSize::of_with(leaf.label.unwrap_or(""), text_metrics.body_bold).width +
        84
      @seq.Divider(divider) =>
        TextSize::of_with(divider.title, text_metrics.body_bold).width + 44
      @seq.Newpage(page) =>
        TextSize::of_with(page.title.unwrap_or(""), text_metrics.body_italic).width +
        48
      @seq.Delay(delay) =>
        TextSize::of_with(delay.label.unwrap_or(""), text_metrics.body).width +
        56
      @seq.Reference(reference) =>
        TextSize::of_with(reference.label.unwrap_or("ref"), text_metrics.body).width +
        72
      @seq.Return(value) =>
        TextSize::of_with(value.value.unwrap_or(""), text_metrics.body).width +
        48
      @seq.LinkAnchor => 0
      @seq.BoxStart(box) =>
        TextSize::of_with(box.label.unwrap_or(""), text_metrics.small_bold).width +
        32
      _ => 0
    }
    width = width.max(measured)
  }
  width
}

///|
