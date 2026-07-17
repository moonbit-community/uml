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
