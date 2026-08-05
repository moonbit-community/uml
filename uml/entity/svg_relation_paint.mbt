///|
fn append_relation_decoration(
  output : StringBuilder,
  end : RelationEnd,
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  color : String,
) -> Unit {
  guard end.decoration_geometry(endpoint, adjacent) is Some(geometry) else {
    return
  }
  guard geometry.points.length() > 0 else { return }
  output <+
    $|<path d="M \{geometry.points[0].0} \{geometry.points[0].1}
  for index in 1..<geometry.points.length() {
    output <+
      $| L \{geometry.points[index].0} \{geometry.points[index].1}
  }
  let fill = if geometry.filled { color } else { "none" }
  output <+
    $| z" class="relation-decoration" fill="\{fill}" style="stroke:\{color}"/>
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
  let label_font_size = if usecase {
    diagram.style.arrow_font_size(fallback=USECASE_RELATION_LABEL_FONT_SIZE)
  } else {
    text_metrics.relation_label_regular.font_size
  }
  let label_font_family = if usecase {
    diagram.style.arrow_font_family()
  } else {
    diagram.style.font_family()
  }
  let label_color = if usecase {
    diagram.style.arrow_font_color()
  } else {
    diagram.style.diagram_text_color()
  }
  let relation_label_layout = layout.relation_label_layout(
    diagram, relation_index, relation, text_metrics,
  )
  let style =
    $| style="stroke:\{relation_color};\{relation_style}"
  let marker_start = match relation_marker(relation.left_end) {
    Some(marker) => " marker-start=\"url(#\{marker})\""
    None => ""
  }
  let marker_end = match relation_marker(relation.right_end) {
    Some(marker) => " marker-end=\"url(#\{marker})\""
    None => ""
  }
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
            let path = spline.points
            guard path.length() > 1 else { continue }
            drew_spline = true
            let visible_path = shorten_relation_spline(
              path,
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
            )
            output <+
              $|<path d="
            output.write_string(@svg.spline_path_data(visible_path))
            output <+
              $|" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
            if first_index == Some(spline_index) {
              append_relation_decoration(
                output,
                relation.left_end,
                path[0],
                path[1],
                relation_color,
              )
            }
            if last_index == Some(spline_index) {
              let last = path.length() - 1
              append_relation_decoration(
                output,
                relation.right_end,
                path[last],
                path[last - 1],
                relation_color,
              )
            }
          }
        }
      }
    _ => ()
  }
  if !drew_spline {
    let visible_line = shorten_relation_spline(
      [(x1.to_double(), y1.to_double()), (x2.to_double(), y2.to_double())],
      relation.left_end.decoration_length(),
      relation.right_end.decoration_length(),
    )
    output <+
      $|<line x1="\{visible_line[0].0}" y1="\{visible_line[0].1}" x2="\{visible_line[1].0}" y2="\{visible_line[1].1}" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
    append_relation_decoration(
      output,
      relation.left_end,
      (x1.to_double(), y1.to_double()),
      (x2.to_double(), y2.to_double()),
      relation_color,
    )
    append_relation_decoration(
      output,
      relation.right_end,
      (x2.to_double(), y2.to_double()),
      (x1.to_double(), y1.to_double()),
      relation_color,
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
