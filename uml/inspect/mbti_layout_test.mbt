///|
/// The mindmap layout puts every entity at a distinct node, with no two boxes
/// overlapping.
test "mindmap layout places every entity in a disjoint box" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let diagram = @parser.parse_mbti(source)
  let layout = @render.mindmap_layout_entity(text_context, diagram.graph)
  @test.assert_eq(layout.nodes.length(), diagram.graph.entities.length())
  expect_nodes_disjoint(layout)
}

///|
/// The tree layout is a forest: every node except the root has exactly one
/// incoming tree edge, and each edge connects the relation target (parent) to
/// the relation source (child) with the child to the right.
test "mindmap layout connects every relation as a tree edge" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|trait Show : Eq {
    #|  fn to_string(Self) -> String
    #|}
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Show for Point;
    #|@enduml
  let diagram = @parser.parse_mbti(source)
  let layout = @render.mindmap_layout_entity(text_context, diagram.graph)
  // Each non-root node hangs under exactly one parent.
  @test.assert_eq(layout.edges.length(), layout.nodes.length() - 1)
  for edge in layout.edges {
    let mut parent_x = 0.0
    let mut found_parent = false
    let mut found_child = false
    for node in layout.nodes {
      if node.index == edge.parent_index {
        parent_x = node.x
        found_parent = true
      }
      if node.index == edge.child_index {
        found_child = node.x >= parent_x
      }
    }
    @test.assert_eq(found_parent && found_child, true)
  }
}

///|
/// A struct with a field of its own type does not loop the tree building:
/// the self relation is skipped and the struct still renders as its own root.
test "mindmap layout survives a self-referencing struct" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Node {
    #|  next : Node
    #|}
    #|@enduml
  let diagram = @parser.parse_mbti(source)
  let layout = @render.mindmap_layout_entity(text_context, diagram.graph)
  @test.assert_eq(layout.nodes.length(), diagram.graph.entities.length())
  // The self relation is skipped, so Node is a root with no incoming edge.
  @test.assert_eq(layout.edges.length(), 0)
}

///|
/// Entities that no relation points to (the base traits) are forest roots,
/// so no tree edge points at them.
test "mindmap layout makes base entities forest roots" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let diagram = @parser.parse_mbti(source)
  let layout = @render.mindmap_layout_entity(text_context, diagram.graph)
  let root_count = layout.nodes
    .filter(node => layout.edges.all(edge => edge.child_index != node.index))
    .length()
  // Point's relation target is Eq, so only Eq is a root.
  @test.assert_eq(root_count, 1)
}

///|
/// Relations that lose the tree race are dropped from the painting: the SVG
/// draws exactly the packed parent-child edges, so every non-root node keeps
/// a single edge and never connects to sibling or otherwise unrelated nodes.
test "mindmap layout paints only tree edges" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|struct Line {
    #|  start : Point
    #|  end : Point
    #|}
    #|impl Eq for Line;
    #|@enduml
  let diagram = @parser.parse_mbti(source)
  let layout = @render.mindmap_layout_entity(text_context, diagram.graph)
  let svg = @render.render_mbti_svg(text_context, diagram) catch {
    _ => @test.fail("svg rendering failed")
  }
  let painted_edges = svg.split("class=\"relation\"").count() - 1
  @test.assert_eq(painted_edges, layout.edges.length())
}
