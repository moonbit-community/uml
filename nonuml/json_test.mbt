///|
test "parses an object into PlantUML record rows in document order" {
  let diagram = parse_json("{\"z\":true,\"user\":{\"name\":\"Ada\"}}")
  @test.assert_eq(diagram.root.kind, Object)
  @test.assert_eq(diagram.root.rows[0].key, Some("z"))
  @test.assert_eq(diagram.root.rows[1].key, Some("user"))
  @test.assert_eq(diagram.root.rows[1].value, Compound)
}

///|
test "renders PlantUML JSON markers as SVG" {
  let svg = parse_json("@startjson\n{\"items\":[1,2]}\n@endjson").render_svg()
  @test.assert_eq(svg.contains("JSON diagram"), true)
  @test.assert_eq(svg.contains("json-edge"), true)
  @test.assert_eq(svg.contains("&#160;&#160;&#160;"), true)
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
  @test.assert_eq(diagram.render_svg().contains("json-edge"), true)
}
