///|
fn append_note(
  output : StringBuilder,
  layout : DiagramLayout,
  note : Note,
  placement : EventPlacement,
  arrow_anchor : Message?,
) -> Unit {
  let geometry = layout.note_geometry(note, placement, arrow_anchor)
  let x = geometry.x
  let y = geometry.y
  let component = geometry.component
  let class_name = match note.note_style {
    NodeNormal => "note"
    Hexagonal => "note hex-note"
    Box => "note box-note"
  }
  let fill = note_color(note.color, layout.defaults)
  match note.note_style {
    NodeNormal => {
      let fold_x = x + component.width - component.fold
      let fold_y = y + component.fold
      output <+
        $|<path d="M\{x},\{y} L\{x},\{y + component.height} L\{x + component.width},\{y + component.height} L\{x + component.width},\{fold_y} L\{fold_x},\{y} Z" class="\{class_name}" fill="\{fill}" />
      output <+
        $|<path d="M\{fold_x},\{y} L\{fold_x},\{fold_y} L\{x + component.width},\{fold_y}" class="note-fold" fill="none" />
    }
    Hexagonal =>
      output <+
        $|<polygon points="\{x + component.fold},\{y} \{x + component.width - component.fold},\{y} \{x + component.width},\{y + component.height / 2} \{x + component.width - component.fold},\{y + component.height} \{x + component.fold},\{y + component.height} \{x},\{y + component.height / 2}" class="\{class_name}" fill="\{fill}" />
    Box =>
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{component.width}" height="\{component.height}" class="\{class_name}" fill="\{fill}" />
  }
  append_text(
    output,
    x + component.text_x,
    y + component.text_y,
    note.text,
    "note-label",
    layout.defaults,
    anchor="start",
    line_height=layout.text_metrics.note.line_height,
  )
}

///|
fn append_divider(
  output : StringBuilder,
  layout : DiagramLayout,
  divider : Divider,
  placement : EventPlacement,
) -> Unit {
  let y = placement.y + 17
  append_line(output, 28, y, layout.width - 28, y, "divider")
  let width = TextSize::of_with(divider.title, layout.text_metrics.body_bold).width +
    22
  output <+
    $|<rect x="\{(layout.width - width) / 2}" y="\{y - 12}" width="\{width}" height="24" class="divider-title"/>
  append_text(
    output,
    layout.width / 2,
    y + 5,
    divider.title,
    "divider-label",
    layout.defaults,
    line_height=layout.text_metrics.body_bold.line_height,
  )
}

///|
fn append_delay(
  output : StringBuilder,
  layout : DiagramLayout,
  delay : Delay,
  placement : EventPlacement,
) -> Unit {
  let y = placement.y + 14
  append_line(output, 28, y, layout.width - 28, y, "delay")
  match delay.label {
    Some(label) =>
      append_text(
        output,
        layout.width / 2,
        y - 5,
        label,
        "delay-label",
        layout.defaults,
        line_height=layout.text_metrics.body.line_height,
      )
    None => ()
  }
}

///|
fn append_reference(
  output : StringBuilder,
  layout : DiagramLayout,
  reference : Reference,
  placement : EventPlacement,
) -> Unit {
  let centers = reference.participant_codes.map(code => {
    layout.participant_at(code).map_or(layout.width / 2, p => p.center_x)
  })
  let first = centers.get(0).unwrap_or(36)
  let last = centers.last().unwrap_or(layout.width - 36)
  let x = first.min(last) - 36
  let width = (first - last).abs() + 72
  let tab_width = TextSize::of_with("ref", layout.text_metrics.body_bold).width +
    34
  output <+
    $|<rect x="\{x}" y="\{placement.y}" width="\{width}" height="\{placement.height}" class="reference"/>
  output <+
    $|<path d="M\{x},\{placement.y}h\{tab_width}v7l-10,10h\{-tab_width + 10}z" class="reference-tab"/>
  append_text(
    output,
    x + 12,
    placement.y + 16,
    "ref",
    "reference-tab-label",
    layout.defaults,
    anchor="start",
    line_height=layout.text_metrics.body_bold.line_height,
  )
  append_text(
    output,
    x + width / 2,
    placement.y + placement.height - 7,
    reference.label.unwrap_or(""),
    "reference-label",
    layout.defaults,
    line_height=layout.text_metrics.body.line_height,
  )
}

///|
fn append_return(
  output : StringBuilder,
  layout : DiagramLayout,
  value : Return,
  placement : EventPlacement,
  preceding_message : Message?,
) -> Unit {
  guard layout.participants.length() >= 2 else { return }
  let y = placement.y + MESSAGE_ARROW_OFFSET
  let mut activation : ActivationSpan? = None
  for candidate in layout.activations {
    if candidate.start_y <= y && y <= candidate.end_y {
      activation = Some(candidate)
    }
  }
  let (from, to) = match activation {
    Some(span) =>
      (
        layout
        .participant_at(span.participant_code)
        .unwrap_or(layout.participants[layout.participants.length() - 1]),
        match span.caller_code {
          Some(caller) =>
            layout.participant_at(caller).unwrap_or(layout.participants[0])
          None => layout.participants[0]
        },
      )
    None =>
      match preceding_message {
        Some(message) =>
          (
            layout
            .participant_at(message.to_code)
            .unwrap_or(layout.participants[layout.participants.length() - 1]),
            layout
            .participant_at(message.from_code)
            .unwrap_or(layout.participants[0]),
          )
        None =>
          (
            layout.participants[layout.participants.length() - 1],
            layout.participants[0],
          )
      }
  }
  let return_value = value.value.unwrap_or("")
  let label = match placement.number {
    Some(number) => "\{number} \{return_value}"
    None => return_value
  }
  output <+
    $|<line x1="\{from.center_x}" y1="\{y}" x2="\{to.center_x}" y2="\{y}" class="message dotted" marker-end="url(#arrow)"/>
  append_text(
    output,
    (from.center_x + to.center_x) / 2,
    y - 6,
    label,
    "message-label",
    layout.defaults,
    line_height=layout.text_metrics.body.line_height,
  )
}

///|
fn append_event(
  output : StringBuilder,
  layout : DiagramLayout,
  event : Event,
  placement : EventPlacement,
  arrow_anchor : Message?,
) -> Unit {
  guard !placement.ignored else { return }
  match event {
    Message(message) => append_message(output, layout, message, placement)
    MessageExo(message) =>
      append_exo_message(output, layout, message, placement)
    Note(note) => append_note(output, layout, note, placement, arrow_anchor)
    Divider(divider) => append_divider(output, layout, divider, placement)
    Delay(delay) => append_delay(output, layout, delay, placement)
    Reference(reference) =>
      append_reference(output, layout, reference, placement)
    Return(value) =>
      append_return(output, layout, value, placement, arrow_anchor)
    Newpage(page) => {
      append_line(
        output,
        18,
        placement.y + 20,
        layout.width - 18,
        placement.y + 20,
        "page-break",
      )
      match page.title {
        Some(title) =>
          append_text(
            output,
            layout.width / 2,
            placement.y + 14,
            title,
            "page-label",
            layout.defaults,
            line_height=layout.text_metrics.body_italic.line_height,
          )
        None => ()
      }
    }
    LinkAnchor => ()
    AutoNewpage(size) =>
      match size {
        Some(height) =>
          output <+
            $|<metadata class="auto-newpage" data-height="\{height}"/>
        None => output.write_string("<metadata class=\"auto-newpage\"/>\n")
      }
    GroupingStart(_)
    | GroupingLeaf(_)
    | LifeEvent(_)
    | HSpace(_)
    | BoxStart(_)
    | BoxEnd
    | Autonumber(_)
    | AutonumberStop
    | AutonumberResume(_)
    | AutonumberIncrement(_)
    | Autoactivate(_)
    | Footbox(_)
    | HideUnlinked(_)
    | Create
    | Url(_, _)
    | DeactivateLatest
    | IgnoreNewpage => ()
  }
}

///|
fn append_destroy_marks(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for mark in layout.destroys {
    guard layout.participant_at(mark.participant_code) is Some(participant) else {
      continue
    }
    append_line(
      output,
      participant.center_x - 7,
      mark.y - 7,
      participant.center_x + 7,
      mark.y + 7,
      "destroy",
    )
    append_line(
      output,
      participant.center_x - 7,
      mark.y + 7,
      participant.center_x + 7,
      mark.y - 7,
      "destroy",
    )
  }
}

///|
fn append_footboxes(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for participant in layout.participants {
    append_participant(output, participant, layout.participant_tail_y(), true)
  }
}

///|
