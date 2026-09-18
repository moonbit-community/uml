///|
fn append_layout_edge(
  edges : Array[ActivityEdgeLayout],
  from_node_index : Int?,
  to_node_index : Int?,
  route : ActivityEdgeRoute,
  label? : String? = None,
) -> Unit {
  guard from_node_index is Some(from_node_index) else { return }
  guard to_node_index is Some(to_node_index) else { return }
  edges.push({ from_node_index, to_node_index, route, label, })
}

///|
fn goto_target(
  nodes : Array[@flow.ActivityNode],
  layouts : Array[ActivityNodeLayout],
  label : String,
) -> Int? {
  for index, node in nodes {
    guard node is @flow.ActivityNode::Label(candidate) && candidate == label else {
      continue
    }
    return layout_for_node(layouts, index)
  }
  None
}

///|
fn append_goto_edges(
  nodes : Array[@flow.ActivityNode],
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Unit {
  for index, node in nodes {
    guard node is Goto(label) else { continue }
    append_layout_edge(
      edges,
      layout_for_node(layouts, index),
      goto_target(nodes, layouts, label),
      Goto,
    )
  }
}

///|
fn layout_for_node(
  layouts : Array[ActivityNodeLayout],
  node_index : Int,
) -> Int? {
  for layout in layouts {
    guard layout.node_index == node_index else { continue }
    return Some(node_index)
  }
  None
}

///|
fn swimlane_for_node(
  nodes : Array[@flow.ActivityNode],
  node_index : Int,
) -> String? {
  for index = node_index.min(nodes.length() - 1); index >= 0; index = index - 1 {
    guard nodes[index] is @flow.ActivityNode::Swimlane(name) else { continue }
    return Some(name)
  }
  None
}

///|
fn swimlane_names(nodes : Array[@flow.ActivityNode]) -> Array[String] {
  let names = []
  for node in nodes {
    guard node is @flow.ActivityNode::Swimlane(name) else { continue }
    guard !names.contains(name) else { continue }
    names.push(name)
  }
  names
}

///|
fn swimlane_index(names : Array[String], name : String) -> Int? {
  for index, candidate in names {
    guard candidate == name else { continue }
    return Some(index)
  }
  None
}

///|
/// Like Swimlanes.computeSizeInternal, translate each lane from its complete
/// horizontal extent. Centering individual nodes would collapse branches.
fn reposition_swimlanes(
  nodes : Array[@flow.ActivityNode],
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
  metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
  height : Int,
) -> Array[ActivityRegionLayout] {
  let names = swimlane_names(nodes)
  // Swimlanes.drawU uses the ordinary layout for zero or one named lane.
  guard names.length() > 1 else { return [] }
  preserve_fork_lane_ports(nodes, layouts, edges)
  let bounds : Array[(Int, Int)?] = names.map(_ => None)
  for layout in layouts {
    guard swimlane_for_node(nodes, layout.node_index) is Some(name) else {
      continue
    }
    let index = swimlane_index(names, name).unwrap()
    bounds[index] = Some(
      bounds[index].map_or((layout.x, layout.x + layout.width), extent => {
        (extent.0.min(layout.x), extent.1.max(layout.x + layout.width))
      }),
    )
  }
  // UGraphicInterceptorOneSwimlane draws links whose endpoints share the lane.
  // Their text participates in the same min/max bounds as the node shapes.
  for edge in edges {
    guard swimlane_for_node(nodes, edge.from_node_index) is Some(name) &&
      swimlane_for_node(nodes, edge.to_node_index) == Some(name) else {
      continue
    }
    let from = layouts[layouts
      .search_by(node => node.node_index == edge.from_node_index)
      .unwrap()]
    let to = layouts[layouts
      .search_by(node => node.node_index == edge.to_node_index)
      .unwrap()]
    let (path_left, path_right) = activity_edge_x_bounds(edge, from, to, nodes)
    let (left, right) = edge.label.map_or((path_left, path_right), label => {
      let (left, right) = activity_edge_label_bounds(
        edge, label, from, to, nodes, small_metrics,
      )
      (path_left.min(left), path_right.max(right))
    })
    let index = swimlane_index(names, name).unwrap()
    let extent = bounds[index].unwrap()
    bounds[index] = Some((extent.0.min(left), extent.1.max(right)))
  }
  let titles = names.map(activity_display_text)
  let widths = []
  for index, _ in names {
    let content_width = bounds[index].map_or(0, extent => extent.1 - extent.0)
    widths.push(
      content_width.max(metrics.measure(titles[index]).width) +
      REGION_PADDING * 2,
    )
  }
  let positions = []
  let mut cursor_x = CANVAS_LEFT
  for width in widths {
    positions.push(cursor_x)
    cursor_x += width + SWIMLANE_GAP
  }
  let shifts = nodes.map(_ => 0)
  for index, layout in layouts {
    guard swimlane_for_node(nodes, layout.node_index) is Some(name) else {
      continue
    }
    guard swimlane_index(names, name) is Some(lane_index) else { continue }
    let (left, right) = bounds[lane_index].unwrap()
    let shift = positions[lane_index] +
      (widths[lane_index] - (right - left)) / 2 -
      left
    shifts[layout.node_index] = shift
    layouts[index] = {
      node_index: layout.node_index,
      x: layout.x + shift,
      y: layout.y,
      width: layout.width,
      height: layout.height,
    }
  }
  // FtileWhile.ConnectionBackSimple translates the outer corridor by the
  // larger endpoint shift, so the return stays outside both lane contents.
  for index, edge in edges {
    guard edge.route is BackwardRight(offset, _) &&
      swimlane_for_node(nodes, edge.from_node_index) !=
      swimlane_for_node(nodes, edge.to_node_index) else {
      continue
    }
    let from_shift = shifts[edge.from_node_index]
    let to_shift = shifts[edge.to_node_index]
    edges[index] = {
      ..edge,
      route: BackwardRight(
        offset + from_shift.max(to_shift) - to_shift,
        DIAMOND_TEXT_PADDING / 2,
      ),
    }
  }
  let regions = []
  for index, title in titles {
    regions.push({
      kind: Swimlane,
      label: title,
      x: positions[index],
      y: CANVAS_TOP,
      width: widths[index],
      height,
    })
  }
  regions
}

///|
fn partition_regions(
  nodes : Array[@flow.ActivityNode],
  layouts : Array[ActivityNodeLayout],
) -> Array[ActivityRegionLayout] {
  let regions = []
  for index, node in nodes {
    match node {
      Partition(_) =>
        for layout in layouts {
          guard layout.node_index == index else { continue }
          regions.push({
            kind: Partition,
            label: node.label().unwrap(),
            x: layout.x,
            y: layout.y,
            width: layout.width,
            height: layout.height,
          })
        }
      _ => ()
    }
  }
  regions
}

///|
/// Keep each port relative to its own node before lanes translate independently.
fn preserve_fork_lane_ports(
  nodes : Array[@flow.ActivityNode],
  layouts : Array[ActivityNodeLayout],
  edges : Array[ActivityEdgeLayout],
) -> Unit {
  for index, edge in edges {
    guard edge.route is Forward else { continue }
    let from_fork = nodes[edge.from_node_index].is_fork()
    let to_fork = nodes[edge.to_node_index].is_fork()
    guard from_fork || to_fork else { continue }
    guard swimlane_for_node(nodes, edge.from_node_index) !=
      swimlane_for_node(nodes, edge.to_node_index) else {
      continue
    }
    let from = layouts[layouts
      .search_by(node => node.node_index == edge.from_node_index)
      .unwrap()]
    let to = layouts[layouts
      .search_by(node => node.node_index == edge.to_node_index)
      .unwrap()]
    let port_x = if nodes[edge.from_node_index] is @flow.ActivityNode::Fork {
      to.x + to.width / 2
    } else {
      from.x + from.width / 2
    }
    edges[index] = { ..edge, route: ForkLane(port_x - from.x, port_x - to.x), }
  }
}
