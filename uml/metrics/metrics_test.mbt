///|
test "font transformations retain their measurement service and full specification" {
  let seen : Array[@metrics.FontSpec] = []
  let service = @metrics.Measurer::new((font, text) => {
    seen.push(font)
    let advance = (font.font_size * text.length()).to_double()
    {
      width: advance.ceil().to_int(),
      advance_width: advance,
      height: font.line_height,
      ascent: font.font_size,
      descent: 0,
      baseline: font.font_size,
      ink_left: 0.0,
      ink_right: 0.0,
    }
  })
  let original = @metrics.FontMetrics::from_defaults(service)
  let family = "Example Family, serif"
  let transformed = original
    .with_family(family)
    .with_face(700, Italic)
    .with_size(original.font_size * 2)
  let configured = @metrics.FontMetrics::from_defaults(
    service,
    font_family=family,
    font_weight=transformed.font_weight,
    style=Italic,
    font_size=transformed.font_size,
    line_height=transformed.line_height,
  )
  @test.assert_eq(transformed.measure("AV ffi"), configured.measure("AV ffi"))
  let measured = seen[seen.length() - 1]
  @test.assert_eq(measured.font_family, family)
  @test.assert_eq(measured.style, transformed.style)
  @test.assert_eq(measured.font_weight, transformed.font_weight)
  @test.assert_eq(measured.font_size, transformed.font_size)
  @test.assert_eq(measured.line_height, transformed.line_height)
}

///|
test "zero-size fonts do not call the platform service" {
  let service = @metrics.Measurer::new((_, _) => {
    abort("zero-size fonts must not require a platform context")
  })
  let font = @metrics.FontMetrics::from_defaults(service, font_size=0)
  let empty = font.measure("")
  @test.assert_eq(font.measure("text\n\t中文"), empty)
  @test.assert_eq(empty.width, 0)
  @test.assert_eq(empty.height, 0)
  @test.assert_eq(empty.advance_width, 0.0)
}
