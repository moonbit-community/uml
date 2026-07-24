///|
test "parses node, stereotype, and arrow style blocks" {
  let diagram = parse(
    "@startmindmap\n<style>\nNode {\n  MinimumWidth 100\n  SameClassWidth true\n  Padding 6\n  Margin 8\n  FontSize 17\n  BackgroundColor #aabbcc\n  LineColor #102030\n}\n.Test1 {\n  HorizontalAlignment Right\n  FontColor #ff0000\n}\narrow {\n  LineColor #00aa00\n  LineThickness 3\n}\n</style>\n* Root\n** Child <<Test1>>\n@endmindmap",
  )
  let root_style = diagram.node_style(0)
  let child_style = diagram.node_style(1)
  @test.assert_eq(root_style.minimum_width, Some(100))
  @test.assert_eq(root_style.padding_x, Some(6))
  @test.assert_eq(root_style.margin_right, Some(8))
  @test.assert_eq(root_style.same_class_width, Some(true))
  @test.assert_eq(child_style.alignment, Some(Right))
  @test.assert_eq(child_style.font_color, Some("#ff0000"))
  @test.assert_eq(diagram.mindmap_style.arrow.line_color, Some("#00aa00"))
  @test.assert_eq(diagram.mindmap_style.arrow.line_thickness, Some(3))
}

///|
test "skinparam node dimensions participate in layout" {
  let plain = parse("* Root\n** Child").layout()
  let styled = parse(
    "skinparam MindMapNodeMinimumWidth 140\nskinparam MindMapNodePadding 18\n* Root\n** Child",
  ).layout()
  let plain_root = node_for(plain, 0)
  let styled_root = node_for(styled, 0)
  @test.assert_eq(styled_root.width > plain_root.width, true)
  @test.assert_eq(styled_root.height > plain_root.height, true)
}

///|
test "same class width and margins affect layout without overlaps" {
  let diagram = parse(
    "<style>\nNode {\n  SameClassWidth true\n  Margin 30\n}\n</style>\n* Root\n** short\n** a considerably longer sibling",
  )
  let layout = diagram.layout()
  let short = node_for(layout, 1)
  let long = node_for(layout, 2)
  @test.assert_eq(short.width, long.width)
  @test.assert_eq(rectangles_overlap(short, long), false)
}

///|
test "style box shorthand keeps horizontal and vertical layout values" {
  let diagram = parse(
    "<style>\nNode {\n  Padding 5 13\n  Margin 7 11 17 19\n}\n</style>\n* Root",
  )
  let node_style = diagram.node_style(0)
  @test.assert_eq(node_style.padding_x, Some(13))
  @test.assert_eq(node_style.padding_y, Some(5))
  @test.assert_eq(node_style.margin_top, Some(7))
  @test.assert_eq(node_style.margin_right, Some(11))
  @test.assert_eq(node_style.margin_bottom, Some(17))
  @test.assert_eq(node_style.margin_left, Some(19))
}

///|
test "root and leaf selectors layer over the node rule" {
  let diagram = parse(
    "<style>\nNode {\n MinimumWidth 80\n}\nrootNode {\n MinimumWidth 120\n}\nleafNode {\n Padding 4\n}\n</style>\n* Root\n** Leaf",
  )
  let root_style = diagram.node_style(0)
  let leaf_style = diagram.node_style(1)
  @test.assert_eq(root_style.minimum_width, Some(120))
  @test.assert_eq(leaf_style.minimum_width, Some(80))
  @test.assert_eq(leaf_style.padding_x, Some(4))
}
