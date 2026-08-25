///|
/// A relation label after Graphviz has supplied its anchor and the renderer
/// has resolved the actual text dimensions. Coordinates are SVG coordinates;
/// `x` and `y` are the top-left corner and `baseline` is the text baseline.
pub struct RelationTextBox {
  text : String
  x : Double
  y : Double
  width : Double
  height : Double
  baseline : Double
} derive(Eq, Debug)

///|
pub extend RelationTextBox with Eq::{not_equal, equal}

///|
pub extend RelationTextBox with Debug::{to_repr}

///|
/// Final positions for every textual part of one class relation.
pub struct RelationLabelLayout {
  relation_index : Int
  label : RelationTextBox?
  left_cardinality : RelationTextBox?
  right_cardinality : RelationTextBox?
  left_role : RelationTextBox?
  right_role : RelationTextBox?
} derive(Eq, Debug)

///|
pub extend RelationLabelLayout with Eq::{not_equal, equal}

///|
pub extend RelationLabelLayout with Debug::{to_repr}

///|
fn RelationLabelLayout::boxes(
  self : RelationLabelLayout,
) -> Array[RelationTextBox] {
  let boxes : Array[RelationTextBox] = []
  if self.label is Some(value) {
    boxes.push(value)
  }
  if self.left_cardinality is Some(value) {
    boxes.push(value)
  }
  if self.right_cardinality is Some(value) {
    boxes.push(value)
  }
  if self.left_role is Some(value) {
    boxes.push(value)
  }
  if self.right_role is Some(value) {
    boxes.push(value)
  }
  boxes
}

///|
fn RelationLabelLayout::end_boxes(
  self : RelationLabelLayout,
) -> Array[RelationTextBox] {
  [
    self.left_cardinality,
    self.right_cardinality,
    self.left_role,
    self.right_role,
  ].filter_map(box => box)
}

///|
priv enum RelationLabelKind {
  Label
  LeftCardinality
  RightCardinality
  LeftRole
  RightRole
} derive(Eq)

///|
priv struct RelationLabelEntry {
  kind : RelationLabelKind
  box : RelationTextBox
}

///|
fn relation_text_box_from_top_left(
  text : String,
  x : Double,
  y : Double,
  metrics : @metrics.FontMetrics,
) -> RelationTextBox {
  let measured = metrics.measure(text)
  {
    text,
    x,
    y,
    width: measured.width.to_double(),
    height: measured.height.to_double(),
    baseline: y + measured.baseline.to_double(),
  }
}

///|
/// Graphviz stores edge label positions at the centre of the label. Convert
/// that point into the top-left SVG text box used by the PlantUML painter.
fn relation_text_box_from_center(
  text : String,
  center : (Double, Double),
  metrics : @metrics.FontMetrics,
) -> RelationTextBox {
  let measured = metrics.measure(text)
  relation_text_box_from_top_left(
    text,
    center.0 - measured.width.to_double() / 2.0,
    center.1 - measured.height.to_double() / 2.0,
    metrics,
  )
}

///|
fn translate_relation_text_box(
  text_box : RelationTextBox,
  dx : Double,
  dy : Double,
) -> RelationTextBox {
  {
    ..text_box,
    x: text_box.x + dx,
    y: text_box.y + dy,
    baseline: text_box.baseline + dy,
  }
}

///|
fn relation_text_box_center(text_box : RelationTextBox) -> (Double, Double) {
  (text_box.x + text_box.width / 2.0, text_box.y + text_box.height / 2.0)
}

///|
fn relation_box_intersects_rect(
  text_box : RelationTextBox,
  rect : (Double, Double, Double, Double),
) -> Bool {
  let (x, y, width, height) = rect
  text_box.x < x + width &&
  text_box.x + text_box.width > x &&
  text_box.y < y + height &&
  text_box.y + text_box.height > y
}

///|
/// Move a label by the smallest axis-aligned translation that clears a node.
fn move_relation_box_away_from_rect(
  text_box : RelationTextBox,
  rect : (Double, Double, Double, Double),
) -> RelationTextBox {
  guard relation_box_intersects_rect(text_box, rect) else { return text_box }
  let (x, y, width, height) = rect
  let candidates = [
    (x - text_box.x - text_box.width, 0.0),
    (x + width - text_box.x, 0.0),
    (0.0, y - text_box.y - text_box.height),
    (0.0, y + height - text_box.y),
  ]
  let mut best = candidates[0]
  for candidate in candidates[1:] {
    if candidate.0.abs() + candidate.1.abs() < best.0.abs() + best.1.abs() {
      best = candidate
    }
  }
  translate_relation_text_box(text_box, best.0, best.1)
}

///|
fn move_relation_box_away_from_nodes(
  text_box : RelationTextBox,
  nodes : Array[GraphvizNodeLayout],
) -> RelationTextBox {
  let mut result = text_box
  for node in nodes {
    let rect = (
      node.x - node.width / 2.0 - 8.0,
      node.y - node.height / 2.0 - 8.0,
      node.width + 16.0,
      node.height + 16.0,
    )
    result = move_relation_box_away_from_rect(result, rect)
  }
  result
}

///|
priv struct RelationPathDistance {
  point : (Double, Double)
  tangent : (Double, Double)
  distance : Double
}

///|
fn nearest_relation_path_distance(
  center : (Double, Double),
  segments : Array[((Double, Double), (Double, Double))],
) -> RelationPathDistance? {
  let mut result : RelationPathDistance? = None
  for segment in segments {
    let (start, end) = segment
    let point = closest_point_on_segment(center, start, end)
    let dx = center.0 - point.0
    let dy = center.1 - point.1
    let distance = (dx * dx + dy * dy).sqrt()
    let tangent = (end.0 - start.0, end.1 - start.1)
    match result {
      None => result = Some({ point, tangent, distance, })
      Some(previous) if distance < previous.distance =>
        result = Some({ point, tangent, distance, })
      Some(_) => ()
    }
  }
  result
}

///|
/// Keep a text box clear of the routed spline. The box's support radius in
/// the spline normal gives a size-aware correction even when the spline runs
/// through the box centre.
fn move_relation_box_away_from_paths(
  text_box : RelationTextBox,
  paths : Array[Array[(Double, Double)]],
) -> RelationTextBox {
  let segments = sample_spline_segments(paths)
  guard segments.length() > 0 else { return text_box }
  let clearance = 3.0
  let mut result = text_box
  for _iteration in 0..<16 {
    let center = relation_text_box_center(result)
    match nearest_relation_path_distance(center, segments) {
      None => break
      Some(nearest) => {
        let mut nx = center.0 - nearest.point.0
        let mut ny = center.1 - nearest.point.1
        let distance = nearest.distance
        let normal_length = (nx * nx + ny * ny).sqrt()
        if normal_length < 0.0001 {
          let tangent_length = (nearest.tangent.0 * nearest.tangent.0 +
          nearest.tangent.1 * nearest.tangent.1).sqrt()
          if tangent_length < 0.0001 {
            break
          }
          nx = -nearest.tangent.1 / tangent_length
          ny = nearest.tangent.0 / tangent_length
        } else {
          nx = nx / normal_length
          ny = ny / normal_length
        }
        let half_extent = nx.abs() * result.width / 2.0 +
          ny.abs() * result.height / 2.0
        let required = half_extent + clearance - distance
        guard required > 0.0 else { break }
        result = translate_relation_text_box(
          result,
          nx * required,
          ny * required,
        )
      }
    }
  }
  result
}

///|
fn correct_relation_text_box(
  text_box : RelationTextBox,
  nodes : Array[GraphvizNodeLayout],
  paths : Array[Array[(Double, Double)]],
) -> RelationTextBox {
  let without_nodes = move_relation_box_away_from_nodes(text_box, nodes)
  move_relation_box_away_from_paths(without_nodes, paths)
}

///|
fn relation_node_center(
  nodes : Array[GraphvizNodeLayout],
  code : String,
) -> (Double, Double)? {
  for node in nodes {
    if node.code == code {
      return Some((node.x, node.y))
    }
  }
  None
}

///|
fn relation_path_endpoint(
  paths : Array[Array[(Double, Double)]],
  tail : Bool,
  fallback : (Double, Double),
) -> (Double, Double) {
  for path in paths {
    guard path.length() > 0 else { continue }
    return if tail { path[0] } else { path[path.length() - 1] }
  }
  fallback
}

///|
fn relation_path_tangent(
  paths : Array[Array[(Double, Double)]],
  tail : Bool,
  fallback : (Double, Double),
) -> (Double, Double) {
  for path in paths {
    guard path.length() > 1 else { continue }
    if tail {
      for index in 1..<path.length() {
        let dx = path[index].0 - path[index - 1].0
        let dy = path[index].1 - path[index - 1].1
        if dx != 0.0 || dy != 0.0 {
          return (dx, dy)
        }
      }
    } else {
      for offset in 1..<path.length() {
        let index = path.length() - offset
        let dx = path[index].0 - path[index - 1].0
        let dy = path[index].1 - path[index - 1].1
        if dx != 0.0 || dy != 0.0 {
          return (dx, dy)
        }
      }
    }
  }
  fallback
}

///|
fn relation_text_box_side(
  text_box : RelationTextBox,
  line_point : (Double, Double),
  tangent : (Double, Double),
) -> Double {
  let tangent_length = (tangent.0 * tangent.0 + tangent.1 * tangent.1).sqrt()
  guard tangent_length > 0.0001 else { return 0.0 }
  let nx = -tangent.1 / tangent_length
  let ny = tangent.0 / tangent_length
  let center = relation_text_box_center(text_box)
  (center.0 - line_point.0) * nx + (center.1 - line_point.1) * ny
}

///|
/// Graphviz computes the head label from the reverse endpoint tangent. After
/// converting to SVG coordinates, PlantUML's positive label angle is measured
/// from the forward path tangent at both ends. Mirror only the normal component
/// so Graphviz's distance and along-edge placement remain unchanged.
fn normalize_relation_endpoint_side(
  text_box : RelationTextBox,
  line_point : (Double, Double),
  tangent : (Double, Double),
) -> RelationTextBox {
  let tangent_length = (tangent.0 * tangent.0 + tangent.1 * tangent.1).sqrt()
  guard tangent_length > 0.0001 else { return text_box }
  let side = relation_text_box_side(text_box, line_point, tangent)
  guard side < 0.0 else { return text_box }
  let nx = -tangent.1 / tangent_length
  let ny = tangent.0 / tangent_length
  translate_relation_text_box(text_box, -2.0 * side * nx, -2.0 * side * ny)
}

///|
fn relation_endpoint_text_box(
  text : String,
  center : (Double, Double),
  line_point : (Double, Double),
  tangent : (Double, Double),
  metrics : @metrics.FontMetrics,
  nodes : Array[GraphvizNodeLayout],
  paths : Array[Array[(Double, Double)]],
) -> RelationTextBox {
  let normalized = normalize_relation_endpoint_side(
    relation_text_box_from_center(text, center, metrics),
    line_point,
    tangent,
  )
  correct_relation_text_box(normalized, nodes, paths)
}

///|
fn place_relation_role_opposite_side(
  role : String,
  cardinality : RelationTextBox,
  line_point : (Double, Double),
  tangent : (Double, Double),
  metrics : @metrics.FontMetrics,
) -> RelationTextBox {
  let role_box = relation_text_box_from_top_left(role, 0.0, 0.0, metrics)
  let dx = tangent.0
  let dy = tangent.1
  let vertical = dy.abs() >= dx.abs()
  let gap = 2.0
  if vertical {
    let cardinality_center = relation_text_box_center(cardinality)
    let role_x = if cardinality_center.0 < line_point.0 {
      line_point.0 + gap
    } else {
      line_point.0 - role_box.width - gap
    }
    return relation_text_box_from_top_left(role, role_x, cardinality.y, metrics)
  }
  if dx.abs() > dy.abs() {
    let cardinality_center = relation_text_box_center(cardinality)
    let role_y = if cardinality_center.1 < line_point.1 {
      line_point.1 + gap
    } else {
      line_point.1 - role_box.height - gap
    }
    return relation_text_box_from_top_left(role, cardinality.x, role_y, metrics)
  }
  let tangent_length = (dx * dx + dy * dy).sqrt()
  guard tangent_length > 0.0001 else {
    return relation_text_box_from_top_left(
      role,
      cardinality.x,
      cardinality.y + cardinality.height + gap,
      metrics,
    )
  }
  let tx = dx / tangent_length
  let ty = dy / tangent_length
  let nx = -ty
  let ny = tx
  let cardinality_center = relation_text_box_center(cardinality)
  let side_value = (cardinality_center.0 - line_point.0) * nx +
    (cardinality_center.1 - line_point.1) * ny
  let side = if side_value < 0.0 { -1.0 } else { 1.0 }
  let along = (cardinality_center.0 - line_point.0) * tx +
    (cardinality_center.1 - line_point.1) * ty
  let cardinality_extent = nx.abs() * cardinality.width / 2.0 +
    ny.abs() * cardinality.height / 2.0
  let role_extent = nx.abs() * role_box.width / 2.0 +
    ny.abs() * role_box.height / 2.0
  let role_center = (
    line_point.0 +
    tx * along -
    nx * side * (cardinality_extent + role_extent + gap),
    line_point.1 +
    ty * along -
    ny * side * (cardinality_extent + role_extent + gap),
  )
  relation_text_box_from_top_left(
    role,
    role_center.0 - role_box.width / 2.0,
    role_center.1 - role_box.height / 2.0,
    metrics,
  )
}

///|
fn relation_entry_box(
  entries : Array[RelationLabelEntry],
  kind : RelationLabelKind,
) -> RelationTextBox? {
  for entry in entries {
    if entry.kind == kind {
      return Some(entry.box)
    }
  }
  None
}

///|
fn relation_label_layout_from_geometry(
  relation_index : Int,
  relation : Relation,
  text_metrics : ClassTextMetrics,
  usecase : Bool,
  paths : Array[Array[(Double, Double)]],
  fallback_start : (Double, Double),
  fallback_end : (Double, Double),
  label_center : (Double, Double)?,
  tail_label_center : (Double, Double)?,
  head_label_center : (Double, Double)?,
  nodes : Array[GraphvizNodeLayout],
) -> RelationLabelLayout {
  let path_start = relation_path_endpoint(paths, true, fallback_start)
  let path_end = relation_path_endpoint(paths, false, fallback_end)
  let edge_direction = (path_end.0 - path_start.0, path_end.1 - path_start.1)
  let tail_tangent = relation_path_tangent(paths, true, edge_direction)
  let head_tangent = relation_path_tangent(paths, false, edge_direction)
  let end_metrics = text_metrics.relation_end_regular
  let entries : Array[RelationLabelEntry] = []
  match relation.label {
    Some(text) => {
      let display = if usecase { @parse.display_stereotype(text) } else { text }
      let center = label_center.unwrap_or(
        (
          (fallback_start.0 + fallback_end.0) / 2.0,
          (fallback_start.1 + fallback_end.1) / 2.0,
        ),
      )
      entries.push({
        kind: Label,
        box: correct_relation_text_box(
          relation_text_box_from_center(
            display,
            center,
            if usecase {
              text_metrics.arrow_regular
            } else {
              text_metrics.relation_label_regular
            },
          ),
          nodes,
          paths,
        ),
      })
    }
    None => ()
  }
  let tail_center = tail_label_center.unwrap_or(path_start)
  let head_center = head_label_center.unwrap_or(path_end)
  if relation.left_cardinality is Some(text) {
    entries.push({
      kind: LeftCardinality,
      box: relation_endpoint_text_box(
        text, tail_center, path_start, tail_tangent, end_metrics, nodes, paths,
      ),
    })
  }
  if relation.right_cardinality is Some(text) {
    entries.push({
      kind: RightCardinality,
      box: relation_endpoint_text_box(
        text, head_center, path_end, head_tangent, end_metrics, nodes, paths,
      ),
    })
  }
  match relation.left_role {
    Some(text) => {
      let box = match relation.left_cardinality {
        Some(_) => {
          let cardinality = relation_entry_box(entries, LeftCardinality).unwrap()
          place_relation_role_opposite_side(
            text, cardinality, path_start, tail_tangent, end_metrics,
          )
        }
        None =>
          relation_endpoint_text_box(
            text, tail_center, path_start, tail_tangent, end_metrics, nodes, paths,
          )
      }
      entries.push({
        kind: LeftRole,
        box: if relation.left_cardinality is Some(_) {
          correct_relation_text_box(box, nodes, paths)
        } else {
          box
        },
      })
    }
    None => ()
  }
  match relation.right_role {
    Some(text) => {
      let box = match relation.right_cardinality {
        Some(_) => {
          let cardinality = relation_entry_box(entries, RightCardinality).unwrap()
          place_relation_role_opposite_side(
            text, cardinality, path_end, head_tangent, end_metrics,
          )
        }
        None =>
          relation_endpoint_text_box(
            text, head_center, path_end, head_tangent, end_metrics, nodes, paths,
          )
      }
      entries.push({
        kind: RightRole,
        box: if relation.right_cardinality is Some(_) {
          correct_relation_text_box(box, nodes, paths)
        } else {
          box
        },
      })
    }
    None => ()
  }
  {
    relation_index,
    label: relation_entry_box(entries, Label),
    left_cardinality: relation_entry_box(entries, LeftCardinality),
    right_cardinality: relation_entry_box(entries, RightCardinality),
    left_role: relation_entry_box(entries, LeftRole),
    right_role: relation_entry_box(entries, RightRole),
  }
}

///|
fn build_relation_label_layouts(
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  nodes : Array[GraphvizNodeLayout],
  edges : Array[@graphviz.GraphvizEdge],
) -> Array[RelationLabelLayout] {
  let result : Array[RelationLabelLayout] = []
  let usecase = diagram.family.is_usecase()
  for relation_index, relation in diagram.relations {
    let left_center = relation_node_center(nodes, relation.left).unwrap_or(
      (0.0, 0.0),
    )
    let right_center = relation_node_center(nodes, relation.right).unwrap_or(
      (0.0, 0.0),
    )
    for edge in edges {
      guard edge.index == relation_index else { continue }
      result.push(
        relation_label_layout_from_geometry(
          relation_index,
          relation,
          text_metrics,
          usecase,
          relation_edge_paths(edge),
          left_center,
          right_center,
          edge.label.map(point => point.pair()),
          edge.tail_label.map(point => point.pair()),
          edge.head_label.map(point => point.pair()),
          nodes,
        ),
      )
    }
  }
  result
}

///|
fn fallback_relation_label_layout(
  layout : ClassLayout,
  diagram : EntityDiagram,
  relation_index : Int,
  relation : Relation,
  text_metrics : ClassTextMetrics,
) -> RelationLabelLayout {
  guard entity_index(diagram, relation.left) is Some(left_index) else {
    return {
      relation_index,
      label: None,
      left_cardinality: None,
      right_cardinality: None,
      left_role: None,
      right_role: None,
    }
  }
  guard entity_index(diagram, relation.right) is Some(right_index) else {
    return {
      relation_index,
      label: None,
      left_cardinality: None,
      right_cardinality: None,
      left_role: None,
      right_role: None,
    }
  }
  let ((left_x, left_y), (right_x, right_y)) = relation_endpoints(
    layout,
    diagram,
    relation,
    Some(left_index),
    Some(right_index),
    text_metrics,
  )
  relation_label_layout_from_geometry(
    relation_index,
    relation,
    text_metrics,
    diagram.family.is_usecase(),
    [],
    (left_x, left_y),
    (right_x, right_y),
    None,
    None,
    None,
    [],
  )
}

///|
fn ClassLayout::relation_label_layout(
  self : ClassLayout,
  diagram : EntityDiagram,
  relation_index : Int,
  relation : Relation,
  text_metrics : ClassTextMetrics,
) -> RelationLabelLayout {
  if self.graphviz is Some(graphviz) {
    for label_layout in graphviz.relation_labels {
      if label_layout.relation_index == relation_index {
        return label_layout
      }
    }
  }
  fallback_relation_label_layout(
    self, diagram, relation_index, relation, text_metrics,
  )
}

///|
/// Flatten each 3n+1 cubic Bezier spline into short polyline segments so
/// distance-to-edge checks follow the actual curve, not the control polygon.
fn sample_spline_segments(
  paths : Array[Array[(Double, Double)]],
) -> Array[((Double, Double), (Double, Double))] {
  let segments : Array[((Double, Double), (Double, Double))] = []
  for path in paths {
    if path.length() >= 4 && (path.length() - 1) % 3 == 0 {
      let count = (path.length() - 1) / 3
      for index in 0..<count {
        let p0 = path[index * 3]
        let p1 = path[index * 3 + 1]
        let p2 = path[index * 3 + 2]
        let p3 = path[index * 3 + 3]
        let mut prev = p0
        for step in 1..<=24 {
          let t = step.to_double() / 24.0
          let u = 1.0 - t
          let point = (
            u * u * u * p0.0 +
            3.0 * u * u * t * p1.0 +
            3.0 * u * t * t * p2.0 +
            t * t * t * p3.0,
            u * u * u * p0.1 +
            3.0 * u * u * t * p1.1 +
            3.0 * u * t * t * p2.1 +
            t * t * t * p3.1,
          )
          segments.push((prev, point))
          prev = point
        }
      }
    } else if path.length() > 1 {
      for index in 1..<path.length() {
        segments.push((path[index - 1], path[index]))
      }
    }
  }
  segments
}

///|
/// Project a point onto a segment and return the closest point on the segment.
fn closest_point_on_segment(
  point : (Double, Double),
  a : (Double, Double),
  b : (Double, Double),
) -> (Double, Double) {
  let (px, py) = point
  let (ax, ay) = a
  let (bx, by) = b
  let tx = bx - ax
  let ty = by - ay
  let length_sq = tx * tx + ty * ty
  guard length_sq > 0.0 else { return a }
  let t = ((px - ax) * tx + (py - ay) * ty) / length_sq
  let t = t.max(0.0).min(1.0)
  (ax + tx * t, ay + ty * t)
}
