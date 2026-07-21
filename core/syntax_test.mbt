///|
test "shared PlantUML syntax helpers respect quoted text" {
  @test.assert_eq(
    strip_line_comment("class \"It's quoted\" ' comment"),
    "class \"It's quoted\"",
  )
  @test.assert_eq(split_unquoted("A, \"B, C\", D", ','), [
    "A", " \"B, C\"", " D",
  ])
  @test.assert_eq(unquote_identifier("\"Display name\""), "Display name")
  let url = extract_url("class User [[https://example.com profile]] <<entity>>").unwrap()
  @test.assert_eq(url.before, "class User ")
  @test.assert_eq(url.target.target, "https://example.com")
  @test.assert_eq(url.after, " <<entity>>")
}
