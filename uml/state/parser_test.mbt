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
test "state transition and note labels use their respective font roles" {
  let svg = render_state_svg(
    "@startuml\nstate Ready\n[*] --> Ready : begin\nnote right of Ready\ndetail\nend note\n@enduml",
  )
  @test.assert_eq(svg.contains(".state-pseudostate-label{font-family:"), true)
  @test.assert_eq(svg.contains(".state-transition-label{font-family:"), true)
  @test.assert_eq(svg.contains(".state-note-label{font-family:"), true)
  @test.assert_eq(
    svg.contains("font-size:" + @svg.auxiliary_label_font_size()),
    true,
  )
}

///|
test "state pseudo-states keep their own circle border style" {
  let svg = render_state_svg(
    "@startuml\nskinparam ArrowColor #123456\n[*] --> Done\nDone --> [*]\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"state-initial\""), true)
  @test.assert_eq(svg.contains("class=\"state-final-outer\""), true)
  @test.assert_eq(svg.contains("stroke=\"#181818\""), true)
  @test.assert_eq(svg.contains("stroke=\"#123456\""), true)
}

///|
test "state terminal circles consume their dedicated activity colors" {
  let svg = render_state_svg(
    "@startuml\nskinparam ActivityStartColor #110000\nskinparam ActivityEndColor #220000\n[*] --> Done\nDone --> [*]\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"state-initial\""), true)
  @test.assert_eq(svg.contains("fill=\"#110000\""), true)
  @test.assert_eq(svg.contains("class=\"state-final-outer\""), true)
  @test.assert_eq(svg.contains("class=\"state-final-inner\""), true)
  @test.assert_eq(svg.contains("stroke=\"#220000\""), true)
}

///|
test "history and choice share the official diamond style roles" {
  let svg = render_state_svg(
    "@startuml\nskinparam ActivityDiamondBackgroundColor #330000\nskinparam ActivityDiamondBorderColor #440000\nskinparam ActivityDiamondFontColor #550000\nskinparam ActivityDiamondFontName Courier New\nskinparam ActivityDiamondFontSize 17\n[*] --> Ready\nReady --> [H]\n[H] --> [H*]\nstate Decision <<choice>>\n[H*] --> Decision\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"state-history\""), true)
  @test.assert_eq(svg.contains("class=\"state-deep-history\""), true)
  @test.assert_eq(svg.contains("class=\"state-choice\""), true)
  @test.assert_eq(svg.contains("fill=\"#330000\""), true)
  @test.assert_eq(svg.contains("stroke=\"#440000\""), true)
  @test.assert_eq(
    svg.contains(
      ".state-pseudostate-label{font-family:Courier New;font-size:17px;fill:#550000}",
    ),
    true,
  )
  @test.assert_eq(svg.contains(">Decision</tspan>"), false)
}

///|
test "synchronization bars consume the activity bar background" {
  let svg = render_state_svg(
    "@startuml\nskinparam ActivityBarColor #660000\n[*] --> Ready\nReady --> ==join==\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"state-synchronization\""), true)
  @test.assert_eq(svg.contains("fill=\"#660000\""), true)
  @test.assert_eq(svg.contains("stroke=\"none\""), true)
}

///|
test "pseudo-state style roles fall back to dark theme colors" {
  let scheme = @style.ColorScheme::ColorScheme(
    "theme-text",
    "theme-line",
    canvas="theme-canvas",
    node="theme-node",
  )
  let svg = render_state_svg(
    "@startuml\n[*] --> Ready\nReady --> [H]\n[H] --> ==join==\n==join== --> [*]\n@enduml",
    color_scheme=scheme,
  )
  @test.assert_eq(svg.contains("class=\"state-initial\""), true)
  @test.assert_eq(svg.contains("class=\"state-history\""), true)
  @test.assert_eq(svg.contains("class=\"state-synchronization\""), true)
  @test.assert_eq(svg.contains("fill=\"theme-line\""), true)
  @test.assert_eq(svg.contains("fill=\"theme-node\""), true)
  @test.assert_eq(svg.contains("class=\"state-canvas\""), true)
  @test.assert_eq(svg.contains("fill=\"theme-canvas\""), true)
}

///|
test "state background and border skinparams paint normal states" {
  let svg = render_state_svg(
    "@startuml\nskinparam stateBackgroundColor #123456\nskinparam STATEBORDERCOLOR #654321\nstate Ready\n@enduml",
  )
  @test.assert_eq(svg.contains("fill=\"#123456\""), true)
  @test.assert_eq(svg.contains("stroke=\"#654321\""), true)
}

///|
test "inline state color takes precedence over the state background skinparam" {
  let svg = render_state_svg(
    "@startuml\nskinparam StateBackgroundColor #123456\nstate Ready #lightyellow\n@enduml",
  )
  @test.assert_eq(svg.contains("fill=\"#FFFFE0\""), true)
  @test.assert_eq(svg.contains("fill=\"#123456\""), false)
}

///|
test "state colors fall back to the selected theme" {
  let scheme = @style.ColorScheme::ColorScheme(
    "theme-text",
    "theme-line",
    node="theme-node",
  )
  let svg = render_state_svg(
    "@startuml\nstate Ready\n@enduml",
    color_scheme=scheme,
  )
  @test.assert_eq(svg.contains("fill=\"theme-node\""), true)
}

///|
test "state name and description use their independent font skinparams" {
  let svg = render_state_svg(
    "@startuml\nskinparam StateFontName Courier New\nskinparam StateFontSize 17\nskinparam StateFontColor #123456\nskinparam StateAttributeFontName Times New Roman\nskinparam StateAttributeFontSize 15\nskinparam StateAttributeFontColor #654321\nstate Ready : detail\n@enduml",
  )
  @test.assert_eq(
    svg.contains(
      ".state-label{font-family:Courier New;font-size:17px;fill:#123456}",
    ),
    true,
  )
  @test.assert_eq(
    svg.contains(
      ".state-description-label{font-family:Times New Roman;font-size:15px;fill:#654321}",
    ),
    true,
  )
  @test.assert_eq(svg.contains("class=\"state-description-label\""), true)
}

///|
test "empty descriptions choose the PlantUML shape selected by the directive" {
  let shown = render_state_svg("@startuml\nstate Empty\n@enduml")
  @test.assert_eq(shown.contains("data-shape=\"compartment\""), true)
  @test.assert_eq(shown.contains("class=\"state-compartment-separator\""), true)
  @test.assert_eq(shown.contains("class=\"state-description-label\""), false)

  let hidden = render_state_svg(
    "@startuml\nhide empty description\nstate Empty\n@enduml",
  )
  @test.assert_eq(hidden.contains("data-shape=\"empty\""), true)
  @test.assert_eq(
    hidden.contains("class=\"state-compartment-separator\""),
    false,
  )
  @test.assert_eq(hidden.contains("class=\"state-label\""), true)

  let restored = render_state_svg(
    "@startuml\nhide empty description\nshow empty description\nstate Empty\n@enduml",
  )
  @test.assert_eq(restored.contains("data-shape=\"compartment\""), true)
  @test.assert_eq(
    restored.contains("class=\"state-compartment-separator\""),
    true,
  )
}

///|
test "description state keeps a separate body label and compartment" {
  let svg = render_state_svg("@startuml\nstate Ready : connected\n@enduml")
  @test.assert_eq(svg.contains("data-shape=\"compartment\""), true)
  @test.assert_eq(svg.contains("class=\"state-compartment-separator\""), true)
  @test.assert_eq(svg.contains("class=\"state-description-label\""), true)
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
test "state URL wraps the node and stereotype selects scoped paint" {
  let svg = render_state_svg(
    "@startuml\nskinparam StateBackgroundColor #112233\nskinparam StateBackgroundColor<<manual>> #223344\nskinparam StateBorderColor<<manual>> #334455\nstate Review <<manual>> [[https://example.com/review]]\nstate Plain\n@enduml",
  )
  @test.assert_eq(svg.contains("data-stereotype=\"&lt;&lt;manual>>\""), true)
  @test.assert_eq(svg.contains("<a href=\"https://example.com/review\">"), true)
  @test.assert_eq(svg.contains("fill=\"#223344\""), true)
  @test.assert_eq(svg.contains("stroke=\"#334455\""), true)
  @test.assert_eq(svg.contains("fill=\"#112233\""), true)
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
test "fixture transitions retain drawable paths and official decorations" {
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
  let svg = diagram.render_svg()
  let drawable_path_count = layout.edges.fold(init=0, fn(count, edge) {
    count + edge.paths.filter(path => path.length() > 1).length()
  })
  @test.assert_eq(
    svg.split("class=\"state-transition\"").count(),
    drawable_path_count + 1,
  )
  @test.assert_eq(
    svg.split("marker-end=\"url(#state-arrow)\"").count(),
    drawable_path_count + 1,
  )
  let cross_count = diagram.transitions
    .filter(transition => transition.has_cross_start)
    .length()
  @test.assert_eq(
    svg.split("marker-start=\"url(#state-cross-start)\"").count(),
    cross_count + 1,
  )
  for transition in diagram.transitions {
    for attribute in @svg.line_style_attributes(transition.line_style) {
      @test.assert_eq(
        svg.contains(attribute.0 + "=\"" + attribute.1 + "\""),
        true,
      )
    }
  }
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
test "canvas and note styles preserve role and inline color precedence" {
  let svg = render_state_svg(
    "@startuml\nskinparam BackgroundColor #010203\nskinparam NoteBackgroundColor #112233\nskinparam NoteBorderColor #223344\nskinparam NoteFontName Courier New\nskinparam NoteFontSize 16\nskinparam NoteFontColor #334455\nA --> B\nnote right of A #lightyellow\ninline note\nend note\nnote on link : styled note\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"state-canvas\""), true)
  @test.assert_eq(svg.contains("fill=\"#010203\""), true)
  @test.assert_eq(svg.contains("fill=\"#FFFFE0\""), true)
  @test.assert_eq(svg.contains("fill=\"#112233\""), true)
  @test.assert_eq(svg.contains("stroke=\"#223344\""), true)
  @test.assert_eq(
    svg.contains(
      ".state-note-label{font-family:Courier New;font-size:16px;fill:#334455}",
    ),
    true,
  )
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
