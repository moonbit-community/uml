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
