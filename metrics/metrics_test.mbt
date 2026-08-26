///|
test "font metrics expose defaulted tuning parameters" {
  let configured_line_height = 22
  let metrics = FontMetrics::from_defaults(
    font_size=16,
    line_height=configured_line_height,
    width_scale=110,
    letter_spacing=1,
  )
  let measured = metrics.measure("AA")
  @test.assert_eq(measured.width > 0, true)
  @test.assert_eq(measured.height, configured_line_height)
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
    bold.measure("downloads").width > regular.measure("downloads").width,
    true,
  )
  @test.assert_eq(
    unexpanded_bold.measure("downloads").width,
    regular.measure("downloads").width,
  )
}

///|
test "combining mark advances come from the shared width source" {
  let metrics = FontMetrics::from_defaults(letter_spacing=2)
  @test.assert_eq(
    metrics.measure("e\u{0301}").advance_width >=
    metrics.measure("e").advance_width,
    true,
  )
  @test.assert_eq(
    metrics.measure("e\u{fe0f}").advance_width >=
    metrics.measure("e").advance_width,
    true,
  )
}

///|
test "font profiles and italic style affect advances" {
  let sans = FontMetrics::from_defaults(profile=Sans)
  let serif = FontMetrics::from_defaults(profile=Serif)
  let monospace = FontMetrics::from_defaults(profile=Monospace)
  let italic = FontMetrics::from_defaults(style=Italic)
  @test.assert_eq(serif.measure("Hello").width > 0, true)
  @test.assert_eq(
    monospace.measure("WWW").width,
    monospace.measure("iii").width,
  )
  @test.assert_eq(
    italic.measure("Hello").width > sans.measure("Hello").width,
    true,
  )
  @test.assert_eq(italic.measure("Hello").ink_left > 0, true)
  @test.assert_eq(italic.measure("").width >= 0, true)
  @test.assert_eq(
    monospace.measure("AV").advance_width,
    monospace.measure("AA").advance_width,
  )
}

///|
test "sans metrics follow per-glyph table advances and fallbacks" {
  let metrics = FontMetrics::from_defaults(font_size=16)
  @test.assert_eq(metrics.char_width('i') < metrics.char_width('!'), true)
  @test.assert_eq(metrics.char_width('!') < metrics.char_width('W'), true)
  @test.assert_eq(metrics.char_width('\u{4e00}') > 0, true)
  @test.assert_eq(metrics.char_width('\u{1f600}') > 0, true)
  @test.assert_eq(metrics.char_width('\u{ff21}') > 0, true)
  @test.assert_eq(metrics.char_width('\u{0600}') > 0, true)
  @test.assert_eq(
    FontMetrics::from_defaults(font_size=32).char_width('!') >
    metrics.char_width('!'),
    true,
  )
}

///|
test "kerning tabs and word spacing participate in measurement" {
  let metrics = FontMetrics::from_defaults(profile=Serif)
  let unkerned = FontMetrics::from_defaults(profile=Serif, kerning_scale=0)
  @test.assert_eq(
    metrics.measure("AV").width < unkerned.measure("AV").width,
    true,
  )
  @test.assert_eq(metrics.measure("\t").width > 0, true)
  @test.assert_eq(
    FontMetrics::from_defaults(profile=Serif, word_spacing=2).measure("a a").width,
    metrics.measure("a a").width + 2,
  )
}

///|
test "numeric runs reserve enough sans-serif width" {
  let metrics = FontMetrics::from_defaults(font_size=14)
  @test.assert_eq(metrics.measure("1").width > 0, true)
  @test.assert_eq(metrics.measure("8").width > 0, true)
  let serif = FontMetrics::from_defaults(profile=Serif, font_size=14)
  @test.assert_eq(serif.measure("1").width < serif.measure("8").width, true)
  @test.assert_eq(
    metrics.measure("0123456789").width > metrics.measure("abcdefghij").width,
    true,
  )
}

///|
test "character class width scales are configurable" {
  let calibrated = FontMetrics::from_defaults(
    font_size=14,
    uppercase_width_scale=120,
    digit_width_scale=90,
  )
  let neutral = FontMetrics::from_defaults(
    font_size=14,
    uppercase_width_scale=100,
    lowercase_width_scale=100,
    digit_width_scale=100,
    punctuation_width_scale=100,
    wide_width_scale=100,
  )
  @test.assert_eq(
    calibrated.measure("ABCDEFGHIJKLMNOPQRSTUVWXYZ").width >
    neutral.measure("ABCDEFGHIJKLMNOPQRSTUVWXYZ").width,
    true,
  )
  @test.assert_eq(
    calibrated.measure("0123456789").width < neutral.measure("0123456789").width,
    true,
  )
  @test.assert_eq(calibrated.measure("中文字体度量").width > 0, true)
}

///|
test "text metrics expose vertical font bounds" {
  let configured_line_height = 20
  let configured_ascent = 12
  let configured_descent = 4
  let metrics = FontMetrics::from_defaults(
    font_size=16,
    line_height=configured_line_height,
    ascent=configured_ascent,
    descent=configured_descent,
    line_gap=configured_descent,
  )
  let measured = metrics.measure("text")
  @test.assert_eq(measured.height, configured_line_height)
  @test.assert_eq(measured.ascent, configured_ascent)
  @test.assert_eq(measured.descent, configured_descent)
  @test.assert_eq(measured.baseline, configured_ascent)
  @test.assert_eq(measured.advance_width, measured.width)
}
