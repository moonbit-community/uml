///|
fn position_of(
  layout : @render.ActivityLayout,
  node_index : Int,
) -> (Int, Int)? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some((node.x, node.y))
  }
  None
}

///|
fn action_index(layout : @render.ActivityLayout, label : String) -> Int? {
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
  layout : @render.ActivityLayout,
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
fn control_index(layout : @render.ActivityLayout, condition : String) -> Int? {
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
  layout : @render.ActivityLayout,
  kind : @render.ActivityRegionKind,
  label : String,
) -> @render.ActivityRegionLayout? {
  for region in layout.regions {
    guard region.kind == kind && region.label == label else { continue }
    return Some(region)
  }
  None
}

///|
test "conditional branches are horizontal siblings and join at endif" {
  let layout = @render.layout_activity(
    @parser.parse_activity(
      "if (ready?) then (yes)\n:Accept;\nnote right\nDetailed explanation beside the accepted branch\nend note\nelse (no)\n:Reject;\nendif\n:Continue;",
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
  let (accept_left, accept_right) = box_extent(layout, accept_index).unwrap()
  let (reject_left, reject_right) = box_extent(layout, reject_index).unwrap()
  let (decision_left, decision_right) = box_extent(
    layout,
    control_index(layout, "ready?").unwrap(),
  ).unwrap()
  @test.assert_eq(
    ((accept_left + accept_right) / 2 + (reject_left + reject_right) / 2) / 2,
    (decision_left + decision_right) / 2,
  )
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
  for
    source in [
      "fork\nfork again\n:Work;\nend fork", "fork\n:Work;\nfork again\nend fork",
      "fork\nfork again\nend fork",
    ] {
    let layout = @render.layout_activity(@parser.parse_activity(source))
    let empty_branches = layout.nodes.filter(node => {
      layout.source_nodes[node.node_index] is @flow.ActivityNode::ForkAgain
    })
    @test.assert_eq(empty_branches.is_empty(), false)
    for branch in empty_branches {
      @test.assert_eq(
        layout.edges.any(edge => {
          edge.to_node_index == branch.node_index &&
          layout.source_nodes[edge.from_node_index] is @flow.ActivityNode::Fork
        }),
        true,
      )
      @test.assert_eq(
        layout.edges.any(edge => {
          edge.from_node_index == branch.node_index &&
          layout.source_nodes[edge.to_node_index] is @flow.ActivityNode::EndFork
        }),
        true,
      )
    }
  }
  let flow = "fork\n:Build;\nfork again\n:Test;\nend fork\n:Ship;"
  for source in [flow, "|Team|\n" + flow] {
    let layout = @render.layout_activity(@parser.parse_activity(source))
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
    guard box_extent(layout, build_index) is Some((_, build_right)) else {
      @test.fail("missing build branch extent")
    }
    @test.assert_eq(build_x < test_x && build_right < test_x, true)
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
}

///|
test "loops include a routed back edge" {
  let layout = @render.layout_activity(
    @parser.parse_activity("while (more?)\n:Read;\nendwhile (done)\n:Finish;"),
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.route is BackwardLeft || edge.route is BackwardRight(_)
    }),
    true,
  )
}

///|
test "loop labels remain attached to control-flow edges" {
  let inner = "repeat\n:Retry;\nrepeat while (failed?) is (again) not (inner done)"
  for
    source in [
      "repeat\n" + inner + "\nrepeat while (outer?) is (retry) not (outer done)",
      "while (outer?) is (yes)\n" + inner + "\nendwhile (no)",
    ] {
    let nested = @render.layout_activity(@parser.parse_activity(source))
    let exits = nested.edges.filter(edge => edge.label == Some("inner done"))
    @test.assert_eq(exits.is_empty(), false)
    for edge in exits {
      @test.assert_eq(
        nested.source_nodes[edge.from_node_index]
        is @flow.ActivityNode::RepeatWhile(_),
        true,
      )
    }
  }
  let source = "while (more?) is (yes\\ncontinue reading\\nuntil exhausted)\n:Read;\nendwhile (done\\nfinished)\nrepeat\n:Retry;\nrepeat while (failed?) is (again\\nretry) not (sent\\nconfirmed\\narchived)\n:Finish;"
  let layout = @render.layout_activity(@parser.parse_activity(source))
  let single_exit = @render.layout_activity(
    @parser.parse_activity(
      source.replace_all(old="sent\\nconfirmed\\narchived", new="sent"),
    ),
  )
  @test.assert_eq(layout.height > single_exit.height, true)
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.label == Some("yes\ncontinue reading\nuntil exhausted")
    }),
    true,
  )
  let single = @render.layout_activity(
    @parser.parse_activity("while (more?) is (yes)\n:Read;\nendwhile"),
  )
  let (_, single_y) = position_of(single, action_index(single, "Read").unwrap()).unwrap()
  let (_, multiline_y) = position_of(
    layout,
    action_index(layout, "Read").unwrap(),
  ).unwrap()
  @test.assert_eq(multiline_y > single_y, true)
  @test.assert_eq(
    layout.edges.any(edge => edge.label == Some("done\nfinished")),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => edge.label == Some("again\nretry")),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => edge.label == Some("sent\nconfirmed\narchived")),
    true,
  )
}

///|
test "while exits from its controlling decision rather than its loop body" {
  let layout = @render.layout_activity(
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
      edge.route is @render.ActivityEdgeRoute::WhileExitLeft(_)
    }),
    true,
  )
}

///|
test "conditional and switch labels belong to incoming branch edges" {
  for
    source in [
      "if (ready?) then (yes)\n:Accept;\nendif", "if (ready?) then (yes)\n:Accept;\nelse (no)\n:Reject;\nendif",
      "if (ready?) then (yes)\n:Accept;\nelseif (other?) then (other)\n:Other;\nelse (no)\n:Reject;\nendif",
    ] {
    let single = @render.layout_activity(@parser.parse_activity(source))
    let multiline = @render.layout_activity(
      @parser.parse_activity(
        source.replace_all(old="(yes)", new="(yes\\ncontinue\\nprocessing)"),
      ),
    )
    @test.assert_eq(multiline.height > single.height, true)
    @test.assert_eq(
      multiline.edges.any(edge => {
        edge.label == Some("yes\ncontinue\nprocessing")
      }),
      true,
    )
  }
  for
    source in [
      "if (ready?) then (yes)\n:Accept;\nendif", "if (ready?) then (yes)\n:Accept;\nelse (no)\nendif",
      "if (ready?) then (yes)\nelse (no)\n:Reject;\nendif", "if (ready?) then (yes)\nelseif (other?) then (other)\n:Other;\nendif",
      "if (ready?) then (yes)\nelse (no)\nendif", "|Start|\nif (ready?) then (yes)\n|Empty|\nelse (no)\n:Reject;\nendif",
      "|Start|\nif (ready?) then (yes)\n:Accept;\nelse (no)\n|Empty|\nendif", "|Start|\nif (ready?) then (yes)\n|First|\nelse (no)\n|Second|\nendif",
    ] {
    let layout = @render.layout_activity(@parser.parse_activity(source))
    for node in layout.nodes {
      guard layout.source_nodes[node.node_index] is @flow.ActivityNode::If(_) else {
        continue
      }
      let outgoing = layout.edges.filter(edge => {
        edge.from_node_index == node.node_index
      })
      @test.assert_eq(outgoing.length(), 2)
    }
  }

  let conditional = @render.layout_activity(
    @parser.parse_activity(
      "if (ready?) then (accept)\n:Accept;\nelse (reject)\n:Reject;\nendif",
    ),
  )
  let switch_layout = @render.layout_activity(
    @parser.parse_activity(
      "switch (Choose the preferred notification delivery method)\ncase (email)\n:Email;\ncase (sms)\n:Sms;\nendswitch",
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
  let decisions = switch_layout.nodes.filter(node => {
    switch_layout.source_nodes[node.node_index] is @flow.ActivityNode::Switch(_)
  })
  let merges = switch_layout.nodes.filter(node => {
    switch_layout.source_nodes[node.node_index] is @flow.ActivityNode::EndSwitch
  })
  let decision = decisions[0]
  let merge = merges[0]
  let (email_left, email_right) = box_extent(
    switch_layout,
    action_index(switch_layout, "Email").unwrap(),
  ).unwrap()
  let (sms_left, sms_right) = box_extent(
    switch_layout,
    action_index(switch_layout, "Sms").unwrap(),
  ).unwrap()
  @test.assert_eq((email_left + email_right) / 2 < decision.x, true)
  @test.assert_eq(
    (sms_left + sms_right) / 2 > decision.x + decision.width,
    true,
  )
  @test.assert_eq(decision.x + decision.width / 2, merge.x + merge.width / 2)
  for
    source in [
      "switch (choice)\ncase (empty)\nendswitch", "switch (choice)\ncase (empty)\ncase (work)\n:Work;\nendswitch",
      "switch (choice)\ncase (terminated)\nstop\ncase (empty)\nendswitch",
    ] {
    let layout = @render.layout_activity(
      @parser.parse_activity(source + "\n:After;"),
    )
    let incoming = layout.edges.filter(edge => edge.label == Some("empty"))
    @test.assert_eq(incoming.length(), 1)
    let empty = incoming[0].to_node_index
    let outgoing = layout.edges.filter(edge => edge.from_node_index == empty)
    @test.assert_eq(outgoing.length(), 1)
    let merge = outgoing[0].to_node_index
    @test.assert_eq(
      layout.source_nodes[merge] is @flow.ActivityNode::EndSwitch,
      true,
    )
    @test.assert_eq(
      layout.edges.any(edge => {
        edge.from_node_index == merge &&
        Some(edge.to_node_index) == action_index(layout, "After")
      }),
      true,
    )
  }
}

///|
test "elseif decisions form a horizontal cascade" {
  for ending in ["endif", "else (no)\nendif"] {
    let empty = @render.layout_activity(
      @parser.parse_activity(
        "if (first?) then (yes)\nelseif (second?) then (other)\n" + ending,
      ),
    )
    let branch_edges = empty.edges.filter(edge => {
      edge.route is @render.ActivityEdgeRoute::Forward
    })
    @test.assert_eq(branch_edges.is_empty(), false)
    for edge in branch_edges {
      let decision = position_of(empty, edge.from_node_index).unwrap()
      let anchor = position_of(empty, edge.to_node_index).unwrap()
      let (left, right) = box_extent(empty, edge.from_node_index).unwrap()
      @test.assert_eq(anchor.0, left + (right - left) / 2)
      @test.assert_eq(anchor.1 > decision.1, true)
      @test.assert_eq(
        empty.edges.any(join => {
          join.from_node_index == edge.to_node_index &&
          join.route is @render.ActivityEdgeRoute::IfChainMerge
        }),
        true,
      )
    }
  }
  let layout = @render.layout_activity(
    @parser.parse_activity(
      "if (first?) then (yes)\n:First;\nnote left\nA wide explanation beside the first branch\nend note\nelseif (second?\\nextra line\\nthird line) then (yes)\n:Second;\nelse (no)\n:Fallback;\nendif",
    ),
  )
  guard control_index(layout, "first?") is Some(first) else {
    @test.fail("missing first decision")
  }
  guard control_index(layout, "second?\\nextra line\\nthird line")
    is Some(second) else {
    @test.fail("missing second decision")
  }
  let decisions = layout.nodes.filter(node => {
    node.node_index == first || node.node_index == second
  })
  @test.assert_eq(decisions[1].height > decisions[0].height, true)
  let (body_left, body_right) = box_extent(
    layout,
    action_index(layout, "First").unwrap(),
  ).unwrap()
  @test.assert_eq(
    decisions[0].x + decisions[0].width / 2,
    body_left + (body_right - body_left) / 2,
  )
  @test.assert_eq(
    decisions[0].y + decisions[0].height / 2,
    decisions[1].y + decisions[1].height / 2,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == first &&
      edge.to_node_index == second &&
      edge.route is @render.ActivityEdgeRoute::Horizontal
    }),
    true,
  )
  guard action_index(layout, "Fallback") is Some(fallback) else {
    @test.fail("missing fallback action")
  }
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == second &&
      edge.to_node_index == fallback &&
      edge.label == Some("no")
    }),
    true,
  )
}

///|
test "partitions and swimlanes contain their visible instructions" {
  for
    flow in [
      "if (first?) then (yes)\n|Worker|\n:First;\nelseif (second?) then (yes)\n:Second;\nelse (no)\n:Fallback;\nendif",
      "switch (method)\ncase (first)\n|Worker|\n:First;\ncase (second)\n:Second;\nendswitch",
    ] {
    let layout = @render.layout_activity(
      @parser.parse_activity("|Control|\n" + flow + "\n:After;"),
    )
    let control = region_for(
      layout,
      @render.ActivityRegionKind::Swimlane,
      "Control",
    ).unwrap()
    let worker = region_for(
      layout,
      @render.ActivityRegionKind::Swimlane,
      "Worker",
    ).unwrap()
    for node in layout.nodes {
      let lane = if layout.source_nodes[node.node_index]
        is @flow.ActivityNode::Action(_) {
        worker
      } else {
        control
      }
      @test.assert_eq(
        node.x >= lane.x && node.x + node.width <= lane.x + lane.width,
        true,
      )
    }
  }
  let source = "|Customer|\n:Submit;\n|Store|\npartition Fulfilment {\n:Validate;\n:Reserve;\n}\n|Customer|\n:Confirm;\n|Empty|\n|Empty lane\\nwith a long heading\\nand extra details|"
  let layout = @render.layout_activity(@parser.parse_activity(source))
  let single_line = @render.layout_activity(
    @parser.parse_activity(source.replace_all(old="\\n", new=" ")),
  )
  guard region_for(layout, @render.ActivityRegionKind::Partition, "Fulfilment")
    is Some(partition) else {
    @test.fail("missing partition region")
  }
  @test.assert_eq(
    layout.regions.any(region => {
      region.kind is @render.ActivityRegionKind::Swimlane &&
      region.label == "Customer"
    }),
    true,
  )
  guard action_index(layout, "Submit") is Some(submit_index) else {
    @test.fail("missing customer action")
  }
  guard action_index(layout, "Validate") is Some(validate_index) else {
    @test.fail("missing store action")
  }
  guard position_of(layout, submit_index) is Some((submit_x, submit_y)) else {
    @test.fail("missing customer position")
  }
  guard position_of(layout, validate_index) is Some((validate_x, _)) else {
    @test.fail("missing store position")
  }
  @test.assert_eq(submit_x == validate_x, false)
  let (_, original_y) = position_of(
    single_line,
    action_index(single_line, "Submit").unwrap(),
  ).unwrap()
  @test.assert_eq(submit_y > original_y, true)
  guard position_of(layout, validate_index) is Some((validate_x, validate_y)) else {
    @test.fail("missing partitioned action position")
  }
  @test.assert_eq(validate_x >= partition.x, true)
  @test.assert_eq(validate_y >= partition.y, true)
  @test.assert_eq(validate_x < partition.x + partition.width, true)
  @test.assert_eq(validate_y < partition.y + partition.height, true)
  let lanes = layout.regions.filter(region => {
    region.kind is @render.ActivityRegionKind::Swimlane
  })
  for lane in lanes {
    @test.assert_eq(lane.y, lanes[0].y)
    @test.assert_eq(lane.height, lanes[0].height)
    @test.assert_eq(lane.x + lane.width < layout.width, true)
    @test.assert_eq(lane.y + lane.height < layout.height, true)
  }
  let empty = region_for(layout, @render.ActivityRegionKind::Swimlane, "Empty").unwrap()
  let titled = region_for(
    layout,
    @render.ActivityRegionKind::Swimlane,
    "Empty lane\nwith a long heading\nand extra details",
  ).unwrap()
  @test.assert_eq(titled.width > empty.width, true)
}

///|
test "explicit arrow text labels the following visible edge" {
  let single = @render.layout_activity(
    @parser.parse_activity(":Receive;\n-> validate input;\n:Validate;"),
  )
  let (_, single_y) = position_of(
    single,
    action_index(single, "Validate").unwrap(),
  ).unwrap()
  for arrow in ["->", "-[#blue]->"] {
    let layout = @render.layout_activity(
      @parser.parse_activity(
        ":Receive;\n" + arrow + "validate  input\\nthen continue;\n:Validate;",
      ),
    )
    @test.assert_eq(
      layout.edges.any(edge => {
        edge.label == Some("validate  input\nthen continue")
      }),
      true,
    )
    let (_, multiline_y) = position_of(
      layout,
      action_index(layout, "Validate").unwrap(),
    ).unwrap()
    @test.assert_eq(multiline_y > single_y, true)
  }
}

///|
test "goto connects its anchor directly to the matching label anchor" {
  let layout = @render.layout_activity(
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
      edge.route is @render.ActivityEdgeRoute::Goto
    }),
    true,
  )
  let decision = control_index(layout, "again?").unwrap()
  let retry = action_index(layout, "Retry").unwrap()
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == decision && edge.to_node_index == goto_anchor
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == label_anchor && edge.to_node_index == retry
    }),
    true,
  )
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == goto_anchor &&
      !(edge.route is @render.ActivityEdgeRoute::Goto)
    }),
    false,
  )
  let (anchor_x, anchor_y) = position_of(layout, label_anchor).unwrap()
  let (retry_left, retry_right) = box_extent(layout, retry).unwrap()
  @test.assert_eq(anchor_x, (retry_left + retry_right) / 2)
  @test.assert_eq(anchor_y < position_of(layout, retry).unwrap().1, true)
}

///|
fn box_extent(layout : @render.ActivityLayout, node_index : Int) -> (Int, Int)? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some((node.x, node.x + node.width))
  }
  None
}

///|
fn box_gap(layout : @render.ActivityLayout, left : Int, right : Int) -> Int? {
  guard box_extent(layout, left) is Some((_, left_right)) else { return None }
  guard box_extent(layout, right) is Some((right_x, _)) else { return None }
  Some(right_x - left_right)
}

///|
test "fork compression is blocked by elements spanning the gaps" {
  let empty = @render.layout_activity(
    @parser.parse_activity("fork\n:A;\nfork again\n:BB;\nend fork"),
  )
  let covered = @render.layout_activity(
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
test "plain sequences are never compressed" {
  let layout = @render.layout_activity(
    @parser.parse_activity(":One;\n:Two;\n:Three;"),
  )
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
  @test.assert_eq(min_x == @render.CANVAS_LEFT, true)
  let axis = one_x + one_right
  @test.assert_eq(two_x + two_right - axis <= 1, true)
  @test.assert_eq(three_x + three_right - axis <= 1, true)
  @test.assert_eq(layout.width > three_right, true)
}

///|
test "sequence canvas keeps its bottom margin as instructions and labels grow" {
  let sources = [
    ":One;", ":One;\n:Two;\n:Three;\n:Four;\n:Five;", ":One;\n-> next step;\n:Two;\n:Three;\n:Four;\n:Five;",
  ]
  let margins = sources.map(source => {
    let layout = @render.layout_activity(@parser.parse_activity(source))
    let mut bottom = 0
    for node in layout.nodes {
      bottom = bottom.max(node.y + node.height)
      @test.assert_eq(node.y + node.height < layout.height, true)
    }
    layout.height - bottom
  })
  for margin in margins {
    @test.assert_eq(margin, margins[0])
  }
}

///|
test "fork join stays below a branch containing a sequence" {
  let layout = @render.layout_activity(
    @parser.parse_activity(
      "fork\n:One;\n:Two;\n:Three;\n:Four;\nfork again\n:Other;\nend fork",
    ),
  )
  guard action_index(layout, "Four") is Some(last) else {
    @test.fail("missing last branch action")
  }
  for edge in layout.edges {
    guard edge.from_node_index == last else { continue }
    guard position_of(layout, edge.to_node_index) is Some((_, join_y)) else {
      @test.fail("missing fork join")
    }
    for node in layout.nodes {
      guard node.node_index == last else { continue }
      @test.assert_eq(node.y + node.height < join_y, true)
    }
  }
}

///|
test "while exit continues after the loop without reentering its body" {
  let layout = @render.layout_activity(
    @parser.parse_activity("while (more?)\n:Read;\nendwhile\n:Finish;"),
  )
  guard action_index(layout, "Finish") is Some(finish) else {
    @test.fail("missing continuation")
  }
  let exits = layout.nodes.filter(node => {
    layout.source_nodes[node.node_index] is @flow.ActivityNode::EndWhile(_)
  })
  @test.assert_eq(exits.is_empty(), false)
  for exit in exits {
    let outgoing = layout.edges.filter(edge => {
      edge.from_node_index == exit.node_index
    })
    @test.assert_eq(outgoing.is_empty(), false)
    for edge in outgoing {
      @test.assert_eq(edge.to_node_index, finish)
    }
  }
}

///|
test "terminal branches do not expose an outgoing flow or merge" {
  for
    source in [
      ":Terminated;\nkill\n:After;", "if (ready?) then\nstop\nelse\nend\nendif\n:After;",
      "if (outer?) then\nif (inner?) then\nstop\nelse\nend\nendif\nelse\n:Terminated;\nkill\nendif\n:After;",
      "switch (choice)\ncase (first)\nstop\ncase (second)\nend\nendswitch\n:After;",
      "while (more?)\nstop\nendwhile\n:After;",
    ] {
    let layout = @render.layout_activity(@parser.parse_activity(source))
    @test.assert_eq(
      layout.edges.any(edge => {
        layout.source_nodes[edge.from_node_index]
        is (@flow.ActivityNode::Stop
        | @flow.ActivityNode::End
        | @flow.ActivityNode::Kill
        | @flow.ActivityNode::Action("Terminated"))
      }),
      false,
    )
    @test.assert_eq(
      layout.nodes.any(node => {
        layout.source_nodes[node.node_index]
        is (@flow.ActivityNode::EndIf
        | @flow.ActivityNode::EndSwitch
        | @flow.ActivityNode::Kill)
      }),
      false,
    )
  }
}

///|
test "nested partitions reserve their frames between adjacent instructions" {
  let source = ":Before;\npartition Outer {\npartition Inner {\n:Inside;\n}\n:Tail;\n}\n:After;"
  let single_line = @render.layout_activity(@parser.parse_activity(source))
  let layout = @render.layout_activity(
    @parser.parse_activity(
      source.replace_all(old="Outer", new="Outer\\nDetails\\nNotes"),
    ),
  )
  let outer = region_for(
    layout,
    @render.ActivityRegionKind::Partition,
    "Outer\nDetails\nNotes",
  ).unwrap()
  let inner = region_for(layout, @render.ActivityRegionKind::Partition, "Inner").unwrap()
  let original_inner = region_for(
    single_line,
    @render.ActivityRegionKind::Partition,
    "Inner",
  ).unwrap()
  @test.assert_eq(inner.y > original_inner.y, true)
  @test.assert_eq(inner.x > outer.x && inner.y > outer.y, true)
  @test.assert_eq(inner.x + inner.width < outer.x + outer.width, true)
  @test.assert_eq(inner.y + inner.height < outer.y + outer.height, true)
  for node in layout.nodes {
    if layout.source_nodes[node.node_index]
      is @flow.ActivityNode::Action("Before") {
      @test.assert_eq(node.y + node.height < outer.y, true)
    }
    if layout.source_nodes[node.node_index]
      is @flow.ActivityNode::Action("After") {
      @test.assert_eq(node.y > outer.y + outer.height, true)
    }
  }
}

///|
test "side notes preserve the activity flow and its axis" {
  let source = "start\nif (ready?) then (yes)\nwhile (more?)\nrepeat\n:Action;\nnote left\nLeft annotation\\nAdditional explanation\\nLast line\nend note\nnote right\nRight annotation with more text\nend note\n:Next;\nrepeat while (again?)\nendwhile\nendif\nstop"
  let layout = @render.layout_activity(@parser.parse_activity(source))
  let expanded = @render.layout_activity(
    @parser.parse_activity(source.replace_all(old="\\n", new="\n")),
  )
  @test.assert_eq(layout.nodes, expanded.nodes)
  let activity = action_index(layout, "Action").unwrap()
  let next = action_index(layout, "Next").unwrap()
  @test.assert_eq(
    layout.edges.any(edge => {
      edge.from_node_index == activity && edge.to_node_index == next
    }),
    true,
  )
  let (left, right) = box_extent(layout, activity).unwrap()
  let (next_left, next_right) = box_extent(layout, next).unwrap()
  @test.assert_eq((left + right - next_left - next_right).abs() <= 1, true)
  for node in layout.nodes {
    if layout.source_nodes[node.node_index]
      is (@flow.ActivityNode::Repeat
      | @flow.ActivityNode::RepeatWhile(_)
      | @flow.ActivityNode::If(_)
      | @flow.ActivityNode::EndIf
      | @flow.ActivityNode::While(_)
      | @flow.ActivityNode::EndWhile(_)
      | @flow.ActivityNode::Start
      | @flow.ActivityNode::Stop) {
      @test.assert_eq(node.x + node.width / 2, left + (right - left) / 2)
    }
  }
  for node in layout.nodes {
    guard layout.source_nodes[node.node_index]
      is @flow.ActivityNode::Note(_, side) else {
      continue
    }
    @test.assert_eq(
      layout.edges.any(edge => {
        edge.from_node_index == node.node_index ||
        edge.to_node_index == node.node_index
      }),
      false,
    )
    if side is Left {
      @test.assert_eq(node.x + node.width < left, true)
    } else {
      @test.assert_eq(node.x > right, true)
    }
    @test.assert_eq(node.x >= 0 && node.x + node.width < layout.width, true)
  }
}
