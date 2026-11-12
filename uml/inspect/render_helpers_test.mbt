///|
let text_measurer : @metrics.Measurer = @heuristic.measurer()

///|
let text_context : @style.RenderContext = @style.RenderContext::new(
  text_measurer,
)

///|
fn node_for(
  layout : @render.MindmapLayout,
  idea_index : Int32,
) -> @render.NodeLayout {
  for node in layout.nodes {
    guard node.index == idea_index else { continue }
    return node
  }
  abort("missing mindmap node")
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
