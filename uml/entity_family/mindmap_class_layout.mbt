///|
/// The mbti family packs its class boxes with the mindmap tee-packing
/// algorithm: every entity hangs under the target of its first relation, and
/// entities that nothing points at (or whose relations would form a cycle)
/// become roots of the forest.
///
/// Only the packed tree edges are painted: every non-root node keeps exactly
/// one edge (its parent -> child), and relations that lose the tree race are
/// dropped instead of connecting nodes with extra beziers.
priv struct MindmapClassLayout {
  layout : @render.MindmapLayout
  rects : Array[(Int, Int, Int, Int)]
  /// Tree edges from the packing.
  structure_edges : Array[MindmapClassEdge]
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
  left_entity : Int
  right_entity : Int
}

///|
/// Whether `source` already has `target` as an ancestor; assigning the parent
/// then would close a cycle.
fn creates_cycle(parent : Array[Int?], source : Int, target : Int) -> Bool {
  let mut current = target
  while current != source {
    guard parent[current] is Some(next) else { return false }
    current = next
  }
  true
}

///|
/// The mindmap tree layout of the mbti family: entities with no incoming
/// relation are the roots and every other entity hangs under the target of
/// its first relation. Exposed so callers can inspect the geometry.
fn @entity.EntityDiagram::mindmap_layout(
  self : @entity.EntityDiagram,
) -> @render.MindmapLayout {
  let text_metrics = ClassTextMetrics::new(self.style)
  self.mindmap_class_layout(text_metrics).layout
}

///|
/// Build the mbti tree: entities with no incoming relation (or whose
/// relations would form a cycle) are the forest roots, and every other
/// entity takes the target of its first relation as its parent.
fn @entity.EntityDiagram::mindmap_class_layout(
  self : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
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
  for _ in 0..<count {
    children.push([])
  }
  for entity_index, p in parent {
    if p is Some(par) {
      children[par].push(entity_index)
    }
  }
  let roots : Array[Int] = []
  let items : Array[@render.LayoutItem] = []
  for entity_index, entity in self.entities {
    let geometry = entity.node_geometry(text_metrics, self.family)
    items.push({
      width: geometry.width,
      height: geometry.height,
      margin_left: @tree.MINDMAP_DEFAULT_MARGIN,
      margin_right: @tree.MINDMAP_DEFAULT_MARGIN,
      margin_top: @tree.MINDMAP_DEFAULT_MARGIN,
      margin_bottom: @tree.MINDMAP_DEFAULT_MARGIN,
      left_children: [],
      right_children: children[entity_index],
    })
    if parent[entity_index] is None {
      roots.push(entity_index)
    }
  }
  let layout = @render.layout_tree(items, roots)
  let rects : Array[(Int, Int, Int, Int)] = Array::make(count, (0, 0, 0, 0))
  for node in layout.nodes {
    rects[node.idea_index] = (node.x, node.y, node.width, node.height)
  }
  let structure_edges : Array[MindmapClassEdge] = layout.edges.map(edge => {
    x1: edge.x1,
    y1: edge.y1,
    control1_x: edge.control1_x,
    control1_y: edge.control1_y,
    control2_x: edge.control2_x,
    control2_y: edge.control2_y,
    x2: edge.x2,
    y2: edge.y2,
    left_entity: edge.parent_index,
    right_entity: edge.child_index,
  })
  { layout, rects, structure_edges, }
}

///|
/// Paint one mbti structure edge (a packed parent-child curve) with open and
/// closed endpoint states so it retracts when a class node collapses.
fn append_mindmap_structure_edges(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
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
/// Emit the open/closed edge-state groups of one mindmap bezier, mirroring the
/// graphviz relation path: when a class node collapses, its endpoint moves
/// from the full box boundary to the header strip.
fn append_mindmap_edge_states(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  edge : MindmapClassEdge,
  relation_index : Int,
  relation_color : String,
  line_attributes : String,
  dash : String,
  class_member_collapsible : Bool,
) -> Unit {
  let left_header = relation_endpoint_header(
    layout,
    diagram,
    edge.left_entity,
    text_metrics,
    class_member_collapsible,
  )
  let right_header = relation_endpoint_header(
    layout,
    diagram,
    edge.right_entity,
    text_metrics,
    class_member_collapsible,
  )
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
/// The mindmap tree layout for a parsed entity diagram.
pub fn mindmap_layout_entity(
  diagram : @entity.EntityDiagram,
) -> @render.MindmapLayout {
  diagram.mindmap_layout()
}
