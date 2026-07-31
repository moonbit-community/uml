///|
fn append_mindmap_text(
  output : @core.XmlWriter,
  x : Int,
  y : Int,
  label : String,
  line_height : Int,
  anchor : String,
  fill : String,
  font_size : Int,
) -> Unit {
  output.open("text", attributes=[
    ("x", x.to_string()),
    ("y", y.to_string()),
    ("text-anchor", anchor),
    ("fill", fill),
    ("font-size", font_size.to_string() + "px"),
    ("class", "mindmap-label"),
  ])
  label
  .split("\n")
  .eachi((index, line) => {
    let dy = if index == 0 { 0 } else { line_height }
    output.open("tspan", attributes=[
      ("x", x.to_string()),
      ("dy", dy.to_string()),
    ])
    parse_mindmap_text_line(line.to_owned()).each(span => {
      let attributes = [
        ..if span.strike {
          [("text-decoration", "line-through")]
        },
      ]
      output.text("tspan", span.text, attributes~)
    })
    output.close()
  })
  output.close()
}

///|
fn append_mindmap_edge(
  output : @core.XmlWriter,
  edge : EdgeLayout,
  line_color : String,
  line_thickness : Int,
) -> Unit {
  let path =
    $|M\{edge.x1} \{edge.y1} C\{edge.control1_x} \{edge.control1_y} \{edge.control2_x} \{edge.control2_y} \{edge.x2} \{edge.y2}
  output.empty("path", attributes=[
    ("d", path),
    ("class", "mindmap-link"),
    ("stroke", line_color),
    ("stroke-width", line_thickness.to_string()),
  ])
}

///|
fn append_mindmap_node(
  output : @core.XmlWriter,
  diagram : MindmapDiagram,
  node : NodeLayout,
) -> Unit {
  let idea = diagram.ideas[node.idea_index]
  let font_size = diagram.node_font_size(node.idea_index)
  let font_metrics = diagram.style.font_metrics(font_size~)
  let node_style = diagram.node_style(node.idea_index)
  let padding_x = node_style.padding_x.unwrap_or(12)
  let padding_y = node_style.padding_y.unwrap_or(10)
  let (text_x, anchor) = match node_style.alignment.unwrap_or(Center) {
    Left => (node.x + padding_x, "start")
    Right => (node.x + node.width - padding_x, "end")
    Center => (node.x + node.width / 2, "middle")
  }
  let (text_x, anchor, first_baseline) = match idea.shape {
    Box =>
      // SVG positions text by its baseline. PlantUML's box renderer starts a
      // line after the top padding plus the font's baseline offset.
      (text_x, anchor, node.y + padding_y + font_size)
    None => {
      // Java adds the horizontal margin on the side away from the connector.
      // The connector itself meets the opposite edge of this virtual box.
      let text_x = match idea.direction {
        Right => node.x + boxless_horizontal_margin
        Left => node.x
      }
      (
        text_x,
        "start",
        node.y +
        boxless_vertical_margin +
        diagram.node_text_metrics(node.idea_index).baseline,
      )
    }
  }
  let shape_class = match idea.shape {
    Box => "box"
    None => "boxless"
  }
  let fill = @core.svg_color(
    match idea.background_color {
      Some(color) => Some(color)
      None => node_style.background_color
    },
    @core.render_defaults().node_background,
  )
  let line_color = @core.svg_color(
    node_style.line_color,
    @core.render_defaults().diagram_line,
  )
  let font_color = @core.svg_color(
    node_style.font_color,
    @core.render_defaults().diagram_text,
  )
  let line_thickness = match node_style.line_thickness {
    Some(value) => value.to_string()
    None => "1.5"
  }
  let round_corner = match node_style.round_corner {
    Some(value) => value.to_string()
    None => "12.5"
  }
  output.open("g", attributes=[
    ("class", "mindmap-node " + shape_class),
    ("data-idea-index", node.idea_index.to_string()),
  ])
  match idea.shape {
    Box =>
      output.empty("rect", attributes=[
        ("x", node.x.to_string()),
        ("y", node.y.to_string()),
        ("width", node.width.to_string()),
        ("height", node.height.to_string()),
        ("rx", round_corner),
        ("fill", fill),
        ("stroke", line_color),
        ("stroke-width", line_thickness),
      ])
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
  output.close()
}

///|
/// Render a parsed mindmap as an SVG document.
pub fn MindmapDiagram::render_svg(self : MindmapDiagram) -> String {
  let layout = self.layout()
  let output = @core.XmlWriter::new()
  let background = self.style.canvas_color()
  let font_family = @core.font_family(self.style)
  let font_size = @core.font_size(self.style)
  let arrow_color = @core.svg_color(
    match self.mindmap_style.arrow.line_color {
      Some(color) => Some(color)
      None => self.style.line_color
    },
    @core.render_defaults().diagram_line,
  )
  let arrow_thickness = self.mindmap_style.arrow.line_thickness.unwrap_or(1)
  output.open("svg", attributes=[
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", layout.width.to_string()),
    ("height", layout.height.to_string()),
    ("viewBox", "0 0 \{layout.width} \{layout.height}"),
    ("role", "img"),
    ("aria-label", "Mindmap"),
  ])
  output.open("style")
  output.raw(
    "svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}.mindmap-link{fill:none}.mindmap-node.boxless .mindmap-label{font-weight:normal}",
  )
  output.close()
  output.empty("rect", attributes=[
    ("x", "0"),
    ("y", "0"),
    ("width", layout.width.to_string()),
    ("height", layout.height.to_string()),
    ("fill", background),
  ])
  layout.edges.each(edge => {
    append_mindmap_edge(output, edge, arrow_color, arrow_thickness)
  })
  layout.nodes.each(node => append_mindmap_node(output, self, node))
  output.close()
  output.to_string()
}

///|
pub fn render_mindmap_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}
