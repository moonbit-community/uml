///|
fn activity_edge_points(
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
) -> Array[@graphics.Point] raise {
  let commands = []
  let arrow = @graphics.MarkerRef::new("test-arrow")
  append_edge(
    @graphics.Graphic::new(command => commands.push(command)),
    layout,
    edge,
    @metrics.FontMetrics::from_defaults(),
    arrow,
  )
  guard commands[0] is Draw(MarkedPath(path, markers), _, _, _) else {
    @test.fail("expected an activity connector")
  }
  @test.assert_eq(markers.start, None)
  @test.assert_eq(markers.end, Some(arrow))
  path.map(segment => {
    match segment {
      MoveTo(point) | LineTo(point) => point
      _ =>
        @test.fail("orthogonal activity routes must remain straight segments")
    }
  })
}

///|
test "all activity routes preserve orthogonality under layout translation" {
  let routes : Array[ActivityEdgeRoute] = [
    Forward,
    Horizontal,
    Goto,
    BackwardLeft,
    BackwardRight,
    IfDownLeft,
    IfDownRight,
    SwitchLeft,
    SwitchRight,
    SwitchMiddle,
    WhileExitLeft,
  ]
  let sources = [
    ":First;\n:Second;", "if (choose?) then (yes)\n:First;\nelse (no)\n:Second;\nendif",
    "fork\n:First;\nfork again\n:Second;\nend fork",
  ]
  let dx = ACTION_FONT
  let dy = SMALL_FONT
  for source in sources {
    let layout = @parser.parse_activity(source).layout()
    let moved = {
      ..layout,
      nodes: layout.nodes.map(node => {
        ..node,
        x: node.x + dx,
        y: node.y + dy,
      }),
    }
    for edge in layout.edges {
      for route in routes {
        let edge = { ..edge, route, }
        let points = activity_edge_points(layout, edge)
        let moved_points = activity_edge_points(moved, edge)
        @test.assert_eq(
          moved_points,
          points.map(point => {
            x: point.x + dx.to_double(),
            y: point.y + dy.to_double(),
          }),
        )
        for index in 1..<points.length() {
          let previous = points[index - 1]
          let point = points[index]
          @test.assert_eq(point.x == previous.x || point.y == previous.y, true)
        }
      }
    }
  }
}

///|
test "activity labels carry the selected font and measured line advances" {
  for size in [ACTION_FONT, SMALL_FONT] {
    let metrics = @metrics.FontMetrics::from_defaults(font_size=size)
    let text = "first line\nlast line"
    let commands = []
    append_label(
      @graphics.Graphic::new(command => commands.push(command)),
      size,
      size,
      text,
      metrics,
      anchor=Start,
      multiline_anchor=Baseline,
    )
    guard commands is [Draw(StyledTextBlock(block, font), _, _, _)] else {
      @test.fail("expected a multiline label with explicit font size")
    }
    @test.assert_eq(font.font_size, Some(metrics.font_size.to_double()))
    @test.assert_eq(block.position.y, size.to_double())
    @test.assert_eq(block.anchor, @graphics.TextAnchor::Start)
    @test.assert_eq(block.lines.map(line => line.text).join("\n"), text)
    for line in block.lines {
      @test.assert_eq(
        line.advance,
        Some(metrics.measure(line.text).advance_width.to_double()),
      )
    }
  }
}
