///|
/// ExtremityArrow.buildPolygon's wing length, aperture, and inner contact.
const WBS_ARROW_WING : Double = 9.0

///|
const WBS_ARROW_APERTURE : Double = 4.0

///|
const WBS_ARROW_CONTACT : Double = 5.0

///|
fn draw_wbs_node(
  output : @graphics.Graphic,
  diagram : @tree.WbsDiagram,
  item : WbsItem,
  node : WbsNodeLayout,
) -> Unit {
  let source = diagram.nodes[node.index]
  guard !(source.shape is @tree.NodeShape::Pseudo) else { return }
  let style = item.style
  let defaults = diagram.style.defaults()
  let font_size = style.font_size.unwrap_or(@tree.WBS_DEFAULT_FONT_SIZE)
  let metrics = diagram.style.font_metrics(font_size~)
  let fill = @svg.svg_color(
    source.background_color.map_or(style.background_color, color => Some(color)),
    defaults.node,
  )
  let stroke = @svg.svg_color(
    style.line_color,
    diagram.style.diagram_line_color(),
  )
  let font_color = @svg.svg_color(
    style.font_color,
    diagram.style.diagram_text_color(),
  )
  let shape_name = if source.shape is @tree.NodeShape::Box {
    "box"
  } else {
    "boxless"
  }
  output.group(
    {
      ..Default::default(),
      class_name: Some("wbs-node " + shape_name),
      data: [("node-index", node.index.to_string())],
    },
    output => {
      let output = output.translated(node.x, node.y)
      let (text_x, text_y) = if source.shape is @tree.NodeShape::Box {
        output
        .with_style({
          ..Default::default(),
          fill: Color(fill),
          stroke: Color(stroke),
          stroke_width: Some(
            wbs_line_thickness(diagram, node.index, false, source.stereotype),
          ),
        })
        .draw(
          Rectangle(
            origin={ x: 0.0, y: 0.0, },
            width=node.width,
            height=node.height,
            rx=Some(style.round_corner.unwrap_or(0).to_double() / 2.0),
            ry=None,
          ),
        )
        (
          style.padding_x.unwrap_or(@tree.WBS_DEFAULT_PADDING_X).to_double(),
          style.padding_y.unwrap_or(@tree.WBS_DEFAULT_PADDING_Y).to_double(),
        )
      } else {
        (
          (node.width - item.natural_width) / 2.0,
          boxless_vertical_margin.to_double(),
        )
      }
      let label_width = tree_label_width(metrics, font_size, item.label)
      let output = output.translated(text_x, text_y)
      let text_lines = item.label.split("\n").to_array()
      for line, value in text_lines {
        let text = value.to_owned()
        let first_line_space = if line == 0 && text_lines.length() > 1 {
          plantuml_space_advance(font_size)
        } else {
          0
        }
        let line_width = plantuml_measure(metrics, tree_visible_text(text)).width +
          first_line_space
        let dx = match style.alignment.unwrap_or(@tree.TextAlignment::Left) {
          @tree.TextAlignment::Left => 0.0
          @tree.TextAlignment::Center =>
            (label_width - line_width).to_double() / 2.0
          @tree.TextAlignment::Right => (label_width - line_width).to_double()
        }
        draw_tree_text(
          output.translated(dx + first_line_space.to_double(), 0.0),
          0,
          font_size + line * metrics.line_height,
          text,
          metrics.line_height,
          Start,
          font_color,
          font_size,
          metrics,
          "wbs-label",
        )
      }
    },
  )
}

///|
fn wbs_link_color(value : String) -> String {
  let parts = value.split(";").to_array()
  parts.fold(init=parts[0].to_owned(), (color, part) => {
    if part.has_prefix("line:") {
      part[5:].to_owned()
    } else {
      color
    }
  })
}

///|
fn wbs_contact(rect : WbsNodeLayout, target : WbsNodeLayout) -> @graphics.Point {
  let center_x = rect.x + rect.width / 2.0
  let center_y = rect.y + rect.height / 2.0
  let dx = target.x + target.width / 2.0 - center_x
  let dy = target.y + target.height / 2.0 - center_y
  let fraction_x = if dx == 0.0 { 1.0 } else { rect.width / (2.0 * dx.abs()) }
  let fraction_y = if dy == 0.0 { 1.0 } else { rect.height / (2.0 * dy.abs()) }
  let fraction = fraction_x.min(fraction_y)
  { x: center_x + dx * fraction, y: center_y + dy * fraction, }
}

///|
fn draw_wbs_links(
  output : @graphics.Graphic,
  diagram : @tree.WbsDiagram,
  layout : WbsLayout,
  items : Array[WbsItem],
) -> Unit {
  for link in diagram.links {
    guard wbs_layout_node(layout, link.source) is Some(source) &&
      wbs_layout_node(layout, link.target) is Some(target) else {
      continue
    }
    // ITFComposed records its translated tile origin and main dimensions for
    // WBSLink; its painted main box can be offset from that origin.
    let link_rect = (node : WbsNodeLayout) => {
      let tile = wbs_tile(items, node.index, diagram)
      { ..node, x: node.x - tile.axis + node.width / 2.0, }
    }
    let source = link_rect(source)
    let target = link_rect(target)
    let start = wbs_contact(source, target)
    let end = wbs_contact(target, source)
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = (dx * dx + dy * dy).sqrt()
    guard length > 0.0 else { continue }
    let arrow = wbs_arrow_style(diagram, link.source, link.stereotype)
    let color = @svg.svg_color(
      link.color.map_or(arrow.line_color, color => Some(wbs_link_color(color))),
      diagram.style.diagram_line_color(),
    )
    let graphic = output.with_style({
      ..Default::default(),
      stroke: Color(color),
      stroke_width: Some(1.0),
    })
    graphic.draw(Line(start, end), metadata={
      ..Default::default(),
      class_name: Some("wbs-cross-link"),
    })
    let ux = dx / length
    let uy = dy / length
    let point = (back : Double, side : Double) => {
      (
        { x: end.x - ux * back - uy * side, y: end.y - uy * back + ux * side, } :
        @graphics.Point)
    }
    graphic
    .with_style({ ..graphic.style, fill: Color(color), })
    .draw(
      Polygon([
        end,
        point(WBS_ARROW_WING, -WBS_ARROW_APERTURE),
        point(WBS_ARROW_CONTACT, 0.0),
        point(WBS_ARROW_WING, WBS_ARROW_APERTURE),
      ]),
      metadata={ ..Default::default(), class_name: Some("wbs-cross-arrow"), },
    )
  }
}

///|
fn wbs_layout_node(layout : WbsLayout, index : Int) -> WbsNodeLayout? {
  for node in layout.nodes {
    guard node.index == index else { continue }
    return Some(node)
  }
  None
}

///|
fn draw_wbs(
  output : @graphics.Graphic,
  diagram : @tree.WbsDiagram,
  layout : WbsLayout,
  items : Array[WbsItem],
) -> Unit {
  for line in layout.lines {
    let style = wbs_arrow_style(
      diagram,
      line.owner,
      diagram.nodes[line.owner].stereotype,
    )
    output
    .with_style({
      ..Default::default(),
      stroke: Color(
        @svg.svg_color(style.line_color, diagram.style.diagram_line_color()),
      ),
      stroke_width: Some(style.line_thickness),
    })
    .draw(Line(line.start, line.end), metadata={
      ..Default::default(),
      class_name: Some("wbs-branch"),
    })
  }
  for node in layout.nodes {
    draw_wbs_node(output, diagram, items[node.index], node)
  }
  draw_wbs_links(output, diagram, layout, items)
}

///|
/// Render a work breakdown structure using its dedicated Fork/ITF layout.
pub fn render_wbs_svg(
  diagram : @tree.WbsDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let diagram = {
    ..diagram,
    style: diagram.style.with_color_scheme(color_scheme),
  }
  let items = wbs_items(diagram)
  let layout = layout_wbs_items(diagram, items)
  let drawing = wbs_document(diagram.style, layout)
  let layout = drawing.tree
  let scale = diagram.style.output_scale(layout.width, layout.height)
  let document = @svg.SvgDocument::new(
    (layout.width * scale).ceil().to_int(),
    (layout.height * scale).ceil().to_int(),
    "Work breakdown structure",
    diagram.style.canvas_color(),
    diagram.style.font_family(),
    diagram.style.font_size(),
  )
  for block in drawing.text {
    document.stylesheet(
      resolve_state_font(diagram.style, block.role).css_rule(
        ".wbs-" + block.kind + "-label",
      ),
    )
  }
  document
  .graphic()
  .scale_group(scale, output => {
    draw_wbs(output, diagram, layout, items)
    draw_document_text(output, diagram.style, "wbs", drawing.text)
  })
  document.to_string()
}
