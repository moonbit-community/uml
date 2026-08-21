///|
/// Whether two layout nodes overlap.
fn mbti_rects_overlap(
  left : (Int, Int, Int, Int),
  right : (Int, Int, Int, Int),
) -> Bool {
  left.0 < right.0 + right.2 &&
  right.0 < left.0 + left.2 &&
  left.1 < right.1 + right.3 &&
  right.1 < left.1 + left.3
}

///|
/// The mindmap layout puts the package name at node 0 and every entity at a
/// distinct node, with no two boxes overlapping.
test "mindmap layout places the package at the root with disjoint boxes" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let diagram = parse(source)
  let layout = diagram.graph.mindmap_layout(diagram.package_name)
  @test.assert_eq(layout.nodes.length(), diagram.graph.entities.length() + 1)
  @test.assert_eq(layout.nodes[0].idea_index, 0)
  for left_index in 0..<layout.nodes.length() {
    for right_index in (left_index + 1)..<layout.nodes.length() {
      let left = layout.nodes[left_index]
      let right = layout.nodes[right_index]
      @test.assert_eq(
        mbti_rects_overlap(
          (left.x, left.y, left.width, left.height),
          (right.x, right.y, right.width, right.height),
        ),
        false,
      )
    }
  }
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
  let diagram = parse(source)
  let layout = diagram.graph.mindmap_layout(diagram.package_name)
  // Each non-root node hangs under exactly one parent.
  @test.assert_eq(layout.edges.length(), layout.nodes.length() - 1)
  for edge in layout.edges {
    let mut parent_x = 0
    let mut found_parent = false
    let mut found_child = false
    for node in layout.nodes {
      if node.idea_index == edge.parent_index {
        parent_x = node.x
        found_parent = true
      }
      if node.idea_index == edge.child_index {
        found_child = node.x >= parent_x
      }
    }
    @test.assert_eq(found_parent && found_child, true)
  }
}

///|
/// A struct with a field of its own type does not loop the tree building:
/// the self relation is skipped and the struct still renders.
test "mindmap layout survives a self-referencing struct" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Node {
    #|  next : Node
    #|}
    #|@enduml
  let diagram = parse(source)
  let layout = diagram.graph.mindmap_layout(diagram.package_name)
  @test.assert_eq(layout.nodes.length(), diagram.graph.entities.length() + 1)
  // The self relation is skipped, so Node hangs directly under the root.
  @test.assert_eq(layout.edges.length(), 1)
  let svg = diagram.render_svg() catch {
    _ => @test.fail("svg rendering failed")
  }
  @test.assert_eq(svg.contains("Node"), true)
}

///|
/// Entities that no relation points to (the base traits) hang directly under
/// the package root, so their tree edge has the root as its parent.
test "mindmap layout hangs base entities directly under the package root" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let diagram = parse(source)
  let layout = diagram.graph.mindmap_layout(diagram.package_name)
  let root_child_count = layout.edges
    .filter(edge => edge.parent_index == 0)
    .length()
  // Point's relation target is Eq, so only Eq hangs directly under the root.
  @test.assert_eq(root_child_count, 1)
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
  let diagram = parse(source)
  let layout = diagram.graph.mindmap_layout(diagram.package_name)
  let svg = diagram.render_svg() catch {
    _ => @test.fail("svg rendering failed")
  }
  let painted_edges = svg.split("class=\"relation\"").length() - 1
  @test.assert_eq(painted_edges, layout.edges.length())
  @test.assert_eq(svg.contains("class=\"relation-label\""), false)
}

///|
/// The class-member collapse machinery works on the mindmap layout too: the
/// member bodies wrap in a `<details>` disclosure (open by default in the
/// mbti family) and every edge emits open/closed endpoint states.
test "mindmap layout renders collapsible class nodes and edges" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let svg = parse(source).render_svg(class_member_collapsible=true) catch {
    _ => @test.fail("svg rendering failed")
  }
  @test.assert_eq(
    svg.contains("<details xmlns=\"http://www.w3.org/1999/xhtml\" open style"),
    true,
  )
  @test.assert_eq(svg.contains("edge-state"), true)
  @test.assert_eq(svg.contains("data-edge-index"), true)
}

///|
/// The package-root structure edge is collapsible too: it gets its own edge
/// group with open/closed states so it stays visible when a child node
/// collapses.
test "mindmap layout keeps the package-root edge collapsible" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let svg = parse(source).render_svg(class_member_collapsible=true) catch {
    _ => @test.fail("svg rendering failed")
  }
  @test.assert_eq(svg.contains("data-edge-index=\"-1\""), true)
  @test.assert_eq(
    svg.contains("g[data-edge-index=\"-1\"] > .edge-state-00"),
    true,
  )
  @test.assert_eq(
    svg.contains("g[data-edge-index=\"-1\"] > .edge-state-01"),
    true,
  )
}
