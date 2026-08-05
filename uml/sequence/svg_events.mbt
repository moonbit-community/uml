///|
fn DiagramLayout::group_bounds(
  self : DiagramLayout,
  group : GroupSpan,
) -> (Int, Int) {
  guard self.participants.length() > 0 else { (18, self.width - 36) }
  let first_index = group.first_participant.unwrap_or(0)
  let last_index = group.last_participant.unwrap_or(
    self.participants.length() - 1,
  )
  let first = self.participants[first_index]
  let last = self.participants[last_index]
  let inset = 10 + group.depth * 8
  let x = first.center_x - first.width / 2 - inset
  let right = last.center_x + last.width / 2 + inset
  (x, (right - x).max(1))
}

///|
fn GroupSpan::header_text(self : GroupSpan) -> String {
  match self.keyword {
    Group => self.header
    _ => self.keyword.label()
  }
}

///|
fn GroupSpan::comment_text(self : GroupSpan) -> String? {
  match self.keyword {
    Group => None
    _ => @parse.normalize_label(self.header)
  }
}

///|
fn append_groups(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for group in layout.groups {
    let (x, width) = layout.group_bounds(group)
    let height = (group.end_y - group.start_y).max(1)
    let body_class = match group.color {
      Some(_) => "group-body group-body-colored"
      None => "group-body"
    }
    output <+
      $|<g class="group" data-keyword="\{group.keyword.label()}">
    if !group.parallel {
      output <+
        $|<rect x="\{x}" y="\{group.start_y}" width="\{width}" height="\{height}" class="\{body_class}" fill="\{svg_color(group.color)}"/>
    }
    for branch_index, branch in group.branches {
      match branch.color {
        Some(color) => {
          let branch_height = (branch.end_y - branch.start_y).max(1)
          output <+
            $|<rect x="\{x}" y="\{branch.start_y}" width="\{width}" height="\{branch_height}" class="group-branch" fill="\{svg_color(Some(color))}"/>
        }
        None => ()
      }
      if branch_index > 0 {
        append_line(
          output,
          x,
          branch.start_y,
          x + width,
          branch.start_y,
          "group-separator",
        )
        match branch.label {
          Some(label) =>
            append_text(
              output,
              x + 8,
              branch.start_y + 12,
              "[\{label}]",
              "group-label",
              anchor="start",
              line_height=layout.text_metrics.body_bold.line_height,
            )
          None => ()
        }
      }
    }
    if !group.parallel {
      let header = group.header_text()
      let comment = group.comment_text()
      let label = comment.map_or(header, value => "\{header} [\{value}]")
      let header_width = (TextSize::of_with(
        label,
        layout.text_metrics.body_bold,
      ).width +
      38).max(54)
      output <+
        $|<path d="M\{x} \{group.start_y}h\{header_width}v22h-8l-5 5-5-5h-\{header_width - 18}z" class="group-header" fill="\{svg_color(group.header_color)}"/>
      append_text(
        output,
        x + 8,
        group.start_y + 16,
        label,
        "group-label",
        anchor="start",
        line_height=layout.text_metrics.body_bold.line_height,
      )
    }
    output.write_string("</g>\n")
  }
}

///|
fn delay_ranges(
  layout : DiagramLayout,
  events : Array[Event],
) -> Array[(Int, Int)] {
  let ranges = []
  events.eachi((index, event) => {
    if event is Delay(_) {
      let placement = layout.placements[index]
      ranges.push((placement.y, placement.y + placement.height))
    }
  })
  ranges
}

///|
fn append_lifelines(
  output : StringBuilder,
  layout : DiagramLayout,
  events : Array[Event],
) -> Unit {
  let delays = delay_ranges(layout, events)
  for participant in layout.participants {
    let mut start = participant.birth_y.map_or(layout.body_top, birth_y => {
      birth_y + 9
    })
    let end = participant.death_y.map_or(layout.body_bottom, death_y => death_y)
    for _, delay in delays {
      let (delay_start, delay_end) = delay
      if start < delay_start && delay_start < end {
        append_line(
          output,
          participant.center_x,
          start,
          participant.center_x,
          delay_start,
          "lifeline",
        )
      }
      start = start.max(delay_end)
    }
    if start < end {
      append_line(
        output,
        participant.center_x,
        start,
        participant.center_x,
        end,
        "lifeline",
      )
    }
  }
}

///|
fn append_activations(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for activation in layout.activations {
    guard layout.participant_at(activation.participant_code)
      is Some(participant) else {
      continue
    }
    let width = 10
    let x = participant.center_x - width / 2 + activation.depth * 8
    let height = (activation.end_y - activation.start_y).max(12)
    output <+
      $|<rect x="\{x}" y="\{activation.start_y}" width="\{width}" height="\{height}" class="activation" fill="\{activation_color(activation.color)}"/>
  }
}

///|
fn append_arrow_head(
  output : StringBuilder,
  head : ArrowHead,
  x : Int,
  y : Int,
) -> Unit {
  match head {
    CrossX => {
      append_line(output, x - 5, y - 5, x + 5, y + 5, "cross")
      append_line(output, x - 5, y + 5, x + 5, y - 5, "cross")
    }
    _ => ()
  }
}

///|
fn append_partial_arrow_head(
  output : StringBuilder,
  head : ArrowHead,
  part : ArrowPart,
  x : Int,
  y : Int,
  points_right : Bool,
) -> Unit {
  match head {
    Normal => {
      let base = if points_right { x - 10 } else { x + 10 }
      let path = match part {
        TopPart => "M\{base} \{y - 4}L\{x} \{y}L\{base} \{y}Z"
        BottomPart => "M\{base} \{y}L\{x} \{y}L\{base} \{y + 4}Z"
        Full => ""
      }
      if part is TopPart || part is BottomPart {
        output <+
          $|<path d="\{path}" class="partial-arrow"/>
      }
    }
    Async => {
      let base = if points_right { x - 10 } else { x + 10 }
      match part {
        TopPart => {
          append_line(output, base, y - 4, x, y, "partial-arrow")
          append_line(output, x, y, base, y, "partial-arrow")
        }
        BottomPart => {
          append_line(output, base, y, x, y, "partial-arrow")
          append_line(output, x, y, base, y + 4, "partial-arrow")
        }
        Full => ()
      }
    }
    _ => ()
  }
}

///|
fn message_label_x(from : ParticipantLayout, to : ParticipantLayout) -> Int {
  if from.center_x > to.center_x {
    to.center_x + to.width / 2 + 7
  } else {
    from.center_x + 7
  }
}

///|
fn ArrowHead::marker(self : ArrowHead, start : Bool) -> String {
  match (self, start) {
    (Normal, true) => " marker-start=\"url(#arrow-start)\""
    (Normal, false) => " marker-end=\"url(#arrow)\""
    (Async, true) => " marker-start=\"url(#open-arrow-start)\""
    (Async, false) => " marker-end=\"url(#open-arrow)\""
    (CrossX | NoneHead, _) => ""
  }
}

///|
fn append_message(
  output : StringBuilder,
  layout : DiagramLayout,
  message : Message,
  placement : EventPlacement,
) -> Unit {
  guard layout.participant_at(message.from_code) is Some(from) else { return }
  guard layout.participant_at(message.to_code) is Some(to) else { return }
  let y = placement.y + MESSAGE_ARROW_OFFSET
  let label = message.rendered_label(placement.number)
  let dotted = if message.arrow_config.body is Dotted { " dotted" } else { "" }
  let line_class = "message\{dotted}"
  let start_y = y
  let end_y = y
  match message.anchor {
    Some(anchor) =>
      output <+
        $|<g id="\{@svg.xml_escape(anchor)}" class="message-anchor">
    None => ()
  }
  if from.participant.code == to.participant.code {
    let loop_x = from.center_x + 34
    let end_marker = match message.arrow_config.part {
      Full => message.arrow_config.head2.marker(false)
      TopPart | BottomPart => ""
    }
    output <+
      $|<path d="M\{from.center_x} \{start_y}h34v22h-34" class="\{line_class}"\{end_marker}/>
    append_partial_arrow_head(
      output,
      message.arrow_config.head2,
      message.arrow_config.part,
      from.center_x,
      end_y + 22,
      false,
    )
    append_text(
      output,
      loop_x + 6,
      end_y + 13,
      label,
      "message-label",
      anchor="start",
      line_height=layout.text_metrics.body.line_height,
    )
  } else {
    let start_x = from.center_x
    let end_x = to.center_x
    let end_marker = match message.arrow_config.part {
      Full => message.arrow_config.head2.marker(false)
      TopPart | BottomPart => ""
    }
    output <+
      $|<line x1="\{start_x}" y1="\{start_y}" x2="\{end_x}" y2="\{end_y}" class="\{line_class}"\{message.arrow_config.head1.marker(true)}\{end_marker}/>
    append_partial_arrow_head(
      output,
      message.arrow_config.head2,
      message.arrow_config.part,
      end_x,
      end_y,
      end_x >= start_x,
    )
    let label_x = message_label_x(from, to)
    append_text(
      output,
      label_x,
      start_y.min(end_y) - 6,
      label,
      "message-label",
      anchor="start",
      line_height=layout.text_metrics.body.line_height,
    )
  }
  if message.arrow_config.circle_start {
    output <+
      $|<circle cx="\{from.center_x}" cy="\{start_y}" r="4" class="endpoint"/>
  }
  if message.arrow_config.circle_end {
    output <+
      $|<circle cx="\{to.center_x}" cy="\{end_y}" r="4" class="endpoint"/>
  }
  append_arrow_head(output, message.arrow_config.head1, from.center_x, start_y)
  if message.arrow_config.part is Full {
    append_arrow_head(output, message.arrow_config.head2, to.center_x, end_y)
  }
  if message.anchor is Some(_) {
    output.write_string("</g>\n")
  }
}

///|
fn append_exo_message(
  output : StringBuilder,
  layout : DiagramLayout,
  message : MessageExo,
  placement : EventPlacement,
) -> Unit {
  guard layout.participant_at(message.participant_code) is Some(participant) else {
    return
  }
  let y = placement.y + MESSAGE_ARROW_OFFSET
  let (outside_x, participant_x) = match message.exo_type {
    FromLeft | ToLeft =>
      (
        if message.short_arrow {
          participant.center_x - 40
        } else {
          0
        },
        participant.center_x,
      )
    FromRight | ToRight =>
      (
        if message.short_arrow {
          participant.center_x + 40
        } else {
          layout.width - 8
        },
        participant.center_x,
      )
  }
  let (start_x, end_x) = match message.exo_type {
    FromLeft | FromRight => (outside_x, participant_x)
    ToLeft | ToRight => (participant_x, outside_x)
  }
  let dotted = if message.arrow_config.body is Dotted { " dotted" } else { "" }
  output <+
    $|<line x1="\{start_x}" y1="\{y}" x2="\{end_x}" y2="\{y}" class="message\{dotted}"\{message.arrow_config.head1.marker(true)}\{message.arrow_config.head2.marker(false)}/>
  let raw_label = message.label.unwrap_or("")
  let label = placement.number
    .map(number => "\{number} \{raw_label}")
    .unwrap_or_else(() => raw_label)
  append_text(
    output,
    start_x.min(end_x) + 7,
    y - 6,
    label,
    "message-label",
    anchor="start",
    line_height=layout.text_metrics.body.line_height,
  )
}

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
  let fill = note_color(note.color)
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
    anchor="start",
    line_height=layout.text_metrics.body_bold.line_height,
  )
  append_text(
    output,
    x + width / 2,
    placement.y + placement.height - 7,
    reference.label.unwrap_or(""),
    "reference-label",
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
