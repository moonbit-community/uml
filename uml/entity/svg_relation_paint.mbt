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
/// One possible anchor for a relation endpoint: the open state sits on the
/// full node boundary, while the closed state re-anchors onto the header strip
/// of a collapsed class node.
priv struct RelationEndpointState {
  endpoint : (Double, Double)
  side : RelationContactSide?
}

///|
/// Header-strip rectangle of a collapsible class node, or `None` when the
/// entity cannot collapse (not a class image, hidden, or without a body).
fn relation_endpoint_header(
  layout : ClassLayout,
  diagram : EntityDiagram,
  index : Int,
  text_metrics : ClassTextMetrics,
  class_member_collapsible : Bool,
) -> Rect? {
  guard class_member_collapsible else { return None }
  let entity = diagram.entities[index]
  guard entity.render_capability(diagram.family).renderer is ClassRenderer else {
    return None
  }
  guard !entity.is_hidden && !entity.is_removed else { return None }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let header_height = entity.header_layout(text_metrics).height
  guard header_height > 0 && header_height < height else { return None }
  Some(
    rect(
      point(
        x.to_double() + width.to_double() / 2.0,
        y.to_double() + header_height.to_double() / 2.0,
      ),
      width.to_double(),
      header_height.to_double(),
    ),
  )
}

///|
/// Relation endpoint alternatives for one side: always the open boundary
/// contact, plus the closed header-strip projection when the attached node is
/// collapsible.
fn relation_endpoint_states(
  endpoint : (Double, Double),
  side : RelationContactSide?,
  header : Rect?,
) -> Array[RelationEndpointState] {
  match header {
    Some(bounds) => {
      let closed = closest_point_on_rect(point_from_pair(endpoint), bounds)
      [
        { endpoint, side },
        {
          endpoint: closed.pair(),
          side: Some(rect_contact_side(closed, bounds)),
        },
      ]
    }
    None => [{ endpoint, side }]
  }
}

///|
/// Move one spline endpoint (and its adjacent control point when the path is
/// cubic) so the endpoint tangent is preserved, mirroring the Graphviz node
/// contact repair used for the open state.
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
/// Paint one relation edge for a concrete open/closed endpoint state.
fn append_relation_edge_state(
  output : StringBuilder,
  edge : @graphviz.GraphvizEdge,
  relation : Relation,
  left : RelationEndpointState,
  right : RelationEndpointState,
  style : String,
  dash : String,
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
    output <+
      $|<path d="
    output.write_string(@svg.spline_path_data(visible_path))
    output <+
      $|" class="relation"\{style}\{dash}/>
    if first {
      append_relation_decoration(
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
      append_relation_decoration(
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
fn append_relation_state_group(
  output : StringBuilder,
  left_state : RelationEndpointState,
  right_state : RelationEndpointState,
  style : String,
  dash : String,
  relation_color : String,
  background_color : String,
  relation : Relation,
) -> Unit {
  let visible_line = shorten_relation_path(
    relation_path([left_state.endpoint, right_state.endpoint]),
    relation.left_end.decoration_length(),
    relation.right_end.decoration_length(),
  ).pairs()
  output <+
    $|<line x1="\{visible_line[0].0}" y1="\{visible_line[0].1}" x2="\{visible_line[1].0}" y2="\{visible_line[1].1}" class="relation"\{style}\{dash}/>
  append_relation_decoration(
    output,
    relation.left_end,
    left_state.endpoint,
    right_state.endpoint,
    relation_color,
    background_color,
    side=left_state.side,
  )
  append_relation_decoration(
    output,
    relation.right_end,
    right_state.endpoint,
    left_state.endpoint,
    relation_color,
    background_color,
    side=right_state.side,
  )
}

///|
fn append_relation_state_groups(
  output : StringBuilder,
  relation_index : Int,
  left_states : Array[RelationEndpointState],
  right_states : Array[RelationEndpointState],
  style : String,
  dash : String,
  relation_color : String,
  background_color : String,
  edge? : @graphviz.GraphvizEdge? = None,
  relation : Relation,
) -> Unit {
  let wrapped = left_states.length() > 1 || right_states.length() > 1
  if wrapped {
    output <+
      $|<g class="edge" data-edge-index="\{relation_index}">
  }
  for left_bit, left_state in left_states {
    for right_bit, right_state in right_states {
      if wrapped {
        output <+
          $|<g class="edge-state edge-state-\{left_bit}\{right_bit}">
      }
      match edge {
        Some(edge) =>
          append_relation_edge_state(
            output, edge, relation, left_state, right_state, style, dash, relation_color,
            background_color,
          )
        None =>
          append_relation_state_group(
            output, left_state, right_state, style, dash, relation_color, background_color,
            relation,
          )
      }
      if wrapped {
        output.write_string("</g>\n")
      }
    }
  }
  if wrapped {
    output.write_string("</g>\n")
  }
}

///|
/// CSS that switches each relation edge to its closed variant when an attached
/// class node collapses its members. Every emitted state group gets exactly
/// one activating rule, chaining one `:has()` condition per collapsible
/// endpoint (nested `:has()` is not supported by browsers), so exactly one
/// state is visible at a time without runtime code.
fn collapsible_relation_style(
  diagram : EntityDiagram,
  layout : ClassLayout,
  text_metrics : ClassTextMetrics,
  class_member_collapsible : Bool,
) -> String {
  guard class_member_collapsible else { return "" }
  let output = StringBuilder()
  output.write_string("g[data-edge-index] > .edge-state{display:none}\n")
  for relation_index, relation in diagram.relations {
    guard entity_index(diagram, relation.left) is Some(left_index) else {
      continue
    }
    guard entity_index(diagram, relation.right) is Some(right_index) else {
      continue
    }
    let left = diagram.entities[left_index]
    let right = diagram.entities[right_index]
    guard !left.is_removed && !right.is_removed else { continue }
    let left_collapsible = relation_endpoint_header(
        layout, diagram, left_index, text_metrics, class_member_collapsible,
      )
      is Some(_)
    let right_collapsible = relation_endpoint_header(
        layout, diagram, right_index, text_metrics, class_member_collapsible,
      )
      is Some(_)
    let left_limit = if left_collapsible { 2 } else { 1 }
    let right_limit = if right_collapsible { 2 } else { 1 }
    for left_bit in 0..<left_limit {
      for right_bit in 0..<right_limit {
        output.write_string(
          relation_state_css(
            left_index,
            right_index,
            relation_index,
            left_bit,
            right_bit,
            left_collapsible,
            right_collapsible,
            relation.url is Some(_),
          ),
        )
      }
    }
  }
  output.to_string()
}

///|
fn relation_state_css(
  left_index : Int,
  right_index : Int,
  relation_index : Int,
  left_bit : Int,
  right_bit : Int,
  left_collapsible : Bool,
  right_collapsible : Bool,
  has_url : Bool,
) -> String {
  let condition = fn(index : Int, bit : Int, collapsible : Bool) -> String {
    guard collapsible else { return "" }
    if bit == 1 {
      ":has(.class-node[data-node-index=\"\{index}\"] details:not([open]))"
    } else {
      ":has(.class-node[data-node-index=\"\{index}\"] details[open])"
    }
  }
  let edge_prefix = if has_url { "a > " } else { "" }
  "svg\{condition(left_index, left_bit, left_collapsible)}\{condition(right_index, right_bit, right_collapsible)} > \{edge_prefix}g[data-edge-index=\"\{relation_index}\"] > .edge-state-\{left_bit}\{right_bit}{display:block}\n"
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
  output : StringBuilder,
  relation : Relation,
  left_endpoint : (Double, Double),
  right_endpoint : (Double, Double),
  text_metrics : ClassTextMetrics,
) -> Unit {
  let font_size = text_metrics.relation_end_regular.font_size
  let font_family = text_metrics.relation_end_font_family
  match relation.left_qualifier {
    Some(qualifier) => {
      let metrics = text_metrics.relation_end_regular.measure(qualifier)
      let x = left_endpoint.0 - metrics.width.to_double() - 6.0
      output.write_string(
        @svg.text_markup(
          x,
          left_endpoint.1 + metrics.ascent.to_double(),
          qualifier,
          [
            ("class", "relation-qualifier"),
            ("font-family", font_family),
            ("font-size", font_size.to_string()),
          ],
          text_metrics.relation_end_regular,
        ),
      )
      output.write_char('\n')
    }
    None => ()
  }
  match relation.right_qualifier {
    Some(qualifier) => {
      let metrics = text_metrics.relation_end_regular.measure(qualifier)
      let x = right_endpoint.0 + 6.0
      output.write_string(
        @svg.text_markup(
          x,
          right_endpoint.1 - metrics.ascent.to_double(),
          qualifier,
          [
            ("class", "relation-qualifier"),
            ("font-family", font_family),
            ("font-size", font_size.to_string()),
          ],
          text_metrics.relation_end_regular,
        ),
      )
      output.write_char('\n')
    }
    None => ()
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
  class_member_collapsible : Bool,
) -> Unit {
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
  let edge_endpoints = match layout.graphviz {
    Some(graphviz) => {
      let mut endpoints : ((Double, Double), (Double, Double))? = None
      for edge in graphviz.edges {
        if edge.index == relation_index {
          endpoints = relation_edge_endpoints(edge)
        }
      }
      endpoints
    }
    None => None
  }
  let (left_endpoint, right_endpoint) = edge_endpoints.unwrap_or(
    ((x1, y1), (x2, y2)),
  )
  match relation.url {
    Some(url) =>
      output <+
        $|<a href="\{@svg.xml_escape(url)}">
    None => ()
  }
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
              let left_header = match left_index {
                Some(index) =>
                  relation_endpoint_header(
                    layout, diagram, index, text_metrics, class_member_collapsible,
                  )
                None => None
              }
              let right_header = match right_index {
                Some(index) =>
                  relation_endpoint_header(
                    layout, diagram, index, text_metrics, class_member_collapsible,
                  )
                None => None
              }
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
              let left_states = relation_endpoint_states(
                left_contact
                .map(value => value.point.pair())
                .unwrap_or(first_path[0]),
                left_contact.map(value => value.side),
                left_header,
              )
              let right_states = relation_endpoint_states(
                right_contact
                .map(value => value.point.pair())
                .unwrap_or(last_path[last_path.length() - 1]),
                right_contact.map(value => value.side),
                right_header,
              )
              drew_spline = true
              append_relation_state_groups(
                output,
                relation_index,
                left_states,
                right_states,
                style,
                dash,
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
    let left_header = match left_index {
      Some(index) =>
        relation_endpoint_header(
          layout, diagram, index, text_metrics, class_member_collapsible,
        )
      None => None
    }
    let right_header = match right_index {
      Some(index) =>
        relation_endpoint_header(
          layout, diagram, index, text_metrics, class_member_collapsible,
        )
      None => None
    }
    let left_states = relation_endpoint_states((x1, y1), None, left_header)
    let right_states = relation_endpoint_states((x2, y2), None, right_header)
    append_relation_state_groups(
      output,
      relation_index,
      left_states,
      right_states,
      style,
      dash,
      relation_color,
      background_color,
      edge=None,
      relation,
    )
  }
  match relation_label_layout.label {
    Some(text_box) => {
      let x = if usecase {
        text_box.x + text_box.width / 2.0
      } else {
        text_box.x
      }
      let attributes = [
        ("class", "relation-label"),
        ("fill", label_color),
        ("font-family", label_font_family),
        ("font-size", label_font_size.to_string()),
        ..if !usecase {
          [("text-anchor", "start")]
        },
      ]
      output.write_string(
        @svg.text_markup(
          x,
          text_box.baseline,
          text_box.text,
          attributes,
          text_metrics.relation_label_regular,
        ),
      )
      output.write_char('\n')
    }
    None => ()
  }
  let end_label_font_size = text_metrics.relation_end_regular.font_size
  let end_label_font_family = text_metrics.relation_end_font_family
  for text_box in relation_label_layout.end_boxes() {
    output.write_string(
      @svg.text_markup(
        text_box.x,
        text_box.baseline,
        text_box.text,
        [
          ("class", "relation-end-label"),
          ("font-family", end_label_font_family),
          ("font-size", end_label_font_size.to_string()),
        ],
        text_metrics.relation_end_regular,
      ),
    )
    output.write_char('\n')
  }
  append_relation_qualifiers(
    output, relation, left_endpoint, right_endpoint, text_metrics,
  )
  match relation.url {
    Some(_) => output.write_string("</a>\n")
    None => ()
  }
}
