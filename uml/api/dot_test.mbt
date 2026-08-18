///|
test "dot parse extracts the DOT source between markers" {
  let source =
    #|@startdot
    #|digraph G {
    #|  a -> b;
    #|}
    #|@enduml
  let diagram = parse_dot_source(source)
  @test.assert_eq(diagram.source, "digraph G {\n  a -> b;\n}\n")
}

///|
test "dot parse keeps text outside markers out of the source" {
  let source =
    #|@startdot
    #|digraph G { a -> b; }
    #|@enddot
  let diagram = parse_dot_source(source)
  @test.assert_eq(diagram.source, "digraph G { a -> b; }\n")
}

///|
test "dot parse without markers uses the whole input" {
  let diagram = parse_dot_source("digraph G { a -> b; }")
  @test.assert_eq(diagram.source, "digraph G { a -> b; }")
}

///|
test "dot render surfaces invalid DOT source as an error" {
  let source =
    #|@startdot
    #|digraph G { a -> b
    #|@enduml
  let diagram = parse_dot_source(source)
  let failed = try {
    let _ = diagram.render_svg()
    false
  } catch {
    _ => true
  }
  @test.assert_eq(failed, true)
}
