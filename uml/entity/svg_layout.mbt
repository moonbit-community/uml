///|
priv struct ClassLayout {
  columns : Int
  cell_width : Int
  cell_height : Int
  width : Int
  graphviz : GraphvizLayout?
}

///|
fn EntityDiagram::layout(
  self : EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> ClassLayout {
  let columns = self.entities.length().min(3).max(1)
  let mut cell_width = 220
  let mut cell_height = 180
  for entity in self.entities {
    let geometry = entity.node_geometry(text_metrics, self.family)
    cell_width = cell_width.max(geometry.width + 24)
    cell_height = cell_height.max(geometry.height + 24)
  }
  {
    columns,
    cell_width,
    cell_height,
    width: 24 + columns * cell_width,
    graphviz: None,
  }
}

///|
fn ClassLayout::entity_rect(
  self : ClassLayout,
  diagram : EntityDiagram,
  index : Int,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, Int, Int) {
  match self.graphviz {
    Some(layout) => {
      let code = diagram.entities[index].qualified_code
      for node in layout.nodes {
        if node.code == code {
          return (
            (node.x - node.width / 2.0).floor().to_int(),
            (node.y - node.height / 2.0).floor().to_int(),
            node.width.ceil().to_int().max(1),
            node.height.ceil().to_int().max(1),
          )
        }
      }
    }
    None => ()
  }
  let geometry = diagram.entities[index].node_geometry(text_metrics, diagram.family)
  (self.node_x(index), self.node_y(index), geometry.width, geometry.height)
}

///|
/// Extent of everything the renderer draws, used to size the SVG canvas like
/// PlantUML's SvekResult minMax: content is placed at (6, 6) and the canvas
/// extends 15px beyond the content's bottom-right corner.
priv struct ContentBounds {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
}

///|
fn ContentBounds::point(
  self : ContentBounds,
  x : Double,
  y : Double,
) -> ContentBounds {
  {
    min_x: self.min_x.min(x),
    min_y: self.min_y.min(y),
    max_x: self.max_x.max(x),
    max_y: self.max_y.max(y),
  }
}

///|
#warnings("-unused_value")
fn ContentBounds::rect(
  self : ContentBounds,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> ContentBounds {
  self.point(x, y).point(x + w, y + h)
}

///|
#warnings("-unused_value")
fn ContentBounds::text(
  self : ContentBounds,
  x : Double,
  baseline_y : Double,
  measured : @metrics.TextMetrics,
  anchor_middle~ : Bool = true,
) -> ContentBounds {
  let left = if anchor_middle {
    x - measured.width.to_double() / 2.0
  } else {
    x
  }
  self.point(left, baseline_y - measured.ascent.to_double()).point(
    left + measured.width.to_double(),
    baseline_y + measured.descent.to_double(),
  )
}

///|
fn ClassLayout::content_bounds(
  self : ClassLayout,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> ContentBounds {
  let usecase = diagram.family.is_usecase()
  let mut bounds : ContentBounds? = None
  let include_point = (bounds : ContentBounds?, x : Double, y : Double) => {
    match bounds {
      None => Some({ min_x: x, min_y: y, max_x: x, max_y: y })
      Some(current) =>
        Some(
          current.point(x, y),
        )
    }
  }
  for index, entity in diagram.entities {
    guard !entity.is_hidden && !entity.is_removed else { continue }
    let (x, y, w, h) = self.entity_rect(diagram, index, text_metrics)
    let (x, y, w, h) = (
      x.to_double(),
      y.to_double(),
      w.to_double(),
      h.to_double(),
    )
    bounds = include_point(bounds, x, y)
    bounds = include_point(bounds, x + w, y + h)
  }
  match self.graphviz {
    Some(graphviz) => {
      for edge in graphviz.edges {
        for path in edge.paths {
          for point in path {
            let (x, y) = point
            bounds = include_point(bounds, x, y)
          }
        }
      }
      for p in graphviz.packages {
        guard p.package_index < diagram.packages.length() else {
          continue
        }
        bounds = include_point(bounds, p.x, p.y)
        bounds = include_point(bounds, p.x + p.width, p.y + p.height)
      }
      for note in graphviz.notes {
        guard note.note_index < diagram.notes.length() else { continue }
        bounds = include_point(bounds, note.x - note.width / 2.0, note.y - note.height / 2.0)
        bounds = include_point(bounds, note.x + note.width / 2.0, note.y + note.height / 2.0)
      }
    }
    None => ()
  }
  for relation_index, relation in diagram.relations {
    guard entity_index(diagram, relation.left) is Some(left_index) else {
      continue
    }
    guard entity_index(diagram, relation.right) is Some(right_index) else {
      continue
    }
    let left = diagram.entities[left_index]
    let right = diagram.entities[right_index]
    guard !left.is_removed && !right.is_removed else { continue }
    let ((x1, y1), (x2, y2)) = relation_endpoints(
      self,
      diagram,
      left_index,
      right_index,
      text_metrics,
    )
    match relation.label {
      Some(label) => {
        let display = if usecase {
          @parse.display_stereotype(label)
        } else {
          label
        }
        let measured = @metrics.measure_text_with(
          display,
          if usecase {
            text_metrics.arrow_regular
          } else {
            text_metrics.relation_label_regular
          },
        )
        let (px, py) = relation_label_position(
          self,
          relation_index,
          ((x1 + x2) / 2, (y1 + y2) / 2),
          measured.width.to_double() / 2.0,
        )
        bounds = include_point(
          bounds,
          px - measured.width.to_double() / 2.0,
          py - 5.0 - measured.ascent.to_double(),
        )
        bounds = include_point(
          bounds,
          px + measured.width.to_double() / 2.0,
          py - 5.0 + measured.descent.to_double(),
        )
      }
      None => ()
    }
    for entry in [
      ((x1 - 8, y1 - 6), relation.left_cardinality),
      ((x2 + 8, y2 - 6), relation.right_cardinality),
      ((x1 - 8, y1 + 13), relation.left_role),
      ((x2 + 8, y2 + 13), relation.right_role),
    ] {
      let (position, text) = entry
      match text {
        Some(value) => {
          let measured = @metrics.measure_text_with(value, text_metrics.regular)
          bounds = include_point(
            bounds,
            position.0.to_double(),
            position.1.to_double() - measured.ascent.to_double(),
          )
          bounds = include_point(
            bounds,
            (position.0 + measured.width).to_double(),
            position.1.to_double() + measured.descent.to_double(),
          )
        }
        None => ()
      }
    }
  }
  match bounds {
    Some(bounds) => bounds
    None => { min_x: 0.0, min_y: 0.0, max_x: 0.0, max_y: 0.0 }
  }
}

///|
fn relation_endpoints(
  layout : ClassLayout,
  diagram : EntityDiagram,
  left_index : Int,
  right_index : Int,
  text_metrics : ClassTextMetrics,
) -> ((Int, Int), (Int, Int)) {
  let (left_x, left_y, left_width, left_height) = layout.entity_rect(
    diagram,
    left_index,
    text_metrics,
  )
  let (right_x, right_y, right_width, right_height) = layout.entity_rect(
    diagram,
    right_index,
    text_metrics,
  )
  let left_center = (left_x + left_width / 2, left_y + left_height / 2)
  let right_center = (right_x + right_width / 2, right_y + right_height / 2)
  let (x1, y1) = if diagram.family.is_usecase() {
    usecase_relation_endpoint(
      left_x,
      left_y,
      left_width,
      left_height,
      right_center.0,
      right_center.1,
    )
  } else {
    left_center
  }
  let (x2, y2) = if diagram.family.is_usecase() {
    usecase_relation_endpoint(
      right_x,
      right_y,
      right_width,
      right_height,
      left_center.0,
      left_center.1,
    )
  } else {
    right_center
  }
  ((x1, y1), (x2, y2))
}

///|
fn entity_index(diagram : EntityDiagram, code : String) -> Int? {
  for index, entity in diagram.entities {
    if entity.qualified_code == code {
      return Some(index)
    }
  }
  None
}

///|
fn ClassLayout::node_x(self : ClassLayout, index : Int) -> Int {
  24 + index % self.columns * self.cell_width
}

///|
fn usecase_relation_endpoint(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  target_x : Int,
  target_y : Int,
) -> (Int, Int) {
  let center_x = x + width / 2
  let center_y = y + height / 2
  let horizontal = (target_x - center_x).abs() > (target_y - center_y).abs()
  if horizontal {
    if target_x < center_x {
      (x, center_y)
    } else {
      (x + width, center_y)
    }
  } else if target_y < center_y {
    (center_x, y)
  } else {
    (center_x, y + height)
  }
}

///|
fn usecase_spline_endpoint(
  entity : Entity,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  current : (Double, Double),
  toward : (Double, Double),
) -> (Double, Double) {
  let center_x = x.to_double() + width.to_double() / 2.0
  let center_y = y.to_double() + height.to_double() / 2.0
  let dx = toward.0 - center_x
  let dy = toward.1 - center_y
  guard dx != 0.0 || dy != 0.0 else { return (center_x, center_y) }
  match entity.kind {
    Usecase | BusinessUsecase => {
      let radius_x = width.to_double() / 2.0
      let radius_y = height.to_double() / 2.0
      let scale = 1.0 /
        (dx * dx / (radius_x * radius_x) + dy * dy / (radius_y * radius_y)).sqrt()
      (center_x + dx * scale, center_y + dy * scale)
    }
    Component => {
      let scale_x = width.to_double() / 2.0 / dx.abs()
      let scale_y = height.to_double() / 2.0 / dy.abs()
      let scale = if dx == 0.0 {
        scale_y
      } else if dy == 0.0 {
        scale_x
      } else {
        scale_x.min(scale_y)
      }
      (center_x + dx * scale, center_y + dy * scale)
    }
    _ => current
  }
}

///|
fn clip_usecase_spline(
  path : Array[(Double, Double)],
  left : Entity,
  left_rect : (Int, Int, Int, Int),
  right : Entity,
  right_rect : (Int, Int, Int, Int),
) -> Array[(Double, Double)] {
  guard path.length() > 1 else { return path }
  let clipped : Array[(Double, Double)] = []
  for point in path {
    clipped.push(point)
  }
  let (left_x, left_y, left_width, left_height) = left_rect
  let (right_x, right_y, right_width, right_height) = right_rect
  let original_start = clipped[0]
  let original_end = clipped[clipped.length() - 1]
  let clipped_start = usecase_spline_endpoint(
    left,
    left_x,
    left_y,
    left_width,
    left_height,
    clipped[0],
    clipped[1],
  )
  clipped[0] = clipped_start
  let last = clipped.length() - 1
  let clipped_end = usecase_spline_endpoint(
    right,
    right_x,
    right_y,
    right_width,
    right_height,
    clipped[last],
    clipped[last - 1],
  )
  clipped[last] = clipped_end
  if (clipped.length() - 1) % 3 == 0 {
    clipped[1] = (
      clipped_start.0 + clipped[1].0 - original_start.0,
      clipped_start.1 + clipped[1].1 - original_start.1,
    )
    clipped[last - 1] = (
      clipped_end.0 - (original_end.0 - clipped[last - 1].0),
      clipped_end.1 - (original_end.1 - clipped[last - 1].1),
    )
  }
  clipped
}

///|
fn relation_marker(end : RelationEnd) -> String? {
  match end {
    Extension | Redefines | DefinedBy => Some("triangle")
    CompositionEnd => Some("diamond")
    AggregationEnd => Some("diamond-open")
    Arrow | TriangleArrow | HalfArrowUp | HalfArrowDown => Some("arrow")
    NotNavigable | DoubleLine => Some("bar")
    CircleEnd | CircleConnect | CircleLine | CircleCrowfoot => Some("circle")
    FilledCircle => Some("circle-filled")
    Square => Some("square")
    Plus => Some("plus")
    Crowfoot | LineCrowfoot => Some("crowfoot")
    _ => None
  }
}

///|
fn relation_label_position(
  layout : ClassLayout,
  relation_index : Int,
  fallback : (Int, Int),
  half_width : Double,
) -> (Double, Double) {
  match layout.graphviz {
    Some(graphviz) =>
      for edge in graphviz.edges {
        if edge.index == relation_index {
          let position = edge.label.unwrap_or(
            (fallback.0.to_double(), fallback.1.to_double()),
          )
          return offset_label_from_edge(position, edge.paths, half_width)
        }
      }
    None => ()
  }
  (fallback.0.to_double(), fallback.1.to_double())
}

///|
/// Nudge the label box away from the edge spline so the text keeps a small
/// visual gap instead of overlapping the line. The text box corners are
/// sampled against the spline; if any corner is closer than the clearance
/// the box is pushed along the normal until the closest corner clears it.
fn offset_label_from_edge(
  label : (Double, Double),
  paths : Array[Array[(Double, Double)]],
  half_width : Double,
) -> (Double, Double) {
  // The rendering drops the baseline 5px below `label` and the text is
  // roughly label_font_size tall, so the text box center sits here.
  let half_height = RELATION_LABEL_FONT_SIZE.to_double() / 2.0
  let center = (label.0, label.1 - 5.0 - half_height)
  // Sample the text box corners: left/right edges at top and bottom.
  let corners = [
    (center.0 - half_width, center.1 - half_height),
    (center.0 - half_width, center.1 + half_height),
    (center.0 + half_width, center.1 - half_height),
    (center.0 + half_width, center.1 + half_height),
  ]
  let clearance = 2.0
  let mut best_corner = (0.0, 0.0)
  let mut best_dist = 1.0e9
  for path in paths {
    guard path.length() > 1 else { continue }
    for index in 0..<(path.length() - 1) {
      let a = path[index]
      let b = path[index + 1]
      for corner_index in 0..<corners.length() {
        let (cx, cy) = corners[corner_index]
        let (nx, ny) = closest_point_on_segment((cx, cy), a, b)
        let dx = cx - nx
        let dy = cy - ny
        let dist = (dx * dx + dy * dy).sqrt()
        if dist < best_dist {
          best_dist = dist
          best_corner = (cx, cy)
        }
      }
    }
  }
  guard best_dist < clearance else { return label }
  // Find the closest point on the edge to the offending corner.
  let (corner_x, corner_y) = best_corner
  let mut closest = (0.0, 0.0)
  let mut closest_dist = 1.0e9
  for path in paths {
    guard path.length() > 1 else { continue }
    for index in 0..<(path.length() - 1) {
      let a = path[index]
      let b = path[index + 1]
      let (nx, ny) = closest_point_on_segment((corner_x, corner_y), a, b)
      let dist = ((corner_x - nx) * (corner_x - nx) + (corner_y - ny) * (corner_y - ny)).sqrt()
      if dist < closest_dist {
        closest_dist = dist
        closest = (nx, ny)
      }
    }
  }
  let (nx, ny) = closest
  let dx = corner_x - nx
  let dy = corner_y - ny
  let normal_length = (dx * dx + dy * dy).sqrt()
  guard normal_length > 0.0001 else { return label }
  let shift = clearance - closest_dist
  // Translate the whole box (and thus the label anchor) along the normal.
  (label.0 + dx / normal_length * shift, label.1 + dy / normal_length * shift)
}

///|
/// Project a point onto a segment and return the closest point on the segment.
fn closest_point_on_segment(
  point : (Double, Double),
  a : (Double, Double),
  b : (Double, Double),
) -> (Double, Double) {
  let (px, py) = point
  let (ax, ay) = a
  let (bx, by) = b
  let tx = bx - ax
  let ty = by - ay
  let length_sq = tx * tx + ty * ty
  guard length_sq > 0.0 else { return a }
  let t = ((px - ax) * tx + (py - ay) * ty) / length_sq
  let t = t.max(0.0).min(1.0)
  (ax + tx * t, ay + ty * t)
}
