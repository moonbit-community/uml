///|
const NOTE_GEOMETRY_EPSILON : Double = 0.0001

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
