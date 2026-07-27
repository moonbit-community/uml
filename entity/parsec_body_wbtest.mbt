///|
test "parse map value entry as one line grammar" {
  guard parse_map_entry_line("id => 42") is Some(syntax) else {
    fail("expected map value entry")
  }
  @test.assert_eq(syntax.entry.key, "id")
  @test.assert_eq(syntax.entry.value, Some("42"))
  @test.assert_eq(syntax.entry.link_target, None)
  @test.assert_eq(syntax.arrow, None)
}

///|
test "parse map link entry as one line grammar" {
  guard parse_map_entry_line("customer *--> Customer") is Some(syntax) else {
    fail("expected map link entry")
  }
  @test.assert_eq(syntax.entry.key, "customer")
  @test.assert_eq(syntax.entry.value, None)
  @test.assert_eq(syntax.entry.link_target, Some("Customer"))
  @test.assert_eq(syntax.arrow, Some("*-->"))
}

///|
test "reject invalid map entry line" {
  guard parse_map_entry_line("invalid line") is None else {
    fail("expected invalid map entry")
  }
}
