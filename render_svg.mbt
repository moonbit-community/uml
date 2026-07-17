///|
fn xml_escape(value : String) -> String {
  let output = StringBuilder()
  for char in value {
    match char {
      '&' => output.write_string("&amp;")
      '<' => output.write_string("&lt;")
      '>' => output.write_string("&gt;")
      '"' => output.write_string("&quot;")
      '\'' => output.write_string("&apos;")
      _ => output.write_char(char)
    }
  }
  output.to_string()
}

///|
fn svg_color(color : String?) -> String {
  match color {
    None => "#FEFECE"
    Some(value) => {
      let mut hexadecimal = value.length() == 3 ||
        value.length() == 6 ||
        value.length() == 8
      for char in value {
        hexadecimal = hexadecimal &&
          (
            char.is_ascii_digit() ||
            ('a' <= char && char <= 'f') ||
            ('A' <= char && char <= 'F')
          )
      }
      if hexadecimal {
        "#\{value}"
      } else {
        xml_escape(value)
      }
    }
  }
}

///|
fn append_line(
  output : StringBuilder,
  x1 : Int,
  y1 : Int,
  x2 : Int,
  y2 : Int,
  class_name : String,
) -> Unit {
  output <+
    "<line x1=\"\{x1}\" y1=\"\{y1}\" x2=\"\{x2}\" y2=\"\{y2}\" class=\"\{class_name}\"/>\n"
}

///|
fn append_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  text : String,
  class_name : String,
  anchor? : String = "middle",
) -> Unit {
  let lines = text.split("\n").to_array()
  output <+
    "<text x=\"\{x}\" y=\"\{y}\" text-anchor=\"\{anchor}\" class=\"\{class_name}\">"
  lines.eachi((index, line) => {
    let dy = if index == 0 { 0 } else { 16 }
    output <+
      "<tspan x=\"\{x}\" dy=\"\{dy}\">\{xml_escape(line.to_owned())}</tspan>"
  })
  output.write_string("</text>\n")
}

///|
fn DiagramLayout::participant_at(
  self : DiagramLayout,
  code : String,
) -> ParticipantLayout? {
  self.participant_index.get(code).map(index => self.participants[index])
}

///|
fn DiagramLayout::participant_head_y(
  self : DiagramLayout,
  participant : ParticipantLayout,
) -> Int {
  self.body_top - participant.participant.typ.header_height() - 10
}

///|
fn DiagramLayout::participant_tail_y(self : DiagramLayout) -> Int {
  self.body_bottom + 9
}

///|
fn GroupKeyword::label(self : GroupKeyword) -> String {
  match self {
    Opt => "opt"
    Alt => "alt"
    Loop => "loop"
    Par => "par"
    Par2 => "par"
    Break => "break"
    Critical => "critical"
    Group => "group"
    Partition => "partition"
  }
}

///|
fn append_participant(
  output : StringBuilder,
  layout : ParticipantLayout,
  y : Int,
  is_tail : Bool,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  let fill = svg_color(layout.participant.color)
  match layout.participant.url {
    Some(url) => output <+ "<a href=\"\{xml_escape(url)}\" target=\"_top\">\n"
    None => ()
  }
  output <+
    "<g class=\"participant \{layout.participant.typ.css_class()}\" data-code=\"\{xml_escape(layout.participant.code)}\">\n"
  match layout.participant.typ {
    Actor | Boundary | Control | Entity | Database =>
      append_vertical_participant(output, layout, y, is_tail)
    Queue => append_queue_participant(output, layout, y)
    Collections => append_collections_participant(output, layout, y, fill)
    Participant => {
      output <+
        "<rect x=\"\{left}\" y=\"\{y}\" width=\"\{layout.width}\" height=\"36\" rx=\"2\" fill=\"\{fill}\"/>\n"
      append_text(
        output,
        layout.center_x,
        y + 23,
        layout.participant.display,
        "participant-label",
      )
    }
  }
  output.write_string("</g>\n")
  if layout.participant.url is Some(_) {
    output.write_string("</a>\n")
  }
}

///|
fn append_vertical_participant(
  output : StringBuilder,
  layout : ParticipantLayout,
  y : Int,
  is_tail : Bool,
) -> Unit {
  let symbol_height = layout.participant.typ.symbol_height()
  let symbol_y = if is_tail { y + 16 } else { y }
  let label_y = if is_tail { y + 13 } else { y + symbol_height + 13 }
  append_participant_symbol(
    output,
    layout.participant.typ,
    layout.center_x,
    symbol_y,
  )
  append_text(
    output,
    layout.center_x,
    label_y,
    layout.participant.display,
    "participant-label",
  )
}

///|
fn append_queue_participant(
  output : StringBuilder,
  layout : ParticipantLayout,
  y : Int,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  let right = left + layout.width
  let middle = y + 13
  output <+
    "<path d=\"M\{left + 5} \{y}H\{right - 5}C\{right} \{y} \{right} \{middle} \{right} \{middle}C\{right} \{middle} \{right} \{y + 26} \{right - 5} \{y + 26}H\{left + 5}C\{left} \{y + 26} \{left} \{middle} \{left} \{middle}C\{left} \{middle} \{left} \{y} \{left + 5} \{y}Z\" class=\"participant-icon\"/>\n"
  append_text(
    output,
    layout.center_x,
    y + 18,
    layout.participant.display,
    "participant-label",
  )
}

///|
fn append_collections_participant(
  output : StringBuilder,
  layout : ParticipantLayout,
  y : Int,
  fill : String,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  output <+
    "<rect x=\"\{left + 4}\" y=\"\{y}\" width=\"\{layout.width - 4}\" height=\"36\" rx=\"2\" fill=\"\{fill}\"/>\n"
  output <+
    "<rect x=\"\{left}\" y=\"\{y + 4}\" width=\"\{layout.width - 4}\" height=\"36\" rx=\"2\" fill=\"\{fill}\"/>\n"
  append_text(
    output,
    layout.center_x,
    y + 27,
    layout.participant.display,
    "participant-label",
  )
}

///|
fn append_participant_symbol(
  output : StringBuilder,
  typ : ParticipantType,
  x : Int,
  y : Int,
) -> Unit {
  match typ {
    Actor => {
      output <+
        "<circle cx=\"\{x}\" cy=\"\{y + 9}\" r=\"8\" class=\"participant-icon\"/>\n"
      append_line(output, x, y + 17, x, y + 44, "participant-icon")
      append_line(output, x - 13, y + 25, x + 13, y + 25, "participant-icon")
      append_line(output, x, y + 44, x - 13, y + 59, "participant-icon")
      append_line(output, x, y + 44, x + 13, y + 59, "participant-icon")
    }
    Boundary => {
      output <+
        "<circle cx=\"\{x + 9}\" cy=\"\{y + 16}\" r=\"12\" class=\"participant-icon\"/>\n"
      append_line(output, x - 20, y + 4, x - 20, y + 28, "participant-icon")
      append_line(output, x - 20, y + 16, x - 3, y + 16, "participant-icon")
    }
    Control => {
      output <+
        "<circle cx=\"\{x}\" cy=\"\{y + 16}\" r=\"12\" class=\"participant-icon\"/>\n"
      output <+
        "<path d=\"M\{x + 8} \{y + 4}l6 -5 -2 5 2 5z\" class=\"participant-icon\"/>\n"
    }
    Entity => {
      output <+
        "<ellipse cx=\"\{x}\" cy=\"\{y + 16}\" rx=\"12\" ry=\"12\" class=\"participant-icon\"/>\n"
      append_line(output, x - 12, y + 30, x + 12, y + 30, "participant-icon")
    }
    Database => {
      output <+
        "<ellipse cx=\"\{x}\" cy=\"\{y + 10}\" rx=\"18\" ry=\"10\" class=\"participant-icon\"/>\n"
      output <+
        "<path d=\"M\{x - 18} \{y + 10}v31c0 7 36 7 36 0V\{y + 10}\" class=\"participant-icon\"/>\n"
      output <+
        "<path d=\"M\{x - 18} \{y + 10}c0 13 36 13 36 0\" class=\"participant-icon\"/>\n"
    }
    Participant | Queue | Collections => ()
  }
}

///|
fn ParticipantType::symbol_height(self : ParticipantType) -> Int {
  match self {
    Actor => 60
    Boundary | Control | Entity => 32
    Database => 51
    Participant | Queue | Collections => 0
  }
}

///|
fn ParticipantType::css_class(self : ParticipantType) -> String {
  match self {
    Participant => "participant-box"
    Actor => "actor"
    Boundary => "boundary"
    Control => "control"
    Entity => "entity"
    Database => "database"
    Queue => "queue"
    Collections => "collections"
  }
}

///|
fn append_participant_box(
  output : StringBuilder,
  layouts : Array[ParticipantLayout],
  box : ParticipantBox,
  depth : Int,
) -> Unit {
  guard layouts.length() > 0 else { return }
  let first = layouts[0]
  let last = layouts[layouts.length() - 1]
  let left = first.center_x - first.width / 2 - 10
  let right = last.center_x + last.width / 2 + 10
  let y = 4 + depth * 3
  output <+
    "<rect x=\"\{left}\" y=\"\{y}\" width=\"\{right - left}\" height=\"56\" class=\"participant-box-group\" fill=\"\{svg_color(box.color)}\"/>\n"
  match box.label {
    Some(label) =>
      append_text(
        output,
        left + 8,
        y + 13,
        label,
        "participant-box-label",
        anchor="start",
      )
    None => ()
  }
}

///|
fn append_participant_boxes(
  output : StringBuilder,
  layout : DiagramLayout,
) -> Unit {
  let mut max_depth = 0
  for participant in layout.participants {
    max_depth = max_depth.max(participant.participant.boxes.length())
  }
  for depth in 0..<max_depth {
    let mut active : ParticipantBox? = None
    let mut start = 0
    for index, participant in layout.participants {
      let current = participant.participant.boxes.get(depth)
      if current != active {
        match active {
          Some(box) =>
            append_participant_box(
              output,
              layout.participants[start:index].to_owned(),
              box,
              depth,
            )
          None => ()
        }
        active = current
        start = index
      }
    }
    match active {
      Some(box) =>
        append_participant_box(
          output,
          layout.participants[start:].to_owned(),
          box,
          depth,
        )
      None => ()
    }
  }
}

///|
fn append_groups(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for group in layout.groups {
    let inset = 8 + group.depth * 12
    let x = 18 + inset
    let width = layout.width - 36 - inset * 2
    let height = (group.end_y - group.start_y).max(22)
    let body_color = svg_color(group.body_color)
    let header_color = svg_color(group.color)
    output <+ "<g class=\"group\" data-keyword=\"\{group.keyword.label()}\">\n"
    output <+
      "<rect x=\"\{x}\" y=\"\{group.start_y}\" width=\"\{width}\" height=\"\{height}\" class=\"group-body\" fill=\"\{body_color}\"/>\n"
    output <+
      "<path d=\"M\{x} \{group.start_y}h\{(TextSize::of(group.header).width + 38).max(54)}v22h-8l-5 5-5-5h-\{(TextSize::of(group.header).width + 20).max(36)}z\" class=\"group-header\" fill=\"\{header_color}\"/>\n"
    append_text(
      output,
      x + 8,
      group.start_y + 16,
      "\{group.keyword.label()} \{group.header}",
      "group-label",
      anchor="start",
    )
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
    let mut start = layout.body_top
    for _, delay in delays {
      let (delay_start, delay_end) = delay
      if start < delay_start {
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
    if start < layout.body_bottom {
      append_line(
        output,
        participant.center_x,
        start,
        participant.center_x,
        layout.body_bottom,
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
      "<rect x=\"\{x}\" y=\"\{activation.start_y}\" width=\"\{width}\" height=\"\{height}\" class=\"activation\" fill=\"\{svg_color(activation.color)}\"/>\n"
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
  let y = placement.y + 18
  let label = placement.number
    .map(number => "\{number} \{message.display_label()}")
    .unwrap_or_else(() => message.display_label())
  let dotted = if message.arrow_config.body is Dotted { " dotted" } else { "" }
  let line_class = "message\{dotted}"
  let (start_y, end_y) = match message.arrow_config.part {
    Full => (y, y)
    TopPart => (y + 5, y - 5)
    BottomPart => (y - 5, y + 5)
  }
  match message.anchor {
    Some(anchor) =>
      output <+ "<g id=\"\{xml_escape(anchor)}\" class=\"message-anchor\">\n"
    None => ()
  }
  if from.participant.code == to.participant.code {
    let loop_x = from.center_x + 34
    output <+
      "<path d=\"M\{from.center_x} \{start_y}h34v22h-34\" class=\"\{line_class}\"\{message.arrow_config.head2.marker(false)}/>\n"
    append_text(
      output,
      loop_x + 6,
      end_y + 13,
      label,
      "message-label",
      anchor="start",
    )
  } else {
    let start_x = from.center_x
    let end_x = to.center_x
    output <+
      "<line x1=\"\{start_x}\" y1=\"\{start_y}\" x2=\"\{end_x}\" y2=\"\{end_y}\" class=\"\{line_class}\"\{message.arrow_config.head1.marker(true)}\{message.arrow_config.head2.marker(false)}/>\n"
    let label_x = (start_x + end_x) / 2
    append_text(output, label_x, start_y.min(end_y) - 6, label, "message-label")
  }
  if message.arrow_config.circle_start {
    output <+
      "<circle cx=\"\{from.center_x}\" cy=\"\{start_y}\" r=\"4\" class=\"endpoint\"/>\n"
  }
  if message.arrow_config.circle_end {
    output <+
      "<circle cx=\"\{to.center_x}\" cy=\"\{end_y}\" r=\"4\" class=\"endpoint\"/>\n"
  }
  append_arrow_head(output, message.arrow_config.head1, from.center_x, start_y)
  append_arrow_head(output, message.arrow_config.head2, to.center_x, end_y)
  for code in message.multicast {
    guard layout.participant_at(code) is Some(target) else { continue }
    output <+
      "<line x1=\"\{from.center_x}\" y1=\"\{start_y}\" x2=\"\{target.center_x}\" y2=\"\{end_y}\" class=\"\{line_class}\"\{message.arrow_config.head2.marker(false)}/>\n"
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
  let y = placement.y + 18
  let length = if message.short_arrow { 40 } else { 90 }
  let (outside_x, participant_x) = match message.exo_type {
    FromLeft | ToLeft => (participant.center_x - length, participant.center_x)
    FromRight | ToRight => (participant.center_x + length, participant.center_x)
  }
  let (start_x, end_x) = match message.exo_type {
    FromLeft | FromRight => (outside_x, participant_x)
    ToLeft | ToRight => (participant_x, outside_x)
  }
  let dotted = if message.arrow_config.body is Dotted { " dotted" } else { "" }
  output <+
    "<line x1=\"\{start_x}\" y1=\"\{y}\" x2=\"\{end_x}\" y2=\"\{y}\" class=\"message\{dotted}\"\{message.arrow_config.head1.marker(true)}\{message.arrow_config.head2.marker(false)}/>\n"
  let raw_label = message.label.unwrap_or("")
  let label = placement.number
    .map(number => "\{number} \{raw_label}")
    .unwrap_or_else(() => raw_label)
  append_text(output, (start_x + end_x) / 2, y - 6, label, "message-label")
}

///|
fn append_note(
  output : StringBuilder,
  layout : DiagramLayout,
  note : Note,
  placement : EventPlacement,
  arrow_anchor : Message?,
) -> Unit {
  let size = TextSize::of(note.text)
  let width = (size.width + 20).max(56)
  let height = note.height()
  let center = note_anchor_center(layout, note, arrow_anchor)
  let x = match note.position {
    Left => center - width - 10
    Right => center + 10
    Over => center - width / 2
    OverSeveral =>
      match (note.participant_codes.get(0), note.participant_codes.last()) {
        (Some(first), Some(last)) => {
          let start = layout
            .participant_at(first)
            .map_or(center, p => p.center_x)
          let end = layout.participant_at(last).map_or(center, p => p.center_x)
          (start + end) / 2 - width / 2
        }
        _ => center - width / 2
      }
    Across => 24
  }
  let note_width = if note.position is Across {
    layout.width - 48
  } else {
    width
  }
  let class_name = match note.note_style {
    NodeNormal => "note"
    Hexagonal => "note hex-note"
    Box => "note box-note"
  }
  output <+
    "<rect x=\"\{x}\" y=\"\{placement.y}\" width=\"\{note_width}\" height=\"\{height}\" class=\"\{class_name}\" fill=\"\{svg_color(note.color)}\"/>\n"
  append_text(
    output,
    x + 10,
    placement.y + 18,
    note.text,
    "note-label",
    anchor="start",
  )
}

///|
fn note_anchor_center(
  layout : DiagramLayout,
  note : Note,
  arrow_anchor : Message?,
) -> Int {
  guard note.on_arrow else {
    match note.participant_codes.get(0) {
      Some(code) =>
        layout
        .participant_at(code)
        .map_or(layout.width / 2, participant => participant.center_x)
      None => layout.width / 2
    }
  }
  match arrow_anchor {
    Some(message) => {
      let from = layout
        .participant_at(message.from_code)
        .map_or(layout.width / 2, participant => participant.center_x)
      let to = layout
        .participant_at(message.to_code)
        .map_or(layout.width / 2, participant => participant.center_x)
      (from + to) / 2
    }
    None => layout.width / 2
  }
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
  let width = TextSize::of(divider.title).width + 22
  output <+
    "<rect x=\"\{(layout.width - width) / 2}\" y=\"\{y - 12}\" width=\"\{width}\" height=\"24\" class=\"divider-title\"/>\n"
  append_text(output, layout.width / 2, y + 5, divider.title, "divider-label")
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
      append_text(output, layout.width / 2, y - 5, label, "delay-label")
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
  output <+
    "<rect x=\"\{x}\" y=\"\{placement.y}\" width=\"\{width}\" height=\"\{placement.height}\" class=\"reference\"/>\n"
  append_text(
    output,
    x + 9,
    placement.y + 20,
    reference.label.unwrap_or("ref"),
    "reference-label",
    anchor="start",
  )
}

///|
fn append_return(
  output : StringBuilder,
  layout : DiagramLayout,
  value : Return,
  placement : EventPlacement,
) -> Unit {
  guard layout.participants.length() >= 2 else { return }
  let y = placement.y + 18
  let mut activation : ActivationSpan? = None
  for candidate in layout.activations {
    if candidate.start_y <= y && y <= candidate.end_y {
      activation = Some(candidate)
    }
  }
  let from = match activation {
    Some(span) =>
      layout
      .participant_at(span.participant_code)
      .unwrap_or(layout.participants[layout.participants.length() - 1])
    None => layout.participants[layout.participants.length() - 1]
  }
  let to = match activation {
    Some(span) =>
      match span.caller_code {
        Some(caller) =>
          layout.participant_at(caller).unwrap_or(layout.participants[0])
        None => layout.participants[0]
      }
    None => layout.participants[0]
  }
  output <+
    "<line x1=\"\{from.center_x}\" y1=\"\{y}\" x2=\"\{to.center_x}\" y2=\"\{y}\" class=\"message dotted\" marker-end=\"url(#arrow)\"/>\n"
  append_text(
    output,
    (from.center_x + to.center_x) / 2,
    y - 6,
    value.value.unwrap_or(""),
    "message-label",
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
  match event {
    Message(message) => append_message(output, layout, message, placement)
    MessageExo(message) =>
      append_exo_message(output, layout, message, placement)
    Note(note) => append_note(output, layout, note, placement, arrow_anchor)
    Divider(divider) => append_divider(output, layout, divider, placement)
    Delay(delay) => append_delay(output, layout, delay, placement)
    Reference(reference) =>
      append_reference(output, layout, reference, placement)
    Return(value) => append_return(output, layout, value, placement)
    GroupingLeaf(leaf) =>
      if !leaf.is_end {
        match leaf.back_color {
          Some(color) =>
            output <+
              "<rect x=\"32\" y=\"\{placement.y}\" width=\"\{layout.width - 64}\" height=\"24\" class=\"group-leaf-color\" fill=\"\{svg_color(Some(color))}\"/>\n"
          None => ()
        }
        append_line(
          output,
          32,
          placement.y + 12,
          layout.width - 32,
          placement.y + 12,
          "group-separator",
        )
        match leaf.label {
          Some(label) =>
            append_text(
              output,
              42,
              placement.y + 8,
              label,
              "group-label",
              anchor="start",
            )
          None => ()
        }
      }
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
          )
        None => ()
      }
    }
    LinkAnchor(from, to, label) => {
      output <+
        "<g class=\"anchor-link\" data-from=\"\{xml_escape(from)}\" data-to=\"\{xml_escape(to)}\">\n"
      match label {
        Some(text) =>
          append_text(
            output,
            layout.width / 2,
            placement.y + 18,
            text,
            "anchor-link-label",
          )
        None => ()
      }
      output.write_string("</g>\n")
    }
    AutoNewpage(size) =>
      match size {
        Some(height) =>
          output <+
            "<metadata class=\"auto-newpage\" data-height=\"\{height}\"/>\n"
        None => output.write_string("<metadata class=\"auto-newpage\"/>\n")
      }
    _ => ()
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
fn append_svg_preamble(output : StringBuilder, layout : DiagramLayout) -> Unit {
  output <+
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{layout.width}\" height=\"\{layout.height}\" viewBox=\"0 0 \{layout.width} \{layout.height}\" role=\"img\" aria-label=\"Sequence diagram\">\n"
  output.write_string(
    "<defs><marker id=\"arrow\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" class=\"arrow-fill\"/></marker><marker id=\"arrow-start\" viewBox=\"0 0 10 10\" refX=\"1\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto\"><path d=\"M 10 0 L 0 5 L 10 10 z\" class=\"arrow-fill\"/></marker><marker id=\"open-arrow\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto\"><path d=\"M 0 0 L 10 5 L 0 10\" class=\"arrow-open\"/></marker><marker id=\"open-arrow-start\" viewBox=\"0 0 10 10\" refX=\"1\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto\"><path d=\"M 10 0 L 0 5 L 10 10\" class=\"arrow-open\"/></marker></defs>\n",
  )
  output.write_string(
    "<style>svg{font-family:Arial,sans-serif;font-size:13px;background:#fff}.participant rect,.activation,.note,.divider-title{stroke:#181818;stroke-width:1.2}.participant-label{font-weight:bold;fill:#181818}.participant-icon{fill:none;stroke:#181818;stroke-width:1.1}.participant-box-group{fill-opacity:.16;stroke:#181818;stroke-width:1.1}.participant-box-label{font-size:11px;font-weight:bold;fill:#181818}.lifeline{stroke:#777;stroke-width:1;stroke-dasharray:5 5}.activation{fill:#FEFECE}.message,.cross,.destroy{fill:none;stroke:#181818;stroke-width:1.3}.message.dotted{stroke-dasharray:5 4}.arrow-fill{fill:#181818}.arrow-open{fill:none;stroke:#181818;stroke-width:1.5}.endpoint{fill:#fff;stroke:#181818;stroke-width:1.2}.message-label,.note-label,.reference-label,.delay-label{fill:#181818;font-size:12px}.group-body{fill-opacity:.18;stroke:#181818;stroke-width:1.1}.group-header{stroke:#181818;stroke-width:1.1}.group-label{font-size:12px;font-weight:bold;fill:#181818}.note{fill:#FEFFDD}.hex-note{stroke-dasharray:2 1}.box-note{rx:0}.divider{stroke:#777;stroke-width:1}.divider-title{fill:#f6f6f6}.divider-label{font-weight:bold}.delay{stroke:#777;stroke-dasharray:3 3}.reference{fill:#fff;stroke:#181818;stroke-width:1.2}.group-separator{stroke:#181818;stroke-dasharray:4 3}.page-break{stroke:#555;stroke-width:1.2;stroke-dasharray:8 4}.page-label{font-style:italic}.destroy{stroke-width:2}</style>\n",
  )
}

///|
/// Render a parsed sequence diagram as a standalone SVG document.
///
/// The renderer follows PlantUML's sequence-diagram ordering: participant
/// headers determine horizontal constraints, events reserve vertical space,
/// and group, lifeline, activation, and message layers are then painted in
/// that order.
pub fn SequenceDiagram::render_svg(self : SequenceDiagram) -> String {
  let layout = self.layout()
  let output = StringBuilder()
  append_svg_preamble(output, layout)
  append_groups(output, layout)
  append_participant_boxes(output, layout)
  for participant in layout.participants {
    append_participant(
      output,
      participant,
      layout.participant_head_y(participant),
      false,
    )
  }
  append_lifelines(output, layout, self.events)
  append_activations(output, layout)
  let mut arrow_anchor : Message? = None
  for index, event in self.events {
    append_event(output, layout, event, layout.placements[index], arrow_anchor)
    match event {
      Message(message) => arrow_anchor = Some(message)
      _ => ()
    }
  }
  append_destroy_marks(output, layout)
  if self.show_footbox {
    append_footboxes(output, layout)
  }
  output.write_string("</svg>\n")
  output.to_string()
}

///|
/// Parse PlantUML sequence-diagram text and render it as standalone SVG.
pub fn render_sequence_svg(input : String) -> String raise ParseError {
  parse(input).render_svg()
}
