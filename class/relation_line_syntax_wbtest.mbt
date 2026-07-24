///|
test "relation line grammar accepts supported syntax" {
  let lines = [
    "U <|.. Auth : implements", "Order \"1\" *-- \"many\" Item : items", "\"Order Item\" --> \"Line Item\"",
    "A \"1\" -- \"many\" B", "\"Quoted A\" \"0..1\" -- \"*\" \"Quoted B\"", "order-item --> target [[https://host:8443/item]] <<phase:value>> : \"sync: now\"",
    "A --[dashed,#red]--> B #blue [[https://example.com]] <<critical>> : calls",
    "(A, B) -- Label : association", "A-->B", "order-item-->target-item",
  ]
  for line in lines {
    guard relation_line_parser().parse(@talc.Input::new(line)) is Ok(_) else {
      @test.fail("relation grammar rejected: " + line)
    }
  }
}

///|
test "relation line grammar parses each typed phase" {
  let line = "U <|.. Auth : implements"
  guard relation_line_parser().parse(@talc.Input::new(line)) is Ok(relation) else {
    @test.fail("complete relation grammar failed")
  }
  @test.assert_eq(relation.left.name.name, "U")
  @test.assert_eq(relation.right.name.name, "Auth")
  @test.assert_eq(relation.arrow, "<|..")
  @test.assert_eq(relation.label, Some("implements"))
}
