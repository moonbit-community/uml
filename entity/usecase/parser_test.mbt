///|
test "use-case parser accepts actor and use-case symbols" {
  let diagram = parse("@startuml\n:Customer: --> (Place order)\n@enduml")
  @test.assert_eq(diagram.entity("Customer").unwrap().kind, @entity.Actor)
  @test.assert_eq(diagram.entity("Place order").unwrap().kind, @entity.Usecase)
}
