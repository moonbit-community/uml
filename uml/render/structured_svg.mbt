///|
priv struct NodeMetrics {
  key_width : Int
  width : Int
  height : Int
  row_heights : Array[Int]
}

///|
priv struct PlacedNode {
  node : @structured.StructuredNode
  metrics : NodeMetrics
  x : Int
  y : Int
  children : Array[(Int, PlacedNode)]
}

///|
const STRUCTURED_FONT_SIZE : Int = 14

///|
const STRUCTURED_KEY_FONT_WEIGHT : Int = 700

///|
const STRUCTURED_LINE_HEIGHT : Int = 21

///|
const STRUCTURED_CELL_PADDING : Int = 5

///|
const STRUCTURED_TEXT_BASELINE_OFFSET : Int = 16

///|
const STRUCTURED_COLUMN_MIN_WIDTH : Int = 30

///|
const STRUCTURED_NODE_GAP : Int = 38

///|
const STRUCTURED_SIBLING_GAP : Int = 8

///|
const STRUCTURED_CANVAS_PADDING : Int = 10

///|
fn @structured.StructuredValueDisplay::measurement_text(
  self : @structured.StructuredValueDisplay,
) -> String {
  match self {
    @structured.Text(text) => text
    @structured.True => "\u{2611} true"
    @structured.False => "\u{2610} false"
    @structured.Null => "\u{2400}"
    @structured.Compound => "\u{a0}\u{a0}\u{a0}"
  }
}

///|
fn NodeMetrics::row_offset(self : NodeMetrics, index : Int) -> Int {
  let mut offset = 0
  for row_index in 0..<index {
    offset += self.row_heights[row_index]
  }
  offset
}

///|
fn append_multiline_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  text : String,
  class? : String,
) -> Unit {
  let text_metrics = @metrics.FontMetrics::from_defaults(
    font_size=STRUCTURED_FONT_SIZE,
    line_height=STRUCTURED_LINE_HEIGHT,
  )
  let attributes = class.map_or([], class => [("class", class)])
  output.write_string(
    @svg.multiline_text_markup(
      x.to_double(),
      y.to_double(),
      text,
      attributes,
      line_height=STRUCTURED_LINE_HEIGHT.to_double(),
      anchor=Baseline,
      text_metrics=Some(text_metrics),
    ),
  )
  output.write_string("\n")
}

///|
fn append_value_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  value : @structured.StructuredValueDisplay,
) -> Unit {
  match value {
    @structured.Text(text) => append_multiline_text(output, x, y, text)
    _ => {
      let markup = @svg.text_markup(
        x.to_double(),
        y.to_double(),
        value.measurement_text(),
        [],
        @metrics.FontMetrics::from_defaults(
          font_size=STRUCTURED_FONT_SIZE,
          line_height=STRUCTURED_LINE_HEIGHT,
        ),
      )
      output.write_string(markup)
      output.write_string("\n")
    }
  }
}

///|
fn is_blank_node(node : @structured.StructuredNode) -> Bool {
  match node.rows {
    [{ key: None, value: @structured.Text(text), child: None }] =>
      text.is_empty()
    _ => false
  }
}

///|
fn @structured.StructuredNode::metrics(
  self : @structured.StructuredNode,
) -> NodeMetrics {
  let regular_metrics = @metrics.FontMetrics::from_defaults(
    font_size=STRUCTURED_FONT_SIZE,
    line_height=STRUCTURED_LINE_HEIGHT,
  )
  let key_metrics = @metrics.FontMetrics::from_defaults(
    font_size=STRUCTURED_FONT_SIZE,
    font_weight=STRUCTURED_KEY_FONT_WEIGHT,
    line_height=STRUCTURED_LINE_HEIGHT,
  )
  let mut key_width = 0
  let mut value_width = 0
  let row_heights = []
  for row in self.rows {
    let key_height = match row.key {
      Some(key) => {
        let key_measurement = key_metrics.measure(key)
        key_width = key_width.max(
          key_measurement.width + STRUCTURED_CELL_PADDING * 2,
        )
        key_measurement.height
      }
      None => 0
    }
    let value_metrics = regular_metrics.measure(row.value.measurement_text())
    value_width = value_width.max(
      value_metrics.width + STRUCTURED_CELL_PADDING * 2,
    )
    row_heights.push(
      key_height.max(value_metrics.height).max(STRUCTURED_LINE_HEIGHT),
    )
  }
  let height = if is_blank_node(self) {
    15
  } else {
    row_heights.fold(init=0, (total, row_height) => total + row_height)
  }
  match self.kind {
    Object => {
      key_width = key_width.max(STRUCTURED_COLUMN_MIN_WIDTH)
      value_width = value_width.max(STRUCTURED_COLUMN_MIN_WIDTH)
      { key_width, width: key_width + value_width, height, row_heights }
    }
    Array => {
      value_width = value_width.max(STRUCTURED_COLUMN_MIN_WIDTH)
      { key_width: 0, width: value_width, height, row_heights }
    }
  }
}

///|
fn @structured.StructuredNode::place(
  self : @structured.StructuredNode,
  x : Int,
  next_y : Int,
) -> (PlacedNode, Int) {
  let metrics = self.metrics()
  let children = []
  let mut child_y = next_y
  for index, row in self.rows {
    guard row.child is Some(child) else { continue }
    let (placed, following_y) = child.place(
      x + metrics.width + STRUCTURED_NODE_GAP,
      child_y,
    )
    children.push((index, placed))
    child_y = following_y + STRUCTURED_SIBLING_GAP
  }
  if children.is_empty() {
    return (
      { node: self, metrics, x, y: next_y, children },
      next_y + metrics.height,
    )
  }
  let first = children[0].1
  let last = children[children.length() - 1].1
  let y = (
      first.y + first.metrics.height / 2 + (last.y + last.metrics.height / 2)
    ) /
    2 -
    metrics.height / 2
  ({ node: self, metrics, x, y, children }, child_y.max(y + metrics.height))
}

///|
fn PlacedNode::max_right(self : PlacedNode) -> Int {
  self.children.fold(init=self.x + self.metrics.width, (right, pair) => {
    right.max(pair.1.max_right())
  })
}

///|
fn PlacedNode::max_bottom(self : PlacedNode) -> Int {
  self.children.fold(init=self.y + self.metrics.height, (bottom, pair) => {
    bottom.max(pair.1.max_bottom())
  })
}

///|
fn PlacedNode::min_top(self : PlacedNode) -> Int {
  self.children.fold(init=self.y, (top, pair) => top.min(pair.1.min_top()))
}

///|
fn PlacedNode::shifted(self : PlacedNode, delta : Int) -> PlacedNode {
  let children = self.children.map(pair => (pair.0, pair.1.shifted(delta)))
  {
    node: self.node,
    metrics: self.metrics,
    x: self.x,
    y: self.y + delta,
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
      let port_y = node.y +
        node.metrics.row_offset(row) +
        node.metrics.row_heights[row] / 2
      child.shifted(port_y - (child.y + child.metrics.height / 2))
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
    let y1 = node.y +
      node.metrics.row_offset(row_index) +
      node.metrics.row_heights[row_index] / 2
    let x2 = child.x
    let y2 = child.y + child.metrics.height / 2
    let arrow_base = x2 - 8
    let control_right = arrow_base - 13
    let arrow_half_height = 3
    let arrow_notch = 2
    output.write_string("<path class=\"structured-edge\"\n")
    output <+
      "  d=\"M \{x1} \{y1} C \{x1 + 13} \{y1}, \{control_right} \{y2}, \{arrow_base} \{y2}\"/>\n"
    output.write_string("<path class=\"structured-arrow\"\n")
    output <+
      "  d=\"M \{arrow_base} \{y2 + arrow_half_height} L \{arrow_base + arrow_notch} \{y2} L \{arrow_base} \{y2 - arrow_half_height} L \{x2} \{y2} z\"/>\n"
    output <+
      "<circle class=\"structured-spot\" cx=\"\{x1}\" cy=\"\{y1}\" r=\"3\"/>\n"
    append_edges(output, child)
  }
}

///|
fn structured_append_node(output : StringBuilder, node : PlacedNode) -> Unit {
  output.write_string("<g class=\"structured-node\">\n<rect\n")
  output <+
    "  x=\"\{node.x}\" y=\"\{node.y}\" width=\"\{node.metrics.width}\"\n"
  output <+ "  height=\"\{node.metrics.height}\" rx=\"5\" ry=\"5\"/>\n"
  guard !is_blank_node(node.node) else {
    output.write_string("</g>\n")
    return
  }
  for index, row in node.node.rows {
    let row_y = node.y + node.metrics.row_offset(index)
    let row_height = node.metrics.row_heights[index]
    if index > 0 {
      output.write_string("<line\n")
      output <+ "  x1=\"\{node.x}\" y1=\"\{row_y}\"\n"
      output <+ "  x2=\"\{node.x + node.metrics.width}\" y2=\"\{row_y}\"/>\n"
    }
    match row.key {
      Some(key) => {
        let divider = node.x + node.metrics.key_width
        append_multiline_text(
          output,
          node.x + STRUCTURED_CELL_PADDING,
          row_y + STRUCTURED_TEXT_BASELINE_OFFSET,
          key,
          class="structured-key",
        )
        output <+
          "<line x1=\"\{divider}\" y1=\"\{row_y}\" x2=\"\{divider}\" y2=\"\{row_y + row_height}\"/>\n"
        append_value_text(
          output,
          divider + STRUCTURED_CELL_PADDING,
          row_y + STRUCTURED_TEXT_BASELINE_OFFSET,
          row.value,
        )
      }
      None =>
        append_value_text(
          output,
          node.x + STRUCTURED_CELL_PADDING,
          row_y + STRUCTURED_TEXT_BASELINE_OFFSET,
          row.value,
        )
    }
  }
  output.write_string("</g>\n")
  for pair in node.children {
    let (_, child) = pair
    structured_append_node(output, child)
  }
}

///|
fn @structured.StructuredDiagram::render_svg(
  diagram : @structured.StructuredDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let (initial_root, _) = diagram.root.place(
    STRUCTURED_CANVAS_PADDING,
    STRUCTURED_CANVAS_PADDING,
  )
  let shifted_root = initial_root.shifted(
    (STRUCTURED_CANVAS_PADDING - initial_root.min_top()).max(0),
  )
  let root = align_empty_records(shifted_root)
  let width = root.max_right() + STRUCTURED_CANVAS_PADDING
  let height = root.max_bottom() + STRUCTURED_CANVAS_PADDING
  let output = StringBuilder()
  output.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\"\n")
  output <+
    "  width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\"\n"
  output <+ "  role=\"img\" aria-label=\"\{diagram.format.aria_label()}\">\n"
  let defaults = color_scheme
  output.write_string("<style>\n")
  output <+
    "svg { font-family: sans-serif; font-size: \{STRUCTURED_FONT_SIZE}px; background: \{defaults.canvas} }\n"
  output.write_string(
    (
      $|.structured-node rect { fill: \{defaults.node}; stroke: \{defaults.text}; stroke-width: 1.5 }
      $|.structured-node line { stroke: \{defaults.text}; stroke-width: 1 }
      $|.structured-node text { fill: \{defaults.text} }
    ),
  )
  output.write_char('\n')
  output <+ ".structured-key { font-weight: \{STRUCTURED_KEY_FONT_WEIGHT} }\n"
  output.write_string(
    (
      $|.structured-edge { fill: none; stroke: \{defaults.text}; stroke-width: 1; stroke-dasharray: 3,3 }
      $|.structured-arrow, .structured-spot { fill: \{defaults.text}; stroke: \{defaults.text}; stroke-width: 1 }
      $|</style>
    ),
  )
  output.write_char('\n')
  append_edges(output, root)
  structured_append_node(output, root)
  output.write_string("</svg>\n")
  output.to_string()
}

///|
/// Render a parsed structured-data diagram to SVG.
pub fn render_structured_svg(
  diagram : @structured.StructuredDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  diagram.render_svg(color_scheme~)
}
