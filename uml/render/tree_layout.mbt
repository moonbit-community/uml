///|
/// The branch gap between a tree item and its packed children.
const MINDMAP_BRANCH_GAP : Int = 30

///|
/// A positioned tree item in document coordinates, shared by the tree
/// diagram families (mindmap, WBS, mbti).
pub(all) struct NodeLayout {
  index : Int
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Debug)

///|
pub extend NodeLayout with Eq::{not_equal, equal}

///|
pub extend NodeLayout with Debug::{to_repr}

///|
/// A cubic parent-to-child connector in document coordinates.
pub(all) struct EdgeLayout {
  parent_index : Int
  child_index : Int
  x1 : Int
  y1 : Int
  control1_x : Int
  control1_y : Int
  control2_x : Int
  control2_y : Int
  x2 : Int
  y2 : Int
} derive(Eq, Debug)

///|
pub extend EdgeLayout with Eq::{not_equal, equal}

///|
pub extend EdgeLayout with Debug::{to_repr}

///|
/// Complete geometry for a mindmap-style (tee-packed) SVG.
pub(all) struct MindmapLayout {
  nodes : Array[NodeLayout]
  edges : Array[EdgeLayout]
  width : Int
  height : Int
} derive(Eq, Debug)

///|
/// A generic tree node for the mindmap packing algorithm: its size, margins,
/// and children per side. Both the mindmap and the mbti families build this
/// structure and pack it with `layout_tree`.
pub(all) struct LayoutItem {
  width : Int
  height : Int
  margin_left : Int
  margin_right : Int
  margin_top : Int
  margin_bottom : Int
  left_children : Array[Int]
  right_children : Array[Int]
} derive(Eq, Debug)

///|
pub extend LayoutItem with Eq::{not_equal, equal}

///|
pub extend LayoutItem with Debug::{to_repr}

///|
pub extend MindmapLayout with Eq::{not_equal, equal}

///|
pub extend MindmapLayout with Debug::{to_repr}

///|
priv struct Tee {
  thickness1 : Int
  elongation1 : Int
  thickness2 : Int
  elongation2 : Int
}

///|
priv struct PositionedTee {
  tee : Tee
  y : Int
}

///|
priv struct Stripe {
  start : Int
  end : Int
  value : Int
}

///|
priv struct TetrisLayout {
  positions : Array[PositionedTee]
  width : Int
  height : Int
}

///|
let outer_padding_x = 10

///|
let outer_padding_y = 20

///|
fn Tee::full_thickness(self : Tee) -> Int {
  self.thickness1.max(self.thickness2)
}

///|
fn Tee::full_elongation(self : Tee) -> Int {
  self.elongation1 + self.elongation2
}

///|
fn PositionedTee::half_thickness(self : PositionedTee) -> Int {
  (self.tee.full_thickness() + 1) / 2
}

///|
fn PositionedTee::min_y(self : PositionedTee) -> Int {
  self.y - self.half_thickness()
}

///|
fn PositionedTee::max_y(self : PositionedTee) -> Int {
  self.y + self.half_thickness()
}

///|
fn contact(frontier : Array[Stripe], start : Int, end : Int) -> Int {
  frontier.fold(init=-1_000_000_000, (result, stripe) => {
    if stripe.end > start && stripe.start < end {
      result.max(stripe.value)
    } else {
      result
    }
  })
}

///|
fn add_frontier_segment(
  frontier : Array[Stripe],
  start : Int,
  end : Int,
  value : Int,
) -> Array[Stripe] {
  guard end > start else { frontier }
  let result = []
  for stripe in frontier {
    if stripe.end <= start || stripe.start >= end {
      result.push(stripe)
    } else {
      if stripe.start < start {
        result.push({ start: stripe.start, end: start, value: stripe.value, })
      }
      result.push({
        start: stripe.start.max(start),
        end: stripe.end.min(end),
        value: stripe.value.max(value),
      })
      if stripe.end > end {
        result.push({ start: end, end: stripe.end, value: stripe.value, })
      }
    }
  }
  result
}

///|
fn append_tee(
  frontier : Array[Stripe],
  tee : Tee,
  first : Bool,
) -> (Array[Stripe], PositionedTee) {
  let half1 = (tee.thickness1 + 1) / 2
  let half2 = (tee.thickness2 + 1) / 2
  let y = if first {
    0
  } else {
    let first = contact(frontier, 0, tee.elongation1) + half1
    let second = contact(frontier, tee.elongation1, tee.full_elongation()) +
      half2
    first.max(second)
  }
  let positioned = { tee, y, }
  let mut next = add_frontier_segment(frontier, 0, tee.elongation1, y + half1)
  next = add_frontier_segment(
    next,
    tee.elongation1,
    tee.full_elongation(),
    y + half2,
  )
  (next, positioned)
}

///|
fn pack_tees(tees : Array[Tee]) -> TetrisLayout {
  guard !tees.is_empty() else { { positions: [], width: 0, height: 0, } }
  let mut frontier = [{ start: 0, end: 1_000_000_000, value: -1_000_000_000, }]
  let positions = []
  for tee in tees {
    let (next_frontier, positioned) = append_tee(
      frontier,
      tee,
      positions.is_empty(),
    )
    frontier = next_frontier
    positions.push(positioned)
  }
  let mut min_y = positions[0].min_y()
  let mut max_y = positions[0].max_y()
  let mut width = 0
  for positioned in positions {
    min_y = min_y.min(positioned.min_y())
    max_y = max_y.max(positioned.max_y())
    width = width.max(positioned.tee.full_elongation())
  }
  let center = (min_y + max_y) / 2
  {
    positions: positions.map(positioned => {
      ..positioned,
      y: positioned.y - center,
    }),
    width,
    height: max_y - min_y,
  }
}

///|
fn item_children(
  items : Array[LayoutItem],
  index : Int,
  direction : @tree.TreeDirection,
) -> Array[Int] {
  match direction {
    @tree.TreeDirection::Left => items[index].left_children
    @tree.TreeDirection::Right => items[index].right_children
  }
}

///|
fn item_thickness(item : LayoutItem) -> Int {
  item.height + item.margin_top + item.margin_bottom
}

///|
fn item_branch_gap(item : LayoutItem) -> Int {
  item.margin_left + item.margin_right + MINDMAP_BRANCH_GAP
}

///|
fn finger_tee(
  items : Array[LayoutItem],
  index : Int,
  direction : @tree.TreeDirection,
) -> Tee {
  let item = items[index]
  let thickness = item_thickness(item)
  let child_tees = item_children(items, index, direction).map(child => {
    finger_tee(items, child, direction)
  })
  let packed = pack_tees(child_tees)
  if packed.positions.is_empty() {
    {
      thickness1: thickness,
      elongation1: item.width,
      thickness2: 0,
      elongation2: 0,
    }
  } else {
    {
      thickness1: thickness,
      elongation1: item.width + item.margin_left,
      thickness2: packed.height,
      elongation2: item.margin_right + MINDMAP_BRANCH_GAP + packed.width,
    }
  }
}

///|
/// This matches PlantUML's reverse root when both branches are present: its
/// phalanx is hidden, but its children still participate in packing.
fn hidden_finger_tee(
  items : Array[LayoutItem],
  index : Int,
  direction : @tree.TreeDirection,
) -> Tee {
  let item = items[index]
  let packed = pack_tees(
    item_children(items, index, direction).map(child => {
      finger_tee(items, child, direction)
    }),
  )
  {
    thickness1: 0,
    elongation1: item.margin_left,
    thickness2: packed.height,
    elongation2: item.margin_right + MINDMAP_BRANCH_GAP + packed.width,
  }
}

///|
fn append_finger(
  items : Array[LayoutItem],
  index : Int,
  direction : @tree.TreeDirection,
  origin_x : Int,
  origin_y : Int,
  draw_node : Bool,
  nodes : Array[NodeLayout],
  edges : Array[EdgeLayout],
) -> Unit {
  let item = items[index]
  let width = item.width
  let height = item.height
  let phalanx_width = if draw_node { width } else { 0 }
  let branch_gap = item_branch_gap(item)
  let sign = match direction {
    @tree.TreeDirection::Right => 1
    @tree.TreeDirection::Left => -1
  }
  if draw_node {
    nodes.push({
      index,
      x: if direction is @tree.TreeDirection::Right {
        origin_x
      } else {
        origin_x - width
      },
      y: origin_y - height / 2,
      width,
      height,
    })
  }
  let children = item_children(items, index, direction)
  let packed = pack_tees(
    children.map(child => finger_tee(items, child, direction)),
  )
  for child_index, child in children {
    let child_y = origin_y + packed.positions[child_index].y
    let child_x = origin_x + sign * (phalanx_width + branch_gap)
    edges.push({
      parent_index: index,
      child_index: child,
      x1: origin_x + sign * phalanx_width,
      y1: origin_y,
      control1_x: origin_x + sign * (phalanx_width + 25),
      control1_y: origin_y,
      control2_x: child_x - sign * 25,
      control2_y: child_y,
      x2: child_x,
      y2: child_y,
    })
    append_finger(items, child, direction, child_x, child_y, true, nodes, edges)
  }
}

///|
/// Translate a list of positioned nodes by a fixed offset. Shared by the
/// tree layout families to place their content inside the document padding.
pub fn translate_nodes(
  nodes : Array[NodeLayout],
  dx : Int,
  dy : Int,
) -> Array[NodeLayout] {
  nodes.map(node => { ..node, x: node.x + dx, y: node.y + dy, })
}

///|
fn MindmapLayout::translated(
  self : MindmapLayout,
  dx : Int,
  dy : Int,
) -> MindmapLayout {
  {
    ..self,
    nodes: translate_nodes(self.nodes, dx, dy),
    edges: self.edges.map(edge => {
      ..edge,
      x1: edge.x1 + dx,
      y1: edge.y1 + dy,
      control1_x: edge.control1_x + dx,
      control1_y: edge.control1_y + dy,
      control2_x: edge.control2_x + dx,
      control2_y: edge.control2_y + dy,
      x2: edge.x2 + dx,
      y2: edge.y2 + dy,
    }),
  }
}

///|
/// Calculate PlantUML-style, symmetric mindmap geometry for a generic tree.
///
/// Each item carries its own size, margins, and per-side children; `roots`
/// lists the item indices with no parent, stacked vertically.
pub fn layout_tree(
  items : Array[LayoutItem],
  roots : Array[Int],
) -> MindmapLayout {
  guard !items.is_empty() else {
    {
      nodes: [],
      edges: [],
      width: outer_padding_x * 2,
      height: outer_padding_y * 2,
    }
  }
  let nodes = []
  let edges = []
  let mut next_y = outer_padding_y
  for root_index in roots {
    let has_left_children = !items[root_index].left_children.is_empty()
    let has_right_children = !items[root_index].right_children.is_empty()
    let left = if has_left_children {
      if has_right_children {
        hidden_finger_tee(items, root_index, @tree.TreeDirection::Left)
      } else {
        finger_tee(items, root_index, @tree.TreeDirection::Left)
      }
    } else {
      { thickness1: 0, elongation1: 0, thickness2: 0, elongation2: 0, }
    }
    let right = if has_right_children || !has_left_children {
      finger_tee(items, root_index, @tree.TreeDirection::Right)
    } else {
      { thickness1: 0, elongation1: 0, thickness2: 0, elongation2: 0, }
    }
    let root_height = left.full_thickness().max(right.full_thickness())
    // PlantUML places the root at the vertical center of its content, which
    // is the tee span minus the node margins; consecutive roots start where
    // the previous root's content ends, plus the outer padding.
    let item = items[root_index]
    let margin_top = item.margin_top
    let margin_bottom = item.margin_bottom
    let content_half = (root_height - margin_top - margin_bottom) / 2
    let root_y = next_y + content_half
    if has_left_children && has_right_children {
      append_finger(
        items,
        root_index,
        @tree.TreeDirection::Right,
        0,
        root_y,
        true,
        nodes,
        edges,
      )
      append_finger(
        items,
        root_index,
        @tree.TreeDirection::Left,
        0,
        root_y,
        false,
        nodes,
        edges,
      )
    } else if has_left_children {
      append_finger(
        items,
        root_index,
        @tree.TreeDirection::Left,
        0,
        root_y,
        true,
        nodes,
        edges,
      )
    } else {
      append_finger(
        items,
        root_index,
        @tree.TreeDirection::Right,
        0,
        root_y,
        true,
        nodes,
        edges,
      )
    }
    next_y = root_y + content_half + outer_padding_y
  }
  let mut min_x = nodes[0].x
  let mut min_y = nodes[0].y
  let mut max_x = nodes[0].x + nodes[0].width
  let mut max_y = nodes[0].y + nodes[0].height
  for node in nodes {
    min_x = min_x.min(node.x)
    min_y = min_y.min(node.y)
    max_x = max_x.max(node.x + node.width)
    max_y = max_y.max(node.y + node.height)
  }
  {
    nodes,
    edges,
    width: max_x - min_x + outer_padding_x * 2,
    height: max_y - min_y + outer_padding_y * 2,
  }.translated(outer_padding_x - min_x, outer_padding_y - min_y)
}
