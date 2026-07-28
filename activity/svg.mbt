///|
fn layout_for(layout : ActivityLayout, node_index : Int) -> ActivityNodeLayout? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some(node)
  }
  None
}

///|
fn append_label(
  output : @core.XmlWriter,
  x : Int,
  y : Int,
  label : String,
  font_metrics : @metrics.FontMetrics,
) -> Unit {
  let lines = label.split("\n").map(StringView::to_owned).to_array()
  let first_baseline = y - (lines.length() - 1) * font_metrics.line_height / 2
  output.open("text", attributes=[
    ("x", x.to_string()),
    ("y", first_baseline.to_string()),
    ("text-anchor", "middle"),
    ("class", "activity-label"),
  ])
  for index, line in lines {
    output.text("tspan", line, attributes=[
      ("x", x.to_string()),
      (
        "dy",
        if index == 0 {
          "0"
        } else {
          font_metrics.line_height.to_string()
        },
      ),
    ])
  }
  output.close()
}

///|
fn append_edge(
  output : @core.XmlWriter,
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
) -> Unit {
  guard layout_for(layout, edge.from_node_index) is Some(from) else { return }
  guard layout_for(layout, edge.to_node_index) is Some(to) else { return }
  let x = from.x + from.width / 2
  let y1 = from.y + from.height
  let y2 = to.y
  output.empty("path", attributes=[
    ("d", "M \{x} \{y1} L \{x} \{y2}"),
    ("class", "activity-edge"),
    ("marker-end", "url(#activity-arrow)"),
  ])
}

///|
fn append_node(
  output : @core.XmlWriter,
  diagram : ActivityDiagram,
  node_layout : ActivityNodeLayout,
  font_metrics : @metrics.FontMetrics,
) -> Unit {
  let node = diagram.nodes[node_layout.node_index]
  let x = node_layout.x
  let y = node_layout.y
  let width = node_layout.width
  let height = node_layout.height
  let center_x = x + width / 2
  let center_y = y + height / 2
  output.open("g", attributes=[
    ("class", "activity-node"),
    ("data-node-index", node_layout.node_index.to_string()),
  ])
  match node {
    Start =>
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (height / 2).to_string()),
        ("class", "activity-start"),
      ])
    Stop | End | Kill => {
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (height / 2).to_string()),
        ("class", "activity-stop-outer"),
      ])
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (height / 2 - 4).to_string()),
        ("class", "activity-stop-inner"),
      ])
    }
    _ if is_fork(node) =>
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("class", "activity-fork"),
      ])
    _ if is_decision(node) => {
      output.empty("path", attributes=[
        (
          "d",
          "M \{center_x} \{y} L \{x + width} \{center_y} L \{center_x} \{y + height} L \{x} \{center_y} Z",
        ),
        ("class", "activity-decision"),
      ])
      match node_label(node) {
        Some(label) =>
          append_label(output, center_x, center_y + 4, label, font_metrics)
        None => ()
      }
    }
    Note(label) => {
      output.empty("path", attributes=[
        (
          "d",
          "M \{x} \{y} H \{x + width - 12} L \{x + width} \{y + 12} V \{y + height} H \{x} Z",
        ),
        ("class", "activity-note"),
      ])
      append_label(output, center_x, center_y + 4, label, font_metrics)
    }
    Action(label) => {
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("rx", "10"),
        ("class", "activity-action"),
      ])
      append_label(output, center_x, center_y + 4, label, font_metrics)
    }
    _ =>
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", "4"),
        ("class", "activity-merge"),
      ])
  }
  output.close()
}

///|
/// Render a parsed activity diagram with the built-in, non-Graphviz layout.
pub fn ActivityDiagram::render_svg(self : ActivityDiagram) -> String {
  let layout = self.layout()
  let output = @core.XmlWriter::new()
  let font_metrics = @metrics.FontMetrics::from_defaults()
  output.open("svg", attributes=[
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", layout.width.to_string()),
    ("height", layout.height.to_string()),
    ("viewBox", "0 0 \{layout.width} \{layout.height}"),
    ("role", "img"),
    ("aria-label", "Activity diagram"),
  ])
  output.open("style")
  output.raw(
    "svg{font-family:Arial,sans-serif;font-size:13px;background:#fff}.activity-edge{fill:none;stroke:#181818;stroke-width:1.5}.activity-label{fill:#181818}.activity-start,.activity-stop-inner,.activity-fork,.activity-merge{fill:#181818}.activity-stop-outer,.activity-action,.activity-decision{fill:#FEFECE;stroke:#181818;stroke-width:1.5}.activity-note{fill:#FEFFDD;stroke:#181818;stroke-width:1.5}",
  )
  output.close()
  output.open("defs")
  output.open("marker", attributes=[
    ("id", "activity-arrow"),
    ("markerWidth", "8"),
    ("markerHeight", "8"),
    ("refX", "6"),
    ("refY", "3"),
    ("orient", "auto"),
    ("markerUnits", "strokeWidth"),
  ])
  output.empty("path", attributes=[
    ("d", "M 0 0 L 6 3 L 0 6 Z"),
    ("fill", "#181818"),
  ])
  output.close()
  output.close()
  layout.edges.each(edge => append_edge(output, layout, edge))
  layout.nodes.each(node => append_node(output, self, node, font_metrics))
  output.close()
  output.to_string()
}
