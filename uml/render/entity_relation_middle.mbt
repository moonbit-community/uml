///|
/// DotPath.getMiddle elects an endpoint or half-curve point minimizing the
/// sum of squared distances to the path's two endpoints.
fn relation_middle(
  edge : @graphviz.GraphvizEdge,
) -> ((Double, Double), Double)? {
  guard relation_edge_endpoint(edge, true) is Some(start) &&
    relation_edge_endpoint(edge, false) is Some(end) else {
    return None
  }
  let mut selected : ((Double, Double), Double, Double)? = None
  let consider = (position : (Double, Double), direction : (Double, Double)) => {
    let cost = relation_point_distance_squared(position, start) +
      relation_point_distance_squared(position, end)
    if selected.map_or(true, previous => cost < previous.2) {
      selected = Some((position, @math.atan2(direction.1, direction.0), cost))
    }
  }
  for spline in edge.splines {
    let path = spline.points
    guard path.length() > 1 else { continue }
    if (path.length() - 1) % 3 == 0 {
      for index in 0..<((path.length() - 1) / 3) {
        let a = path[index * 3]
        let b = path[index * 3 + 1]
        let c = path[index * 3 + 2]
        let d = path[index * 3 + 3]
        consider(a.pair(), (b.x - a.x, b.y - a.y))
        consider(
          (
            (a.x + 3 * b.x + 3 * c.x + d.x) / 8.0,
            (a.y + 3 * b.y + 3 * c.y + d.y) / 8.0,
          ),
          (d.x + c.x - b.x - a.x, d.y + c.y - b.y - a.y),
        )
        consider(d.pair(), (d.x - c.x, d.y - c.y))
      }
    } else {
      for index in 1..<path.length() {
        let a = path[index - 1]
        let b = path[index]
        let direction = (b.x - a.x, b.y - a.y)
        consider(a.pair(), direction)
        consider(((a.x + b.x) / 2.0, (a.y + b.y) / 2.0), direction)
        consider(b.pair(), direction)
      }
    }
  }
  selected.map(value => (value.0, value.1))
}

///|
const MIDDLE_OUTER_RADIUS : Double = 10.0

///|
fn draw_relation_middle(
  output : @graphics.Graphic,
  edge : @graphviz.GraphvizEdge,
  inside : String,
  color : String,
  background : String,
) -> Unit {
  guard relation_middle(edge) is Some((center, direction)) else { return }
  let radius = MIDDLE_OUTER_RADIUS
  if inside == "(0)" {
    output
    .with_style({
      ..Default::default(),
      fill: Color(background),
      stroke: Color(background),
      inline: true,
    })
    .draw(Circle(center={ x: center.0, y: center.1, }, radius~))
  }
  let arc = (angle : Double) => {
    let start = (
      center.0 + radius * @math.cos(angle),
      center.1 + radius * @math.sin(angle),
    )
    let end_angle = angle - @math.PI / 2.0
    let end = (
      center.0 + radius * @math.cos(end_angle),
      center.1 + radius * @math.sin(end_angle),
    )
    draw_relation_decoration_primitive(
      output,
      {
        shape: DecorationArc({
          start,
          end,
          radius,
          large_arc: false,
          sweep: false,
        }),
        fill: NoDecorationFill,
        stroke_width: 1.5,
      },
      color,
      background,
    )
  }
  let angle = direction + @math.PI / 4.0
  if inside == "0)" || inside == "(0)" {
    arc(angle)
  }
  if inside == "(0" || inside == "(0)" {
    arc(angle + @math.PI)
  }
  draw_relation_decoration_primitive(
    output,
    {
      shape: DecorationCircle(center, CIRCLE_RADIUS),
      fill: BackgroundDecorationFill,
      stroke_width: 1.5,
    },
    color,
    background,
  )
}
