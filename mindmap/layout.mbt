///|
/// A positioned mindmap item in document coordinates.
pub struct NodeLayout {
  idea_index : Int
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Debug)

///|
/// A cubic parent-to-child connector in document coordinates.
pub struct EdgeLayout {
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
/// Complete geometry for a mindmap SVG.
pub struct MindmapLayout {
  nodes : Array[NodeLayout]
  edges : Array[EdgeLayout]
  width : Int
  height : Int
} derive(Eq, Debug)

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
let node_padding_x = 10

///|
let node_padding_y = 6

///|
let branch_gap = 35

///|
let outer_padding = 12

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
  self.tee.full_thickness() / 2
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
fn MindmapDiagram::children_of(
  self : MindmapDiagram,
  parent : Int,
  direction : Direction,
) -> Array[Int] {
  let children = []
  for index, idea in self.ideas {
    if idea.parent == Some(parent) && idea.direction == direction {
      children.push(index)
    }
  }
  children
}

///|
fn MindmapDiagram::node_size(self : MindmapDiagram, index : Int) -> (Int, Int) {
  let idea = self.ideas[index]
  let metrics = @metrics.measure_text_with(
    idea.label,
    self.style.font_metrics(),
  )
  match idea.shape {
    Box =>
      (metrics.width + node_padding_x * 2, metrics.height + node_padding_y * 2)
    None => (metrics.width + 3, metrics.height + 2)
  }
}

///|
fn contact(frontier : Array[Stripe], start : Int, end : Int) -> Int {
  let mut result = -1_000_000_000
  for stripe in frontier {
    if stripe.end > start && stripe.start < end {
      result = result.max(stripe.value)
    }
  }
  result
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
        result.push({ start: stripe.start, end: start, value: stripe.value })
      }
      result.push({
        start: stripe.start.max(start),
        end: stripe.end.min(end),
        value: stripe.value.max(value),
      })
      if stripe.end > end {
        result.push({ start: end, end: stripe.end, value: stripe.value })
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
  let half1 = tee.thickness1 / 2
  let half2 = tee.thickness2 / 2
  let y = if first {
    0
  } else {
    let first = contact(frontier, 0, tee.elongation1) + half1
    let second = contact(frontier, tee.elongation1, tee.full_elongation()) +
      half2
    first.max(second)
  }
  let positioned = { tee, y }
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
  guard !tees.is_empty() else { { positions: [], width: 0, height: 0 } }
  let mut frontier = [{ start: 0, end: 1_000_000_000, value: -1_000_000_000 }]
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
fn MindmapDiagram::finger_tee(
  self : MindmapDiagram,
  index : Int,
  direction : Direction,
) -> Tee {
  let (width, height) = self.node_size(index)
  let child_tees = self
    .children_of(index, direction)
    .map(child => self.finger_tee(child, direction))
  let packed = pack_tees(child_tees)
  if packed.positions.is_empty() {
    { thickness1: height, elongation1: width, thickness2: 0, elongation2: 0 }
  } else {
    {
      thickness1: height,
      elongation1: width,
      thickness2: packed.height,
      elongation2: branch_gap + packed.width,
    }
  }
}

///|
fn append_finger(
  diagram : MindmapDiagram,
  index : Int,
  direction : Direction,
  origin_x : Int,
  origin_y : Int,
  draw_node : Bool,
  nodes : Array[NodeLayout],
  edges : Array[EdgeLayout],
) -> Unit {
  let (width, height) = diagram.node_size(index)
  let sign = match direction {
    Right => 1
    Left => -1
  }
  if draw_node {
    nodes.push({
      idea_index: index,
      x: if direction is Right {
        origin_x
      } else {
        origin_x - width
      },
      y: origin_y - height / 2,
      width,
      height,
    })
  }
  let children = diagram.children_of(index, direction)
  let packed = pack_tees(
    children.map(child => diagram.finger_tee(child, direction)),
  )
  for child_index, child in children {
    let child_y = origin_y + packed.positions[child_index].y
    let child_x = origin_x + sign * (width + branch_gap)
    edges.push({
      parent_index: index,
      child_index: child,
      x1: origin_x + sign * width,
      y1: origin_y,
      control1_x: origin_x + sign * (width + 25),
      control1_y: origin_y,
      control2_x: child_x - sign * 25,
      control2_y: child_y,
      x2: child_x,
      y2: child_y,
    })
    append_finger(
      diagram, child, direction, child_x, child_y, true, nodes, edges,
    )
  }
}

///|
fn MindmapLayout::translated(
  self : MindmapLayout,
  dx : Int,
  dy : Int,
) -> MindmapLayout {
  {
    ..self,
    nodes: self.nodes.map(node => { ..node, x: node.x + dx, y: node.y + dy }),
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
/// Calculate PlantUML-style, symmetric mindmap geometry without rendering it.
pub fn MindmapDiagram::layout(self : MindmapDiagram) -> MindmapLayout {
  guard !self.ideas.is_empty() else {
    {
      nodes: [],
      edges: [],
      width: outer_padding * 2,
      height: outer_padding * 2,
    }
  }
  let nodes = []
  let edges = []
  let mut next_y = 0
  for root_index, root in self.ideas {
    guard root.parent is None else { continue }
    let left = self.finger_tee(root_index, Left)
    let right = self.finger_tee(root_index, Right)
    let root_height = left.full_thickness().max(right.full_thickness())
    let root_y = next_y + root_height / 2
    append_finger(self, root_index, Right, 0, root_y, true, nodes, edges)
    append_finger(self, root_index, Left, 0, root_y, false, nodes, edges)
    next_y += root_height + outer_padding * 2
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
    width: max_x - min_x + outer_padding * 2,
    height: max_y - min_y + outer_padding * 2,
  }.translated(outer_padding - min_x, outer_padding - min_y)
}
