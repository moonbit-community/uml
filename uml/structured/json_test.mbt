///|
test "parses an object into PlantUML record rows in document order" {
  let diagram = parse_json("{\"z\":true,\"user\":{\"name\":\"Ada\"}}")
  @test.assert_eq(diagram.format, Json)
  @test.assert_eq(diagram.root.kind, Object)
  @test.assert_eq(diagram.root.rows[0].key, Some("z"))
  @test.assert_eq(diagram.root.rows[1].key, Some("user"))
  @test.assert_eq(diagram.root.rows[1].value, Compound)
}

///|
test "structured renderer derives its label from the diagram format" {
  let diagram = parse_json("{\"value\":1}")
  @test.assert_eq(diagram.render_svg(), diagram.render_json_svg())
}

///|
test "uses builtin JSON scalar display" {
  let diagram = parse_json(
    "{\"enabled\":true,\"missing\":null,\"number\":6.02e23}",
  )
  @test.assert_eq(diagram.root.rows[0].value, True)
  @test.assert_eq(diagram.root.rows[1].value, Null)
  @test.assert_eq(diagram.root.rows[2].value, Text("6.02e+23"))
}

///|
test "renders empty compound values as linked empty records" {
  let diagram = parse_json("{\"empty\":[]}")
  @test.assert_eq(diagram.root.rows[0].value, Compound)
  @test.assert_eq(diagram.root.rows[0].child is Some(_), true)
}
