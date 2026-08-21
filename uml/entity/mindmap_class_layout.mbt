///|
/// The mbti family packs its class boxes with the mindmap tee-packing
/// algorithm: the package name is the single root, every entity hangs under
/// the target of its first relation, and entities that nothing points at
/// (or whose relations would form a cycle) hang under the package root.
priv struct MindmapClassLayout {
  layout : @mindmap.MindmapLayout
  root_rect : (Int, Int, Int, Int)
  package_label : String
  rects : Array[(Int, Int, Int, Int)]
  /// Tree edges from the packing (including the package root's children).
  structure_edges : Array[MindmapClassEdge]
  /// Per relation: a bezier for relations that are not tree edges, `None`
  /// when the relation already appears as a structure edge.
  extra_edges : Array[MindmapClassEdge?]
}

///|
/// One relation or structure edge drawn as a mindmap-style bezier, with the
/// entity indices of its endpoints so collapsible nodes can retract it.
priv struct MindmapClassEdge {
  x1 : Int
  y1 : Int
  control1_x : Int
  control1_y : Int
  control2_x : Int
  control2_y : Int
  x2 : Int
  y2 : Int
  left_entity : Int?
  right_entity : Int?
}

///|
/// Whether `source` already has `target` as an ancestor; assigning the parent
/// then would close a cycle.
fn creates_cycle(parent : Array[Int?], source : Int, target : Int) -> Bool {
  let mut current = target
  while current != source {
    match parent[current] {
      Some(next) => current = next
      None => return false
    }
  }
  true
}

///|
/// The mindmap tree layout of the mbti family: node 0 is the package root and
/// node i+1 is entity i. Exposed so callers can inspect the geometry.
pub fn EntityDiagram::mindmap_layout(
  self : EntityDiagram,
  package_name : String,
) -> @mindmap.MindmapLayout {
  let text_metrics = ClassTextMetrics::new(self.style)
  self.mindmap_class_layout(text_metrics, package_name).layout
}

///|
/// Build the mbti tree: node 0 is the package root, node i+1 is entity i.
/// Every entity takes the target of its first relation as its parent; an
/// entity is a child of the package root when no relation assigns it one.
fn EntityDiagram::mindmap_class_layout(
  self : EntityDiagram,
  text_metrics : ClassTextMetrics,
  package_name : String,
) -> MindmapClassLayout {
  let count = self.entities.length()
  let parent : Array[Int?] = Array::make(count, None)
  for relation in self.relations {
    let source = entity_index(self, relation.left)
    let target = entity_index(self, relation.right)
    match (source, target) {
      (Some(source), Some(target)) if source != target =>
        if parent[source] is None && !creates_cycle(parent, source, target) {
          parent[source] = Some(target)
        }
      _ => ()
    }
  }
  let children : Array[Array[Int]] = []
  for _ in 0..<(count + 1) {
    children.push([])
  }
  for entity_index, p in parent {
    let parent_node = match p {
      Some(parent) => parent + 1
      None => 0
    }
    children[parent_node].push(entity_index + 1)
  }
  let items : Array[@mindmap.LayoutItem] = []
  let root_metrics = text_metrics.regular.measure(package_name)
  items.push({
    width: root_metrics.width + @mindmap.MINDMAP_DEFAULT_PADDING_X * 2,
    height: root_metrics.height + @mindmap.MINDMAP_DEFAULT_PADDING_Y * 2,
    margin_left: @mindmap.MINDMAP_DEFAULT_MARGIN,
    margin_right: @mindmap.MINDMAP_DEFAULT_MARGIN,
    margin_top: @mindmap.MINDMAP_DEFAULT_MARGIN,
    margin_bottom: @mindmap.MINDMAP_DEFAULT_MARGIN,
    left_children: [],
    right_children: children[0],
  })
  for entity_index, entity in self.entities {
    let geometry = entity.node_geometry(text_metrics, self.family)
    items.push({
      width: geometry.width,
      height: geometry.height,
      margin_left: @mindmap.MINDMAP_DEFAULT_MARGIN,
      margin_right: @mindmap.MINDMAP_DEFAULT_MARGIN,
      margin_top: @mindmap.MINDMAP_DEFAULT_MARGIN,
      margin_bottom: @mindmap.MINDMAP_DEFAULT_MARGIN,
      left_children: [],
      right_children: children[entity_index + 1],
    })
  }
  let layout = @mindmap.layout_tree(items, [0])
  let mut root_rect = (0, 0, 0, 0)
  let rects : Array[(Int, Int, Int, Int)] = Array::make(count, (0, 0, 0, 0))
  for node in layout.nodes {
    if node.idea_index == 0 {
      root_rect = (node.x, node.y, node.width, node.height)
    } else {
      rects[node.idea_index - 1] = (node.x, node.y, node.width, node.height)
    }
  }
  let structure_edges : Array[MindmapClassEdge] = []
  for edge in layout.edges {
    structure_edges.push({
      x1: edge.x1,
      y1: edge.y1,
      control1_x: edge.control1_x,
      control1_y: edge.control1_y,
      control2_x: edge.control2_x,
      control2_y: edge.control2_y,
      x2: edge.x2,
      y2: edge.y2,
      left_entity: if edge.parent_index == 0 {
        None
      } else {
        Some(edge.parent_index - 1)
      },
      right_entity: if edge.child_index == 0 {
        None
      } else {
        Some(edge.child_index - 1)
      },
    })
  }
  let extra_edges : Array[MindmapClassEdge?] = []
  for relation in self.relations {
    let source = entity_index(self, relation.left)
    let target = entity_index(self, relation.right)
    match (source, target) {
      (Some(source), Some(target)) => {
        let source_node = source + 1
        let target_node = target + 1
        // The tree edge connects the relation target (parent) to its source
        // (child); the relation is a structure edge when it won the race.
        let is_tree_edge = layout.edges.any(edge => {
          edge.parent_index == target_node && edge.child_index == source_node
        })
        if is_tree_edge {
          extra_edges.push(None)
        } else {
          let edge = bezier_between(rects[source], rects[target])
          extra_edges.push(
            Some({
              ..edge,
              left_entity: Some(source),
              right_entity: Some(target),
            }),
          )
        }
      }
      _ => extra_edges.push(None)
    }
  }
  {
    layout,
    root_rect,
    package_label: package_name,
    rects,
    structure_edges,
    extra_edges,
  }
}

///|
/// Paint one mbti structure edge (a packed parent-child curve) with open and
/// closed endpoint states so it retracts when a class node collapses.
fn append_mindmap_structure_edges(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  class_member_collapsible : Bool,
) -> Unit {
  match layout.mindmap {
    Some(mindmap) => {
      let color = diagram.style.diagram_line_color()
      for structure_index, edge in mindmap.structure_edges {
        append_mindmap_edge_states(
          output,
          diagram,
          text_metrics,
          layout,
          edge,
          -1 - structure_index,
          color,
          "",
          "",
          class_member_collapsible,
        )
      }
    }
    None => ()
  }
}

///|
/// Paint the mbti package root: a box with the package name, drawn before the
/// entity boxes so the relation curves stay behind it.
fn append_mindmap_root(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.mindmap {
    Some(mindmap) => {
      let (x, y, width, height) = mindmap.root_rect
      let package_label = mindmap.package_label
      let fill = @svg.svg_color(None, class_background_color(diagram.style))
      let stroke = @svg.svg_color(None, class_border_color(diagram.style))
      let title = text_metrics.regular.measure(package_label)
      let title_x = x + (width - title.width) / 2
      let title_baseline = y +
        (height + title.height) / 2 -
        CLASS_TEXT_BASELINE_BOTTOM_GAP
      output <+
        $|<g class="class-node" data-code="\{@svg.xml_escape(package_label)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}" style="stroke:\{stroke};stroke-width:1.2"/><text x="\{title_x}" y="\{title_baseline}" class="class-title">\{@svg.xml_escape(package_label)}</text></g>
    }
    None => ()
  }
}

///|
/// Paint one mbti relation as a mindmap-style bezier curve with its label at
/// the curve midpoint.
fn append_mindmap_relation(
  output : StringBuilder,
  diagram : EntityDiagram,
  relation_index : Int,
  relation : Relation,
  edge : MindmapClassEdge,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  class_member_collapsible : Bool,
) -> Unit {
  let relation_color = @svg.svg_color(
    relation.color,
    diagram.style.diagram_line_color(),
  )
  let line_attributes = @svg.stroke_style(relation.line_style, default_width="")
  let dash = if relation.dotted {
    @svg.line_style_attributes_markup(Some("dashed"))
  } else {
    ""
  }
  append_mindmap_edge_states(
    output, diagram, text_metrics, layout, edge, relation_index, relation_color,
    line_attributes, dash, class_member_collapsible,
  )
  match relation.label {
    Some(label) => {
      let x = (edge.x1 + 3 * edge.control1_x + 3 * edge.control2_x + edge.x2) /
        8
      let y = (edge.y1 + 3 * edge.control1_y + 3 * edge.control2_y + edge.y2) /
        8
      let label_color = diagram.style.diagram_text_color()
      output <+
        $|<text x="\{x}" y="\{y}" class="relation-label" fill="\{label_color}">\{@svg.xml_escape(label)}</text>
    }
    None => ()
  }
}

///|
/// Emit the open/closed edge-state groups of one mindmap bezier, mirroring the
/// graphviz relation path: when a class node collapses, its endpoint moves
/// from the full box boundary to the header strip.
fn append_mindmap_edge_states(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  edge : MindmapClassEdge,
  relation_index : Int,
  relation_color : String,
  line_attributes : String,
  dash : String,
  class_member_collapsible : Bool,
) -> Unit {
  let left_header = match edge.left_entity {
    Some(index) =>
      relation_endpoint_header(
        layout, diagram, index, text_metrics, class_member_collapsible,
      )
    None => None
  }
  let right_header = match edge.right_entity {
    Some(index) =>
      relation_endpoint_header(
        layout, diagram, index, text_metrics, class_member_collapsible,
      )
    None => None
  }
  let left_states = relation_endpoint_states(
    (edge.x1.to_double(), edge.y1.to_double()),
    None,
    left_header,
  )
  let right_states = relation_endpoint_states(
    (edge.x2.to_double(), edge.y2.to_double()),
    None,
    right_header,
  )
  let wrapped = left_states.length() > 1 || right_states.length() > 1
  if wrapped {
    output <+
      $|<g class="edge" data-edge-index="\{relation_index}">
  }
  for left_bit, left_state in left_states {
    for right_bit, right_state in right_states {
      if wrapped {
        output <+
          $|<g class="edge-state edge-state-\{left_bit}\{right_bit}">
      }
      append_mindmap_edge_state(
        output, edge, left_state, right_state, relation_color, line_attributes, dash,
      )
      if wrapped {
        output.write_string("</g>\n")
      }
    }
  }
  if wrapped {
    output.write_string("</g>\n")
  }
}

///|
/// Paint one mindmap bezier for a concrete open/closed endpoint state, moving
/// the endpoint (and its adjacent control point) so the tangent is preserved.
fn append_mindmap_edge_state(
  output : StringBuilder,
  edge : MindmapClassEdge,
  left : RelationEndpointState,
  right : RelationEndpointState,
  relation_color : String,
  line_attributes : String,
  dash : String,
) -> Unit {
  let path : Array[(Double, Double)] = [
    (edge.x1.to_double(), edge.y1.to_double()),
    (edge.control1_x.to_double(), edge.control1_y.to_double()),
    (edge.control2_x.to_double(), edge.control2_y.to_double()),
    (edge.x2.to_double(), edge.y2.to_double()),
  ]
  let adjusted = move_relation_spline_endpoint(
    move_relation_spline_endpoint(path, true, left.endpoint),
    false,
    right.endpoint,
  )
  let visible_path = shorten_relation_path(relation_path(adjusted), 0.0, 0.0).pairs()
  output <+
    $|<path d="
  output.write_string(@svg.spline_path_data(visible_path))
  output <+
    $|" class="relation" style="stroke:\{relation_color};\{line_attributes}"\{dash}/>
}

///|
/// A mindmap-style bezier between two boxes: from the left box's right edge
/// center to the right box's left edge center, with control points offset by
/// the mindmap's 25px elbow. When the boxes overlap horizontally (a vertical
/// connection), the elbow offsets along the vertical axis instead so the
/// curve never folds back.
fn bezier_between(
  source : (Int, Int, Int, Int),
  target : (Int, Int, Int, Int),
) -> MindmapClassEdge {
  let (sx, sy, sw, sh) = source
  let (tx, ty, tw, th) = target
  let source_center = sx + sw / 2
  let target_center = tx + tw / 2
  let syc = sy + sh / 2
  let tyc = ty + th / 2
  let left_first = source_center <= target_center
  let (x1, y1, x2, y2) = if left_first {
    (sx + sw, syc, tx, tyc)
  } else {
    (tx + tw, tyc, sx, syc)
  }
  // The horizontal elbow would cross the facing box span when the gap is
  // narrow, so offset the control points along the direction of travel.
  let gap = (x2 - x1).abs()
  if gap < 50 {
    let sign = if y2 >= y1 { 1 } else { -1 }
    {
      x1,
      y1,
      control1_x: x1,
      control1_y: y1 + 25 * sign,
      control2_x: x2,
      control2_y: y2 - 25 * sign,
      x2,
      y2,
      left_entity: None,
      right_entity: None,
    }
  } else {
    {
      x1,
      y1,
      control1_x: x1 + 25,
      control1_y: y1,
      control2_x: x2 - 25,
      control2_y: y2,
      x2,
      y2,
      left_entity: None,
      right_entity: None,
    }
  }
}
