///|
test "default font metrics retain legacy text measurements" {
  @test.assert_eq(measure_text("Hello").width, 28)
  @test.assert_eq(measure_text("Hello\nWorld").height, 30)
}

///|
test "font metrics expose defaulted tuning parameters" {
  let metrics = FontMetrics::from_defaults(
    font_size=16,
    line_height=22,
    width_scale=110,
    letter_spacing=1,
  )
  @test.assert_eq(metrics.font_size, 16)
  let measured = measure_text_with("AA", metrics)
  @test.assert_eq(measured.width, 23)
  @test.assert_eq(measured.height, 22)
}

///|
test "combining marks do not widen text" {
  let metrics = FontMetrics::from_defaults(letter_spacing=2)
  @test.assert_eq(measure_text_with("e\u{0301}e", metrics).width, 16)
}
