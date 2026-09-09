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
fn draw_structured_multiline_text(
  graphic : @graphics.Graphic,
  x : Int,
  y : Int,
  text : String,
  class? : String,
) -> Unit {
  let text_metrics = @metrics.FontMetrics::from_defaults(
    font_size=STRUCTURED_FONT_SIZE,
    line_height=STRUCTURED_LINE_HEIGHT,
  )
  graphic.draw(
    TextBlock(
      @svg.layout_multiline_text(
        x.to_double(),
        y.to_double(),
        text,
        line_height=STRUCTURED_LINE_HEIGHT.to_double(),
        anchor=Baseline,
        text_metrics=Some(text_metrics),
      ),
    ),
    metadata={ ..Default::default(), class_name: class, },
  )
}

///|
fn draw_structured_value_text(
  graphic : @graphics.Graphic,
  x : Int,
  y : Int,
  value : @structured.StructuredValueDisplay,
) -> Unit {
  match value {
    @structured.Text(text) =>
      draw_structured_multiline_text(graphic, x, y, text)
    _ => {
      let text = value.measurement_text()
      let measured = @metrics.FontMetrics::from_defaults(
        font_size=STRUCTURED_FONT_SIZE,
        line_height=STRUCTURED_LINE_HEIGHT,
      ).measure(text)
      graphic.draw(
        Text({
          text,
          position: { x: x.to_double(), y: y.to_double(), },
          advance: if text.length() > 1 && measured.advance_width > 0 {
            Some(measured.advance_width.to_double())
          } else {
            None
          },
          anchor: Start,
          font_size: STRUCTURED_FONT_SIZE.to_double(),
          font_family: None,
          strike: false,
        }),
      )
    }
  }
}

///|
fn is_blank_node(node : @structured.StructuredNode) -> Bool {
  match node.rows {
    [{ key: None, value: @structured.Text(text), child: None, }] =>
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
      { key_width, width: key_width + value_width, height, row_heights, }
    }
    Array => {
      value_width = value_width.max(STRUCTURED_COLUMN_MIN_WIDTH)
      { key_width: 0, width: value_width, height, row_heights, }
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
      { node: self, metrics, x, y: next_y, children, },
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
  ({ node: self, metrics, x, y, children, }, child_y.max(y + metrics.height))
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
  { node: node.node, metrics: node.metrics, x: node.x, y: node.y, children, }
}

///|
fn draw_structured_edges(
  graphic : @graphics.Graphic,
  node : PlacedNode,
) -> Unit {
  for pair in node.children {
    let (row_index, child) = pair
    let x1 = node.x + node.metrics.width - 12
    let y1 = node.y +
      node.metrics.row_offset(row_index) +
      node.metrics.row_heights[row_index] / 2
    let x2 = child.x
    let y2 = child.y + child.metrics.height / 2
    let arrow_base = x2 - 8
    let control_offset = 13
    let arrow_half_height = 3
    let arrow_notch = 2
    let point = (x : Int, y : Int) => @graphics.Point::{
      x: x.to_double(),
      y: y.to_double(),
    }
    graphic.draw(
      Path([
        MoveTo(point(x1, y1)),
        CubicTo(
          point(x1 + control_offset, y1),
          point(arrow_base - control_offset, y2),
          point(arrow_base, y2),
        ),
      ]),
      metadata={ ..Default::default(), class_name: Some("structured-edge"), },
    )
    graphic.draw(
      Path([
        MoveTo(point(arrow_base, y2 + arrow_half_height)),
        LineTo(point(arrow_base + arrow_notch, y2)),
        LineTo(point(arrow_base, y2 - arrow_half_height)),
        LineTo(point(x2, y2)),
        Close,
      ]),
      metadata={ ..Default::default(), class_name: Some("structured-arrow"), },
    )
    graphic.draw(Circle(center=point(x1, y1), radius=3), metadata={
      ..Default::default(),
      class_name: Some("structured-spot"),
    })
    draw_structured_edges(graphic, child)
  }
}

///|
fn draw_structured_node(graphic : @graphics.Graphic, node : PlacedNode) -> Unit {
  graphic.group(
    { ..Default::default(), class_name: Some("structured-node"), },
    graphic => {
      graphic.draw(
        Rectangle(
          origin={ x: node.x.to_double(), y: node.y.to_double(), },
          width=node.metrics.width.to_double(),
          height=node.metrics.height.to_double(),
          rx=Some(5),
          ry=Some(5),
        ),
      )
      guard !is_blank_node(node.node) else { return }
      for index, row in node.node.rows {
        let row_y = node.y + node.metrics.row_offset(index)
        let row_height = node.metrics.row_heights[index]
        if index > 0 {
          graphic.draw(
            Line({ x: node.x.to_double(), y: row_y.to_double(), }, {
              x: (node.x + node.metrics.width).to_double(),
              y: row_y.to_double(),
            }),
          )
        }
        if row.key is Some(key) {
          let divider = node.x + node.metrics.key_width
          draw_structured_multiline_text(
            graphic,
            node.x + STRUCTURED_CELL_PADDING,
            row_y + STRUCTURED_TEXT_BASELINE_OFFSET,
            key,
            class="structured-key",
          )
          graphic.draw(
            Line({ x: divider.to_double(), y: row_y.to_double(), }, {
              x: divider.to_double(),
              y: (row_y + row_height).to_double(),
            }),
          )
          draw_structured_value_text(
            graphic,
            divider + STRUCTURED_CELL_PADDING,
            row_y + STRUCTURED_TEXT_BASELINE_OFFSET,
            row.value,
          )
        } else {
          draw_structured_value_text(
            graphic,
            node.x + STRUCTURED_CELL_PADDING,
            row_y + STRUCTURED_TEXT_BASELINE_OFFSET,
            row.value,
          )
        }
      }
    },
  )
  guard !is_blank_node(node.node) else { return }
  for pair in node.children {
    let (_, child) = pair
    draw_structured_node(graphic, child)
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
  let document = @svg.SvgDocument::empty(
    width,
    height,
    diagram.format.aria_label(),
  )
  let defaults = color_scheme
  document.stylesheet(
    @svg.svg_style_rule(
      "sans-serif",
      "\{STRUCTURED_FONT_SIZE}px",
      defaults.canvas,
    ) +
    (
      $|.structured-node rect { fill: \{defaults.node}; stroke: \{defaults.text}; stroke-width: \{@svg.EMPHASIZED_STROKE_WIDTH} }
      $|.structured-node line { stroke: \{defaults.text}; stroke-width: 1 }
      $|.structured-node text { fill: \{defaults.text} }
      $|.structured-key { font-weight: \{STRUCTURED_KEY_FONT_WEIGHT} }
      $|.structured-edge { fill: none; stroke: \{defaults.text}; stroke-width: 1; stroke-dasharray: 3,3 }
      $|.structured-arrow, .structured-spot { fill: \{defaults.text}; stroke: \{defaults.text}; stroke-width: 1 }
    ),
  )
  let graphic = document.graphic()
  draw_structured_edges(graphic, root)
  draw_structured_node(graphic, root)
  document.to_string()
}

///|
/// Render a parsed structured-data diagram to SVG.
pub fn render_structured_svg(
  diagram : @structured.StructuredDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  diagram.render_svg(color_scheme~)
}
