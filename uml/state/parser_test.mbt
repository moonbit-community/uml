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
    "@startuml\nstate A\nstate B\nA -right-> B : next\nB --> [H]\n[H] --> ==join==\nnote right of A\nremember\nend note\nnote on link : transition note\n@enduml",
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
  @test.assert_eq(svg.contains(">begin</tspan>"), true)
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
  @test.assert_eq(diagram.state("Flow").unwrap().display, "Order flow")
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

///|
fn layout_node(layout : StateLayout, code : String) -> StateNodeLayout {
  for node in layout.nodes {
    if node.code == code {
      return node
    }
  }
  abort("missing state layout node: " + code)
}

///|
test "recursive layout keeps composite contents inside their rendered parent" {
  let diagram = parse(
    "@startuml\nstate Work {\n[*] --> Input\nInput --> Capacity\n}\nWork --> Done\n@enduml",
  )
  let layout = diagram.layout()
  let work = layout_node(layout, "Work")
  let input = layout_node(layout, "Input")
  let capacity = layout_node(layout, "Capacity")
  @test.assert_eq(layout.edges.length(), diagram.transitions.length())
  @test.assert_eq(input.x >= work.x, true)
  @test.assert_eq(input.y >= work.y, true)
  @test.assert_eq(input.x + input.width <= work.x + work.width, true)
  @test.assert_eq(input.y + input.height <= work.y + work.height, true)
  @test.assert_eq(capacity.x >= work.x, true)
  @test.assert_eq(capacity.y >= work.y, true)
  @test.assert_eq(capacity.x + capacity.width <= work.x + work.width, true)
  @test.assert_eq(capacity.y + capacity.height <= work.y + work.height, true)
}

///|
test "concurrent regions preserve their separator orientation in layout" {
  let diagram = parse(
    "@startuml\nstate Work {\nstate Input\n||\nstate Capacity\n}\n@enduml",
  )
  let layout = diagram.layout()
  let input = layout_node(layout, "Input")
  let capacity = layout_node(layout, "Capacity")
  @test.assert_eq(
    layout.regions.any(region => region.separator == Some(Vertical)),
    true,
  )
  @test.assert_eq(
    input.x + input.width <= capacity.x ||
    capacity.x + capacity.width <= input.x,
    true,
  )
}

///|
test "state and link notes participate in layout and SVG output" {
  let diagram = parse(
    "@startuml\nA --> B : next\nnote right of A\nremember\nend note\nnote on link : transition detail\n@enduml",
  )
  let layout = diagram.layout()
  @test.assert_eq(layout.notes.length(), diagram.notes.length())
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"state-note\""), true)
  @test.assert_eq(svg.contains(">remember</tspan>"), true)
  @test.assert_eq(svg.contains(">transition detail</tspan>"), true)
}

///|
test "nested pseudo-states belong to their composite scope" {
  let diagram = parse(
    "@startuml\n[*] --> Work\nstate Work {\n[*] --> Ready\nReady --> [*]\n}\n@enduml",
  )
  @test.assert_eq(
    diagram.state("__initial__Work").unwrap().parent,
    Some("Work"),
  )
  @test.assert_eq(diagram.state("__final__Work").unwrap().parent, Some("Work"))
  @test.assert_eq(
    diagram.layout().nodes
    .filter(node => node.code == "__initial__Work")
    .length(),
    1,
  )
}

///|
test "layout direction is forwarded to the Graphviz state pass" {
  let diagram = parse("@startuml\nleft to right direction\nA --> B\n@enduml")
  let layout = diagram.layout()
  let a = layout_node(layout, "A")
  let b = layout_node(layout, "B")
  @test.assert_eq(a.x + a.width <= b.x || b.x + b.width <= a.x, true)
}
