///|
test "activity renderer emits semantic nodes and connectors" {
  let svg = parse(
    "start\n:Work;\nif (ready?) then (yes)\n:Continue;\nendif\nstop",
  ).render_svg()
  @test.assert_eq(svg.contains("aria-label=\"Activity diagram\""), true)
  @test.assert_eq(svg.contains("activity-action"), true)
  @test.assert_eq(svg.contains("activity-decision"), true)
  @test.assert_eq(svg.contains("activity-edge"), true)
}

///|
test "activity layout connects each adjacent visible instruction" {
  let layout = parse("start\n:Work;\nstop").layout()
  @test.assert_eq(layout.nodes.is_empty(), false)
  @test.assert_eq(layout.edges.is_empty(), false)
}
