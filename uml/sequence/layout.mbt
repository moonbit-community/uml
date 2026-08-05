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
      defaults: diagram.style.defaults(),
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
  let autonumber = AutonumberState::new()
  for event in diagram.events {
    autonumber.apply(event)
    match event {
      Message(message) => {
        let number = autonumber.take()
        constrain_message_gap(gaps, index, message, number, text_metrics)
      }
      MessageExo(_) | Return(_) => ignore(autonumber.take())
      Note(note) => constrain_note_gap(gaps, index, note, text_metrics)
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
    end_y: y + MESSAGE_ARROW_OFFSET,
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
  let autonumber = AutonumberState::new()

  for event_index, event in diagram.events {
    autonumber.apply(event)
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
      Message(_) | MessageExo(_) | Return(_) => autonumber.take()
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
        let arrow_extra = if message.is_self() {
          SELF_MESSAGE_LOOP_DEPTH
        } else {
          MESSAGE_VISUAL_CLEARANCE
        }
        last_visual_bottom = last_visual_bottom.max(
          y + MESSAGE_ARROW_OFFSET + arrow_extra,
        )
        apply_activation_spec(
          message.activation_spec,
          message.to_code,
          Some(message.from_code),
          y + MESSAGE_ARROW_OFFSET,
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
            y + MESSAGE_ARROW_OFFSET,
            None,
          )
        }
        last_message_to = Some(message.to_code)
        last_message_arrow_y = Some(y + MESSAGE_ARROW_OFFSET)
      }
      MessageExo(message) => {
        messages_since_auto_newpage += 1
        last_visual_bottom = last_visual_bottom.max(y + MESSAGE_ARROW_OFFSET)
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
        last_message_arrow_y = Some(y + MESSAGE_ARROW_OFFSET)
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
        if message.is_self() {
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
          Some(Destroy) =>
            deaths[message.to_code] = placements[index].y + MESSAGE_ARROW_OFFSET
          _ => ()
        }
      MessageExo(message) =>
        match message.activation_spec {
          Some(Create) => births[message.participant_code] = placements[index].y
          Some(Destroy) =>
            deaths[message.participant_code] = placements[index].y +
              MESSAGE_ARROW_OFFSET
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
    defaults: self.style.defaults(),
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
