///|
fn append_mindmap_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  label : String,
  line_height : Int,
  anchor : String,
  fill : String,
  font_size : Int,
) -> Unit {
  output <+
    "<text x=\"\{x}\" y=\"\{y}\" text-anchor=\"\{anchor}\" fill=\"\{fill}\" font-size=\"\{font_size}px\" class=\"mindmap-label\">"
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
fn append_mindmap_edge(
  output : StringBuilder,
  edge : EdgeLayout,
  line_color : String,
  line_thickness : Int,
) -> Unit {
  output <+
    "<path d=\"M\{edge.x1} \{edge.y1} C\{edge.control1_x} \{edge.control1_y} \{edge.control2_x} \{edge.control2_y} \{edge.x2} \{edge.y2}\" class=\"mindmap-link\" stroke=\"\{line_color}\" stroke-width=\"\{line_thickness}\"/>\n"
}

///|
fn append_mindmap_node(
  output : StringBuilder,
  diagram : MindmapDiagram,
  node : NodeLayout,
) -> Unit {
  let idea = diagram.ideas[node.idea_index]
  let node_style = diagram.node_style(node.idea_index)
  let font_size = node_style.font_size.unwrap_or(
    @core.font_size_value(diagram.style),
  )
  let font_metrics = diagram.style.font_metrics(font_size~)
  let text_metrics = diagram.node_text_metrics(node.idea_index)
  let padding_x = node_style.padding_x.unwrap_or(10)
  let (text_x, anchor) = match node_style.alignment.unwrap_or(Center) {
    Left => (node.x + padding_x, "start")
    Right => (node.x + node.width - padding_x, "end")
    Center => (node.x + node.width / 2, "middle")
  }
  let first_baseline = node.y +
    (node.height - text_metrics.height) / 2 +
    text_metrics.baseline
  let shape_class = match idea.shape {
    Box => "box"
    None => "boxless"
  }
  let fill = @core.svg_color(
    match idea.background_color {
      Some(color) => Some(color)
      None => node_style.background_color
    },
    "#FEFECE",
  )
  let line_color = @core.svg_color(node_style.line_color, "#181818")
  let font_color = @core.svg_color(node_style.font_color, "#181818")
  let line_thickness = node_style.line_thickness.unwrap_or(2)
  let round_corner = node_style.round_corner.unwrap_or(25)
  output <+
    "<g class=\"mindmap-node \{shape_class}\" data-idea-index=\"\{node.idea_index}\">\n"
  match idea.shape {
    Box =>
      output <+
        "<rect x=\"\{node.x}\" y=\"\{node.y}\" width=\"\{node.width}\" height=\"\{node.height}\" rx=\"\{round_corner}\" fill=\"\{fill}\" stroke=\"\{line_color}\" stroke-width=\"\{line_thickness}\"/>\n"
    None => ()
  }
  append_mindmap_text(
    output,
    text_x,
    first_baseline,
    idea.label,
    font_metrics.line_height,
    anchor,
    font_color,
    font_size,
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
  let arrow_color = @core.svg_color(
    match self.mindmap_style.arrow.line_color {
      Some(color) => Some(color)
      None => self.style.line_color
    },
    "#181818",
  )
  let arrow_thickness = self.mindmap_style.arrow.line_thickness.unwrap_or(1)
  output <+
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{layout.width}\" height=\"\{layout.height}\" viewBox=\"0 0 \{layout.width} \{layout.height}\" role=\"img\" aria-label=\"Mindmap\">\n"
  output <+
    "<style>svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}.mindmap-link{fill:none}.mindmap-node.boxless .mindmap-label{font-weight:normal}</style>\n"
  output <+
    "<rect x=\"0\" y=\"0\" width=\"\{layout.width}\" height=\"\{layout.height}\" fill=\"\{background}\"/>\n"
  layout.edges.each(edge => {
    append_mindmap_edge(output, edge, arrow_color, arrow_thickness)
  })
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
