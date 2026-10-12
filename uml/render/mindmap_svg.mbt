///|
fn append_mindmap_edge(
  output : @graphics.Graphic,
  edge : EdgeLayout,
  line_color : String,
  line_thickness : Double,
  vertical : Bool,
) -> Unit {
  let sign = if vertical {
    if edge.y2 < edge.y1 {
      -1.0
    } else {
      1.0
    }
  } else if edge.x2 < edge.x1 {
    -1.0
  } else {
    1.0
  }
  let dx = if vertical { 0.0 } else { sign * 10.0 }
  let dy = if vertical { sign * 3.0 } else { 0 }
  output
  .with_style({
    ..@graphics.DrawingStyle::default(),
    stroke: Color(line_color),
    stroke_width: Some(line_thickness),
  })
  .draw(
    Path([
      MoveTo({ x: edge.x1, y: edge.y1, }),
      LineTo({ x: edge.x1 + dx, y: edge.y1 + dy, }),
      CubicTo(
        { x: edge.control1_x, y: edge.control1_y, },
        { x: edge.control2_x, y: edge.control2_y, },
        { x: edge.x2 - dx, y: edge.y2 - dy, },
      ),
      LineTo({ x: edge.x2, y: edge.y2, }),
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
  let font_metrics = diagram.node_font_metrics(node.index)
  let node_style = diagram.node_style(node.index)
  let padding_x = node_style.padding_left.unwrap_or(
    @tree.MINDMAP_DEFAULT_PADDING_X,
  )
  let padding_y = node_style.padding_top.unwrap_or(
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
      (text_x, anchor, node.y + padding_y + font_size.to_double())
    @tree.IdeaShape::Boxless => {
      // Java adds the horizontal margin on the side away from the connector.
      // The connector itself meets the opposite edge of this virtual box.
      let text_x = match idea.direction {
        @tree.TreeDirection::Right =>
          node.x + boxless_horizontal_margin.to_double()
        @tree.TreeDirection::Left => node.x
      }
      (
        text_x,
        @graphics.TextAnchor::Start,
        node.y + (boxless_vertical_margin + font_size).to_double(),
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
  let line_thickness = node_style.line_thickness.unwrap_or(1.5)
  let round_corner = node_style.round_corner.map_or(12.5, value => value / 2.0)
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
              origin={ x: node.x, y: node.y, },
              width=node.width,
              height=node.height,
              rx=Some(round_corner),
              ry=None,
            ),
          )
        @tree.IdeaShape::Boxless => ()
      }
      draw_tree_text_at(
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
        wrap_width=node_style.wrap_width.unwrap_or(0.0),
        font_family=node_style.font_name,
      )
    },
  )
}

///|
/// Render a parsed mindmap as an SVG document.
fn @tree.MindmapDiagram::render_svg(
  self : @tree.MindmapDiagram,
  color_scheme~ : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme), }
  let layout = self.layout()
  let decoration = decorate_document_text(
    self.style,
    layout.width,
    layout.height,
  )
  let scale = self.style.output_scale(decoration.width, decoration.height)
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
    (decoration.width * scale).ceil().to_int(),
    (decoration.height * scale).ceil().to_int(),
    "Mindmap",
    background,
    font_family,
    font_size,
    css=".mindmap-link{fill:none}.mindmap-node.boxless .mindmap-label{font-weight:normal}",
  )
  for block in decoration.text {
    document.stylesheet(
      resolve_state_font(self.style, block.role).css_rule(
        ".mindmap-" + block.kind + "-label",
      ),
    )
  }
  document
  .graphic()
  .scale_group(scale, graphic => {
    let output = graphic.translated(decoration.dx, decoration.dy)
    layout.edges.each(edge => {
      let style = mindmap_properties(self, edge.parent_index, true).fold(
        init=self.mindmap_style.arrow,
        (style, property) => style.with_property(property.name, property.value),
      )
      append_mindmap_edge(
        output,
        edge,
        @svg.svg_color(style.line_color, arrow_color),
        style.line_thickness.unwrap_or(arrow_thickness),
        self.style.layout_direction is Some(TopToBottom),
      )
    })
    layout.nodes.each(node => append_mindmap_node(output, self, node))
    draw_document_text(graphic, self.style, "mindmap", decoration.text)
  })
  document.to_string()
}

///|
/// Render a parsed mindmap to SVG.
pub fn render_mindmap_svg(
  diagram : @tree.MindmapDiagram,
  color_scheme~ : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  diagram.render_svg(color_scheme~)
}
