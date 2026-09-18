///|
/// SkinParam.getDotSplines accepts these two overrides, case-insensitively.
/// DotStringFactory applies them to autonomous inner graphs as well.
/// Verified before Graphviz 0.1.10: polyline/ortho paths retain bends, semantic
/// contacts, labels and notes; exterior labels do not reserve a label rank.
fn state_graphviz_routing(style : @style.DocumentStyle) -> String {
  let value = style.property("linetype").map(value => value.to_lower())
  match value.unwrap_or("") {
    "polyline" => "polyline"
    "ortho" => "ortho"
    _ => "spline"
  }
}

///|
/// DotPath.simulateCompound uses eight cubic subdivisions at a cluster edge.
const STATE_CLUSTER_CLIP_SUBDIVISIONS : Int = 8

///|
priv struct StateCubic {
  start : (Double, Double)
  control1 : (Double, Double)
  control2 : (Double, Double)
  end : (Double, Double)
}

///|
fn state_point_midpoint(
  left : (Double, Double),
  right : (Double, Double),
) -> (Double, Double) {
  ((left.0 + right.0) / 2.0, (left.1 + right.1) / 2.0)
}

///|
fn StateCubic::subdivide(self : StateCubic) -> (StateCubic, StateCubic) {
  let left1 = state_point_midpoint(self.start, self.control1)
  let middle = state_point_midpoint(self.control1, self.control2)
  let right2 = state_point_midpoint(self.control2, self.end)
  let left2 = state_point_midpoint(left1, middle)
  let right1 = state_point_midpoint(middle, right2)
  let split = state_point_midpoint(left2, right1)
  (
    { start: self.start, control1: left1, control2: left2, end: split, },
    { start: split, control1: right1, control2: right2, end: self.end, },
  )
}

///|
fn StateNodeLayout::contains_point(
  self : StateNodeLayout,
  point : (Double, Double),
) -> Bool {
  point.0 >= self.x &&
  point.0 < self.x + self.width &&
  point.1 >= self.y &&
  point.1 < self.y + self.height
}

///|
fn StateCubic::append_to(
  self : StateCubic,
  output : Array[(Double, Double)],
) -> Unit {
  if output.is_empty() {
    output.push(self.start)
  }
  output.push(self.control1)
  output.push(self.control2)
  output.push(self.end)
}

///|
/// Match DotPath.simulateCompound: retain the original cubic pieces outside
/// the group and subdivide only the piece crossing its rectangular boundary.
/// A link entirely inside the group remains intact, as in the Java renderer.
fn clip_state_cluster_head(
  path : Array[(Double, Double)],
  head : StateNodeLayout,
) -> Array[(Double, Double)] {
  guard path.last() is Some(end) && head.contains_point(end) else {
    return path
  }
  let result = []
  let mut index = 0
  while index + 3 < path.length() {
    let curve : StateCubic = {
      start: path[index],
      control1: path[index + 1],
      control2: path[index + 2],
      end: path[index + 3],
    }
    guard head.contains_point(curve.end) else {
      curve.append_to(result)
      index += 3
      continue
    }
    guard !head.contains_point(curve.start) else { return path }
    let mut current = curve
    for _ in 0..<STATE_CLUSTER_CLIP_SUBDIVISIONS {
      let (left, right) = current.subdivide()
      if head.contains_point(left.end) {
        current = left
      } else {
        left.append_to(result)
        current = right
      }
    }
    return result
  }
  path
}

///|
fn clip_state_cluster_path(
  path : Array[(Double, Double)],
  tail : StateNodeLayout?,
  head : StateNodeLayout?,
) -> Array[(Double, Double)] {
  let path = tail.map_or(path, tail => clip_state_cluster_tail(path, tail))
  head.map_or(path, head => clip_state_cluster_head(path, head))
}

///|
/// The tail removes successive inner pieces before subdividing the exiting
/// curve. This differs from reversing the head algorithm when a path reenters.
fn clip_state_cluster_tail(
  path : Array[(Double, Double)],
  tail : StateNodeLayout,
) -> Array[(Double, Double)] {
  guard path.get(0) is Some(start) && tail.contains_point(start) else {
    return path
  }
  let mut index = 0
  while index + 3 < path.length() && tail.contains_point(path[index + 3]) {
    index += 3
  }
  guard index + 3 < path.length() else { return path }
  let mut current : StateCubic = {
    start: path[index],
    control1: path[index + 1],
    control2: path[index + 2],
    end: path[index + 3],
  }
  let pieces : Array[StateCubic] = []
  for _ in 0..<STATE_CLUSTER_CLIP_SUBDIVISIONS {
    let (left, right) = current.subdivide()
    if tail.contains_point(left.end) {
      current = right
    } else {
      pieces.insert(0, right)
      current = left
    }
  }
  let result = []
  for piece in pieces {
    piece.append_to(result)
  }
  index += 3
  while index + 3 < path.length() {
    StateCubic::{
      start: path[index],
      control1: path[index + 1],
      control2: path[index + 2],
      end: path[index + 3],
    }.append_to(result)
    index += 3
  }
  result
}
