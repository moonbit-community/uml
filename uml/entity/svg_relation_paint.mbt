///|
fn relation_decoration_fill(
  fill : RelationDecorationFill,
  color : String,
  background : String,
) -> String {
  match fill {
    NoDecorationFill => "none"
    LineDecorationFill => color
    BackgroundDecorationFill => background
  }
}

///|
fn append_relation_decoration_primitive(
  output : StringBuilder,
  primitive : RelationDecorationPrimitive,
  color : String,
  background : String,
) -> Unit {
  let fill = relation_decoration_fill(primitive.fill, color, background)
  let style =
    $| style="stroke:\{color};stroke-width:\{primitive.stroke_width}"
  match primitive.shape {
    DecorationPolygon(points) => {
      guard points.length() > 0 else { return }
      output <+
        $|<path d="M \{points[0].0} \{points[0].1}
      for index in 1..<points.length() {
        output <+
          $| L \{points[index].0} \{points[index].1}
      }
      output <+
        $| z" class="relation-decoration" fill="\{fill}"\{style}/>
    }
    DecorationSegment(start, end) =>
      output <+
        $|<line x1="\{start.0}" y1="\{start.1}" x2="\{end.0}" y2="\{end.1}" class="relation-decoration" fill="none"\{style}/>
    DecorationCircle(center, radius) =>
      output <+
        $|<circle cx="\{center.0}" cy="\{center.1}" r="\{radius}" class="relation-decoration" fill="\{fill}"\{style}/>
    DecorationSquare(center, radius) =>
      output <+
        $|<rect x="\{center.0 - radius}" y="\{center.1 - radius}" width="\{radius * 2.0}" height="\{radius * 2.0}" class="relation-decoration" fill="\{fill}"\{style}/>
    DecorationArc(arc) =>
      output <+
        $|<path d="M \{arc.start.0} \{arc.start.1} A \{arc.radius} \{arc.radius} 0 \{if arc.large_arc { 1 } else { 0 }} \{if arc.sweep { 1 } else { 0 }} \{arc.end.0} \{arc.end.1}" class="relation-decoration" fill="\{fill}"\{style}/>
  }
}

///|
fn append_relation_decoration(
  output : StringBuilder,
  end : RelationEnd,
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  color : String,
  background : String,
  side? : RelationContactSide? = None,
) -> Unit {
  guard end.decoration_geometry(endpoint, adjacent, side~) is Some(geometry) else {
    return
  }
  for primitive in geometry.primitives {
    append_relation_decoration_primitive(output, primitive, color, background)
  }
}

///|
fn append_relation(
  output : StringBuilder,
  diagram : EntityDiagram,
  relation_index : Int,
  relation : Relation,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  let usecase = diagram.family.is_usecase()
  guard entity_index(diagram, relation.left) is Some(left_index) else { return }
  guard entity_index(diagram, relation.right) is Some(right_index) else {
    return
  }
  let left = diagram.entities[left_index]
  let right = diagram.entities[right_index]
  guard !left.is_removed && !right.is_removed else { return }
  let ((x1, y1), (x2, y2)) = relation_endpoints(
    layout, diagram, left_index, right_index, text_metrics,
  )
  // Dotted arrows render with the dash pattern shared by the dashed line
  // style, matching PlantUML where a dotted arrow draws dash-like segments.
  let dash = if relation.dotted {
    @svg.line_style_attributes_markup(Some("dashed"))
  } else {
    ""
  }
  let relation_style = @svg.stroke_style(relation.line_style, default_width="")
  let relation_color = @svg.svg_color(
    relation.color,
    diagram.style.diagram_line_color(),
  )
  let background_color = diagram.style.canvas_color()
  let label_font_size = if usecase {
    arrow_font_size(diagram.style, fallback=USECASE_RELATION_LABEL_FONT_SIZE)
  } else {
    text_metrics.relation_label_regular.font_size
  }
  let label_font_family = if usecase {
    arrow_font_family(diagram.style)
  } else {
    diagram.style.font_family()
  }
  let label_color = if usecase {
    arrow_font_color(diagram.style)
  } else {
    diagram.style.diagram_text_color()
  }
  let relation_label_layout = layout.relation_label_layout(
    diagram, relation_index, relation, text_metrics,
  )
  let style =
    $| style="stroke:\{relation_color};\{relation_style}"
  let mut drew_spline = false
  match layout.graphviz {
    Some(graphviz) if !(usecase &&
      relation.dotted &&
      relation.direction is Automatic) =>
      for edge in graphviz.edges {
        if edge.index == relation_index {
          let first_index = relation_edge_first_spline_index(edge)
          let last_index = relation_edge_last_spline_index(edge)
          for spline_index, spline in edge.splines {
            let path = spline.points.map(point => point.pair())
            guard path.length() > 1 else { continue }
            drew_spline = true
            let visible_path = shorten_relation_path(
              relation_path(path),
              if first_index == Some(spline_index) {
                relation.left_end.decoration_length()
              } else {
                0.0
              },
              if last_index == Some(spline_index) {
                relation.right_end.decoration_length()
              } else {
                0.0
              },
            ).pairs()
            output <+
              $|<path d="
            output.write_string(@svg.spline_path_data(visible_path))
            output <+
              $|" class="relation"\{style}\{dash}/>
            if first_index == Some(spline_index) {
              let contact = graphviz
                .node(relation.left)
                .map(node => node.contact(point_from_pair(path[0])))
              let side = contact.map(value => value.side)
              let endpoint = contact
                .map(value => value.point.pair())
                .unwrap_or(path[0])
              append_relation_decoration(
                output,
                relation.left_end,
                endpoint,
                path[1],
                relation_color,
                background_color,
                side~,
              )
            }
            if last_index == Some(spline_index) {
              let last = path.length() - 1
              let contact = graphviz
                .node(relation.right)
                .map(node => node.contact(point_from_pair(path[last])))
              let side = contact.map(value => value.side)
              let endpoint = contact
                .map(value => value.point.pair())
                .unwrap_or(path[last])
              append_relation_decoration(
                output,
                relation.right_end,
                endpoint,
                path[last - 1],
                relation_color,
                background_color,
                side~,
              )
            }
          }
        }
      }
    _ => ()
  }
  if !drew_spline {
    let visible_line = shorten_relation_path(
      relation_path([
        (x1.to_double(), y1.to_double()),
        (x2.to_double(), y2.to_double()),
      ]),
      relation.left_end.decoration_length(),
      relation.right_end.decoration_length(),
    ).pairs()
    output <+
      $|<line x1="\{visible_line[0].0}" y1="\{visible_line[0].1}" x2="\{visible_line[1].0}" y2="\{visible_line[1].1}" class="relation"\{style}\{dash}/>
    append_relation_decoration(
      output,
      relation.left_end,
      (x1.to_double(), y1.to_double()),
      (x2.to_double(), y2.to_double()),
      relation_color,
      background_color,
    )
    append_relation_decoration(
      output,
      relation.right_end,
      (x2.to_double(), y2.to_double()),
      (x1.to_double(), y1.to_double()),
      relation_color,
      background_color,
    )
  }
  match relation_label_layout.label {
    Some(text_box) => {
      let x = if usecase {
        text_box.x + text_box.width / 2.0
      } else {
        text_box.x
      }
      let anchor_style = if usecase {
        ""
      } else {
        " style=\"text-anchor:start\""
      }
      output <+
        $|<text x="\{x}" y="\{text_box.baseline}" class="relation-label" fill="\{label_color}" font-family="\{@svg.xml_escape(label_font_family)}" font-size="\{label_font_size}"\{anchor_style}>\{@svg.xml_escape(text_box.text)}</text>
    }
    None => ()
  }
  let end_label_font_size = text_metrics.relation_end_regular.font_size
  let end_label_font_family = text_metrics.relation_end_font_family
  for text_box in relation_label_layout.end_boxes() {
    output <+
      $|<text x="\{text_box.x}" y="\{text_box.baseline}" class="relation-end-label" font-family="\{@svg.xml_escape(end_label_font_family)}" font-size="\{end_label_font_size}">\{@svg.xml_escape(text_box.text)}</text>
  }
}
