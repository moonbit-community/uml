///|
fn append_mindmap_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  label : String,
  line_height : Int,
) -> Unit {
  output <+
    "<text x=\"\{x}\" y=\"\{y}\" text-anchor=\"middle\" class=\"mindmap-label\">"
  label
  .split("\n")
  .eachi((index, line) => {
    let dy = if index == 0 { 0 } else { line_height }
    output <+
      "<tspan x=\"\{x}\" dy=\"\{dy}\">\{@core.xml_escape(line.to_owned())}</tspan>"
  })
  output.write_string("</text>\n")
}

///|
fn append_mindmap_edge(output : StringBuilder, edge : EdgeLayout) -> Unit {
  output <+
    "<path d=\"M\{edge.x1} \{edge.y1} C\{edge.control1_x} \{edge.control1_y} \{edge.control2_x} \{edge.control2_y} \{edge.x2} \{edge.y2}\" class=\"mindmap-link\"/>\n"
}

///|
fn append_mindmap_node(
  output : StringBuilder,
  diagram : MindmapDiagram,
  node : NodeLayout,
) -> Unit {
  let idea = diagram.ideas[node.idea_index]
  let font_metrics = diagram.style.font_metrics()
  let text_metrics = @metrics.measure_text_with(idea.label, font_metrics)
  let center_x = node.x + node.width / 2
  let first_baseline = node.y +
    (node.height - text_metrics.height) / 2 +
    text_metrics.baseline
  let shape_class = match idea.shape {
    Box => "box"
    None => "boxless"
  }
  let fill = @core.svg_color(idea.background_color, "#FEFECE")
  output <+
    "<g class=\"mindmap-node \{shape_class}\" data-idea-index=\"\{node.idea_index}\">\n"
  match idea.shape {
    Box =>
      output <+
        "<rect x=\"\{node.x}\" y=\"\{node.y}\" width=\"\{node.width}\" height=\"\{node.height}\" rx=\"4\" fill=\"\{fill}\"/>\n"
    None => ()
  }
  append_mindmap_text(
    output,
    center_x,
    first_baseline,
    idea.label,
    font_metrics.line_height,
  )
  output.write_string("</g>\n")
}

///|
/// Render a parsed mindmap as an SVG document.
pub fn MindmapDiagram::render_svg(self : MindmapDiagram) -> String {
  let layout = self.layout()
  let output = StringBuilder()
  let background = @core.svg_color(self.style.background_color, "#fff")
  let font_family = @core.font_family(self.style)
  let font_size = @core.font_size(self.style)
  let line_color = @core.svg_color(self.style.line_color, "#181818")
  output <+
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{layout.width}\" height=\"\{layout.height}\" viewBox=\"0 0 \{layout.width} \{layout.height}\" role=\"img\" aria-label=\"Mindmap\">\n"
  output <+
    "<style>svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}.mindmap-link{fill:none;stroke:\{line_color};stroke-width:1.3}.mindmap-node rect{stroke:#181818;stroke-width:1.1}.mindmap-label{fill:#181818}.mindmap-node.boxless .mindmap-label{font-weight:normal}</style>\n"
  output <+
    "<rect x=\"0\" y=\"0\" width=\"\{layout.width}\" height=\"\{layout.height}\" fill=\"\{background}\"/>\n"
  layout.edges.each(edge => append_mindmap_edge(output, edge))
  layout.nodes.each(node => append_mindmap_node(output, self, node))
  output.write_string("</svg>\n")
  output.to_string()
}

///|
pub fn render_svg(diagram : MindmapDiagram) -> String {
  diagram.render_svg()
}

///|
pub fn render_mindmap_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}
