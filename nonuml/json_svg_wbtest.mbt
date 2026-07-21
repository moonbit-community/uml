///|
test "json key columns use bold font metrics" {
  let diagram = parse_json("@startjson\n{\"downloads\": 42}\n@endjson")
  let metrics = node_metrics(diagram.root)
  let regular = @core.FontMetrics::from_defaults(font_size=14, line_height=21)
  let bold = @core.FontMetrics::from_defaults(
    font_size=14,
    font_weight=700,
    line_height=21,
  )
  @test.assert_eq(regular.profile, Sans)
  @test.assert_eq(regular.font_size, 14)
  @test.assert_eq(bold.font_weight, 700)
  @test.assert_eq(@core.measure_text_with("downloads", regular).width, 68)
  @test.assert_eq(@core.measure_text_with("downloads", bold).width, 75)
  @test.assert_eq(metrics.key_width, 85)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("font-size: 14px"), true)
  @test.assert_eq(svg.contains("font-weight: 700"), true)
}
