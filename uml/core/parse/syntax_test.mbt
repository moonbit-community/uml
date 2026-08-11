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
  @test.assert_eq(
    strip_line_comment("class \"O\\\"'Brien\" ' comment"),
    "class \"O\\\"'Brien\"",
  )
  @test.assert_eq(
    strip_line_comment("class A [[https://example.com/o'clock"),
    "class A [[https://example.com/o'clock",
  )
  @test.assert_eq(
    strip_line_comment_preserving_indent("  ** Child ' comment"),
    "  ** Child",
  )
  @test.assert_eq(split_unquoted("A, \"B, C\", D", ','), [
    "A", " \"B, C\"", " D",
  ])
  @test.assert_eq(split_unquoted("\"A, B\", C, \"D\\\" E\"", ','), [
    "\"A, B\"", " C", " \"D\\\" E\"",
  ])
  @test.assert_eq(unquote_identifier("\"Display name\""), "Display name")
  let url = extract_url("class User [[https://example.com profile]] <<entity>>").unwrap()
  @test.assert_eq(url.before, "class User ")
  @test.assert_eq(url.target.target, "https://example.com")
  @test.assert_eq(url.after, " <<entity>>")
}

///|
test "stereotype display uses PlantUML guillemets" {
  @test.assert_eq(display_stereotype("<<business>>"), "«business»")
  @test.assert_eq(display_stereotype("plain label"), "plain label")
}

///|
test "parses URL targets with quoted values and labels" {
  let labelled = parse_url_target("[[https://example.com profile page]]").unwrap()
  @test.assert_eq(labelled.target, "https://example.com")
  @test.assert_eq(labelled.label, Some("profile page"))
  let quoted = parse_url_target(
    " [[ \"https://example.com/a path\" profile ]] ",
  ).unwrap()
  @test.assert_eq(quoted.target, "https://example.com/a path")
  @test.assert_eq(quoted.label, Some("profile"))
  let unlabeled = parse_url_target("[[https://example.com   ]]").unwrap()
  @test.assert_eq(unlabeled.target, "https://example.com")
  @test.assert_eq(unlabeled.label, None)
  @test.assert_eq(parse_url_target("[[ ]]"), None)
  @test.assert_eq(parse_url_target("[[https://example.com"), None)
}

///|
test "syntax words preserve quoted identifiers as single tokens" {
  @test.assert_eq(syntax_words("class \"Display name\" as User"), [
    "class", "\"Display name\"", "as", "User",
  ])
  @test.assert_eq(syntax_words("note right of \"A B\" : text here"), [
    "note", "right", "of", "\"A B\"", ":", "text", "here",
  ])
  @test.assert_eq(syntax_words("class User\" display name\" as U"), [
    "class", "User\" display name\"", "as", "U",
  ])
  @test.assert_eq(syntax_words("class \"quoted \\\"name\\\"\" as User"), [
    "class", "\"quoted \\\"name\\\"\"", "as", "User",
  ])
}

///|
test "splits aliases only outside quoted identifiers" {
  @test.assert_eq(
    parse_alias_identifier("\"Display as text\" as User"),
    Some(("\"Display as text\"", "User")),
  )
  @test.assert_eq(
    parse_alias_identifier("User as \"Display as text\""),
    Some(("User", "\"Display as text\"")),
  )
  @test.assert_eq(parse_alias_identifier("\"User as text\""), None)
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
  @test.assert_eq(
    find_unquoted_literal("\"escaped \\\" extends A\" extends B", "extends "),
    Some(23),
  )
  @test.assert_eq(find_literal("角色::端口", "::"), Some(2))
  @test.assert_eq(find_literal("abc", ""), Some(0))
  @test.assert_eq(unquoted_delimiter_delta("{\"key\": \"}\"}", '{', '}'), 0)
  @test.assert_eq(unquoted_delimiter_delta("{\"key\": {", '{', '}'), 2)
}

///|
test "shared block collector consumes the terminator exactly once" {
  let source = ["first", "second", "end note", "after"]
  let mut index = 0
  let lines = collect_lines_until(
    fn() {
      guard index < source.length() else { return None }
      let line = source[index]
      index += 1
      Some(line)
    },
    line => line == "end note",
  )
  @test.assert_eq(lines, Some(["first", "second"]))
  @test.assert_eq(source[index], "after")
}
