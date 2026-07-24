///|

///|
fn svg_height(svg : String) -> Int {
  let parts = svg.split("height=\"").to_array()
  guard parts.length() >= 2 else { return 0 }
  let height = parts[1].split("\"").to_array()[0].to_owned()
  @string.parse_int(height) catch {
    _ => 0
  }
}

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

///|
test "YAML block scalars render as multiline record cells" {
  let diagram = parse_yaml(
    (
      #|@startyaml
      #|notes: |
      #|  first line
      #|  second line
      #|next: value
      #|@endyaml
    ),
  )
  let svg = render_yaml_svg(diagram)
  let single_line_svg = render_yaml_svg(
    parse_yaml("@startyaml\nnotes: first line\nnext: value\n@endyaml"),
  )
  @test.assert_eq(svg_height(svg) > svg_height(single_line_svg), true)
  @test.assert_eq(svg.contains("<tspan"), true)
  @test.assert_eq(svg.contains("first line</tspan>"), true)
  @test.assert_eq(svg.contains("second line</tspan>"), true)
  @test.assert_eq(svg.contains("first line\nsecond line"), false)
}
