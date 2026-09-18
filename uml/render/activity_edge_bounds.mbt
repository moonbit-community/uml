///|
/// Horizontal path bounds, independent of whether a route blocks compression.
fn activity_edge_x_bounds(
  edge : ActivityEdgeLayout,
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
  nodes : Array[@flow.ActivityNode],
) -> (Int, Int) {
  let from_source = nodes[edge.from_node_index]
  let to_source = nodes[edge.to_node_index]
  if (from_source.is_fork() || to_source.is_fork()) && edge.route is Forward {
    let port = if from_source is @flow.ActivityNode::Fork {
      to.x + to.width / 2
    } else {
      from.x + from.width / 2
    }
    return (port, port)
  }
  let x = from.x + from.width / 2
  let target_x = to.x + to.width / 2
  let from_is_decision = from_source.is_decision()
  let to_is_switch_exit = to_source is @flow.ActivityNode::EndSwitch
  match edge.route {
    ForkSequence | WhileEntry | RepeatForward =>
      (x.min(target_x), x.max(target_x))
    Forward =>
      if from_is_decision && !to_is_switch_exit && target_x != x {
        let start_x = if target_x < x { from.x } else { from.x + from.width }
        (start_x.min(target_x), start_x.max(target_x))
      } else {
        (x.min(target_x), x.max(target_x))
      }
    Horizontal | IfSideTerminal => {
      let start = (from.x + from.width).min(to.x)
      (start, (from.x + from.width).max(to.x))
    }
    Goto => (from.x.min(to.x), from.x.max(to.x))
    BackwardLeft => {
      let route_x = backward_left_route_x(from, to)
      (route_x, x.max(target_x))
    }
    BackwardRight(offset, _) | RepeatBackRight(offset) => {
      let route_x = to.x + offset
      let start_x = if edge.route is RepeatBackRight(_) {
        from.x + from.width
      } else {
        x
      }
      (
        start_x.min(to.x + to.width).min(route_x),
        start_x.max(to.x + to.width).max(route_x),
      )
    }
    RepeatLaneBack(offset) => {
      let (route_x, landing_x) = repeat_lane_return(from, to, offset)
      (
        (from.x + from.width).min(route_x).min(landing_x),
        (from.x + from.width).max(route_x).max(landing_x),
      )
    }
    IfBypassRight(offset) =>
      ((from.x + from.width).min(to.x + to.width), from.x + offset)
    IfEmptyDown => {
      let end = if x == target_x {
        x
      } else if x < target_x {
        to.x
      } else {
        to.x + to.width
      }
      (x.min(end), x.max(end))
    }
    IfChainMerge => (x.min(target_x), x.max(target_x))
    IfDownLeft | SwitchLeft => (from.x.min(target_x), from.x.max(target_x))
    IfDownRight =>
      ((from.x + from.width).min(target_x), (from.x + from.width).max(target_x))
    ForkLane(from_offset, to_offset)
    | ForkSequencePorts(from_offset, to_offset) => {
      let start = from.x + from_offset
      let end = to.x + to_offset
      (start.min(end), start.max(end))
    }
    SwitchMiddle => (x.min(target_x), x.max(target_x))
    SwitchRight => {
      let turn = switch_right_route_x(from, target_x)
      (
        (from.x + from.width).min(target_x).min(turn),
        (from.x + from.width).max(target_x).max(turn),
      )
    }
    SwitchSideMerge => {
      let right = to.x + to.width
      let end = if x < to.x {
        to.x
      } else if x > right {
        right
      } else {
        target_x
      }
      let turn = if x > right && x - right < SWITCH_MERGE_APPROACH {
        x + SWITCH_MERGE_DETOUR
      } else {
        x
      }
      (x.min(end), turn.max(end))
    }
    WhileExitLeft(offset) => {
      let route_x = from.x + offset
      (route_x, from.x.max(target_x))
    }
  }
}
