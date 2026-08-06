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
