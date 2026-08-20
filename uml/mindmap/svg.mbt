///|
/// Render one line of a mindmap label. PlantUML emits one `<text>` element
/// per markup span, positioned at the cumulative advance; the whitespace
/// between spans is measured but not drawn. The first line of a multi-line
/// label carries an extra leading space (visible in the reference SVGs).
fn append_mindmap_text(
  output : @svg.XmlWriter,
  x : Int,
  y : Int,
  label : String,
  line_height : Int,
  anchor : String,
  fill : String,
  font_size : Int,
  text_metrics : @metrics.FontMetrics,
) -> Unit {
  let lines = label.split("\n").to_array()
  let space = mindmap_space_advance(font_size)
  let first_line_extra = if lines.length() > 1 { space } else { 0 }
  lines.eachi((line_index, line) => {
    let spans = parse_mindmap_text_line(line.to_owned())
    let mut cursor_x = x + (if line_index == 0 { first_line_extra } else { 0 })
    let mut pending_ws = 0
    for span_index, span in spans {
      let (text, leading, trailing) = split_whitespace(span.text)
      if span_index > 0 {
        cursor_x += pending_ws +
          mindmap_measure(text_metrics, leading).advance_width
      }
      if !text.is_empty() {
        let measured = mindmap_measure(text_metrics, text)
        let attributes = [
          ("x", cursor_x.to_string()),
          ("y", (y + line_index * line_height).to_string()),
          ("text-anchor", anchor),
          ("fill", fill),
          ("font-size", font_size.to_string() + "px"),
          ("class", "mindmap-label"),
          ..if measured.advance_width > 0 {
            [
              ("textLength", measured.advance_width.to_string()),
              ("lengthAdjust", "spacing"),
            ]
          },
          ..if span.strike {
            [("text-decoration", "line-through")]
          },
        ]
        output.text("text", text, attributes~)
        cursor_x += measured.advance_width
      }
      pending_ws = mindmap_measure(text_metrics, trailing).advance_width
    }
  })
}

///|
fn split_whitespace(value : String) -> (String, String, String) {
  let length = value.length()
  let mut start = 0
  while start < length && value[start] == ' ' {
    start = start + 1
  }
  let mut end = length
  while end > start && value[end - 1] == ' ' {
    end = end - 1
  }
  (
    value[start:end].to_owned(),
    value[:start].to_owned(),
    value[end:].to_owned(),
  )
}

///|
fn append_mindmap_edge(
  output : @svg.XmlWriter,
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
  output : @svg.XmlWriter,
  diagram : MindmapDiagram,
  node : NodeLayout,
) -> Unit {
  let idea = diagram.ideas[node.idea_index]
  let font_size = diagram.node_font_size(node.idea_index)
  let font_metrics = diagram.style.font_metrics(font_size~)
  let node_style = diagram.node_style(node.idea_index)
  let padding_x = node_style.padding_x.unwrap_or(MINDMAP_DEFAULT_PADDING_X)
  let padding_y = node_style.padding_y.unwrap_or(MINDMAP_DEFAULT_PADDING_Y)
  let (text_x, anchor) = match node_style.alignment.unwrap_or(Left) {
    // PlantUML draws every node label at the box's left edge plus the
    // padding; `HorizontalAlignment Right` does not move it either.
    Left | Right => (node.x + padding_x, "start")
    Center => (node.x + node.width / 2, "middle")
  }
  let (text_x, anchor, first_baseline) = match idea.shape {
    Box =>
      // SVG positions text by its baseline. PlantUML's box renderer starts a
      // line after the top padding plus the font's baseline offset.
      (text_x, anchor, node.y + padding_y + font_size)
    Boxless => {
      // Java adds the horizontal margin on the side away from the connector.
      // The connector itself meets the opposite edge of this virtual box.
      let text_x = match idea.direction {
        Right => node.x + boxless_horizontal_margin
        Left => node.x
      }
      (text_x, "start", node.y + boxless_vertical_margin + font_size)
    }
  }
  let shape_class = match idea.shape {
    Box => "box"
    Boxless => "boxless"
  }
  let defaults = diagram.style.defaults()
  let fill = @svg.svg_color(
    match idea.background_color {
      Some(color) => Some(color)
      None => node_style.background_color
    },
    defaults.node,
  )
  let line_color = @svg.svg_color(node_style.line_color, defaults.line)
  let font_color = @svg.svg_color(node_style.font_color, defaults.text)
  let line_thickness = node_style.line_thickness.map_or("1.5", value => {
    value.to_string()
  })
  let round_corner = node_style.round_corner.map_or("12.5", value => {
    value.to_string()
  })
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
    Boxless => ()
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
    font_metrics,
  )
  output.close()
}

///|
/// Render a parsed mindmap as an SVG document.
pub fn MindmapDiagram::render_svg(
  self : MindmapDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme) }
  let layout = self.layout()
  let output = @svg.XmlWriter::new()
  let background = self.style.canvas_color()
  let font_family = self.style.font_family()
  let font_size = self.style.font_size()
  let arrow_color = @svg.svg_color(
    match self.mindmap_style.arrow.line_color {
      Some(color) => Some(color)
      None => self.style.line_color
    },
    self.style.defaults().line,
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
pub fn render_mindmap_svg(
  input : String,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @parse.ParseError {
  parse(input).render_svg(color_scheme~)
}
