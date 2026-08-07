///|
fn append_participant(
  output : StringBuilder,
  layout : ParticipantLayout,
  y : Int,
  is_tail : Bool,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  let fill = svg_color(layout.participant.color, layout.defaults)
  match layout.participant.url {
    Some(url) =>
      output <+ "<a href=\"\{@svg.xml_escape(url)}\" target=\"_top\">\n"
    None => ()
  }
  output <+
    $|<g class="participant \{layout.participant.typ.css_class()}" data-code="\{@svg.xml_escape(layout.participant.code)}">
  match layout.participant.typ {
    Actor | Boundary | Control | Entity | Database =>
      append_vertical_participant(output, layout, y, is_tail)
    Queue => append_queue_participant(output, layout, y)
    Collections => append_collections_participant(output, layout, y, fill)
    Participant => {
      output <+
        $|<rect x="\{left}" y="\{y}" width="\{layout.width}" height="36" rx="2" fill="\{fill}"/>
      append_text(
        output,
        layout.center_x,
        y + 23,
        layout.participant.display,
        "participant-label",
        layout.defaults,
        line_height=layout.text_metrics.participant.line_height,
        font_metrics=Some(layout.text_metrics.participant),
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
    layout.defaults,
    line_height=layout.text_metrics.participant.line_height,
    font_metrics=Some(layout.text_metrics.participant),
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
    $|<path d="M\{left + 5} \{y}H\{right - 5}C\{right} \{y} \{right} \{middle} \{right} \{middle}C\{right} \{middle} \{right} \{y + 26} \{right - 5} \{y + 26}H\{left + 5}C\{left} \{y + 26} \{left} \{middle} \{left} \{middle}C\{left} \{middle} \{left} \{y} \{left + 5} \{y}Z" class="participant-icon"/>
  append_text(
    output,
    layout.center_x,
    y + 18,
    layout.participant.display,
    "participant-label",
    layout.defaults,
    line_height=layout.text_metrics.participant.line_height,
    font_metrics=Some(layout.text_metrics.participant),
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
    $|<rect x="\{left + 4}" y="\{y}" width="\{layout.width - 4}" height="36" rx="2" fill="\{fill}"/>
  output <+
    $|<rect x="\{left}" y="\{y + 4}" width="\{layout.width - 4}" height="36" rx="2" fill="\{fill}"/>
  append_text(
    output,
    layout.center_x,
    y + 27,
    layout.participant.display,
    "participant-label",
    layout.defaults,
    line_height=layout.text_metrics.participant.line_height,
    font_metrics=Some(layout.text_metrics.participant),
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
        $|<circle cx="\{x}" cy="\{y + 9}" r="8" class="participant-icon"/>
      append_line(output, x, y + 17, x, y + 44, "participant-icon")
      append_line(output, x - 13, y + 25, x + 13, y + 25, "participant-icon")
      append_line(output, x, y + 44, x - 13, y + 59, "participant-icon")
      append_line(output, x, y + 44, x + 13, y + 59, "participant-icon")
    }
    Boundary => {
      output <+
        $|<circle cx="\{x + 9}" cy="\{y + 16}" r="12" class="participant-icon"/>
      append_line(output, x - 20, y + 4, x - 20, y + 28, "participant-icon")
      append_line(output, x - 20, y + 16, x - 3, y + 16, "participant-icon")
    }
    Control => {
      output <+
        $|<circle cx="\{x}" cy="\{y + 16}" r="12" class="participant-icon"/>
      output <+
        $|<path d="M\{x + 8} \{y + 4}l6 -5 -2 5 2 5z" class="participant-icon"/>
    }
    Entity => {
      output <+
        $|<ellipse cx="\{x}" cy="\{y + 16}" rx="12" ry="12" class="participant-icon"/>
      append_line(output, x - 12, y + 30, x + 12, y + 30, "participant-icon")
    }
    Database => {
      output <+
        $|<ellipse cx="\{x}" cy="\{y + 10}" rx="18" ry="10" class="participant-icon"/>
      output <+
        $|<path d="M\{x - 18} \{y + 10}v31c0 7 36 7 36 0V\{y + 10}" class="participant-icon"/>
      output <+
        $|<path d="M\{x - 18} \{y + 10}c0 13 36 13 36 0" class="participant-icon"/>
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
  diagram_layout : DiagramLayout,
) -> Unit {
  guard layouts.length() > 0 else { return }
  let first = layouts[0]
  let (left, right) = participant_box_horizontal_bounds(layouts, box)
  let y = 4 + depth * (first.text_metrics.small_bold.line_height + 5)
  let height = (diagram_layout.height - y - 5).max(22)
  output <+
    $|<rect x="\{left}" y="\{y}" width="\{right - left}" height="\{height}" class="participant-box-group" fill="\{svg_color(box.color, diagram_layout.defaults)}"/>
  match box.label {
    Some(label) =>
      append_text(
        output,
        left + 8,
        y + 13,
        label,
        "participant-box-label",
        diagram_layout.defaults,
        anchor="start",
        line_height=first.text_metrics.small_bold.line_height,
        font_metrics=Some(first.text_metrics.small_bold),
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
              layout,
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
          layout,
        )
      None => ()
    }
  }
}

///|
