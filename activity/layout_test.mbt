///|
fn position_of(layout : ActivityLayout, node_index : Int) -> (Int, Int)? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some((node.x, node.y))
  }
  None
}

///|
test "conditional branches are horizontal siblings and join at endif" {
  let layout = parse(
    "if (ready?) then (yes)\n:Accept;\nelse (no)\n:Reject;\nendif\n:Continue;",
  ).layout()
  guard position_of(layout, 1) is Some((left_x, left_y)) else {
    @test.fail("missing accepted branch")
  }
  guard position_of(layout, 3) is Some((right_x, right_y)) else {
    @test.fail("missing rejected branch")
  }
  @test.assert_eq(left_y, right_y)
  @test.assert_eq(left_x == right_x, false)
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == 1 && edge.to_node_index == 4
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == 3 && edge.to_node_index == 4
    }),
    true,
  )
}

///|
test "parallel branches are horizontal and converge at the ending fork" {
  let layout = parse("fork\n:Build;\nfork again\n:Test;\nend fork\n:Ship;").layout()
  guard position_of(layout, 1) is Some((build_x, build_y)) else {
    @test.fail("missing build branch")
  }
  guard position_of(layout, 3) is Some((test_x, test_y)) else {
    @test.fail("missing test branch")
  }
  @test.assert_eq(build_y, test_y)
  @test.assert_eq(build_x == test_x, false)
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == 1 && edge.to_node_index == 4
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == 3 && edge.to_node_index == 4
    }),
    true,
  )
}

///|
test "loops include a routed back edge" {
  let layout = parse("while (more?)\n:Read;\nendwhile (done)\n:Finish;").layout()
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.route is BackwardLeft || edge.route is BackwardRight
    }),
    true,
  )
}

///|
test "goto creates a backward edge to the instruction after its label" {
  let layout = parse(
    "label retry\n:Retry;\nif (again?) then (yes)\ngoto retry\nendif",
  ).layout()
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == 2 &&
      edge.to_node_index == 1 &&
      edge.route is BackwardLeft
    }),
    true,
  )
}
