///|
/// The Java hand-drawing adapter starts a new java.util.Random on every
/// derived UGraphic context, keeping repeated renders deterministic.
const HANDWRITTEN_SEED : Int64 = 424242L

///|
const HANDWRITTEN_LINE_VARIATION : Double = 2.0

///|
const HANDWRITTEN_PATH_VARIATION : Double = 4.0

///|
const HANDWRITTEN_POLYGON_VARIATION : Double = 1.5

///|
const HANDWRITTEN_SEGMENT_LENGTH : Double = 10.0

///|
const HANDWRITTEN_MIN_SEGMENTS : Int = 5

///|
const HANDWRITTEN_FLATNESS : Double = 0.1

///|
const HANDWRITTEN_CURVE_DISTANCE : Double = 20.0

///|
const HANDWRITTEN_MIN_DISTANCE : Double = 0.001

///|
priv struct HandJiggle {
  random : JavaRandom
  variation : Double
  points : Array[@graphics.Point]
  mut current : @graphics.Point
}

///|
fn HandJiggle::new(
  start : @graphics.Point,
  variation : Double,
  random : JavaRandom,
) -> HandJiggle {
  { random, variation, points: [start], current: start, }
}

///|
fn HandJiggle::line_to(self : HandJiggle, end : @graphics.Point) -> Unit {
  let dx = (end.x - self.current.x).abs()
  let dy = (end.y - self.current.y).abs()
  let distance = (dx * dx + dy * dy).sqrt()
  guard distance >= HANDWRITTEN_MIN_DISTANCE else { return }
  let suggested = (distance / HANDWRITTEN_SEGMENT_LENGTH).round().to_int()
  let segments = suggested.max(HANDWRITTEN_MIN_SEGMENTS)
  let variation = if suggested < HANDWRITTEN_MIN_SEGMENTS {
    self.variation / 3.0
  } else {
    self.variation
  }
  let step_x = (end.x - self.current.x) / segments.to_double()
  let step_y = (end.y - self.current.y) / segments.to_double()
  let fx = dx / distance
  let fy = dy / distance
  for index in 0..<segments {
    let offset = (self.random.next_double() - 0.5) * variation
    self.points.push({
      x: step_x * index.to_double() + self.current.x - offset * fy,
      y: step_y * index.to_double() + self.current.y - offset * fx,
    })
  }
  self.points.push(end)
  self.current = end
}

///|
fn HandJiggle::arc_to(
  self : HandJiggle,
  start_angle : Double,
  end_angle : Double,
  center : @graphics.Point,
  rx : Double,
  ry : Double,
) -> Unit {
  for angle in [(start_angle + end_angle) / 2.0, end_angle] {
    self.line_to({
      x: center.x + @math.cos(angle) * rx,
      y: center.y + @math.sin(angle) * ry,
    })
  }
}

///|
fn hand_midpoint(a : @graphics.Point, b : @graphics.Point) -> @graphics.Point {
  { x: (a.x + b.x) / 2.0, y: (a.y + b.y) / 2.0, }
}

///|
fn hand_distance_to_segment(
  point : @graphics.Point,
  start : @graphics.Point,
  end : @graphics.Point,
) -> Double {
  let dx = end.x - start.x
  let dy = end.y - start.y
  let squared = dx * dx + dy * dy
  let t = if squared == 0.0 {
    0.0
  } else {
    (((point.x - start.x) * dx + (point.y - start.y) * dy) / squared)
    .max(0.0)
    .min(1.0)
  }
  let x = point.x - start.x - t * dx
  let y = point.y - start.y - t * dy
  (x * x + y * y).sqrt()
}

///|
fn HandJiggle::curve_to(
  self : HandJiggle,
  start : @graphics.Point,
  first : @graphics.Point,
  second : @graphics.Point,
  end : @graphics.Point,
) -> Unit {
  let flatness = hand_distance_to_segment(first, start, end).max(
    hand_distance_to_segment(second, start, end),
  )
  let dx = end.x - start.x
  let dy = end.y - start.y
  if flatness > HANDWRITTEN_FLATNESS &&
    (dx * dx + dy * dy).sqrt() > HANDWRITTEN_CURVE_DISTANCE {
    let left = hand_midpoint(start, first)
    let middle = hand_midpoint(first, second)
    let right = hand_midpoint(second, end)
    let left_control = hand_midpoint(left, middle)
    let right_control = hand_midpoint(middle, right)
    let split = hand_midpoint(left_control, right_control)
    self.curve_to(start, left, left_control, split)
    self.curve_to(split, right_control, right, end)
  } else {
    self.line_to(end)
  }
}

///|
fn hand_path(points : Array[@graphics.Point]) -> Array[@graphics.PathSegment] {
  points.mapi((index, point) => {
    if index == 0 {
      @graphics.PathSegment::MoveTo(point)
    } else {
      @graphics.PathSegment::LineTo(point)
    }
  })
}

///|
fn handwritten_polygon(
  points : Array[@graphics.Point],
  random : JavaRandom,
) -> @graphics.Shape {
  guard points.get(0) is Some(start) else { return Polygon([]) }
  let jiggle = HandJiggle::new(start, HANDWRITTEN_POLYGON_VARIATION, random)
  for index in 1..<points.length() {
    jiggle.line_to(points[index])
  }
  jiggle.line_to(start)
  Polygon(jiggle.points)
}

///|
fn handwritten_rectangle(
  origin : @graphics.Point,
  width : Double,
  height : Double,
  rx : Double?,
  ry : Double?,
  random : JavaRandom,
) -> @graphics.Shape {
  // Graphic rectangle radii already use SVG radii, whereas Java URectangle
  // stores corner diameters and divides them in URectangleHand.
  let rx = rx.unwrap_or(0.0).min(width / 2.0)
  let ry = ry.unwrap_or(rx).min(height / 2.0)
  let point = (x, y) => @graphics.Point::{ x: origin.x + x, y: origin.y + y, }
  let jiggle = HandJiggle::new(
    point(rx, 0.0),
    HANDWRITTEN_POLYGON_VARIATION,
    random,
  )
  if rx == 0.0 && ry == 0.0 {
    jiggle.line_to(point(width, 0.0))
    jiggle.line_to(point(width, height))
    jiggle.line_to(point(0.0, height))
    jiggle.line_to(origin)
  } else {
    jiggle.line_to(point(width - rx, 0.0))
    jiggle.arc_to(-@math.PI / 2.0, 0.0, point(width - rx, ry), rx, ry)
    jiggle.line_to(point(width, height - ry))
    jiggle.arc_to(0.0, @math.PI / 2.0, point(width - rx, height - ry), rx, ry)
    jiggle.line_to(point(rx, height))
    jiggle.arc_to(@math.PI / 2.0, @math.PI, point(rx, height - ry), rx, ry)
    jiggle.line_to(point(0.0, ry))
    jiggle.arc_to(@math.PI, 3.0 * @math.PI / 2.0, point(rx, ry), rx, ry)
  }
  Polygon(jiggle.points)
}

///|
fn handwritten_ellipse(
  center : @graphics.Point,
  rx : Double,
  ry : Double,
  random : JavaRandom,
) -> @graphics.Shape {
  let points : Array[@graphics.Point] = []
  let mut angle = 0.0
  if rx == ry {
    while angle < @math.PI * 2.0 {
      angle += (10.0 + random.next_double() * 10.0) * @math.PI / 180.0
      let variation = 1.0 + (random.next_double() - 0.5) / 8.0
      points.push({
        x: center.x + @math.cos(angle) * rx * variation,
        y: center.y + @math.sin(angle) * ry * variation,
      })
    }
  } else {
    while angle < @math.PI * 2.0 {
      angle += @math.PI / 20.0
      let variation = (random.next_double() - 0.5) / 50.0
      points.push({
        x: center.x + @math.cos(angle) * rx + variation * rx * 2.0,
        y: center.y + @math.sin(angle) * ry + variation * ry * 2.0,
      })
    }
  }
  Polygon(points)
}

///|
/// UPathHand deliberately preserves paths containing a close or quadratic
/// command, and replaces SVG arcs by their chord. Earlier random draws still
/// occur when a later unsupported segment causes the original path to return.
fn handwritten_path(
  source : Array[@graphics.PathSegment],
  random : JavaRandom,
) -> Array[@graphics.PathSegment] {
  let result = []
  let mut last : @graphics.Point = { x: 0.0, y: 0.0, }
  for segment in source {
    match segment {
      MoveTo(point) => {
        result.push(segment)
        last = point
      }
      LineTo(point) => {
        let jiggle = HandJiggle::new(last, HANDWRITTEN_PATH_VARIATION, random)
        jiggle.line_to(point)
        for index in 1..<jiggle.points.length() {
          result.push(LineTo(jiggle.points[index]))
        }
        last = point
      }
      CubicTo(first, second, end) => {
        let jiggle = HandJiggle::new(last, HANDWRITTEN_LINE_VARIATION, random)
        jiggle.curve_to(last, first, second, end)
        for point in jiggle.points {
          result.push(LineTo(point))
        }
        last = end
      }
      ArcTo(end~, ..) => {
        result.push(LineTo(end))
        last = end
      }
      QuadraticTo(_, _) | Close => return source
    }
  }
  result
}

///|
/// UDotPathHand shares one jiggle over all its Beziers. Metadata records the
/// original DotPath primitive when an SVG path alone would lose that distinction.
fn handwritten_dot_path(
  source : Array[@graphics.PathSegment],
  random : JavaRandom,
) -> Array[@graphics.PathSegment] {
  guard source.get(0) is Some(MoveTo(start)) else {
    return handwritten_path(source, random)
  }
  let jiggle = HandJiggle::new(start, HANDWRITTEN_LINE_VARIATION, random)
  let mut last = start
  for index in 1..<source.length() {
    guard source[index] is CubicTo(first, second, end) else {
      return handwritten_path(source, random)
    }
    jiggle.curve_to(last, first, second, end)
    last = end
  }
  hand_path(jiggle.points)
}

///|
/// Called once per Graphic context; apply/translate/style derives a fresh
/// factory result, matching UGraphicHandwritten.apply rather than a SVG filter.
pub fn handwritten_shape_transform() -> (@graphics.Shape, @graphics.Metadata) -> @graphics.Shape {
  let random = JavaRandom::new(HANDWRITTEN_SEED)
  (shape, metadata) => {
    match shape {
      Line(start, end) => {
        let jiggle = HandJiggle::new(start, HANDWRITTEN_LINE_VARIATION, random)
        jiggle.line_to(end)
        Path(hand_path(jiggle.points))
      }
      Rectangle(origin~, width~, height~, rx~, ry~) =>
        handwritten_rectangle(origin, width, height, rx, ry, random)
      Polygon(points) => handwritten_polygon(points, random)
      Circle(center~, radius~) =>
        handwritten_ellipse(center, radius, radius, random)
      Ellipse(center~, rx~, ry~) => handwritten_ellipse(center, rx, ry, random)
      Path(path) =>
        Path(
          if metadata.data.contains(("handwritten-path", "dot")) {
            handwritten_dot_path(path, random)
          } else {
            handwritten_path(path, random)
          },
        )
      MarkedPath(path, markers) =>
        MarkedPath(
          if metadata.data.contains(("handwritten-path", "dot")) {
            handwritten_dot_path(path, random)
          } else {
            handwritten_path(path, random)
          },
          markers,
        )
      _ => shape
    }
  }
}

///|
pub fn handwritten_graphic(
  output : @graphics.Graphic,
  style : @style.DocumentStyle,
) -> @graphics.Graphic {
  if style
    .property("Handwritten")
    .map_or(false, value => value.to_lower() == "true") {
    output.with_shape_transform(handwritten_shape_transform)
  } else {
    output
  }
}
