///|
priv enum ActivityConditionShape {
  Hexagon
  InsideDiamond
  EmptyDiamond
} derive(Eq)

///|
/// SkinParam.getConditionStyle / ConditionStyle.fromString. Switch and empty
/// merge nodes use their own factory, not the conditional-shape setting.
fn @flow.ActivityNode::condition_shape(
  self : @flow.ActivityNode,
) -> ActivityConditionShape {
  let style = match self {
    If(value) | ElseIf(value) | While(value) | RepeatWhile(value) => value.style
    _ => return Hexagon
  }
  match style.property("ConditionStyle").unwrap_or("").to_lower() {
    "insidediamond" | "inside_diamond" | "foo1" => InsideDiamond
    "diamond" | "empty_diamond" => EmptyDiamond
    _ => Hexagon
  }
}

///|
/// FtileDiamond allocates the north label above a fixed diamond. Connections
/// attach to the diamond, while layout and occupied bounds retain the label.
fn activity_connection_box(
  node : @flow.ActivityNode,
  layout : ActivityNodeLayout,
) -> ActivityNodeLayout {
  if node.condition_shape() == EmptyDiamond && layout.height > DIAMOND_HEIGHT {
    {
      ..layout,
      y: layout.y + layout.height - DIAMOND_HEIGHT,
      height: DIAMOND_HEIGHT,
    }
  } else {
    layout
  }
}

///|
fn activity_decision_label_bounds(
  node : @flow.ActivityNode,
  layout : ActivityNodeLayout,
) -> (Double, Double)? {
  guard node.condition_shape() == EmptyDiamond &&
    node.activity_decision() is Some(decision) else {
    return None
  }
  let text = activity_measure(
    activity_decision_metrics(decision),
    decision.text,
  )
  let left = layout.x + DIAMOND_TEXT_PADDING * 3 / 4
  Some((left, left + text.width))
}

///|
fn activity_node_drawn_right(
  node : @flow.ActivityNode,
  layout : ActivityNodeLayout,
  metrics : @metrics.FontMetrics,
) -> Double {
  let right = layout.x + layout.width + activity_fork_label_width(node, metrics)
  activity_decision_label_bounds(node, layout).map_or(right, bounds => {
    right.max(bounds.1)
  })
}

///|
/// FtileGroup measures the inner drawing with LimitFinder before adding title
/// space. Use the same placement and painted bounds here, including north
/// decision labels and labels on return edges that exceed the tile width.
fn activity_group_inner_width(
  tiles : Array[Tile],
  nodes : Array[@flow.ActivityNode],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Double {
  let body = measure_sequence(tiles, nodes, metrics, small_metrics)
  let original = body.width + ACTIVITY_GROUP_MARGIN * 2
  let layouts = []
  let edges = []
  ignore(
    place_sequence(
      tiles,
      nodes,
      metrics,
      small_metrics,
      ACTIVITY_GROUP_MARGIN,
      0,
      layouts,
      edges,
    ),
  )
  let right = layout_content_right(layouts, edges, nodes, small_metrics)
  if right > original {
    right + ACTIVITY_GROUP_OVERFLOW_MARGIN
  } else {
    original
  }
}

///|
/// FtileGroup.getInnerDimensionSlow reserves five points after overflow.
const ACTIVITY_GROUP_OVERFLOW_MARGIN : Double = 5.0
