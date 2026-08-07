///|
test "standard border token is the default stroke source" {
  @test.assert_eq(
    @svg.stroke_style(None),
    "stroke-width:" + @svg.standard_border_stroke_width(),
  )
  @test.assert_eq(
    @svg.standard_border_stroke_width(),
    @svg.stroke_style(None)["stroke-width:".length():].to_owned(),
  )
}

///|
test "shared emphasis and separator tokens preserve SVG values" {
  @test.assert_eq(@svg.emphasized_stroke_width().length() > 0, true)
  @test.assert_eq(@svg.secondary_structure_stroke_width().length() > 0, true)
  @test.assert_eq(@svg.auxiliary_label_font_size().has_suffix("px"), true)
  @test.assert_eq(@svg.separator_dash_pattern().length() > 0, true)
  @test.assert_eq(@svg.line_style_attributes(Some("dashed")), [
    ("stroke-dasharray", @svg.dashed_line_pattern()),
  ])
  @test.assert_eq(@svg.line_style_attributes(Some("dotted")), [
    ("stroke-dasharray", @svg.dotted_line_pattern()),
  ])
}

///|
test "sequence dash roles have distinct shared sources" {
  let patterns = [
    @svg.lifeline_dash_pattern(),
    @svg.dotted_message_dash_pattern(),
    @svg.hex_note_dash_pattern(),
    @svg.delay_dash_pattern(),
    @svg.page_break_dash_pattern(),
  ]
  for index in 0..<patterns.length() {
    let other_start = index + 1
    for other in other_start..<patterns.length() {
      @test.assert_eq(patterns[index] == patterns[other], false)
    }
  }
}

///|
test "multiline text serializes layout advances as complete XML attributes" {
  let metrics = @metrics.FontMetrics::from_defaults(font_size=16)
  let line = "wide label"
  let measured = metrics.measure(line)
  let svg = @svg.multiline_text_markup(
    0.0,
    12.0,
    line + "\nX",
    [],
    line_height=metrics.line_height.to_double(),
    text_metrics=Some(metrics),
  )
  @test.assert_eq(
    svg,
    "<text x=\"0\" y=\"" +
    (12.0 - metrics.line_height.to_double() / 2.0).to_string() +
    "\"><tspan x=\"0\" dy=\"0\" textLength=\"" +
    measured.advance_width.to_string() +
    "\" lengthAdjust=\"spacing\">" +
    line +
    "</tspan><tspan x=\"0\" dy=\"" +
    metrics.line_height.to_double().to_string() +
    "\">X</tspan></text>",
  )
}

///|
test "single-line text serializes layout advances as complete XML attributes" {
  let metrics = @metrics.FontMetrics::from_defaults(font_size=16)
  let text = "state name"
  let measured = metrics.measure(text)
  let svg = @svg.text_markup(0.0, 0.0, text, [], metrics)
  @test.assert_eq(
    svg,
    "<text x=\"0\" y=\"0\" textLength=\"" +
    measured.advance_width.to_string() +
    "\" lengthAdjust=\"spacing\">" +
    text +
    "</text>",
  )
}

///|
test "PlantUML named colors serialize as canonical SVG colors" {
  @test.assert_eq(@svg.svg_color(Some("lightyellow"), "fallback"), "#FFFFE0")
  @test.assert_eq(@svg.svg_color(Some("#DARKorange"), "fallback"), "#FF8C00")
  @test.assert_eq(@svg.svg_color(Some("#abc"), "fallback"), "#abc")
}
