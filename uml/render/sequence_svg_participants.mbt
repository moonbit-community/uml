///|
fn append_participant(
  output : SequenceDrawing,
  layout : ParticipantLayout,
  y : Int,
  is_tail : Bool,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  let fill = svg_color(layout.participant.color, layout.defaults)
  output.link(layout.participant.url, output => {
    output.group(
      {
        ..Default::default(),
        class_name: Some("participant \{layout.participant.typ.css_class()}"),
        data: [("code", layout.participant.code)],
      },
      output => {
        match layout.participant.typ {
          Actor | Boundary | Control | Entity | Database =>
            append_vertical_participant(output, layout, y, is_tail, fill)
          Queue => append_queue_participant(output, layout, y, fill)
          Collections => append_collections_participant(output, layout, y, fill)
          @seq.Participant => {
            output.draw(
              Rectangle(
                origin=sequence_point(left, y),
                width=layout.width.to_double(),
                height=36,
                rx=Some(2),
                ry=None,
              ),
              fill=Color(fill),
            )
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
      },
    )
  })
}

///|
fn append_vertical_participant(
  output : SequenceDrawing,
  layout : ParticipantLayout,
  y : Int,
  is_tail : Bool,
  fill : String,
) -> Unit {
  let symbol_height = layout.participant.typ.symbol_height()
  let symbol_y = if is_tail { y + 16 } else { y }
  let label_y = if is_tail { y + 13 } else { y + symbol_height + 13 }
  append_participant_symbol(
    output,
    layout.participant.typ,
    layout.center_x,
    symbol_y,
    fill,
    layout.defaults.line,
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
  output : SequenceDrawing,
  layout : ParticipantLayout,
  y : Int,
  fill : String,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  let right = left + layout.width
  let middle = y + 13
  output.draw(
    Path([
      MoveTo(sequence_point(left + 5, y)),
      LineTo(sequence_point(right - 5, y)),
      CubicTo(
        sequence_point(right, y),
        sequence_point(right, middle),
        sequence_point(right, middle),
      ),
      CubicTo(
        sequence_point(right, middle),
        sequence_point(right, y + 26),
        sequence_point(right - 5, y + 26),
      ),
      LineTo(sequence_point(left + 5, y + 26)),
      CubicTo(
        sequence_point(left, y + 26),
        sequence_point(left, middle),
        sequence_point(left, middle),
      ),
      CubicTo(
        sequence_point(left, middle),
        sequence_point(left, y),
        sequence_point(left + 5, y),
      ),
      Close,
    ]),
    class_name="participant-icon",
    fill=Color(fill),
  )
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
  output : SequenceDrawing,
  layout : ParticipantLayout,
  y : Int,
  fill : String,
) -> Unit {
  let left = layout.center_x - layout.width / 2
  output.draw(
    Rectangle(
      origin=sequence_point(left + 4, y),
      width=(layout.width - 4).to_double(),
      height=36,
      rx=Some(2),
      ry=None,
    ),
    fill=Color(fill),
  )
  output.draw(
    Rectangle(
      origin=sequence_point(left, y + 4),
      width=(layout.width - 4).to_double(),
      height=36,
      rx=Some(2),
      ry=None,
    ),
    fill=Color(fill),
  )
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
  output : SequenceDrawing,
  typ : @seq.ParticipantType,
  x : Int,
  y : Int,
  fill : String,
  line : String,
) -> Unit {
  match typ {
    Actor => {
      output.draw(
        Circle(center=sequence_point(x, y + 9), radius=8),
        class_name="participant-icon",
        fill=Color(fill),
      )
      append_line(output, x, y + 17, x, y + 44, "participant-icon")
      append_line(output, x - 13, y + 25, x + 13, y + 25, "participant-icon")
      append_line(output, x, y + 44, x - 13, y + 59, "participant-icon")
      append_line(output, x, y + 44, x + 13, y + 59, "participant-icon")
    }
    Boundary => {
      output.draw(
        Circle(center=sequence_point(x + 9, y + 16), radius=12),
        class_name="participant-icon",
        fill=Color(fill),
      )
      append_line(output, x - 20, y + 4, x - 20, y + 28, "participant-icon")
      append_line(output, x - 20, y + 16, x - 3, y + 16, "participant-icon")
    }
    Control => {
      output.draw(
        Circle(center=sequence_point(x, y + 16), radius=12),
        class_name="participant-icon",
        fill=Color(fill),
      )
      output.draw(
        Path([
          MoveTo(sequence_point(x + 8, y + 4)),
          LineTo(sequence_point(x + 14, y - 1)),
          LineTo(sequence_point(x + 12, y + 4)),
          LineTo(sequence_point(x + 14, y + 9)),
          Close,
        ]),
        class_name="participant-icon",
        fill=Color(line),
      )
    }
    Entity => {
      output.draw(
        Ellipse(center=sequence_point(x, y + 16), rx=12, ry=12),
        class_name="participant-icon",
        fill=Color(fill),
      )
      append_line(output, x - 12, y + 30, x + 12, y + 30, "participant-icon")
    }
    Database => {
      output.draw(
        Ellipse(center=sequence_point(x, y + 10), rx=18, ry=10),
        class_name="participant-icon",
        fill=Color(fill),
      )
      output.draw(
        Path([
          MoveTo(sequence_point(x - 18, y + 10)),
          LineTo(sequence_point(x - 18, y + 41)),
          CubicTo(
            sequence_point(x - 18, y + 48),
            sequence_point(x + 18, y + 48),
            sequence_point(x + 18, y + 41),
          ),
          LineTo(sequence_point(x + 18, y + 10)),
        ]),
        class_name="participant-icon",
        fill=Color(fill),
      )
      output.draw(
        Path([
          MoveTo(sequence_point(x - 18, y + 10)),
          CubicTo(
            sequence_point(x - 18, y + 23),
            sequence_point(x + 18, y + 23),
            sequence_point(x + 18, y + 10),
          ),
        ]),
        class_name="participant-icon",
        fill=None,
      )
    }
    @seq.Participant | Queue | Collections => ()
  }
}

///|
fn @seq.ParticipantType::symbol_height(self : @seq.ParticipantType) -> Int {
  match self {
    Actor => 60
    Boundary | Control | Entity => 32
    Database => 51
    @seq.Participant | Queue | Collections => 0
  }
}

///|
fn @seq.ParticipantType::css_class(self : @seq.ParticipantType) -> String {
  match self {
    @seq.Participant => "participant-box"
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
  output : SequenceDrawing,
  layouts : Array[ParticipantLayout],
  box : @seq.ParticipantBox,
  depth : Int,
  diagram_layout : DiagramLayout,
) -> Unit {
  guard layouts.length() > 0 else { return }
  let first = layouts[0]
  let (left, right) = participant_box_horizontal_bounds(layouts, box)
  let y = 4 + depth * (first.text_metrics.small_bold.line_height + 5)
  let height = (diagram_layout.height - y - 5).max(22)
  output.draw(
    Rectangle(
      origin=sequence_point(left, y),
      width=(right - left).to_double(),
      height=height.to_double(),
      rx=None,
      ry=None,
    ),
    class_name="participant-box-group",
    fill=Color(svg_color(box.color, diagram_layout.defaults)),
  )
  if box.label is Some(label) {
    append_text(
      output,
      left + 8,
      y + 13,
      label,
      "participant-box-label",
      diagram_layout.defaults,
      anchor=Start,
      line_height=first.text_metrics.small_bold.line_height,
      font_metrics=Some(first.text_metrics.small_bold),
    )
  }
}

///|
fn append_participant_boxes(
  output : SequenceDrawing,
  layout : DiagramLayout,
) -> Unit {
  let max_depth = max_participant_box_depth(layout.participants)
  for depth in 0..<max_depth {
    for_each_participant_box_run(layout.participants, depth, (start, end, box) => {
      append_participant_box(
        output,
        layout.participants[start:end].to_owned(),
        box,
        depth,
        layout,
      )
    })
  }
}

///|
