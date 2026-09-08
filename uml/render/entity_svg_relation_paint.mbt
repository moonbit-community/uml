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
    append_relation_decoration_primitive(output, primitive, color, background)
  }
}

///|
/// One possible anchor for a relation endpoint: the open state sits on the
/// full node boundary, while the closed state re-anchors onto the visible
/// bounds of a collapsed class node.
priv struct RelationEndpointState {
  endpoint : (Double, Double)
  side : RelationContactSide?
}

///|
/// Visible rectangles for every disclosure combination of a collapsible class
/// node. The first state is always the open/full boundary; subsequent states
/// replace each closed section with its retained `...` row.
fn relation_endpoint_closed_bounds(
  layout : ClassLayout,
  diagram : @entity.EntityDiagram,
  index : Int,
  text_metrics : ClassTextMetrics,
  member_collapse : ClassMemberCollapse,
) -> Array[Rect?] {
  let entity = diagram.entities[index]
  guard entity.render_capability(diagram.family).renderer is ClassRenderer else {
    return []
  }
  guard !entity.is_hidden && !entity.is_removed else { return [] }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let body = entity.body_layout(text_metrics, diagram.family)
  let header = entity.header_layout(text_metrics, diagram.family)
  guard member_collapse.is_collapsible(body) else { return [] }
  let masks = member_collapse.section_masks(body)
  let row_height = text_metrics.row_height()
  let bounds : Array[Rect?] = []
  for mask in masks {
    if mask == 0 {
      bounds.push(None)
    } else {
      let visible_height = header.height +
        member_collapse.visible_body_height(body, row_height, mask)
      if header.height > 0 && visible_height < height {
        let center_y = y.to_double() + visible_height.to_double() / 2.0
        bounds.push(
          Some(
            rect(
              point(x.to_double() + width.to_double() / 2.0, center_y),
              width.to_double(),
              visible_height.to_double(),
            ),
          ),
        )
      } else {
        bounds.push(None)
      }
    }
  }
  bounds
}

///|
/// @entity.Relation endpoint alternatives for one side: always the open boundary
/// contact, plus the closed visible-bounds contact when the attached node is
/// collapsible. The closed endpoint is clipped along the original route ray,
/// preserving the edge's approach direction.
fn relation_endpoint_states(
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  side : RelationContactSide?,
  closed_bounds : Array[Rect?],
) -> Array[RelationEndpointState] {
  if closed_bounds.is_empty() {
    return [{ endpoint, side, }]
  }
  let states : Array[RelationEndpointState] = []
  for _state_id, bounds in closed_bounds {
    match bounds {
      Some(bounds) => {
        // Preserve the routed tangent when moving the endpoint to the closed
        // node boundary instead of snapping it to an edge midpoint.
        let closed_endpoint = clip_toward_rect(
          point_from_pair(endpoint),
          point_from_pair(adjacent),
          bounds,
        )
        let closed_side = rect_contact_side(closed_endpoint, bounds)
        states.push({
          endpoint: closed_endpoint.pair(),
          side: Some(closed_side),
        })
      }
      None => states.push({ endpoint, side, })
    }
  }
  states
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
  relation : @entity.Relation,
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
  relation : @entity.Relation,
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
  relation : @entity.Relation,
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
  diagram : @entity.EntityDiagram,
  layout : ClassLayout,
  text_metrics : ClassTextMetrics,
  member_collapse : ClassMemberCollapse,
) -> String {
  guard member_collapse.enabled else { return "" }
  let output = StringBuilder()
  output.write_string("g[data-edge-index] > .edge-state{display:none}\n")
  for relation_index, relation in diagram.relations {
    output.write_string(
      collapsible_edge_css(
        diagram,
        layout,
        text_metrics,
        member_collapse,
        relation_index,
        entity_index(diagram, relation.left),
        entity_index(diagram, relation.right),
        relation.url is Some(_),
      ),
    )
  }
  if layout.mindmap is Some(mindmap) {
    for structure_index, edge in mindmap.structure_edges {
      output.write_string(
        collapsible_edge_css(
          diagram,
          layout,
          text_metrics,
          member_collapse,
          -1 - structure_index,
          Some(edge.parent_entity),
          Some(edge.child_entity),
          false,
        ),
      )
    }
  }
  output.to_string()
}

///|
/// The CSS that switches one edge to its closed variant when an attached
/// class node collapses. A `None` endpoint (not an entity, e.g. a package)
/// is never collapsible.
fn collapsible_edge_css(
  diagram : @entity.EntityDiagram,
  layout : ClassLayout,
  text_metrics : ClassTextMetrics,
  member_collapse : ClassMemberCollapse,
  edge_index : Int,
  left_entity : Int?,
  right_entity : Int?,
  has_url : Bool,
) -> String {
  let left_masks = left_entity.map_or([], index => {
    relation_endpoint_closed_bounds(
      layout, diagram, index, text_metrics, member_collapse,
    )
  })
  let right_masks = right_entity.map_or([], index => {
    relation_endpoint_closed_bounds(
      layout, diagram, index, text_metrics, member_collapse,
    )
  })
  let left_collapsible = left_masks.length() > 1
  let right_collapsible = right_masks.length() > 1
  let left_state_masks = left_entity.map_or([], index => {
    member_collapse.section_masks(
      diagram.entities[index].body_layout(text_metrics, diagram.family),
    )
  })
  let right_state_masks = right_entity.map_or([], index => {
    member_collapse.section_masks(
      diagram.entities[index].body_layout(text_metrics, diagram.family),
    )
  })
  let left_sections = left_entity.map_or((false, false), index => {
    let body = diagram.entities[index].body_layout(text_metrics, diagram.family)
    (
      member_collapse.section_is_collapsible(body, Fields),
      member_collapse.section_is_collapsible(body, Methods),
    )
  })
  let right_sections = right_entity.map_or((false, false), index => {
    let body = diagram.entities[index].body_layout(text_metrics, diagram.family)
    (
      member_collapse.section_is_collapsible(body, Fields),
      member_collapse.section_is_collapsible(body, Methods),
    )
  })
  let left_index = left_entity.unwrap_or(-1)
  let right_index = right_entity.unwrap_or(-1)
  let left_limit = if left_collapsible { left_masks.length() } else { 1 }
  let right_limit = if right_collapsible { right_masks.length() } else { 1 }
  let out = StringBuilder()
  for left_bit in 0..<left_limit {
    for right_bit in 0..<right_limit {
      out.write_string(
        relation_state_css(
          left_index,
          right_index,
          edge_index,
          if left_collapsible {
            left_state_masks[left_bit]
          } else {
            0
          },
          if right_collapsible {
            right_state_masks[right_bit]
          } else {
            0
          },
          left_bit,
          right_bit,
          left_collapsible,
          right_collapsible,
          member_collapse.independent,
          left_sections,
          right_sections,
          has_url,
        ),
      )
    }
  }
  out.to_string()
}

///|
fn relation_state_css(
  left_index : Int,
  right_index : Int,
  relation_index : Int,
  left_mask : Int,
  right_mask : Int,
  left_state_id : Int,
  right_state_id : Int,
  left_collapsible : Bool,
  right_collapsible : Bool,
  independent : Bool,
  left_sections : (Bool, Bool),
  right_sections : (Bool, Bool),
  has_url : Bool,
) -> String {
  let condition = (
    index : Int,
    mask : Int,
    collapsible : Bool,
    sections : (Bool, Bool),
  ) => {
    guard collapsible else { return "" }
    if !independent {
      if mask == 1 {
        return ":has(.class-node[data-node-index=\"\{index}\"] details:not([open]))"
      } else {
        return ":has(.class-node[data-node-index=\"\{index}\"] details[open])"
      }
    }
    let fields = if sections.0 && mask % 2 == 1 {
      ":has(.class-node[data-node-index=\"\{index}\"] details.fields:not([open]))"
    } else if sections.0 {
      ":has(.class-node[data-node-index=\"\{index}\"] details.fields[open])"
    } else {
      ""
    }
    let methods = if sections.1 && mask / 2 % 2 == 1 {
      ":has(.class-node[data-node-index=\"\{index}\"] details.methods:not([open]))"
    } else if sections.1 {
      ":has(.class-node[data-node-index=\"\{index}\"] details.methods[open])"
    } else {
      ""
    }
    fields + methods
  }
  let edge_prefix = if has_url { "a > " } else { "" }
  "svg\{condition(left_index, left_mask, left_collapsible, left_sections)}\{condition(right_index, right_mask, right_collapsible, right_sections)} > \{edge_prefix}g[data-edge-index=\"\{relation_index}\"] > .edge-state-\{left_state_id}\{right_state_id}{display:block}\n"
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
  relation : @entity.Relation,
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
  diagram : @entity.EntityDiagram,
  relation_index : Int,
  relation : @entity.Relation,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  member_collapse : ClassMemberCollapse,
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
  let style =
    $| style="stroke:\{relation_color};\{relation_style}"
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
  if relation.url is Some(url) {
    output <+
      $|<a href="\{@svg.xml_escape(url)}">
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
              let left_header = left_index.map_or([], index => {
                relation_endpoint_closed_bounds(
                  layout, diagram, index, text_metrics, member_collapse,
                )
              })
              let right_header = right_index.map_or([], index => {
                relation_endpoint_closed_bounds(
                  layout, diagram, index, text_metrics, member_collapse,
                )
              })
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
                left_contact.map_or(first_path[0], value => value.point.pair()),
                if first_path.length() > 1 {
                  first_path[1]
                } else {
                  last_path[last_path.length() - 1]
                },
                left_contact.map(value => value.side),
                left_header,
              )
              let right_states = relation_endpoint_states(
                right_contact.map_or(last_path[last_path.length() - 1], value => {
                  value.point.pair()
                }),
                if last_path.length() > 1 {
                  last_path[last_path.length() - 2]
                } else {
                  first_path[0]
                },
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
    let left_header = left_index.map_or([], index => {
      relation_endpoint_closed_bounds(
        layout, diagram, index, text_metrics, member_collapse,
      )
    })
    let right_header = right_index.map_or([], index => {
      relation_endpoint_closed_bounds(
        layout, diagram, index, text_metrics, member_collapse,
      )
    })
    let left_states = relation_endpoint_states(
      (x1, y1),
      (x2, y2),
      None,
      left_header,
    )
    let right_states = relation_endpoint_states(
      (x2, y2),
      (x1, y1),
      None,
      right_header,
    )
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
  if relation.url is Some(_) {
    output.write_string("</a>\n")
  }
}
