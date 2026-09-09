///|
/// SVG driver for the typed drawing API. Geometry and styles become XML
/// only here; renderers supply unescaped values and measured text advances.
pub fn XmlWriter::graphic(self : XmlWriter) -> @graphics.Graphic {
  @graphics.Graphic::new(command => self.draw_command(command))
}

///|
/// Paint through the typed API into this document's existing output stream.
pub fn SvgDocument::graphic(self : SvgDocument) -> @graphics.Graphic {
  self.writer.graphic()
}

///|
fn metadata_attributes(
  metadata : @graphics.Metadata,
) -> Array[(String, String)] {
  [
    ..metadata.id.map_or([], value => [("id", value)]),
    ..metadata.class_name.map_or([], value => [("class", value)]),
    ..metadata.data.map(entry => ("data-" + entry.0, entry.1)),
  ]
}

///|
fn paint_attributes(
  name : String,
  paint : @graphics.Paint,
) -> Array[(String, String)] {
  match paint {
    Inherit => []
    None => [(name, "none")]
    Color(value) => [(name, value)]
  }
}

///|
fn drawing_style_attributes(
  style : @graphics.DrawingStyle,
) -> Array[(String, String)] {
  [
    ..paint_attributes("fill", style.fill),
    ..paint_attributes("stroke", style.stroke),
    ..style.stroke_width.map_or([], width => {
      [("stroke-width", width.to_string())]
    }),
    ..style.dash.map_or([], dash => {
      [
        (
          "stroke-dasharray",
          if dash.is_empty() {
            "none"
          } else {
            dash.map(value => value.to_string()).join(" ")
          },
        ),
      ]
    }),
  ]
}

///|
fn translated_point(
  point : @graphics.Point,
  translation : @graphics.Point,
) -> String {
  "\{point.x + translation.x} \{point.y + translation.y}"
}

///|
/// Serialize typed path operations without changing their geometry. Offsets
/// apply to endpoints/control points only, never radii, rotations or flags.
pub fn path_data(
  segments : Array[@graphics.PathSegment],
  translation? : @graphics.Point = @graphics.Point::default(),
) -> String {
  segments
  .map(segment => {
    match segment {
      MoveTo(point) => "M " + translated_point(point, translation)
      LineTo(point) => "L " + translated_point(point, translation)
      CubicTo(first, second, end) =>
        "C " +
        translated_point(first, translation) +
        " " +
        translated_point(second, translation) +
        " " +
        translated_point(end, translation)
      QuadraticTo(control, end) =>
        "Q " +
        translated_point(control, translation) +
        " " +
        translated_point(end, translation)
      ArcTo(rx~, ry~, rotation~, large_arc~, sweep~, end~) =>
        "A \{rx} \{ry} \{rotation} \{if large_arc { 1 } else { 0 }} \{if sweep { 1 } else { 0 }} " +
        translated_point(end, translation)
      Close => "Z"
    }
  })
  .join(" ")
}

///|
fn XmlWriter::draw_command(
  self : XmlWriter,
  command : @graphics.DrawCommand,
) -> Unit {
  match command {
    BeginGroup(metadata) =>
      self.open("g", attributes=metadata_attributes(metadata))
    EndGroup => self.close()
    BeginLink(url) => self.open("a", attributes=[("href", url)])
    EndLink => self.close()
    Draw(shape, style, translation, metadata) => {
      let attributes = [
        ..match shape {
          StyledTextBlock(_, font) =>
            [
              ..font.font_size.map_or([], size => {
                [("font-size", size.to_string())]
              }),
              ..font.font_family.map_or([], family => [("font-family", family)]),
            ]
          _ => []
        },
        ..drawing_style_attributes(style),
        ..metadata_attributes(metadata),
        ..match shape {
          MarkedPath(_, markers) => marker_attributes(markers)
          _ => []
        },
      ]
      match shape {
        Circle(center~, radius~) =>
          self.empty(
            "circle",
            attributes=[
              ("cx", (center.x + translation.x).to_string()),
              ("cy", (center.y + translation.y).to_string()),
              ("r", radius.to_string()),
              ..attributes,
            ],
          )
        Rectangle(origin~, width~, height~, rx~, ry~) =>
          self.empty(
            "rect",
            attributes=[
              ("x", (origin.x + translation.x).to_string()),
              ("y", (origin.y + translation.y).to_string()),
              ("width", width.to_string()),
              ("height", height.to_string()),
              ..rx.map_or([], radius => [("rx", radius.to_string())]),
              ..ry.map_or([], radius => [("ry", radius.to_string())]),
              ..attributes,
            ],
          )
        Ellipse(center~, rx~, ry~) =>
          self.empty(
            "ellipse",
            attributes=[
              ("cx", (center.x + translation.x).to_string()),
              ("cy", (center.y + translation.y).to_string()),
              ("rx", rx.to_string()),
              ("ry", ry.to_string()),
              ..attributes,
            ],
          )
        Line(start, end) =>
          self.empty(
            "line",
            attributes=[
              ("x1", (start.x + translation.x).to_string()),
              ("y1", (start.y + translation.y).to_string()),
              ("x2", (end.x + translation.x).to_string()),
              ("y2", (end.y + translation.y).to_string()),
              ..attributes,
            ],
          )
        Polygon(points) =>
          self.empty(
            "polygon",
            attributes=[
              (
                "points",
                points
                .map(point => translated_point(point, translation))
                .join(" "),
              ),
              ..attributes,
            ],
          )
        Path(segments) | MarkedPath(segments, _) =>
          self.empty(
            "path",
            attributes=[("d", path_data(segments, translation~)), ..attributes],
          )
        TextBlock(block) | StyledTextBlock(block, _) => {
          let x = block.position.x + translation.x
          self.open(
            "text",
            attributes=[
              ("x", x.to_string()),
              ("y", (block.position.y + translation.y).to_string()),
              ("text-anchor", text_anchor_value(block.anchor)),
              ..attributes,
            ],
          )
          for line in block.lines {
            self.text(
              "tspan",
              line.text,
              attributes=[
                ("x", x.to_string()),
                ("dy", line.dy.to_string()),
                ..line.advance.map_or([], advance => {
                  [
                    ("textLength", advance.to_string()),
                    ("lengthAdjust", "spacing"),
                  ]
                }),
              ],
            )
          }
          self.close()
        }
        Text(run) =>
          self.text(
            "text",
            run.text,
            attributes=[
              ("x", (run.position.x + translation.x).to_string()),
              ("y", (run.position.y + translation.y).to_string()),
              ("text-anchor", text_anchor_value(run.anchor)),
              ("font-size", "\{run.font_size}px"),
              ..run.font_family.map_or([], family => [("font-family", family)]),
              ..run.advance.map_or([], advance => {
                [
                  ("textLength", advance.to_string()),
                  ("lengthAdjust", "spacing"),
                ]
              }),
              ..if run.strike {
                [("text-decoration", "line-through")]
              },
              ..attributes,
            ],
          )
      }
    }
  }
}

///|
fn text_anchor_value(anchor : @graphics.TextAnchor) -> String {
  match anchor {
    Start => "start"
    Middle => "middle"
    End => "end"
  }
}
