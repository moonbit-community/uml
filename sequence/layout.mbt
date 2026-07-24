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
fn SequenceTextMetrics::new(style : @core.DocumentStyle) -> SequenceTextMetrics {
  let base_size = @core.font_size_value(style)
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
  let metrics = @metrics.measure_text_with(text, font_metrics)
  { width: metrics.width, height: metrics.height }
}

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
  match self {
    Actor => 76
    Boundary | Control | Entity => 48
    Database => 67
    Queue => 26
    Collections => 40
    Participant => 36
  }
}

///|
fn Note::height(self : Note, text_metrics : SequenceTextMetrics) -> Int {
  self.component(text_metrics).height
}

///|
fn Event::height(self : Event, text_metrics : SequenceTextMetrics) -> Int {
  match self {
    Message(message) =>
      if message.from_code == message.to_code {
        42
      } else {
        14
      }
    MessageExo(_) => 14
    Note(note) => note.height(text_metrics) + 10
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
      if message.from_code == message.to_code {
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
  number
  .map(number => "\{number} \{self.display_label()}")
  .unwrap_or_else(() => self.display_label())
}

///|
fn ParticipantBox::minimum_width(
  self : ParticipantBox,
  text_metrics : SequenceTextMetrics,
) -> Int {
  match self.label {
    Some(label) => TextSize::of_with(label, text_metrics.small_bold).width + 16
    None => 0
  }
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
      Message(message) => {
        if message.from_code == code || message.to_code == code {
          return true
        }
        for target in message.multicast {
          if target == code {
            return true
          }
        }
      }
      MessageExo(message) => if message.participant_code == code { return true }
      Note(note) =>
        for participant in note.participant_codes {
          if participant == code {
            return true
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
  let mut hidden = false
  for event in self.events {
    match event {
      HideUnlinked(value) => hidden = value
      _ => ()
    }
  }
  hidden
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
fn increment_autonumber(value : String, increment : Int) -> String {
  let parts = value.split(".").to_array()
  guard parts.length() > 0 else { "\{increment}" }
  let last_index = parts.length() - 1
  let last = parts[last_index].to_owned()
  let next = @string.parse_int(last) catch { _ => 0 }
  let output = StringBuilder()
  for index, part in parts {
    if index > 0 {
      output.write_char('.')
    }
    if index == last_index {
      output <+ "\{next + increment}"
    } else {
      output.write_string(part.to_owned())
    }
  }
  output.to_string()
}

///|
fn format_autonumber(format : String, value : String) -> String {
  if format.contains("#") {
    format.replace(old="#", new=value)
  } else {
    format.replace(old="0", new=value)
  }
}

///|
fn increment_autonumber_part(
  value : String,
  position : String?,
  increment : Int,
) -> String {
  let parts = value.split(".").to_array()
  guard parts.length() > 0 else {
    return increment_autonumber(value, increment)
  }
  let index = match position {
    Some(letter) if letter.length() > 0 => {
      let chars = letter.to_array()
      let value = chars[0].to_int() - 'a'.to_int()
      value.max(0).min(parts.length() - 1)
    }
    _ => parts.length() - 1
  }
  let output = StringBuilder()
  for part_index, part in parts {
    if part_index > 0 {
      output.write_char('.')
    }
    if part_index == index {
      let number = @string.parse_int(part) catch { _ => 0 }
      output <+ "\{number + increment}"
    } else {
      output.write_string(part.to_owned())
    }
  }
  output.to_string()
}

///|
fn constrain_message_gap(
  gaps : Array[Int],
  participant_index : Map[String, Int],
  message : Message,
  number : String?,
  text_metrics : SequenceTextMetrics,
) -> Unit {
  guard participant_index.get(message.from_code) is Some(from) else { return }
  guard participant_index.get(message.to_code) is Some(to) else { return }
  let first = if from < to { from } else { to }
  let last = if from < to { to } else { from }
  let span = last - first
  guard span > 0 else { return }
  let required = message.gap_requirement(number, text_metrics)
  let per_gap = (required + span - 1) / span
  for index in first..<last {
    gaps[index] = gaps[index].max(per_gap)
  }
}

///|
fn constrain_note_gap(
  gaps : Array[Int],
  participant_index : Map[String, Int],
  note : Note,
  text_metrics : SequenceTextMetrics,
) -> Unit {
  guard note.position is OverSeveral else { return }
  guard note.participant_codes.get(0) is Some(first_code) else { return }
  guard note.participant_codes.last() is Some(last_code) else { return }
  guard participant_index.get(first_code) is Some(first) else { return }
  guard participant_index.get(last_code) is Some(last) else { return }
  let left = first.min(last)
  let right = first.max(last)
  let span = right - left
  guard span > 0 else { return }
  let required = note.component(text_metrics).width
  let per_gap = (required + span - 1) / span
  for index in left..<right {
    gaps[index] = gaps[index].max(per_gap)
  }
}

///|
fn constrain_participant_box_gap(
  gaps : Array[Int],
  layouts : Array[ParticipantLayout],
  start : Int,
  end : Int,
  box : ParticipantBox,
  text_metrics : SequenceTextMetrics,
) -> Unit {
  let gap_count = end - start - 1
  guard gap_count > 0 else { return }
  let mut available = layouts[start].width / 2 + layouts[end - 1].width / 2 + 20
  for index in start..<(end - 1) {
    available += gaps[index]
  }
  let missing = box.minimum_width(text_metrics) - available
  guard missing > 0 else { return }
  let extra_per_gap = (missing + gap_count - 1) / gap_count
  for index in start..<(end - 1) {
    gaps[index] += extra_per_gap
  }
}

///|
fn constrain_participant_box_gaps(
  gaps : Array[Int],
  layouts : Array[ParticipantLayout],
  text_metrics : SequenceTextMetrics,
) -> Unit {
  let mut max_depth = 0
  for layout in layouts {
    max_depth = max_depth.max(layout.participant.boxes.length())
  }
  for depth in 0..<max_depth {
    let mut active : ParticipantBox? = None
    let mut start = 0
    for index, layout in layouts {
      let current = layout.participant.boxes.get(depth)
      if current != active {
        match active {
          Some(box) =>
            constrain_participant_box_gap(
              gaps, layouts, start, index, box, text_metrics,
            )
          None => ()
        }
        active = current
        start = index
      }
    }
    match active {
      Some(box) =>
        constrain_participant_box_gap(
          gaps,
          layouts,
          start,
          layouts.length(),
          box,
          text_metrics,
        )
      None => ()
    }
  }
}

///|
fn SequenceDiagram::participant_box_header_height(
  self : SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> Int {
  let mut max_depth = 0
  for _, participant in self.participants {
    max_depth = max_depth.max(participant.boxes.length())
  }
  max_depth * (text_metrics.small_bold.line_height + 5)
}

///|
fn initial_participant_layout(
  diagram : SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> Array[ParticipantLayout] {
  let layouts = []
  let mut index = 0
  let hide_unlinked = diagram.hides_unlinked()
  for _, participant in diagram.participants {
    guard !hide_unlinked || diagram.participant_is_linked(participant.code) else {
      continue
    }
    let width = (TextSize::of_with(
      participant.display,
      text_metrics.participant,
    ).width +
    14).max(32)
    layouts.push({
      participant,
      text_metrics,
      index,
      center_x: 0,
      width,
      birth_y: None,
      death_y: None,
    })
    index = index + 1
  }
  for current in 0..<layouts.length() {
    let mut first = current
    for candidate in (current + 1)..<layouts.length() {
      let candidate_order = layouts[candidate].participant.order.unwrap_or(0)
      let first_order = layouts[first].participant.order.unwrap_or(0)
      if candidate_order < first_order {
        first = candidate
      }
    }
    if first != current {
      let saved = layouts[current]
      layouts[current] = layouts[first]
      layouts[first] = saved
    }
  }
  for index, participant in layouts {
    layouts[index] = { ..participant, index, }
  }
  layouts
}

///|
fn layout_participants(
  diagram : SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> (Array[ParticipantLayout], Map[String, Int], Int) {
  let layouts = initial_participant_layout(diagram, text_metrics)
  let index = participant_code_index(layouts)
  guard layouts.length() > 0 else { (layouts, index, horizontal_margin * 2) }

  let gaps = []
  for participant_index in 0..<(layouts.length() - 1) {
    let left = layouts[participant_index]
    let right = layouts[participant_index + 1]
    gaps.push(left.width / 2 + right.width / 2 + 21)
  }
  let mut autonumber = false
  let mut next_number = "1"
  let mut number_increment = 1
  let mut number_format : String? = None
  for event in diagram.events {
    match event {
      Message(message) => {
        let number = if autonumber {
          let value = next_number
          next_number = increment_autonumber(next_number, number_increment)
          match number_format {
            Some(format) => Some(format_autonumber(format, value))
            None => Some(value)
          }
        } else {
          None
        }
        constrain_message_gap(gaps, index, message, number, text_metrics)
      }
      Note(note) => constrain_note_gap(gaps, index, note, text_metrics)
      Autonumber(config) => {
        autonumber = true
        next_number = config.start.unwrap_or("1")
        number_increment = config.increment.unwrap_or(1)
        number_format = config.format
      }
      AutonumberStop => autonumber = false
      AutonumberResume(config) => {
        autonumber = true
        number_increment = config.increment.unwrap_or(number_increment)
        number_format = match config.format {
          Some(format) => Some(format)
          None => number_format
        }
      }
      AutonumberIncrement(position) =>
        next_number = increment_autonumber_part(
          next_number, position, number_increment,
        )
      _ => ()
    }
  }
  constrain_participant_box_gaps(gaps, layouts, text_metrics)

  let mut center_x = horizontal_margin + layouts[0].width / 2
  layouts[0] = { ..layouts[0], center_x, }
  for participant_index in 1..<layouts.length() {
    center_x = center_x + gaps[participant_index - 1]
    layouts[participant_index] = { ..layouts[participant_index], center_x, }
  }
  let last = layouts[layouts.length() - 1]
  (layouts, index, last.center_x + last.width / 2 + horizontal_margin)
}

///|
fn activation_depth(
  active : Map[String, Array[Int]],
  participant_code : String,
) -> Int {
  active.get(participant_code).map_or(0, spans => spans.length())
}

///|
fn start_activation(
  activations : Array[ActivationSpan],
  active : Map[String, Array[Int]],
  participant_code : String,
  caller_code : String?,
  y : Int,
  color : String?,
) -> Unit {
  let depth = activation_depth(active, participant_code)
  activations.push({
    participant_code,
    caller_code,
    depth,
    start_y: y,
    end_y: y + 18,
    color,
  })
  let indices = active.get(participant_code).unwrap_or([])
  indices.push(activations.length() - 1)
  active[participant_code] = indices
}

///|
fn finish_activation(
  activations : Array[ActivationSpan],
  active : Map[String, Array[Int]],
  participant_code : String,
  y : Int,
) -> Bool {
  guard active.get(participant_code) is Some(indices) else { false }
  guard indices.pop() is Some(index) else { false }
  let activation = activations[index]
  activations[index] = { ..activation, end_y: y.max(activation.start_y + 12) }
  if indices.length() == 0 {
    active.remove(participant_code)
  } else {
    active[participant_code] = indices
  }
  true
}

///|
fn apply_activation_spec(
  spec : ActivationSpec?,
  participant_code : String,
  caller_code : String?,
  y : Int,
  color : String?,
  activations : Array[ActivationSpan],
  active : Map[String, Array[Int]],
  destroys : Array[DestroyMark],
) -> Unit {
  match spec {
    Some(Activate) =>
      start_activation(
        activations, active, participant_code, caller_code, y, color,
      )
    Some(Create) => ()
    Some(Deactivate) => {
      let _ = finish_activation(activations, active, participant_code, y)
      ()
    }
    Some(Destroy) => {
      let _ = finish_activation(activations, active, participant_code, y)
      destroys.push({ participant_code, y })
    }
    None => ()
  }
}

///|
fn layout_events(
  diagram : SequenceDiagram,
  participant_index : Map[String, Int],
  start_y : Int,
  text_metrics : SequenceTextMetrics,
) -> (
  Array[EventPlacement],
  Array[ActivationSpan],
  Array[GroupSpan],
  Array[DestroyMark],
  Array[Int],
  Int,
) {
  let placements = []
  let activations = []
  let groups = []
  let destroys = []
  let active : Map[String, Array[Int]] = Map([])
  let group_stack = []
  let mut current_y = start_y
  let mut previous_top = current_y
  let mut parallel_bottom = current_y
  let mut last_visual_bottom = start_y
  let mut last_message_to : String? = None
  let mut last_message_arrow_y : Int? = None
  let mut autoactivate = diagram.autoactivate
  let mut ignore_newpage = false
  let auto_page_breaks = []
  let mut auto_newpage : Int? = None
  let mut messages_since_auto_newpage = 0
  let mut autonumber = false
  let mut next_number = diagram.auto_number.map_or("1", config => {
    config.start.unwrap_or("1")
  })
  let mut number_increment = diagram.auto_number.map_or(1, config => {
    config.increment.unwrap_or(1)
  })
  let mut number_format : String? = diagram.auto_number.map_or(None, config => {
    config.format
  })

  for event_index, event in diagram.events {
    // Auto pagination is a layout marker inserted before the next message;
    // it keeps the parsed event stream unchanged for metadata and numbering.
    let auto_page_break = match auto_newpage {
      Some(threshold) if threshold > 0 &&
        messages_since_auto_newpage >= threshold =>
        event is Message(_) || event is MessageExo(_)
      _ => false
    }
    if auto_page_break {
      auto_page_breaks.push(current_y + 20)
      current_y += 40
      previous_top += 40
      parallel_bottom += 40
      last_visual_bottom += 40
      messages_since_auto_newpage = 0
    }
    let ignored = event is Newpage(_) && ignore_newpage
    let event_height = if ignored { 0 } else { event.height(text_metrics) }
    let advances = !ignored && event_advances_layout(event, text_metrics)
    let height = if !advances {
      0
    } else if event is Note(_) {
      event_height
    } else {
      event_height.max(
        next_visual_gap(diagram.events, event_index, text_metrics),
      )
    }
    let y = match event {
      Note(note) if note.on_arrow => previous_top + 4
      _ => current_y
    }
    let number = match event {
      Message(_) | MessageExo(_) | Return(_) if autonumber => {
        let value = next_number
        next_number = increment_autonumber(next_number, number_increment)
        match number_format {
          Some(format) => Some(format_autonumber(format, value))
          None => Some(value)
        }
      }
      _ => None
    }
    placements.push({ y, height, number, ignored })
    if !advances {
      ()
    } else {
      previous_top = y
      parallel_bottom = y + height
      current_y = parallel_bottom
    }

    match event.participant_span(participant_index) {
      Some(span) =>
        for group_index in group_stack {
          let group = groups[group_index]
          groups[group_index] = GroupSpan::include_participant_span(group, span)
        }
      None => ()
    }

    match event {
      Message(message) => {
        messages_since_auto_newpage += 1
        let arrow_extra = if message.from_code == message.to_code {
          28
        } else {
          6
        }
        last_visual_bottom = last_visual_bottom.max(y + 18 + arrow_extra)
        apply_activation_spec(
          message.activation_spec,
          message.to_code,
          Some(message.from_code),
          y + 18,
          message.life_color,
          activations,
          active,
          destroys,
        )
        if autoactivate &&
          message.activation_spec is None &&
          message.arrow_config.body != Dotted {
          start_activation(
            activations,
            active,
            message.to_code,
            Some(message.from_code),
            y + 18,
            None,
          )
        }
        last_message_to = Some(message.to_code)
        last_message_arrow_y = Some(y + 18)
      }
      MessageExo(message) => {
        messages_since_auto_newpage += 1
        last_visual_bottom = last_visual_bottom.max(y + 18)
        apply_activation_spec(
          message.activation_spec,
          message.participant_code,
          None,
          y + height,
          message.life_color,
          activations,
          active,
          destroys,
        )
        last_message_to = Some(message.participant_code)
        last_message_arrow_y = Some(y + 18)
      }
      LifeEvent(life) => {
        let life_y = if life.event_type is Activate &&
          last_message_to == Some(life.participant_code) {
          last_message_arrow_y.unwrap_or(y)
        } else {
          y
        }
        apply_activation_spec(
          Some(life.event_type),
          life.participant_code,
          None,
          life_y,
          life.color,
          activations,
          active,
          destroys,
        )
      }
      GroupingStart(group) => {
        groups.push({
          start_y: y,
          end_y: y + height,
          depth: group_stack.length(),
          keyword: group.keyword,
          header: group.header,
          color: group.back_color_header,
          header_color: group.back_color_body,
          parallel: group.parallel,
          first_participant: None,
          last_participant: None,
          branches: [
            { start_y: y, end_y: y + height, label: None, color: None },
          ],
        })
        group_stack.push(groups.length() - 1)
      }
      GroupingLeaf(leaf) =>
        if group_stack.last() is Some(index) {
          let group = groups[index]
          let branch_index = group.branches.length() - 1
          let branches = group.branches
          let end_y = y.max(last_visual_bottom)
          branches[branch_index] = { ..branches[branch_index], end_y, }
          if leaf.is_end {
            groups[index] = { ..group, end_y, branches }
            let _ = group_stack.pop()
          } else {
            let branch_color = match leaf.back_color {
              Some(color) => Some(color)
              None => if group.parallel { group.color } else { None }
            }
            branches.push({
              start_y: y,
              end_y: y,
              label: leaf.label,
              color: branch_color,
            })
            groups[index] = { ..group, branches, }
          }
        }
      Autoactivate(enabled) => autoactivate = enabled
      Autonumber(config) => {
        autonumber = true
        next_number = config.start.unwrap_or("1")
        number_increment = config.increment.unwrap_or(1)
        number_format = config.format
      }
      AutonumberStop => autonumber = false
      AutonumberResume(config) => {
        autonumber = true
        number_increment = config.increment.unwrap_or(number_increment)
        number_format = match config.format {
          Some(format) => Some(format)
          None => number_format
        }
      }
      AutonumberIncrement(position) =>
        next_number = increment_autonumber_part(
          next_number, position, number_increment,
        )
      IgnoreNewpage => ignore_newpage = true
      AutoNewpage(size) => {
        auto_newpage = size
        messages_since_auto_newpage = 0
      }
      _ => ()
    }
  }

  current_y = current_y.max(last_visual_bottom + participant_edge_gap - 9)

  for _, indices in active {
    for index in indices {
      let activation = activations[index]
      activations[index] = { ..activation, end_y: current_y }
    }
  }
  for index in group_stack {
    let group = groups[index]
    let branch_index = group.branches.length() - 1
    let branches = group.branches
    let end_y = current_y.max(last_visual_bottom)
    branches[branch_index] = { ..branches[branch_index], end_y, }
    groups[index] = { ..group, end_y, branches }
  }
  (placements, activations, groups, destroys, auto_page_breaks, current_y)
}

///|
fn DiagramLayout::note_anchor_center(
  self : DiagramLayout,
  note : Note,
  arrow_anchor : Message?,
) -> Int {
  guard note.on_arrow else {
    match note.participant_codes.get(0) {
      Some(code) =>
        self
        .participant_at(code)
        .map_or(self.width / 2, participant => participant.center_x)
      None => self.width / 2
    }
  }
  match arrow_anchor {
    Some(message) => {
      let from = self
        .participant_at(message.from_code)
        .map_or(self.width / 2, participant => participant.center_x)
      let to = self
        .participant_at(message.to_code)
        .map_or(self.width / 2, participant => participant.center_x)
      (from + to) / 2
    }
    None => self.width / 2
  }
}

///|
fn DiagramLayout::content_horizontal_bounds(
  self : DiagramLayout,
  events : Array[Event],
) -> (Int, Int) {
  guard self.participants.length() > 0 else { (0, self.width) }
  let first = self.participants[0]
  let last = self.participants[self.participants.length() - 1]
  let mut min_x = first.center_x - first.width / 2
  let mut max_x = last.center_x + last.width / 2
  let mut arrow_anchor : Message? = None
  for index, event in events {
    match event {
      Message(message) => {
        if message.from_code == message.to_code {
          match self.participant_at(message.from_code) {
            Some(participant) =>
              max_x = max_x.max(
                participant.center_x +
                40 +
                TextSize::of_with(
                  message.display_label(),
                  self.text_metrics.body,
                ).width,
              )
            None => ()
          }
        }
        arrow_anchor = Some(message)
      }
      MessageExo(message) =>
        match self.participant_at(message.participant_code) {
          Some(participant) => {
            let label_width = TextSize::of_with(
                message.label.unwrap_or(""),
                self.text_metrics.body,
              ).width
            let extent = if message.short_arrow {
              40
            } else {
              (label_width + 32).max(90)
            }
            match message.exo_type {
              FromLeft | ToLeft =>
                min_x = min_x.min(participant.center_x - extent)
              FromRight | ToRight =>
                max_x = max_x.max(participant.center_x + extent)
            }
          }
          None => ()
        }
      Note(note) => {
        let geometry = self.note_geometry(
          note,
          self.placements[index],
          arrow_anchor,
        )
        min_x = min_x.min(geometry.x)
        max_x = max_x.max(geometry.x + geometry.component.width)
      }
      _ => ()
    }
  }
  for group in self.groups {
    let (x, width) = self.group_bounds(group)
    min_x = min_x.min(x)
    max_x = max_x.max(x + width)
  }
  let mut max_box_depth = 0
  for participant in self.participants {
    max_box_depth = max_box_depth.max(participant.participant.boxes.length())
  }
  for depth in 0..<max_box_depth {
    let mut active : ParticipantBox? = None
    let mut start = 0
    for index, participant in self.participants {
      let current = participant.participant.boxes.get(depth)
      if current != active {
        match active {
          Some(box) => {
            let (left, right) = participant_box_horizontal_bounds(
              self.participants[start:index].to_owned(),
              box,
            )
            min_x = min_x.min(left)
            max_x = max_x.max(right)
          }
          None => ()
        }
        active = current
        start = index
      }
    }
    match active {
      Some(box) => {
        let (left, right) = participant_box_horizontal_bounds(
          self.participants[start:].to_owned(),
          box,
        )
        min_x = min_x.min(left)
        max_x = max_x.max(right)
      }
      None => ()
    }
  }
  (min_x, max_x)
}

///|
fn participant_lifetimes(
  events : Array[Event],
  placements : Array[EventPlacement],
) -> (Map[String, Int], Map[String, Int]) {
  let births : Map[String, Int] = Map([])
  let deaths : Map[String, Int] = Map([])
  for index, event in events {
    match event {
      Message(message) =>
        match message.activation_spec {
          Some(Create) => births[message.to_code] = placements[index].y
          Some(Destroy) => deaths[message.to_code] = placements[index].y + 18
          _ => ()
        }
      MessageExo(message) =>
        match message.activation_spec {
          Some(Create) => births[message.participant_code] = placements[index].y
          Some(Destroy) =>
            deaths[message.participant_code] = placements[index].y + 18
          _ => ()
        }
      LifeEvent(life) =>
        match life.event_type {
          Create => births[life.participant_code] = placements[index].y
          Destroy => deaths[life.participant_code] = placements[index].y
          _ => ()
        }
      _ => ()
    }
  }
  (births, deaths)
}

///|
fn SequenceDiagram::layout(self : SequenceDiagram) -> DiagramLayout {
  let text_metrics = SequenceTextMetrics::new(self.style)
  let (participants, participant_index, width) = layout_participants(
    self, text_metrics,
  )
  let mut participant_header_height = 36 +
    self.participant_box_header_height(text_metrics)
  for participant in participants {
    participant_header_height = participant_header_height.max(
      participant.participant.typ.header_height(),
    )
  }
  let (placements, activations, groups, destroys, auto_page_breaks, body_bottom) = layout_events(
    self,
    participant_index,
    participant_header_height + vertical_margin + 8,
    text_metrics,
  )
  let (births, deaths) = participant_lifetimes(self.events, placements)
  let participants = participants.map(participant => {
    ..participant,
    birth_y: births.get(participant.participant.code),
    death_y: deaths.get(participant.participant.code),
  })
  let footbox_height = if self.show_footbox {
    participant_header_height + 10
  } else {
    24
  }
  let layout = {
    participants,
    participant_index,
    placements,
    activations,
    groups,
    destroys,
    auto_page_breaks,
    width,
    height: body_bottom + footbox_height + vertical_margin,
    body_top: participant_header_height + vertical_margin,
    body_bottom,
    text_metrics,
  }
  let (min_x, max_x) = layout.content_horizontal_bounds(self.events)
  let shift = (horizontal_margin - min_x).max(0)
  let participants = layout.participants.map(participant => {
    ..participant,
    center_x: participant.center_x + shift,
  })
  let width = (max_x + shift + horizontal_margin).max(
    self.minimum_text_width(text_metrics),
  )
  { ..layout, participants, width }
}
