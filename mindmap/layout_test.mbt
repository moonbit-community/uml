///|
fn node_for(layout : MindmapLayout, idea_index : Int) -> NodeLayout {
  for node in layout.nodes {
    if node.idea_index == idea_index {
      return node
    }
  }
  abort("missing mindmap node")
}

///|
fn rectangles_overlap(left : NodeLayout, right : NodeLayout) -> Bool {
  left.x < right.x + right.width &&
  right.x < left.x + left.width &&
  left.y < right.y + right.height &&
  right.y < left.y + left.height
}

///|
test "layout keeps reverse and regular branches on opposite sides" {
  let diagram = parse("* Root\n++ Right\n-- Left")
  let layout = diagram.layout()
  let root = node_for(layout, 0)
  let right = node_for(layout, 1)
  let left = node_for(layout, 2)
  @test.assert_eq(right.x >= root.x + root.width, true)
  @test.assert_eq(left.x + left.width <= root.x, true)
  @test.assert_eq(layout.edges.length(), 2)
}

///|
test "layout separates sibling subtrees without fixed coordinates" {
  let diagram = parse(
    "* Root\n** First\n*** First leaf\n** Second\n*** Second leaf",
  )
  let layout = diagram.layout()
  for left_index in 0..<layout.nodes.length() {
    for right_index in (left_index + 1)..<layout.nodes.length() {
      @test.assert_eq(
        rectangles_overlap(layout.nodes[left_index], layout.nodes[right_index]),
        false,
      )
    }
  }
  @test.assert_eq(layout.nodes.length(), diagram.ideas.length())
  @test.assert_eq(layout.width > 0 && layout.height > 0, true)
}

///|
test "layout keeps multiple roots and both branch directions disjoint" {
  let diagram = parse(
    "* First root\n++ Right branch\n-- Left branch\n* Second root\n** Child",
  )
  let layout = diagram.layout()
  @test.assert_eq(layout.nodes.length(), diagram.ideas.length())
  for left_index in 0..<layout.nodes.length() {
    for right_index in (left_index + 1)..<layout.nodes.length() {
      @test.assert_eq(
        rectangles_overlap(layout.nodes[left_index], layout.nodes[right_index]),
        false,
      )
    }
  }
  let first_root = node_for(layout, 0)
  let second_root = node_for(layout, 3)
  @test.assert_eq(first_root.y + first_root.height <= second_root.y, true)
}

///|
test "layout represents every parsed parent-child relation once" {
  let diagram = parse("* Root\n** One\n*** Leaf\n** Two")
  let layout = diagram.layout()
  let expected = diagram.ideas.filter(idea => idea.parent is Some(_)).length()
  @test.assert_eq(layout.edges.length(), expected)
  for edge in layout.edges {
    @test.assert_eq(
      diagram.ideas[edge.child_index].parent,
      Some(edge.parent_index),
    )
  }
}
