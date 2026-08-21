///|
/// X-compression post-pass mirroring PlantUML's global `CompressionXorYBuilder`
/// (`klimt/compress`): after layout, every empty vertical strip wider than
/// 10px between occupied shapes collapses to a 10px strip and everything to
/// its right shifts left by G-10 (piecewise-affine in x, widths adjust too).
/// Fork bars and their connection edges are `ignoreForCompression` in
/// PlantUML, and switch case edges empirically do not block compression
/// either; all three are excluded from slot collection.

///|
priv struct Slot {
  start : Int
  end : Int
}

///|
/// Shrunken gap: the 5px margin on each side survives, the middle (G-10)
/// collapses completely.
priv struct Gap {
  start : Int
  end : Int
}

///|
/// Horizontal extent of an edge polyline, mirroring the path math in
/// `svg.mbt`. Fork connection edges and switch case edges never block
/// compression, matching PlantUML.
fn edge_x_extent(
  edge : ActivityEdgeLayout,
  layout : ActivityLayout,
) -> (Int, Int)? {
  guard layout_for(layout, edge.from_node_index) is Some(from) else {
    return None
  }
  guard layout_for(layout, edge.to_node_index) is Some(to) else { return None }
  let from_source = layout.source_nodes[edge.from_node_index]
  let to_source = layout.source_nodes[edge.to_node_index]
  guard !from_source.is_fork() && !to_source.is_fork() else { return None }
  let x = from.x + from.width / 2
  let target_x = to.x + to.width / 2
  let from_is_decision = from_source.is_decision()
  let to_is_switch_exit = to_source is ActivityNode::EndSwitch
  let start_end = match edge.route {
    Forward =>
      if to_is_switch_exit {
        // Switch case joins draw like the case edges in PlantUML and do not
        // block compression. (If/elseif joins still do: their reference gaps
        // stay open because rows above span them.)
        return None
      } else if from_is_decision && target_x != x {
        let start_x = if target_x < x { from.x } else { from.x + from.width }
        (start_x.min(target_x), start_x.max(target_x))
      } else {
        (x.min(target_x), x.max(target_x))
      }
    Horizontal => {
      let start = (from.x + from.width).min(to.x)
      (start, (from.x + from.width).max(to.x))
    }
    Goto => (from.x.min(to.x), from.x.max(to.x))
    BackwardLeft => {
      let route_x = from.x.min(to.x) - WHILE_BACK_MARGIN
      (route_x, x.max(target_x))
    }
    BackwardRight => {
      let route_x = (from.x + from.width).max(to.x + to.width) +
        WHILE_BACK_MARGIN
      (x.min(target_x), route_x)
    }
    IfDownLeft => (from.x.min(target_x), from.x.max(target_x))
    IfDownRight =>
      ((from.x + from.width).min(target_x), (from.x + from.width).max(target_x))
    SwitchLeft | SwitchRight | SwitchMiddle => return None
    WhileExitLeft => {
      let route_x = from.x.min(to.x) - WHILE_BACK_MARGIN
      (route_x, from.x.max(target_x))
    }
  }
  Some(start_end)
}

///|
/// Occupied x-intervals of every drawn element except fork bars and the edges
/// exempt above. Node labels live inside their node boxes, so node rectangles
/// cover them.
fn merge_slots(layout : ActivityLayout) -> Array[Slot] {
  let ranges = []
  for node in layout.nodes {
    guard !layout.source_nodes[node.node_index].is_fork() else { continue }
    guard node.width > 0 else { continue }
    ranges.push((node.x, node.x + node.width))
  }
  for edge in layout.edges {
    guard edge_x_extent(edge, layout) is Some((start, end)) else { continue }
    ranges.push((start, end))
  }
  for region in layout.regions {
    ranges.push((region.x, region.x + region.width))
  }
  ranges.sort_by((a, b) => a.0.compare(b.0))
  let merged : Array[Slot] = []
  for range in ranges {
    if merged.is_empty() || range.0 > merged[merged.length() - 1].end {
      merged.push({ start: range.0, end: range.1 })
    } else {
      let last = merged[merged.length() - 1]
      merged[merged.length() - 1] = { ..last, end: last.end.max(range.1) }
    }
  }
  merged
}

///|
/// Gaps between consecutive occupied regions, plus the leading and trailing
/// strips bounded by the leftmost/rightmost node boxes (fork bars are exempt
/// from the slot set, so the strips next to them are compressible).
fn compress_gaps(
  merged : Array[Slot],
  content_min : Int,
  content_max : Int,
) -> Array[Gap] {
  let gaps : Array[Gap] = []
  let mut prev_end = content_min
  for slot in merged {
    let start = prev_end
    let end = slot.start
    if end - start > 10 {
      gaps.push({ start: start + 5, end: end - 5 })
    }
    prev_end = prev_end.max(slot.end)
  }
  if content_max - prev_end > 10 {
    gaps.push({ start: prev_end + 5, end: content_max - 5 })
  }
  gaps
}

///|
/// PlantUML's slot pass measures the outer fork columns two pixels wider than
/// their rectangles: a bare fork block's leading and trailing gaps compress
/// from 14px to 12px (verified against the reference SVGs). Extending the
/// extreme slots by 2px replicates that; it only matters when an exempt fork
/// bar sits at the content edge, and is a no-op otherwise.
fn extend_extreme_slots(merged : Array[Slot]) -> Unit {
  if !merged.is_empty() {
    merged[0] = { ..merged[0], start: merged[0].start - 2 }
    let last = merged.length() - 1
    merged[last] = { ..merged[last], end: merged[last].end + 2 }
  }
}

///|
/// Total compression shift applied at position `v` (PlantUML
/// `CompressionTransform.getCompressDelta`).
fn delta(gaps : Array[Gap], v : Int) -> Int {
  let mut result = 0
  for gap in gaps {
    if v > gap.end {
      result += gap.end - gap.start
    } else if v > gap.start {
      result += v - gap.start
    }
  }
  result
}

///|
fn transform(gaps : Array[Gap], v : Int) -> Int {
  v - delta(gaps, v)
}

///|
/// Compress empty horizontal strips of the laid-out diagram in place. Edge
/// routes are position-free; `svg.mbt` regenerates their polylines from the
/// transformed node boxes, and `layout()` recomputes the canvas width.
pub fn ActivityLayout::compress_x(self : ActivityLayout) -> ActivityLayout {
  let merged = merge_slots(self)
  extend_extreme_slots(merged)
  let mut content_min = 0
  let mut content_max = 0
  for index, node in self.nodes {
    if index == 0 {
      content_min = node.x
      content_max = node.x + node.width
    } else {
      content_min = content_min.min(node.x)
      content_max = content_max.max(node.x + node.width)
    }
  }
  let gaps = compress_gaps(merged, content_min, content_max)
  let nodes = self.nodes.map(node => {
    let x = transform(gaps, node.x)
    let right = transform(gaps, node.x + node.width)
    { ..node, x, width: right - x }
  })
  let regions = self.regions.map(region => {
    let x = transform(gaps, region.x)
    let right = transform(gaps, region.x + region.width)
    { ..region, x, width: right - x }
  })
  { ..self, nodes, regions }
}
