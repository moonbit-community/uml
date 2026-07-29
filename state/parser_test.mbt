///|
test "parses initial and final pseudo-states as distinct state nodes" {
  let diagram = parse("@startuml\n[*] --> Idle\nIdle --> [*]\n@enduml")
  @test.assert_eq(diagram.state("__initial__").unwrap().kind, Initial)
  @test.assert_eq(diagram.state("__final__").unwrap().kind, Final)
  @test.assert_eq(diagram.transitions.length(), 2)
}

///|
test "declaration completes a transition-created state instead of duplicating it" {
  let diagram = parse(
    "@startuml\n[*] --> Active\nstate \"Active session\" as Active : connected\n@enduml",
  )
  @test.assert_eq(
    diagram.states.filter(state => state.code == "Active").length(),
    1,
  )
  let state = diagram.state("Active").unwrap()
  @test.assert_eq(state.display, "Active session")
  @test.assert_eq(state.description, Some("connected"))
}

///|
test "keeps composite ownership and concurrent region separators" {
  let diagram = parse(
    "@startuml\nstate Work {\nstate Input\n--\nstate Capacity\n}\n@enduml",
  )
  @test.assert_eq(diagram.state("Input").unwrap().parent, Some("Work"))
  @test.assert_eq(diagram.state("Capacity").unwrap().parent, Some("Work"))
  @test.assert_eq(diagram.concurrent_regions, ["Work"])
}

///|
test "preserves history synchronization transition metadata and notes" {
  let diagram = parse(
    "@startuml\nstate A\nstate B\nA -right-> B : next\nB --> [H]\n[H] --> =join=\nnote right of A\nremember\nend note\nnote on link : transition note\n@enduml",
  )
  @test.assert_eq(diagram.transitions[0].direction, Rightward)
  @test.assert_eq(diagram.state("__history__").unwrap().kind, History)
  @test.assert_eq(
    diagram.state("__synchronization_join").unwrap().kind,
    Synchronization,
  )
  @test.assert_eq(diagram.notes[0].target, StateNote("A"))
  @test.assert_eq(diagram.notes[1].target, TransitionNote(2))
}

///|
test "renders semantic state node and transition labels without coordinates" {
  let svg = render_state_svg("@startuml\n[*] --> Ready : begin\n@enduml")
  @test.assert_eq(svg.contains("aria-label=\"State diagram\""), true)
  @test.assert_eq(svg.contains("data-code=\"Ready\""), true)
  @test.assert_eq(svg.contains(">begin</text>"), true)
}

///|
test "preserves declaration stereotypes and frame aliases in scope" {
  let diagram = parse(
    "@startuml\nstate Decision <<choice>>\nframe \"Order flow\" as Flow {\nstate Paid\n}\n@enduml",
  )
  @test.assert_eq(diagram.state("Decision").unwrap().kind, Choice)
  @test.assert_eq(
    diagram.state("Decision").unwrap().stereotype,
    Some("<<choice>>"),
  )
  @test.assert_eq(diagram.state("Paid").unwrap().parent, Some("Flow"))
}

///|
test "preserves URL metadata declared on a state" {
  let diagram = parse(
    "@startuml\nstate Review [[https://example.com/review]] #lightyellow\n@enduml",
  )
  @test.assert_eq(
    diagram.state("Review").unwrap().url,
    Some("https://example.com/review"),
  )
}

///|
test "parsec transition grammar preserves reverse endpoints and line styles" {
  let diagram = parse("@startuml\nArchived <-[bold]- Closed : archive\n@enduml")
  let transition = diagram.transitions[0]
  @test.assert_eq(transition.source, "Closed")
  @test.assert_eq(transition.target, "Archived")
  @test.assert_eq(transition.line_style, Some("bold"))
  @test.assert_eq(transition.label, Some("archive"))
}
