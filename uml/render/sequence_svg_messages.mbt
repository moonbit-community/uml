///|
fn append_arrow_head(
  output : StringBuilder,
  head : @seq.ArrowHead,
  x : Int,
  y : Int,
) -> Unit {
  match head {
    @seq.CrossX => {
      append_line(output, x - 5, y - 5, x + 5, y + 5, "cross")
      append_line(output, x - 5, y + 5, x + 5, y - 5, "cross")
    }
    _ => ()
  }
}

///|
fn append_partial_arrow_head(
  output : StringBuilder,
  head : @seq.ArrowHead,
  part : @seq.ArrowPart,
  x : Int,
  y : Int,
  points_right : Bool,
) -> Unit {
  match head {
    @seq.Normal => {
      let base = if points_right { x - 10 } else { x + 10 }
      let path = match part {
        @seq.TopPart => "M\{base} \{y - 4}L\{x} \{y}L\{base} \{y}Z"
        @seq.BottomPart => "M\{base} \{y}L\{x} \{y}L\{base} \{y + 4}Z"
        @seq.Full => ""
      }
      if part is @seq.TopPart || part is @seq.BottomPart {
        output <+
          $|<path d="\{path}" class="partial-arrow"/>
      }
    }
    @seq.Async => {
      let base = if points_right { x - 10 } else { x + 10 }
      match part {
        @seq.TopPart => {
          append_line(output, base, y - 4, x, y, "partial-arrow")
          append_line(output, x, y, base, y, "partial-arrow")
        }
        @seq.BottomPart => {
          append_line(output, base, y, x, y, "partial-arrow")
          append_line(output, x, y, base, y + 4, "partial-arrow")
        }
        @seq.Full => ()
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
fn @seq.ArrowHead::marker(self : @seq.ArrowHead, start : Bool) -> String {
  match (self, start) {
    (@seq.Normal, true) => " marker-start=\"url(#arrow-start)\""
    (@seq.Normal, false) => " marker-end=\"url(#arrow)\""
    (@seq.Async, true) => " marker-start=\"url(#open-arrow-start)\""
    (@seq.Async, false) => " marker-end=\"url(#open-arrow)\""
    (@seq.CrossX | @seq.NoneHead, _) => ""
  }
}

///|
/// The message link URL: the message's own URL, falling back to the URL of
/// an attached on-arrow note, mirroring `AbstractMessage.getUrl()`.
fn link_url(own : String?, note : String?) -> String? {
  own.map_or(note, url => Some(url))
}

///|
fn append_message(
  output : StringBuilder,
  layout : DiagramLayout,
  message : @seq.Message,
  placement : EventPlacement,
  note_url : String?,
) -> Unit {
  guard layout.participant_at(message.from_code) is Some(from) else { return }
  guard layout.participant_at(message.to_code) is Some(to) else { return }
  // Java merges the stereotype into the arrow style signature
  // (AbstractMessage.getStyleSignature); the modeled style set has no
  // stereotype-tagged arrow styles, so the tag changes nothing visible.
  let _ = message.stereotype
  // Java's `AbstractMessage.getUrl()` falls back to the URL of an attached
  // on-arrow note, wrapping the arrow in the note's link as well.
  if link_url(message.url, note_url) is Some(url) {
    output <+ "<a href=\"\{@svg.xml_escape(url)}\" target=\"_top\">\n"
  }
  let y = placement.y + MESSAGE_ARROW_OFFSET
  let label = message.rendered_label(placement.number)
  let dotted = if message.arrow_config.body is @seq.Dotted {
    " dotted"
  } else {
    ""
  }
  let line_class = "message\{dotted}"
  let start_y = y
  let end_y = y
  if message.anchor is Some(anchor) {
    output <+
      $|<g id="\{@svg.xml_escape(anchor)}" class="message-anchor">
  }
  if from.participant.code == to.participant.code {
    let loop_x = from.center_x + 34
    let end_marker = match message.arrow_config.part {
      @seq.Full => message.arrow_config.head2.marker(false)
      @seq.TopPart | @seq.BottomPart => ""
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
      layout.defaults,
      anchor="start",
      line_height=layout.text_metrics.body.line_height,
      font_metrics=Some(layout.text_metrics.body),
    )
  } else {
    let start_x = from.center_x
    let end_x = to.center_x
    let end_marker = match message.arrow_config.part {
      @seq.Full => message.arrow_config.head2.marker(false)
      @seq.TopPart | @seq.BottomPart => ""
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
      layout.defaults,
      anchor="start",
      line_height=layout.text_metrics.body.line_height,
      font_metrics=Some(layout.text_metrics.body),
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
  if message.arrow_config.part is @seq.Full {
    append_arrow_head(output, message.arrow_config.head2, to.center_x, end_y)
  }
  if message.anchor is Some(_) {
    output.write_string("</g>\n")
  }
  if link_url(message.url, note_url) is Some(_) {
    output.write_string("</a>\n")
  }
}

///|
fn append_exo_message(
  output : StringBuilder,
  layout : DiagramLayout,
  message : @seq.MessageExo,
  placement : EventPlacement,
  note_url : String?,
) -> Unit {
  guard layout.participant_at(message.participant_code) is Some(participant) else {
    return
  }
  if link_url(message.url, note_url) is Some(url) {
    output <+ "<a href=\"\{@svg.xml_escape(url)}\" target=\"_top\">\n"
  }
  let y = placement.y + MESSAGE_ARROW_OFFSET
  let (outside_x, participant_x) = match message.exo_type {
    @seq.FromLeft | @seq.ToLeft =>
      (
        if message.short_arrow {
          participant.center_x - 40
        } else {
          0
        },
        participant.center_x,
      )
    @seq.FromRight | @seq.ToRight =>
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
    @seq.FromLeft | @seq.FromRight => (outside_x, participant_x)
    @seq.ToLeft | @seq.ToRight => (participant_x, outside_x)
  }
  let dotted = if message.arrow_config.body is @seq.Dotted {
    " dotted"
  } else {
    ""
  }
  output <+
    $|<line x1="\{start_x}" y1="\{y}" x2="\{end_x}" y2="\{y}" class="message\{dotted}"\{message.arrow_config.head1.marker(true)}\{message.arrow_config.head2.marker(false)}/>
  let raw_label = message.label.unwrap_or("")
  let label = placement.number.map_or_else(() => raw_label, number => {
    "\{number} \{raw_label}"
  })
  append_text(
    output,
    start_x.min(end_x) + 7,
    y - 6,
    label,
    "message-label",
    layout.defaults,
    anchor="start",
    line_height=layout.text_metrics.body.line_height,
    font_metrics=Some(layout.text_metrics.body),
  )
  if link_url(message.url, note_url) is Some(_) {
    output.write_string("</a>\n")
  }
}

///|
