///|
test "YAML preserves scalar kinds and nested mapping structure" {
  let diagram = parse_yaml(
    (
      #|@startyaml
      #|version: 9223372036854775807
      #|enabled: false
      #|service:
      #|  name: api
      #|@endyaml
    ),
  )
  @test.assert_eq(diagram.root.kind, Object)
  @test.assert_eq(diagram.root.rows[0].key, Some("version"))
  @test.assert_eq(diagram.root.rows[1].key, Some("enabled"))
  @test.assert_eq(diagram.root.rows[2].key, Some("service"))
  @test.assert_eq(diagram.root.rows[0].value, Text("9223372036854775807"))
  @test.assert_eq(diagram.root.rows[1].value, False)
  @test.assert_eq(diagram.root.rows[2].value, Compound)
  @test.assert_eq(diagram.root.rows[2].child is Some(_), true)
  let svg = render_yaml_svg(diagram)
  @test.assert_eq(svg.contains("aria-label=\"YAML diagram\""), true)
  @test.assert_eq(svg.contains("json-edge"), true)
}

///|
test "TOML tables arrays and datetimes use the shared structure renderer" {
  let diagram = parse_toml(
    (
      #|@starttoml
      #|title = "service"
      #|enabled = true
      #|created = 1979-05-27T07:32:00Z
      #|[server]
      #|ports = [8000, 8001]
      #|@endtoml
    ),
  )
  @test.assert_eq(diagram.root.kind, Object)
  @test.assert_eq(diagram.root.rows[0].key, Some("title"))
  @test.assert_eq(diagram.root.rows[1].key, Some("enabled"))
  @test.assert_eq(diagram.root.rows[2].key, Some("created"))
  @test.assert_eq(diagram.root.rows[3].key, Some("server"))
  @test.assert_eq(
    diagram.root.rows.any(row => row.value == Text("1979-05-27T07:32:00Z")),
    true,
  )
  @test.assert_eq(
    diagram.root.rows.any(row => {
      row.key == Some("server") && row.child is Some(_)
    }),
    true,
  )
  let svg = render_toml_svg(diagram)
  @test.assert_eq(svg.contains("aria-label=\"TOML diagram\""), true)
  @test.assert_eq(svg.contains("json-edge"), true)
}
