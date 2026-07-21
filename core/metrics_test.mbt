///|
test "font metrics expose defaulted tuning parameters" {
  let metrics = FontMetrics::from_defaults(
    font_size=16,
    line_height=22,
    width_scale=110,
    letter_spacing=1,
  )
  let measured = measure_text_with("AA", metrics)
  @test.assert_eq(measured.width > 0, true)
  @test.assert_eq(measured.height, 22)
}

///|
test "bold font metrics widen glyph advances" {
  let regular = FontMetrics::from_defaults(font_size=14)
  let bold = FontMetrics::from_defaults(font_size=14, font_weight=700)
  let unexpanded_bold = FontMetrics::from_defaults(
    font_size=14,
    font_weight=700,
    bold_width_scale=100,
  )
  @test.assert_eq(
    measure_text_with("downloads", bold).width >
    measure_text_with("downloads", regular).width,
    true,
  )
  @test.assert_eq(
    measure_text_with("downloads", unexpanded_bold).width,
    measure_text_with("downloads", regular).width,
  )
}

///|
test "combining marks do not widen text" {
  let metrics = FontMetrics::from_defaults(letter_spacing=2)
  @test.assert_eq(
    measure_text_with("e\u{0301}e", metrics).width,
    measure_text_with("ee", metrics).width,
  )
  @test.assert_eq(
    measure_text_with("e\u{fe0f}", metrics).width,
    measure_text_with("e", metrics).width,
  )
}

///|
test "font profiles and italic style affect advances" {
  let sans = FontMetrics::from_defaults(profile=Sans)
  let serif = FontMetrics::from_defaults(profile=Serif)
  let monospace = FontMetrics::from_defaults(profile=Monospace)
  let italic = FontMetrics::from_defaults(style=Italic)
  @test.assert_eq(measure_text_with("Hello", serif).width > 0, true)
  @test.assert_eq(
    measure_text_with("WWW", monospace).width,
    measure_text_with("iii", monospace).width,
  )
  @test.assert_eq(
    measure_text_with("Hello", italic).width >
    measure_text_with("Hello", sans).width,
    true,
  )
  @test.assert_eq(measure_text_with("Hello", italic).ink_left > 0, true)
  @test.assert_eq(measure_text_with("", italic).width >= 0, true)
  @test.assert_eq(
    measure_text_with("AV", monospace).advance_width,
    measure_text_with("AA", monospace).advance_width,
  )
}

///|
test "kerning tabs and word spacing participate in measurement" {
  let metrics = FontMetrics::default()
  let unkerned = FontMetrics::from_defaults(kerning_scale=0)
  @test.assert_eq(
    measure_text_with("AV", metrics).width <
    measure_text_with("AV", unkerned).width,
    true,
  )
  @test.assert_eq(measure_text_with("\t", metrics).width > 0, true)
  @test.assert_eq(
    measure_text_with("a a", FontMetrics::from_defaults(word_spacing=2)).width,
    measure_text_with("a a", metrics).width + 2,
  )
}

///|
test "numeric runs reserve enough sans-serif width" {
  let metrics = FontMetrics::from_defaults(font_size=14)
  @test.assert_eq(
    measure_text_with("1", metrics).width <
    measure_text_with("8", metrics).width,
    true,
  )
  let serif = FontMetrics::from_defaults(profile=Serif, font_size=14)
  @test.assert_eq(
    measure_text_with("1", serif).width < measure_text_with("8", serif).width,
    true,
  )
  @test.assert_eq(
    measure_text_with("0123456789", metrics).width >
    measure_text_with("abcdefghij", metrics).width,
    true,
  )
}

///|
test "character class width scales are configurable" {
  let calibrated = FontMetrics::from_defaults(font_size=14)
  let neutral = FontMetrics::from_defaults(
    font_size=14,
    uppercase_width_scale=100,
    lowercase_width_scale=100,
    digit_width_scale=100,
    punctuation_width_scale=100,
    cjk_width_scale=100,
  )
  @test.assert_eq(
    measure_text_with("ABCDEFGHIJKLMNOPQRSTUVWXYZ", calibrated).width >
    measure_text_with("ABCDEFGHIJKLMNOPQRSTUVWXYZ", neutral).width,
    true,
  )
  @test.assert_eq(
    measure_text_with("0123456789", calibrated).width <
    measure_text_with("0123456789", neutral).width,
    true,
  )
  @test.assert_eq(measure_text_with("中文字体度量", calibrated).width > 0, true)
}

///|
test "text metrics expose vertical font bounds" {
  let metrics = FontMetrics::from_defaults(
    font_size=16,
    line_height=20,
    ascent=12,
    descent=4,
    line_gap=4,
  )
  let measured = measure_text_with("text", metrics)
  @test.assert_eq(measured.height, 20)
  @test.assert_eq(measured.ascent, 12)
  @test.assert_eq(measured.descent, 4)
  @test.assert_eq(measured.baseline, 12)
  @test.assert_eq(measured.advance_width, measured.width)
}
