///|
fn append_note(
  output : SequenceDrawing,
  layout : DiagramLayout,
  note : @seq.Note,
  placement : EventPlacement,
  arrow_anchor : @seq.Message?,
  suppress_url : Bool,
) -> Unit {
  let geometry = layout.note_geometry(note, placement, arrow_anchor)
  let x = geometry.x
  let y = geometry.y
  let component = geometry.component
  let class_name = match note.note_style {
    @seq.NodeNormal => "note"
    @seq.Hexagonal => "note hex-note"
    @seq.Box => "note box-note"
  }
  let fill = note_color(note.color, note.stereotype, layout.defaults)
  output.link(if suppress_url { None } else { note.url }, output => {
    match note.note_style {
      @seq.NodeNormal => {
        let fold_x = x + component.width - component.fold
        let fold_y = y + component.fold
        output.draw(
          Path([
            MoveTo(sequence_point(x, y)),
            LineTo(sequence_point(x, y + component.height)),
            LineTo(sequence_point(x + component.width, y + component.height)),
            LineTo(sequence_point(x + component.width, fold_y)),
            LineTo(sequence_point(fold_x, y)),
            Close,
          ]),
          class_name~,
          fill=Color(fill),
        )
        output.draw(
          Path([
            MoveTo(sequence_point(fold_x, y)),
            LineTo(sequence_point(fold_x, fold_y)),
            LineTo(sequence_point(x + component.width, fold_y)),
          ]),
          class_name="note-fold",
          fill=None,
        )
      }
      @seq.Hexagonal =>
        output.draw(
          Polygon([
            sequence_point(x + component.fold, y),
            sequence_point(x + component.width - component.fold, y),
            sequence_point(x + component.width, y + component.height / 2),
            sequence_point(
              x + component.width - component.fold,
              y + component.height,
            ),
            sequence_point(x + component.fold, y + component.height),
            sequence_point(x, y + component.height / 2),
          ]),
          class_name~,
          fill=Color(fill),
        )
      @seq.Box =>
        output.draw(
          Rectangle(
            origin=sequence_point(x, y),
            width=component.width.to_double(),
            height=component.height.to_double(),
            rx=None,
            ry=None,
          ),
          class_name~,
          fill=Color(fill),
        )
    }
    append_text(
      output,
      x + component.text_x,
      y + component.text_y,
      note.text,
      "note-label",
      layout.defaults,
      anchor=Start,
      line_height=layout.text_metrics.note.line_height,
      font_metrics=Some(layout.text_metrics.note),
    )
  })
}

///|
fn append_divider(
  output : SequenceDrawing,
  layout : DiagramLayout,
  divider : @seq.Divider,
  placement : EventPlacement,
) -> Unit {
  let y = placement.y + 17
  append_line(output, 28, y, layout.width - 28, y, "divider")
  let width = TextSize::of_with(divider.title, layout.text_metrics.body_bold).width +
    22
  output.draw(
    Rectangle(
      origin=sequence_point((layout.width - width) / 2, y - 12),
      width=width.to_double(),
      height=24,
      rx=None,
      ry=None,
    ),
    class_name="divider-title",
  )
  append_text(
    output,
    layout.width / 2,
    y + 5,
    divider.title,
    "divider-label",
    layout.defaults,
    line_height=layout.text_metrics.body_bold.line_height,
    font_metrics=Some(layout.text_metrics.body_bold),
  )
}

///|
fn append_delay(
  output : SequenceDrawing,
  layout : DiagramLayout,
  delay : @seq.Delay,
  placement : EventPlacement,
) -> Unit {
  let y = placement.y + 14
  append_line(output, 28, y, layout.width - 28, y, "delay")
  if delay.label is Some(label) {
    append_text(
      output,
      layout.width / 2,
      y - 5,
      label,
      "delay-label",
      layout.defaults,
      line_height=layout.text_metrics.body.line_height,
      font_metrics=Some(layout.text_metrics.body),
    )
  }
}

///|
fn append_reference(
  output : SequenceDrawing,
  layout : DiagramLayout,
  reference : @seq.Reference,
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
  output.draw(
    Rectangle(
      origin=sequence_point(x, placement.y),
      width=width.to_double(),
      height=placement.height.to_double(),
      rx=None,
      ry=None,
    ),
    class_name="reference",
  )
  output.draw(
    Path([
      MoveTo(sequence_point(x, placement.y)),
      LineTo(sequence_point(x + tab_width, placement.y)),
      LineTo(sequence_point(x + tab_width, placement.y + 7)),
      LineTo(sequence_point(x + tab_width - 10, placement.y + 17)),
      LineTo(sequence_point(x, placement.y + 17)),
      Close,
    ]),
    class_name="reference-tab",
  )
  append_text(
    output,
    x + 12,
    placement.y + 16,
    "ref",
    "reference-tab-label",
    layout.defaults,
    anchor=Start,
    line_height=layout.text_metrics.body_bold.line_height,
    font_metrics=Some(layout.text_metrics.body_bold),
  )
  append_text(
    output,
    x + width / 2,
    placement.y + placement.height - 7,
    reference.label.unwrap_or(""),
    "reference-label",
    layout.defaults,
    line_height=layout.text_metrics.body.line_height,
    font_metrics=Some(layout.text_metrics.body),
  )
}

///|
fn append_return(
  output : SequenceDrawing,
  layout : DiagramLayout,
  value : @seq.Return,
  placement : EventPlacement,
  preceding_message : @seq.Message?,
) -> Unit {
  guard layout.participants.length() >= 2 else { return }
  let y = placement.y + MESSAGE_ARROW_OFFSET
  let last_participant = layout.participants[layout.participants.length() - 1]
  let activation = layout.activations.fold(init=None, (activation, candidate) => {
    if candidate.start_y <= y && y <= candidate.end_y {
      Some(candidate)
    } else {
      activation
    }
  })
  let (from, to) = if activation is Some(span) {
    (
      layout.participant_at(span.participant_code).unwrap_or(last_participant),
      span.caller_code.map_or(layout.participants[0], caller => {
        layout.participant_at(caller).unwrap_or(layout.participants[0])
      }),
    )
  } else if preceding_message is Some(message) {
    (
      layout.participant_at(message.to_code).unwrap_or(last_participant),
      layout.participant_at(message.from_code).unwrap_or(layout.participants[0]),
    )
  } else {
    (last_participant, layout.participants[0])
  }
  let return_value = value.value.unwrap_or("")
  let label = placement.number.map_or(return_value, number => {
    "\{number} \{return_value}"
  })
  output.draw(
    MarkedPath(
      [
        MoveTo(sequence_point(from.center_x, y)),
        LineTo(sequence_point(to.center_x, y)),
      ],
      { start: None, end: Some(output.arrow), },
    ),
    class_name="message dotted",
  )
  append_text(
    output,
    (from.center_x + to.center_x) / 2,
    y - 6,
    label,
    "message-label",
    layout.defaults,
    line_height=layout.text_metrics.body.line_height,
    font_metrics=Some(layout.text_metrics.body),
  )
}

///|
fn append_event(
  output : SequenceDrawing,
  layout : DiagramLayout,
  event : @seq.Event,
  placement : EventPlacement,
  arrow_anchor : @seq.Message?,
  note_url : String?,
  suppress_url : Bool,
) -> Unit {
  guard !placement.ignored else { return }
  match event {
    @seq.Message(message) =>
      append_message(output, layout, message, placement, note_url)
    @seq.MessageExo(message) =>
      append_exo_message(output, layout, message, placement, note_url)
    @seq.Note(note) =>
      append_note(output, layout, note, placement, arrow_anchor, suppress_url)
    @seq.Notes(notes) =>
      notes.each(note => {
        append_note(output, layout, note, placement, arrow_anchor, suppress_url)
      })
    @seq.Divider(divider) => append_divider(output, layout, divider, placement)
    @seq.Delay(delay) => append_delay(output, layout, delay, placement)
    @seq.Reference(reference) =>
      append_reference(output, layout, reference, placement)
    @seq.Return(value) =>
      append_return(output, layout, value, placement, arrow_anchor)
    @seq.Newpage(page) => {
      append_line(
        output,
        18,
        placement.y + 20,
        layout.width - 18,
        placement.y + 20,
        "page-break",
      )
      if page.title is Some(title) {
        append_text(
          output,
          layout.width / 2,
          placement.y + 14,
          title,
          "page-label",
          layout.defaults,
          line_height=layout.text_metrics.body_italic.line_height,
          font_metrics=Some(layout.text_metrics.body_italic),
        )
      }
    }
    @seq.LinkAnchor => ()
    @seq.AutoNewpage(size) =>
      output.graphic.annotate({
        ..Default::default(),
        class_name: Some("auto-newpage"),
        data: size.map_or([], height => [("height", height.to_string())]),
      })
    @seq.GroupingStart(_)
    | @seq.GroupingLeaf(_)
    | @seq.LifeEvent(_)
    | @seq.HSpace(_)
    | @seq.BoxStart(_)
    | @seq.BoxEnd
    | @seq.Autonumber(_)
    | @seq.AutonumberStop
    | @seq.AutonumberResume(_)
    | @seq.AutonumberIncrement(_)
    | @seq.Autoactivate(_)
    | @seq.Footbox(_)
    | @seq.HideUnlinked(_)
    | @seq.Create
    | @seq.Url(_, _)
    | @seq.DeactivateLatest
    | @seq.IgnoreNewpage => ()
  }
}

///|
fn append_destroy_marks(
  output : SequenceDrawing,
  layout : DiagramLayout,
) -> Unit {
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
fn append_footboxes(output : SequenceDrawing, layout : DiagramLayout) -> Unit {
  for participant in layout.participants {
    append_participant(output, participant, layout.participant_tail_y(), true)
  }
}

///|
