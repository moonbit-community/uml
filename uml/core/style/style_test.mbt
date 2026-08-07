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
  @test.assert_eq(
    parse_style_property("StateFontName Courier New"),
    Some(Property("StateFontName", "Courier New")),
  )
}

///|
test "document color resolution uses shared render defaults and skinparams" {
  let style = DocumentStyle::empty()
  let defaults = ColorScheme::default()
  @test.assert_eq(style.canvas_color(), defaults.canvas)
  @test.assert_eq(style.diagram_line_color(), defaults.line)

  style.apply(BackgroundColor("#012345"))
  style.apply(LineColor("#654321"))
  @test.assert_eq(style.canvas_color(), "#012345")
  @test.assert_eq(style.diagram_line_color(), "#654321")
}

///|
test "generic skinparam resolvers use shared defaults and fallbacks" {
  let style = DocumentStyle::empty()
  let defaults = ColorScheme::default()
  @test.assert_eq(
    style.property_color("ClassBackgroundColor", defaults.node),
    defaults.node,
  )
  @test.assert_eq(
    style.property_color("NoteBackgroundColor", defaults.note),
    defaults.note,
  )
  @test.assert_eq(style.property_font_color("UsecaseFontColor"), defaults.text)
  @test.assert_eq(style.property_font_size("UsecaseFontSize", fallback=14), 14)
  @test.assert_eq(
    style.property_font_family("UsecaseFontName"),
    style.font_family(),
  )

  style.apply(Property("ClassBackgroundColor", "#123456"))
  style.apply(Property("UsecaseFontColor", "#abc123"))
  style.apply(Property("UsecaseFontSize", "16"))
  style.apply(Property("UsecaseFontName", "Courier"))
  @test.assert_eq(
    style.property_color("ClassBackgroundColor", defaults.node),
    "#123456",
  )
  @test.assert_eq(style.property_font_color("UsecaseFontColor"), "#abc123")
  @test.assert_eq(style.property_font_size("UsecaseFontSize", fallback=14), 16)
  @test.assert_eq(style.property_font_family("UsecaseFontName"), "Courier")
}

///|
test "skinparam properties resolve without regard to property-key casing" {
  let style = DocumentStyle::empty()
  style.apply(Property("stateBackgroundColor", "#123456"))
  style.apply(Property("STATEBORDERCOLOR", "#654321"))
  @test.assert_eq(style.property("StateBackgroundColor"), Some("#123456"))
  @test.assert_eq(style.property("StateBorderColor"), Some("#654321"))
}

///|
test "theme projections keep family roles outside document style" {
  let scheme = ColorScheme::ColorScheme(
    "theme-text",
    "theme-line",
    participant="theme-participant",
    activation="theme-activation",
    visibility_private_stroke="theme-private-stroke",
    visibility_private_fill="theme-private-fill",
  )
  let sequence = scheme.sequence_colors()
  let entity = scheme.entity_colors()
  @test.assert_eq(sequence.text, "theme-text")
  @test.assert_eq(sequence.participant, "theme-participant")
  @test.assert_eq(sequence.activation, "theme-activation")
  @test.assert_eq(entity.text, "theme-text")
  @test.assert_eq(entity.visibility_private_stroke, "theme-private-stroke")
  @test.assert_eq(entity.visibility_private_fill, "theme-private-fill")
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

///|
test "empty description visibility directives preserve their latest value" {
  @test.assert_eq(
    parse_style_directive("hide empty description"),
    Some(Property("hide empty description", "true")),
  )
  @test.assert_eq(
    parse_style_directive("show empty description"),
    Some(Property("hide empty description", "false")),
  )
  let style = DocumentStyle::empty()
  style.apply(Property("hide empty description", "true"))
  style.apply(Property("hide empty description", "false"))
  @test.assert_eq(style.property("hide empty description"), Some("false"))
}
