///|
test "class parser retains the class-diagram mixing rule" {
  try parse("@startuml\ncomponent Adapter\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => @test.fail("expected class parser to reject a component declaration")
  }
}
