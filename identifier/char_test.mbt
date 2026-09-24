///|
test "is_unicode_letter follows the Unicode letter category" {
  @test.assert_eq(@identifier.is_unicode_letter('A'), true)
  @test.assert_eq(@identifier.is_unicode_letter('é'), true)
  @test.assert_eq(@identifier.is_unicode_letter('中'), true)
  @test.assert_eq(@identifier.is_unicode_letter('ع'), true)
  // CJK Extension B: a letter the previous block table did not cover.
  @test.assert_eq(@identifier.is_unicode_letter('\u{20000}'), true)
  @test.assert_eq(@identifier.is_unicode_letter('1'), false)
  // Greek lower numeral sign is a symbol, not a letter.
  @test.assert_eq(@identifier.is_unicode_letter('\u{0375}'), false)
}

///|
test "is_identifier_char accepts letters, numbers and underscore" {
  @test.assert_eq(@identifier.is_identifier_char('_'), true)
  @test.assert_eq(@identifier.is_identifier_char('a'), true)
  @test.assert_eq(@identifier.is_identifier_char('中'), true)
  @test.assert_eq(@identifier.is_identifier_char('\u{0663}'), true) // Arabic-Indic digit
  @test.assert_eq(@identifier.is_identifier_char('-'), false)
  @test.assert_eq(@identifier.is_identifier_char(' '), false)
}
