///|
fn relation_point_distance_squared(
  first : (Double, Double),
  second : (Double, Double),
) -> Double {
  let dx = first.0 - second.0
  let dy = first.1 - second.1
  dx * dx + dy * dy
}

///|
fn reverse_relation_spline(
  spline : @graphviz.GraphvizSpline,
) -> @graphviz.GraphvizSpline {
  let points : Array[(Double, Double)] = []
  let mut index = spline.points.length()
  while index > 0 {
    index -= 1
    points.push(spline.points[index])
  }
  { arrow_start: spline.arrow_end, arrow_end: spline.arrow_start, points }
}

///|
fn relation_edge_endpoint(
  edge : @graphviz.GraphvizEdge,
  start : Bool,
) -> (Double, Double)? {
  if start {
    for spline in edge.splines {
      match spline.arrow_start {
        Some(point) => return Some(point)
        None =>
          match spline.points.get(0) {
            Some(point) => return Some(point)
            None => ()
          }
      }
    }
  } else {
    let mut index = edge.splines.length()
    while index > 0 {
      index -= 1
      let spline = edge.splines[index]
      match spline.arrow_end {
        Some(point) => return Some(point)
        None =>
          match spline.points.last() {
            Some(point) => return Some(point)
            None => ()
          }
      }
    }
  }
  None
}

///|
/// Graphviz may route an edge in the opposite order from its semantic tail and
/// head. PlantUML corrects this by comparing both endpoint assignments to the
/// two node centers before it creates extremities.
fn orient_relation_edge(
  edge : @graphviz.GraphvizEdge,
  left_center : (Double, Double),
  right_center : (Double, Double),
) -> @graphviz.GraphvizEdge {
  guard relation_edge_endpoint(edge, true) is Some(start) else { return edge }
  guard relation_edge_endpoint(edge, false) is Some(end) else { return edge }
  let normal = relation_point_distance_squared(start, left_center).sqrt() +
    relation_point_distance_squared(end, right_center).sqrt()
  let reversed = relation_point_distance_squared(start, right_center).sqrt() +
    relation_point_distance_squared(end, left_center).sqrt()
  guard reversed < normal else { return edge }
  let splines : Array[@graphviz.GraphvizSpline] = []
  let mut index = edge.splines.length()
  while index > 0 {
    index -= 1
    splines.push(reverse_relation_spline(edge.splines[index]))
  }
  { ..edge, splines, }
}

///|
fn move_spline_start_to(
  spline : @graphviz.GraphvizSpline,
  endpoint : (Double, Double),
) -> @graphviz.GraphvizSpline {
  guard spline.points.length() > 0 else { return spline }
  let points = spline.points.copy()
  let dx = endpoint.0 - points[0].0
  let dy = endpoint.1 - points[0].1
  points[0] = endpoint
  if points.length() > 1 && (points.length() - 1) % 3 == 0 {
    points[1] = (points[1].0 + dx, points[1].1 + dy)
  }
  { ..spline, points, }
}

///|
fn move_spline_end_to(
  spline : @graphviz.GraphvizSpline,
  endpoint : (Double, Double),
) -> @graphviz.GraphvizSpline {
  guard spline.points.length() > 0 else { return spline }
  let points = spline.points.copy()
  let last = points.length() - 1
  let dx = endpoint.0 - points[last].0
  let dy = endpoint.1 - points[last].1
  points[last] = endpoint
  if points.length() > 1 && (points.length() - 1) % 3 == 0 {
    points[last - 1] = (points[last - 1].0 + dx, points[last - 1].1 + dy)
  }
  { ..spline, points, }
}

///|
fn repair_relation_contacts(
  edge : @graphviz.GraphvizEdge,
  left_node : GraphvizNodeLayout,
  left_shape : NodeShape,
  right_node : GraphvizNodeLayout,
  right_shape : NodeShape,
) -> @graphviz.GraphvizEdge {
  let splines = edge.splines.copy()
  let mut first_index = 0
  while first_index < splines.length() &&
        splines[first_index].points.length() == 0 {
    first_index += 1
  }
  guard first_index < splines.length() else { return edge }
  let mut last_index = splines.length() - 1
  while last_index > first_index && splines[last_index].points.length() == 0 {
    last_index -= 1
  }
  let first = splines[first_index]
  let first_adjacent = if first.points.length() > 1 {
    first.points[1]
  } else {
    (right_node.x, right_node.y)
  }
  let start = clip_ray_to_node(
    first.points[0],
    first_adjacent,
    left_node,
    left_shape,
  )
  splines[first_index] = move_spline_start_to(first, start)
  let last = splines[last_index]
  let last_point = last.points.length() - 1
  let last_adjacent = if last.points.length() > 1 {
    last.points[last_point - 1]
  } else {
    (left_node.x, left_node.y)
  }
  let end = clip_ray_to_node(
    last.points[last_point],
    last_adjacent,
    right_node,
    right_shape,
  )
  splines[last_index] = move_spline_end_to(last, end)
  { ..edge, splines, }
}

///|
fn relation_node_layout(
  nodes : Array[GraphvizNodeLayout],
  code : String,
) -> GraphvizNodeLayout? {
  for node in nodes {
    if node.code == code {
      return Some(node)
    }
  }
  None
}

///|
fn normalize_relation_edges(
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  nodes : Array[GraphvizNodeLayout],
  edges : Array[@graphviz.GraphvizEdge],
) -> Array[@graphviz.GraphvizEdge] {
  edges.map(edge => {
    guard edge.index >= 0 && edge.index < diagram.relations.length() else {
      return edge
    }
    let relation = diagram.relations[edge.index]
    guard relation_node_layout(nodes, relation.left) is Some(left_node) else {
      return edge
    }
    guard relation_node_layout(nodes, relation.right) is Some(right_node) else {
      return edge
    }
    guard diagram.entity(relation.left) is Some(left_entity) else {
      return edge
    }
    guard diagram.entity(relation.right) is Some(right_entity) else {
      return edge
    }
    let oriented = orient_relation_edge(
      edge,
      (left_node.x, left_node.y),
      (right_node.x, right_node.y),
    )
    repair_relation_contacts(
      oriented,
      left_node,
      left_entity.node_geometry(text_metrics, diagram.family).shape,
      right_node,
      right_entity.node_geometry(text_metrics, diagram.family).shape,
    )
  })
}

///|
fn relation_edge_paths(
  edge : @graphviz.GraphvizEdge,
) -> Array[Array[(Double, Double)]] {
  edge.splines.map(spline => spline.points)
}

///|
fn relation_edge_first_spline_index(edge : @graphviz.GraphvizEdge) -> Int? {
  for index, spline in edge.splines {
    if spline.points.length() > 1 {
      return Some(index)
    }
  }
  None
}

///|
fn relation_edge_last_spline_index(edge : @graphviz.GraphvizEdge) -> Int? {
  let mut index = edge.splines.length()
  while index > 0 {
    index -= 1
    if edge.splines[index].points.length() > 1 {
      return Some(index)
    }
  }
  None
}

///|
const ARROW_DECORATION_LENGTH : Double = 5.0

///|
const ARROW_WING_LENGTH : Double = 9.0

///|
const ARROW_APERTURE : Double = 4.0

///|
const TRIANGLE_DECORATION_LENGTH : Double = 18.0

///|
const TRIANGLE_APERTURE : Double = 6.0

///|
const DIAMOND_DECORATION_LENGTH : Double = 12.0

///|
const DIAMOND_APERTURE : Double = 4.0

///|
priv struct RelationDecorationGeometry {
  points : Array[(Double, Double)]
  filled : Bool
}

///|
fn RelationEnd::decoration_length(self : RelationEnd) -> Double {
  match self {
    Extension | Redefines | DefinedBy => TRIANGLE_DECORATION_LENGTH
    CompositionEnd | AggregationEnd => DIAMOND_DECORATION_LENGTH
    Arrow | TriangleArrow | HalfArrowUp | HalfArrowDown =>
      ARROW_DECORATION_LENGTH
    _ => 0.0
  }
}

///|
fn RelationEnd::decoration_geometry(
  self : RelationEnd,
  endpoint : (Double, Double),
  adjacent : (Double, Double),
) -> RelationDecorationGeometry? {
  let dx = endpoint.0 - adjacent.0
  let dy = endpoint.1 - adjacent.1
  let tangent_length = (dx * dx + dy * dy).sqrt()
  guard tangent_length > 0.0 else { return None }
  let tx = dx / tangent_length
  let ty = dy / tangent_length
  let nx = -ty
  let ny = tx
  let point = fn(along : Double, normal : Double) {
    (
      endpoint.0 - tx * along + nx * normal,
      endpoint.1 - ty * along + ny * normal,
    )
  }
  match self {
    Arrow | TriangleArrow | HalfArrowUp | HalfArrowDown =>
      Some({
        points: [
          endpoint,
          point(ARROW_WING_LENGTH, -ARROW_APERTURE),
          point(ARROW_DECORATION_LENGTH, 0.0),
          point(ARROW_WING_LENGTH, ARROW_APERTURE),
        ],
        filled: true,
      })
    Extension | Redefines | DefinedBy =>
      Some({
        points: [
          endpoint,
          point(TRIANGLE_DECORATION_LENGTH, -TRIANGLE_APERTURE),
          point(TRIANGLE_DECORATION_LENGTH, TRIANGLE_APERTURE),
        ],
        filled: false,
      })
    CompositionEnd | AggregationEnd =>
      Some({
        points: [
          endpoint,
          point(DIAMOND_DECORATION_LENGTH / 2.0, -DIAMOND_APERTURE),
          point(DIAMOND_DECORATION_LENGTH, 0.0),
          point(DIAMOND_DECORATION_LENGTH / 2.0, DIAMOND_APERTURE),
        ],
        filled: self is CompositionEnd,
      })
    _ => None
  }
}

///|
fn normalized_vector(dx : Double, dy : Double) -> (Double, Double)? {
  let length = (dx * dx + dy * dy).sqrt()
  guard length > 0.0 else { return None }
  Some((dx / length, dy / length))
}

///|
fn relation_spline_start_direction(
  points : Array[(Double, Double)],
) -> (Double, Double)? {
  guard points.length() > 1 else { return None }
  let start = points[0]
  let adjacent = points[1]
  match normalized_vector(adjacent.0 - start.0, adjacent.1 - start.1) {
    Some(direction) => Some(direction)
    None => {
      let segment_end = if points.length() >= 4 &&
        (points.length() - 1) % 3 == 0 {
        points[3]
      } else {
        points[points.length() - 1]
      }
      normalized_vector(segment_end.0 - start.0, segment_end.1 - start.1)
    }
  }
}

///|
fn relation_spline_end_direction(
  points : Array[(Double, Double)],
) -> (Double, Double)? {
  guard points.length() > 1 else { return None }
  let last = points.length() - 1
  let end = points[last]
  let adjacent = points[last - 1]
  match normalized_vector(end.0 - adjacent.0, end.1 - adjacent.1) {
    Some(direction) => Some(direction)
    None => {
      let segment_start = if points.length() >= 4 &&
        (points.length() - 1) % 3 == 0 {
        points[last - 3]
      } else {
        points[0]
      }
      normalized_vector(end.0 - segment_start.0, end.1 - segment_start.1)
    }
  }
}

///|
/// Mirrors PlantUML `DotPath.moveStartPoint`: move the endpoint and first
/// control point together, dropping one complete leading Bezier when the
/// decoration is longer than that segment's endpoint chord.
fn move_relation_spline_start(
  path : Array[(Double, Double)],
  distance : Double,
) -> Array[(Double, Double)] {
  guard distance > 0.0 else { return path.copy() }
  guard relation_spline_start_direction(path) is Some(direction) else {
    return path.copy()
  }
  let move_x = direction.0 * distance
  let move_y = direction.1 * distance
  let cubic = path.length() >= 4 && (path.length() - 1) % 3 == 0
  let drop_first = cubic &&
    path.length() > 4 &&
    relation_point_distance_squared(path[0], path[3]).sqrt() <= distance
  let moved : Array[(Double, Double)] = []
  let start_index = if drop_first { 3 } else { 0 }
  for index in start_index..<path.length() {
    moved.push(path[index])
  }
  guard moved.length() > 0 else { return path.copy() }
  let original_start = path[0]
  let dx = original_start.0 + move_x - moved[0].0
  let dy = original_start.1 + move_y - moved[0].1
  moved[0] = (moved[0].0 + dx, moved[0].1 + dy)
  if cubic && moved.length() > 1 {
    moved[1] = (moved[1].0 + dx, moved[1].1 + dy)
  }
  moved
}

///|
/// Mirrors PlantUML `DotPath.moveEndPoint`: move the endpoint and final
/// control point by the same vector so the endpoint tangent is unchanged.
fn move_relation_spline_end(
  path : Array[(Double, Double)],
  distance : Double,
) -> Array[(Double, Double)] {
  guard distance > 0.0 else { return path.copy() }
  guard relation_spline_end_direction(path) is Some(direction) else {
    return path.copy()
  }
  let moved = path.copy()
  let last = moved.length() - 1
  let move_x = -direction.0 * distance
  let move_y = -direction.1 * distance
  moved[last] = (moved[last].0 + move_x, moved[last].1 + move_y)
  if moved.length() >= 4 && (moved.length() - 1) % 3 == 0 {
    moved[last - 1] = (moved[last - 1].0 + move_x, moved[last - 1].1 + move_y)
  }
  moved
}

///|
fn shorten_relation_spline(
  path : Array[(Double, Double)],
  start_length : Double,
  end_length : Double,
) -> Array[(Double, Double)] {
  guard path.length() > 1 else { return path }
  move_relation_spline_start(path, start_length)
  |> move_relation_spline_end(end_length)
}
