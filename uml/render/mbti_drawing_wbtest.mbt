///|
fn mbti_drawing_graph() -> @entity.EntityDiagram raise @tokenizer.ParseError {
  @parser.parse_mbti(
    (
      #|@startuml '.mbti
      #|package "demo";
      #|trait Show {
      #|  fn show(Self) -> String
      #|}
      #|struct Point {
      #|  x : Int
      #|  y : Int
      #|}
      #|fn Point::first(Self) -> Int
      #|fn Point::second(Self) -> Int
      #|impl Show for Point;
      #|@enduml
    ),
  ).graph
}

///|
test "mbti toggle areas follow current compartment bounds and expansion state" {
  let graph = mbti_drawing_graph()
  let entity = graph.entity("Point").unwrap()
  let index = entity_index(graph, entity.qualified_code).unwrap()
  for fields_expanded in [true, false] {
    for methods_expanded in [true, false] {
      let metrics = member_test_metrics(
        graph,
        Map([(entity.qualified_code, { fields_expanded, methods_expanded, })]),
      )
      let layout = {
        ..graph.layout(metrics),
        mindmap: Some(graph.mindmap_class_layout(metrics)),
      }
      let commands = []
      let drawing = {
        graphic: @graphics.Graphic::new(command => commands.push(command)),
        diagram: graph,
        text_metrics: metrics,
      }
      drawing.draw_class(entity, index, layout)
      let (x, y, width, _) = layout.entity_rect(graph, index, metrics)
      let header = entity.header_layout(metrics, graph.family)
      let body = entity.body_layout(metrics, graph.family)
      let toggles = commands.filter_map(command => {
        guard command
          is Draw(
            ToggleArea(origin~, width~, height~, expanded~, ..),
            _,
            _,
            metadata
          ) else {
          return None
        }
        @test.assert_eq(
          metadata.data.contains(("member-node", entity.qualified_code)),
          true,
        )
        Some((origin, width, height, expanded))
      })
      @test.assert_eq(toggles, [
        (
          class_point(x, y + header.height),
          width.to_double(),
          body.fields_height.to_double(),
          fields_expanded,
        ),
        (
          class_point(x, y + header.height + body.fields_height),
          width.to_double(),
          body.methods_height.to_double(),
          methods_expanded,
        ),
      ])
    }
  }
}

///|
test "mbti tree painting preserves shortened cubic routes and decorations" {
  let graph = mbti_drawing_graph()
  let metrics = member_test_metrics(graph, {})
  let packed = graph.mindmap_class_layout(metrics)
  @test.assert_eq(packed.structure_edges.is_empty(), false)
  for edge in packed.structure_edges {
    let commands = []
    draw_mindmap_class_edge(
      @graphics.Graphic::new(command => commands.push(command)),
      edge,
      graph.style.diagram_line_color(),
      graph.style.canvas_color(),
    )
    let points = [
      (edge.x1.to_double(), edge.y1.to_double()),
      (edge.control1_x.to_double(), edge.control1_y.to_double()),
      (edge.control2_x.to_double(), edge.control2_y.to_double()),
      (edge.x2.to_double(), edge.y2.to_double()),
    ]
    let visible = shorten_relation_path(
      relation_path(points),
      edge.parent_end.decoration_length(),
      edge.child_end.decoration_length(),
    ).pairs()
    guard commands[0] is Draw(Path(path), _, _, _) else {
      @test.fail("tree route must precede decorations")
    }
    @test.assert_eq(path, @graphics.spline_segments(visible))
    let expected = edge.parent_end
      .decoration_geometry(points[0], points[1])
      .map_or(0, g => g.primitives.length()) +
      edge.child_end
      .decoration_geometry(points[3], points[2])
      .map_or(0, g => g.primitives.length())
    @test.assert_eq(commands.length() - 1, expected)
  }
}

///|
test "empty class titles keep their laid out baseline without an artificial advance" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let position = class_point(metrics.font_size, metrics.line_height)
  let commands = []
  draw_class_text(
    @graphics.Graphic::new(command => commands.push(command)),
    metrics.font_size,
    metrics.line_height,
    "",
    "class-title",
    metrics,
  )
  guard commands is [Draw(StyledText(run, _), _, _, _)] else {
    @test.fail("missing title run")
  }
  @test.assert_eq(run.position, position)
  @test.assert_eq(run.advance, None)
}
