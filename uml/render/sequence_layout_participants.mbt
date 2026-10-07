///|
fn constrain_message_gap(
  constraints : Map[(Int, Int), Double],
  participant_index : Map[String, Int],
  message : @seq.Message,
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
  let key = (first, last)
  constraints[key] = constraints.get(key).unwrap_or(0).max(required)
}

///|
fn constrain_note_gap(
  constraints : Map[(Int, Int), Double],
  participant_index : Map[String, Int],
  note : @seq.Note,
  text_metrics : SequenceTextMetrics,
) -> Unit {
  guard note.position is @seq.OverSeveral else { return }
  guard note.participant_codes.get(0) is Some(first_code) else { return }
  guard note.participant_codes.last() is Some(last_code) else { return }
  guard participant_index.get(first_code) is Some(first) else { return }
  guard participant_index.get(last_code) is Some(last) else { return }
  let left = first.min(last)
  let right = first.max(last)
  let span = right - left
  guard span > 0 else { return }
  let required = note.component(text_metrics).width
  let key = (left, right)
  constraints[key] = constraints.get(key).unwrap_or(0).max(required)
}

///|
fn constrain_participant_box_gap(
  constraints : Map[(Int, Int), Double],
  layouts : Array[ParticipantLayout],
  start : Int,
  end : Int,
  box : @seq.ParticipantBox,
  text_metrics : SequenceTextMetrics,
) -> Unit {
  let gap_count = end - start - 1
  guard gap_count > 0 else { return }
  let required = box.minimum_width(text_metrics) -
    layouts[start].width / 2 -
    layouts[end - 1].width / 2 -
    20
  let key = (start, end - 1)
  constraints[key] = constraints.get(key).unwrap_or(0).max(required)
}

///|
fn constrain_participant_box_gaps(
  constraints : Map[(Int, Int), Double],
  layouts : Array[ParticipantLayout],
  text_metrics : SequenceTextMetrics,
) -> Unit {
  let max_depth = max_participant_box_depth(layouts)
  for depth in 0..<max_depth {
    for_each_participant_box_run(layouts, depth, (start, end, box) => {
      constrain_participant_box_gap(
        constraints, layouts, start, end, box, text_metrics,
      )
    })
  }
}

///|
fn @seq.SequenceDiagram::participant_box_header_height(
  self : @seq.SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> Double {
  let mut max_depth = 0
  for _, participant in self.participants {
    max_depth = max_depth.max(participant.boxes.length())
  }
  (max_depth * (text_metrics.small_bold.line_height + 5)).to_double()
}

///|
fn initial_participant_layout(
  diagram : @seq.SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> Array[ParticipantLayout] {
  let layouts = []
  let mut index = 0
  let hide_unlinked = diagram.hides_unlinked()
  for _, participant in diagram.participants {
    guard !hide_unlinked || diagram.participant_is_linked(participant.code) else {
      continue
    }
    let label = participant.stereotype.map_or(participant.display, stereotype => {
      @tokenizer.display_stereotype(stereotype) + "\n" + participant.display
    })
    let label_size = TextSize::of_with(label, text_metrics.participant)
    let width = (TextSize::of_with(label, text_metrics.participant).width + 14).max(
      32,
    )
    layouts.push({
      participant,
      text_metrics,
      defaults: sequence_colors(diagram.style),
      index,
      center_x: 0,
      width,
      height: participant.typ.header_height() +
      (label_size.height - text_metrics.participant.line_height.to_double()).max(
        0,
      ),
      label,
      birth_y: None,
      death_y: None,
    })
    index = index + 1
  }
  // Preserve declaration order among participants with the same order value.
  layouts.sort_by((a, b) => {
    let order = a.participant.order.unwrap_or(0) -
      b.participant.order.unwrap_or(0)
    if order == 0 {
      a.participant.position - b.participant.position
    } else {
      order
    }
  })
  for index, participant in layouts {
    layouts[index] = { ..participant, index, }
  }
  layouts
}

///|
fn layout_participants(
  diagram : @seq.SequenceDiagram,
  text_metrics : SequenceTextMetrics,
) -> (Array[ParticipantLayout], Map[String, Int], Double) {
  let layouts = initial_participant_layout(diagram, text_metrics)
  let index = participant_code_index(layouts)
  guard layouts.length() > 0 else { (layouts, index, horizontal_margin * 2) }

  let constraints : Map[(Int, Int), Double] = Map([])
  for participant_index in 0..<(layouts.length() - 1) {
    let left = layouts[participant_index]
    let right = layouts[participant_index + 1]
    constraints[(participant_index, participant_index + 1)] = left.width / 2 +
      right.width / 2 +
      21
  }
  let autonumber = @seq.AutonumberState::new()
  for event in diagram.events {
    autonumber.apply(event)
    match event {
      @seq.Message(message) => {
        let number = autonumber.take()
        constrain_message_gap(constraints, index, message, number, text_metrics)
        for code in message.multicast {
          constrain_message_gap(
            constraints,
            index,
            { ..message, to_code: code, label: None, },
            None,
            text_metrics,
          )
        }
      }
      @seq.MessageExo(_) | @seq.Return(_) => ignore(autonumber.take())
      @seq.Note(note) =>
        constrain_note_gap(constraints, index, note, text_metrics)
      @seq.Notes(notes) =>
        notes.each(note => {
          constrain_note_gap(constraints, index, note, text_metrics)
        })
      _ => ()
    }
  }
  constrain_participant_box_gaps(constraints, layouts, text_metrics)

  // Teoz RealLine/PositiveForce: each endpoint moves only when its incoming
  // constraint is violated. Revisit all forces until no endpoint moves; the
  // adjacent participant constraints propagate changes without consuming
  // already available space between later participants.
  let centers = Array::make(
    layouts.length(),
    horizontal_margin + layouts[0].width / 2,
  )
  let mut changed = true
  while changed {
    changed = false
    for (first, last), required in constraints {
      let minimum = centers[first] + required
      if centers[last] < minimum {
        centers[last] = minimum
        changed = true
      }
    }
  }
  for index, participant in layouts {
    layouts[index] = { ..participant, center_x: centers[index], }
  }
  let last = layouts[layouts.length() - 1]
  (layouts, index, last.center_x + last.width / 2 + horizontal_margin)
}

///|
