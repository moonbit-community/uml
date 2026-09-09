///|
test "state multiline labels preserve text metrics and centered baselines" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let text = "first line\n\nx\nlast & line"
  let x = metrics.font_size.to_double()
  let y = metrics.line_height.to_double()
  let commands = []
  append_state_label(
    @graphics.Graphic::new(command => commands.push(command)),
    text,
    x,
    y,
    "label",
    metrics,
  )
  guard commands is [Draw(TextBlock(block), _, _, metadata)] else {
    @test.fail("expected one multiline label")
  }
  @test.assert_eq(block.lines.map(line => line.text).join("\n"), text)
  @test.assert_eq(block.position.x, x)
  @test.assert_eq(metadata.class_name, Some("label"))
  let last_baseline = block.lines.fold(init=block.position.y, (baseline, line) => {
    baseline + line.dy
  })
  @test.assert_eq((block.position.y + last_baseline) / 2.0, y)
  for line in block.lines {
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

///|
test "state transition drawing retains routed points and endpoint marker ownership" {
  let diagram = @parser.parse_state(
    "@startuml\nA x--> B\nB -->o C\nC <-[dashed]- D\n@enduml",
  )
  let layout = diagram.layout()
  let arrow = @graphics.MarkerRef::new("arrow")
  let cross = @graphics.MarkerRef::new("cross")
  for edge in layout.edges {
    let commands = []
    append_state_edge(
      @graphics.Graphic::new(command => commands.push(command)),
      diagram,
      edge,
      arrow,
      cross,
    )
    let paths = commands.filter_map(command => {
      guard command is Draw(MarkedPath(segments, markers), _, _, _) else {
        return None
      }
      let transition = diagram.transitions[edge.transition_index]
      @test.assert_eq(markers.end, Some(arrow))
      @test.assert_eq(
        markers.start,
        if transition.has_cross_start {
          Some(cross)
        } else {
          None
        },
      )
      let points = []
      for segment in segments {
        match segment {
          MoveTo(point) | LineTo(point) => points.push((point.x, point.y))
          CubicTo(first, second, end) => {
            points.push((first.x, first.y))
            points.push((second.x, second.y))
            points.push((end.x, end.y))
          }
          _ => @test.fail("unexpected replacement of routed path geometry")
        }
      }
      Some(points)
    })
    @test.assert_eq(paths, edge.paths.filter(path => !path.is_empty()))
  }
}

///|
test "state node drawing preserves semantic groups links and terminal nesting" {
  let diagram = @parser.parse_state(
    "@startuml\n[*] --> Review\nstate Review [[https://example.invalid/review]]\nReview --> [*]\n@enduml",
  )
  let layout = diagram.layout()
  for node in layout.nodes {
    let commands = []
    append_state_node(
      @graphics.Graphic::new(command => commands.push(command)),
      diagram,
      node,
    )
    let state = diagram.state(node.code).unwrap()
    guard commands[0] is BeginGroup(metadata) else {
      @test.fail("missing state group")
    }
    @test.assert_eq(metadata.data.contains(("code", state.code)), true)
    @test.assert_eq(commands.last(), Some(@graphics.DrawCommand::EndGroup))
    let urls = commands.filter_map(command => {
      guard command is BeginLink(url) else { return None }
      Some(url)
    })
    @test.assert_eq(urls, state.url.map_or([], url => [url]))
    if state.kind == @flow.StateKind::Final {
      let circles = commands.filter_map(command => {
        guard command is Draw(Circle(center~, radius~), _, _, _) else {
          return None
        }
        Some((center, radius))
      })
      guard circles is [outer, inner] else {
        @test.fail("final state must have concentric outlines")
      }
      @test.assert_eq(outer.0, inner.0)
      @test.assert_eq(outer.1 > inner.1, true)
    }
  }
}
