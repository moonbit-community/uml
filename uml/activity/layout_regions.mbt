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
  edges.push({ from_node_index, to_node_index, route, label })
}

///|
fn goto_target(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
  label : String,
) -> Int? {
  for index, node in nodes {
    guard node is ActivityNode::Label(candidate) && candidate == label else {
      continue
    }
    return layout_for_node(layouts, index)
  }
  None
}

///|
fn append_goto_edges(
  nodes : Array[ActivityNode],
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
fn region_for(
  layouts : Array[ActivityNodeLayout],
  kind : ActivityRegionKind,
  label : String,
  select : (ActivityNodeLayout) -> Bool,
) -> ActivityRegionLayout? {
  let mut min_x : Int? = None
  let mut min_y : Int? = None
  let mut max_x : Int? = None
  let mut max_y : Int? = None
  for layout in layouts {
    guard select(layout) else { continue }
    min_x = Some(min_x.map(value => value.min(layout.x)).unwrap_or(layout.x))
    min_y = Some(min_y.map(value => value.min(layout.y)).unwrap_or(layout.y))
    max_x = Some(
      max_x
      .map(value => value.max(layout.x + layout.width))
      .unwrap_or(layout.x + layout.width),
    )
    max_y = Some(
      max_y
      .map(value => value.max(layout.y + layout.height))
      .unwrap_or(layout.y + layout.height),
    )
  }
  match (min_x, min_y, max_x, max_y) {
    (Some(min_x), Some(min_y), Some(max_x), Some(max_y)) =>
      Some({
        kind,
        label,
        x: min_x - REGION_PADDING,
        y: min_y - REGION_HEADER_HEIGHT - REGION_PADDING,
        width: max_x - min_x + REGION_PADDING * 2,
        height: max_y - min_y + REGION_HEADER_HEIGHT + REGION_PADDING * 2,
      })
    _ => None
  }
}

///|
fn region_for_range(
  layouts : Array[ActivityNodeLayout],
  start : Int,
  end : Int,
  kind : ActivityRegionKind,
  label : String,
) -> ActivityRegionLayout? {
  region_for(layouts, kind, label, layout => {
    layout.node_index > start && layout.node_index < end
  })
}

///|
fn swimlane_for_node(nodes : Array[ActivityNode], node_index : Int) -> String? {
  for index = node_index.min(nodes.length() - 1); index >= 0; index = index - 1 {
    guard nodes[index] is ActivityNode::Swimlane(name) else { continue }
    return Some(name)
  }
  None
}

///|
fn swimlane_names(nodes : Array[ActivityNode]) -> Array[String] {
  let names = []
  for node in nodes {
    guard node is ActivityNode::Swimlane(name) else { continue }
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
fn reposition_swimlanes(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
) -> Int {
  let names = swimlane_names(nodes)
  guard !names.is_empty() else { return 0 }
  let widths = names.map(_ => REGION_PADDING * 2)
  for layout in layouts {
    guard swimlane_for_node(nodes, layout.node_index) is Some(name) else {
      continue
    }
    guard swimlane_index(names, name) is Some(index) else { continue }
    widths[index] = widths[index].max(layout.width + REGION_PADDING * 2)
  }
  let positions = []
  let mut cursor_x = CANVAS_LEFT
  for width in widths {
    positions.push(cursor_x)
    cursor_x += width + SWIMLANE_GAP
  }
  for index, layout in layouts {
    guard swimlane_for_node(nodes, layout.node_index) is Some(name) else {
      continue
    }
    guard swimlane_index(names, name) is Some(lane_index) else { continue }
    layouts[index] = {
      node_index: layout.node_index,
      x: positions[lane_index] + (widths[lane_index] - layout.width) / 2,
      y: layout.y,
      width: layout.width,
      height: layout.height,
    }
  }
  cursor_x - SWIMLANE_GAP + CANVAS_LEFT
}

///|
fn region_for_swimlane(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
  label : String,
) -> ActivityRegionLayout? {
  region_for(layouts, ActivityRegionKind::Swimlane, label, layout => {
    swimlane_for_node(nodes, layout.node_index) is Some(name) && name == label
  })
}

///|
fn regions_from_nodes(
  nodes : Array[ActivityNode],
  layouts : Array[ActivityNodeLayout],
) -> Array[ActivityRegionLayout] {
  let regions = []
  let seen_swimlanes = []
  for index, node in nodes {
    match node {
      Swimlane(label) => {
        guard !seen_swimlanes.contains(label) else { continue }
        seen_swimlanes.push(label)
        guard region_for_swimlane(nodes, layouts, label) is Some(region) else {
          continue
        }
        regions.push(region)
      }
      Partition(label) => {
        let end = partition_end(nodes, index)
        guard region_for_range(
            layouts,
            index,
            end,
            ActivityRegionKind::Partition,
            label,
          )
          is Some(region) else {
          continue
        }
        regions.push(region)
      }
      _ => ()
    }
  }
  regions
}

///|
fn partition_end(nodes : Array[ActivityNode], index : Int) -> Int {
  for next = index + 1; next < nodes.length(); next = next + 1 {
    guard nodes[next] is EndPartition else { continue }
    return next
  }
  nodes.length()
}
