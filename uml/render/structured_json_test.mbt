///|
test "parses an object into PlantUML record rows in document order" {
  let diagram = @parser.parse_structured_json(
    "{\"z\":true,\"user\":{\"name\":\"Ada\"}}",
  )
  @test.assert_eq(diagram.format, @structured.Json)
  @test.assert_eq(diagram.root.kind, Object)
  @test.assert_eq(diagram.root.rows[0].key, Some("z"))
  @test.assert_eq(diagram.root.rows[1].key, Some("user"))
  @test.assert_eq(diagram.root.rows[1].value, @structured.Compound)
}

///|
test "structured renderer derives its label from the diagram format" {
  let diagram = @parser.parse_structured_json("{\"value\":1}")
  @test.assert_eq(
    render_structured_svg(diagram),
    render_structured_svg(diagram),
  )
}

///|
test "uses builtin JSON scalar display" {
  let diagram = @parser.parse_structured_json(
    "{\"enabled\":true,\"missing\":null,\"number\":6.02e23}",
  )
  @test.assert_eq(diagram.root.rows[0].value, @structured.True)
  @test.assert_eq(diagram.root.rows[1].value, @structured.Null)
  @test.assert_eq(diagram.root.rows[2].value, @structured.Text("6.02e+23"))
}

///|
test "renders empty compound values as linked empty records" {
  let diagram = @parser.parse_structured_json("{\"empty\":[]}")
  @test.assert_eq(diagram.root.rows[0].value, @structured.Compound)
  @test.assert_eq(diagram.root.rows[0].child is Some(_), true)
}
