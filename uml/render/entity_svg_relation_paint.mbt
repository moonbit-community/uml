///|
fn draw_relation_decoration_primitive(
  output : @graphics.Graphic,
  primitive : RelationDecorationPrimitive,
  color : String,
  background : String,
) -> Unit {
  let fill : @graphics.Paint = match primitive.fill {
    NoDecorationFill => None
    LineDecorationFill => Color(color)
    BackgroundDecorationFill => Color(background)
  }
  let point = (pair : (Double, Double)) => @graphics.Point::{
    x: pair.0,
    y: pair.1,
  }
  let shape : @graphics.Shape = match primitive.shape {
    DecorationPolygon(points) => {
      guard !points.is_empty() else { return }
      let path : Array[@graphics.PathSegment] = [MoveTo(point(points[0]))]
      for index in 1..<points.length() {
        path.push(LineTo(point(points[index])))
      }
      path.push(Close)
      Path(path)
    }
    DecorationSegment(start, end) => Line(point(start), point(end))
    DecorationCircle(center, radius) => Circle(center=point(center), radius~)
    DecorationSquare(center, radius) =>
      Rectangle(
        origin={ x: center.0 - radius, y: center.1 - radius, },
        width=radius * 2,
        height=radius * 2,
        rx=None,
        ry=None,
      )
    DecorationArc(arc) =>
      Path([
        MoveTo(point(arc.start)),
        ArcTo(
          rx=arc.radius,
          ry=arc.radius,
          rotation=0,
          large_arc=arc.large_arc,
          sweep=arc.sweep,
          end=point(arc.end),
        ),
      ])
  }
  output
  .with_style({
    ..Default::default(),
    fill,
    stroke: Color(color),
    stroke_width: Some(primitive.stroke_width),
    inline: true,
  })
  .draw(shape, metadata={
    ..Default::default(),
    class_name: Some("relation-decoration"),
  })
}

///|
fn draw_relation_decoration(
  output : @graphics.Graphic,
  end : @entity.RelationEnd,
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
    draw_relation_decoration_primitive(output, primitive, color, background)
  }
}

///|
/// Contact point and decoration orientation on the current node boundary.
priv struct RelationEndpoint {
  endpoint : (Double, Double)
  side : RelationContactSide?
}

///|
/// Move one spline endpoint (and its adjacent control point when the path is
/// cubic) so the endpoint tangent is preserved, mirroring the Graphviz node
/// contact repair.
fn move_relation_spline_endpoint(
  path : Array[(Double, Double)],
  at_start : Bool,
  endpoint : (Double, Double),
) -> Array[(Double, Double)] {
  let moved = path.copy()
  let index = if at_start { 0 } else { path.length() - 1 }
  let dx = endpoint.0 - path[index].0
  let dy = endpoint.1 - path[index].1
  moved[index] = endpoint
  if path.length() > 1 && (path.length() - 1) % 3 == 0 {
    let control = if at_start { 1 } else { path.length() - 2 }
    moved[control] = (moved[control].0 + dx, moved[control].1 + dy)
  }
  moved
}

///|
/// Paint the routed splines with their current node contacts.
fn append_relation_spline(
  output : @graphics.Graphic,
  edge : @graphviz.GraphvizEdge,
  relation : @entity.Relation,
  left : RelationEndpoint,
  right : RelationEndpoint,
  style : @graphics.DrawingStyle,
  relation_color : String,
  background_color : String,
) -> Unit {
  let first_index = relation_edge_first_spline_index(edge)
  let last_index = relation_edge_last_spline_index(edge)
  for spline_index, spline in edge.splines {
    let path = spline.points.map(point => point.pair())
    guard path.length() > 1 else { continue }
    let first = first_index == Some(spline_index)
    let last = last_index == Some(spline_index)
    let mut adjusted = path
    if first {
      adjusted = move_relation_spline_endpoint(adjusted, true, left.endpoint)
    }
    if last {
      adjusted = move_relation_spline_endpoint(adjusted, false, right.endpoint)
    }
    let visible_path = shorten_relation_path(
      relation_path(adjusted),
      if first {
        relation.left_end.decoration_length()
      } else {
        0.0
      },
      if last {
        relation.right_end.decoration_length()
      } else {
        0.0
      },
    ).pairs()
    output
    .with_style(style)
    .draw(Path(@graphics.spline_segments(visible_path)), metadata={
      ..Default::default(),
      class_name: Some("relation"),
    })
    if first {
      draw_relation_decoration(
        output,
        relation.left_end,
        left.endpoint,
        adjusted[1],
        relation_color,
        background_color,
        side=left.side,
      )
    }
    if last {
      let last_point = adjusted.length() - 1
      draw_relation_decoration(
        output,
        relation.right_end,
        right.endpoint,
        adjusted[last_point - 1],
        relation_color,
        background_color,
        side=right.side,
      )
    }
  }
}

///|
fn append_relation_line(
  output : @graphics.Graphic,
  left : RelationEndpoint,
  right : RelationEndpoint,
  style : @graphics.DrawingStyle,
  relation_color : String,
  background_color : String,
  relation : @entity.Relation,
) -> Unit {
  let visible_line = shorten_relation_path(
    relation_path([left.endpoint, right.endpoint]),
    relation.left_end.decoration_length(),
    relation.right_end.decoration_length(),
  ).pairs()
  output
  .with_style(style)
  .draw(
    Line({ x: visible_line[0].0, y: visible_line[0].1, }, {
      x: visible_line[1].0,
      y: visible_line[1].1,
    }),
    metadata={ ..Default::default(), class_name: Some("relation"), },
  )
  draw_relation_decoration(
    output,
    relation.left_end,
    left.endpoint,
    right.endpoint,
    relation_color,
    background_color,
    side=left.side,
  )
  draw_relation_decoration(
    output,
    relation.right_end,
    right.endpoint,
    left.endpoint,
    relation_color,
    background_color,
    side=right.side,
  )
}

///|
fn append_relation_path(
  output : @graphics.Graphic,
  left : RelationEndpoint,
  right : RelationEndpoint,
  style : @graphics.DrawingStyle,
  relation_color : String,
  background_color : String,
  edge? : @graphviz.GraphvizEdge? = None,
  relation : @entity.Relation,
) -> Unit {
  if edge is Some(edge) {
    append_relation_spline(
      output, edge, relation, left, right, style, relation_color, background_color,
    )
  } else {
    append_relation_line(
      output, left, right, style, relation_color, background_color, relation,
    )
  }
}

///|
fn relation_edge_endpoints(
  edge : @graphviz.GraphvizEdge,
) -> ((Double, Double), (Double, Double))? {
  let first_index = relation_edge_first_spline_index(edge)
  let last_index = relation_edge_last_spline_index(edge)
  guard first_index is Some(first_index) else { return None }
  guard last_index is Some(last_index) else { return None }
  let first = edge.splines[first_index]
  let last = edge.splines[last_index]
  guard first.points.length() > 0 && last.points.length() > 0 else {
    return None
  }
  Some((first.points[0].pair(), last.points[last.points.length() - 1].pair()))
}

///|
/// Qualifier labels sit outside the relation endpoint, mirroring the `Kal`
/// decoration of the Java edge without its dot-path internals.
fn append_relation_qualifiers(
  output : @graphics.Graphic,
  relation : @entity.Relation,
  left_endpoint : (Double, Double),
  right_endpoint : (Double, Double),
  text_metrics : ClassTextMetrics,
) -> Unit {
  let font_size = text_metrics.relation_end_regular.font_size
  let font_family = text_metrics.relation_end_font_family
  if relation.left_qualifier is Some(qualifier) {
    let metrics = text_metrics.relation_end_regular.measure(qualifier)
    let x = left_endpoint.0 - metrics.width.to_double() - 6.0
    draw_entity_text(
      output,
      x,
      left_endpoint.1 + metrics.ascent.to_double(),
      qualifier,
      text_metrics.relation_end_regular,
      class_name="relation-qualifier",
      font_family~,
      font_size~,
    )
  }
  if relation.right_qualifier is Some(qualifier) {
    let metrics = text_metrics.relation_end_regular.measure(qualifier)
    let x = right_endpoint.0 + 6.0
    draw_entity_text(
      output,
      x,
      right_endpoint.1 - metrics.ascent.to_double(),
      qualifier,
      text_metrics.relation_end_regular,
      class_name="relation-qualifier",
      font_family~,
      font_size~,
    )
  }
}

///|
fn append_relation(
  output : @graphics.Graphic,
  diagram : @entity.EntityDiagram,
  relation_index : Int,
  relation : @entity.Relation,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  // The mindmap tree edges are painted as structure edges; every other
  // relation is dropped so non-root nodes keep exactly one edge.
  guard layout.mindmap is None else { return }
  let usecase = diagram.family.is_usecase()
  let left_index = entity_index(diagram, relation.left)
  let right_index = entity_index(diagram, relation.right)
  if left_index is Some(index) && diagram.entities[index].is_removed {
    return
  }
  if right_index is Some(index) && diagram.entities[index].is_removed {
    return
  }
  let ((x1, y1), (x2, y2)) = relation_endpoints(
    layout, diagram, relation, left_index, right_index, text_metrics,
  )
  // Dotted arrows render with the dash pattern shared by the dashed line
  // style, matching PlantUML where a dotted arrow draws dash-like segments.
  let dash = @svg.line_drawing_style(
    if relation.dotted {
      Some("dashed")
    } else {
      None
    },
  )
  let relation_style = @svg.line_drawing_style(relation.line_style)
  let relation_color = @svg.svg_color(
    relation.color,
    diagram.style.diagram_line_color(),
  )
  let background_color = diagram.style.canvas_color()
  let label_font_size = if usecase {
    @entity.arrow_font_size(
      diagram.style,
      fallback=USECASE_RELATION_LABEL_FONT_SIZE,
    )
  } else {
    text_metrics.relation_label_regular.font_size
  }
  let label_font_family = if usecase {
    @entity.arrow_font_family(diagram.style)
  } else {
    diagram.style.font_family()
  }
  let label_color = if usecase {
    @entity.arrow_font_color(diagram.style)
  } else {
    diagram.style.diagram_text_color()
  }
  let relation_label_layout = layout.relation_label_layout(
    diagram, relation_index, relation, text_metrics,
  )
  let style = {
    ..relation_style,
    stroke: Color(relation_color),
    inline: true,
    dash: relation_style.dash.map_or(dash.dash, value => Some(value)),
  }
  let edge_endpoints = layout.graphviz.bind(graphviz => {
    let mut endpoints : ((Double, Double), (Double, Double))? = None
    for edge in graphviz.edges {
      if edge.index == relation_index {
        endpoints = relation_edge_endpoints(edge)
      }
    }
    endpoints
  })
  let (left_endpoint, right_endpoint) = edge_endpoints.unwrap_or(
    ((x1, y1), (x2, y2)),
  )
  with_entity_link(output, relation.url, output => {
    let mut drew_spline = false
    match layout.graphviz {
      Some(graphviz) if !(usecase &&
        relation.dotted &&
        relation.direction is Automatic) =>
        for edge in graphviz.edges {
          if edge.index == relation_index {
            match relation_edge_first_spline_index(edge) {
              Some(first_index) => {
                let last_index = relation_edge_last_spline_index(edge)
                let first_path = edge.splines[first_index].points.map(point => {
                  point.pair()
                })
                let last_path = edge.splines[last_index.unwrap_or(first_index)].points.map(point => {
                    point.pair()
                  },
                )
                let left_contact = graphviz
                  .node(relation.left)
                  .map(node => node.contact(point_from_pair(first_path[0])))
                let right_contact = graphviz
                  .node(relation.right)
                  .map(node => {
                    node.contact(
                      point_from_pair(last_path[last_path.length() - 1]),
                    )
                  })
                let left = relation_endpoint(
                  left_contact.map_or(first_path[0], value => value.point.pair()),
                  left_contact.map(value => value.side),
                )
                let right = relation_endpoint(
                  right_contact.map_or(last_path[last_path.length() - 1], value => {
                    value.point.pair()
                  }),
                  right_contact.map(value => value.side),
                )
                drew_spline = true
                append_relation_path(
                  output,
                  left,
                  right,
                  style,
                  relation_color,
                  background_color,
                  edge=Some(edge),
                  relation,
                )
              }
              None => ()
            }
          }
        }
      _ => ()
    }
    if !drew_spline {
      let left = relation_endpoint((x1, y1), None)
      let right = relation_endpoint((x2, y2), None)
      append_relation_path(
        output,
        left,
        right,
        style,
        relation_color,
        background_color,
        edge=None,
        relation,
      )
    }
    if relation_label_layout.label is Some(text_box) {
      let x = if usecase {
        text_box.x + text_box.width / 2.0
      } else {
        text_box.x
      }
      draw_entity_text(
        output,
        x,
        text_box.baseline,
        text_box.text,
        text_metrics.relation_label_regular,
        class_name="relation-label",
        fill=label_color,
        font_family=label_font_family,
        font_size=label_font_size,
        anchor=if usecase { Middle } else { Start },
      )
    }
    let end_label_font_size = text_metrics.relation_end_regular.font_size
    let end_label_font_family = text_metrics.relation_end_font_family
    for text_box in relation_label_layout.end_boxes() {
      draw_entity_text(
        output,
        text_box.x,
        text_box.baseline,
        text_box.text,
        text_metrics.relation_end_regular,
        class_name="relation-end-label",
        font_family=end_label_font_family,
        font_size=end_label_font_size,
      )
    }
    append_relation_qualifiers(
      output, relation, left_endpoint, right_endpoint, text_metrics,
    )
  })
}

///|
fn relation_endpoint(
  endpoint : (Double, Double),
  side : RelationContactSide?,
) -> RelationEndpoint {
  { endpoint, side, }
}
