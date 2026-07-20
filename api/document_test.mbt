///|
test "document facade dispatches a sequence diagram" {
  let document = parse("@startuml\nAlice -> Bob : request\n@enduml")
  let svg = document.render_svg()
  @test.assert_eq(svg.contains("Sequence diagram"), true)
  @test.assert_eq(
    render_svg("@startuml\nAlice -> Bob : request\n@enduml").contains("request"),
    true,
  )
}

///|
test "document facade renders a class diagram" {
  let document = parse_class("@startuml\nclass User\nUser --> Account\n@enduml")
  match document.kind() {
    Class => ()
    _ => @test.fail("expected class diagram")
  }
  @test.assert_eq(document.render_svg().contains("Class diagram"), true)
}

///|
test "document facade renders a JSON structure diagram" {
  let document = parse_json(
    "@startjson\n{\"service\":{\"port\":8080}}\n@endjson",
  )
  match document.kind() {
    Json => ()
    _ => @test.fail("expected JSON diagram")
  }
  @test.assert_eq(document.render_svg().contains(">service<"), true)
  @test.assert_eq(is_json_source("\n@STARTJSON\n{}\n@endjson"), true)
}
