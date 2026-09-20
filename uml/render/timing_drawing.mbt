///|
priv struct TimingDrawing {
  style : @style.DocumentStyle
  commands : Array[@graphics.DrawCommand]
  mut min_x : Double
  mut min_y : Double
  mut max_x : Double
  mut max_y : Double
}

///|
fn TimingDrawing::point(self : TimingDrawing, x : Double, y : Double) -> Unit {
  self.min_x = self.min_x.min(x)
  self.min_y = self.min_y.min(y)
  self.max_x = self.max_x.max(x)
  self.max_y = self.max_y.max(y)
}

///|
fn TimingDrawing::graphic(
  self : TimingDrawing,
  paint : @graphics.DrawingStyle,
) -> @graphics.Graphic {
  @graphics.Graphic::new(command => self.commands.push(command)).with_style(
    paint,
  )
}

///|
fn TimingDrawing::line(
  self : TimingDrawing,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  paint : @graphics.DrawingStyle,
  class_name? : String = "timing-wave",
) -> Unit {
  self.point(x1, y1)
  self.point(x2, y2)
  self
  .graphic(paint)
  .draw(Line({ x: x1, y: y1, }, { x: x2, y: y2, }), metadata={
    ..Default::default(),
    class_name: Some(class_name),
  })
}

///|
fn TimingDrawing::polygon(
  self : TimingDrawing,
  points : Array[@graphics.Point],
  paint : @graphics.DrawingStyle,
  class_name? : String = "timing-ribbon",
  closed? : Bool = true,
) -> Unit {
  guard !points.is_empty() else { return }
  for point in points {
    self.point(point.x, point.y)
  }
  let shape = if closed {
    @graphics.Shape::Polygon(points)
  } else {
    let segments = [@graphics.PathSegment::MoveTo(points[0])]
    for index in 1..<points.length() {
      segments.push(LineTo(points[index]))
    }
    @graphics.Shape::Path(segments)
  }
  self
  .graphic(paint)
  .draw(shape, metadata={ ..Default::default(), class_name: Some(class_name), })
}

///|
fn TimingDrawing::rect(
  self : TimingDrawing,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  paint : @graphics.DrawingStyle,
  class_name? : String = "timing-region",
) -> Unit {
  self.point(x, y)
  self.point(x + width, y + height)
  self
  .graphic(paint)
  .draw(Rectangle(origin={ x, y, }, width~, height~, rx=None, ry=None), metadata={
    ..Default::default(),
    class_name: Some(class_name),
  })
}

///|
fn TimingDrawing::text(
  self : TimingDrawing,
  text : String,
  x : Double,
  y : Double,
  role : String,
  anchor? : @graphics.TextAnchor = Start,
) -> Unit {
  guard !text.is_empty() else { return }
  let appearance = timing_appearance(self.style, role)
  let size = timing_text_size(text, appearance)
  let dx = match anchor {
    Start => 0.0
    Middle => size.0 / 2.0
    End => size.0
  }
  self.point(x - dx, y)
  self.point(x - dx + size.0, y + size.1)
  append_state_text_at_top(
    self.graphic({ ..Default::default(), fill: Color(appearance.color), }),
    text,
    x,
    y,
    "timing-" + role + "-label",
    appearance.metrics,
    anchor~,
  )
}

///|
fn TimingDrawing::arrow(
  self : TimingDrawing,
  start : @graphics.Point,
  end : @graphics.Point,
  paint : @graphics.DrawingStyle,
) -> (@graphics.Point, @graphics.Point) {
  let dx = end.x - start.x
  let dy = end.y - start.y
  let length = (dx * dx + dy * dy).sqrt()
  guard length > 0.0 else { return (end, end) }
  let ux = dx / length
  let uy = dy / length
  let back = TIMING_ARROW_LENGTH * @math.cos(TIMING_ARROW_ANGLE)
  let side = TIMING_ARROW_LENGTH * @math.sin(TIMING_ARROW_ANGLE)
  let first : @graphics.Point = {
    x: end.x - ux * back - uy * side,
    y: end.y - uy * back + ux * side,
  }
  let second : @graphics.Point = {
    x: end.x - ux * back + uy * side,
    y: end.y - uy * back - ux * side,
  }
  self.line(start.x, start.y, end.x, end.y, paint, class_name="timing-message")
  self.polygon(
    [first, second, end],
    { ..paint, fill: paint.stroke, },
    class_name="timing-arrowhead",
  )
  (first, second)
}

///|
fn timing_wave_paint(
  appearance : TimingAppearance,
  color : String?,
) -> @graphics.DrawingStyle {
  {
    ..appearance.paint(fill=true),
    fill: Color(timing_color_part(color, "back", appearance.fill)),
    stroke: Color(timing_color_part(color, "line", appearance.line)),
  }
}
