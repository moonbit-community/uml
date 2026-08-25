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
test "circle and cross decorations render at the semantic transition ends" {
  let svg = render_state(
    "@startuml\nA x--> B\nC -->o D\nE o <-- F\nG <--x H\n@enduml",
  )
  @test.assert_eq(
    count_substring(svg, "marker-start=\"url(#state-cross-start)\""),
    2,
  )
  @test.assert_eq(count_substring(svg, "<ellipse"), 2)
  let first = svg[svg.find("<ellipse").unwrap():].to_owned()
  let after_first = first[first.find("/>").unwrap() + 2:].to_owned()
  let second = after_first[after_first.find("<ellipse").unwrap():].to_owned()
  let center = (part : String) => {
    ellipse_attribute(part, "cx") + "," + ellipse_attribute(part, "cy")
  }
  @test.assert_eq(center(first) == center(second), false)
}

///|
fn count_substring(haystack : String, needle : String) -> Int {
  let mut count = 0
  let mut view = haystack[:]
  while view.contains(needle) {
    count += 1
    view = view[view.find(needle).unwrap() + needle.length():]
  }
  count
}

///|
fn ellipse_attribute(part : String, name : String) -> String {
  let start = part.find(name + "=\"").unwrap() + name.length() + 2
  let rest = part[start:].to_owned()
  rest[:rest.find("\"").unwrap()].to_owned()
}

///|
test "recursive layout keeps composite contents inside their rendered parent" {
  let diagram = @parser.parse_state(
    "@startuml\nstate Work {\n[*] --> Input\nInput --> Capacity\n}\nWork --> Done\n@enduml",
  )
  let layout = layout_state(diagram)
  let work = layout_node(layout, "Work")
  for state in diagram.states {
    guard state.parent == Some("Work") else { continue }
    @test.assert_eq(work.contains(layout_node(layout, state.code)), true)
  }
}

///|
test "concurrent regions preserve orientation and never overlap" {
  let diagram = @parser.parse_state(
    "@startuml\nstate Work {\nstate Input\n--\nstate Capacity\n--\nstate Audit\n}\n@enduml",
  )
  let layout = layout_state(diagram)
  @test.assert_eq(
    layout.regions.any(region => {
      region.separator == Some(@flow.StateRegionSeparator::Horizontal)
    }),
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
  let diagram = @parser.parse_state(
    "@startuml\nstate Open\nstate Closed\nstate Archived\nOpen -[dashed]-> Closed : close\nArchived <-[bold]- Closed : archive\nOpen x--> Archived : cancel\n@enduml",
  )
  let layout = layout_state(diagram)
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
  let diagram = @parser.parse_state(
    "@startuml\nA --> B : next\nnote right of A\nremember\nend note\nnote on link : transition detail\n@enduml",
  )
  let layout = layout_state(diagram)
  @test.assert_eq(layout.notes.length(), diagram.notes.length())
}

///|
test "note position words are preserved on entity notes" {
  let diagram = @parser.parse_state(
    "@startuml\nstate A\nstate B\nnote left of A\nleft text\nend note\nnote right of B\nright text\nend note\nnote top of A\ntop text\nend note\nnote bottom of B\nbottom text\nend note\n@enduml",
  )
  let positions = diagram.notes.map(note => note.position)
  @test.assert_eq(positions[0], Some(@flow.StateNotePosition::NoteLeft))
  @test.assert_eq(positions[1], Some(@flow.StateNotePosition::NoteRight))
  @test.assert_eq(positions[2], Some(@flow.StateNotePosition::NoteTop))
  @test.assert_eq(positions[3], Some(@flow.StateNotePosition::NoteBottom))
}

///|
test "entity notes land on the requested side of their anchor" {
  let layout = layout_state(
    @parser.parse_state(
      "@startuml\nstate A\nstate B\nnote left of A\nleft note\nend note\nnote right of B\nright note\nend note\nnote bottom of B\nbottom note\nend note\n@enduml",
    ),
  )
  let node_center = (code : String) => {
    let node = layout.nodes.filter(node => node.code == code)[0]
    (node.x + node.width / 2.0, node.y + node.height / 2.0)
  }
  let note_center = (index : Int) => {
    let note = layout.notes[index]
    (note.x + note.width / 2.0, note.y + note.height / 2.0)
  }
  let a = node_center("A")
  let b = node_center("B")
  @test.assert_eq(note_center(0).0 < a.0, true)
  @test.assert_eq(note_center(1).0 > b.0, true)
  @test.assert_eq(note_center(1).1 - b.1 < 1.0, true)
  @test.assert_eq(note_center(2).1 > b.1, true)
}

///|
test "note font metrics participate in Graphviz node sizing" {
  let regular = layout_state(
      @parser.parse_state(
        "@startuml\nstate Ready\nnote right of Ready\nreview details\nend note\n@enduml",
      ),
    ).notes[0]
  let enlarged = layout_state(
      @parser.parse_state(
        "@startuml\nskinparam NoteFontSize 24\nstate Ready\nnote right of Ready\nreview details\nend note\n@enduml",
      ),
    ).notes[0]
  @test.assert_eq(enlarged.width > regular.width, true)
  @test.assert_eq(enlarged.height > regular.height, true)
}

///|
test "nested pseudo-states belong to their composite scope" {
  let diagram = @parser.parse_state(
    "@startuml\n[*] --> Work\nstate Work {\n[*] --> Ready\nReady --> [*]\n}\n@enduml",
  )
  @test.assert_eq(
    diagram.state("__initial__Work").unwrap().parent,
    Some("Work"),
  )
  @test.assert_eq(diagram.state("__final__Work").unwrap().parent, Some("Work"))
  @test.assert_eq(
    layout_state(diagram).nodes
    .filter(node => node.code == "__initial__Work")
    .length(),
    1,
  )
}

///|
test "layout direction is forwarded to the Graphviz state pass" {
  let diagram = @parser.parse_state(
    "@startuml\nleft to right direction\nA --> B\n@enduml",
  )
  let layout = layout_state(diagram)
  let a = layout_node(layout, "A")
  let b = layout_node(layout, "B")
  @test.assert_eq(a.x + a.width <= b.x || b.x + b.width <= a.x, true)
}
