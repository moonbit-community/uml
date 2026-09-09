///|
/// Read one serializer-owned attribute, independently of its order in a tag.
fn attribute(xml : String, name : String) -> String? {
  let marker = " \{name}=\""
  guard xml.find(marker) is Some(start) else { return None }
  let rest = xml[start + marker.length():].to_owned()
  guard rest.find("\"") is Some(end) else { return None }
  Some(rest[:end].to_owned())
}

///|
test "translation moves positions without changing dimensions" {
  let origin : @graphics.Point = { x: -12.75, y: 23.5, }
  let size : @graphics.Point = { x: 48.25, y: 31.5, }
  let offset : @graphics.Point = { x: 17.5, y: -9.25, }
  let writer = @svg.XmlWriter::new()
  writer
  .graphic()
  .translated(offset.x, offset.y)
  .draw(Rectangle(origin~, width=size.x, height=size.y, rx=None, ry=None))
  let xml = writer.to_string()
  @test.assert_eq(attribute(xml, "x"), Some((origin.x + offset.x).to_string()))
  @test.assert_eq(attribute(xml, "y"), Some((origin.y + offset.y).to_string()))
  @test.assert_eq(attribute(xml, "width"), Some(size.x.to_string()))
  @test.assert_eq(attribute(xml, "height"), Some(size.y.to_string()))
}

///|
test "text preserves the supplied layout advance and escapes once" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let text = "A < B & C"
  // Include a layout-owned spacing adjustment. The backend must not
  // silently replace it by measuring the string again.
  let advance = (metrics.measure(text).advance_width + metrics.font_size).to_double()
  let writer = @svg.XmlWriter::new()
  writer
  .graphic()
  .draw(
    Text({
      text,
      position: @graphics.Point::default(),
      advance: Some(advance),
      anchor: Start,
      font_size: metrics.font_size.to_double(),
      font_family: None,
      strike: true,
    }),
  )
  let xml = writer.to_string()
  @test.assert_eq(attribute(xml, "textLength"), Some(advance.to_string()))
  @test.assert_eq(attribute(xml, "lengthAdjust"), Some("spacing"))
  @test.assert_eq(xml.contains(@svg.xml_escape_text(text)), true)
  @test.assert_eq(xml.contains("&amp;lt;"), false)
  @test.assert_eq(attribute(xml, "text-decoration"), Some("line-through"))
}

///|
test "paint inheritance is distinct from explicitly disabling paint" {
  let inherited = @svg.XmlWriter::new()
  let disabled = @svg.XmlWriter::new()
  let shape = @graphics.Shape::Path([])
  inherited.graphic().draw(shape)
  disabled
  .graphic()
  .with_style({
    ..@graphics.DrawingStyle::default(),
    fill: None,
    stroke: None,
    dash: Some([]),
  })
  .draw(shape)
  @test.assert_eq(attribute(inherited.to_string(), "fill"), None)
  @test.assert_eq(attribute(disabled.to_string(), "fill"), Some("none"))
  @test.assert_eq(attribute(disabled.to_string(), "stroke"), Some("none"))
  @test.assert_eq(
    attribute(disabled.to_string(), "stroke-dasharray"),
    Some("none"),
  )
}

///|
test "link and metadata values cannot inject XML elements or attributes" {
  let value = "\"/><script> & more"
  let writer = @svg.XmlWriter::new()
  writer
  .graphic()
  .group(
    {
      ..@graphics.Metadata::default(),
      class_name: Some(value),
      data: [("code", value)],
    },
    graphic => graphic.link(value, link => link.draw(Path([]))),
  )
  let xml = writer.to_string()
  @test.assert_eq(
    attribute(xml, "class"),
    Some(@svg.xml_escape_attribute(value)),
  )
  @test.assert_eq(
    attribute(xml, "data-code"),
    Some(@svg.xml_escape_attribute(value)),
  )
  @test.assert_eq(
    attribute(xml, "href"),
    Some(@svg.xml_escape_attribute(value)),
  )
  @test.assert_eq(xml.contains("<script>"), false)
}

///|
test "marker definitions allocate distinct IDs and paths reference their handles" {
  let document = @svg.SvgDocument::empty(100, 100, "markers")
  let size = @metrics.FontMetrics::from_defaults().font_size.to_double()
  let first = document.arrow_marker(
    "arrow",
    marker_width=size,
    marker_height=size,
    fill="black",
  )
  let second = document.arrow_marker(
    "arrow",
    marker_width=size,
    marker_height=size,
    fill="black",
  )
  @test.assert_eq(first == second, false)
  document
  .graphic()
  .draw(MarkedPath([], { start: Some(first), end: Some(second), }))
  let xml = document.to_string()
  let definitions = xml.split("<marker ").to_array()
  let ids = definitions[1:].map(definition => {
    attribute(" " + definition.to_owned(), "id").unwrap()
  })
  @test.assert_eq(ids, [first.id, second.id])
  @test.assert_eq(attribute(xml, "marker-start"), Some("url(#\{first.id})"))
  @test.assert_eq(attribute(xml, "marker-end"), Some("url(#\{second.id})"))
}

///|
test "multiline driver retains per-line spacing advance and XML text boundaries" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let block = @svg.layout_multiline_text(
    0.0,
    0.0,
    "first < line\n\nlast & line",
    line_height=metrics.line_height.to_double(),
    text_metrics=Some(metrics),
  )
  let offset = metrics.font_size.to_double()
  let writer = @svg.XmlWriter::new()
  writer.graphic().translated(offset, offset).draw(TextBlock(block))
  let xml = writer.to_string()
  @test.assert_eq(
    attribute(xml, "y"),
    Some((block.position.y + offset).to_string()),
  )
  let spans = xml.split("<tspan ").to_array()[1:]
  @test.assert_eq(spans.length(), block.lines.length())
  for index, span in spans {
    let line = block.lines[index]
    let xml = " " + span.to_owned()
    @test.assert_eq(
      attribute(xml, "x"),
      Some((block.position.x + offset).to_string()),
    )
    @test.assert_eq(attribute(xml, "dy"), Some(line.dy.to_string()))
    @test.assert_eq(
      attribute(xml, "textLength"),
      line.advance.map(advance => advance.to_string()),
    )
    @test.assert_eq(xml.contains(@svg.xml_escape_text(line.text)), true)
  }
}

///|
test "styled multiline blocks supply fonts without changing inherited blocks" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let block = @svg.layout_multiline_text(
    0.0,
    0.0,
    "label",
    line_height=metrics.line_height.to_double(),
    text_metrics=Some(metrics),
  )
  let font = {
    ..@graphics.TextStyle::default(),
    font_size: Some(metrics.font_size.to_double()),
  }
  let styled = @svg.XmlWriter::new()
  let inherited = @svg.XmlWriter::new()
  styled.graphic().draw(StyledTextBlock(block, font))
  inherited.graphic().draw(TextBlock(block))
  @test.assert_eq(
    attribute(styled.to_string(), "font-size"),
    font.font_size.map(size => size.to_string()),
  )
  @test.assert_eq(attribute(inherited.to_string(), "font-size"), None)
  @test.assert_eq(
    attribute(styled.to_string(), "textLength"),
    attribute(inherited.to_string(), "textLength"),
  )
}
