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
fn edge_for(layout : MindmapLayout, child_index : Int) -> EdgeLayout {
  for edge in layout.edges {
    if edge.child_index == child_index {
      return edge
    }
  }
  abort("missing mindmap edge")
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
test "layout connects a shared root directly to its reverse branch" {
  let diagram = parse("* Root\n++ Right\n-- Left")
  let layout = diagram.layout()
  let root = node_for(layout, 0)
  let left = node_for(layout, 2)
  let left_edge = edge_for(layout, 2)
  @test.assert_eq(left_edge.x1, root.x)
  @test.assert_eq(left_edge.x2, left.x + left.width)
}

///|
test "layout puts a reverse-only root on the reverse branch" {
  let diagram = parse("* Root\n-- Left")
  let layout = diagram.layout()
  let root = node_for(layout, 0)
  let left_edge = edge_for(layout, 1)
  @test.assert_eq(left_edge.x1, root.x)
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

///|
test "labels are left-aligned at the box padding" {
  let svg = parse("@startmindmap\n* Root\n** Child\n@endmindmap").render_svg()
  @test.assert_eq(svg.contains("text-anchor=\"start\""), true)
  @test.assert_eq(svg.contains("text-anchor=\"middle\""), false)
}

///|
test "strikethrough spans split into positioned text elements" {
  let svg = parse("@startmindmap\n* Root\n** <s>Old</s> New\n@endmindmap").render_svg()
  @test.assert_eq(svg.contains("text-decoration=\"line-through\""), true)
  let old_pos = svg.find(">Old<").unwrap_or(-1)
  let new_pos = svg.find(">New<").unwrap_or(-1)
  @test.assert_eq(old_pos > 0 && new_pos > old_pos, true)
}

///|
test "consecutive roots stack with a modest gap" {
  let diagram = parse("* First root\n** Deep child\n* Second root\n** Child")
  let layout = diagram.layout()
  let first = node_for(layout, 0)
  let second = node_for(layout, 3)
  @test.assert_eq(second.y > first.y + first.height, true)
  @test.assert_eq(second.y - (first.y + first.height) < first.height, true)
}

///|
test "width emulation leaves the rendered font size untouched" {
  let svg = parse(
    "@startmindmap\n* Root\n** Child with a long label here\n@endmindmap",
  ).render_svg()
  @test.assert_eq(svg.contains("font-size=\"14px\""), true)
  @test.assert_eq(svg.contains("font-size=\"15px\""), false)
}
