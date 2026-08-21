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
/// The participant a message activation specifier acts on: `++`/`**`/`!!`
/// target the second participant, `--` the first one, mirroring Java's
/// `manageActivations`.
fn message_target(message : Message, spec : ActivationSpec?) -> String {
  match spec {
    Some(Deactivate) => message.from_code
    _ => message.to_code
  }
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
    Some(Create) | None => ()
    Some(Deactivate) => {
      let _ = finish_activation(activations, active, participant_code, y)
      ()
    }
    Some(Destroy) => {
      let _ = finish_activation(activations, active, participant_code, y)
      destroys.push({ participant_code, y })
    }
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
  let last_message_y : Map[String, Int] = Map([])
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
    let auto_page_break = auto_newpage is Some(threshold) &&
      threshold > 0 &&
      messages_since_auto_newpage >= threshold &&
      (event is Message(_) || event is MessageExo(_))
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
    } else if event is Note(_) || event is Notes(_) {
      event_height
    } else {
      event_height.max(
        next_visual_gap(diagram.events, event_index, text_metrics),
      )
    }
    let y = match event {
      Note(note) if note.on_arrow => previous_top + 4
      Notes(notes) if notes[0].on_arrow => previous_top + 4
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

    if event.participant_span(participant_index) is Some(span) {
      for group_index in group_stack {
        let group = groups[group_index]
        groups[group_index] = GroupSpan::include_participant_span(group, span)
      }
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
          message_target(message, message.activation_spec),
          Some(message.from_code),
          y + MESSAGE_ARROW_OFFSET,
          message.life_color,
          activations,
          active,
          destroys,
        )
        apply_activation_spec(
          message.activation_spec2,
          message_target(message, message.activation_spec2),
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
        last_message_y[message.from_code] = y + MESSAGE_ARROW_OFFSET
        last_message_y[message.to_code] = y + MESSAGE_ARROW_OFFSET
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
        last_message_y[message.participant_code] = y + MESSAGE_ARROW_OFFSET
      }
      LifeEvent(life) => {
        // A standalone life event attaches to the y of the last message
        // dealing with its participant, mirroring Java's
        // `lastEventWithDeactivate.dealWith(p)`; otherwise it sits on its
        // own row.
        let life_y = last_message_y.get(life.participant_code).unwrap_or(y)
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
