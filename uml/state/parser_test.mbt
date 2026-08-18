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
test "preserves inline colors on state and link notes" {
  let diagram = parse(
    "@startuml\nA --> B\nnote right of A #pink\nentity note\nend note\nnote on link #lightblue : link note\n@enduml",
  )
  @test.assert_eq(diagram.notes[0].color, Some("pink"))
  @test.assert_eq(diagram.notes[1].color, Some("lightblue"))
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
test "transition arrow splits hyphens and styles around the direction" {
  let diagram = parse(
    "@startuml\nA -[dashed]left-> B\nC -up-> D\nE x-[bold]-> F\n@enduml",
  )
  let transitions = diagram.transitions
  @test.assert_eq(transitions[0].direction, Leftward)
  @test.assert_eq(transitions[0].line_style, Some("dashed"))
  @test.assert_eq(transitions[1].direction, Upward)
  @test.assert_eq(transitions[2].line_style, Some("bold"))
  @test.assert_eq(transitions[2].has_cross_start, true)
}

///|
test "reverse arrow keeps reversed endpoints and a bare cross marker" {
  let diagram = parse("@startuml\nA <-left- B\nC <-x D\nE o<-- F\n@enduml")
  let transitions = diagram.transitions
  @test.assert_eq(transitions[0].source, "B")
  @test.assert_eq(transitions[0].target, "A")
  @test.assert_eq(transitions[0].direction, Leftward)
  @test.assert_eq(transitions[1].source, "D")
  @test.assert_eq(transitions[1].target, "C")
  @test.assert_eq(transitions[1].line_style, None)
  @test.assert_eq(transitions[2].source, "F")
  @test.assert_eq(transitions[2].target, "E")
}

///|
test "compact group openers and the begin keyword open composite states" {
  let diagram = parse(
    "@startuml\nstate Work{\nstate A\n}\nstate Flow begin\nstate B\nend state\n@enduml",
  )
  @test.assert_eq(diagram.state("A").unwrap().parent, Some("Work"))
  @test.assert_eq(diagram.state("B").unwrap().parent, Some("Flow"))
}

///|
test "synchronization endpoints consume surrounding spaces in transitions" {
  let diagram = parse("@startuml\n[*] --> ==join==\n==join== --> Done\n@enduml")
  @test.assert_eq(diagram.transitions.length(), 2)
  @test.assert_eq(
    diagram.state("__synchronization_join").unwrap().kind,
    Synchronization,
  )
}

///|
test "quoted identifiers and escaped quotes stay single tokens" {
  let diagram = parse(
    "@startuml\nstate \"A \\\"quoted\\\"\" as Q\n\"A \\\"quoted\\\"\" --> Q\n@enduml",
  )
  let state = diagram.state("Q").unwrap()
  @test.assert_eq(state.display, "A \\\"quoted\\\"")
  @test.assert_eq(diagram.transitions.length(), 1)
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
fn layout_edge(layout : StateLayout, transition_index : Int) -> StateEdgeLayout {
  for edge in layout.edges {
    if edge.transition_index == transition_index {
      return edge
    }
  }
  abort("missing state layout edge: " + transition_index.to_string())
}

///|
fn StateNodeLayout::contains(
  self : StateNodeLayout,
  child : StateNodeLayout,
) -> Bool {
  child.x >= self.x &&
  child.y >= self.y &&
  child.x + child.width <= self.x + self.width &&
  child.y + child.height <= self.y + self.height
}

///|
fn StateNodeLayout::does_not_overlap(
  self : StateNodeLayout,
  other : StateNodeLayout,
) -> Bool {
  self.x + self.width <= other.x ||
  other.x + other.width <= self.x ||
  self.y + self.height <= other.y ||
  other.y + other.height <= self.y
}

///|
fn StateEdgeLayout::has_drawable_path(self : StateEdgeLayout) -> Bool {
  self.paths.any(path => {
    guard path.length() > 1 else { false }
    path[0] != path[path.length() - 1]
  })
}

///|
test "recursive layout keeps composite contents inside their rendered parent" {
  let diagram = parse(
    "@startuml\nstate Work {\n[*] --> Input\nInput --> Capacity\n}\nWork --> Done\n@enduml",
  )
  let layout = diagram.layout()
  let work = layout_node(layout, "Work")
  for state in diagram.states {
    guard state.parent == Some("Work") else { continue }
    @test.assert_eq(work.contains(layout_node(layout, state.code)), true)
  }
}

///|
test "concurrent regions preserve orientation and never overlap" {
  let diagram = parse(
    "@startuml\nstate Work {\nstate Input\n--\nstate Capacity\n--\nstate Audit\n}\n@enduml",
  )
  let layout = diagram.layout()
  @test.assert_eq(
    layout.regions.any(region => region.separator == Some(Horizontal)),
    true,
  )
  let region_nodes = ["Input", "Capacity", "Audit"].map(code => {
    layout_node(layout, code)
  })
  for index in 0..<region_nodes.length() {
    for other in (index + 1)..<region_nodes.length() {
      @test.assert_eq(
        region_nodes[index].does_not_overlap(region_nodes[other]),
        true,
      )
    }
  }
}

///|
test "fixture transitions retain drawable paths" {
  let diagram = parse(
    "@startuml\nstate Open\nstate Closed\nstate Archived\nOpen -[dashed]-> Closed : close\nArchived <-[bold]- Closed : archive\nOpen x--> Archived : cancel\n@enduml",
  )
  let layout = diagram.layout()
  @test.assert_eq(layout.edges.length(), diagram.transitions.length())
  for transition_index in 0..<diagram.transitions.length() {
    @test.assert_eq(
      layout_edge(layout, transition_index).has_drawable_path(),
      true,
    )
  }
}

///|
test "state and link notes participate in layout" {
  let diagram = parse(
    "@startuml\nA --> B : next\nnote right of A\nremember\nend note\nnote on link : transition detail\n@enduml",
  )
  let layout = diagram.layout()
  @test.assert_eq(layout.notes.length(), diagram.notes.length())
}

///|
test "note font metrics participate in Graphviz node sizing" {
  let regular = parse(
      "@startuml\nstate Ready\nnote right of Ready\nreview details\nend note\n@enduml",
    ).layout().notes[0]
  let enlarged = parse(
      "@startuml\nskinparam NoteFontSize 24\nstate Ready\nnote right of Ready\nreview details\nend note\n@enduml",
    ).layout().notes[0]
  @test.assert_eq(enlarged.width > regular.width, true)
  @test.assert_eq(enlarged.height > regular.height, true)
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
