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
