///|
fn position_of(layout : ActivityLayout, node_index : Int) -> (Int, Int)? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some((node.x, node.y))
  }
  None
}

///|
fn action_index(layout : ActivityLayout, label : String) -> Int? {
  for index, node in layout.source_nodes {
    guard node is ActivityNode::Action(candidate) && candidate == label else {
      continue
    }
    return Some(index)
  }
  None
}

///|
fn anchor_index(
  layout : ActivityLayout,
  name : String,
  is_label : Bool,
) -> Int? {
  for index, node in layout.source_nodes {
    guard (
        is_label && node is ActivityNode::Label(candidate) && candidate == name
      ) ||
      (!is_label && node is ActivityNode::Goto(candidate) && candidate == name) else {
      continue
    }
    return Some(index)
  }
  None
}

///|
fn control_index(layout : ActivityLayout, condition : String) -> Int? {
  for index, node in layout.source_nodes {
    guard (node is ActivityNode::While(value) && value == condition) ||
      (node is ActivityNode::RepeatWhile(value) && value == condition) else {
      continue
    }
    return Some(index)
  }
  None
}

///|
fn region_for(
  layout : ActivityLayout,
  kind : ActivityRegionKind,
  label : String,
) -> ActivityRegionLayout? {
  for region in layout.regions {
    guard region.kind == kind && region.label == label else { continue }
    return Some(region)
  }
  None
}

///|
test "conditional branches are horizontal siblings and join at endif" {
  let layout = parse(
    "if (ready?) then (yes)\n:Accept;\nelse (no)\n:Reject;\nendif\n:Continue;",
  ).layout()
  guard action_index(layout, "Accept") is Some(accept_index) else {
    @test.fail("missing accepted branch index")
  }
  guard action_index(layout, "Reject") is Some(reject_index) else {
    @test.fail("missing rejected branch index")
  }
  guard action_index(layout, "Continue") is Some(continue_index) else {
    @test.fail("missing continuation index")
  }
  guard position_of(layout, accept_index) is Some((left_x, left_y)) else {
    @test.fail("missing accepted branch")
  }
  guard position_of(layout, reject_index) is Some((right_x, right_y)) else {
    @test.fail("missing rejected branch")
  }
  @test.assert_eq(left_y, right_y)
  @test.assert_eq(left_x == right_x, false)
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == accept_index &&
      edge.to_node_index < continue_index
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == reject_index &&
      edge.to_node_index < continue_index
    }),
    true,
  )
}

///|
test "parallel branches are horizontal and converge at the ending fork" {
  let layout = parse("fork\n:Build;\nfork again\n:Test;\nend fork\n:Ship;").layout()
  guard action_index(layout, "Build") is Some(build_index) else {
    @test.fail("missing build branch index")
  }
  guard action_index(layout, "Test") is Some(test_index) else {
    @test.fail("missing test branch index")
  }
  guard action_index(layout, "Ship") is Some(ship_index) else {
    @test.fail("missing ship index")
  }
  guard position_of(layout, build_index) is Some((build_x, build_y)) else {
    @test.fail("missing build branch")
  }
  guard position_of(layout, test_index) is Some((test_x, test_y)) else {
    @test.fail("missing test branch")
  }
  @test.assert_eq(build_y, test_y)
  @test.assert_eq(build_x == test_x, false)
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == build_index && edge.to_node_index < ship_index
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == test_index && edge.to_node_index < ship_index
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
test "loop labels remain attached to control-flow edges" {
  let layout = parse(
    "while (more?) is (yes)\n:Read;\nendwhile (done)\nrepeat\n:Retry;\nrepeat while (failed?) is (again) not (sent)\n:Finish;",
  ).layout()
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("yes")), true)
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("done")), true)
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("again")), true)
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("sent")), true)
}

///|
test "while exits from its controlling decision rather than its loop body" {
  let layout = parse(
    "while (more?) is (yes)\n:Read;\nendwhile (done)\n:Finish;",
  ).layout()
  guard control_index(layout, "more?") is Some(while_decision) else {
    @test.fail("missing while decision")
  }
  guard action_index(layout, "Finish") is Some(finish) else {
    @test.fail("missing instruction after loop")
  }
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == while_decision &&
      edge.to_node_index == finish &&
      edge.label == Some("done") &&
      edge.route is ActivityEdgeRoute::BackwardLeft
    }),
    true,
  )
}

///|
test "conditional and switch labels belong to incoming branch edges" {
  let conditional = parse(
    "if (ready?) then (accept)\n:Accept;\nelse (reject)\n:Reject;\nendif",
  ).layout()
  let switch_layout = parse(
    "switch (method)\ncase (email)\n:Email;\ncase (sms)\n:Sms;\nendswitch",
  ).layout()
  @test.assert_eq(
    conditional.edges.any(edge => edge.label == Some("accept")),
    true,
  )
  @test.assert_eq(
    conditional.edges.any(edge => edge.label == Some("reject")),
    true,
  )
  @test.assert_eq(
    switch_layout.edges.any(edge => edge.label == Some("email")),
    true,
  )
  @test.assert_eq(
    switch_layout.edges.any(edge => edge.label == Some("sms")),
    true,
  )
}

///|
test "elseif decisions form a horizontal cascade" {
  let layout = parse(
    "if (first?) then (yes)\n:First;\nelseif (second?) then (yes)\n:Second;\nelse (no)\n:Fallback;\nendif",
  ).layout()
  @test.assert_eq(
    layout.edges.any(edge => edge.route is ActivityEdgeRoute::Horizontal),
    true,
  )
}

///|
test "partitions and swimlanes contain their visible instructions" {
  let layout = parse(
    "|Customer|\n:Submit;\n|Store|\npartition Fulfilment {\n:Validate;\n:Reserve;\n}\n|Customer|\n:Confirm;",
  ).layout()
  guard region_for(layout, ActivityRegionKind::Partition, "Fulfilment")
    is Some(partition) else {
    @test.fail("missing partition region")
  }
  @test.assert_eq(
    layout.regions.any(region => {
      region.kind is ActivityRegionKind::Swimlane && region.label == "Customer"
    }),
    true,
  )
  guard action_index(layout, "Submit") is Some(submit_index) else {
    @test.fail("missing customer action")
  }
  guard action_index(layout, "Validate") is Some(validate_index) else {
    @test.fail("missing store action")
  }
  guard position_of(layout, submit_index) is Some((submit_x, _)) else {
    @test.fail("missing customer position")
  }
  guard position_of(layout, validate_index) is Some((validate_x, _)) else {
    @test.fail("missing store position")
  }
  @test.assert_eq(submit_x == validate_x, false)
  guard position_of(layout, validate_index) is Some((validate_x, validate_y)) else {
    @test.fail("missing partitioned action position")
  }
  @test.assert_eq(validate_x >= partition.x, true)
  @test.assert_eq(validate_y >= partition.y, true)
  @test.assert_eq(validate_x < partition.x + partition.width, true)
  @test.assert_eq(validate_y < partition.y + partition.height, true)
}

///|
test "explicit arrow text labels the following visible edge" {
  let layout = parse(":Receive;\n-> validate input\n:Validate;").layout()
  @test.assert_eq(
    layout.edges.any(edge => edge.label == Some("validate input")),
    true,
  )
}

///|
test "goto connects its anchor directly to the matching label anchor" {
  let layout = parse(
    "label retry\n:Retry;\nif (again?) then (yes)\ngoto retry\nendif",
  ).layout()
  guard anchor_index(layout, "retry", true) is Some(label_anchor) else {
    @test.fail("missing label anchor")
  }
  guard anchor_index(layout, "retry", false) is Some(goto_anchor) else {
    @test.fail("missing goto anchor")
  }
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == goto_anchor &&
      edge.to_node_index == label_anchor &&
      edge.route is ActivityEdgeRoute::Goto
    }),
    true,
  )
}
