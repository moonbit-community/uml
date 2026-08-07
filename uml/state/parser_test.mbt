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
test "state auxiliary labels share their SVG font-size token" {
  let svg = render_state_svg(
    "@startuml\nstate Ready\n[*] --> Ready : begin\nnote right of Ready\ndetail\nend note\n@enduml",
  )
  let font_size = "font-size:" + @svg.auxiliary_label_font_size()
  @test.assert_eq(svg.contains(".state-pseudostate-label{font-family:"), true)
  @test.assert_eq(svg.contains(".state-transition-label{font-family:"), true)
  @test.assert_eq(svg.contains(".state-note-label{font-family:"), true)
  @test.assert_eq(svg.contains(font_size), true)
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
  @test.assert_eq(svg.contains("fill=\"theme-canvas\""), false)
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
