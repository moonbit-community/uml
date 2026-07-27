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
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"package\""), true)
  @test.assert_eq(svg.contains("class=\"class-note\""), true)
  @test.assert_eq(svg.contains(">owner</text>"), true)
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
