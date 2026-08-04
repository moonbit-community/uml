///|
test "document font settings select metrics profile and size" {
  let monospace = DocumentStyle::empty()
  monospace.apply(FontFamily("Courier"))
  monospace.apply(FontSize("16px"))
  @test.assert_eq(font_profile(monospace), Monospace)
  @test.assert_eq(font_size_value(monospace), 16)
  @test.assert_eq(monospace.font_metrics().font_size, 16)

  let points = DocumentStyle::empty()
  points.apply(FontSize("12pt"))
  @test.assert_eq(font_size_value(points), 16)

  let serif = DocumentStyle::empty()
  serif.apply(FontFamily("Times New Roman, serif"))
  @test.assert_eq(font_profile(serif), Serif)

  let sans = DocumentStyle::empty()
  sans.apply(FontFamily("Arial, sans-serif"))
  @test.assert_eq(font_profile(sans), Sans)
}

///|
test "font name skinparams preserve families with spaces" {
  @test.assert_eq(
    parse_style_property("UsecaseFontName Times New Roman"),
    Some(Property("UsecaseFontName", "Times New Roman")),
  )
  @test.assert_eq(
    parse_style_property("ActorFontName Courier New"),
    Some(Property("ActorFontName", "Courier New")),
  )
  @test.assert_eq(
    parse_style_property("ClassStereotypeFontName Times New Roman"),
    Some(Property("ClassStereotypeFontName", "Times New Roman")),
  )
}

///|
test "document color resolution uses shared render defaults and skinparams" {
  let style = DocumentStyle::empty()
  let defaults = render_defaults()
  @test.assert_eq(style.canvas_color(), defaults.canvas_background)
  @test.assert_eq(style.diagram_line_color(), defaults.diagram_line)
  @test.assert_eq(style.class_background_color(), defaults.node_background)
  @test.assert_eq(style.note_background_color(), defaults.note_background)

  style.apply(Property("ClassBackgroundColor", "#123456"))
  style.apply(Property("ClassBorderColor", "#654321"))
  style.apply(Property("PackageBackgroundColor", "#abcdef"))
  style.apply(Property("UsecaseBackgroundColor", "#456789"))
  style.apply(Property("ActorBorderColor", "#987654"))
  style.apply(Property("actorStyle", "awesome"))
  style.apply(Property("UsecaseFontColor", "#abc123"))
  style.apply(Property("ActorFontColor", "#def456"))
  style.apply(Property("UsecaseFontSize", "16"))
  style.apply(Property("ActorFontSize", "12pt"))
  style.apply(Property("UsecaseFontName", "Courier"))
  style.apply(Property("ActorFontName", "Times New Roman"))
  style.apply(Property("ClassStereotypeFontColor", "#123abc"))
  style.apply(Property("ClassStereotypeFontSize", "17"))
  style.apply(Property("ClassStereotypeFontName", "Georgia"))
  style.apply(Property("ArrowFontColor", "#abcd12"))
  style.apply(Property("ArrowFontSize", "15"))
  style.apply(Property("ArrowFontName", "Courier New"))
  @test.assert_eq(style.class_background_color(), "#123456")
  @test.assert_eq(style.class_border_color(), "#654321")
  @test.assert_eq(style.package_background_color(), "#abcdef")
  @test.assert_eq(style.usecase_background_color(), "#456789")
  @test.assert_eq(style.actor_border_color(), "#987654")
  @test.assert_eq(style.actor_style(), "awesome")
  @test.assert_eq(style.usecase_font_color(), "#abc123")
  @test.assert_eq(style.actor_font_color(), "#def456")
  @test.assert_eq(style.usecase_font_size(fallback=14), 16)
  @test.assert_eq(style.actor_font_size(fallback=14), 16)
  @test.assert_eq(style.usecase_font_family(), "Courier")
  @test.assert_eq(style.actor_font_family(), "Times New Roman")
  @test.assert_eq(style.class_stereotype_font_color(), "#123abc")
  @test.assert_eq(style.class_stereotype_font_size(fallback=12), 17)
  @test.assert_eq(style.class_stereotype_font_family(), "Georgia")
  @test.assert_eq(style.arrow_font_color(), "#abcd12")
  @test.assert_eq(style.arrow_font_size(fallback=13), 15)
  @test.assert_eq(style.arrow_font_family(), "Courier New")
}

///|
test "distinguishes legend alignment headers from single-line legends" {
  @test.assert_eq(parse_style_directive("legend top left"), None)
  @test.assert_eq(
    parse_style_directive("legend: Key"),
    Some(TextBlock("legend", "Key")),
  )
  @test.assert_eq(
    parse_style_directive("center header Report"),
    Some(TextBlock("header", "Report")),
  )
}
