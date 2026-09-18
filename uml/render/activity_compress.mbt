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
  guard !(edge.route
    is (ForkLane(_) | SwitchLeft | SwitchRight | SwitchMiddle | SwitchSideMerge)) &&
    !(edge.route is Forward &&
    (
      from_source.is_fork() ||
      to_source.is_fork() ||
      to_source is @flow.ActivityNode::EndSwitch
    )) else {
    return None
  }
  Some(activity_edge_x_bounds(edge, from, to, layout.source_nodes))
}

///|
/// Occupied x-intervals of every drawn element except fork bars and the edges
/// exempt above. Node labels live inside their node boxes, so node rectangles
/// cover them.
fn merge_slots(
  layout : ActivityLayout,
  small_metrics : @metrics.FontMetrics,
) -> Array[Slot] {
  let ranges = []
  for node in layout.nodes {
    guard !layout.source_nodes[node.node_index].is_fork() else { continue }
    guard node.width > 0 else { continue }
    ranges.push((node.x, node.x + node.width))
  }
  for edge in layout.edges {
    if edge.label is Some(label) {
      let from = layout_for(layout, edge.from_node_index).unwrap()
      let to = layout_for(layout, edge.to_node_index).unwrap()
      ranges.push(
        activity_edge_label_bounds(
          edge,
          label,
          from,
          to,
          layout.source_nodes,
          small_metrics,
        ),
      )
    }
    guard edge_x_extent(edge, layout) is Some((start, end)) else { continue }
    ranges.push((start, end))
  }
  for region in layout.regions {
    ranges.push((region.x, region.x + region.width))
  }
  ranges.sort_by((a, b) => a.0.compare(b.0))
  let merged : Array[Slot] = []
  for range in ranges {
    let last_index = merged.length() - 1
    if merged.is_empty() || range.0 > merged[last_index].end {
      merged.push({ start: range.0, end: range.1, })
    } else {
      let last = merged[last_index]
      merged[last_index] = { ..last, end: last.end.max(range.1), }
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
      gaps.push({ start: start + 5, end: end - 5, })
    }
    prev_end = prev_end.max(slot.end)
  }
  if content_max - prev_end > 10 {
    gaps.push({ start: prev_end + 5, end: content_max - 5, })
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
    merged[0] = { ..merged[0], start: merged[0].start - 2, }
    let last = merged.length() - 1
    merged[last] = { ..merged[last], end: merged[last].end + 2, }
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
pub fn ActivityLayout::compress_x(
  self : ActivityLayout,
  small_metrics? : @metrics.FontMetrics = @metrics.FontMetrics::from_defaults(
    font_size=SMALL_FONT,
  ),
) -> ActivityLayout {
  let merged = merge_slots(self, small_metrics)
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
    { ..node, x, width: right - x, }
  })
  let regions = self.regions.map(region => {
    let x = transform(gaps, region.x)
    let right = transform(gaps, region.x + region.width)
    { ..region, x, width: right - x, }
  })
  let compress_offset = (anchor : Int, offset : Int) => {
    let node = layout_for(self, anchor).unwrap()
    transform(gaps, node.x + offset) - transform(gaps, node.x)
  }
  let edges = self.edges.map(edge => {
    let route = match edge.route {
      ForkSequence => {
        let from = layout_for(self, edge.from_node_index).unwrap()
        let to = layout_for(self, edge.to_node_index).unwrap()
        ForkSequencePorts(
          compress_offset(edge.from_node_index, from.width / 2),
          compress_offset(edge.to_node_index, to.width / 2),
        )
      }
      ForkSequencePorts(from_offset, to_offset) =>
        ForkSequencePorts(
          compress_offset(edge.from_node_index, from_offset),
          compress_offset(edge.to_node_index, to_offset),
        )
      ForkLane(from_offset, to_offset) =>
        ForkLane(
          compress_offset(edge.from_node_index, from_offset),
          compress_offset(edge.to_node_index, to_offset),
        )
      IfBypassRight(offset) =>
        IfBypassRight(compress_offset(edge.from_node_index, offset))
      WhileExitLeft(offset) =>
        WhileExitLeft(compress_offset(edge.from_node_index, offset))
      BackwardRight(offset, drop) =>
        BackwardRight(compress_offset(edge.to_node_index, offset), drop)
      RepeatBackRight(offset) =>
        RepeatBackRight(compress_offset(edge.to_node_index, offset))
      RepeatLaneBack(offset) =>
        RepeatLaneBack(compress_offset(edge.from_node_index, offset))
      route => route
    }
    { ..edge, route, }
  })
  { ..self, nodes, edges, regions, }
}
