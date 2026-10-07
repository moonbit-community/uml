///|
priv struct StructuredPaint {
  font_size : Int
  font_weight : Int
  italic : Bool
  font_family : String
  font_color : String
  background : String
  line_color : String
  line_thickness : Double
  round_corner : Double
  wrap_width : Double
  alignment : @graphics.TextAnchor
  dash : Array[Double]
}

///|
priv struct StructuredCell {
  text : String
  paint : StructuredPaint
  metrics : @metrics.FontMetrics
  rich : StateRichText?
  width : Int
  height : Int
}

///|
priv struct StructuredRowLayout {
  key : StructuredCell?
  value : StructuredCell
  height : Int
  highlight : StructuredPaint?
}

///|
priv struct StructuredBlock {
  rows : Array[StructuredRowLayout]
  key_width : Int
  width : Int
  height : Int
}

///|
priv struct StructuredPlacement {
  block : StructuredBlock
  x : Double
  y : Double
}

///|
const STRUCTURED_FONT_SIZE : Int = 14

///|
const STRUCTURED_CELL_PADDING_X : Int = 5

///|
const STRUCTURED_CELL_PADDING_Y : Int = 2

///|
const STRUCTURED_COLUMN_MIN_WIDTH : Int = 30

///|
const STRUCTURED_CANVAS_PADDING : Int = 10

///|
const STRUCTURED_SPOT_BACK : Double = 13.0

///|
fn @structured.StructuredValueDisplay::measurement_text(
  self : @structured.StructuredValueDisplay,
) -> String {
  match self {
    @structured.Text(text) => text
    @structured.True => "\u{2611} true"
    @structured.False => "\u{2610} false"
    @structured.Null => "\u{2400}"
    @structured.Compound => "   "
  }
}

///|
fn structured_stereotype(value : String) -> String {
  value.trim().trim_start(chars="<").trim_end(chars=">").to_lower().to_owned()
}

///|
fn structured_highlight(
  diagram : @structured.StructuredDiagram,
  path : Array[String],
) -> @structured.StructuredHighlight? {
  for highlight in diagram.highlights {
    let mut offset = 0
    let mut matched = true
    for index, key in path {
      if offset >= highlight.path.length() {
        matched = false
        break
      }
      let part = highlight.path[offset]
      if part == "**" {
        matched = highlight.path.length() == offset + 2 &&
          highlight.path[offset + 1] == path[path.length() - 1]
        break
      }
      if part != key && !(part == "*" && index < path.length() - 1) {
        matched = false
        break
      }
      offset += 1
    }
    if matched &&
      (offset == highlight.path.length() || highlight.path[offset] == "**") {
      return Some(highlight)
    }
  }
  None
}

///|
fn StructuredPaint::with_property(
  self : StructuredPaint,
  name : String,
  value : String,
) -> StructuredPaint {
  let number = @string.parse_double(value) catch { _ => -1.0 }
  match name.to_lower().replace_all(old="-", new="") {
    "fontcolor" => { ..self, font_color: value, }
    "backgroundcolor" => { ..self, background: value, }
    "linecolor" => { ..self, line_color: value, }
    "fontname" | "fontfamily" => { ..self, font_family: value, }
    "fontsize" if number > 0.0 =>
      { ..self, font_size: number.round().to_int(), }
    "fontstyle" =>
      {
        ..self,
        font_weight: if value.to_lower().contains("bold") {
          700
        } else {
          400
        },
        italic: value.to_lower().contains("italic"),
      }
    "linethickness" if number >= 0.0 => { ..self, line_thickness: number, }
    "roundcorner" if number >= 0.0 => { ..self, round_corner: number, }
    "wrapwidth" if number >= 0.0 => { ..self, wrap_width: number, }
    "horizontalalignment" =>
      {
        ..self,
        alignment: match value.to_lower() {
          "right" => End
          "center" => Middle
          _ => Start
        },
      }
    "linestyle" => {
      let dash = value
        .split("-")
        .filter_map(part => {
          let value = @string.parse_double(part) catch { _ => return None }
          if value > 0.0 {
            Some(value)
          } else {
            None
          }
        })
        .to_array()
      { ..self, dash, }
    }
    _ => self
  }
}

///|
fn structured_paint(
  diagram : @structured.StructuredDiagram,
  scheme : @style.ColorScheme,
  role : String,
  highlight : @structured.StructuredHighlight?,
) -> StructuredPaint {
  let base : StructuredPaint = {
    font_size: STRUCTURED_FONT_SIZE,
    font_weight: if role == "header" {
      700
    } else {
      400
    },
    italic: false,
    font_family: "sans-serif",
    font_color: scheme.text,
    background: if highlight is Some(_) {
      "#ccff02"
    } else {
      scheme.node
    },
    line_color: scheme.text,
    line_thickness: if role == "arrow" || role == "separator" {
      1.0
    } else {
      1.5
    },
    round_corner: 10.0,
    wrap_width: 0.0,
    alignment: Start,
    dash: if role == "arrow" {
      [3.0, 3.0]
    } else {
      []
    },
  }
  let family = match diagram.format {
    Json => "jsondiagram"
    Yaml => "yamldiagram"
    Toml => "tomldiagram"
  }
  let selected : Array[(Int, Int, @structured.StructuredStyleProperty)] = []
  for order, property in diagram.styles {
    let mut specificity = 0
    let matches = property.selector
      .to_lower()
      .split(" ")
      .all(group => {
        group
        .split(",")
        .any(word => {
          if word.is_empty() {
            return true
          }
          match word {
            "root" | "element" => true
            _ if word == family => true
            "node" => role != "arrow"
            "header" => {
              specificity += 10
              role == "header"
            }
            "separator" => {
              specificity += 10
              role == "separator"
            }
            "arrow" => {
              specificity += 10
              role == "arrow"
            }
            "highlight" => {
              specificity += 100
              highlight is Some(_)
            }
            _ if word.has_prefix(".") => {
              specificity += 1000
              highlight
              .bind(value => value.stereotype)
              .map_or(false, name => {
                structured_stereotype(name) == word[1:].to_owned()
              })
            }
            _ => false
          }
        })
      })
    if matches {
      selected.push((specificity, order, property))
    }
  }
  selected.sort_by((a, b) => if a.0 == b.0 { a.1 - b.1 } else { a.0 - b.0 })
  selected.fold(init=base, (paint, entry) => {
    paint.with_property(entry.2.name, entry.2.value)
  })
}

///|
fn structured_cell(text : String, paint : StructuredPaint) -> StructuredCell {
  let metrics = @metrics.FontMetrics::from_defaults(
    profile=@style.font_profile_for(paint.font_family),
    font_size=paint.font_size,
    line_height=paint.font_size + 3,
    ascent=paint.font_size,
    font_weight=paint.font_weight,
    style=if paint.italic { Italic } else { Normal },
  )
  let rich = state_rich_text(
    text,
    metrics,
    paint.wrap_width,
    literal_newlines=true,
  )
  let text = state_display(text, literal_newlines=true).wrap(
      metrics,
      paint.wrap_width,
    ).text
  let measured = metrics.measure(text)
  {
    text,
    paint,
    metrics,
    rich,
    width: rich.map_or(measured.width, rich => rich.width.ceil().to_int()) +
    STRUCTURED_CELL_PADDING_X * 2,
    height: rich.map_or(measured.height, rich => rich.height.ceil().to_int()) +
    STRUCTURED_CELL_PADDING_Y * 2,
  }
}

///|
fn is_blank_node(node : @structured.StructuredNode) -> Bool {
  node.rows.is_empty()
}

///|
fn structured_block(
  diagram : @structured.StructuredDiagram,
  node : @structured.StructuredNode,
  path : Array[String],
  scheme : @style.ColorScheme,
) -> StructuredBlock {
  let rows = []
  let mut key_width = 0
  let mut value_width = 0
  let mut height = 0
  for index, row in node.rows {
    let highlight = structured_highlight(
      diagram,
      [..path, row.key.unwrap_or(index.to_string())],
    )
    let key = row.key.map(key => {
      structured_cell(
        key,
        structured_paint(diagram, scheme, "header", highlight),
      )
    })
    let value = structured_cell(
      row.value.measurement_text(),
      structured_paint(diagram, scheme, "node", highlight),
    )
    let row_height = value.height.max(key.map_or(0, key => key.height))
    key_width = key_width.max(key.map_or(0, key => key.width))
    value_width = value_width.max(value.width)
    height += row_height
    rows.push({
      key,
      value,
      height: row_height,
      highlight: highlight.map(value => {
        structured_paint(diagram, scheme, "node", Some(value))
      }),
    })
  }
  if is_blank_node(node) {
    return {
      rows: [],
      key_width: 0,
      width: STRUCTURED_COLUMN_MIN_WIDTH,
      height: 15,
    }
  }
  { rows, key_width, width: key_width + value_width, height, }
}

///|
/// Smetana supplies record fields with externally measured dimensions. The
/// graphviz adapter expresses those same boxes as fixed HTML cells and named
/// ports; all ranking, crossing reduction, positioning and splines run in dot.
fn structured_graph_label(block : StructuredBlock) -> String {
  let output = StringBuilder()
  output.write_string(
    "<<TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\">",
  )
  if block.rows.is_empty() {
    output.write_string(
      "<TR><TD WIDTH=\"\{block.width}\" HEIGHT=\"\{block.height}\" FIXEDSIZE=\"TRUE\"></TD></TR>",
    )
  } else {
    for index, row in block.rows {
      output.write_string("<TR>")
      if block.key_width > 0 {
        output.write_string(
          "<TD WIDTH=\"\{block.key_width}\" HEIGHT=\"\{row.height}\" FIXEDSIZE=\"TRUE\"></TD>",
        )
      }
      output.write_string(
        "<TD PORT=\"P\{index}\" WIDTH=\"\{block.width - block.key_width}\" HEIGHT=\"\{row.height}\" FIXEDSIZE=\"TRUE\"></TD></TR>",
      )
    }
  }
  output.write_string("</TABLE>>")
  output.to_string()
}

///|
fn structured_graph_node(
  diagram : @structured.StructuredDiagram,
  node : @structured.StructuredNode,
  path : Array[String],
  scheme : @style.ColorScheme,
  graph : @cgraph.Graph,
  blocks : Array[StructuredBlock],
  edges : Map[Int, String],
) -> @cgraph.Node {
  let index = blocks.length()
  let block = structured_block(diagram, node, path, scheme)
  blocks.push(block)
  let vertex = graph.node(index.to_string())
  vertex.set_attr("shape", "plain")
  vertex.set_attr("margin", "0")
  vertex.set_attr("width", "0")
  vertex.set_attr("height", "0")
  vertex.set_attr("fontsize", "1")
  vertex.set_attr_value("label", @cgraph.Html(structured_graph_label(block)))
  for row_index, row in node.rows {
    guard row.child is Some(child) else { continue }
    let target = structured_graph_node(
      diagram,
      child,
      [..path, row.key.unwrap_or(row_index.to_string())],
      scheme,
      graph,
      blocks,
      edges,
    )
    let edge = graph.edge(vertex, target, tail_port={
      name: Some("P\{row_index}"),
      compass: None,
    })
    edge.set_attr("arrowsize", ".75")
    edge.set_attr("arrowtail", "none")
    edge.set_attr("arrowhead", "normal")
    edges[edge.id()] = edges.length().to_string()
  }
  vertex
}

///|
fn draw_structured_cell(
  output : @graphics.Graphic,
  cell : StructuredCell,
  x : Double,
  y : Double,
  width : Double,
  class_name : String,
) -> Unit {
  let dx = match cell.paint.alignment {
    Start => STRUCTURED_CELL_PADDING_X.to_double()
    Middle =>
      (width - cell.width.to_double()) / 2.0 +
      STRUCTURED_CELL_PADDING_X.to_double()
    End =>
      width - cell.width.to_double() + STRUCTURED_CELL_PADDING_X.to_double()
  }
  if cell.rich is Some(rich) {
    rich.draw(
      output.with_style({
        ..output.style,
        fill: Color(@svg.svg_color(Some(cell.paint.font_color), "black")),
      }),
      x + dx,
      y + STRUCTURED_CELL_PADDING_Y.to_double(),
      cell.metrics,
      { ..Default::default(), class_name: Some(class_name), },
      Start,
      Some(cell.paint.alignment),
    )
    return
  }
  output
  .with_style({
    ..Default::default(),
    fill: Color(@svg.svg_color(Some(cell.paint.font_color), "black")),
    stroke: None,
  })
  .draw(
    StyledTextBlock(
      @svg.layout_multiline_text(
        x + dx,
        y +
        STRUCTURED_CELL_PADDING_Y.to_double() +
        cell.metrics.ascent.to_double(),
        cell.text,
        line_height=cell.metrics.line_height.to_double(),
        anchor=Baseline,
        text_metrics=Some(cell.metrics),
      ),
      {
        weight: Some(cell.paint.font_weight),
        italic: Some(cell.paint.italic),
        font_family: Some(cell.paint.font_family),
        font_size: Some(cell.paint.font_size.to_double()),
      },
    ),
    metadata={ ..Default::default(), class_name: Some(class_name), },
  )
}

///|
fn draw_structured_node(
  output : @graphics.Graphic,
  placement : StructuredPlacement,
  paint : StructuredPaint,
  separator : StructuredPaint,
) -> Unit {
  let block = placement.block
  let origin : @graphics.Point = { x: placement.x, y: placement.y, }
  let rect : @graphics.Shape = Rectangle(
    origin~,
    width=block.width.to_double(),
    height=block.height.to_double(),
    rx=Some(paint.round_corner / 2.0),
    ry=None,
  )
  let node = output.with_style({
    ..Default::default(),
    fill: Color(@svg.svg_color(Some(paint.background), "white")),
    stroke: Color(@svg.svg_color(Some(paint.line_color), "black")),
    stroke_width: Some(paint.line_thickness),
    dash: Some(paint.dash),
  })
  node.group({ ..Default::default(), class_name: Some("structured-node"), }, output => {
    output.draw(rect)
    let separator_graphic = output.with_style({
      ..Default::default(),
      stroke: Color(@svg.svg_color(Some(separator.line_color), "black")),
      stroke_width: Some(separator.line_thickness),
      dash: Some(separator.dash),
      fill: None,
    })
    let mut y = origin.y
    for row in block.rows {
      if row.highlight is Some(paint) {
        output
        .with_style({
          ..Default::default(),
          fill: Color(@svg.svg_color(Some(paint.background), "#ccff02")),
          stroke: None,
        })
        .draw(
          Rectangle(
            origin={ x: origin.x + 1.5, y, },
            width=block.width.to_double() - 2.0,
            height=row.height.to_double(),
            rx=Some(4.0),
            ry=None,
          ),
          metadata={
            ..Default::default(),
            class_name: Some("structured-highlight"),
          },
        )
      }
      if y > origin.y {
        separator_graphic.draw(
          Line({ x: origin.x, y, }, {
            x: origin.x + block.width.to_double(),
            y,
          }),
        )
      }
      if row.key is Some(key) {
        draw_structured_cell(
          output,
          key,
          origin.x,
          y,
          block.key_width.to_double(),
          "structured-key",
        )
        let x = origin.x + block.key_width.to_double()
        separator_graphic.draw(
          Line({ x, y, }, { x, y: y + row.height.to_double(), }),
        )
      }
      draw_structured_cell(
        output,
        row.value,
        origin.x + block.key_width.to_double(),
        y,
        (block.width - block.key_width).to_double(),
        "structured-value",
      )
      y += row.height.to_double()
    }
    output.with_style({ ..output.style, fill: None, }).draw(rect)
  })
}

///|
fn draw_structured_edges(
  output : @graphics.Graphic,
  edges : Array[@graphviz.GraphvizEdge],
  paint : StructuredPaint,
) -> Unit {
  let color = @svg.svg_color(Some(paint.line_color), "black")
  let output = output.with_style({
    ..Default::default(),
    stroke: Color(color),
    stroke_width: Some(paint.line_thickness),
    dash: Some(paint.dash),
    fill: None,
  })
  for edge in edges {
    for spline in edge.splines {
      guard spline.points.length() >= 2 else { continue }
      let point = (value : @graphviz.GraphvizPoint) => @graphics.Point::{
        x: value.x,
        y: value.y,
      }
      let first = spline.points[0]
      let second = spline.points[1]
      let dx = first.x - second.x
      let dy = first.y - second.y
      let length = (dx * dx + dy * dy).sqrt()
      let start : @graphics.Point = if length > 0.0 {
        {
          x: first.x + dx / length * STRUCTURED_SPOT_BACK,
          y: first.y + dy / length * STRUCTURED_SPOT_BACK,
        }
      } else {
        point(first)
      }
      let path : Array[@graphics.PathSegment] = [
        MoveTo(start),
        LineTo(point(first)),
      ]
      let mut index = 1
      while index + 2 < spline.points.length() {
        path.push(
          CubicTo(
            point(spline.points[index]),
            point(spline.points[index + 1]),
            point(spline.points[index + 2]),
          ),
        )
        index += 3
      }
      output.draw(Path(path), metadata={
        ..Default::default(),
        class_name: Some("structured-edge"),
      })
      let ink = output.with_style({
        ..output.style,
        fill: Color(color),
        dash: Some([]),
        stroke_width: Some(1.0),
      })
      ink.draw(Circle(center=start, radius=3.0), metadata={
        ..Default::default(),
        class_name: Some("structured-spot"),
      })
      if spline.arrow_end is Some(end) {
        let last = spline.points[spline.points.length() - 1]
        let dx = end.x - last.x
        let dy = end.y - last.y
        ink.draw(
          Polygon([
            { x: last.x - dy * 0.4, y: last.y + dx * 0.4, },
            { x: last.x + dx * 0.3, y: last.y + dy * 0.3, },
            { x: last.x + dy * 0.4, y: last.y - dx * 0.4, },
            point(end),
          ]),
          metadata={
            ..Default::default(),
            class_name: Some("structured-arrow"),
          },
        )
      }
    }
  }
}

///|
/// Render structured records using the same graph-layout stages as
/// SmetanaForJson: measured port cells, dot layout, spline extraction, paint.
/// Layout errors are propagated; there is no geometric fallback.
pub fn render_structured_svg(
  diagram : @structured.StructuredDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @dot_layout.DotLayoutError {
  let graph = @cgraph.Graph::new(Directed, name="structured", strict=false)
  graph.set_attr("rankdir", "LR")
  graph.set_attr("splines", "spline")
  let blocks = []
  let edge_names : Map[Int, String] = Map([])
  ignore(
    structured_graph_node(
      diagram,
      diagram.root,
      [],
      color_scheme,
      graph,
      blocks,
      edge_names,
    ),
  )
  let layout = @dot_layout.layout_dot(graph)
  let edges = @graphviz.graphviz_edges(layout, edge_names, layout.bbox)
  let placements = layout.nodes.map(node => {
    let index = @string.parse_int(node.node.name()) catch {
      _ => abort("invalid structured node identifier")
    }
    let (x, y, _, _) = @graphviz.graphviz_node_rect(node, layout.bbox)
    { block: blocks[index], x, y, }
  })
  let width = layout.bbox.urx -
    layout.bbox.llx +
    STRUCTURED_CANVAS_PADDING.to_double() * 2.0
  let height = layout.bbox.ury -
    layout.bbox.lly +
    STRUCTURED_CANVAS_PADDING.to_double() * 2.0
  let style = @style.DocumentStyle::empty().with_color_scheme(color_scheme)
  for (key, value) in diagram.presentation {
    if @style.parse_style_directive(key + " " + value) is Some(directive) {
      style.apply(directive)
    }
  }
  let decoration = decorate_document_text(style, width, height)
  let scale = style.output_scale(decoration.width, decoration.height)
  let document = @svg.SvgDocument::new(
    (decoration.width * scale).ceil().to_int(),
    (decoration.height * scale).ceil().to_int(),
    diagram.format.aria_label(),
    style.canvas_color(),
    style.font_family(),
    style.font_size(),
  )
  for block in decoration.text {
    document.stylesheet(
      resolve_state_font(style, block.role).css_rule(
        ".structured-" + block.kind + "-label",
      ),
    )
  }
  handwritten_graphic(document.graphic(), style).scale_group(scale, graphic => {
    let output = graphic.translated(
      decoration.dx + STRUCTURED_CANVAS_PADDING.to_double(),
      decoration.dy + STRUCTURED_CANVAS_PADDING.to_double(),
    )
    let paint = structured_paint(diagram, color_scheme, "node", None)
    let separator = structured_paint(diagram, color_scheme, "separator", None)
    for placement in placements {
      draw_structured_node(output, placement, paint, separator)
    }
    draw_structured_edges(
      output,
      edges,
      structured_paint(diagram, color_scheme, "arrow", None),
    )
    draw_document_text(graphic, style, "structured", decoration.text)
  })
  document.to_string()
}
