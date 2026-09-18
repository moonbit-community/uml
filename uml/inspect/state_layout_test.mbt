///|
fn layout_node(
  layout : @render.StateLayout,
  code : String,
) -> @render.StateNodeLayout {
  for node in layout.nodes {
    if node.code == code {
      return node
    }
  }
  abort("missing state layout node: " + code)
}

///|
fn layout_edge(
  layout : @render.StateLayout,
  transition_index : Int,
) -> @render.StateEdgeLayout {
  for edge in layout.edges {
    if edge.transition_index == transition_index {
      return edge
    }
  }
  abort("missing state layout edge: " + transition_index.to_string())
}

///|
fn @render.StateNodeLayout::contains(
  self : @render.StateNodeLayout,
  child : @render.StateNodeLayout,
) -> Bool {
  child.x >= self.x &&
  child.y >= self.y &&
  child.x + child.width <= self.x + self.width &&
  child.y + child.height <= self.y + self.height
}

///|
fn @render.StateNodeLayout::does_not_overlap(
  self : @render.StateNodeLayout,
  other : @render.StateNodeLayout,
) -> Bool {
  self.x + self.width <= other.x ||
  other.x + other.width <= self.x ||
  self.y + self.height <= other.y ||
  other.y + other.height <= self.y
}

///|
fn @render.StateEdgeLayout::has_drawable_path(
  self : @render.StateEdgeLayout,
) -> Bool {
  self.paths.any(path => {
    guard path.length() > 1 else { false }
    path[0] != path[path.length() - 1]
  })
}

///|
test "recursive layout keeps composite contents inside their rendered parent" {
  let diagram = @parser.parse_state(
    "@startuml\nstate Work {\n[*] --> Input\nInput --> Capacity\n}\nWork --> Done\n@enduml",
  )
  let layout = @render.layout_state(diagram)
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
  let layout = @render.layout_state(diagram)
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
  let layout = @render.layout_state(diagram)
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
  let layout = @render.layout_state(diagram)
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
  let layout = @render.layout_state(
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
  @test.assert_eq(note_center(2).1 > b.1, true)
}

///|
test "note font metrics participate in Graphviz node sizing" {
  let regular = @render.layout_state(
      @parser.parse_state(
        "@startuml\nstate Ready\nnote right of Ready\nreview details\nend note\n@enduml",
      ),
    ).notes[0]
  let enlarged = @render.layout_state(
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
    @render.layout_state(diagram).nodes
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
  let layout = @render.layout_state(diagram)
  let a = layout_node(layout, "A")
  let b = layout_node(layout, "B")
  @test.assert_eq(a.x + a.width <= b.x || b.x + b.width <= a.x, true)
}

///|
test "self transitions and their notes survive in each containing scope" {
  for
    source in [
      "state Ready\nReady --> Ready : retry\nnote on link : again", "state Work {\nstate Ready\nReady --> Ready : retry\nnote on link : again\n}",
      "state Work {\nstate Ready\n}\nWork --> Work : retry\nnote on link : again",
      "state Work {\nstate Ready\n--\nstate Busy\nBusy --> Busy : retry\nnote on link : again\n}",
    ] {
    let diagram = @parser.parse_state("@startuml\n" + source + "\n@enduml")
    let layout = @render.layout_state(diagram)
    @test.assert_eq(layout.edges.length(), diagram.transitions.length())
    @test.assert_eq(layout.notes.length(), diagram.notes.length())
    for edge in layout.edges {
      @test.assert_eq(edge.has_drawable_path(), true)
      @test.assert_eq(edge.label is Some(_), true)
    }
  }
}

///|
test "synchronization bars rotate with the diagram direction" {
  let source = "\n[*] --> ==join==\n==join== --> [*]\n@enduml"
  let vertical = @render.layout_state(@parser.parse_state("@startuml" + source))
  let horizontal = @render.layout_state(
    @parser.parse_state("@startuml\nleft to right direction" + source),
  )
  let bar = layout_node(vertical, "__synchronization_join")
  let rotated = layout_node(horizontal, "__synchronization_join")
  @test.assert_eq(bar.width > bar.height, true)
  @test.assert_eq(rotated.width < rotated.height, true)
  @test.assert_eq((bar.width, bar.height), (rotated.height, rotated.width))
}

///|
test "initial final and history states retain their distinct circle sizes" {
  let layout = @render.layout_state(
    @parser.parse_state("@startuml\n[*] --> [H]\n[H] --> [*]\n@enduml"),
  )
  let initial = layout_node(layout, "__initial__")
  let final_node = layout_node(layout, "__final__")
  let history = layout_node(layout, "__history__")
  @test.assert_eq(initial.width < final_node.width, true)
  @test.assert_eq(
    (history.width, history.height),
    (final_node.width, final_node.height),
  )
  for node in layout.nodes {
    @test.assert_eq(node.width, node.height)
  }
}

///|
test "off-axis transitions attach to curved and diamond outlines" {
  for source in ["[*]", "[H]", "[H*]", "Decision"] {
    let declaration = if source == "Decision" {
      "state Decision <<choice>>\n"
    } else {
      ""
    }
    let diagram = @parser.parse_state(
      "@startuml\n" +
      declaration +
      source +
      " --> Left\n" +
      source +
      " --> Center\n" +
      source +
      " --> Right\n@enduml",
    )
    let layout = @render.layout_state(diagram)
    let node = layout_node(layout, diagram.transitions[0].source)
    // A diagonal contact with a circle or diamond is strictly inside its
    // enclosing rectangle. Routing against a box leaves all contacts outside.
    @test.assert_eq(
      layout.edges.any(edge => {
        edge.paths.any(path => {
          guard !path.is_empty() else { return false }
          let point = path[0]
          point.0 > node.x &&
          point.0 < node.x + node.width &&
          point.1 > node.y &&
          point.1 < node.y + node.height
        })
      }),
      true,
    )
  }
}

///|
test "transition label font size reserves space in both rank directions" {
  for direction in ["", "left to right direction\n"] {
    let source = direction + "A --> B : transition details\n@enduml"
    let regular = @render.layout_state(
      @parser.parse_state("@startuml\n" + source),
    )
    let enlarged = @render.layout_state(
      @parser.parse_state("@startuml\nskinparam ArrowFontSize 32\n" + source),
    )
    let gap = (layout : @render.StateLayout) => {
      let a = layout_node(layout, "A")
      let b = layout_node(layout, "B")
      if direction.is_empty() {
        b.y - (a.y + a.height)
      } else {
        b.x - (a.x + a.width)
      }
    }
    @test.assert_eq(gap(enlarged) > gap(regular), true)
  }
}
