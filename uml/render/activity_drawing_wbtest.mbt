///|
fn activity_edge_points(
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
) -> Array[@graphics.Point] raise {
  let commands = []
  let arrow = @graphics.MarkerRef::new("test-arrow")
  append_edge(
    @graphics.Graphic::new(command => commands.push(command)),
    layout,
    edge,
    @metrics.FontMetrics::from_defaults(),
    arrow,
  )
  guard commands[0] is Draw(MarkedPath(path, markers), _, _, _) else {
    @test.fail("expected an activity connector")
  }
  @test.assert_eq(markers.start, None)
  @test.assert_eq(
    markers.end,
    if edge.route is WhileExitLeft(_) {
      None
    } else {
      Some(arrow)
    },
  )
  path.map(segment => {
    match segment {
      MoveTo(point) | LineTo(point) => point
      _ =>
        @test.fail("orthogonal activity routes must remain straight segments")
    }
  })
}

///|
test "all activity routes preserve orthogonality under layout translation" {
  let routes : Array[ActivityEdgeRoute] = [
    Forward,
    Horizontal,
    Goto,
    BackwardLeft,
    BackwardRight(WHILE_BACK_MARGIN, LOOP_BACK_GAP),
    RepeatBackRight(WHILE_BACK_MARGIN),
    IfDownLeft,
    IfDownRight,
    IfBypassRight(BRANCH_GAP),
    IfEmptyDown,
    SwitchLeft,
    SwitchRight,
    SwitchMiddle,
    SwitchSideMerge,
    WhileExitLeft(-WHILE_BACK_MARGIN),
  ]
  let sources = [
    ":First;\n:Second;", "if (choose?) then (yes)\n:First;\nelse (no)\n:Second;\nendif",
    "fork\n:First;\nfork again\n:Second;\nend fork",
  ]
  let dx = ACTION_FONT
  let dy = SMALL_FONT
  for source in sources {
    let layout = @parser.parse_activity(source).layout()
    let moved = {
      ..layout,
      nodes: layout.nodes.map(node => {
        ..node,
        x: node.x + dx,
        y: node.y + dy,
      }),
    }
    for edge in layout.edges {
      for route in routes {
        let edge = { ..edge, route, }
        let points = activity_edge_points(layout, edge)
        let moved_points = activity_edge_points(moved, edge)
        if route is SwitchRight {
          let from = layout_for(layout, edge.from_node_index).unwrap()
          let to = layout_for(layout, edge.to_node_index).unwrap()
          if to.x + to.width / 2 < from.x + from.width {
            @test.assert_eq(
              points[1].x > (from.x + from.width).to_double(),
              true,
            )
            @test.assert_eq(
              points[2].y > (from.y + from.height).to_double(),
              true,
            )
          }
        }
        @test.assert_eq(
          moved_points,
          points.map(point => {
            x: point.x + dx.to_double(),
            y: point.y + dy.to_double(),
          }),
        )
        for index in 1..<points.length() {
          let previous = points[index - 1]
          let point = points[index]
          @test.assert_eq(point.x == previous.x || point.y == previous.y, true)
        }
      }
    }
  }
}

///|
test "switch labels reserve space through layout and compression" {
  let diagram = @parser.parse_activity(
    "switch (method)\ncase (Send through the primary notification channel\\nwhen available\\nand enabled\\nfor this account)\n:A;\ncase (Use the secondary notification channel instead)\n:B;\nendswitch",
  )
  let metrics = diagram.style.font_metrics_for(
    diagram.style.font_family(),
    font_size=SMALL_FONT,
  )
  let layout = diagram.layout()
  let incoming = layout.edges.filter(edge => edge.label is Some(_))
  let first = layout_for(layout, incoming[0].to_node_index).unwrap()
  let second = layout_for(layout, incoming[1].to_node_index).unwrap()
  let first_label_end = first.x +
    first.width / 2 +
    metrics.measure(incoming[0].label.unwrap()).width
  let second_label_end = second.x +
    second.width / 2 +
    metrics.measure(incoming[1].label.unwrap()).width
  @test.assert_eq(first_label_end < second.x, true)
  @test.assert_eq(second_label_end < layout.width, true)
  @test.assert_eq(first.y > second.y, true)
  let commands = []
  append_edge(
    @graphics.Graphic::new(command => commands.push(command)),
    layout,
    incoming[0],
    metrics,
    @graphics.MarkerRef::new("test-arrow"),
  )
  let labels = commands.filter(command => {
    command is Draw(StyledTextBlock(_, _), _, _, _)
  })
  guard labels is [Draw(StyledTextBlock(block, _), _, _, _)] else {
    @test.fail("missing switch case label")
  }
  @test.assert_eq(block.lines.length() > 1, true)
  let condition = layout_for(layout, incoming[0].from_node_index).unwrap()
  @test.assert_eq(
    block.position.y > (condition.y + condition.height).to_double(),
    true,
  )
  @test.assert_eq(
    block.position.y +
    ((block.lines.length() - 1) * metrics.line_height).to_double() <
    first.y.to_double(),
    true,
  )
}

///|
test "switch outer continuing branches enter the merge from its sides" {
  for body in [":Left;", "stop", ""] {
    let layout = @parser.parse_activity(
      "switch (choice)\ncase (left)\n" +
      body +
      "\ncase (middle)\n:Middle;\ncase (right)\n:Right;\nendswitch",
    ).layout()
    let merges = layout.edges.filter(edge => {
      layout.source_nodes[edge.to_node_index] is @flow.ActivityNode::EndSwitch
    })
    let sides = merges.filter(edge => edge.route is SwitchSideMerge)
    @test.assert_eq(sides.length(), 2)
    for edge in sides {
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let to = layout_for(layout, edge.to_node_index).unwrap()
      if layout.source_nodes[edge.from_node_index]
        is @flow.ActivityNode::Case(_) {
        let commands = []
        let metrics = @metrics.FontMetrics::from_defaults()
        activity_append_node(
          @graphics.Graphic::new(command => commands.push(command)),
          layout,
          from,
          metrics,
          metrics,
        )
        @test.assert_eq(
          commands.any(command => command is Draw(_, _, _, _)),
          false,
        )
      }
      let points = activity_edge_points(layout, edge)
      let end = points[points.length() - 1]
      let x = from.x + from.width / 2
      if x < to.x || x > to.x + to.width {
        @test.assert_eq(end.y, (to.y + to.height / 2).to_double())
        @test.assert_eq(
          end.x,
          (if x < to.x { to.x } else { to.x + to.width }).to_double(),
        )
      } else {
        @test.assert_eq(end.y, to.y.to_double())
        @test.assert_eq(end.x, (to.x + to.width / 2).to_double())
      }
      @test.assert_eq(
        layout.source_nodes[edge.from_node_index] is @flow.ActivityNode::Stop,
        false,
      )
    }
  }
}

///|
test "activity labels carry the selected font and measured line advances" {
  let chain = @parser.parse_activity(
    "if (first?) then (yes)\n:A;\nelseif (second?) then (yes)\nrepeat\n:B;\nrepeat while (again?) is (retry) not (done)\nelse (no)\n:C;\nendif\n:After;",
  ).layout()
  let chain_joins = chain.edges.filter(edge => edge.route is IfChainMerge)
  @test.assert_eq(chain_joins.is_empty(), false)
  @test.assert_eq(chain_joins.any(edge => edge.label == Some("done")), true)
  for edge in chain_joins {
    let from = layout_for(chain, edge.from_node_index).unwrap()
    let merge = layout_for(chain, edge.to_node_index).unwrap()
    @test.assert_eq(merge.width == 0 && merge.height == 0, true)
    let commands = []
    append_edge(
      @graphics.Graphic::new(command => commands.push(command)),
      chain,
      edge,
      @metrics.FontMetrics::from_defaults(),
      @graphics.MarkerRef::new("test-arrow"),
    )
    guard commands[0] is Draw(MarkedPath(vertical, vertical_markers), _, _, _) &&
      commands[1] is Draw(MarkedPath(horizontal, horizontal_markers), _, _, _) else {
      @test.fail("missing chain joining line")
    }
    @test.assert_eq(vertical, [
      MoveTo(activity_point(from.x + from.width / 2, from.y + from.height)),
      LineTo(activity_point(from.x + from.width / 2, merge.y)),
    ])
    @test.assert_eq(vertical_markers.end is Some(_), true)
    @test.assert_eq(horizontal, [
      MoveTo(activity_point(from.x + from.width / 2, merge.y)),
      LineTo(activity_point(merge.x, merge.y)),
    ])
    @test.assert_eq(horizontal_markers.end, None)
  }
  let switch_body = "repeat\n:Retry;\nrepeat while (failed?) is (again) not (done)\n"
  let switch_layout = @parser.parse_activity(
    "switch (kind?)\ncase (first)\n" +
    switch_body +
    "case (middle)\n" +
    switch_body +
    "case (last)\n" +
    switch_body +
    "endswitch",
  ).layout()
  let loop_exits = switch_layout.edges.filter(edge => edge.label == Some("done"))
  let loop_conditions = switch_layout.nodes.filter(node => {
    switch_layout.source_nodes[node.node_index]
    is @flow.ActivityNode::RepeatWhile(_)
  })
  @test.assert_eq(loop_exits.length(), loop_conditions.length())
  for edge in loop_exits {
    @test.assert_eq(
      switch_layout.source_nodes[edge.to_node_index]
      is @flow.ActivityNode::EndSwitch,
      true,
    )
    let from = layout_for(switch_layout, edge.from_node_index).unwrap()
    let points = activity_edge_points(switch_layout, edge)
    @test.assert_eq(
      points[0],
      activity_point(from.x + from.width / 2, from.y + from.height),
    )
  }
  for other in [":Other;", ""] {
    let layout = @parser.parse_activity(
      "if (ready?) then (yes)\nrepeat\n:Retry;\nrepeat while (failed?) is (again) not (done)\nelse (no)\n" +
      other +
      "\nendif",
    ).layout()
    let joins = layout.edges.filter(edge => edge.label == Some("done"))
    @test.assert_eq(joins.is_empty(), false)
    for edge in joins {
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let to = layout_for(layout, edge.to_node_index).unwrap()
      let points = activity_edge_points(layout, edge)
      @test.assert_eq(
        points[0],
        activity_point(from.x + from.width / 2, from.y + from.height),
      )
      if from.x + from.width / 2 != to.x + to.width / 2 {
        let end_x = if from.x + from.width / 2 < to.x + to.width / 2 {
          to.x
        } else {
          to.x + to.width
        }
        @test.assert_eq(
          points[points.length() - 1],
          activity_point(end_x, to.y + to.height / 2),
        )
        @test.assert_eq(points[1].x, points[0].x)
      }
    }
  }
  for
    source in [
      "fork\nrepeat\n:Retry;\nrepeat while (failed?) is (again) not (done)\nfork again\n:Other;\nend fork",
      "|Loop|\nfork\nrepeat\n:Retry;\nrepeat while (failed?) is (again) not (done)\nfork again\n|Join|\n:Other;\nend fork",
    ] {
    let layout = @parser.parse_activity(source).layout()
    let joins = layout.edges.filter(edge => edge.label == Some("done"))
    @test.assert_eq(joins.is_empty(), false)
    for edge in joins {
      @test.assert_eq(
        layout.source_nodes[edge.to_node_index] is @flow.ActivityNode::EndFork,
        true,
      )
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let commands = []
      append_edge(
        @graphics.Graphic::new(command => commands.push(command)),
        layout,
        edge,
        @metrics.FontMetrics::from_defaults(),
        @graphics.MarkerRef::new("test-arrow"),
      )
      let labels = commands.filter(command => {
        command is Draw(StyledTextBlock(_, _), _, _, _)
      })
      guard labels is [Draw(StyledTextBlock(block, _), _, _, _)] else {
        @test.fail("missing loop exit label")
      }
      @test.assert_eq(
        block.position.x,
        (from.x + from.width / 2 + EDGE_LABEL_OFFSET).to_double(),
      )
    }
  }
  let parallel_diagram = @parser.parse_activity(
    "fork\n:A;\n->A long explanation on the connector;\n:B;\nfork again\n:Other;\nend fork",
  )
  let parallel = parallel_diagram.layout()
  let arrow = parallel.edges.filter(edge => edge.label is Some(_))[0]
  let from = layout_for(parallel, arrow.from_node_index).unwrap()
  let neighbor = parallel.nodes.filter(node => {
      parallel.source_nodes[node.node_index]
      is @flow.ActivityNode::Action("Other")
    })[0]
  let arrow_metrics = parallel_diagram.style.font_metrics_for(
    parallel_diagram.style.font_family(),
    font_size=SMALL_FONT,
  )
  @test.assert_eq(
    from.x +
    from.width / 2 +
    EDGE_LABEL_OFFSET +
    arrow_metrics.measure(arrow.label.unwrap()).width <
    neighbor.x,
    true,
  )
  for branch in [":Reject;", ""] {
    let diagram = @parser.parse_activity(
      "if (ready?) then (All prerequisite checks have passed)\n:Accept;\nelse (At least one prerequisite is still missing)\n" +
      branch +
      "\nendif",
    )
    let layout = diagram.layout()
    let metrics = diagram.style.font_metrics_for(
      diagram.style.font_family(),
      font_size=SMALL_FONT,
    )
    for edge in layout.edges {
      guard edge.label is Some(label) &&
        edge.route is (IfDownLeft | IfDownRight | IfBypassRight(_)) else {
        continue
      }
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let commands = []
      append_edge(
        @graphics.Graphic::new(command => commands.push(command)),
        layout,
        edge,
        metrics,
        @graphics.MarkerRef::new("test-arrow"),
      )
      let labels = commands.filter(command => {
        command is Draw(StyledTextBlock(_, _), _, _, _)
      })
      guard labels is [Draw(StyledTextBlock(block, _), _, _, _)] else {
        @test.fail("missing conditional side label")
      }
      let width = metrics.measure(label).width.to_double()
      if edge.route is IfDownLeft {
        @test.assert_eq(block.anchor, @graphics.TextAnchor::End)
        @test.assert_eq(block.position.x, from.x.to_double())
        @test.assert_eq(block.position.x - width >= 0, true)
      } else {
        @test.assert_eq(block.anchor, @graphics.TextAnchor::Start)
        @test.assert_eq(
          block.position.x + width < layout.width.to_double(),
          true,
        )
      }
    }
  }
  let diagram = @parser.parse_activity(":Read input\\nValidate input;")
  let layout = diagram.layout()
  let metrics = diagram.style.font_metrics_for(
    diagram.style.font_family(),
    font_size=ACTION_FONT,
  )
  let commands = []
  activity_append_node(
    @graphics.Graphic::new(command => commands.push(command)),
    layout,
    layout.nodes[0],
    metrics,
    metrics,
  )
  let labels = commands.filter(command => {
    command is Draw(StyledTextBlock(_, _), _, _, _)
  })
  guard labels is [Draw(StyledTextBlock(block, _), _, _, _)] else {
    @test.fail("missing activity text")
  }
  @test.assert_eq(block.lines.map(line => line.text), [
    "Read input", "Validate input",
  ])
  let single = @parser.parse_activity(":Read input Validate input;").layout()
  @test.assert_eq(layout.nodes[0].height > single.nodes[0].height, true)
  @test.assert_eq(layout.nodes[0].width < single.nodes[0].width, true)
  for size in [ACTION_FONT, SMALL_FONT] {
    let metrics = @metrics.FontMetrics::from_defaults(font_size=size)
    let text = "first line\nlast line"
    let commands = []
    append_label(
      @graphics.Graphic::new(command => commands.push(command)),
      size,
      size,
      text,
      metrics,
      anchor=Start,
      multiline_anchor=Baseline,
    )
    guard commands is [Draw(StyledTextBlock(block, font), _, _, _)] else {
      @test.fail("expected a multiline label with explicit font size")
    }
    @test.assert_eq(font.font_size, Some(metrics.font_size.to_double()))
    @test.assert_eq(block.position.y, size.to_double())
    @test.assert_eq(block.anchor, @graphics.TextAnchor::Start)
    @test.assert_eq(block.lines.map(line => line.text).join("\n"), text)
    for line in block.lines {
      @test.assert_eq(
        line.advance,
        Some(metrics.measure(line.text).advance_width.to_double()),
      )
    }
  }
}

///|
test "end renders a crossed circle instead of a stop bullseye" {
  let layout = @parser.parse_activity("end").layout()
  let stop = @parser.parse_activity("stop").layout()
  @test.assert_eq(layout.nodes[0].width < stop.nodes[0].width, true)
  let commands = []
  let metrics = @metrics.FontMetrics::from_defaults()
  activity_append_node(
    @graphics.Graphic::new(command => commands.push(command)),
    layout,
    layout.nodes[0],
    metrics,
    metrics,
  )
  let shapes = commands.filter(command => command is Draw(_, _, _, _))
  guard shapes
    is [
      Draw(Circle(..), _, _, _),
      Draw(Path([MoveTo(a), LineTo(b), MoveTo(c), LineTo(d)]), _, _, _),
    ] else {
    @test.fail("expected a circle with two crossing strokes")
  }
  @test.assert_eq(a.x, c.x)
  @test.assert_eq(b.x, d.x)
  @test.assert_eq(a.y, d.y)
  @test.assert_eq(b.y, c.y)
  @test.assert_eq(a.x < b.x && a.y < b.y, true)
}

///|
test "loop back edges reach the target side from outside the node" {
  let sources = [
    "while (more?)\nendwhile", "while (more?) is (yes)\nendwhile (no)\n:After;",
    "while (more?)\n:A much wider activity in the middle of the loop;\n:Last;\nendwhile",
    "repeat\n:A much wider activity in the middle of the loop;\n:Last;\nrepeat while (retry?)",
    "while (more?)\n:Read;\nendwhile (No more records remain in this batch)", "while (outer?)\nwhile (inner?)\n:Read;\nendwhile\nendwhile",
    "while (more?)\nfork\n:Read;\nfork again\n:Write;\nend fork\nendwhile", "repeat\n:Retry;\nrepeat while (failed?) is (Retry delivery through the secondary channel)",
    "while (outer?)\nrepeat\n:Retry;\nrepeat while (failed?)\nendwhile",
  ]
  for source in sources {
    let layout = @parser.parse_activity(source).layout()
    for edge in layout.edges {
      guard edge.label is Some(label) &&
        edge.route is (WhileExitLeft(_) | RepeatBackRight(_)) else {
        continue
      }
      let metrics = @metrics.FontMetrics::from_defaults(font_size=SMALL_FONT)
      let commands = []
      append_edge(
        @graphics.Graphic::new(command => commands.push(command)),
        layout,
        edge,
        metrics,
        @graphics.MarkerRef::new("test-arrow"),
      )
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let labels = commands.filter(command => {
        command is Draw(StyledTextBlock(_, _), _, _, _)
      })
      guard labels is [Draw(StyledTextBlock(block, _), _, _, _)] else {
        @test.fail("missing loop side label")
      }
      let width = metrics.measure(label).width.to_double()
      if edge.route is WhileExitLeft(_) {
        @test.assert_eq(block.anchor, @graphics.TextAnchor::End)
        @test.assert_eq(block.position.x, from.x.to_double())
        @test.assert_eq(block.position.x - width >= 0, true)
      } else {
        @test.assert_eq(block.anchor, @graphics.TextAnchor::Start)
        @test.assert_eq(block.position.x, (from.x + from.width).to_double())
        @test.assert_eq(
          block.position.x + width < layout.width.to_double(),
          true,
        )
      }
    }
    let back_edges = layout.edges.filter(edge => {
      edge.route is (BackwardRight(_) | RepeatBackRight(_))
    })
    @test.assert_eq(back_edges.is_empty(), false)
    for node in layout.nodes {
      guard layout.source_nodes[node.node_index]
        is @flow.ActivityNode::EndWhile(_) else {
        continue
      }
      let commands = []
      let metrics = @metrics.FontMetrics::from_defaults()
      activity_append_node(
        @graphics.Graphic::new(command => commands.push(command)),
        layout,
        node,
        metrics,
        metrics,
      )
      @test.assert_eq(
        commands.any(command => command is Draw(_, _, _, _)),
        false,
      )
      let exits = layout.edges.filter(edge => {
        edge.to_node_index == node.node_index
      })
      for edge in exits {
        let points = activity_edge_points(layout, edge)
        @test.assert_eq(
          points[points.length() - 1],
          activity_point(node.x, node.y),
        )
      }
    }
    if source == "while (more?) is (yes)\nendwhile (no)\n:After;" {
      @test.assert_eq(
        back_edges.any(edge => {
          edge.from_node_index == edge.to_node_index &&
          edge.label == Some("yes")
        }),
        true,
      )
    }
    for edge in back_edges {
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let target = layout_for(layout, edge.to_node_index).unwrap()
      let points = activity_edge_points(layout, edge)
      let end = points[points.length() - 1]
      let before_end = points[points.length() - 2]
      @test.assert_eq(
        end,
        activity_point(target.x + target.width, target.y + target.height / 2),
      )
      @test.assert_eq(before_end.x > end.x, true)
      @test.assert_eq(before_end.y, end.y)
      for node in layout.nodes {
        guard node.y >= target.y && node.y + node.height <= from.y + from.height else {
          continue
        }
        @test.assert_eq((node.x + node.width).to_double() < before_end.x, true)
      }
      if edge.route is RepeatBackRight(_) {
        @test.assert_eq(
          points[0],
          activity_point(from.x + from.width, from.y + from.height / 2),
        )
      } else {
        @test.assert_eq(
          points[0],
          activity_point(from.x + from.width / 2, from.y + from.height),
        )
        @test.assert_eq(points[1].y > points[0].y, true)
      }
    }
  }
}

///|
test "fork lane connectors keep their ports on both translated nodes" {
  for
    source in [
      "fork\nfork\n:A;\nfork again\n:B;\nend fork\nfork again\n:C;\nend fork", "|Outer|\nfork\n|Inner|\nfork\n:A;\nfork again\n:B;\nend fork\nfork again\n|Outer|\n:C;\nend fork",
    ] {
    let nested = @parser.parse_activity(source).layout()
    let joins = nested.edges.filter(edge => {
      nested.source_nodes[edge.from_node_index] is @flow.ActivityNode::EndFork &&
      nested.source_nodes[edge.to_node_index] is @flow.ActivityNode::EndFork
    })
    @test.assert_eq(joins.is_empty(), false)
    for edge in joins {
      let from = layout_for(nested, edge.from_node_index).unwrap()
      let to = layout_for(nested, edge.to_node_index).unwrap()
      let points = activity_edge_points(nested, edge)
      @test.assert_eq(points[0].x, (from.x + from.width / 2).to_double())
      if edge.route is ForkLane(_, _) {
        @test.assert_eq(points[1].y, (to.y - FORK_LANE_IN_RISE).to_double())
      }
    }
  }
  let layout = @parser.parse_activity(
    "|Before|\n:Begin;\n|Origin|\nfork\n|Worker|\n:Work;\nfork again\n|Origin|\n:Local;\nend fork\n|After|\n:Finish;",
  ).layout()
  let sequential = layout.edges.filter(edge => edge.route is ForkSequence)
  @test.assert_eq(sequential.is_empty(), false)
  for edge in sequential {
    let from = layout_for(layout, edge.from_node_index).unwrap()
    let to = layout_for(layout, edge.to_node_index).unwrap()
    let points = activity_edge_points(layout, edge)
    @test.assert_eq(points[0].x, (from.x + from.width / 2).to_double())
    @test.assert_eq(
      points[points.length() - 1].x,
      (to.x + to.width / 2).to_double(),
    )
    @test.assert_eq(
      points[1].y,
      ((from.y + from.height + to.y) / 2).to_double(),
    )
  }
  let crossings = layout.edges.filter(edge => edge.route is ForkLane(_, _))
  @test.assert_eq(crossings.is_empty(), false)
  for edge in crossings {
    let from = layout_for(layout, edge.from_node_index).unwrap()
    let to = layout_for(layout, edge.to_node_index).unwrap()
    let points = activity_edge_points(layout, edge)
    let first = points[0]
    let last = points[points.length() - 1]
    @test.assert_eq(
      first.x >= from.x.to_double() &&
      first.x <= (from.x + from.width).to_double(),
      true,
    )
    @test.assert_eq(
      last.x >= to.x.to_double() && last.x <= (to.x + to.width).to_double(),
      true,
    )
    @test.assert_eq(first.y, (from.y + from.height).to_double())
    @test.assert_eq(last.y, to.y.to_double())
    @test.assert_eq(first.x != last.x, true)
    for index in 1..<points.length() {
      @test.assert_eq(
        points[index - 1].x == points[index].x ||
        points[index - 1].y == points[index].y,
        true,
      )
    }
  }
}
