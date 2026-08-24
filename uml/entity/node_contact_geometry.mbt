///|
const NOTE_GEOMETRY_EPSILON : Double = 0.0001

///|
/// A point in the SVG coordinate space used by entity relations and notes.
priv struct Point {
  x : Double
  y : Double
}

///|
/// An axis-aligned rectangle in SVG coordinate space.
priv struct Rect {
  center : Point
  width : Double
  height : Double
}

///|
/// A node boundary contact point, retaining its semantic node side.
priv struct NodeContact {
  point : Point
  side : RelationContactSide
}

///|
fn point(x : Double, y : Double) -> Point {
  { x, y }
}

///|
fn point_from_pair(value : (Double, Double)) -> Point {
  point(value.0, value.1)
}

///|
fn Point::pair(self : Point) -> (Double, Double) {
  (self.x, self.y)
}

///|
fn rect(center : Point, width : Double, height : Double) -> Rect {
  { center, width, height }
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
fn GraphvizNodeLayout::relation_contact_side(
  self : GraphvizNodeLayout,
  point : Point,
) -> RelationContactSide {
  let left = self.x - self.width / 2.0
  let right = self.x + self.width / 2.0
  let top = self.y - self.height / 2.0
  let bottom = self.y + self.height / 2.0
  let candidates = [
    ((point.x - left).abs(), ContactWest),
    ((point.x - right).abs(), ContactEast),
    ((point.y - top).abs(), ContactNorth),
    ((point.y - bottom).abs(), ContactSouth),
  ]
  let mut closest = candidates[0]
  for candidate in candidates[1:] {
    if candidate.0 < closest.0 {
      closest = candidate
    }
  }
  closest.1
}

///|
fn GraphvizNodeLayout::contact(
  self : GraphvizNodeLayout,
  point : Point,
) -> NodeContact {
  { point, side: self.relation_contact_side(point) }
}

///|
fn point_distance_squared(first : Point, second : Point) -> Double {
  let dx = first.x - second.x
  let dy = first.y - second.y
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
/// Clip a ray (origin `endpoint`, direction `(dx, dy)`) against an
/// axis-aligned rectangle. Returns the first boundary hit, or `None` when the
/// ray misses the rectangle.
fn clip_ray_to_rect_dir(
  endpoint : Point,
  dx : Double,
  dy : Double,
  bounds : Rect,
) -> Point? {
  let left = bounds.center.x - bounds.width / 2.0
  let right = bounds.center.x + bounds.width / 2.0
  let top = bounds.center.y - bounds.height / 2.0
  let bottom = bounds.center.y + bounds.height / 2.0
  guard dx != 0.0 || dy != 0.0 else { return None }
  let mut best : Double? = None
  if dx != 0.0 {
    for side in [left, right] {
      let t = (side - endpoint.x) / dx
      let y = endpoint.y + t * dy
      if y >= top - NOTE_GEOMETRY_EPSILON && y <= bottom + NOTE_GEOMETRY_EPSILON {
        best = keep_nearest_nonnegative(best, t)
      }
    }
  }
  if dy != 0.0 {
    for side in [top, bottom] {
      let t = (side - endpoint.y) / dy
      let x = endpoint.x + t * dx
      if x >= left - NOTE_GEOMETRY_EPSILON && x <= right + NOTE_GEOMETRY_EPSILON {
        best = keep_nearest_nonnegative(best, t)
      }
    }
  }
  best.map(t => point(endpoint.x + t * dx, endpoint.y + t * dy))
}

///|
fn clip_ray_to_rect(endpoint : Point, adjacent : Point, bounds : Rect) -> Point {
  let left = bounds.center.x - bounds.width / 2.0
  let right = bounds.center.x + bounds.width / 2.0
  let top = bounds.center.y - bounds.height / 2.0
  let bottom = bounds.center.y + bounds.height / 2.0
  let inside = endpoint.x >= left - NOTE_GEOMETRY_EPSILON &&
    endpoint.x <= right + NOTE_GEOMETRY_EPSILON &&
    endpoint.y >= top - NOTE_GEOMETRY_EPSILON &&
    endpoint.y <= bottom + NOTE_GEOMETRY_EPSILON
  let (dx, dy) = if inside {
    (adjacent.x - endpoint.x, adjacent.y - endpoint.y)
  } else {
    (endpoint.x - adjacent.x, endpoint.y - adjacent.y)
  }
  match clip_ray_to_rect_dir(endpoint, dx, dy, bounds) {
    Some(hit) => hit
    None =>
      // The spline endpoint is off the node (graphviz routing already failed):
      // fall back to the boundary facing the node center, then to the closest
      // boundary point.
      clip_ray_to_rect_dir(
        endpoint,
        bounds.center.x - endpoint.x,
        bounds.center.y - endpoint.y,
        bounds,
      ).unwrap_or(closest_point_on_rect(endpoint, bounds))
  }
}

///|
fn clip_ray_to_ellipse(
  endpoint : Point,
  adjacent : Point,
  bounds : Rect,
) -> Point {
  let radius_x = bounds.width / 2.0
  let radius_y = bounds.height / 2.0
  guard radius_x > 0.0 && radius_y > 0.0 else { return endpoint }
  let px = endpoint.x - bounds.center.x
  let py = endpoint.y - bounds.center.y
  let normalized = px * px / (radius_x * radius_x) +
    py * py / (radius_y * radius_y)
  let inside = normalized <= 1.0 + NOTE_GEOMETRY_EPSILON
  let (dx, dy) = if inside {
    (adjacent.x - endpoint.x, adjacent.y - endpoint.y)
  } else {
    (endpoint.x - adjacent.x, endpoint.y - adjacent.y)
  }
  let a = dx * dx / (radius_x * radius_x) + dy * dy / (radius_y * radius_y)
  let b = 2.0 *
    (px * dx / (radius_x * radius_x) + py * dy / (radius_y * radius_y))
  let c = normalized - 1.0
  let discriminant = b * b - 4.0 * a * c
  let best = if a > 0.0 && discriminant >= 0.0 {
    let root = discriminant.sqrt()
    let first = (-b - root) / (2.0 * a)
    let second = (-b + root) / (2.0 * a)
    keep_nearest_nonnegative(keep_nearest_nonnegative(None, first), second)
  } else {
    None
  }
  match best {
    Some(t) => point(endpoint.x + t * dx, endpoint.y + t * dy)
    None => {
      // The spline endpoint misses the node entirely: fall back to the
      // boundary facing the node center.
      guard normalized > 0.0 else { return endpoint }
      let scale = 1.0 / normalized.sqrt()
      point(bounds.center.x + px * scale, bounds.center.y + py * scale)
    }
  }
}

///|
fn clip_ray_to_node(
  endpoint : Point,
  adjacent : Point,
  node : GraphvizNodeLayout,
  shape : NodeShape,
) -> Point {
  match shape {
    Box => {
      let bounds = rect(point(node.x, node.y), node.width, node.height)
      clip_ray_to_rect(endpoint, adjacent, bounds)
    }
    Ellipse | Circle => {
      let bounds = rect(point(node.x, node.y), node.width, node.height)
      clip_ray_to_ellipse(endpoint, adjacent, bounds)
    }
    InterfaceCircle => {
      // The interface figure is a 16px circle centered 9px below the node
      // rect's top edge (`CircleSymbol` figure origin), not the full
      // description rect.
      let center = point(node.x, node.y - node.height / 2.0 + 9.0)
      let bounds = rect(center, INTERFACE_CIRCLE_SIZE, INTERFACE_CIRCLE_SIZE)
      clip_ray_to_ellipse(endpoint, adjacent, bounds)
    }
    Hexagon => {
      let bounds = rect(point(node.x, node.y), node.width, node.height)
      clip_ray_to_rect(endpoint, adjacent, bounds)
    }
  }
}

///|
const INTERFACE_CIRCLE_SIZE : Double = 16.0

///|
/// Closest point on an axis-aligned rectangle to a given point. The segment
/// from any outside point to its projection never crosses the rectangle
/// interior; the result also feeds `rect_contact_side` to tell which edge a
/// relation approaches.
fn closest_point_on_rect(target : Point, bounds : Rect) -> Point {
  let left = bounds.center.x - bounds.width / 2.0
  let right = bounds.center.x + bounds.width / 2.0
  let top = bounds.center.y - bounds.height / 2.0
  let bottom = bounds.center.y + bounds.height / 2.0
  point(target.x.min(right).max(left), target.y.min(bottom).max(top))
}

///|
/// Which edge of an axis-aligned rectangle a boundary point lies on, choosing
/// the nearest side when the point sits on a corner.
fn rect_contact_side(point : Point, bounds : Rect) -> RelationContactSide {
  let left = bounds.center.x - bounds.width / 2.0
  let right = bounds.center.x + bounds.width / 2.0
  let top = bounds.center.y - bounds.height / 2.0
  let bottom = bounds.center.y + bounds.height / 2.0
  let candidates = [
    ((point.x - left).abs(), ContactWest),
    ((point.x - right).abs(), ContactEast),
    ((point.y - top).abs(), ContactNorth),
    ((point.y - bottom).abs(), ContactSouth),
  ]
  let mut closest = candidates[0]
  for candidate in candidates[1:] {
    if candidate.0 < closest.0 {
      closest = candidate
    }
  }
  closest.1
}

///|
/// The midpoint of the rectangle edge for a contact side. A collapsed class
/// node re-anchors its relations here: the edge lands on the middle of the
/// header-strip side it approaches instead of drifting to a corner.
fn rect_edge_midpoint(bounds : Rect, side : RelationContactSide) -> Point {
  let left = bounds.center.x - bounds.width / 2.0
  let right = bounds.center.x + bounds.width / 2.0
  let top = bounds.center.y - bounds.height / 2.0
  let bottom = bounds.center.y + bounds.height / 2.0
  match side {
    ContactWest => point(left, bounds.center.y)
    ContactEast => point(right, bounds.center.y)
    ContactNorth => point(bounds.center.x, top)
    ContactSouth => point(bounds.center.x, bottom)
  }
}
