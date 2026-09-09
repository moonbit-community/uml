///|
test "PlantUML named colors serialize as canonical SVG colors" {
  @test.assert_eq(@svg.svg_color(Some("lightyellow"), "fallback"), "#FFFFE0")
  @test.assert_eq(@svg.svg_color(Some("#DARKorange"), "fallback"), "#FF8C00")
  @test.assert_eq(@svg.svg_color(Some("#abc"), "fallback"), "#abc")
}
