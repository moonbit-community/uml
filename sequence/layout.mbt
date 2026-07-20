///|
priv struct TextSize {
  width : Int
  height : Int
}

///|
priv struct ParticipantLayout {
  participant : Participant
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
  body_color : String?
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
  width : Int
  height : Int
  body_top : Int
  body_bottom : Int
}

///|
let horizontal_margin = 5

///|
let vertical_margin = 5

///|
let participant_edge_gap = 17

///|
fn TextSize::of(text : String) -> TextSize {
  let metrics = @core.measure_text(text)
  { width: metrics.width, height: metrics.height }
}

///|
fn Message::display_label(self : Message) -> String {
  self.label.unwrap_or("")
}

///|
fn Message::label_height(self : Message) -> Int {
  match self.label {
    Some(label) if label.length() > 0 => TextSize::of(label).height
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
fn Note::height(self : Note) -> Int {
  self.component().height
}

///|
fn Event::height(self : Event) -> Int {
  match self {
    Message(message) =>
      if message.from_code == message.to_code {
        42
      } else {
        14
      }
    MessageExo(_) => 14
    Note(note) => note.height() + 10
    GroupingStart(_) => 34
    GroupingLeaf(leaf) => if leaf.is_end { 12 } else { 24 }
    LifeEvent(_) => 0
    Delay(_) => 28
    Divider(_) => 34
    HSpace(space) => space.pixels.unwrap_or(0)
    Newpage(_) => 40
    Reference(reference) =>
      (TextSize::of(reference.label.unwrap_or("ref")).height + 28).max(42)
    BoxStart(_) | BoxEnd => 0
    Return(return_value) =>
      (TextSize::of(return_value.value.unwrap_or("")).height + 24).max(34)
    Create => 0
    Url(_, _) => 0
    DeactivateLatest => 0
    LinkAnchor(_, _, label) =>
      (TextSize::of(label.unwrap_or("")).height + 24).max(34)
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
fn Event::required_gap_before(self : Event) -> Int {
  match self {
    Message(message) =>
      if message.from_code == message.to_code {
        42
      } else if message.activation_spec is Some(Create) {
        message.label_height().max(15) + 44
      } else if message.label_height() > 0 {
        message.label_height() + 14
      } else {
        14
      }
    MessageExo(message) =>
      match message.label {
        Some(label) if label.length() > 0 => TextSize::of(label).height + 14
        _ => 14
      }
    Note(note) => note.component().height + 18
    _ => self.height()
  }
}

///|
fn Event::is_parallel(self : Event) -> Bool {
  match self {
    Message(message) => message.parallel
    GroupingStart(group) => group.parallel
    _ => false
  }
}

///|
fn event_advances_layout(event : Event) -> Bool {
  match event {
    Note(note) => !note.on_arrow
    _ => event.height() > 0
  }
}

///|
fn next_visual_gap(events : Array[Event], index : Int) -> Int {
  for next_index in (index + 1)..<events.length() {
    let next = events[next_index]
    if event_advances_layout(next) {
      return next.required_gap_before()
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
fn Message::gap_requirement(self : Message) -> Int {
  TextSize::of(self.display_label()).width + 48
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
) -> Unit {
  guard participant_index.get(message.from_code) is Some(from) else { return }
  guard participant_index.get(message.to_code) is Some(to) else { return }
  let first = if from < to { from } else { to }
  let last = if from < to { to } else { from }
  let span = last - first
  guard span > 0 else { return }
  let required = message.gap_requirement()
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
  let required = note.component().width
  let per_gap = (required + span - 1) / span
  for index in left..<right {
    gaps[index] = gaps[index].max(per_gap)
  }
}

///|
fn initial_participant_layout(
  diagram : SequenceDiagram,
) -> Array[ParticipantLayout] {
  let layouts = []
  let mut index = 0
  let hide_unlinked = diagram.hides_unlinked()
  for _, participant in diagram.participants {
    guard !hide_unlinked || diagram.participant_is_linked(participant.code) else {
      continue
    }
    let width = (TextSize::of(participant.display).width + 28).max(80)
    layouts.push({
      participant,
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
) -> (Array[ParticipantLayout], Map[String, Int], Int) {
  let layouts = initial_participant_layout(diagram)
  let index = participant_code_index(layouts)
  guard layouts.length() > 0 else { (layouts, index, horizontal_margin * 2) }

  let gaps = []
  for participant_index in 0..<(layouts.length() - 1) {
    let left = layouts[participant_index]
    let right = layouts[participant_index + 1]
    gaps.push(left.width / 2 + right.width / 2 + 32)
  }
  for event in diagram.events {
    match event {
      Message(message) => constrain_message_gap(gaps, index, message)
      Note(note) => constrain_note_gap(gaps, index, note)
      _ => ()
    }
  }

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
  start_y : Int,
) -> (
  Array[EventPlacement],
  Array[ActivationSpan],
  Array[GroupSpan],
  Array[DestroyMark],
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
  let mut autoactivate = diagram.autoactivate
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
    let event_height = event.height()
    let advances = event_advances_layout(event)
    let height = if !advances {
      0
    } else if event is Note(_) {
      event_height
    } else {
      event_height.max(next_visual_gap(diagram.events, event_index))
    }
    let y = match event {
      Note(note) if note.on_arrow => previous_top + 4
      _ => if event.is_parallel() { previous_top } else { current_y }
    }
    let number = match event {
      Message(_) | MessageExo(_) if autonumber => {
        let value = next_number
        next_number = increment_autonumber(next_number, number_increment)
        match number_format {
          Some(format) => Some(format.replace(old="0", new=value))
          None => Some(value)
        }
      }
      _ => None
    }
    placements.push({ y, height, number })
    if !advances {
      ()
    } else if event.is_parallel() {
      parallel_bottom = parallel_bottom.max(y + height)
      current_y = parallel_bottom
    } else {
      previous_top = y
      parallel_bottom = y + height
      current_y = parallel_bottom
    }

    match event {
      Message(message) => {
        let arrow_extra = if message.from_code == message.to_code {
          22
        } else {
          0
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
      }
      MessageExo(message) => {
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
      }
      LifeEvent(life) =>
        apply_activation_spec(
          Some(life.event_type),
          life.participant_code,
          None,
          y,
          life.color,
          activations,
          active,
          destroys,
        )
      GroupingStart(group) => {
        groups.push({
          start_y: y,
          end_y: y + height,
          depth: group_stack.length(),
          keyword: group.keyword,
          header: group.header,
          color: group.back_color_header,
          body_color: group.back_color_body,
        })
        group_stack.push(groups.length() - 1)
      }
      GroupingLeaf(leaf) =>
        if leaf.is_end {
          if group_stack.pop() is Some(index) {
            groups[index] = { ..groups[index], end_y: y + height }
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
    groups[index] = { ..groups[index], end_y: current_y }
  }
  (placements, activations, groups, destroys, current_y)
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
                TextSize::of(message.display_label()).width,
              )
            None => ()
          }
        }
        arrow_anchor = Some(message)
      }
      MessageExo(message) =>
        match self.participant_at(message.participant_code) {
          Some(participant) => {
            let length = if message.short_arrow { 40 } else { 90 }
            let outside = match message.exo_type {
              FromLeft | ToLeft => participant.center_x - length
              FromRight | ToRight => participant.center_x + length
            }
            let label_width = TextSize::of(message.label.unwrap_or("")).width
            min_x = min_x.min(
              outside.min(participant.center_x) - label_width / 2,
            )
            max_x = max_x.max(
              outside.max(participant.center_x) + label_width / 2,
            )
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
  let (participants, participant_index, width) = layout_participants(self)
  let mut participant_header_height = 36
  for participant in participants {
    participant_header_height = participant_header_height.max(
      participant.participant.typ.header_height(),
    )
  }
  let (placements, activations, groups, destroys, body_bottom) = layout_events(
    self,
    participant_header_height - 6 + vertical_margin,
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
    width,
    height: body_bottom + footbox_height + vertical_margin,
    body_top: participant_header_height + vertical_margin,
    body_bottom,
  }
  let (min_x, max_x) = layout.content_horizontal_bounds(self.events)
  let shift = (horizontal_margin - min_x).max(0)
  let participants = layout.participants.map(participant => {
    ..participant,
    center_x: participant.center_x + shift,
  })
  { ..layout, participants, width: max_x + shift + horizontal_margin }
}
