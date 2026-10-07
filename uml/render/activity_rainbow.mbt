///|
/// WormMutation describes how successive parallel snakes move at each turn.
fn activity_mutation_definition(signature : String) -> String {
  match signature {
    "D" | "U" => "33"
    "L" | "R" => "55"
    "RD" => "123"
    "RU" => "543"
    "LD" => "187"
    "LU" => "567"
    "DL" => "345"
    "DR" => "765"
    "UL" => "321"
    "UR" => "781"
    _ => abort("non-orthogonal activity snake")
  }
}

///|
fn activity_mutation_vector(code : Char, delta : Double) -> @graphics.Point {
  match code {
    '1' => { x: 0.0, y: -delta, }
    '2' => { x: delta, y: -delta, }
    '3' => { x: delta, y: 0.0, }
    '4' => { x: delta, y: delta, }
    '5' => { x: 0.0, y: delta, }
    '6' => { x: -delta, y: delta, }
    '7' => { x: -delta, y: 0.0, }
    _ => { x: -delta, y: -delta, }
  }
}

///|
fn activity_rainbow_paths(
  path : Array[@graphics.PathSegment],
  count : Int,
  separation : Double,
) -> (Array[Array[@graphics.PathSegment]], Bool, Double) {
  let points : Array[@graphics.Point] = []
  for segment in path {
    let point = match segment {
      MoveTo(point) | LineTo(point) => point
      _ => abort("nonlinear activity snake")
    }
    if points.last().map_or(false, previous => previous == point) {
      continue
    }
    if points.length() > 1 {
      let a = points[points.length() - 2]
      let b = points[points.length() - 1]
      if (a.x == b.x && b.x == point.x && (b.y - a.y) * (point.y - b.y) >= 0.0) ||
        (a.y == b.y && b.y == point.y && (b.x - a.x) * (point.x - b.x) >= 0.0) {
        ignore(points.pop())
      }
    }
    points.push(point)
  }
  guard points.length() > 1 else { return ([path], false, 0.0) }
  let directions : Array[String] = []
  for index in 1..<points.length() {
    let a = points[index - 1]
    let b = points[index]
    directions.push(
      if a.x == b.x {
        if b.y > a.y {
          "D"
        } else {
          "U"
        }
      } else if b.x > a.x {
        "R"
      } else {
        "L"
      },
    )
  }
  let delta = 2.0 + separation
  let vectors : Array[@graphics.Point] = []
  if directions.length() == 1 {
    for code in activity_mutation_definition(directions[0]) {
      vectors.push(activity_mutation_vector(code, delta))
    }
  } else {
    for index in 0..<(directions.length() - 1) {
      let definition = activity_mutation_definition(
        directions[index] + directions[index + 1],
      )
      let values = definition
        .to_array()
        .map(code => activity_mutation_vector(code, delta))
      if index == 0 {
        vectors.push(values[0])
      } else if vectors.last().unwrap() != values[0] {
        for item, value in values {
          values[item] = { x: -value.x, y: -value.y, }
        }
      }
      vectors.push(values[1])
      if index == directions.length() - 2 {
        vectors.push(values[2])
      }
    }
  }
  let global = -(count - 1).to_double() / 2.0
  let first = vectors[0]
  let shift = (
    point : @graphics.Point,
    vector : @graphics.Point,
    amount : Double,
  ) => @graphics.Point::{
    x: point.x + vector.x * amount,
    y: point.y + vector.y * amount,
  }
  points[0] = shift(points[0], first, global)
  points[1] = shift(points[1], first, global)
  if vectors.length() > 2 {
    let last = vectors.last().unwrap()
    let end = points.length() - 1
    points[end] = shift(points[end], last, global)
    points[end - 1] = shift(points[end - 1], last, global)
  }
  let paths = []
  for color in 0..<count {
    paths.push(
      points.mapi((index, point) => {
        let point = shift(point, vectors[index], color.to_double())
        if index == 0 {
          @graphics.PathSegment::MoveTo(point)
        } else {
          @graphics.PathSegment::LineTo(point)
        }
      }),
    )
  }
  let extreme = vectors.fold(init=0.0, (value, vector) => {
    if vector.x.abs() > value.abs() {
      vector.x
    } else {
      value
    }
  })
  (paths, first.x < 0.0, extreme * (count - 1).to_double())
}

///|
fn activity_edge_commands(
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
  metrics : @metrics.FontMetrics,
) -> Array[@graphics.DrawCommand] {
  let commands = []
  append_edge(
    @graphics.Graphic::new(command => commands.push(command)),
    layout,
    edge,
    metrics,
    @graphics.MarkerRef::new("activity-provisional-arrow"),
  )
  commands
}

///|
fn append_activity_rainbow(
  output : @graphics.Graphic,
  document : @svg.SvgDocument,
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
  metrics : @metrics.FontMetrics,
  default_color : String,
  index : Int,
) -> Unit {
  let colors = edge.style
    .unwrap_or("")
    .split(";")
    .map(StringView::to_owned)
    .to_array()
  for command in activity_edge_commands(layout, edge, metrics) {
    match command {
      Draw(MarkedPath(path, markers), _, translation, metadata) => {
        let (paths, reverse, _) = activity_rainbow_paths(
          path,
          colors.length(),
          edge.rainbow_separation,
        )
        for color_index, path in paths {
          let color = colors[if reverse {
              colors.length() - 1 - color_index
            } else {
              color_index
            }]
          let paint = activity_arrow_style(Some(color), default_color)
          let paint = {
            ..paint,
            stroke_width: if paint.dash is Some(dash) && !dash.is_empty() {
              Some(
                if edge.rainbow_separation == 0.0 {
                  if color_index == colors.length() - 1 {
                    2.0
                  } else {
                    3.0
                  }
                } else {
                  1.5
                },
              )
            } else {
              paint.stroke_width
            },
          }
          let marker = define_activity_arrow(
            document,
            match paint.stroke {
              Color(value) => value
              _ => "none"
            },
            id="activity-arrow-" +
              index.to_string() +
              "-" +
              color_index.to_string(),
          )
          output
          .translated(translation.x, translation.y)
          .with_style(paint)
          .draw(
            MarkedPath(path, {
              start: None,
              end: if markers.end is Some(_) {
                Some(marker)
              } else {
                None
              },
            }),
            metadata~,
          )
        }
      }
      Draw(shape, paint, translation, metadata) =>
        output
        .translated(translation.x, translation.y)
        .with_style(paint)
        .draw(shape, metadata~)
      _ => ()
    }
  }
}

///|
fn activity_rainbow_extents(
  edge : ActivityEdgeLayout,
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
  nodes : Array[@flow.ActivityNode],
) -> (Double, Double, Double)? {
  let count = edge.style.map_or(1, value => value.split(";").count())
  guard count > 1 else { return None }
  let layout : ActivityLayout = {
    nodes: [from, to],
    edges: [],
    regions: [],
    source_nodes: nodes,
    width: 0.0,
    height: 0.0,
  }
  let metrics = @metrics.FontMetrics::from_defaults(font_size=SMALL_FONT)
  let mut left = from.x + from.width / 2.0
  let mut right = left
  let mut text_dx = 0.0
  for
    command in activity_edge_commands(layout, { ..edge, label: None, }, metrics) {
    guard command is Draw(MarkedPath(path, _), _, _, metadata) else { continue }
    let (paths, _, dx) = activity_rainbow_paths(
      path,
      count,
      edge.rainbow_separation,
    )
    if !metadata.data.is_empty() {
      text_dx = dx
    }
    for path in paths {
      for segment in path {
        match segment {
          MoveTo(point) | LineTo(point) => {
            left = left.min(point.x)
            right = right.max(point.x)
          }
          _ => ()
        }
      }
    }
  }
  Some((left, right, text_dx))
}
