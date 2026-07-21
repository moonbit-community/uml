///|
priv struct NodeMetrics {
  key_width : Int
  width : Int
  height : Int
}

///|
priv struct PlacedNode {
  node : JsonNode
  metrics : NodeMetrics
  x : Int
  y : Int
  children : Array[(Int, PlacedNode)]
}

///|
fn json_font_size() -> Int {
  14
}

///|
fn json_key_font_weight() -> Int {
  700
}

///|
fn display_text(value : JsonValueDisplay) -> String {
  match value {
    Text(text) => text
    True => "[x] true"
    False => "[ ] false"
    Null => "[]"
    Compound => "   "
  }
}

///|
fn display_svg(value : JsonValueDisplay) -> String {
  match value {
    Text(text) => @core.xml_escape(text)
    True => "&#9745; true"
    False => "&#9744; false"
    Null => "&#9216;"
    Compound => "&#160;&#160;&#160;"
  }
}

///|
fn is_blank_node(node : JsonNode) -> Bool {
  match node.rows {
    [{ key: None, value: Text(text), child: None }] => text.is_empty()
    _ => false
  }
}

///|
fn node_metrics(node : JsonNode) -> NodeMetrics {
  let regular_metrics = @core.FontMetrics::from_defaults(
    font_size=json_font_size(),
    line_height=21,
  )
  let key_metrics = @core.FontMetrics::from_defaults(
    font_size=json_font_size(),
    font_weight=json_key_font_weight(),
    line_height=21,
  )
  let mut key_width = 0
  let mut value_width = 0
  for row in node.rows {
    match row.key {
      Some(key) =>
        key_width = key_width.max(
          @core.measure_text_with(key, key_metrics).width + 10,
        )
      None => ()
    }
    value_width = value_width.max(
      @core.measure_text_with(display_text(row.value), regular_metrics).width +
      10,
    )
  }
  let height = if is_blank_node(node) {
    15
  } else {
    node.rows.length().max(1) * 21
  }
  match node.kind {
    Object => {
      key_width = key_width.max(30)
      value_width = value_width.max(30)
      { key_width, width: key_width + value_width, height }
    }
    Array => {
      value_width = value_width.max(30)
      { key_width: 0, width: value_width, height }
    }
  }
}

///|
fn layout_node(node : JsonNode, x : Int, next_y : Int) -> (PlacedNode, Int) {
  let metrics = node_metrics(node)
  let children = []
  let mut child_y = next_y
  for index, row in node.rows {
    match row.child {
      Some(child) => {
        let (placed, following_y) = layout_node(
          child,
          x + metrics.width + 38,
          child_y,
        )
        children.push((index, placed))
        child_y = following_y + 8
      }
      None => ()
    }
  }
  if children.is_empty() {
    return ({ node, metrics, x, y: next_y, children }, next_y + metrics.height)
  }
  let first = children[0].1
  let last = children[children.length() - 1].1
  let y = (
      first.y + first.metrics.height / 2 + (last.y + last.metrics.height / 2)
    ) /
    2 -
    metrics.height / 2
  ({ node, metrics, x, y, children }, child_y.max(y + metrics.height))
}

///|
fn max_right(node : PlacedNode) -> Int {
  let mut right = node.x + node.metrics.width
  for pair in node.children {
    let (_, child) = pair
    right = right.max(max_right(child))
  }
  right
}

///|
fn max_bottom(node : PlacedNode) -> Int {
  let mut bottom = node.y + node.metrics.height
  for pair in node.children {
    let (_, child) = pair
    bottom = bottom.max(max_bottom(child))
  }
  bottom
}

///|
fn min_top(node : PlacedNode) -> Int {
  let mut top = node.y
  for pair in node.children {
    let (_, child) = pair
    top = top.min(min_top(child))
  }
  top
}

///|
fn shift_node(node : PlacedNode, delta : Int) -> PlacedNode {
  let children = []
  for pair in node.children {
    let (row, child) = pair
    children.push((row, shift_node(child, delta)))
  }
  {
    node: node.node,
    metrics: node.metrics,
    x: node.x,
    y: node.y + delta,
    children,
  }
}

///|
fn is_empty_record(node : PlacedNode) -> Bool {
  is_blank_node(node.node)
}

///|
fn align_empty_records(node : PlacedNode) -> PlacedNode {
  let children = []
  for pair in node.children {
    let (row, original_child) = pair
    let child = align_empty_records(original_child)
    let child = if is_empty_record(child) {
      let port_y = node.y + row * 21 + 10
      shift_node(child, port_y - (child.y + child.metrics.height / 2))
    } else {
      child
    }
    children.push((row, child))
  }
  { node: node.node, metrics: node.metrics, x: node.x, y: node.y, children }
}

///|
fn append_edges(output : StringBuilder, node : PlacedNode) -> Unit {
  for pair in node.children {
    let (row_index, child) = pair
    let x1 = node.x + node.metrics.width - 12
    let y1 = node.y + row_index * 21 + 10
    let x2 = child.x
    let y2 = child.y + child.metrics.height / 2
    let arrow_base = x2 - 8
    let control_right = arrow_base - 13
    let arrow_half_height = 3
    let arrow_notch = 2
    output.write_string("<path class=\"json-edge\"\n")
    output <+
      "  d=\"M \{x1} \{y1} C \{x1 + 13} \{y1}, \{control_right} \{y2}, \{arrow_base} \{y2}\"/>\n"
    output.write_string("<path class=\"json-arrow\"\n")
    output <+
      "  d=\"M \{arrow_base} \{y2 + arrow_half_height} L \{arrow_base + arrow_notch} \{y2} L \{arrow_base} \{y2 - arrow_half_height} L \{x2} \{y2} z\"/>\n"
    output <+
      "<circle class=\"json-spot\" cx=\"\{x1}\" cy=\"\{y1}\" r=\"3\"/>\n"
    append_edges(output, child)
  }
}

///|
fn append_node(output : StringBuilder, node : PlacedNode) -> Unit {
  output.write_string("<g class=\"json-node\">\n<rect\n")
  output <+
    "  x=\"\{node.x}\" y=\"\{node.y}\" width=\"\{node.metrics.width}\"\n"
  output <+ "  height=\"\{node.metrics.height}\" rx=\"5\" ry=\"5\"/>\n"
  guard !is_blank_node(node.node) else {
    output.write_string("</g>\n")
    return
  }
  for index, row in node.node.rows {
    let row_y = node.y + index * 21
    if index > 0 {
      output.write_string("<line\n")
      output <+ "  x1=\"\{node.x}\" y1=\"\{row_y}\"\n"
      output <+ "  x2=\"\{node.x + node.metrics.width}\" y2=\"\{row_y}\"/>\n"
    }
    match row.key {
      Some(key) => {
        let divider = node.x + node.metrics.key_width
        output <+
          "<text class=\"json-key\" x=\"\{node.x + 5}\" y=\"\{row_y + 16}\">\{@core.xml_escape(key)}</text>\n"
        output <+
          "<line x1=\"\{divider}\" y1=\"\{row_y}\" x2=\"\{divider}\" y2=\"\{row_y + 21}\"/>\n"
        output <+
          "<text x=\"\{divider + 5}\" y=\"\{row_y + 16}\">\{display_svg(row.value)}</text>\n"
      }
      None =>
        output <+
          "<text x=\"\{node.x + 5}\" y=\"\{row_y + 16}\">\{display_svg(row.value)}</text>\n"
    }
  }
  output.write_string("</g>\n")
  for pair in node.children {
    let (_, child) = pair
    append_node(output, child)
  }
}

///|
pub fn JsonDiagram::render_svg(self : JsonDiagram) -> String {
  let (initial_root, _) = layout_node(self.root, 10, 10)
  let shifted_root = shift_node(
    initial_root,
    (10 - min_top(initial_root)).max(0),
  )
  let root = align_empty_records(shifted_root)
  let width = max_right(root) + 10
  let height = max_bottom(root) + 10
  let output = StringBuilder()
  output.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\"\n")
  output <+
    "  width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\"\n"
  output.write_string("  role=\"img\" aria-label=\"JSON diagram\">\n")
  let font_size = json_font_size()
  let key_font_weight = json_key_font_weight()
  output.write_string("<style>\n")
  output <+
    "svg { font-family: sans-serif; font-size: \{font_size}px; background: #fff }\n"
  output.write_string(
    (
      #|.json-node rect { fill: #F1F1F1; stroke: #000; stroke-width: 1.5 }
      #|.json-node line { stroke: #000; stroke-width: 1 }
      #|.json-node text { fill: #000 }
    ),
  )
  output.write_char('\n')
  output <+ ".json-key { font-weight: \{key_font_weight} }\n"
  output.write_string(
    (
      #|.json-edge { fill: none; stroke: #000; stroke-width: 1; stroke-dasharray: 3,3 }
      #|.json-arrow, .json-spot { fill: #000; stroke: #000; stroke-width: 1 }
      #|</style>
    ),
  )
  output.write_char('\n')
  append_edges(output, root)
  append_node(output, root)
  output.write_string("</svg>\n")
  output.to_string()
}

///|
pub fn render_json_svg(diagram : JsonDiagram) -> String {
  diagram.render_svg()
}
