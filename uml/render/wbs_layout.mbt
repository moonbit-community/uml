///|
/// Fork.delta1x, Fork.deltay, ITFComposed.delta1x, and WBSDiagram.drawU.
const WBS_FORK_GAP : Double = 20.0

///|
const WBS_FORK_DROP : Double = 40.0

///|
const WBS_BRANCH_GAP : Double = 10.0

///|
const WBS_CANVAS_MARGIN : Double = 10.0

///|
/// A WBS main box, retaining half-pixel attachment coordinates.
pub(all) struct WbsNodeLayout {
  index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
/// One shared bus or branch segment, styled by its owning parent.
pub(all) struct WbsLineLayout {
  owner : Int
  start : @graphics.Point
  end : @graphics.Point
} derive(Eq, Debug)

///|
/// The Fork/ITF layout, before document title, legend, and scale wrappers.
pub(all) struct WbsLayout {
  nodes : Array[WbsNodeLayout]
  lines : Array[WbsLineLayout]
  width : Double
  height : Double
} derive(Eq, Debug)

///|
priv struct WbsItem {
  index : Int
  style : @tree.TreeNodeStyle
  label : String
  natural_width : Double
  width : Double
  height : Double
  left : Array[Int]
  right : Array[Int]
}

///|
priv struct WbsTile {
  item : WbsItem
  left : Array[WbsTile]
  right : Array[WbsTile]
  width : Double
  height : Double
  axis : Double
}

///|
fn wbs_items(diagram : @tree.WbsDiagram) -> Array[WbsItem] {
  let left : Array[Array[Int]] = Array::makei(diagram.nodes.length(), _ => [])
  let right : Array[Array[Int]] = Array::makei(diagram.nodes.length(), _ => [])
  for index, node in diagram.nodes {
    guard node.parent is Some(parent) else { continue }
    if node.direction is @tree.TreeDirection::Left {
      left[parent].push(index)
    } else {
      right[parent].push(index)
    }
  }
  // WElement.createElement prepends every left level-one node to the root's
  // right collection; Fork draws that collection in its resulting order.
  if !diagram.nodes.is_empty() {
    right[0] = [..left[0].rev(), ..right[0]]
    left[0] = []
  }
  let items = []
  for index, node in diagram.nodes {
    let style = wbs_node_style(diagram, index)
    let font_size = style.font_size.unwrap_or(@tree.WBS_DEFAULT_FONT_SIZE)
    let metrics = diagram.style.font_metrics(font_size~)
    let label = node.label.replace(old="\\n", new="\n")
    let text = tree_label_metrics(metrics, label)
    let text_width = tree_label_width(metrics, font_size, label).to_double()
    let (width, height) = match node.shape {
      @tree.NodeShape::Pseudo => (0.0, 0.0)
      @tree.NodeShape::Box =>
        (
          (text_width +
          style.padding_x.unwrap_or(@tree.WBS_DEFAULT_PADDING_X).to_double() *
          2.0).max(style.minimum_width.unwrap_or(0).to_double()),
          text.height.to_double() +
          style.padding_y.unwrap_or(@tree.WBS_DEFAULT_PADDING_Y).to_double() *
          2.0,
        )
      @tree.NodeShape::Boxless =>
        (
          text_width + boxless_horizontal_margin.to_double(),
          text.height.to_double() + boxless_vertical_margin.to_double() * 2.0,
        )
    }
    items.push({
      index,
      style,
      label,
      natural_width: width,
      width,
      height,
      left: left[index],
      right: right[index],
    })
  }
  // Auto width acts on immediate siblings before their subtrees are measured.
  // Composed boxless/pseudo blocks cannot be forced; ITFLeaf can be.
  for item in items {
    guard item.style.width_auto.unwrap_or(false) else { continue }
    let children = [..item.left, ..item.right]
    let width = children.fold(init=0.0, (width, child) => {
      width.max(items[child].natural_width)
    })
    for child in children {
      let candidate = items[child]
      if diagram.nodes[child].shape is @tree.NodeShape::Box ||
        (candidate.left.is_empty() && candidate.right.is_empty()) {
        items[child] = { ..candidate, width: candidate.width.max(width), }
      }
    }
  }
  items
}

///|
fn wbs_tile(
  items : Array[WbsItem],
  index : Int,
  diagram : @tree.WbsDiagram,
) -> WbsTile {
  let item = items[index]
  let left = item.left.map(child => wbs_tile(items, child, diagram))
  let right = item.right.map(child => wbs_tile(items, child, diagram))
  guard !left.is_empty() || !right.is_empty() else {
    return {
      item,
      left,
      right,
      width: item.width,
      height: item.height,
      axis: item.width / 2.0,
    }
  }
  let gap = wbs_child_margin(diagram, item)
  let left_width = left.fold(init=0.0, (width, tile) => width.max(tile.width))
  let right_width = right.fold(init=0.0, (width, tile) => width.max(tile.width))
  let left_height = left.fold(init=0.0, (height, tile) => {
    height + gap + tile.height
  })
  let right_height = right.fold(init=0.0, (height, tile) => {
    height + gap + tile.height
  })
  let axis = (item.width / 2.0).max(WBS_BRANCH_GAP + left_width)
  {
    item,
    left,
    right,
    axis,
    width: axis + (item.width / 2.0).max(WBS_BRANCH_GAP + right_width),
    height: item.height + left_height.max(right_height),
  }
}

///|
fn wbs_child_margin(diagram : @tree.WbsDiagram, item : WbsItem) -> Double {
  if diagram.nodes[item.index].shape is @tree.NodeShape::Pseudo {
    0.0
  } else {
    item.style.margin_bottom.unwrap_or(@tree.WBS_DEFAULT_MARGIN).to_double()
  }
}

///|
fn wbs_line(
  lines : Array[WbsLineLayout],
  owner : Int,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Unit {
  lines.push({ owner, start: { x: x1, y: y1, }, end: { x: x2, y: y2, }, })
}

///|
fn place_wbs_tile(
  tile : WbsTile,
  diagram : @tree.WbsDiagram,
  x : Double,
  y : Double,
  nodes : Array[WbsNodeLayout],
  lines : Array[WbsLineLayout],
) -> Unit {
  let item = tile.item
  let axis = x + tile.axis
  nodes.push({
    index: item.index,
    x: axis - item.width / 2.0,
    y,
    width: item.width,
    height: item.height,
  })
  guard !tile.left.is_empty() || !tile.right.is_empty() else { return }
  let gap = wbs_child_margin(diagram, item)
  let mut last_y = y + item.height
  for side in [@tree.TreeDirection::Left, @tree.TreeDirection::Right] {
    let children = if side is @tree.TreeDirection::Left {
      tile.left
    } else {
      tile.right
    }
    let mut child_y = y + item.height
    for child in children {
      child_y += gap
      let child_x = if side is @tree.TreeDirection::Left {
        axis - WBS_BRANCH_GAP - child.width
      } else {
        axis + WBS_BRANCH_GAP
      }
      let port_x = child_x +
        child.axis +
        (if side is @tree.TreeDirection::Left {
          child.item.width / 2.0
        } else {
          -child.item.width / 2.0
        })
      let port_y = child_y + child.item.height / 2.0
      wbs_line(
        lines,
        item.index,
        axis.min(port_x),
        port_y,
        axis.max(port_x),
        port_y,
      )
      place_wbs_tile(child, diagram, child_x, child_y, nodes, lines)
      last_y = last_y.max(port_y)
      child_y += child.height
    }
  }
  wbs_line(lines, item.index, axis, y + item.height, axis, last_y)
}

///|
fn layout_wbs_items(
  diagram : @tree.WbsDiagram,
  items : Array[WbsItem],
) -> WbsLayout {
  guard !items.is_empty() else {
    return {
      nodes: [],
      lines: [],
      width: WBS_CANVAS_MARGIN * 2.0,
      height: WBS_CANVAS_MARGIN * 2.0,
    }
  }
  let root = items[0]
  let children = root.right.map(child => wbs_tile(items, child, diagram))
  let children_width = children.fold(init=0.0, (width, tile) => {
      width + tile.width
    }) +
    (children.length() - 1).max(0).to_double() * WBS_FORK_GAP
  let content_width = root.width.max(children_width)
  let content_height = root.height +
    WBS_FORK_DROP +
    children.fold(init=0.0, (height, tile) => height.max(tile.height))
  let nodes = []
  let lines = []
  let y0 = WBS_CANVAS_MARGIN + root.height
  let y1 = y0 + WBS_FORK_DROP / 2.0
  let y2 = y0 + WBS_FORK_DROP
  let mut first_x = WBS_CANVAS_MARGIN + root.width / 2.0
  let mut last_x = first_x
  let mut cursor_x = WBS_CANVAS_MARGIN
  for index, child in children {
    last_x = cursor_x + child.axis
    if index == 0 {
      first_x = last_x
    }
    wbs_line(lines, root.index, last_x, y1, last_x, y2)
    place_wbs_tile(child, diagram, cursor_x, y2, nodes, lines)
    cursor_x += child.width + WBS_FORK_GAP
  }
  let root_x = if children.is_empty() {
    WBS_CANVAS_MARGIN
  } else if last_x > first_x {
    (first_x + last_x - root.width) / 2.0
  } else {
    WBS_CANVAS_MARGIN + (content_width - root.width) / 2.0
  }
  let root_axis = root_x + root.width / 2.0
  nodes.push({
    index: root.index,
    x: root_x,
    y: WBS_CANVAS_MARGIN,
    width: root.width,
    height: root.height,
  })
  if !children.is_empty() {
    wbs_line(
      lines,
      root.index,
      first_x.min(root_axis),
      y1,
      last_x.max(root_axis),
      y1,
    )
  }
  wbs_line(lines, root.index, root_axis, y0, root_axis, y1)
  // Export bounds include the actual drawing: a wide root over several small
  // children can extend left of Fork's nominal dimension.
  let min_x = nodes.fold(init=0.0, (x, node) => {
    x.min(node.x - WBS_CANVAS_MARGIN)
  })
  let max_x = nodes.fold(init=content_width + WBS_CANVAS_MARGIN, (x, node) => {
    x.max(node.x + node.width)
  })
  {
    nodes: nodes.map(node => { ..node, x: node.x - min_x, }),
    lines: lines.map(line => {
      ..line,
      start: { ..line.start, x: line.start.x - min_x, },
      end: { ..line.end, x: line.end.x - min_x, },
    }),
    width: max_x - min_x + WBS_CANVAS_MARGIN,
    height: content_height + WBS_CANVAS_MARGIN * 2.0,
  }
}

///|
/// Lay out a work breakdown tree using PlantUML's root Fork and recursive ITFs.
pub fn layout_wbs(diagram : @tree.WbsDiagram) -> WbsLayout {
  layout_wbs_items(diagram, wbs_items(diagram))
}
