///|
fn record_sequence_drawing(
  commands : Array[@graphics.DrawCommand],
) -> SequenceDrawing {
  {
    graphic: @graphics.Graphic::new(command => commands.push(command)),
    arrow: @graphics.MarkerRef::new("filled-end"),
    arrow_start: @graphics.MarkerRef::new("filled-start"),
    open_arrow: @graphics.MarkerRef::new("open-end"),
    open_arrow_start: @graphics.MarkerRef::new("open-start"),
  }
}

///|
test "sequence messages connect their participants and keep endpoint marker ownership" {
  let diagram = @parser.parse_sequence(
    "@startuml\nA -> B\nB ->> A\nA <-> B\nB -> B\n@enduml",
  )
  let layout = diagram.layout()
  for index, event in diagram.events {
    guard event is @seq.Message(message) else { @test.fail("expected message") }
    let commands = []
    let drawing = record_sequence_drawing(commands)
    append_message(drawing, layout, message, layout.placements[index], None)
    let paths = commands.filter_map(command => {
      guard command is Draw(MarkedPath(path, markers), _, _, _) else {
        return None
      }
      Some((path, markers))
    })
    guard paths is [(path, markers)] else {
      @test.fail("expected one message route")
    }
    let from = layout.participant_at(message.from_code).unwrap()
    let to = layout.participant_at(message.to_code).unwrap()
    guard path[0] is MoveTo(start) else { @test.fail("missing route start") }
    guard path.last() is Some(LineTo(end)) else {
      @test.fail("missing route end")
    }
    @test.assert_eq(start.x, from.center_x.to_double())
    @test.assert_eq(end.x, to.center_x.to_double())
    @test.assert_eq(
      markers.end,
      drawing.marker(message.arrow_config.head2, false),
    )
    if message.from_code == message.to_code {
      @test.assert_eq(end.y > start.y, true)
      @test.assert_eq(markers.start, None)
      @test.assert_eq(
        path.any(segment => {
          guard segment is LineTo(point) else { return false }
          point.x > start.x
        }),
        true,
      )
    } else {
      @test.assert_eq(start.y, end.y)
      @test.assert_eq(
        markers.start,
        drawing.marker(message.arrow_config.head1, true),
      )
    }
  }
}

///|
test "sequence group header returns to the body left edge below its title" {
  for title in ["short", "a considerably longer group caption"] {
    let diagram = @parser.parse_sequence(
      "@startuml\ngroup \{title}\nA -> B\nend\n@enduml",
    )
    let layout = diagram.layout()
    let commands = []
    append_groups(record_sequence_drawing(commands), layout)
    let headers = commands.filter_map(command => {
      guard command is Draw(Path(path), _, _, _) else { return None }
      Some(path)
    })
    guard headers is [header] else { @test.fail("missing group header") }
    guard header is [MoveTo(start), .., LineTo(end), Close] else {
      @test.fail("header must close from its bottom left corner")
    }
    let (left, _) = layout.group_bounds(layout.groups[0])
    @test.assert_eq(start.x, left.to_double())
    @test.assert_eq(end.x, start.x)
    @test.assert_eq(end.y > start.y, true)
  }
}

///|
test "sequence message URL overrides note URL and wraps the anchored drawing" {
  let diagram = @parser.parse_sequence("@startuml\nA -> B\n@enduml")
  let layout = diagram.layout()
  guard diagram.events[0] is @seq.Message(original) else {
    @test.fail("missing message")
  }
  let own_url = "https://example.invalid/message?x=1&y=2"
  let note_url = "https://example.invalid/note"
  let anchor = "message & anchor"
  for url in [None, Some(own_url)] {
    let message = { ..original, url, anchor: Some(anchor), }
    let commands = []
    append_message(
      record_sequence_drawing(commands),
      layout,
      message,
      layout.placements[0],
      Some(note_url),
    )
    guard commands
      is [
        BeginLinkWithTarget(actual_url, target),
        BeginGroup(metadata),
        ..,
        EndGroup,
        EndLink,
      ] else {
      @test.fail("link must enclose the complete anchored message")
    }
    @test.assert_eq(actual_url, url.unwrap_or(note_url))
    @test.assert_eq(target, "_top")
    @test.assert_eq(metadata.id, message.anchor)
  }
}

///|
test "sequence multiline text carries measured advances and baseline spacing" {
  let diagram = @parser.parse_sequence("@startuml\nA -> B\n@enduml")
  let layout = diagram.layout()
  let metrics = layout.text_metrics.body
  let text = "first & line\n\nx\nlast line"
  let position = sequence_point(layout.width / 2, layout.body_top)
  let commands = []
  append_text(
    record_sequence_drawing(commands),
    layout.width / 2,
    layout.body_top,
    text,
    "message-label",
    layout.defaults,
    line_height=metrics.line_height,
    font_metrics=Some(metrics),
  )
  guard commands is [Draw(TextBlock(block), _, _, _)] else {
    @test.fail("missing text block")
  }
  @test.assert_eq(block.position, position)
  @test.assert_eq(block.lines.map(line => line.text).join("\n"), text)
  for index, line in block.lines {
    @test.assert_eq(
      line.dy,
      if index == 0 {
        0.0
      } else {
        metrics.line_height.to_double()
      },
    )
    if line.text.length() > 1 {
      @test.assert_eq(
        line.advance,
        Some(metrics.measure(line.text).advance_width.to_double()),
      )
    } else {
      @test.assert_eq(line.advance, None)
    }
  }
}
