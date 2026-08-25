///|
test "parses initial and final pseudo-states as distinct state nodes" {
  let diagram = parse_state("@startuml\n[*] --> Idle\nIdle --> [*]\n@enduml")
  @test.assert_eq(
    diagram.state("__initial__").unwrap().kind,
    @flow.StateKind::Initial,
  )
  @test.assert_eq(
    diagram.state("__final__").unwrap().kind,
    @flow.StateKind::Final,
  )
  @test.assert_eq(diagram.transitions.length(), 2)
}

///|
test "declaration completes a transition-created state instead of duplicating it" {
  let diagram = parse_state(
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
  let diagram = parse_state(
    "@startuml\nstate Work {\nstate Input\n--\nstate Capacity\n}\n@enduml",
  )
  @test.assert_eq(diagram.state("Input").unwrap().parent, Some("Work"))
  @test.assert_eq(diagram.state("Capacity").unwrap().parent, Some("Work"))
  @test.assert_eq(diagram.concurrent_regions, ["Work"])
}

///|
test "preserves history synchronization transition metadata and notes" {
  let diagram = parse_state(
    "@startuml\nstate A\nstate B\nA -right-> B : next\nB --> [H]\n[H] --> ==join==\nnote right of A\nremember\nend note\nnote on link : transition note\n@enduml",
  )
  @test.assert_eq(
    diagram.transitions[0].direction,
    @flow.TransitionDirection::Rightward,
  )
  @test.assert_eq(
    diagram.state("__history__").unwrap().kind,
    @flow.StateKind::History,
  )
  @test.assert_eq(
    diagram.state("__synchronization_join").unwrap().kind,
    @flow.StateKind::Synchronization,
  )
  @test.assert_eq(diagram.notes[0].target, @flow.StateNote("A"))
  @test.assert_eq(
    diagram.notes[1].target,
    @flow.StateNoteTarget::TransitionNote(2),
  )
}

///|
test "preserves declaration stereotypes and frame aliases in scope" {
  let diagram = parse_state(
    "@startuml\nstate Decision <<choice>>\nframe \"Order flow\" as Flow {\nstate Paid\n}\n@enduml",
  )
  @test.assert_eq(
    diagram.state("Decision").unwrap().kind,
    @flow.StateKind::Choice,
  )
  @test.assert_eq(
    diagram.state("Decision").unwrap().stereotype,
    Some("<<choice>>"),
  )
  @test.assert_eq(diagram.state("Flow").unwrap().display, "Order flow")
  @test.assert_eq(diagram.state("Paid").unwrap().parent, Some("Flow"))
}

///|
test "preserves URL metadata declared on a state" {
  let diagram = parse_state(
    "@startuml\nstate Review [[https://example.com/review]] #lightyellow\n@enduml",
  )
  @test.assert_eq(
    diagram.state("Review").unwrap().url,
    Some("https://example.com/review"),
  )
}

///|
test "preserves inline colors on state and link notes" {
  let diagram = parse_state(
    "@startuml\nA --> B\nnote right of A #pink\nentity note\nend note\nnote on link #lightblue : link note\n@enduml",
  )
  @test.assert_eq(diagram.notes[0].color, Some("pink"))
  @test.assert_eq(diagram.notes[1].color, Some("lightblue"))
}

///|
test "parsec transition grammar preserves reverse endpoints and line styles" {
  let diagram = parse_state(
    "@startuml\nArchived <-[bold]- Closed : archive\n@enduml",
  )
  let transition = diagram.transitions[0]
  @test.assert_eq(transition.source, "Closed")
  @test.assert_eq(transition.target, "Archived")
  @test.assert_eq(transition.line_style, Some("bold"))
  @test.assert_eq(transition.label, Some("archive"))
}

///|
test "transition arrow splits hyphens and styles around the direction" {
  let diagram = parse_state(
    "@startuml\nA -[dashed]left-> B\nC -up-> D\nE x-[bold]-> F\n@enduml",
  )
  let transitions = diagram.transitions
  @test.assert_eq(transitions[0].direction, @flow.TransitionDirection::Leftward)
  @test.assert_eq(transitions[0].line_style, Some("dashed"))
  @test.assert_eq(transitions[1].direction, @flow.TransitionDirection::Upward)
  @test.assert_eq(transitions[2].line_style, Some("bold"))
  @test.assert_eq(transitions[2].has_cross_start, true)
}

///|
test "reverse arrow keeps reversed endpoints and a bare cross marker" {
  let diagram = parse_state(
    "@startuml\nA <-left- B\nC <-x D\nE o<-- F\nG o <-- H\nI -->o J\n@enduml",
  )
  let transitions = diagram.transitions
  @test.assert_eq(transitions[0].source, "B")
  @test.assert_eq(transitions[0].target, "A")
  @test.assert_eq(transitions[0].direction, @flow.TransitionDirection::Leftward)
  @test.assert_eq(transitions[1].source, "D")
  @test.assert_eq(transitions[1].target, "C")
  @test.assert_eq(transitions[1].line_style, None)
  @test.assert_eq(transitions[1].has_cross_start, true)
  @test.assert_eq(transitions[1].has_circle_end, false)
  @test.assert_eq(transitions[2].source, "F")
  @test.assert_eq(transitions[2].target, "E")
  @test.assert_eq(transitions[2].has_circle_end, true)
  @test.assert_eq(transitions[2].has_cross_start, false)
  @test.assert_eq(transitions[3].source, "H")
  @test.assert_eq(transitions[3].target, "G")
  @test.assert_eq(transitions[3].has_circle_end, true)
  @test.assert_eq(transitions[4].source, "I")
  @test.assert_eq(transitions[4].target, "J")
  @test.assert_eq(transitions[4].has_circle_end, true)
}

///|
test "compact group openers and the begin keyword open composite states" {
  let diagram = parse_state(
    "@startuml\nstate Work{\nstate A\n}\nstate Flow begin\nstate B\nend state\n@enduml",
  )
  @test.assert_eq(diagram.state("A").unwrap().parent, Some("Work"))
  @test.assert_eq(diagram.state("B").unwrap().parent, Some("Flow"))
}

///|
test "synchronization endpoints consume surrounding spaces in transitions" {
  let diagram = parse_state(
    "@startuml\n[*] --> ==join==\n==join== --> Done\n@enduml",
  )
  @test.assert_eq(diagram.transitions.length(), 2)
  @test.assert_eq(
    diagram.state("__synchronization_join").unwrap().kind,
    @flow.StateKind::Synchronization,
  )
}

///|
test "quoted identifiers and escaped quotes stay single tokens" {
  let diagram = parse_state(
    "@startuml\nstate \"A \\\"quoted\\\"\" as Q\n\"A \\\"quoted\\\"\" --> Q\n@enduml",
  )
  let state = diagram.state("Q").unwrap()
  @test.assert_eq(state.display, "A \\\"quoted\\\"")
  @test.assert_eq(diagram.transitions.length(), 1)
}
