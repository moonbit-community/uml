///|
test "classifies ASCII and Latin-1 letters" {
  @test.assert_eq(is_unicode_letter('A'), true)
  @test.assert_eq(is_unicode_letter('z'), true)
  @test.assert_eq(is_unicode_letter('0'), false)
  @test.assert_eq(is_unicode_letter('-'), false)
  @test.assert_eq(is_unicode_letter('É'), true)
}

///|
test "classifies non-Latin scripts" {
  @test.assert_eq(is_unicode_letter('代'), true)
  @test.assert_eq(is_unicode_letter('码'), true)
  @test.assert_eq(is_unicode_letter('あ'), true)
  @test.assert_eq(is_unicode_letter('한'), true)
  @test.assert_eq(is_unicode_letter('а'), true)
  @test.assert_eq(is_unicode_letter('α'), true)
}

///|
test "identifier chars cover letters, digits, and underscore" {
  @test.assert_eq(is_identifier_char('A'), true)
  @test.assert_eq(is_identifier_char('9'), true)
  @test.assert_eq(is_identifier_char('_'), true)
  @test.assert_eq(is_identifier_char('代'), true)
  @test.assert_eq(is_identifier_char('-'), false)
  @test.assert_eq(is_identifier_char(' '), false)
  @test.assert_eq(is_identifier_char('.'), false)
}
