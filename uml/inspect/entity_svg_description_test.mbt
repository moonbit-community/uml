///|
/// Core properties of the description-symbol rendering, exercised through
/// the public parse/render boundary: every deployment kind paints its own
/// node group, symbol packages paint their container, and the cloud outline
/// is deterministic. These tests assert structural properties, never
/// absolute layout values.

///|
fn render_description(source : String) -> String raise {
  let diagram = @parser.parse_entity(source, family=@entity.DeploymentDiagram)
  @render.render_entity_svg(diagram)
}

///|
/// Every description-family kind paints a `description-node` group instead
/// of falling back to a class image.
test "every description kind paints its own node" {
  let kinds = [
    "node n1", "frame f1", "cloud c1", "storage s1", "database d1", "queue q1", "stack st1",
    "agent a1", "artifact ar1", "folder fo1", "card ca1", "file fi1", "rectangle r1",
    "hexagon h1", "label l1", "action ac1", "process p1", "boundary b1", "control co1",
    "collections col1", "person pe1", "circle ci1",
  ]
  let source = "@startuml\n" + kinds.join("\n") + "\n@enduml"
  let svg = render_description(source)
  @test.assert_eq(svg.length() > 0, true)
  for declaration in kinds {
    let code = declaration.split(" ").nth(1).unwrap()
    @test.assert_eq(
      @tokenizer.find_unquoted_literal(svg, "data-code=\"\{code}\"") is Some(_),
      true,
    )
    @test.assert_eq(
      @tokenizer.find_unquoted_literal(
        svg,
        "class=\"description-node\" data-code=\"\{code}\"",
      )
      is Some(_),
      true,
    )
  }
}

///|
/// The hexagon paints its six-vertex outline, the interface its fixed
/// circle figure, and a symbol package (`node N {`) its machine polygon:
/// shape selection survives the render boundary.
test "symbols paint their defining shapes" {
  let svg = render_description(
    "@startuml\nhexagon h1\n() api\nnode box {\nport p1\nnode inner\n}\n@enduml",
  )
  @test.assert_eq(
    @tokenizer.find_unquoted_literal(svg, "<polygon") is Some(_),
    true,
  )
  @test.assert_eq(
    @tokenizer.find_unquoted_literal(svg, "<ellipse") is Some(_),
    true,
  )
  @test.assert_eq(
    @tokenizer.find_unquoted_literal(svg, "class=\"symbol-package\"") is Some(_),
    true,
  )
  @test.assert_eq(
    @tokenizer.find_unquoted_literal(svg, "class=\"port-node\"") is Some(_),
    true,
  )
}

///|
/// The description nodes and their labels appear only after the deployment
/// family's entity-first paint order: the painter emits node groups before
/// any relation path.
test "entities are painted before relations" {
  let svg = render_description("@startuml\nnode a\nnode b\na --> b\n@enduml")
  let entity_at = @tokenizer.find_unquoted_literal(
    svg, "class=\"description-node\"",
  )
  let relation_at = @tokenizer.find_unquoted_literal(svg, "class=\"relation\"")
  match (entity_at, relation_at) {
    (Some(first), Some(second)) => @test.assert_eq(first < second, true)
    _ => @test.fail("expected both entities and relations")
  }
}

///|
/// Rendering is deterministic: the same source reproduces the identical
/// outline, including the seeded cloud frontier.
test "cloud outline is deterministic across renders" {
  let source = "@startuml\ncloud c1\n@enduml"
  @test.assert_eq(render_description(source), render_description(source))
}
