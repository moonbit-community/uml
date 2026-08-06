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
  @test.assert_eq(@svg.separator_dash_pattern().length() > 0, true)
  @test.assert_eq(@svg.line_style_attributes(Some("dashed")), [
    ("stroke-dasharray", @svg.dashed_line_pattern()),
  ])
}
