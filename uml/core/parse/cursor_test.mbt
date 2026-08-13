///|
test "cursor consumes and restores character input" {
  let indent = "  "
  let marker = "**"
  let cursor = Cursor::new(indent + marker + "_>Node")
  @test.assert_eq(
    cursor.skip_while(char => char == ' '),
    indent.to_array().length(),
  )
  @test.assert_eq(cursor.take_while(char => char == '*' || char == '+'), marker)
  let checkpoint = cursor.offset()
  @test.assert_eq(cursor.consume('_'), true)
  @test.assert_eq(cursor.consume('>'), true)
  @test.assert_eq(cursor.take_while(char => !char.is_whitespace()), "Node")
  @test.assert_eq(cursor.is_eof(), true)
  @test.assert_eq(cursor.restore(checkpoint), true)
  @test.assert_eq(cursor.remaining(), "_>Node")
}

///|
test "cursor handles lines and Unicode as characters" {
  let cursor = Cursor::new("根\n子")
  @test.assert_eq(cursor.current_line(), "根")
  @test.assert_eq(cursor.take_line(), "根")
  @test.assert_eq(cursor.current_line(), "子")
  @test.assert_eq(cursor.take_line(), "子")
  @test.assert_eq(cursor.is_eof(), true)
}

///|
test "scanner preserves quoted and delimited syntax fragments" {
  let cursor = Cursor::new("\"A\\\" B\" [[https://example.com/o'clock")
  @test.assert_eq(cursor.take_quoted_text(), Some("\"A\\\" B\""))
  @test.assert_eq(cursor.skip_inline_whitespace(), 1)
  @test.assert_eq(
    cursor.take_delimited_text("[[", "]]"),
    Some("[[https://example.com/o'clock"),
  )
  @test.assert_eq(cursor.is_eof(), true)
}

///|
test "strict quoted value requires a closing quote" {
  let cursor = Cursor::new("\"A\\\" B\" tail")
  @test.assert_eq(cursor.take_quoted_value(), Some("A\\\" B"))
  @test.assert_eq(cursor.skip_inline_whitespace(), 1)
  @test.assert_eq(cursor.remaining(), "tail")

  let unclosed = Cursor::new("\"A\\\" B")
  @test.assert_eq(unclosed.take_quoted_value(), None)
  @test.assert_eq(unclosed.is_eof(), false)
  @test.assert_eq(unclosed.remaining(), "\"A\\\" B")
}

///|
test "value scanners preserve PlantUML token values" {
  let stereotype = Cursor::new("<<choice>> tail")
  @test.assert_eq(stereotype.take_stereotype_value(), Some("<<choice>>"))
  @test.assert_eq(stereotype.remaining(), " tail")

  let url = Cursor::new("[[https://example.com/docs]] tail")
  @test.assert_eq(url.take_url_value(), Some("https://example.com/docs"))
  @test.assert_eq(url.remaining(), " tail")

  let color = Cursor::new("#lightblue tail")
  @test.assert_eq(color.take_color_value(), Some("lightblue"))
  @test.assert_eq(color.remaining(), " tail")

  let tag = Cursor::new("$backend tail")
  @test.assert_eq(tag.take_tag_value(), Some("backend"))
  @test.assert_eq(tag.remaining(), " tail")
}

///|
test "value scanners restore the position on failure" {
  let unclosed = Cursor::new("<<choice")
  @test.assert_eq(unclosed.take_stereotype_value(), None)
  @test.assert_eq(unclosed.remaining(), "<<choice")

  let bare = Cursor::new("choice")
  @test.assert_eq(bare.take_stereotype_value(), None)
  @test.assert_eq(bare.remaining(), "choice")

  let invalid_url = Cursor::new("[[ ]]")
  @test.assert_eq(invalid_url.take_url_value(), None)
  @test.assert_eq(invalid_url.remaining(), "[[ ]]")

  let empty = Cursor::new("# ")
  @test.assert_eq(empty.take_color_value(), None)
  @test.assert_eq(empty.remaining(), "# ")
}
