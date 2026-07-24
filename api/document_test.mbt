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
test "sequence commands win over dotted reply arrows" {
  let source = "@startuml\nparticipant Client\nparticipant Server\nServer -> Client -- : response\n@enduml"
  @test.assert_eq(is_sequence_source(source), true)
  @test.assert_eq(is_class_source(source), false)
}

///|
test "sequence grouping commands win over class-style reply arrows" {
  let source = "@startuml\nAlice -> Bob\nalt success\nBob --> Alice : response\nend\n@enduml"
  @test.assert_eq(is_sequence_source(source), true)
  @test.assert_eq(is_class_source(source), false)
}

///|
test "sequence-only arrow dressings select the sequence parser" {
  let source = "@startuml\nAlice \\-> Bob : bottom\nAlice /--> Bob : dotted top\n@enduml"
  @test.assert_eq(is_sequence_source(source), true)
  @test.assert_eq(is_class_source(source), false)
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
test "document facade recognizes and renders mindmaps" {
  let source = "@startmindmap\n* Root\n** Child\n@endmindmap"
  @test.assert_eq(is_mindmap_source(source), true)
  let document = parse_mindmap(source)
  @test.assert_eq(document.kind() is Mindmap, true)
  @test.assert_eq(
    document.render_svg().contains("aria-label=\"Mindmap\""),
    true,
  )
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

///|
test "detects object map and inline JSON class sources" {
  @test.assert_eq(is_class_source("@startuml\nobject User\n@enduml"), true)
  @test.assert_eq(
    is_class_source("@startuml\nmap Values {\nkey => value\n}\n@enduml"),
    true,
  )
  @test.assert_eq(is_class_source("@startuml\njson Values 42\n@enduml"), true)
}

///|
test "detects the remaining class-only declarations and dotted arrows" {
  for
    source in ["annotation A", "record R", "exception E", "folder F", "A .> B"] {
    @test.assert_eq(is_class_source("@startuml\n" + source + "\n@enduml"), true)
  }
  @test.assert_eq(is_class_source("@startuml\nAlice -> Bob\n@enduml"), false)
  @test.assert_eq(is_class_source("@startuml\nANNOTATION A\n@enduml"), true)
}

///|
test "diagram source detection ignores comments and labels" {
  let sequence_with_label = "@startuml\nAlice -> Bob : class diagram\n@enduml"
  let class_with_label = "@startuml\nA --> B : participant service\n@enduml"
  @test.assert_eq(is_sequence_source(sequence_with_label), false)
  @test.assert_eq(is_class_source(sequence_with_label), false)
  @test.assert_eq(is_sequence_source(class_with_label), false)
  @test.assert_eq(is_class_source(class_with_label), true)
  @test.assert_eq(
    is_sequence_source("@startuml\n' participant Fake\nAlice -> Bob\n@enduml"),
    false,
  )
}

///|
test "sequence participant shapes are classified with their messages" {
  let source = "@startuml\nactor User\nUser -> Service : call\n@enduml"
  @test.assert_eq(is_sequence_source(source), true)
  @test.assert_eq(is_class_source(source), false)
}
