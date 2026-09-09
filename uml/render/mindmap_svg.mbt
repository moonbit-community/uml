///|
fn append_mindmap_edge(
  output : @graphics.Graphic,
  edge : EdgeLayout,
  line_color : String,
  line_thickness : Int,
) -> Unit {
  output
  .with_style({
    ..@graphics.DrawingStyle::default(),
    stroke: Color(line_color),
    stroke_width: Some(line_thickness.to_double()),
  })
  .draw(
    Path([
      MoveTo({ x: edge.x1.to_double(), y: edge.y1.to_double(), }),
      CubicTo(
        { x: edge.control1_x.to_double(), y: edge.control1_y.to_double(), },
        { x: edge.control2_x.to_double(), y: edge.control2_y.to_double(), },
        { x: edge.x2.to_double(), y: edge.y2.to_double(), },
      ),
    ]),
    metadata={
      ..@graphics.Metadata::default(),
      class_name: Some("mindmap-link"),
    },
  )
}

///|
fn append_mindmap_node(
  output : @graphics.Graphic,
  diagram : @tree.MindmapDiagram,
  node : NodeLayout,
) -> Unit {
  let idea = diagram.ideas[node.index]
  let font_size = diagram.node_font_size(node.index)
  let font_metrics = diagram.style.font_metrics(font_size~)
  let node_style = diagram.node_style(node.index)
  let padding_x = node_style.padding_x.unwrap_or(
    @tree.MINDMAP_DEFAULT_PADDING_X,
  )
  let padding_y = node_style.padding_y.unwrap_or(
    @tree.MINDMAP_DEFAULT_PADDING_Y,
  )
  let (text_x, anchor) = match
    node_style.alignment.unwrap_or(@tree.TextAlignment::Left) {
    // PlantUML draws every node label at the box's left edge plus the
    // padding; `HorizontalAlignment Right` does not move it either.
    @tree.TextAlignment::Left | @tree.TextAlignment::Right =>
      (node.x + padding_x, @graphics.TextAnchor::Start)
    @tree.TextAlignment::Center =>
      (node.x + node.width / 2, @graphics.TextAnchor::Middle)
  }
  let (text_x, anchor, first_baseline) = match idea.shape {
    @tree.IdeaShape::Box =>
      // SVG positions text by its baseline. PlantUML's box renderer starts a
      // line after the top padding plus the font's baseline offset.
      (text_x, anchor, node.y + padding_y + font_size)
    @tree.IdeaShape::Boxless => {
      // Java adds the horizontal margin on the side away from the connector.
      // The connector itself meets the opposite edge of this virtual box.
      let text_x = match idea.direction {
        @tree.TreeDirection::Right => node.x + boxless_horizontal_margin
        @tree.TreeDirection::Left => node.x
      }
      (
        text_x,
        @graphics.TextAnchor::Start,
        node.y + boxless_vertical_margin + font_size,
      )
    }
  }
  let shape_class = match idea.shape {
    @tree.IdeaShape::Box => "box"
    @tree.IdeaShape::Boxless => "boxless"
  }
  let defaults = diagram.style.defaults()
  let fill = @svg.svg_color(
    idea.background_color.map_or(node_style.background_color, color => {
      Some(color)
    }),
    defaults.node,
  )
  let line_color = @svg.svg_color(node_style.line_color, defaults.line)
  let font_color = @svg.svg_color(node_style.font_color, defaults.text)
  let line_thickness = node_style.line_thickness.map_or(1.5, value => {
    value.to_double()
  })
  let round_corner = node_style.round_corner.map_or(12.5, value => {
    value.to_double()
  })
  output.group(
    {
      ..@graphics.Metadata::default(),
      class_name: Some("mindmap-node " + shape_class),
      data: [("idea-index", node.index.to_string())],
    },
    output => {
      match idea.shape {
        @tree.IdeaShape::Box =>
          output
          .with_style({
            ..@graphics.DrawingStyle::default(),
            fill: Color(fill),
            stroke: Color(line_color),
            stroke_width: Some(line_thickness),
          })
          .draw(
            Rectangle(
              origin={ x: node.x.to_double(), y: node.y.to_double(), },
              width=node.width.to_double(),
              height=node.height.to_double(),
              rx=Some(round_corner),
              ry=None,
            ),
          )
        @tree.IdeaShape::Boxless => ()
      }
      draw_tree_text(
        output,
        text_x,
        first_baseline,
        idea.label,
        font_metrics.line_height,
        anchor,
        font_color,
        font_size,
        font_metrics,
        "mindmap-label",
      )
    },
  )
}

///|
/// Render a parsed mindmap as an SVG document.
fn @tree.MindmapDiagram::render_svg(
  self : @tree.MindmapDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme), }
  let layout = self.layout()
  let background = self.style.canvas_color()
  let font_family = self.style.font_family()
  let font_size = self.style.font_size()
  let arrow_color = @svg.svg_color(
    self.mindmap_style.arrow.line_color.map_or(self.style.line_color, color => {
      Some(color)
    }),
    self.style.defaults().line,
  )
  let arrow_thickness = self.mindmap_style.arrow.line_thickness.unwrap_or(1)
  let document = @svg.SvgDocument::new(
    layout.width,
    layout.height,
    "Mindmap",
    background,
    font_family,
    font_size,
    css=".mindmap-link{fill:none}.mindmap-node.boxless .mindmap-label{font-weight:normal}",
  )
  let output = document.graphic()
  layout.edges.each(edge => {
    append_mindmap_edge(output, edge, arrow_color, arrow_thickness)
  })
  layout.nodes.each(node => append_mindmap_node(output, self, node))
  document.to_string()
}

///|
/// Render a parsed mindmap to SVG.
pub fn render_mindmap_svg(
  diagram : @tree.MindmapDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  diagram.render_svg(color_scheme~)
}
