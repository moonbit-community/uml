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
  // A bare actor declaration is a description element: PlantUML's class
  // factory rejects it, so it renders with the use-case facade.
  @test.assert_eq(
    parse("@startuml\nactor User\n@enduml").kind() is UseCase,
    true,
  )
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
test "life-event commands alone select the sequence parser" {
  let source = "@startuml\nAlice -> Bob\nactivate Bob #FF0000\nBob --> Alice\n@enduml"
  @test.assert_eq(parse(source).kind() is Sequence, true)
}

///|
test "divider and delay lines alone select the sequence parser" {
  @test.assert_eq(
    parse("@startuml\nAlice -> Bob\n== checkpoint ==\n... wait ...\n@enduml").kind()
    is Sequence,
    true,
  )
  @test.assert_eq(
    parse(
      "@startuml\nhnote over Alice #lightgreen : colored hex\nrnote over Carol #lightcoral : colored box\n@enduml",
    ).kind()
    is Sequence,
    true,
  )
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
test "description declarations dispatch through the deployment facade" {
  @test.assert_eq(
    parse("@startuml\nnode Web\n@enduml").kind() is Deployment,
    true,
  )
  @test.assert_eq(
    parse("@startuml\nnode \"Web Server\" as web {\nnode App\n}\n@enduml").kind()
    is Deployment,
    true,
  )
  @test.assert_eq(
    parse("@startuml\ncloud Cache\n@enduml").kind() is Deployment,
    true,
  )
}

///|
test "allowmixing keeps description declarations in the class grammar" {
  let source = "@startuml\nallowmixing\nnode Web\nclass App\n@enduml"
  @test.assert_eq(parse(source).kind() is Class, true)
}

///|
test "class content decides between class and deployment grammars" {
  // The Java class factory parses symbol-keyword groups without
  // allowmixing, so class content inside a node body stays a class diagram.
  let grouped = "@startuml\nnode X {\nclass A\n}\n@enduml"
  @test.assert_eq(parse(grouped).kind() is Class, true)
  @test.assert_eq(
    parse("@startuml\nnode X\ninterface I\n@enduml").kind() is Deployment,
    true,
  )
  // Class-only declarations next to description leaves are an error in
  // PlantUML; the class facade reports it as a mixing error.
  @test.assert_raise(() => ignore(parse("@startuml\nnode X\nclass A\n@enduml")))
}

///|
test "association classes stay in the class grammar" {
  // `(Student, Course) -- Enrollment` is an association class, not a
  // use-case shape: PlantUML renders it with the class factory.
  let source = "@startuml\n(Student, Course) -- Enrollment\nEnrollment --> Student\n@enduml"
  @test.assert_eq(parse(source).kind() is Class, true)
}

///|
test "deployment symbols win over a use-case declaration" {
  // A node/cloud/database source mentioning a use case is still a
  // description (deployment) diagram in PlantUML, never a use-case diagram.
  let source = "@startuml\nnode Web\nusecase \"Login\" as login\nlogin ..> Web : uses\n@enduml"
  @test.assert_eq(parse(source).kind() is Deployment, true)
}

///|
test "allowmixing keeps description elements in the class grammar" {
  // With allowmixing the class factory accepts description declarations, so
  // actor/usecase/component leaves render as a class diagram.
  let source = "@startuml\nallowmixing\nactor Customer\nusecase \"Pay\" as Pay\ncomponent C\nCustomer --> Pay\n@enduml"
  @test.assert_eq(parse(source).kind() is Class, true)
}

///|
test "bare frames select deployment, state bodies select state" {
  @test.assert_eq(
    parse("@startuml\nframe X\n@enduml").kind() is Deployment,
    true,
  )
  let source = "@startuml\nframe \"Order flow\" as Flow {\nstate Paid\n}\n@enduml"
  @test.assert_eq(parse(source).kind() is State, true)
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
test "explicit class declarations win over triangle-arrow sequence substrings" {
  let source = "@startuml\nclass A\nclass B\nA -->> B\n@enduml"
  @test.assert_eq(parse(source).kind() is Class, true)
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

///|
test "explicit default theme preserves SVG output" {
  let sources = [
    "@startuml\nparticipant Alice\nAlice -> Bob : hello\n@enduml", "@startuml\nclass User {\n- secret\n}\n@enduml",
  ]
  for source in sources {
    @test.assert_eq(
      render_svg(source),
      render_svg(source, color_scheme=@style.ColorScheme::default()),
    )
  }
}

///|
test "document rendering delegates through the parsed diagram boundary" {
  let source = "@startuml\nparticipant Alice\nAlice -> Bob : hello\n@enduml"
  let document = parse(source)
  @test.assert_eq(document.render_svg(), document.diagram.render_svg())
}

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
test "dot render themes the graphviz defaults" {
  let scheme = @style.ColorScheme::ColorScheme(
    "#191a1b",
    "#161718",
    canvas="#101112",
    node="#131415",
  )
  let source = "@startdot\ndigraph G { a -> b; }\n@enddot"
  let svg = render_svg(source, color_scheme=scheme)
  @test.assert_eq(svg.contains("fill=\"#101112\""), true)
  @test.assert_eq(svg.contains("fill=\"white\""), false)
  @test.assert_eq(svg.contains("stroke=\"#161718\""), true)
  @test.assert_eq(svg.contains("fill=\"#191a1b\""), true)
}

///|
test "dot render fills filled nodes with the scheme node color" {
  let scheme = @style.ColorScheme::ColorScheme(
    "#191a1b",
    "#161718",
    canvas="#101112",
    node="#131415",
  )
  let source = "@startdot\ndigraph G { a [style=filled]; a -> b; }\n@enddot"
  let svg = render_svg(source, color_scheme=scheme)
  @test.assert_eq(svg.contains("fill=\"#131415\""), true)
}

///|
test "dot render lets dot attributes win over the scheme" {
  let scheme = @style.ColorScheme::ColorScheme(
    "#191a1b",
    "#161718",
    canvas="#101112",
    node="#131415",
  )
  let source =
    #|@startdot
    #|digraph G {
    #|  bgcolor="#112233";
    #|  a [style=filled, fillcolor="#445566", color="#778899", fontcolor="#aabbcc"];
    #|  a -> b [color="#ddeeff", fontcolor="#123456", label="edge"];
    #|}
    #|@enduml
  let svg = render_svg(source, color_scheme=scheme)
  @test.assert_eq(svg.contains("#112233"), true)
  @test.assert_eq(svg.contains("#445566"), true)
  @test.assert_eq(svg.contains("#778899"), true)
  @test.assert_eq(svg.contains("#aabbcc"), true)
  @test.assert_eq(svg.contains("#ddeeff"), true)
  @test.assert_eq(svg.contains("#123456"), true)
  @test.assert_eq(svg.contains("#101112"), false)
  @test.assert_eq(svg.contains("#131415"), false)
  @test.assert_eq(svg.contains("#161718"), true)
}

///|
test "dot render accepts a css-variable scheme" {
  let scheme = @style.ColorScheme::ColorScheme(
    "var(--uml-text)",
    "var(--uml-line)",
    canvas="var(--uml-canvas)",
    node="var(--uml-node)",
  )
  let source = "@startdot\ndigraph G { a [style=filled]; a -> b; }\n@enddot"
  let svg = render_svg(source, color_scheme=scheme)
  @test.assert_eq(svg.contains("fill=\"var(--uml-canvas)\""), true)
  @test.assert_eq(svg.contains("fill=\"var(--uml-node)\""), true)
  @test.assert_eq(svg.contains("stroke=\"var(--uml-line)\""), true)
  @test.assert_eq(svg.contains("fill=\"var(--uml-text)\""), true)
}

///|
test "dot render keeps the graphviz white canvas without a painted scheme" {
  let svg = render_svg("@startdot\ndigraph G { a -> b; }\n@enddot")
  @test.assert_eq(svg.contains("fill=\"white\""), true)
}

///|
test "document rendering threads the scheme into dot diagrams" {
  let scheme = @style.ColorScheme::ColorScheme(
    "#191a1b",
    "#161718",
    canvas="#101112",
  )
  let source = "@startdot\ndigraph G { a -> b; }\n@enddot"
  let svg = parse(source).render_svg(color_scheme=scheme)
  @test.assert_eq(svg.contains("fill=\"#101112\""), true)
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
