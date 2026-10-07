///|
const SEQUENCE_ANCHOR_LABEL_GAP : Double = 6.0

///|
fn sequence_anchor_positions(
  events : Array[@seq.Event],
  layout : DiagramLayout,
) -> Map[String, (Double, Double)] {
  let anchors : Map[String, (Double, Double)] = Map([])
  for index, event in events {
    guard !layout.placements[index].ignored else { continue }
    let y = layout.placements[index].y + MESSAGE_ARROW_OFFSET
    match event {
      @seq.Message(message) => {
        guard layout.participant_at(message.from_code) is Some(from) &&
          layout.participant_at(message.to_code) is Some(to) else {
          continue
        }
        if message.anchor is Some(anchor) {
          anchors[anchor] = ((from.center_x + to.center_x) / 2, y)
        }
        if message.from_anchor is Some(anchor) {
          anchors[anchor] = (from.center_x, y)
        }
        if message.to_anchor is Some(anchor) {
          anchors[anchor] = (to.center_x, y)
        }
      }
      @seq.MessageExo(message) => {
        guard message.anchor is Some(anchor) &&
          layout.participant_at(message.participant_code) is Some(participant) else {
          continue
        }
        let border = match message.exo_type {
          @seq.FromLeft | @seq.ToLeft => 0.0
          @seq.FromRight | @seq.ToRight => layout.width
        }
        anchors[anchor] = ((border + participant.center_x) / 2, y)
      }
      _ => ()
    }
  }
  anchors
}

///|
/// LinkAnchor.drawAnchor attaches to the two arrow contact lines, never the
/// middle of an event's bounding box (which includes its notes and label).
fn append_sequence_anchors(
  output : SequenceDrawing,
  diagram : @seq.SequenceDiagram,
  layout : DiagramLayout,
) -> Unit {
  let anchors = sequence_anchor_positions(diagram.events, layout)
  for event in diagram.events {
    guard event is @seq.LinkAnchor(link) &&
      anchors.get(link.first) is Some(first) &&
      anchors.get(link.second) is Some(second) else {
      continue
    }
    let x = (first.0 + second.0) / 2
    let top = first.1.min(second.1) + 2
    let bottom = first.1.max(second.1) - 2
    output.draw(
      MarkedPath(
        [MoveTo(sequence_point(x, top)), LineTo(sequence_point(x, bottom))],
        { start: Some(output.arrow_start), end: Some(output.arrow), },
      ),
      class_name="message anchor-link",
    )
    if link.label is Some(label) {
      append_text(
        output,
        x + SEQUENCE_ANCHOR_LABEL_GAP,
        (top + bottom) / 2,
        label,
        "message-label",
        layout.defaults,
        anchor=Start,
        font_metrics=Some(layout.text_metrics.body),
      )
    }
  }
}
