///|
test "shared PlantUML syntax helpers respect quoted text" {
  @test.assert_eq(
    strip_line_comment("class \"It's quoted\" ' comment"),
    "class \"It's quoted\"",
  )
  @test.assert_eq(
    strip_line_comment("class A [[https://example.com/o'clock]] ' comment"),
    "class A [[https://example.com/o'clock]]",
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

///|
test "syntax words preserve quoted identifiers as single tokens" {
  @test.assert_eq(syntax_words("class \"Display name\" as User"), [
    "class", "\"Display name\"", "as", "User",
  ])
  @test.assert_eq(syntax_words("note right of \"A B\" : text here"), [
    "note", "right", "of", "\"A B\"", ":", "text", "here",
  ])
}

///|
test "recognizes shared definition blocks" {
  @test.assert_eq(common_block_terminator("sprite $icon {"), Some("}"))
  @test.assert_eq(common_block_terminator("<style>"), Some("</style>"))
  @test.assert_eq(common_block_terminator("<style>foo</style>"), None)
}

///|
test "parses namespace separator commands" {
  @test.assert_eq(
    parse_namespace_separator("set namespaceSeparator ::"),
    Some(Some("::")),
  )
  @test.assert_eq(
    parse_namespace_separator("set namespace_separator none"),
    Some(None),
  )
  @test.assert_eq(parse_namespace_separator("class A"), None)
}

///|
test "finds literals only outside quoted text" {
  @test.assert_eq(
    find_unquoted_literal("\"extends A\" extends B", "extends "),
    Some(12),
  )
  @test.assert_eq(find_unquoted_literal("\"extends A\"", "extends "), None)
}
