///|
test "class parser retains the class-diagram mixing rule" {
  try parse("@startuml\ncomponent Adapter\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => @test.fail("expected class parser to reject a component declaration")
  }
}

///|
test "class parser owns object map and JSON syntax" {
  let diagram = parse(
    "@startuml\nobject Customer {\nid = \"customer-42\"\n}\nmap Index {\ncustomer *--> Customer\n}\njson Profile {\n\"active\": true\n}\n@enduml",
  )
  @test.assert_eq(diagram.entity("Customer").unwrap().kind, Object)
  @test.assert_eq(diagram.entity("Index").unwrap().kind, Map)
  @test.assert_eq(diagram.entity("Profile").unwrap().kind, Json)
  @test.assert_eq(diagram.relations.length(), 1)
}
