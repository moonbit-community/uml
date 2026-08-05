///|
test "parse dispatches structured formats by their delimiters" {
  @test.assert_eq(
    parse("@startjson\n{\"items\":[]}\n@endjson").kind() is Json,
    true,
  )
  @test.assert_eq(
    parse("@startyaml\nkey: value\n@endyaml").kind() is Yaml,
    true,
  )
  @test.assert_eq(
    parse("@starttoml\nkey = \"value\"\n@endtoml").kind() is Toml,
    true,
  )
  @test.assert_eq(
    parse("@startmindmap\n* Root\n@endmindmap").kind() is Mindmap,
    true,
  )
}

///|
test "unknown documents raise a parse error" {
  @test.assert_raise(() => ignore(parse("@startuml\n@enduml")))
}

///|
test "parse dispatches activity commands before other heuristics" {
  let source = "@startuml\nstart\n:Run;\nstop\n@enduml"
  @test.assert_eq(parse(source).kind() is Activity, true)
}

///|
test "sequence grouping commands win over class-style reply arrows" {
  let source = "@startuml\nAlice -> Bob\nalt success\nBob --> Alice : response\nend\n@enduml"
  @test.assert_eq(parse(source).kind() is Sequence, true)
}

///|
test "sequence-only arrow dressings select the sequence parser" {
  let source = "@startuml\nAlice \\-> Bob : bottom\nAlice /--> Bob : dotted top\n@enduml"
  @test.assert_eq(parse(source).kind() is Sequence, true)
}

///|
test "participant shapes classify as sequence only with messages" {
  @test.assert_eq(
    parse("@startuml\nactor User\nUser -> Service : call\n@enduml").kind()
    is Sequence,
    true,
  )
  @test.assert_eq(parse("@startuml\nactor User\n@enduml").kind() is Class, true)
}

///|
test "component declarations take precedence over sequence participants" {
  let source = "@startuml\ncomponent Gateway\nGateway --> Backend\n@enduml"
  @test.assert_eq(parse(source).kind() is Component, true)
}

///|
test "participant shapes with component-like keywords stay sequence" {
  let source = "@startuml\nboundary Gateway\ncontrol Controller\ncollections CollectionA\nGateway -> Controller : call\n@enduml"
  @test.assert_eq(parse(source).kind() is Sequence, true)
}

///|
test "sequence grouping with else branches stays sequence" {
  let source = "@startuml\nAlice -> Bob\nalt success\nBob -> Carol\nelse error\nBob --> Alice\nend\n@enduml"
  @test.assert_eq(parse(source).kind() is Sequence, true)
}

///|
test "activity partition blocks stay activity" {
  let source = "@startuml\nstart\npartition A {\n:work;\n}\nstop\n@enduml"
  @test.assert_eq(parse(source).kind() is Activity, true)
}

///|
test "usecase endpoint syntax takes precedence over actor messages" {
  let source = "@startuml\nactor Customer\nCustomer --> (Place order)\n@enduml"
  @test.assert_eq(parse(source).kind() is UseCase, true)
}

///|
test "state markers select the state parser" {
  let source = "@startuml\n[*] --> Idle\nstate Idle\n@enduml"
  @test.assert_eq(parse(source).kind() is State, true)
}

///|
test "object declarations dispatch through the object facade" {
  @test.assert_eq(
    parse("@startuml\nobject User\n@enduml").kind() is Object,
    true,
  )
  @test.assert_eq(
    parse("@startuml\nclass Model\nobject Value\n@enduml").kind() is Class,
    true,
  )
}

///|
test "class declarations and dotted arrows select the class parser" {
  @test.assert_eq(
    parse("@startuml\nclass User\nUser --> Account\n@enduml").kind() is Class,
    true,
  )
  @test.assert_eq(parse("@startuml\nA .> B\n@enduml").kind() is Class, true)
}

///|
test "render_svg renders every diagram family" {
  let sources = [
    "@startjson\n{\"items\":[1,2]}\n@endjson", "@startyaml\nservice:\n  port: 8080\n@endyaml",
    "@starttoml\n[service]\nport = 8080\n@endtoml", "@startmindmap\n* Root\n** Child\n@endmindmap",
    "@startuml\nstart\n:Run;\nstop\n@enduml", "@startuml\nparticipant Client\nClient -> Server : request\n@enduml",
    "@startuml\n[*] --> Idle\nstate Idle\n@enduml", "@startuml\n:Customer: --> (Place order)\n@enduml",
    "@startuml\ncomponent Gateway\n[Client] --> Gateway\n@enduml", "@startuml\nobject User\n@enduml",
    "@startuml\nclass User\nUser --> Account\n@enduml",
  ]
  for source in sources {
    @test.assert_eq(render_svg(source).length() > 0, true)
  }
}
