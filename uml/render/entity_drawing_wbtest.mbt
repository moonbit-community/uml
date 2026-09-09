///|
test "cloud curves translate without changing seeded control geometry" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let measurement = metrics.measure("a cloud containing several lines of text")
  for size in [measurement.width.to_double(), measurement.height.to_double()] {
    let height = size + metrics.line_height.to_double()
    let dx = metrics.font_size.to_double()
    let dy = -metrics.line_height.to_double()
    let original = description_cloud_path(size, height, 0, 0)
    let shifted = description_cloud_path(size, height, dx, dy)
    @test.assert_eq(original.is_empty(), false)
    // Compare displacement, allowing floating-point roundoff in the local frames.
    let check_shift = (before : @graphics.Point, after : @graphics.Point) => {
      @test.assert_eq((after.x - before.x).is_close(dx), true)
      @test.assert_eq((after.y - before.y).is_close(dy), true)
    }
    @test.assert_eq(shifted.length(), original.length())
    for index, segment in original {
      match (segment, shifted[index]) {
        (MoveTo(before), MoveTo(after)) => check_shift(before, after)
        (CubicTo(a, b, c), CubicTo(d, e, f)) => {
          check_shift(a, d)
          check_shift(b, e)
          check_shift(c, f)
        }
        _ => @test.fail("cloud frontier must retain its cubic segments")
      }
    }
  }
}

///|
test "object image links enclose geometry and text inside the entity identity" {
  let graph = @parser.parse_entity(
    "@startuml\nobject Example {\nfield = value\n}\n@enduml",
    family=@entity.ObjectDiagram,
  )
  let metrics = ClassTextMetrics::new(graph.style)
  let layout = graph.layout(metrics)
  let url = "https://example.invalid/object?a=1&b=2"
  let entity = { ..graph.entities[0], url: Some(url), }
  let commands = []
  let context = {
    output: @graphics.Graphic::new(command => commands.push(command)),
    diagram: graph,
    text_metrics: metrics,
  }
  context.append_entity_image(entity, 0, layout)
  guard commands
    is [
      BeginGroup(metadata),
      BeginLink(link),
      Draw(Rectangle(origin~, width~, height~, ..), _, _, _),
      ..,
      EndLink,
      EndGroup,
    ] else {
    @test.fail("object link must wrap the complete node image")
  }
  let (x, y, w, h) = layout.entity_rect(graph, 0, metrics)
  @test.assert_eq(origin, class_point(x, y))
  @test.assert_eq((width, height), (w.to_double(), h.to_double()))
  @test.assert_eq(link, url)
  @test.assert_eq(metadata.data.contains(("code", entity.qualified_code)), true)
}

///|
test "relation painting shortens visible lines without moving decoration contacts" {
  let graph = @parser.parse_entity(
    "@startuml\nclass A\nclass B\nA o--> B\n@enduml",
  )
  let metrics = ClassTextMetrics::new(graph.style)
  let layout = graph.layout(metrics)
  let relation = graph.relations[0]
  let (start, end) = relation_endpoints(
    layout,
    graph,
    relation,
    entity_index(graph, relation.left),
    entity_index(graph, relation.right),
    metrics,
  )
  let commands = []
  let color = graph.style.diagram_line_color()
  let background = graph.style.canvas_color()
  append_relation_line(
    @graphics.Graphic::new(command => commands.push(command)),
    relation_endpoint(start, None),
    relation_endpoint(end, None),
    entity_line_style(None),
    color,
    background,
    relation,
  )
  let visible = shorten_relation_path(
    relation_path([start, end]),
    relation.left_end.decoration_length(),
    relation.right_end.decoration_length(),
  ).pairs()
  guard commands[0] is Draw(Line(first, last), _, _, _) else {
    @test.fail("missing visible relation segment")
  }
  @test.assert_eq((first.x, first.y), visible[0])
  @test.assert_eq((last.x, last.y), visible[1])
  let decorations = []
  let recorder = @graphics.Graphic::new(command => decorations.push(command))
  draw_relation_decoration(
    recorder,
    relation.left_end,
    start,
    end,
    color,
    background,
  )
  draw_relation_decoration(
    recorder,
    relation.right_end,
    end,
    start,
    color,
    background,
  )
  @test.assert_eq(commands[1:].to_owned(), decorations)
}
