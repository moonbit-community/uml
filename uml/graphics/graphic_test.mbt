///|
test "derived contexts compose translations and isolate sibling styles" {
  let commands = []
  let graphic = @graphics.Graphic::new(command => commands.push(command))
  let offset : @graphics.Point = { x: 17.25, y: -8.5, }
  let child_offset : @graphics.Point = { x: -4.5, y: 31.75, }
  let style = {
    ..@graphics.DrawingStyle::default(),
    stroke: @graphics.Paint::Color("navy"),
  }
  let shape = @graphics.Shape::Line(offset, child_offset)
  graphic
  .translated(offset.x, offset.y)
  .with_style(style)
  .translated(child_offset.x, child_offset.y)
  .draw(shape)
  graphic.draw(shape)
  @test.assert_eq(commands, [
    @graphics.DrawCommand::Draw(
      shape,
      style,
      { x: offset.x + child_offset.x, y: offset.y + child_offset.y, },
      @graphics.Metadata::default(),
    ),
    @graphics.DrawCommand::Draw(
      shape,
      @graphics.DrawingStyle::default(),
      @graphics.Point::default(),
      @graphics.Metadata::default(),
    ),
  ])
}

///|
test "groups and links retain nesting and draw order" {
  let commands = []
  let graphic = @graphics.Graphic::new(command => commands.push(command))
  let metadata = { ..@graphics.Metadata::default(), class_name: Some("node"), }
  let url = "https://example.invalid/?a=one&b=two"
  let shape = @graphics.Shape::Path([])
  graphic.group(metadata, group => group.link(url, link => link.draw(shape)))
  graphic.draw(shape)
  let draw = @graphics.DrawCommand::Draw(
    shape,
    @graphics.DrawingStyle::default(),
    @graphics.Point::default(),
    @graphics.Metadata::default(),
  )
  @test.assert_eq(commands, [
    @graphics.DrawCommand::BeginGroup(metadata),
    @graphics.DrawCommand::BeginLink(url),
    draw,
    @graphics.DrawCommand::EndLink,
    @graphics.DrawCommand::EndGroup,
    draw,
  ])
}

///|
test "recorded geometry metadata and styles own their array snapshots" {
  let commands = []
  let graphic = @graphics.Graphic::new(command => commands.push(command))
  let origin = @graphics.Point::default()
  let segments = [@graphics.PathSegment::MoveTo(origin)]
  let data = [("code", "original")]
  let dash = [3.5, 2.25]
  let initial_segments = segments.copy()
  let initial_data = data.copy()
  let initial_dash = dash.copy()
  let styled = graphic.with_style({
    ..@graphics.DrawingStyle::default(),
    dash: Some(dash),
  })
  styled.draw(Path(segments), metadata={
    ..@graphics.Metadata::default(),
    data,
  })
  segments.push(Close)
  data.push(("code", "changed"))
  dash.push(9.75)
  styled.draw(Path(initial_segments), metadata={
    ..@graphics.Metadata::default(),
    data: initial_data,
  })
  for command in commands {
    guard command is Draw(Path(path), style, _, metadata) else {
      @test.fail("expected a path")
    }
    @test.assert_eq(path, initial_segments)
    @test.assert_eq(metadata.data, initial_data)
    @test.assert_eq(style.dash, Some(initial_dash))
  }
}

///|
test "spline conversion preserves every cubic control point in order" {
  for curve_count in 1..<8 {
    let points = Array::makei(curve_count * 3 + 1, index => {
      (index.to_double(), -index.to_double())
    })
    let restored = []
    for segment in @graphics.spline_segments(points) {
      match segment {
        MoveTo(point) => restored.push((point.x, point.y))
        CubicTo(first, second, end) => {
          restored.push((first.x, first.y))
          restored.push((second.x, second.y))
          restored.push((end.x, end.y))
        }
        _ => @test.fail("a cubic spline must not be flattened")
      }
    }
    @test.assert_eq(restored, points)
  }
}

///|
test "non cubic point lists retain their polyline geometry" {
  for length in 0..<12 {
    if length > 0 && (length - 1) % 3 == 0 {
      continue
    }
    let points = Array::makei(length, index => {
      (index.to_double(), index.to_double())
    })
    let restored = []
    for segment in @graphics.spline_segments(points) {
      match segment {
        MoveTo(point) | LineTo(point) => restored.push((point.x, point.y))
        _ => @test.fail("expected a polyline")
      }
    }
    @test.assert_eq(restored, points)
  }
}
