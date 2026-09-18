///|
/// One label position shared by rendering, compression, and canvas bounds.
fn activity_edge_label_position(
  edge : ActivityEdgeLayout,
  label : String,
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
  nodes : Array[@flow.ActivityNode],
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int, @graphics.TextAnchor) {
  let x = from.x + from.width / 2
  let y1 = from.y + from.height
  let target_x = to.x + to.width / 2
  let y2 = to.y
  let from_center_y = from.y + from.height / 2
  let from_is_decision = nodes[edge.from_node_index].is_decision()
  let to_is_fork = nodes[edge.to_node_index].is_fork()
  let to_is_switch_exit = nodes[edge.to_node_index]
    is @flow.ActivityNode::EndSwitch
  match edge.route {
    ForkSequence | IfEmptyDown | SwitchSideMerge | IfChainMerge | WhileEntry =>
      (
        x + EDGE_LABEL_OFFSET,
        y1 + (if from_is_decision { 11 } else { 21 }),
        @graphics.TextAnchor::Start,
      )
    RepeatForward => {
      let (label_x, label_y) = repeat_forward_label_position(from, to, nodes)
      (label_x, label_y, @graphics.TextAnchor::Start)
    }
    ForkLane(from_offset, _) | ForkSequencePorts(from_offset, _) =>
      (
        from.x + from_offset + EDGE_LABEL_OFFSET,
        y1 + (if from_is_decision { 11 } else { 21 }),
        @graphics.TextAnchor::Start,
      )
    Forward =>
      if nodes[edge.from_node_index] is @flow.ActivityNode::Fork {
        (target_x + EDGE_LABEL_OFFSET, y1 + 21, @graphics.TextAnchor::Start)
      } else if (to_is_fork || to_is_switch_exit) && from_is_decision {
        (x + EDGE_LABEL_OFFSET, y1 + 11, @graphics.TextAnchor::Start)
      } else if from_is_decision && target_x != x {
        (target_x + EDGE_LABEL_OFFSET, y1 + 11, @graphics.TextAnchor::Start)
      } else if from_is_decision {
        (target_x + EDGE_LABEL_OFFSET, y1 + 11, @graphics.TextAnchor::Start)
      } else {
        (x + EDGE_LABEL_OFFSET, y1 + 21, @graphics.TextAnchor::Start)
      }
    Horizontal =>
      (
        (from.x + from.width + to.x) / 2,
        from.y + from.height / 2 - 4,
        @graphics.TextAnchor::Middle,
      )
    Goto =>
      ((from.x + to.x) / 2, (from.y + to.y) / 2, @graphics.TextAnchor::Middle)
    BackwardLeft =>
      (
        from.x.min(to.x) - WHILE_BACK_MARGIN,
        (y1 + y2) / 2,
        @graphics.TextAnchor::Middle,
      )
    BackwardRight(_, _) if from_is_decision =>
      (x + EDGE_LABEL_OFFSET, y1 + 11, @graphics.TextAnchor::Start)
    BackwardRight(offset, _) => {
      let route_x = to.x + offset
      (route_x, (y1 + y2) / 2, @graphics.TextAnchor::Middle)
    }
    IfDownLeft | WhileExitLeft(_) =>
      (
        from.x,
        from_center_y - 2 - (line_count(label) - 1) * small_metrics.line_height,
        @graphics.TextAnchor::End,
      )
    IfDownRight
    | IfBypassRight(_)
    | RepeatBackRight(_)
    | RepeatLaneBack(_)
    | IfSideTerminal =>
      (
        from.x + from.width,
        from_center_y - 2 - (line_count(label) - 1) * small_metrics.line_height,
        @graphics.TextAnchor::Start,
      )
    SwitchLeft | SwitchRight | SwitchMiddle =>
      (
        target_x,
        y2 - VERTICAL_GAP - (line_count(label) - 1) * small_metrics.line_height,
        @graphics.TextAnchor::Start,
      )
  }
}

///|
fn activity_edge_label_bounds(
  edge : ActivityEdgeLayout,
  label : String,
  from : ActivityNodeLayout,
  to : ActivityNodeLayout,
  nodes : Array[@flow.ActivityNode],
  small_metrics : @metrics.FontMetrics,
) -> (Int, Int) {
  let (x, _, anchor) = activity_edge_label_position(
    edge, label, from, to, nodes, small_metrics,
  )
  let width = small_metrics.measure(label).width
  let start = match anchor {
    Start => x
    Middle => x - width / 2
    End => x - width
  }
  (start, start + width)
}
