///|
fn append_packages(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for package_layout in graphviz.packages {
        guard package_layout.package_index < diagram.packages.length() else {
          continue
        }
        let group = diagram.packages[package_layout.package_index]
        let fill = @svg.svg_color(
          group.color,
          diagram.style.package_background_color(),
        )
        let tab_width = text_metrics.regular.measure(group.display).width.to_double() +
          18.0
        let x = package_layout.x
        let y = package_layout.y
        let right = x + package_layout.width
        let bottom = y + package_layout.height
        let border_color = diagram.style.package_border_color()
        output <+
          $|<g class="package">
          $|<path d="M \{x + 2.5} \{y} L \{x + tab_width - 9.0} \{y} Q \{x + tab_width - 6.5} \{y} \{x + tab_width - 5.5} \{y + 2.5} L \{x + tab_width + 1.5} \{y + 22.0} L \{right - 2.5} \{y + 22.0} Q \{right} \{y + 22.0} \{right} \{y + 24.5} L \{right} \{bottom - 2.5} Q \{right} \{bottom} \{right - 2.5} \{bottom} L \{x + 2.5} \{bottom} Q \{x} \{bottom} \{x} \{bottom - 2.5} L \{x} \{y + 2.5} Q \{x} \{y} \{x + 2.5} \{y}" fill="\{fill}" style="stroke:\{border_color}"/>
          $|<line x1="\{x}" y1="\{y + 22.0}" x2="\{x + tab_width + 1.5}" y2="\{y + 22.0}" style="stroke:\{border_color}"/>
          $|<text x="\{x + 4.0}" y="\{y + 16.0}" class="package-title">\{@svg.xml_escape(group.display)}</text></g>
      }
    None => ()
  }
}

///|
const NOTE_CORNER_SIZE : Double = 10.0

///|
const NOTE_POINTER_DELTA : Double = 4.0

///|
const NOTE_GEOMETRY_EPSILON : Double = 0.0001

///|
priv enum NoteOpaleStrategy {
  OpaleLeft
  OpaleRight
  OpaleUp
  OpaleDown
}

///|
priv struct NoteOpaleAttachment {
  strategy : NoteOpaleStrategy
  note_point : (Double, Double)
  target_point : (Double, Double)
}

///|
fn GraphvizLayout::note_edge(
  self : GraphvizLayout,
  note_index : Int,
) -> @graphviz.GraphvizEdge? {
  for edge in self.note_edges {
    if edge.index == note_index {
      return Some(edge)
    }
  }
  None
}

///|
fn GraphvizLayout::node(
  self : GraphvizLayout,
  code : String,
) -> GraphvizNodeLayout? {
  for node in self.nodes {
    if node.code == code {
      return Some(node)
    }
  }
  None
}

///|
fn point_distance_squared(
  first : (Double, Double),
  second : (Double, Double),
) -> Double {
  let dx = first.0 - second.0
  let dy = first.1 - second.1
  dx * dx + dy * dy
}

///|
fn keep_nearest_nonnegative(current : Double?, candidate : Double) -> Double? {
  guard candidate >= -NOTE_GEOMETRY_EPSILON else { return current }
  let candidate = candidate.max(0.0)
  match current {
    Some(previous) if previous <= candidate => current
    _ => Some(candidate)
  }
}

///|
fn clip_ray_to_rect(
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  center : (Double, Double),
  width : Double,
  height : Double,
) -> (Double, Double) {
  let left = center.0 - width / 2.0
  let right = center.0 + width / 2.0
  let top = center.1 - height / 2.0
  let bottom = center.1 + height / 2.0
  let inside = endpoint.0 >= left - NOTE_GEOMETRY_EPSILON &&
    endpoint.0 <= right + NOTE_GEOMETRY_EPSILON &&
    endpoint.1 >= top - NOTE_GEOMETRY_EPSILON &&
    endpoint.1 <= bottom + NOTE_GEOMETRY_EPSILON
  let (dx, dy) = if inside {
    (adjacent.0 - endpoint.0, adjacent.1 - endpoint.1)
  } else {
    (endpoint.0 - adjacent.0, endpoint.1 - adjacent.1)
  }
  guard dx != 0.0 || dy != 0.0 else { return endpoint }
  let mut best : Double? = None
  if dx != 0.0 {
    for side in [left, right] {
      let t = (side - endpoint.0) / dx
      let y = endpoint.1 + t * dy
      if y >= top - NOTE_GEOMETRY_EPSILON && y <= bottom + NOTE_GEOMETRY_EPSILON {
        best = keep_nearest_nonnegative(best, t)
      }
    }
  }
  if dy != 0.0 {
    for side in [top, bottom] {
      let t = (side - endpoint.1) / dy
      let x = endpoint.0 + t * dx
      if x >= left - NOTE_GEOMETRY_EPSILON && x <= right + NOTE_GEOMETRY_EPSILON {
        best = keep_nearest_nonnegative(best, t)
      }
    }
  }
  match best {
    Some(t) => (endpoint.0 + t * dx, endpoint.1 + t * dy)
    None => endpoint
  }
}

///|
fn clip_ray_to_ellipse(
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  center : (Double, Double),
  width : Double,
  height : Double,
) -> (Double, Double) {
  let radius_x = width / 2.0
  let radius_y = height / 2.0
  guard radius_x > 0.0 && radius_y > 0.0 else { return endpoint }
  let px = endpoint.0 - center.0
  let py = endpoint.1 - center.1
  let normalized = px * px / (radius_x * radius_x) +
    py * py / (radius_y * radius_y)
  let inside = normalized <= 1.0 + NOTE_GEOMETRY_EPSILON
  let (dx, dy) = if inside {
    (adjacent.0 - endpoint.0, adjacent.1 - endpoint.1)
  } else {
    (endpoint.0 - adjacent.0, endpoint.1 - adjacent.1)
  }
  let a = dx * dx / (radius_x * radius_x) + dy * dy / (radius_y * radius_y)
  guard a > 0.0 else { return endpoint }
  let b = 2.0 *
    (px * dx / (radius_x * radius_x) + py * dy / (radius_y * radius_y))
  let c = px * px / (radius_x * radius_x) +
    py * py / (radius_y * radius_y) -
    1.0
  let discriminant = b * b - 4.0 * a * c
  guard discriminant >= 0.0 else { return endpoint }
  let root = discriminant.sqrt()
  let first = (-b - root) / (2.0 * a)
  let second = (-b + root) / (2.0 * a)
  let best = keep_nearest_nonnegative(
    keep_nearest_nonnegative(None, first),
    second,
  )
  match best {
    Some(t) => (endpoint.0 + t * dx, endpoint.1 + t * dy)
    None => endpoint
  }
}

///|
fn clip_ray_to_node(
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  node : GraphvizNodeLayout,
  shape : NodeShape,
) -> (Double, Double) {
  match shape {
    Box =>
      clip_ray_to_rect(
        endpoint,
        adjacent,
        (node.x, node.y),
        node.width,
        node.height,
      )
    Ellipse =>
      clip_ray_to_ellipse(
        endpoint,
        adjacent,
        (node.x, node.y),
        node.width,
        node.height,
      )
  }
}

///|
/// Mirrors `EntityImageNote`: orient the routed edge so its first endpoint is
/// the one attached to the note, then select the nearest note boundary.
fn note_opale_attachment(
  note : @graphviz.GraphvizNote,
  edge : @graphviz.GraphvizEdge,
  target : GraphvizNodeLayout,
  target_shape : NodeShape,
) -> NoteOpaleAttachment? {
  let center = (note.x, note.y)
  for spline in edge.splines {
    let path = spline.points
    guard path.length() > 0 else { continue }
    let first = match spline.arrow_start {
      Some(point) => point
      None => path[0]
    }
    let last = match spline.arrow_end {
      Some(point) => point
      None => path[path.length() - 1]
    }
    let first_adjacent = match spline.arrow_start {
      Some(_) => path[0]
      None => if path.length() > 1 { path[1] } else { last }
    }
    let last_adjacent = match spline.arrow_end {
      Some(_) => path[path.length() - 1]
      None => if path.length() > 1 { path[path.length() - 2] } else { first }
    }
    let (raw_note_point, note_adjacent, raw_target_point, target_adjacent) = if point_distance_squared(
        first, center,
      ) <=
      point_distance_squared(last, center) {
      (first, first_adjacent, last, last_adjacent)
    } else {
      (last, last_adjacent, first, first_adjacent)
    }
    let note_point = clip_ray_to_rect(
      raw_note_point,
      note_adjacent,
      center,
      note.width,
      note.height,
    )
    let target_point = clip_ray_to_node(
      raw_target_point, target_adjacent, target, target_shape,
    )
    let left = note.x - note.width / 2.0
    let right = note.x + note.width / 2.0
    let top = note.y - note.height / 2.0
    let bottom = note.y + note.height / 2.0
    let distance_left = (note_point.0 - left).abs()
    let distance_right = (note_point.0 - right).abs()
    let distance_top = (note_point.1 - top).abs()
    let distance_bottom = (note_point.1 - bottom).abs()
    let strategy = if distance_left <= distance_right &&
      distance_left <= distance_top &&
      distance_left <= distance_bottom {
      OpaleLeft
    } else if distance_right <= distance_top &&
      distance_right <= distance_bottom {
      OpaleRight
    } else if distance_top <= distance_bottom {
      OpaleUp
    } else {
      OpaleDown
    }
    return Some({ strategy, note_point, target_point })
  }
  None
}

///|
fn clamp_double(value : Double, lower : Double, upper : Double) -> Double {
  value.max(lower).min(upper)
}

///|
fn normal_note_path(note : @graphviz.GraphvizNote) -> String {
  let x = note.x - note.width / 2.0
  let y = note.y - note.height / 2.0
  let right = x + note.width
  let bottom = y + note.height
  (
    $|M \{x} \{y} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
  )
}

///|
/// Mirrors `Opale.getCorner` for PlantUML's default zero-rounding geometry.
fn note_corner_path(note : @graphviz.GraphvizNote) -> String {
  let x = note.x - note.width / 2.0
  let y = note.y - note.height / 2.0
  let right = x + note.width
  (
    $|M \{right - NOTE_CORNER_SIZE} \{y} L \{right - NOTE_CORNER_SIZE} \{y + NOTE_CORNER_SIZE} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
  )
}

///|
/// Mirrors the four `Opale.getPolygon*` paths with PlantUML's zero-rounding
/// geometry. The pointer tip is the routed edge endpoint on the target.
fn opale_note_path(
  note : @graphviz.GraphvizNote,
  attachment : NoteOpaleAttachment,
) -> String {
  let x = note.x - note.width / 2.0
  let y = note.y - note.height / 2.0
  let right = x + note.width
  let bottom = y + note.height
  let tip = attachment.target_point
  match attachment.strategy {
    OpaleLeft => {
      let base = clamp_double(
        attachment.note_point.1 - NOTE_POINTER_DELTA,
        y,
        bottom - 2.0 * NOTE_POINTER_DELTA,
      )
      (
        $|M \{x} \{y} L \{x} \{base} L \{tip.0} \{tip.1} L \{x} \{base + 2.0 * NOTE_POINTER_DELTA} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
      )
    }
    OpaleRight => {
      let base = clamp_double(
        attachment.note_point.1 - NOTE_POINTER_DELTA,
        y + NOTE_CORNER_SIZE,
        bottom - 2.0 * NOTE_POINTER_DELTA,
      )
      (
        $|M \{x} \{y} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{base + 2.0 * NOTE_POINTER_DELTA} L \{tip.0} \{tip.1} L \{right} \{base} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
      )
    }
    OpaleUp => {
      let base = clamp_double(
        attachment.note_point.0 - NOTE_POINTER_DELTA,
        x,
        right - NOTE_CORNER_SIZE,
      )
      (
        $|M \{x} \{y} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} L \{base + 2.0 * NOTE_POINTER_DELTA} \{y} L \{tip.0} \{tip.1} L \{base} \{y} Z
      )
    }
    OpaleDown => {
      let base = clamp_double(
        attachment.note_point.0 - NOTE_POINTER_DELTA,
        x,
        right,
      )
      (
        $|M \{x} \{y} L \{x} \{bottom} L \{base} \{bottom} L \{tip.0} \{tip.1} L \{base + 2.0 * NOTE_POINTER_DELTA} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
      )
    }
  }
}

///|
fn append_notes(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for note_layout in graphviz.notes {
        guard note_layout.note_index < diagram.notes.length() else { continue }
        let note = diagram.notes[note_layout.note_index]
        let x = note_layout.x - note_layout.width / 2.0
        let y = note_layout.y - note_layout.height / 2.0
        let fill = @svg.svg_color(
          note.color,
          diagram.style.note_background_color(),
        )
        let mut path = normal_note_path(note_layout)
        let corner_path = note_corner_path(note_layout)
        let mut path_class = ""
        if note.target_kind is EntityNote || note.target_kind is MemberTip {
          match graphviz.note_edge(note_layout.note_index) {
            Some(edge) =>
              match (graphviz.node(note.target), diagram.entity(note.target)) {
                (Some(target), Some(entity)) => {
                  let target_shape = entity.node_geometry(
                      text_metrics,
                      diagram.family,
                    ).shape
                  match
                    note_opale_attachment(
                      note_layout, edge, target, target_shape,
                    ) {
                    Some(attachment) => {
                      path = opale_note_path(note_layout, attachment)
                      path_class = " class=\"note-opale-link\""
                    }
                    None => ()
                  }
                }
                _ => ()
              }
            None => ()
          }
        }
        output <+
          $|<g class="class-note" style="stroke:\{diagram.style.note_border_color()}"><path d="\{path}"\{path_class} fill="\{fill}"/><path d="\{corner_path}" fill="\{fill}"/></g>
        for line_index, line in note.text.split("\n") {
          output <+
            $|<text x="\{x + NOTE_LEFT_PADDING.to_double()}" y="\{y + NOTE_VERTICAL_PADDING.to_double() + text_metrics.note.ascent.to_double() + line_index.to_double() * text_metrics.note.line_height.to_double()}" class="note-text">\{@svg.xml_escape(line.to_owned())}</text>
        }
      }
    None => ()
  }
}

///|
fn ClassLayout::node_y(self : ClassLayout, index : Int) -> Int {
  24 + index / self.columns * self.cell_height
}

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

///|
fn append_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let header = entity.header_layout(text_metrics)
  let body = entity.body_layout(text_metrics)
  let row_height = text_metrics.row_height()
  let fill = @svg.svg_color(
    entity.color,
    diagram.style.class_background_color(),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    diagram.style.class_border_color(),
  )
  let stroke_style = @svg.stroke_style(entity.line_style)
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let title_style = match entity.kind {
    AbstractClass | Interface => " font-style=\"italic\""
    _ => ""
  }
  let (spot_text, spot_fill) = entity.spot()
  let placement = header.placement(width)
  output <+
    $|<g class="class-node" data-code="\{@svg.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}"\{line_attributes}/>
  match placement.circle_center {
    Some((circle_cx, circle_cy)) =>
      output <+
        $|<circle cx="\{x + circle_cx}" cy="\{y + circle_cy}" r="\{CLASS_SPOT_RADIUS}" fill="\{spot_fill}" stroke="\{diagram.style.diagram_line_color()}" stroke-width="1"/><text x="\{x + circle_cx}" y="\{y + circle_cy + 4}" class="class-spot">\{spot_text}</text>
    None => ()
  }
  match (header.stereotype, placement.stereotype_position) {
    (Some(stereotype), Some((stereotype_x, stereotype_baseline))) =>
      output <+
        $|<text x="\{x + stereotype_x}" y="\{y + stereotype_baseline}" class="class-stereotype" fill="\{diagram.style.class_stereotype_font_color()}" font-family="\{@svg.xml_escape(text_metrics.class_stereotype_font_family)}" font-size="\{text_metrics.class_stereotype.font_size}">\{@svg.xml_escape(stereotype)}</text>
    _ => ()
  }
  output <+
    $|<text x="\{x + placement.title_x}" y="\{y + placement.title_baseline}" class="class-title"\{title_style}>\{@svg.xml_escape(entity.display)}</text>
  let mut section_y = y + header.height
  for section_index, section in [body.fields, body.methods] {
    let section_height = if section_index == 0 {
      body.fields_height
    } else {
      body.methods_height
    }
    output <+
      $|<line x1="\{x}" y1="\{section_y}" x2="\{x + width}" y2="\{section_y}"\{line_attributes}/>
    for member_index, entry in section {
      let member_y = section_y + (member_index + 1) * row_height + 1
      output <+
        $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y)}</g><text x="\{x + entry.member_text_x()}" y="\{member_y}" class="member">\{@svg.xml_escape(entry.display_without_visibility())}</text>
    }
    section_y += section_height
  }
  output.write_string("</g>\n")
}

///|
fn append_usecase_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let (background, border) = match entity.kind {
    Usecase | BusinessUsecase =>
      (
        diagram.style.usecase_background_color(),
        diagram.style.usecase_border_color(),
      )
    Actor | BusinessActor =>
      (
        diagram.style.actor_background_color(),
        diagram.style.actor_border_color(),
      )
    _ =>
      (
        diagram.style.class_background_color(),
        diagram.style.class_border_color(),
      )
  }
  let fill = @svg.svg_color(entity.color, background)
  let stroke = @svg.svg_color(entity.line_color, border)
  let text_color = match entity.kind {
    Usecase | BusinessUsecase => diagram.style.usecase_font_color()
    Actor | BusinessActor => diagram.style.actor_font_color()
    _ => diagram.style.diagram_text_color()
  }
  let line_attributes = @svg.stroke_style(entity.line_style)
  match entity.kind {
    Usecase | BusinessUsecase | Actor | BusinessActor | Component => ()
    _ => {
      append_entity(output, diagram, entity, index, text_metrics, layout)
      return
    }
  }
  let node_class = match entity.kind {
    Usecase | BusinessUsecase => "usecase-node"
    Actor | BusinessActor => "actor-node"
    Component => "component-node"
    _ => ""
  }
  output <+
    $|<g class="\{node_class}" data-code="\{@svg.xml_escape(entity.qualified_code)}">
  match entity.url {
    Some(url) =>
      output <+
        $|<a href="\{@svg.xml_escape(url)}">
    None => ()
  }
  match entity.kind {
    Usecase | BusinessUsecase => {
      let (_, content_height, stereotype) = entity.usecase_content_layout(
        text_metrics,
      )
      // TextBlockInEllipse centers the text block, then applies dy - 2.
      // The ellipse itself has grown by 6px, so SVG text needs a +2px
      // top offset before converting its font ascent to a baseline.
      let content_top = y + height / 2 - content_height / 2 + 2
      let title_metrics = text_metrics.usecase_regular.measure(entity.display)
      output <+
        $|<ellipse cx="\{x + width / 2}" cy="\{y + height / 2}" rx="\{width / 2}" ry="\{height / 2}" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
      match stereotype {
        Some(value) => {
          let metrics = text_metrics.usecase_italic.measure(value)
          output <+
            $|<text x="\{x + width / 2}" y="\{content_top + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_italic.font_size}">\{@svg.xml_escape(value)}</text>
        }
        None => ()
      }
      let title_y = match stereotype {
        Some(value) =>
          content_top +
          text_metrics.usecase_italic.measure(value).height +
          title_metrics.baseline
        None => content_top + title_metrics.baseline
      }
      output <+
        $|<text x="\{x + width / 2}" y="\{title_y}" class="usecase-title" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_regular.font_size}">\{@svg.xml_escape(entity.display)}</text>
      if entity.kind is BusinessUsecase {
        let (mark_start, mark_end) = usecase_business_mark(x, y, width, height)
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="usecase-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Actor | BusinessActor => {
      let center_x = x + width / 2
      let title = text_metrics.actor_regular.measure(entity.display)
      let (_, _, stereotype) = entity.actor_content_layout(text_metrics)
      let appearance = actor_appearance(text_metrics.actor_style)
      let (figure_width, figure_height) = actor_figure_geometry(
        appearance,
        business=entity.kind is BusinessActor,
      )
      let stereotype_height = match stereotype {
        Some(value) => text_metrics.actor_italic.measure(value).height
        None => 0
      }
      let figure_top = y + stereotype_height
      let label_y = figure_top + figure_height + title.baseline
      match stereotype {
        Some(value) => {
          let metrics = text_metrics.actor_italic.measure(value)
          output <+
            $|<text x="\{center_x}" y="\{y + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_italic.font_size}">\{@svg.xml_escape(value)}</text>
        }
        None => ()
      }
      if entity.kind is Actor {
        match appearance {
          Awesome =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 17}" r="16" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 27} \{figure_top + 50} Q \{center_x} \{figure_top + 38} \{center_x + 27} \{figure_top + 50} V \{figure_top + 62} Q \{center_x + 27} \{figure_top + 62} \{center_x + 19} \{figure_top + 62} H \{center_x - 19} Q \{center_x - 27} \{figure_top + 62} \{center_x - 27} \{figure_top + 54} Z" class="actor-awesome-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Hollow =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 5}" r="4" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 13} \{figure_top + 12} H \{center_x + 13} V \{figure_top + 17} H \{center_x + 3} V \{figure_top + 27} L \{center_x + 9} \{figure_top + 35} H \{center_x + 3} L \{center_x} \{figure_top + 30} L \{center_x - 3} \{figure_top + 35} H \{center_x - 9} L \{center_x - 3} \{figure_top + 27} V \{figure_top + 17} H \{center_x - 13} Z" class="actor-hollow-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Stickman => ()
        }
      }
      if entity.kind is BusinessActor || appearance is Stickman {
        output <+
          $|<circle cx="\{center_x}" cy="\{figure_top + 9}" r="8" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x} \{figure_top + 17} L \{center_x} \{figure_top + 43} M \{center_x - 13} \{figure_top + 27} L \{center_x + 13} \{figure_top + 27} M \{center_x} \{figure_top + 43} L \{center_x - 13} \{figure_top + figure_height} M \{center_x} \{figure_top + 43} L \{center_x + 13} \{figure_top + figure_height}" fill="none" stroke="\{stroke}" style="\{line_attributes}"/>
      }
      output <+
        $|<text x="\{center_x}" y="\{label_y}" class="usecase-title" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_regular.font_size}">\{@svg.xml_escape(entity.display)}</text>
      if entity.kind is BusinessActor && figure_width == ACTOR_FIGURE_WIDTH {
        let (mark_start, mark_end) = actor_business_mark(
          center_x,
          figure_top + 9,
          8,
        )
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="actor-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Component => {
      let title = text_metrics.regular.measure(entity.display)
      let tab_x = x + width - COMPONENT_TAB_WIDTH - COMPONENT_TAB_INSET
      let tab_y = y + COMPONENT_TAB_INSET
      let mark_x = tab_x - COMPONENT_TAB_MARK_LEFT_OFFSET
      let first_mark_y = tab_y + COMPONENT_TAB_MARK_TOP_OFFSET
      let second_mark_y = first_mark_y + COMPONENT_TAB_MARK_GAP
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2" ry="2" class="component-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{tab_x}" y="\{tab_y}" width="\{COMPONENT_TAB_WIDTH}" height="\{COMPONENT_TAB_HEIGHT}" class="component-tab" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{first_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{second_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><text x="\{x + width / 2}" y="\{y + (height + title.height) / 2 - 2}" class="usecase-title" fill="\{text_color}">\{@svg.xml_escape(entity.display)}</text>
    }
    _ => ()
  }
  match entity.url {
    Some(_) => output.write_string("</a>")
    None => ()
  }
  output.write_string("</g>\n")
}

///|
