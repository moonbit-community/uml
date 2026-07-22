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
