///|
fn node_named(diagram : WbsDiagram, label : String) -> WbsNode {
  for node in diagram.nodes {
    if node.label == label {
      return node
    }
  }
  abort("missing WBS node in test")
}

///|
fn parent_label(diagram : WbsDiagram, node : WbsNode) -> String? {
  node.parent.map(index => diagram.nodes[index].label)
}

///|
fn first_link(diagram : WbsDiagram) -> WbsLink {
  match diagram.links {
    [link, ..] => link
    _ => abort("missing WBS link in test")
  }
}

///|
fn style_property_named(
  diagram : WbsDiagram,
  name : String,
) -> WbsStyleProperty {
  for property in diagram.style_properties {
    if property.name == name {
      return property
    }
  }
  abort("missing WBS style property in test")
}

///|
test "builds WBS hierarchy from smart marker levels" {
  let diagram = parse(
    "@startwbs\n* Root\n** First\n*** Leaf\n** Second\n@endwbs",
  )
  let root = node_named(diagram, "Root")
  let first = node_named(diagram, "First")
  let leaf = node_named(diagram, "Leaf")
  let second = node_named(diagram, "Second")
  @test.assert_eq(parent_label(diagram, root), None)
  @test.assert_eq(parent_label(diagram, first), Some("Root"))
  @test.assert_eq(parent_label(diagram, leaf), Some("First"))
  @test.assert_eq(parent_label(diagram, second), Some("Root"))
}

///|
test "uses marker and explicit directions independently" {
  let diagram = parse("@startwbs\n* Root\n**> Right\n--< Left\n@endwbs")
  @test.assert_eq(node_named(diagram, "Right").direction, Right)
  @test.assert_eq(node_named(diagram, "Left").direction, Left)
  @test.assert_eq(
    parent_label(diagram, node_named(diagram, "Left")),
    Some("Root"),
  )
}

///|
test "parses modern and legacy node modifiers" {
  let diagram = parse(
    "@startwbs\n* Root\n**_>[#abc](right) Boxless <<tag>>\n**>_(direction_first) Direction first\n**[#def](left)_> Legacy\n@endwbs",
  )
  let modern = node_named(diagram, "Boxless")
  let direction_first = node_named(diagram, "Direction first")
  let legacy = node_named(diagram, "Legacy")
  @test.assert_eq(modern.shape, Boxless)
  @test.assert_eq(modern.background_color, Some("#abc"))
  @test.assert_eq(modern.code, Some("right"))
  @test.assert_eq(modern.stereotype, Some("<<tag>>"))
  @test.assert_eq(direction_first.shape, Boxless)
  @test.assert_eq(direction_first.direction, Right)
  @test.assert_eq(legacy.shape, Boxless)
  @test.assert_eq(legacy.background_color, Some("#def"))
  @test.assert_eq(legacy.code, Some("left"))
}

///|
test "supports quoted aliases, pseudo nodes, and multiline labels" {
  let diagram = parse(
    "@startwbs\n* Root\n** \"Alpha\" as alpha\n**_(group)\n***: first line\nsecond line; <<note>>\n@endwbs",
  )
  let alpha = node_named(diagram, "Alpha")
  let pseudo = node_named(diagram, "")
  let multiline = node_named(diagram, "first line\nsecond line")
  @test.assert_eq(alpha.code, Some("alpha"))
  @test.assert_eq(pseudo.shape, Pseudo)
  @test.assert_eq(pseudo.code, Some("group"))
  @test.assert_eq(multiline.stereotype, Some("<<note>>"))
  @test.assert_eq(parent_label(diagram, multiline), Some(""))
}

///|
test "completes a multiline root before parsing its descendants" {
  let diagram = parse(
    "@startwbs\n*: root line\nroot continuation;\n** Child\n@endwbs",
  )
  let root = node_named(diagram, "root line\nroot continuation")
  @test.assert_eq(
    parent_label(diagram, node_named(diagram, "Child")),
    Some(root.label),
  )
}

///|
test "joins PlantUML line continuations before parsing node labels" {
  let diagram = parse(
    (
      #|@startwbs
      #|* Root \
      #| [[https://example.com Link]]
      #|@endwbs
    ),
  )
  let root = node_named(diagram, "Root [[https://example.com Link]]")
  @test.assert_eq(root.parent, None)
}

///|
test "resolves links after coded nodes and preserves link metadata" {
  let diagram = parse(
    "@startwbs\n* Root\n** \"Alpha\" as alpha\n** \"Beta\" as beta\nalpha .> beta #red <<critical>> : ignored\n@endwbs",
  )
  let link = first_link(diagram)
  @test.assert_eq(
    diagram.links.any(candidate => {
      candidate.source == link.source && candidate.target == link.target
    }),
    true,
  )
  @test.assert_eq(diagram.nodes[link.source].label, "Alpha")
  @test.assert_eq(diagram.nodes[link.target].label, "Beta")
  @test.assert_eq(link.color, Some("#red"))
  @test.assert_eq(link.stereotype, Some("<<critical>>"))
  @test.assert_eq(link.label, Some("ignored"))
}

///|
test "retains document and nested WBS style properties" {
  let diagram = parse(
    "@startwbs\nskinparam BackgroundColor #eeeeee\n<style>\nwbsDiagram {\n  node {\n    width auto\n  }\n}\n</style>\n* Root\n@endwbs",
  )
  @test.assert_eq(diagram.style.canvas_color(), "#eeeeee")
  let property = style_property_named(diagram, "width")
  @test.assert_eq(property.selector, "wbsDiagram node")
  @test.assert_eq(property.name, "width")
  @test.assert_eq(property.value, "auto")
}

///|
test "accepts common title and legend blocks" {
  let diagram = parse(
    "@startwbs\ntitle\nWork plan\nend title\nlegend left\nLegend text\nendlegend\n* Root\n@endwbs",
  )
  @test.assert_eq(diagram.style.title, Some("Work plan"))
  @test.assert_eq(diagram.style.legend, Some("Legend text"))
}

///|
test "rejects invalid tree structure and unresolved links" {
  @test.assert_raise(() => ignore(parse("@startwbs\n* Root\n*** Gap\n@endwbs")))
  @test.assert_raise(() => ignore(parse("@startwbs\n* Root\n* Second\n@endwbs")))
  @test.assert_raise(() => {
    ignore(parse("@startwbs\n* Root\nmissing -> node\n@endwbs"))
  })
  @test.assert_raise(() => {
    ignore(
      parse("@startwbs\n* \"Root\" as root\n** Child\nroot -> child\n@endwbs"),
    )
  })
  @test.assert_raise(() => ignore(parse("@startwbs\n*\n@endwbs")))
}
