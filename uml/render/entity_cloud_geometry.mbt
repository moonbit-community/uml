// Seeded cloud frontier shared by node and container symbol painters.
// USymbolCloud seeds JavaRandom with width + 7919 * height.
// Random draws and curve construction retain the PlantUML order.

///|
/// `CoordinateChange`: a length-preserving local frame along a segment.
priv struct CoordinateChange {
  x1 : Double
  y1 : Double
  vect_u_x : Double
  vect_u_y : Double
  vect_v_x : Double
  vect_v_y : Double
  len : Double
}

///|
fn CoordinateChange::create(
  p1 : (Double, Double),
  p2 : (Double, Double),
) -> CoordinateChange {
  let dx = p2.0 - p1.0
  let dy = p2.1 - p1.1
  let len = (dx * dx + dy * dy).sqrt()
  let vect_u_x = (p2.0 - p1.0) / len
  let vect_u_y = (p2.1 - p1.1) / len
  {
    x1: p1.0,
    y1: p1.1,
    vect_u_x,
    vect_u_y,
    vect_v_x: -vect_u_y,
    vect_v_y: vect_u_x,
    len,
  }
}

///|
fn CoordinateChange::true_coordinate(
  self : CoordinateChange,
  a : Double,
  b : Double,
) -> (Double, Double) {
  (
    self.x1 + a * self.vect_u_x + b * self.vect_v_x,
    self.y1 + a * self.vect_u_y + b * self.vect_v_y,
  )
}

///|
fn description_cloud_points_on_segment(
  random : JavaRandom,
  points : Array[(Double, Double)],
  p1 : (Double, Double),
  p2 : (Double, Double),
  bubble_size : Double,
) -> Unit {
  let change = CoordinateChange::create(p1, p2)
  let length = change.len
  let mut bubble_size = bubble_size
  let mut nb = (length / bubble_size).to_int()
  if nb == 0 {
    bubble_size = length / 2.0
    nb = (length / bubble_size).to_int()
  }
  for i in 0..<nb {
    let (x, y) = change.true_coordinate(
      i.to_double() * length / nb.to_double(),
      0.0,
    )
    let dx = bubble_size * 0.2 * random.next_double()
    let dy = bubble_size * 0.2 * random.next_double()
    points.push((x + dx, y + dy))
  }
}

///|
fn description_cloud_special_line(
  random : JavaRandom,
  points : Array[(Double, Double)],
  p1 : (Double, Double),
  p2 : (Double, Double),
  bubble_size : Double,
) -> Unit {
  let change = CoordinateChange::create(p1, p2)
  let length = change.len
  let offset = -random.ranged(1.0, 1.0 + 12.0.min(bubble_size * 0.8))
  let middle = change.true_coordinate(length / 2.0, offset)
  description_cloud_points_on_segment(random, points, p1, middle, bubble_size)
  description_cloud_points_on_segment(random, points, middle, p2, bubble_size)
}

///|
fn description_cloud_curve(
  random : JavaRandom,
  output : Array[@graphics.PathSegment],
  p1 : (Double, Double),
  p2 : (Double, Double),
) -> Unit {
  let change = CoordinateChange::create(p1, p2)
  let length = change.len
  let coef = random.ranged(0.25, 0.35)
  let (m1x, m1y) = change.true_coordinate(
    length * coef,
    -length * random.ranged(0.4, 0.55),
  )
  let (m2x, m2y) = change.true_coordinate(
    length * (1.0 - coef),
    -length * random.ranged(0.4, 0.55),
  )
  output.push(
    CubicTo({ x: m1x, y: m1y, }, { x: m2x, y: m2y, }, { x: p2.0, y: p2.1, }),
  )
}

///|
/// `USymbolCloud.getSpecificFrontierForCloudNew`: a wavy frontier whose
/// random offsets are seeded by the node size.
fn description_cloud_path(
  width : Double,
  height : Double,
  origin_x : Double,
  origin_y : Double,
) -> Array[@graphics.PathSegment] {
  let random = JavaRandom::new(width.to_int64() + 7919L * height.to_int64())
  let mut bubble_size = 11.0
  let max_dim = width.max(height)
  if max_dim / bubble_size > 16.0 {
    bubble_size = max_dim / 16.0
  }
  let margin1 = 8.0
  let point_a = (margin1, margin1)
  let point_b = (width - margin1, margin1)
  let point_c = (width - margin1, height - margin1)
  let point_d = (margin1, height - margin1)
  let points : Array[(Double, Double)] = []
  if width > 100.0 && height > 100.0 {
    let margin2 = 7.0
    description_cloud_special_line(
      random,
      points,
      (point_a.0 + margin2, point_a.1),
      (point_b.0 - margin2, point_b.1),
      bubble_size,
    )
    points.push((point_b.0, point_b.1 + margin2))
    description_cloud_special_line(
      random,
      points,
      (point_b.0, point_b.1 + margin2),
      (point_c.0, point_c.1 - margin2),
      bubble_size,
    )
    points.push((point_c.0 - margin2, point_c.1))
    description_cloud_special_line(
      random,
      points,
      (point_c.0 - margin2, point_c.1),
      (point_d.0 + margin2, point_d.1),
      bubble_size,
    )
    points.push((point_d.0, point_d.1 - margin2))
    description_cloud_special_line(
      random,
      points,
      (point_d.0, point_d.1 - margin2),
      (point_a.0, point_a.1 + margin2),
      bubble_size,
    )
    points.push((point_a.0 + margin2, point_a.1))
  } else {
    description_cloud_special_line(
      random, points, point_a, point_b, bubble_size,
    )
    description_cloud_special_line(
      random, points, point_b, point_c, bubble_size,
    )
    description_cloud_special_line(
      random, points, point_c, point_d, bubble_size,
    )
    description_cloud_special_line(
      random, points, point_d, point_a, bubble_size,
    )
  }
  points.push(points[0])
  let output : Array[@graphics.PathSegment] = [
    MoveTo({ x: origin_x + points[0].0, y: origin_y + points[0].1, }),
  ]
  for i in 0..<(points.length() - 1) {
    description_cloud_curve(
      random,
      output,
      (origin_x + points[i].0, origin_y + points[i].1),
      (origin_x + points[i + 1].0, origin_y + points[i + 1].1),
    )
  }
  output
}
