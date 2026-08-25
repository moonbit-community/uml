///|
fn node_for(
  layout : @render.MindmapLayout,
  idea_index : Int,
) -> @render.NodeLayout {
  for node in layout.nodes {
    guard node.idea_index == idea_index else { continue }
    return node
  }
  abort("missing mindmap node")
}

///|
fn edge_for(
  layout : @render.MindmapLayout,
  child_index : Int,
) -> @render.EdgeLayout {
  for edge in layout.edges {
    guard edge.child_index == child_index else { continue }
    return edge
  }
  abort("missing mindmap edge")
}

///|
fn rectangles_overlap(
  left : @render.NodeLayout,
  right : @render.NodeLayout,
) -> Bool {
  left.x < right.x + right.width &&
  right.x < left.x + left.width &&
  left.y < right.y + right.height &&
  right.y < left.y + left.height
}

///|
fn expect_nodes_disjoint(layout : @render.MindmapLayout) -> Unit raise {
  for left_index in 0..<layout.nodes.length() {
    for right_index in (left_index + 1)..<layout.nodes.length() {
      @test.assert_eq(
        rectangles_overlap(layout.nodes[left_index], layout.nodes[right_index]),
        false,
      )
    }
  }
}

///|
test "layout keeps reverse and regular branches on opposite sides" {
  let diagram = @parser.parse_mindmap("* Root\n++ Right\n-- Left")
  let layout = @render.layout_mindmap(diagram)
  let root = node_for(layout, 0)
  let right = node_for(layout, 1)
  let left = node_for(layout, 2)
  @test.assert_eq(right.x >= root.x + root.width, true)
  @test.assert_eq(left.x + left.width <= root.x, true)
  @test.assert_eq(layout.edges.length(), 2)
}

///|
test "layout connects a shared root directly to its reverse branch" {
  let diagram = @parser.parse_mindmap("* Root\n++ Right\n-- Left")
  let layout = @render.layout_mindmap(diagram)
  let root = node_for(layout, 0)
  let left = node_for(layout, 2)
  let left_edge = edge_for(layout, 2)
  @test.assert_eq(left_edge.x1, root.x)
  @test.assert_eq(left_edge.x2, left.x + left.width)
}

///|
test "layout puts a reverse-only root on the reverse branch" {
  let diagram = @parser.parse_mindmap("* Root\n-- Left")
  let layout = @render.layout_mindmap(diagram)
  let root = node_for(layout, 0)
  let left_edge = edge_for(layout, 1)
  @test.assert_eq(left_edge.x1, root.x)
}

///|
test "layout separates sibling subtrees without fixed coordinates" {
  let diagram = @parser.parse_mindmap(
    "* Root\n** First\n*** First leaf\n** Second\n*** Second leaf",
  )
  let layout = @render.layout_mindmap(diagram)
  expect_nodes_disjoint(layout)
  @test.assert_eq(layout.nodes.length(), diagram.ideas.length())
  @test.assert_eq(layout.width > 0 && layout.height > 0, true)
}

///|
test "layout keeps multiple roots and both branch directions disjoint" {
  let diagram = @parser.parse_mindmap(
    "* First root\n++ Right branch\n-- Left branch\n* Second root\n** Child",
  )
  let layout = @render.layout_mindmap(diagram)
  expect_nodes_disjoint(layout)
  @test.assert_eq(layout.nodes.length(), diagram.ideas.length())
  let first_root = node_for(layout, 0)
  let second_root = node_for(layout, 3)
  @test.assert_eq(first_root.y + first_root.height <= second_root.y, true)
}

///|
test "layout represents every parsed parent-child relation once" {
  let diagram = @parser.parse_mindmap("* Root\n** One\n*** Leaf\n** Two")
  let layout = @render.layout_mindmap(diagram)
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
test "generic layout_tree packs explicit items without overlap" {
  let items : Array[@render.LayoutItem] = [
    {
      width: 60,
      height: 30,
      margin_left: 10,
      margin_right: 10,
      margin_top: 10,
      margin_bottom: 10,
      left_children: [],
      right_children: [1, 2],
    },
    {
      width: 40,
      height: 20,
      margin_left: 10,
      margin_right: 10,
      margin_top: 10,
      margin_bottom: 10,
      left_children: [],
      right_children: [3],
    },
    {
      width: 50,
      height: 25,
      margin_left: 10,
      margin_right: 10,
      margin_top: 10,
      margin_bottom: 10,
      left_children: [],
      right_children: [],
    },
    {
      width: 30,
      height: 15,
      margin_left: 10,
      margin_right: 10,
      margin_top: 10,
      margin_bottom: 10,
      left_children: [],
      right_children: [],
    },
  ]
  let layout = @render.layout_tree(items, [0])
  @test.assert_eq(layout.nodes.length(), items.length())
  @test.assert_eq(layout.edges.length(), 3)
  expect_nodes_disjoint(layout)
}

///|
test "labels are left-aligned at the box padding" {
  let svg = @render.render_mindmap_svg(
    @parser.parse_mindmap("@startmindmap\n* Root\n** Child\n@endmindmap"),
  )
  @test.assert_eq(svg.contains("text-anchor=\"start\""), true)
  @test.assert_eq(svg.contains("text-anchor=\"middle\""), false)
}

///|
test "strikethrough spans split into positioned text elements" {
  let svg = @render.render_mindmap_svg(
    @parser.parse_mindmap(
      "@startmindmap\n* Root\n** <s>Old</s> New\n@endmindmap",
    ),
  )
  @test.assert_eq(svg.contains("text-decoration=\"line-through\""), true)
  let old_pos = svg.find(">Old<").unwrap_or(-1)
  let new_pos = svg.find(">New<").unwrap_or(-1)
  @test.assert_eq(old_pos > 0 && new_pos > old_pos, true)
}

///|
test "consecutive roots stack with a modest gap" {
  let diagram = @parser.parse_mindmap(
    "* First root\n** Deep child\n* Second root\n** Child",
  )
  let layout = @render.layout_mindmap(diagram)
  let first = node_for(layout, 0)
  let second = node_for(layout, 3)
  @test.assert_eq(second.y > first.y + first.height, true)
  @test.assert_eq(second.y - (first.y + first.height) < first.height, true)
}

///|
test "width emulation leaves the rendered font size untouched" {
  let svg = @render.render_mindmap_svg(
    @parser.parse_mindmap(
      "@startmindmap\n* Root\n** Child with a long label here\n@endmindmap",
    ),
  )
  @test.assert_eq(svg.contains("font-size=\"14px\""), true)
  @test.assert_eq(svg.contains("font-size=\"15px\""), false)
}

///|
test "generic layout_tree keeps one edge per non-root node" {
  // 17 nodes: root 0 with children {1..15}, node 1 with child 16.
  // Mirrors the mbti 05-activity shape.
  let items : Array[@render.LayoutItem] = []
  items.push({
    width: 100,
    height: 30,
    margin_left: 10,
    margin_right: 10,
    margin_top: 10,
    margin_bottom: 10,
    left_children: [],
    right_children: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  })
  for _ in 0..<16 {
    items.push({
      width: 60,
      height: 30,
      margin_left: 10,
      margin_right: 10,
      margin_top: 10,
      margin_bottom: 10,
      left_children: [],
      right_children: [],
    })
  }
  items[1] = { ..items[1], right_children: [16], }
  let layout = @render.layout_tree(items, [0])
  @test.assert_eq(layout.edges.length(), items.length() - 1)
  // every non-root node appears as a child exactly once
  let child_seen : Array[Int] = Array::make(items.length(), 0)
  for edge in layout.edges {
    child_seen[edge.child_index] += 1
  }
  for index in 1..<items.length() {
    @test.assert_eq(child_seen[index], 1)
  }
}
