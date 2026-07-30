///|
test "component parser accepts component declarations" {
  let diagram = parse("@startuml\ncomponent Adapter\n@enduml")
  @test.assert_eq(diagram.entity("Adapter").unwrap().kind, @entity.Component)
}
