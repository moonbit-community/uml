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
    guard node is @flow.ActivityNode::Action(candidate) && candidate == label else {
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
        is_label &&
        node is @flow.ActivityNode::Label(candidate) &&
        candidate == name
      ) ||
      (
        !is_label &&
        node is @flow.ActivityNode::Goto(candidate) &&
        candidate == name
      ) else {
      continue
    }
    return Some(index)
  }
  None
}

///|
fn control_index(layout : ActivityLayout, condition : String) -> Int? {
  for index, node in layout.source_nodes {
    guard (node is @flow.ActivityNode::While(value) && value == condition) ||
      (node is @flow.ActivityNode::RepeatWhile(value) && value == condition) ||
      (node is @flow.ActivityNode::If(value) && value == condition) else {
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
  let layout = layout_activity(
    @parser.parse_activity(
      "if (ready?) then (yes)\n:Accept;\nelse (no)\n:Reject;\nendif\n:Continue;",
    ),
  )
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
  let layout = layout_activity(
    @parser.parse_activity(
      "fork\n:Build;\nfork again\n:Test;\nend fork\n:Ship;",
    ),
  )
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
  let layout = layout_activity(
    @parser.parse_activity("while (more?)\n:Read;\nendwhile (done)\n:Finish;"),
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.route is BackwardLeft || edge.route is BackwardRight
    }),
    true,
  )
}

///|
test "loop labels remain attached to control-flow edges" {
  let layout = layout_activity(
    @parser.parse_activity(
      "while (more?) is (yes)\n:Read;\nendwhile (done)\nrepeat\n:Retry;\nrepeat while (failed?) is (again) not (sent)\n:Finish;",
    ),
  )
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("yes")), true)
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("done")), true)
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("again")), true)
  @test.assert_eq(layout.edges.any(edge => edge.label == Some("sent")), true)
}

///|
test "while exits from its controlling decision rather than its loop body" {
  let layout = layout_activity(
    @parser.parse_activity(
      "while (more?) is (yes)\n:Read;\nendwhile (done)\n:Finish;",
    ),
  )
  guard control_index(layout, "more?") is Some(while_decision) else {
    @test.fail("missing while decision")
  }
  guard action_index(layout, "Finish") is Some(finish) else {
    @test.fail("missing instruction after loop")
  }
  guard position_of(layout, while_decision) is Some((_, decision_y)) else {
    @test.fail("missing while decision layout")
  }
  @test.assert_eq(
    layout.nodes.any(node => {
      node.node_index != while_decision &&
      node.y > decision_y &&
      node.node_index != finish
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == while_decision &&
      edge.label == Some("done") &&
      edge.route is ActivityEdgeRoute::WhileExitLeft
    }),
    true,
  )
}

///|
test "conditional and switch labels belong to incoming branch edges" {
  let conditional = layout_activity(
    @parser.parse_activity(
      "if (ready?) then (accept)\n:Accept;\nelse (reject)\n:Reject;\nendif",
    ),
  )
  let switch_layout = layout_activity(
    @parser.parse_activity(
      "switch (method)\ncase (email)\n:Email;\ncase (sms)\n:Sms;\nendswitch",
    ),
  )
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
  let layout = layout_activity(
    @parser.parse_activity(
      "if (first?) then (yes)\n:First;\nelseif (second?) then (yes)\n:Second;\nelse (no)\n:Fallback;\nendif",
    ),
  )
  guard control_index(layout, "first?") is Some(first) else {
    @test.fail("missing first decision")
  }
  guard control_index(layout, "second?") is Some(second) else {
    @test.fail("missing second decision")
  }
  guard position_of(layout, first) is Some((_, first_y)) else {
    @test.fail("missing first decision layout")
  }
  guard position_of(layout, second) is Some((_, second_y)) else {
    @test.fail("missing second decision layout")
  }
  @test.assert_eq(first_y == second_y, true)
}

///|
test "partitions and swimlanes contain their visible instructions" {
  let layout = layout_activity(
    @parser.parse_activity(
      "|Customer|\n:Submit;\n|Store|\npartition Fulfilment {\n:Validate;\n:Reserve;\n}\n|Customer|\n:Confirm;",
    ),
  )
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
  let layout = layout_activity(
    @parser.parse_activity(":Receive;\n-> validate input\n:Validate;"),
  )
  @test.assert_eq(
    layout.edges.any(edge => edge.label == Some("validate input")),
    true,
  )
}

///|
test "goto connects its anchor directly to the matching label anchor" {
  let layout = layout_activity(
    @parser.parse_activity(
      "label retry\n:Retry;\nif (again?) then (yes)\ngoto retry\nendif",
    ),
  )
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

///|
fn fork_bar_index(layout : ActivityLayout) -> Int? {
  for index, node in layout.source_nodes {
    guard node is @flow.ActivityNode::Fork else { continue }
    return Some(index)
  }
  None
}

///|
fn box_extent(layout : ActivityLayout, node_index : Int) -> (Int, Int)? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some((node.x, node.x + node.width))
  }
  None
}

///|
fn box_gap(layout : ActivityLayout, left : Int, right : Int) -> Int? {
  guard box_extent(layout, left) is Some((_, left_right)) else { return None }
  guard box_extent(layout, right) is Some((right_x, _)) else { return None }
  Some(right_x - left_right)
}

///|
test "fork columns compress toward the bars when the gaps are empty" {
  let layout = layout_activity(
    @parser.parse_activity("fork\n:A;\nfork again\n:BB;\nend fork"),
  )
  guard fork_bar_index(layout) is Some(bar_index) else {
    @test.fail("missing fork bar")
  }
  guard action_index(layout, "A") is Some(a_index) else {
    @test.fail("missing first branch")
  }
  guard action_index(layout, "BB") is Some(bb_index) else {
    @test.fail("missing second branch")
  }
  guard box_extent(layout, bar_index) is Some((bar_x, _)) else {
    @test.fail("missing bar layout")
  }
  guard box_extent(layout, a_index) is Some((a_x, _)) else {
    @test.fail("missing first branch layout")
  }
  guard box_gap(layout, a_index, bb_index) is Some(gap) else {
    @test.fail("missing branch gap")
  }
  @test.assert_eq(a_x - bar_x > 0, true)
  @test.assert_eq(gap > 0, true)
  @test.assert_eq(gap < a_x - bar_x, true)
}

///|
test "fork compression is blocked by elements spanning the gaps" {
  let empty = layout_activity(
    @parser.parse_activity("fork\n:A;\nfork again\n:BB;\nend fork"),
  )
  let covered = layout_activity(
    @parser.parse_activity(
      ":WWWWWWWWWWWWWWWWWWWW;\nfork\n:A;\nfork again\n:BB;\nend fork\n:WWWWWWWWWWWWWWWWWWWW;",
    ),
  )
  guard action_index(empty, "A") is Some(empty_a) else {
    @test.fail("missing first branch")
  }
  guard action_index(empty, "BB") is Some(empty_bb) else {
    @test.fail("missing second branch")
  }
  guard action_index(covered, "A") is Some(covered_a) else {
    @test.fail("missing covered first branch")
  }
  guard action_index(covered, "BB") is Some(covered_bb) else {
    @test.fail("missing covered second branch")
  }
  guard box_gap(empty, empty_a, empty_bb) is Some(empty_gap) else {
    @test.fail("missing empty branch gap")
  }
  guard box_gap(covered, covered_a, covered_bb) is Some(covered_gap) else {
    @test.fail("missing covered branch gap")
  }
  @test.assert_eq(empty_gap > 0, true)
  @test.assert_eq(covered_gap > 0, true)
  @test.assert_eq(covered_gap > empty_gap, true)
}

///|
test "switch case columns compress when nothing spans the gaps" {
  let layout = layout_activity(
    @parser.parse_activity(
      "switch (x)\ncase (email)\n:Email;\ncase (sms)\n:Sms;\ncase (other)\n:Other;\nendswitch",
    ),
  )
  guard action_index(layout, "Email") is Some(email_index) else {
    @test.fail("missing email branch")
  }
  guard action_index(layout, "Sms") is Some(sms_index) else {
    @test.fail("missing sms branch")
  }
  guard box_extent(layout, email_index) is Some((email_x, _)) else {
    @test.fail("missing email branch layout")
  }
  guard box_gap(layout, email_index, sms_index) is Some(gap) else {
    @test.fail("missing branch gap")
  }
  @test.assert_eq(gap > 0, true)
  @test.assert_eq(gap < email_x, true)
}

///|
test "plain sequences are never compressed" {
  let layout = layout_activity(@parser.parse_activity(":One;\n:Two;\n:Three;"))
  guard action_index(layout, "One") is Some(one_index) else {
    @test.fail("missing first action")
  }
  guard action_index(layout, "Two") is Some(two_index) else {
    @test.fail("missing second action")
  }
  guard action_index(layout, "Three") is Some(three_index) else {
    @test.fail("missing third action")
  }
  guard box_extent(layout, one_index) is Some((one_x, one_right)) else {
    @test.fail("missing first layout")
  }
  guard box_extent(layout, two_index) is Some((two_x, two_right)) else {
    @test.fail("missing second layout")
  }
  guard box_extent(layout, three_index) is Some((three_x, three_right)) else {
    @test.fail("missing third layout")
  }
  let mut min_x = one_x
  for node in layout.nodes {
    min_x = min_x.min(node.x)
  }
  @test.assert_eq(min_x == CANVAS_LEFT, true)
  let axis = one_x + one_right
  @test.assert_eq(two_x + two_right - axis <= 1, true)
  @test.assert_eq(three_x + three_right - axis <= 1, true)
  @test.assert_eq(layout.width > three_right, true)
}
