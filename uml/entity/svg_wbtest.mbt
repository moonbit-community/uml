///|
test "use-case layout uses ellipse and actor geometry before Graphviz" {
  let diagram = parse(
    "@startuml\n:Customer: --> (Place order)\n@enduml",
    family=UseCaseDiagram,
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let actor = diagram.entity("Customer").unwrap()
  let usecase = diagram.entity("Place order").unwrap()
  let actor_geometry = actor.node_geometry(metrics, UseCaseDiagram)
  let usecase_geometry = usecase.node_geometry(metrics, UseCaseDiagram)
  @test.assert_eq(actor_geometry.shape, Box)
  @test.assert_eq(usecase_geometry.shape, Ellipse)
  @test.assert_eq(actor_geometry.height > usecase_geometry.height, true)
  @test.assert_eq(usecase_geometry.width > usecase_geometry.height, true)
}

///|
test "use-case ellipse geometry grows with its text footprint" {
  let compact = text_block_in_ellipse_geometry(20, 10)
  let wide = text_block_in_ellipse_geometry(80, 10)
  let tall = text_block_in_ellipse_geometry(20, 40)
  @test.assert_eq(wide.0 > compact.0, true)
  @test.assert_eq(tall.1 > compact.1, true)
}

///|
test "use-case SVG keeps actor labels below their figure" {
  let svg = parse(
    "@startuml\n:Customer: --> (Place order)\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("class=\"actor-node\""), true)
  @test.assert_eq(svg.contains("class=\"usecase-node\""), true)
  @test.assert_eq(svg.contains("aria-label=\"Use case diagram\""), true)
}

///|
test "dependency links preserve their dot length for Graphviz ranks" {
  let diagram = parse("@startuml\n(Place order) .> (Approve order)\n@enduml")
  let relation = diagram.relations[0]
  @test.assert_eq(relation.dotted, true)
  @test.assert_eq(relation.graphviz_minlen(), 0)
}

///|
test "use-case SVG preserves dotted dependencies and business markers" {
  let svg = parse(
    "@startuml\nactor/ Partner\nusecase/ \"Approve order\" as Approve <<business>>\nPartner --> Approve\nApprove .> (Confirm)\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("stroke-dasharray=\"6 4\""), true)
  @test.assert_eq(svg.contains("class=\"actor-business-mark\""), true)
  @test.assert_eq(svg.contains("class=\"usecase-business-mark\""), true)
  @test.assert_eq(svg.contains("class=\"usecase-stereotype\""), true)
}

///|
test "actor stereotypes participate in use-case node geometry" {
  let plain = parse("@startuml\nactor Customer\n@enduml", family=UseCaseDiagram)
  let stereotyped = parse(
    "@startuml\nactor Customer <<external>>\n@enduml",
    family=UseCaseDiagram,
  )
  let plain_metrics = ClassTextMetrics::new(plain.style)
  let stereotyped_metrics = ClassTextMetrics::new(stereotyped.style)
  let plain_geometry = plain.entities[0].node_geometry(plain_metrics, UseCaseDiagram)
  let stereotyped_geometry = stereotyped.entities[0].node_geometry(
    stereotyped_metrics,
    UseCaseDiagram,
  )
  let svg = stereotyped.render_svg()
  @test.assert_eq(stereotyped_geometry.height > plain_geometry.height, true)
  @test.assert_eq(
    svg.contains(">\{@style.xml_escape("«external»")}</text>"),
    true,
  )
}

///|
test "use-case labels render stereotypes with PlantUML guillemets" {
  let svg = parse(
    "@startuml\nusecase Review <<business>>\nReview .> (Approve) : <<include>>\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("«business»"), true)
  @test.assert_eq(svg.contains("«include»"), true)
}

///|
test "actor styles select matching geometry and SVG symbols" {
  let stickman = parse("@startuml\nactor A\n@enduml", family=UseCaseDiagram)
  let awesome = parse(
    "@startuml\nskinparam actorStyle awesome\nactor A\n@enduml",
    family=UseCaseDiagram,
  )
  let hollow = parse(
    "@startuml\nskinparam actorStyle hollow\nactor A\n@enduml",
    family=UseCaseDiagram,
  )
  let stickman_geometry = stickman.entities[0].node_geometry(
    ClassTextMetrics::new(stickman.style),
    UseCaseDiagram,
  )
  let awesome_geometry = awesome.entities[0].node_geometry(
    ClassTextMetrics::new(awesome.style),
    UseCaseDiagram,
  )
  let hollow_geometry = hollow.entities[0].node_geometry(
    ClassTextMetrics::new(hollow.style),
    UseCaseDiagram,
  )
  @test.assert_eq(awesome.style.actor_style(), "awesome")
  @test.assert_eq(awesome_geometry.width > stickman_geometry.width, true)
  @test.assert_eq(hollow_geometry.height < stickman_geometry.height, true)
  @test.assert_eq(
    awesome.render_svg().contains("class=\"actor-awesome-body\""),
    true,
  )
  @test.assert_eq(
    hollow.render_svg().contains("class=\"actor-hollow-body\""),
    true,
  )
}

///|
test "mixed use-case components use component geometry and symbols" {
  let diagram = parse(
    "@startuml\nallowmixing\nusecase Pay\ncomponent Provider\nPay --> Provider\n@enduml",
    family=UseCaseDiagram,
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let component = diagram.entity("Provider").unwrap()
  let geometry = component.node_geometry(metrics, UseCaseDiagram)
  let svg = diagram.render_svg()
  @test.assert_eq(component.kind, Component)
  @test.assert_eq(geometry.width > component.width(metrics), true)
  @test.assert_eq(svg.contains("class=\"component-node\""), true)
  @test.assert_eq(svg.contains("class=\"component-tab\""), true)
}

///|
test "use-case packages render PlantUML-style bold titles" {
  let svg = parse(
    "@startuml\npackage System {\n  actor User\n  usecase Run\n  User --> Run\n}\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(
    svg.contains(".package-title{fill:#000000;font-weight:bold}"),
    true,
  )
}

///|
test "use-case package layout preserves PlantUML sibling ordering" {
  let diagram = parse(
    (
      #|@startuml
      #|left to right direction
      #|package Fulfillment {
      #|  :Customer:
      #|  (Place order)
      #|  (Track delivery)
      #|  :Customer: --> (Place order)
      #|  :Customer: --> (Track delivery)
      #|}
      #|@enduml
    ),
    family=UseCaseDiagram,
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let mut place_y : Double? = None
  let mut track_y : Double? = None
  for node in layout.nodes {
    if node.code == "Fulfillment.Place order" {
      place_y = Some(node.y)
    } else if node.code == "Fulfillment.Track delivery" {
      track_y = Some(node.y)
    }
  }
  @test.assert_eq(track_y.unwrap() < place_y.unwrap(), true)
}

///|
test "use-case relation labels use PlantUML label typography" {
  let svg = parse(
    "@startuml\nusecase Start\nusecase Finish\nStart .> Finish : <<include>>\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(
    svg.contains(".relation-label{text-anchor:middle;font-size:13px}"),
    true,
  )
}

///|
test "use-case relation labels use ArrowFont skinparams" {
  let svg = parse(
    "@startuml\nskinparam ArrowFontColor #456789\nskinparam ArrowFontSize 16\nskinparam ArrowFontName Courier\nusecase Start\nStart .> (Finish) : <<include>>\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("fill=\"#456789\""), true)
  @test.assert_eq(svg.contains("font-family=\"Courier\""), true)
  @test.assert_eq(svg.contains("font-size=\"16\""), true)
}

///|
test "use-case notes use their measured PlantUML font size" {
  let svg = parse(
    "@startuml\nusecase Review\nnote right of Review\n  Review details\nend note\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains(".note-text{fill:#000000;font-size:13px}"), true)
}

///|
test "entity notes use an Opale pointer toward their target" {
  let svg = parse(
    "@startuml\nusecase Review\nnote right of Review\n  Review details\nend note\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("class=\"note-opale-link\""), true)
}

///|
test "use-case canvas includes notes positioned outside the Graphviz box" {
  let diagram = parse(
    "@startuml\nusecase Review\nnote right of Review\n  Review details\nend note\n@enduml",
    family=UseCaseDiagram,
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let graphviz = diagram.graphviz_layout(metrics)
  let layout = {
    columns: 1,
    cell_width: 1,
    cell_height: 1,
    width: 1,
    graphviz: Some(graphviz),
  }
  let note = graphviz.notes[0]
  let bounds = layout.content_bounds(diagram, metrics)
  @test.assert_eq(
    bounds.max_x >= note.x + note.width / 2.0,
    true,
  )
  @test.assert_eq(
    bounds.min_x <= note.x - note.width / 2.0,
    true,
  )
}

///|
test "use-case SVG preserves entity URLs" {
  let svg = parse(
    "@startuml\nusecase \"Submit request\" as Submit [[https://example.com/submit]]\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("href=\"https://example.com/submit\""), true)
}

///|
test "use-case SVG uses actor and usecase skinparam colors" {
  let svg = parse(
    "@startuml\nskinparam UsecaseBackgroundColor #456789\nskinparam ActorBorderColor #987654\nactor Customer\nusecase PlaceOrder\nCustomer --> PlaceOrder\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("fill=\"#456789\""), true)
  @test.assert_eq(svg.contains("stroke=\"#987654\""), true)
}

///|
test "use-case SVG uses actor and usecase font skinparams" {
  let svg = parse(
    "@startuml\nskinparam UsecaseFontColor #456789\nskinparam ActorFontColor #987654\nactor Customer\nusecase PlaceOrder\nCustomer --> PlaceOrder\n@enduml",
    family=UseCaseDiagram,
  ).render_svg()
  @test.assert_eq(svg.contains("fill=\"#456789\""), true)
  @test.assert_eq(svg.contains("fill=\"#987654\""), true)
}

///|
test "use-case font sizes affect matching node geometry and SVG text" {
  let regular = parse(
    "@startuml\nactor Customer\nusecase Review\n@enduml",
    family=UseCaseDiagram,
  )
  let styled = parse(
    "@startuml\nskinparam ActorFontSize 18\nskinparam UsecaseFontSize 18\nactor Customer\nusecase Review\n@enduml",
    family=UseCaseDiagram,
  )
  let regular_metrics = ClassTextMetrics::new(regular.style)
  let styled_metrics = ClassTextMetrics::new(styled.style)
  let regular_actor = regular.entities[0].node_geometry(regular_metrics, UseCaseDiagram)
  let styled_actor = styled.entities[0].node_geometry(styled_metrics, UseCaseDiagram)
  let regular_usecase = regular.entities[1].node_geometry(
    regular_metrics,
    UseCaseDiagram,
  )
  let styled_usecase = styled.entities[1].node_geometry(
    styled_metrics,
    UseCaseDiagram,
  )
  let svg = styled.render_svg()
  @test.assert_eq(styled_actor.width > regular_actor.width, true)
  @test.assert_eq(styled_usecase.height > regular_usecase.height, true)
  @test.assert_eq(svg.contains("font-size=\"18\""), true)
}

///|
test "use-case font families use matching metrics profiles and SVG text" {
  let diagram = parse(
    "@startuml\nskinparam ActorFontName Courier\nskinparam UsecaseFontName Times New Roman\nactor Customer\nusecase Review\n@enduml",
    family=UseCaseDiagram,
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let svg = diagram.render_svg()
  @test.assert_eq(metrics.actor_regular.profile, Monospace)
  @test.assert_eq(metrics.usecase_regular.profile, Serif)
  @test.assert_eq(svg.contains("font-family=\"Courier\""), true)
  @test.assert_eq(svg.contains("font-family=\"Times New Roman\""), true)
}

///|
test "class layout receives document font profile size and title style" {
  let source = "@startuml\nclass VeryLongClassDisplayName\n@enduml"
  let regular = parse(source)
  let styled = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nclass VeryLongClassDisplayName\n@enduml",
  )
  let regular_metrics = ClassTextMetrics::new(regular.style)
  let styled_metrics = ClassTextMetrics::new(styled.style)
  @test.assert_eq(styled_metrics.regular.profile, Monospace)
  @test.assert_eq(styled_metrics.regular.font_size, 16)
  @test.assert_eq(styled_metrics.italic.style, Italic)
  @test.assert_eq(
    styled.entities[0].width(styled_metrics) >
    regular.entities[0].width(regular_metrics),
    true,
  )
  let layout = styled.layout(styled_metrics)
  @test.assert_eq(
    layout.width >=
    layout.node_x(0) + styled.entities[0].width(styled_metrics) + 24,
    true,
  )
}

///|
test "class body keeps empty field and method sections" {
  let empty = parse("@startuml\ninterface Empty\n@enduml")
  let with_field = parse("@startuml\ninterface Empty {\n+ id : Int\n}\n@enduml")
  let with_method = parse("@startuml\ninterface Empty {\n+ run()\n}\n@enduml")
  let metrics = ClassTextMetrics::new(empty.style)
  let empty_entity = empty.entities[0]
  let empty_body = empty_entity.body_layout(metrics)
  @test.assert_eq(empty_body.fields.length(), 0)
  @test.assert_eq(empty_body.methods.length(), 0)
  @test.assert_eq(empty_body.fields_height > 0, true)
  @test.assert_eq(empty_body.methods_height > 0, true)
  @test.assert_eq(
    with_field.entities[0].height(metrics) > empty_entity.height(metrics),
    true,
  )
  @test.assert_eq(
    with_method.entities[0].height(metrics) > empty_entity.height(metrics),
    true,
  )
}

///|
test "class SVG draws field and method partitions from the layout model" {
  let diagram = parse(
    "@startuml\nclass User {\n+ id : Int\n+ login()\n}\n@enduml",
  )
  let entity = diagram.entities[0]
  let metrics = ClassTextMetrics::new(diagram.style)
  let body = entity.body_layout(metrics)
  let svg = diagram.render_svg()
  @test.assert_eq(body.fields.length(), 1)
  @test.assert_eq(body.methods.length(), 1)
  @test.assert_eq(svg.split("<line ").count() >= 2, true)
  @test.assert_eq(svg.contains("class=\"member-icon\""), true)
  @test.assert_eq(svg.contains(">id : Int</text>"), true)
  @test.assert_eq(svg.contains(">login()</text>"), true)
  @test.assert_eq(svg.contains(">+ id : Int</text>"), false)
}

///|
test "class SVG uses PlantUML spots, visibility icons, and package tabs" {
  let diagram = parse(
    "@startuml\npackage domain {\nabstract class Abstract\nclass Concrete {\n+ visible\n- hidden\n+ run()\n}\ninterface Contract\n}\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"class-spot\">A</text>"), true)
  @test.assert_eq(svg.contains("class=\"class-spot\">C</text>"), true)
  @test.assert_eq(svg.contains("class=\"class-spot\">I</text>"), true)
  @test.assert_eq(svg.contains("class=\"member-icon\""), true)
  @test.assert_eq(svg.contains("fill=\"#84BE84\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\" style="), false)
  @test.assert_eq(svg.contains("class=\"package-title\">domain</text>"), true)
  @test.assert_eq(svg.contains("<path d=\"M "), true)
  @test.assert_eq(svg.contains("style=\"stroke:#181818\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\"><rect"), false)
}

///|
test "class SVG consumes colors resolved by document style" {
  let default_svg = parse("@startuml\nclass User\n@enduml").render_svg()
  let styled_svg = parse(
    "@startuml\nskinparam ClassBackgroundColor #123456\nskinparam ClassBorderColor #654321\nclass User\n@enduml",
  ).render_svg()
  @test.assert_eq(default_svg.contains("fill=\"#F1F1F1\""), true)
  @test.assert_eq(styled_svg.contains("fill=\"#123456\""), true)
  @test.assert_eq(styled_svg.contains("stroke:#654321"), true)
}

///|
test "graphviz receives dimensions from each class header and body" {
  let diagram = parse(
    "@startuml\nclass Short\nclass VeryLongClassDisplayName {\n+ attribute : Int\n+ operation()\n}\nShort --> VeryLongClassDisplayName\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let nodes : Map[String, GraphvizNodeLayout] = Map([])
  for node in layout.nodes {
    nodes[node.code] = node
  }
  let short = nodes.get("Short").unwrap()
  let long = nodes.get("VeryLongClassDisplayName").unwrap()
  @test.assert_eq(long.width > short.width, true)
  @test.assert_eq(long.height > short.height, true)
}

///|
test "graphviz layout emits semantic node and spline geometry" {
  let diagram = parse(
    "@startuml\nclass Parent\nclass Child\nParent <|-- Child : inherits\n@enduml",
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let layout = diagram.graphviz_layout(metrics)
  @test.assert_eq(layout.nodes.length(), 2)
  @test.assert_eq(layout.edges.length(), 1)
  @test.assert_eq(layout.edges[0].paths.length() > 0, true)
  @test.assert_eq(layout.edges[0].label is Some(_), true)
  @test.assert_eq(layout.width > 0.0 && layout.height > 0.0, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("<path d=\"M "), true)
  @test.assert_eq(svg.contains(" C "), true)
}

///|
test "graphviz layout includes package clusters and notes" {
  let diagram = parse(
    "@startuml\npackage Domain {\nclass User\nclass Account\nUser --> Account\nnote right of User : owner\nnote on link : association\n}\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  @test.assert_eq(layout.packages.length(), 1)
  @test.assert_eq(layout.notes.length(), 2)
  @test.assert_eq(layout.packages[0].width > 0.0, true)
  @test.assert_eq(layout.notes[0].width > 0.0, true)
  @test.assert_eq(layout.notes[1].y > layout.edges[0].label.unwrap().1, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"package\""), true)
  @test.assert_eq(svg.contains("class=\"class-note\""), true)
  @test.assert_eq(svg.contains(">owner</text>"), true)
}

///|
test "graphviz layout anchors an entity note beside its target" {
  let diagram = parse(
    "@startuml\nclass Identity\nclass Store\nIdentity --> Store\nnote right of Identity : validates\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let mut identity_x = None
  for node in layout.nodes {
    if node.code == "Identity" {
      identity_x = Some(node.x)
    }
  }
  @test.assert_eq(layout.notes[0].x > identity_x.unwrap(), true)
}

///|
test "graphviz layout follows PlantUML inheritance ordering without fake labels" {
  let diagram = parse(
    (
      #|@startuml
      #|package domain {
      #|  abstract class "Account Holder" as Account
      #|  interface Auditable
      #|  class Customer extends Account
      #|  Customer ..|> Auditable
      #|}
      #|@enduml
    ),
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let nodes : Map[String, GraphvizNodeLayout] = Map([])
  for node in layout.nodes {
    nodes[node.code] = node
  }
  let account = nodes.get("domain.Account").unwrap()
  let customer = nodes.get("domain.Customer").unwrap()
  let auditable = nodes.get("domain.Auditable").unwrap()
  @test.assert_eq(
    account.y + account.height / 2.0 < customer.y - customer.height / 2.0 &&
    customer.y + customer.height / 2.0 < auditable.y - auditable.height / 2.0,
    true,
  )
  @test.assert_eq(layout.edges.length(), diagram.relations.length())
  for edge in layout.edges {
    @test.assert_eq(edge.label, None)
  }
}

///|
test "routed relations preserve endpoint decorations and cardinalities" {
  let diagram = parse(
    "@startuml\nOrder \"1\" *-- \"many\" Item : contains\nClient --[dashed]--> Service\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("url(#diamond)"), true)
  @test.assert_eq(svg.contains("marker path,marker circle,marker rect"), true)
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), false)
  @test.assert_eq(svg.contains(">1</text>"), true)
  @test.assert_eq(svg.contains(">many</text>"), true)
  @test.assert_eq(svg.contains("stroke-dasharray:6 4"), true)
}

///|
test "hollow inheritance arrows retain a visible outline" {
  let svg = parse("@startuml\nParent <|-- Child\n@enduml").render_svg()
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), true)
  @test.assert_eq(svg.contains("fill=\"white\""), true)
  @test.assert_eq(svg.contains("marker path,marker circle,marker rect"), true)
}

