///|
pub(all) struct StateNodeLayout {
  code : String
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend StateNodeLayout with Eq::{not_equal, equal}

///|
pub extend StateNodeLayout with Debug::{to_repr}

///|
pub(all) struct StateEdgeLayout {
  transition_index : Int
  paths : Array[Array[(Double, Double)]]
  label : (Double, Double)?
} derive(Eq, Debug)

///|
pub extend StateEdgeLayout with Eq::{not_equal, equal}

///|
pub extend StateEdgeLayout with Debug::{to_repr}

///|
pub(all) struct StateRegionLayout {
  parent : String
  region_index : Int
  separator : @flow.StateRegionSeparator?
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend StateRegionLayout with Eq::{not_equal, equal}

///|
pub extend StateRegionLayout with Debug::{to_repr}

///|
pub(all) struct StateNoteLayout {
  note_index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend StateNoteLayout with Eq::{not_equal, equal}

///|
pub extend StateNoteLayout with Debug::{to_repr}

///|
pub(all) struct StateLayout {
  width : Double
  height : Double
  nodes : Array[StateNodeLayout]
  edges : Array[StateEdgeLayout]
  regions : Array[StateRegionLayout]
  notes : Array[StateNoteLayout]
} derive(Eq, Debug)

///|
pub extend StateLayout with Eq::{not_equal, equal}

///|
pub extend StateLayout with Debug::{to_repr}

///|
priv struct StateFragment {
  width : Double
  height : Double
  nodes : Array[StateNodeLayout]
  edges : Array[StateEdgeLayout]
  regions : Array[StateRegionLayout]
  notes : Array[StateNoteLayout]
}

///|
priv struct StateVisibleNode {
  state : @flow.StateNode
  child : StateFragment?
}

///|
const STATE_CANVAS_PADDING : Double = 28.0

///|
const STATE_INTERNAL_PADDING : Double = 18.0

///|
const STATE_HEADER_HEIGHT : Double = 26.0

///|
const STATE_REGION_GAP : Double = 18.0

///|
const STATE_EMPTY_NODE_MIN_WIDTH : Double = 50.0

///|
const STATE_EMPTY_NODE_MIN_HEIGHT : Double = 40.0

///|
const STATE_COMPARTMENT_MIN_WIDTH : Double = 50.0

///|
const STATE_COMPARTMENT_MIN_HEIGHT : Double = 50.0

///|
const STATE_EMPTY_NODE_PADDING : Double = 10.0

///|
const STATE_COMPARTMENT_PADDING : Double = 20.0

///|
const STATE_SYNC_WIDTH : Double = 96.0

///|
const STATE_SYNC_HEIGHT : Double = 12.0

///|
const STATE_TERMINAL_SIZE : Double = 24.0

///|
fn plantuml_state_nodesep_in() -> Double {
  35.0 / @graphviz.GRAPHVIZ_DPI
}

///|
fn plantuml_state_ranksep_in() -> Double {
  35.0 / @graphviz.GRAPHVIZ_DPI
}

///|
fn state_graphviz_node_name(index : Int) -> String {
  "s" + index.to_string()
}

///|
fn shift_state_node(
  node : StateNodeLayout,
  dx : Double,
  dy : Double,
) -> StateNodeLayout {
  { ..node, x: node.x + dx, y: node.y + dy }
}

///|
fn shift_state_edge(
  edge : StateEdgeLayout,
  dx : Double,
  dy : Double,
) -> StateEdgeLayout {
  {
    ..edge,
    paths: edge.paths.map(path => {
      path.map(point => (point.0 + dx, point.1 + dy))
    }),
    label: edge.label.map(point => (point.0 + dx, point.1 + dy)),
  }
}

///|
fn shift_state_region(
  region : StateRegionLayout,
  dx : Double,
  dy : Double,
) -> StateRegionLayout {
  { ..region, x: region.x + dx, y: region.y + dy }
}

///|
fn shift_state_note(
  note : StateNoteLayout,
  dx : Double,
  dy : Double,
) -> StateNoteLayout {
  { ..note, x: note.x + dx, y: note.y + dy }
}

///|
fn @flow.StateDiagram::has_children(
  self : @flow.StateDiagram,
  code : String,
) -> Bool {
  for state in self.states {
    if state.parent == Some(code) {
      return true
    }
  }
  false
}

///|
fn @flow.StateDiagram::regions_for(
  self : @flow.StateDiagram,
  parent : String,
) -> Array[@flow.StateRegion] {
  self.regions.filter(region => region.parent == parent)
}

///|
fn @flow.StateDiagram::scope_path(
  self : @flow.StateDiagram,
  code : String,
) -> Array[String] {
  let path : Array[String] = []
  let mut current = self.state(code)
  while current is Some(state) {
    path.push(state.code)
    current = state.parent.bind(parent => self.state(parent))
  }
  let output : Array[String] = []
  for entry in path {
    output.insert(0, entry)
  }
  output
}

///|
fn longest_common_state_path(
  left : Array[String],
  right : Array[String],
) -> String? {
  let mut common = None
  let length = left.length().min(right.length())
  for index in 0..<length {
    if left[index] == right[index] {
      common = Some(left[index])
    } else {
      return common
    }
  }
  common
}

///|
fn @flow.StateDiagram::transition_scope(
  self : @flow.StateDiagram,
  transition : @flow.StateTransition,
) -> String? {
  longest_common_state_path(
    self.scope_path(transition.source),
    self.scope_path(transition.target),
  )
}

///|
fn @flow.StateDiagram::transition_region_index(
  self : @flow.StateDiagram,
  transition : @flow.StateTransition,
  scope : String?,
) -> Int {
  match scope {
    None => -1
    Some(scope) =>
      match (self.state(transition.source), self.state(transition.target)) {
        (Some(source), Some(target)) if source.parent == Some(scope) &&
          target.parent == Some(scope) &&
          source.region_index == target.region_index => source.region_index
        _ => -1
      }
  }
}

///|
fn @flow.StateDiagram::transition_visible_endpoint(
  self : @flow.StateDiagram,
  code : String,
  scope : String?,
) -> String {
  let path = self.scope_path(code)
  match scope {
    None => if path.length() > 0 { path[0] } else { code }
    Some(scope) =>
      match path.search_by(entry => entry == scope) {
        Some(index) if index + 1 < path.length() => path[index + 1]
        _ => code
      }
  }
}

///|
fn @flow.StateDiagram::state_note_scope(
  self : @flow.StateDiagram,
  target : String,
) -> String? {
  self.state(target).bind(state => state.parent)
}

///|
fn @flow.StateDiagram::state_note_region_index(
  self : @flow.StateDiagram,
  target : String,
  scope : String?,
) -> Int {
  match (self.state(target), scope) {
    (Some(state), Some(scope)) if state.parent == Some(scope) =>
      state.region_index
    _ => -1
  }
}

///|
fn @flow.StateDiagram::note_scope(
  self : @flow.StateDiagram,
  note : @flow.StateNote,
) -> String? {
  match note.target {
    @flow.StateNote(target) => self.state_note_scope(target)
    @flow.StateNoteTarget::TransitionNote(index) =>
      if index < self.transitions.length() {
        self.transition_scope(self.transitions[index])
      } else {
        None
      }
  }
}

///|
fn @flow.StateDiagram::note_region_index(
  self : @flow.StateDiagram,
  note : @flow.StateNote,
  scope : String?,
) -> Int {
  match note.target {
    @flow.StateNote(target) => self.state_note_region_index(target, scope)
    @flow.StateNoteTarget::TransitionNote(index) =>
      if index < self.transitions.length() {
        self.transition_region_index(self.transitions[index], scope)
      } else {
        -1
      }
  }
}

///|
fn @flow.StateDiagram::note_anchor(
  self : @flow.StateDiagram,
  note : @flow.StateNote,
  scope : String?,
) -> String? {
  match note.target {
    @flow.StateNote(target) =>
      Some(self.transition_visible_endpoint(target, scope))
    @flow.StateNoteTarget::TransitionNote(index) =>
      if index < self.transitions.length() {
        Some(
          self.transition_visible_endpoint(
            self.transitions[index].source,
            scope,
          ),
        )
      } else {
        None
      }
  }
}

///|
fn state_text_size(
  text : String,
  metrics : @metrics.FontMetrics,
) -> (Double, Double) {
  let measured = metrics.measure(text)
  (measured.width.to_double(), measured.height.to_double())
}

///|
fn state_note_size(
  note : @flow.StateNote,
  metrics : @metrics.FontMetrics,
) -> (Double, Double) {
  let (width, height) = state_text_size(note.text, metrics)
  ((width + 24.0).max(80.0), (height + 18.0).max(34.0))
}

///|
fn @flow.StateNode::leaf_size(
  self : @flow.StateNode,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
  hide_empty_description : Bool,
) -> (Double, Double) {
  match self.kind {
    @flow.StateKind::Initial
    | @flow.StateKind::Final
    | @flow.StateKind::History
    | @flow.StateKind::DeepHistory
    | @flow.StateKind::Choice => (STATE_TERMINAL_SIZE, STATE_TERMINAL_SIZE)
    @flow.StateKind::Synchronization => (STATE_SYNC_WIDTH, STATE_SYNC_HEIGHT)
    @flow.StateKind::Normal => {
      let name = state_text_size(self.display, name_metrics)
      if !self.has_description() && hide_empty_description {
        (
          (name.0 + STATE_EMPTY_NODE_PADDING).max(STATE_EMPTY_NODE_MIN_WIDTH),
          (name.1 + STATE_EMPTY_NODE_PADDING).max(STATE_EMPTY_NODE_MIN_HEIGHT),
        )
      } else {
        let description = self.description.map_or((0.0, 0.0), text => {
          state_text_size(text, description_metrics)
        })
        (
          (name.0.max(description.0) + STATE_COMPARTMENT_PADDING).max(
            STATE_COMPARTMENT_MIN_WIDTH,
          ),
          (name.1 + description.1 + STATE_COMPARTMENT_PADDING).max(
            STATE_COMPARTMENT_MIN_HEIGHT,
          ),
        )
      }
    }
  }
}

///|
fn @flow.StateDiagram::composite_fragment(
  self : @flow.StateDiagram,
  state : @flow.StateNode,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
) -> StateFragment? raise @dot_layout.DotLayoutError {
  guard self.has_children(state.code) else { return None }
  Some(self.layout_composite_state(state, name_metrics, description_metrics))
}

///|
fn @flow.StateDiagram::visible_nodes_for_scope(
  self : @flow.StateDiagram,
  scope : String?,
  region_index : Int,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
) -> Array[StateVisibleNode] raise @dot_layout.DotLayoutError {
  self.states.filter_map(state => {
    guard state.parent == scope else { return None }
    guard region_index < 0 || state.region_index == region_index else {
      return None
    }
    let child = self.composite_fragment(
      state, name_metrics, description_metrics,
    )
    Some({ state, child })
  })
}

///|
fn append_shifted_fragment(
  output : StateFragment,
  fragment : StateFragment,
  dx : Double,
  dy : Double,
) -> Unit {
  for node in fragment.nodes {
    output.nodes.push(shift_state_node(node, dx, dy))
  }
  for edge in fragment.edges {
    output.edges.push(shift_state_edge(edge, dx, dy))
  }
  for region in fragment.regions {
    output.regions.push(shift_state_region(region, dx, dy))
  }
  for note in fragment.notes {
    output.notes.push(shift_state_note(note, dx, dy))
  }
}

///|
fn @flow.StateDiagram::layout_scope(
  self : @flow.StateDiagram,
  scope : String?,
  region_index : Int,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
) -> StateFragment raise @dot_layout.DotLayoutError {
  let visible_nodes = self.visible_nodes_for_scope(
    scope, region_index, name_metrics, description_metrics,
  )
  let graph = @graphviz.new_directed_graph("state", self.style)
  let node_names : Map[String, String] = Map([])
  for index, visible in visible_nodes {
    let name = state_graphviz_node_name(index)
    node_names[visible.state.code] = name
    let node = graph.node(name)
    let (width, height) = visible.child.map_or(
      visible.state.leaf_size(
        name_metrics,
        description_metrics,
        self.hide_empty_description(),
      ),
      child => {
        (
          (child.width + STATE_INTERNAL_PADDING * 2.0).max(
            visible.state.leaf_size(
              name_metrics,
              description_metrics,
              self.hide_empty_description(),
            ).0,
          ),
          child.height + STATE_HEADER_HEIGHT + STATE_INTERNAL_PADDING,
        )
      },
    )
    @graphviz.set_fixed_node_size(node, width, height)
  }
  let transition_names : Map[Int, String] = Map([])
  for transition_index, transition in self.transitions {
    let route_scope = self.transition_scope(transition)
    guard route_scope == scope else { continue }
    guard self.transition_region_index(transition, scope) == region_index else {
      continue
    }
    let source = self.transition_visible_endpoint(transition.source, scope)
    let target = self.transition_visible_endpoint(transition.target, scope)
    guard node_names.get(source) is Some(source_name) else { continue }
    guard node_names.get(target) is Some(target_name) else { continue }
    let edge = graph.edge(
      graph.node(source_name),
      graph.node(target_name),
      name="t" + transition_index.to_string(),
    )
    transition_names[edge.id()] = transition_index.to_string()
    if transition.label is Some(label) {
      edge.set_attr("label", label)
    }
    match transition.direction {
      @flow.TransitionDirection::Leftward => edge.set_attr("dir", "back")
      _ => edge.set_attr("dir", "forward")
    }
    match transition.line_style {
      Some("dashed") | Some("dotted") => edge.set_attr("style", "dotted")
      Some("bold") => edge.set_attr("penwidth", "3")
      _ => ()
    }
  }
  let note_names : Map[String, Int] = Map([])
  let note_metrics = note_font_metrics(self.style)
  for note_index, note in self.notes {
    guard self.note_scope(note) == scope else { continue }
    guard self.note_region_index(note, scope) == region_index else { continue }
    let name = @graphviz.graphviz_note_name(note_index)
    note_names[name] = note_index
    let node = graph.node(name)
    let (width, height) = state_note_size(note, note_metrics)
    @graphviz.set_fixed_node_size(node, width, height, shape="note")
    match self.note_anchor(note, scope) {
      Some(anchor) => {
        guard node_names.get(anchor) is Some(anchor_name) else { continue }
        let anchor_node = graph.node(anchor_name)
        let edge = match note.position {
          Some(@flow.StateNotePosition::NoteRight)
          | Some(@flow.StateNotePosition::NoteBottom) =>
            graph.edge(anchor_node, node)
          _ => graph.edge(node, anchor_node)
        }
        edge.set_attr("dir", "none")
        edge.set_attr("style", "invis")
        match note.position {
          Some(@flow.StateNotePosition::NoteLeft)
          | Some(@flow.StateNotePosition::NoteRight) => {
            let same_rank = graph.subgraph()
            same_rank.set_attr("rank", "same")
            ignore(same_rank.node(name))
            ignore(same_rank.node(anchor_name))
          }
          _ => ()
        }
      }
      None => ()
    }
  }
  if visible_nodes.is_empty() {
    return {
      width: 1.0,
      height: 1.0,
      nodes: [],
      edges: [],
      regions: [],
      notes: [],
    }
  }
  let laid_out = @graphviz.layout_dot(
    graph,
    self.style,
    plantuml_state_nodesep_in(),
    plantuml_state_ranksep_in(),
  )
  let bbox = laid_out.bbox
  let output : StateFragment = {
    width: bbox.urx - bbox.llx,
    height: bbox.ury - bbox.lly,
    nodes: [],
    edges: [],
    regions: [],
    notes: [],
  }
  for node_layout in laid_out.nodes {
    let node_name = node_layout.node.name()
    for index, visible in visible_nodes {
      guard state_graphviz_node_name(index) == node_name else { continue }
      let point = @graphviz.graphviz_point_to_svg(node_layout.pos, bbox)
      let x = point.x
      let y = point.y
      let width = @graphviz.inches_to_points(node_layout.width_in)
      let height = @graphviz.inches_to_points(node_layout.height_in)
      let node_x = x - width / 2.0
      let node_y = y - height / 2.0
      output.nodes.push({
        code: visible.state.code,
        x: node_x,
        y: node_y,
        width,
        height,
      })
      if visible.child is Some(child) {
        append_shifted_fragment(
          output,
          child,
          node_x + STATE_INTERNAL_PADDING,
          node_y + STATE_HEADER_HEIGHT,
        )
      }
    }
  }
  for edge in @graphviz.graphviz_edges(laid_out, transition_names, bbox) {
    output.edges.push({
      transition_index: edge.index,
      paths: edge.splines.map(spline => spline.points.map(point => point.pair())),
      label: edge.label.map(point => point.pair()),
    })
  }
  for note in @graphviz.graphviz_notes(laid_out, note_names, bbox) {
    output.notes.push(self.correct_note_side(scope, output.nodes, note))
  }
  let mut min_x = 0.0
  let mut max_x = 0.0
  for node in output.nodes {
    if node.x + node.width > max_x {
      max_x = node.x + node.width
    }
  }
  for edge in output.edges {
    for path in edge.paths {
      for point in path {
        if point.0 > max_x {
          max_x = point.0
        }
      }
    }
    match edge.label {
      Some(point) if point.0 > max_x => max_x = point.0
      _ => ()
    }
  }
  for note in output.notes {
    if note.x < min_x {
      min_x = note.x
    }
    if note.x + note.width > max_x {
      max_x = note.x + note.width
    }
  }
  let dx = if min_x < 0.0 { -min_x } else { 0.0 }
  if dx == 0.0 && max_x <= output.width {
    output
  } else {
    {
      ..output,
      width: if dx > 0.0 {
        max_x + dx
      } else {
        output.width
      },
      nodes: output.nodes.map(node => { ..node, x: node.x + dx }),
      edges: output.edges.map(edge => {
        ..edge,
        paths: edge.paths.map(path => path.map(point => (point.0 + dx, point.1))),
        label: edge.label.map(point => (point.0 + dx, point.1)),
      }),
      regions: output.regions.map(region => { ..region, x: region.x + dx }),
      notes: output.notes.map(note => { ..note, x: note.x + dx }),
    }
  }
}

///|
/// Graphviz places a same-rank note beside its anchor, but the flat-edge
/// ordering is not honored for isolated rank pairs, so the note may land on
/// the wrong side. Mirror the note across its anchor with the same gap.
fn @flow.StateDiagram::correct_note_side(
  self : @flow.StateDiagram,
  scope : String?,
  nodes : Array[StateNodeLayout],
  note : @graphviz.GraphvizNote,
) -> StateNoteLayout {
  let note_index = note.note_index
  let layout : StateNoteLayout = {
    note_index,
    x: note.x,
    y: note.y,
    width: note.width,
    height: note.height,
  }
  guard note_index < self.notes.length() else { return layout }
  let position = self.notes[note_index].position
  guard position
    is (Some(@flow.StateNotePosition::NoteLeft)
    | Some(@flow.StateNotePosition::NoteRight)) else {
    return layout
  }
  guard self.note_anchor(self.notes[note_index], scope) is Some(anchor) else {
    return layout
  }
  guard note_anchor_rect(nodes, anchor) is Some((anchor_x, anchor_w)) else {
    return layout
  }
  let note_center = note.x + note.width / 2.0
  let anchor_center = anchor_x + anchor_w / 2.0
  let on_correct_side = if position is Some(@flow.StateNotePosition::NoteLeft) {
    note_center <= anchor_center
  } else {
    note_center >= anchor_center
  }
  if on_correct_side {
    return layout
  }
  let gap = if note_center >= anchor_center {
    note.x - (anchor_x + anchor_w)
  } else {
    anchor_x - (note.x + note.width)
  }
  let corrected_x = if position is Some(@flow.StateNotePosition::NoteLeft) {
    anchor_x - gap - note.width
  } else {
    anchor_x + anchor_w + gap
  }
  { ..layout, x: corrected_x }
}

///|
fn note_anchor_rect(
  nodes : Array[StateNodeLayout],
  anchor : String,
) -> (Double, Double)? {
  for node in nodes {
    if node.code == anchor {
      return Some((node.x, node.width))
    }
  }
  None
}

///|
fn stack_region_fragments(
  parent : String,
  regions : Array[@flow.StateRegion],
  fragments : Array[StateFragment],
) -> StateFragment {
  let output : StateFragment = {
    width: 1.0,
    height: 1.0,
    nodes: [],
    edges: [],
    regions: [],
    notes: [],
  }
  let horizontal = regions.any(region => {
    region.separator == Some(@flow.StateRegionSeparator::Vertical)
  })
  if horizontal {
    let mut x = 0.0
    let mut height = 1.0
    for index, fragment in fragments {
      let region = regions[index]
      output.regions.push({
        parent,
        region_index: region.index,
        separator: region.separator,
        x,
        y: 0.0,
        width: fragment.width,
        height: fragment.height,
      })
      append_shifted_fragment(output, fragment, x, 0.0)
      x += fragment.width
      if index + 1 < fragments.length() {
        x += STATE_REGION_GAP
      }
      height = height.max(fragment.height)
    }
    { ..output, width: x.max(1.0), height }
  } else {
    let mut y = 0.0
    let mut width = 1.0
    for index, fragment in fragments {
      let region = regions[index]
      output.regions.push({
        parent,
        region_index: region.index,
        separator: region.separator,
        x: 0.0,
        y,
        width: fragment.width,
        height: fragment.height,
      })
      append_shifted_fragment(output, fragment, 0.0, y)
      y += fragment.height
      if index + 1 < fragments.length() {
        y += STATE_REGION_GAP
      }
      width = width.max(fragment.width)
    }
    { ..output, width, height: y.max(1.0) }
  }
}

///|
fn @flow.StateDiagram::layout_composite_state(
  self : @flow.StateDiagram,
  state : @flow.StateNode,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
) -> StateFragment raise @dot_layout.DotLayoutError {
  let regions = self.regions_for(state.code)
  if regions.is_empty() {
    return self.layout_scope(
      Some(state.code),
      -1,
      name_metrics,
      description_metrics,
    )
  }
  let fragments = regions.map(region => {
    self.layout_scope(
      Some(state.code),
      region.index,
      name_metrics,
      description_metrics,
    )
  })
  stack_region_fragments(state.code, regions, fragments)
}

///|
fn @flow.StateDiagram::layout(
  self : @flow.StateDiagram,
) -> StateLayout raise @dot_layout.DotLayoutError {
  let name_metrics = state_font_metrics(self.style)
  let description_metrics = state_description_font_metrics(self.style)
  let fragment = self.layout_scope(None, -1, name_metrics, description_metrics)
  {
    width: fragment.width + STATE_CANVAS_PADDING * 2.0,
    height: fragment.height + STATE_CANVAS_PADDING * 2.0,
    nodes: fragment.nodes.map(node => {
      shift_state_node(node, STATE_CANVAS_PADDING, STATE_CANVAS_PADDING)
    }),
    edges: fragment.edges.map(edge => {
      shift_state_edge(edge, STATE_CANVAS_PADDING, STATE_CANVAS_PADDING)
    }),
    regions: fragment.regions.map(region => {
      shift_state_region(region, STATE_CANVAS_PADDING, STATE_CANVAS_PADDING)
    }),
    notes: fragment.notes.map(note => {
      shift_state_note(note, STATE_CANVAS_PADDING, STATE_CANVAS_PADDING)
    }),
  }
}

///|
/// Calculate PlantUML-style state-diagram geometry without rendering it.
pub fn layout_state(
  diagram : @flow.StateDiagram,
) -> StateLayout raise @dot_layout.DotLayoutError {
  diagram.layout()
}
