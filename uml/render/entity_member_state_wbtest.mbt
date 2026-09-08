///|
test "free node uses a free marker and independently collapsible method layout" {
  let graph = @parser.parse_mbti(
      "@startuml '.mbti\npackage \"demo\";\nstruct Free {}\nfn first() -> Free\nfn second(Free) -> Int\n@enduml",
    ).graph
  let free = graph.entities.filter(entity => entity.kind is FreeFunctions)[0]
  let defaults = @entity.MbtiRenderOptions::default().member_state()
  let expanded = {
    ..member_test_metrics(graph, {}),
    member_defaults: defaults,
  }
  let closed = member_test_metrics(
    graph,
    Map([(free.qualified_code, { ..defaults, methods_expanded: false, })]),
  )
  let open_body = free.body_layout(expanded, graph.family)
  let closed_body = free.body_layout(closed, graph.family)
  @test.assert_eq(mbti_spot_word(free.kind), "free")
  @test.assert_eq(open_body.fields.is_empty(), true)
  @test.assert_eq(open_body.methods_collapsed, false)
  @test.assert_eq(closed_body.methods_collapsed, true)
  @test.assert_eq(closed_body.methods_height < open_body.methods_height, true)
  let open_layout = graph.mindmap_class_layout(expanded)
  let closed_layout = graph.mindmap_class_layout(closed)
  @test.assert_eq(open_layout.structure_edges.is_empty(), true)
  @test.assert_eq(closed_layout.structure_edges.is_empty(), true)
  @test.assert_eq(open_layout.rects.length(), graph.entities.length())
  @test.assert_eq(closed_layout.rects.length(), graph.entities.length())
  let declared = graph.entity("Free").unwrap()
  @test.assert_eq(
    declared.class_node_size(expanded, graph.family),
    declared.class_node_size(closed, graph.family),
  )
}

///|
fn member_test_metrics(
  diagram : @entity.EntityDiagram,
  states : Map[String, @entity.ClassMemberState],
) -> ClassTextMetrics {
  {
    ..ClassTextMetrics::new(diagram.style),
    member_interaction: true,
    member_defaults: { fields_expanded: true, methods_expanded: true, },
    member_states: states,
  }
}

///|
test "member state changes layout without mutating the parsed graph" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Show {
    #|  fn show(Self) -> String
    #|}
    #|struct Point {
    #|  x : Int
    #|  y : Int
    #|  z : Int
    #|}
    #|fn Point::first(Self) -> Int
    #|fn Point::second(Self) -> Int
    #|impl Show for Point;
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  let node = graph.entity("Point").unwrap()
  let original_members = node.members.copy()
  let expanded = member_test_metrics(graph, {})
  let open_body = node.body_layout(expanded, graph.family)
  for fields_expanded in [true, false] {
    for methods_expanded in [true, false] {
      let states : Map[String, @entity.ClassMemberState] = Map([
        (node.qualified_code, { fields_expanded, methods_expanded, }),
      ])
      let metrics = member_test_metrics(graph, states)
      let body = node.body_layout(metrics, graph.family)
      @test.assert_eq(body.fields_collapsed, !fields_expanded)
      @test.assert_eq(body.methods_collapsed, !methods_expanded)
      @test.assert_eq(body.fields_height <= open_body.fields_height, true)
      @test.assert_eq(body.methods_height <= open_body.methods_height, true)
      let packed = graph.mindmap_class_layout(metrics)
      for left_index, left in packed.rects {
        for right in packed.rects[left_index + 1:] {
          let overlap = left.0 < right.0 + right.2 &&
            right.0 < left.0 + left.2 &&
            left.1 < right.1 + right.3 &&
            right.1 < left.1 + left.3
          @test.assert_eq(overlap, false)
        }
      }
      for index, entity in graph.entities {
        let (_, _, width, height) = packed.rects[index]
        @test.assert_eq(
          (width, height),
          entity.class_node_size(metrics, graph.family),
        )
        if entity.code != node.code {
          @test.assert_eq(
            entity.class_node_size(metrics, graph.family),
            entity.class_node_size(expanded, graph.family),
          )
        }
      }
      @test.assert_eq(
        packed.structure_edges.length(),
        graph.mindmap_class_layout(expanded).structure_edges.length(),
      )
    }
  }
  let collapsed = member_test_metrics(
    graph,
    Map([
      (
        node.qualified_code,
        { fields_expanded: false, methods_expanded: false, },
      ),
    ]),
  )
  @test.assert_eq(
    node.class_node_size(collapsed, graph.family).1 <
    node.class_node_size(expanded, graph.family).1,
    true,
  )
  @test.assert_eq(node.members, original_members)
  @test.assert_eq(
    graph.mindmap_class_layout(expanded).rects,
    graph.mindmap_class_layout(member_test_metrics(graph, {})).rects,
  )
}

///|
test "class collapse reroutes nodes edges and attached notes using current bounds" {
  let graph = @parser.parse_entity(
    "@startuml\nclass A {\nfield\nsecond\nmethod()\n}\nclass B\nA --> B\nnote right of A: note\n@enduml",
  )
  let node = graph.entity("A").unwrap()
  let open_metrics = member_test_metrics(graph, {})
  let closed_metrics = member_test_metrics(
    graph,
    Map([
      (node.qualified_code, { fields_expanded: false, methods_expanded: true, }),
    ]),
  )
  let open_layout = graph.graphviz_layout(open_metrics)
  let closed_layout = graph.graphviz_layout(closed_metrics)
  @test.assert_eq(
    closed_layout.node(node.qualified_code).unwrap().height <
    open_layout.node(node.qualified_code).unwrap().height,
    true,
  )
  @test.assert_eq(closed_layout.edges.length(), open_layout.edges.length())
  @test.assert_eq(closed_layout.notes.length(), open_layout.notes.length())
  let body = node.body_layout(closed_metrics, graph.family)
  @test.assert_eq(body.fields_collapsed && body.methods_collapsed, true)
  let header = node.header_layout(closed_metrics, graph.family)
  @test.assert_eq(
    node.class_node_size(closed_metrics, graph.family).1,
    header.height,
  )
  let restored = graph.graphviz_layout(member_test_metrics(graph, {}))
  @test.assert_eq(
    restored.node(node.qualified_code).unwrap().height,
    open_layout.node(node.qualified_code).unwrap().height,
  )
}
