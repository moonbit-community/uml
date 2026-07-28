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
test "document facade dispatches a component diagram" {
  let source = "@startuml\ncomponent \"Gateway API\" as Gateway\n[Client] --> Gateway\n@enduml"
  @test.assert_eq(is_component_source(source), true)
  @test.assert_eq(is_sequence_source(source), false)
  let document = parse_component(source)
  match document.kind() {
    Component => ()
    _ => @test.fail("expected component diagram")
  }
  @test.assert_eq(document.render_svg().contains("Gateway API"), true)
}

///|
test "component declarations take precedence over sequence participants" {
  let source = "@startuml\ncomponent Gateway\nGateway --> Backend\n@enduml"
  @test.assert_eq(is_component_source(source), true)
  @test.assert_eq(is_sequence_source(source), false)
}

///|
test "document facade dispatches a use-case diagram" {
  let source = "@startuml\n:Customer: --> (Place order)\n@enduml"
  @test.assert_eq(is_usecase_source(source), true)
  let document = parse_usecase(source)
  @test.assert_eq(document.kind() is UseCase, true)
  @test.assert_eq(document.render_svg().contains("Place order"), true)
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
test "activity parser recognizes and preserves structured commands" {
  let source = "@startuml\nstart\nif (ready?) then (yes)\n:Run;\nendif\nstop\n@enduml"
  @test.assert_eq(is_activity_source(source), true)
  @test.assert_eq(parse_activity(source).kind() is Activity, true)
  @test.assert_eq(
    parse_activity(source).render_svg().contains("Activity diagram"),
    true,
  )
  @test.assert_eq(
    is_activity_source("@startuml\nclass Service\n@enduml"),
    false,
  )
}

///|
test "document facade dispatches state diagrams before class diagrams" {
  let source = "@startuml\n[*] --> Idle\nstate Idle\n@enduml"
  @test.assert_eq(is_state_source(source), true)
  let document = parse_state(source)
  @test.assert_eq(document.kind() is State, true)
  @test.assert_eq(document.render_svg().contains("State diagram"), true)
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
test "document facade renders YAML and TOML structure diagrams" {
  let yaml_source = "@startyaml\nservice:\n  port: 8080\n@endyaml"
  let yaml_document = parse_yaml(yaml_source)
  @test.assert_eq(yaml_document.kind() is Yaml, true)
  @test.assert_eq(
    yaml_document.render_svg().contains("aria-label=\"YAML diagram\""),
    true,
  )
  @test.assert_eq(is_yaml_source("\n@STARTYAML\nkey: value\n@endyaml"), true)

  let toml_source = "@starttoml\n[service]\nport = 8080\n@endtoml"
  let toml_document = parse_toml(toml_source)
  @test.assert_eq(toml_document.kind() is Toml, true)
  @test.assert_eq(
    toml_document.render_svg().contains("aria-label=\"TOML diagram\""),
    true,
  )
  @test.assert_eq(
    is_toml_source("\n@STARTTOML\nkey = \"value\"\n@endtoml"),
    true,
  )
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
test "dispatches object declarations through the object facade" {
  let source = "@startuml\npackage domain {\nobject Customer\n}\n@enduml"
  let document = parse_object(source)
  @test.assert_eq(is_object_source(source), true)
  @test.assert_eq(document.kind() is Object, true)
  @test.assert_eq(
    document.render_svg().contains("data-code=\"domain.Customer\""),
    true,
  )
  @test.assert_eq(
    is_object_source("@startuml\nclass Model\nobject Value\n@enduml"),
    false,
  )
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
