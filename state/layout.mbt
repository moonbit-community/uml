///|
pub struct StateNodeLayout {
  code : String
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub struct StateEdgeLayout {
  transition_index : Int
  paths : Array[Array[(Double, Double)]]
  label : (Double, Double)?
} derive(Eq, Debug)

///|
pub struct StateRegionLayout {
  parent : String
  region_index : Int
  separator : StateRegionSeparator?
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub struct StateNoteLayout {
  note_index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub struct StateLayout {
  width : Double
  height : Double
  nodes : Array[StateNodeLayout]
  edges : Array[StateEdgeLayout]
  regions : Array[StateRegionLayout]
  notes : Array[StateNoteLayout]
} derive(Eq, Debug)

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
  state : StateNode
  child : StateFragment?
}

///|
const STATE_DPI : Double = 72.0

///|
const STATE_CANVAS_PADDING : Double = 28.0

///|
const STATE_INTERNAL_PADDING : Double = 18.0

///|
const STATE_HEADER_HEIGHT : Double = 34.0

///|
const STATE_REGION_GAP : Double = 18.0

///|
const STATE_NODE_MIN_WIDTH : Double = 72.0

///|
const STATE_NODE_MIN_HEIGHT : Double = 46.0

///|
const STATE_SYNC_WIDTH : Double = 96.0

///|
const STATE_SYNC_HEIGHT : Double = 12.0

///|
const STATE_TERMINAL_SIZE : Double = 24.0

///|
fn StateDiagram::graphviz_rankdir(self : StateDiagram) -> @rankdir.RankDir {
  match self.style.layout_direction {
    Some(@core.LeftToRight) => @rankdir.LR
    _ => @rankdir.TB
  }
}

///|
fn plantuml_state_nodesep_in() -> Double {
  35.0 / STATE_DPI
}

///|
fn plantuml_state_ranksep_in() -> Double {
  60.0 / STATE_DPI
}

///|
fn state_graphviz_node_name(index : Int) -> String {
  "s" + index.to_string()
}

///|
fn state_graphviz_note_name(index : Int) -> String {
  "note" + index.to_string()
}

///|
fn state_graphviz_point_to_svg(
  point : @geom.Point,
  bbox : @geom.Rect,
) -> (Double, Double) {
  (point.x - bbox.llx, bbox.ury - point.y)
}

///|
fn state_graphviz_path_to_svg(
  spline : @geom.Spline,
  bbox : @geom.Rect,
) -> Array[(Double, Double)] {
  spline.points.map(point => state_graphviz_point_to_svg(point, bbox))
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
fn StateDiagram::state_by_code(
  self : StateDiagram,
  code : String,
) -> StateNode? {
  for state in self.states {
    if state.code == code {
      return Some(state)
    }
  }
  None
}

///|
fn StateDiagram::has_children(self : StateDiagram, code : String) -> Bool {
  for state in self.states {
    if state.parent == Some(code) {
      return true
    }
  }
  false
}

///|
fn StateDiagram::regions_for(
  self : StateDiagram,
  parent : String,
) -> Array[StateRegion] {
  let regions : Array[StateRegion] = []
  for region in self.regions {
    if region.parent == parent {
      regions.push(region)
    }
  }
  regions
}

///|
fn StateDiagram::scope_path(
  self : StateDiagram,
  code : String,
) -> Array[String] {
  let path : Array[String] = []
  let mut current = self.state_by_code(code)
  while current is Some(state) {
    path.push(state.code)
    current = match state.parent {
      Some(parent) => self.state_by_code(parent)
      None => None
    }
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
fn StateDiagram::transition_scope(
  self : StateDiagram,
  transition : StateTransition,
) -> String? {
  longest_common_state_path(
    self.scope_path(transition.source),
    self.scope_path(transition.target),
  )
}

///|
fn StateDiagram::transition_region_index(
  self : StateDiagram,
  transition : StateTransition,
  scope : String?,
) -> Int {
  match scope {
    None => -1
    Some(scope) =>
      match
        (
          self.state_by_code(transition.source),
          self.state_by_code(transition.target),
        ) {
        (Some(source), Some(target)) if source.parent == Some(scope) &&
          target.parent == Some(scope) &&
          source.region_index == target.region_index => source.region_index
        _ => -1
      }
  }
}

///|
fn StateDiagram::transition_visible_endpoint(
  self : StateDiagram,
  code : String,
  scope : String?,
) -> String {
  let path = self.scope_path(code)
  match scope {
    None => if path.length() > 0 { path[0] } else { code }
    Some(scope) => {
      let mut found = false
      for entry in path {
        if found {
          return entry
        }
        if entry == scope {
          found = true
        }
      }
      code
    }
  }
}

///|
fn StateDiagram::state_note_scope(
  self : StateDiagram,
  target : String,
) -> String? {
  match self.state_by_code(target) {
    Some(state) => state.parent
    None => None
  }
}

///|
fn StateDiagram::state_note_region_index(
  self : StateDiagram,
  target : String,
  scope : String?,
) -> Int {
  match (self.state_by_code(target), scope) {
    (Some(state), Some(scope)) if state.parent == Some(scope) =>
      state.region_index
    _ => -1
  }
}

///|
fn StateDiagram::note_scope(self : StateDiagram, note : StateNote) -> String? {
  match note.target {
    StateNote(target) => self.state_note_scope(target)
    TransitionNote(index) =>
      if index < self.transitions.length() {
        self.transition_scope(self.transitions[index])
      } else {
        None
      }
  }
}

///|
fn StateDiagram::note_region_index(
  self : StateDiagram,
  note : StateNote,
  scope : String?,
) -> Int {
  match note.target {
    StateNote(target) => self.state_note_region_index(target, scope)
    TransitionNote(index) =>
      if index < self.transitions.length() {
        self.transition_region_index(self.transitions[index], scope)
      } else {
        -1
      }
  }
}

///|
fn StateDiagram::note_anchor(
  self : StateDiagram,
  note : StateNote,
  scope : String?,
) -> String? {
  match note.target {
    StateNote(target) => Some(self.transition_visible_endpoint(target, scope))
    TransitionNote(index) =>
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
  let measured = @metrics.measure_text_with(text, metrics)
  (measured.width.to_double(), measured.height.to_double())
}

///|
fn state_note_size(
  note : StateNote,
  metrics : @metrics.FontMetrics,
) -> (Double, Double) {
  let (width, height) = state_text_size(note.text, metrics)
  ((width + 24.0).max(80.0), (height + 18.0).max(34.0))
}

///|
fn StateNode::leaf_size(
  self : StateNode,
  metrics : @metrics.FontMetrics,
) -> (Double, Double) {
  match self.kind {
    Initial | Final | History | DeepHistory | Choice =>
      (STATE_TERMINAL_SIZE, STATE_TERMINAL_SIZE)
    Synchronization => (STATE_SYNC_WIDTH, STATE_SYNC_HEIGHT)
    Normal => {
      let description = self.description.unwrap_or("")
      let text = if description.length() == 0 {
        self.display
      } else {
        self.display + "\n" + description
      }
      let (width, height) = state_text_size(text, metrics)
      (
        (width + 28.0).max(STATE_NODE_MIN_WIDTH),
        (height + 20.0).max(STATE_NODE_MIN_HEIGHT),
      )
    }
  }
}

///|
fn StateDiagram::composite_fragment(
  self : StateDiagram,
  state : StateNode,
  metrics : @metrics.FontMetrics,
) -> StateFragment? raise @dot_layout.DotLayoutError {
  guard self.has_children(state.code) else { return None }
  Some(self.layout_composite_state(state, metrics))
}

///|
fn StateDiagram::visible_nodes_for_scope(
  self : StateDiagram,
  scope : String?,
  region_index : Int,
  metrics : @metrics.FontMetrics,
) -> Array[StateVisibleNode] raise @dot_layout.DotLayoutError {
  let output : Array[StateVisibleNode] = []
  for state in self.states {
    guard state.parent == scope else { continue }
    guard region_index < 0 || state.region_index == region_index else {
      continue
    }
    let child = self.composite_fragment(state, metrics)
    output.push({ state, child })
  }
  output
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
fn StateDiagram::layout_scope(
  self : StateDiagram,
  scope : String?,
  region_index : Int,
  metrics : @metrics.FontMetrics,
) -> StateFragment raise @dot_layout.DotLayoutError {
  let visible_nodes = self.visible_nodes_for_scope(scope, region_index, metrics)
  let graph = @cgraph.Graph::new(@cgraph.Directed, name="state", strict=false)
  graph.set_attr(
    "rankdir",
    match self.graphviz_rankdir() {
      @rankdir.LR => "LR"
      @rankdir.TB => "TB"
      @rankdir.BT => "BT"
      @rankdir.RL => "RL"
    },
  )
  graph.set_attr("splines", "spline")
  let node_names : Map[String, String] = Map([])
  for index, visible in visible_nodes {
    let name = state_graphviz_node_name(index)
    node_names[visible.state.code] = name
    let node = graph.node(name)
    node.set_attr("label", "")
    node.set_attr("shape", "box")
    let (width, height) = match visible.child {
      Some(child) =>
        (
          (child.width + STATE_INTERNAL_PADDING * 2.0).max(
            visible.state.leaf_size(metrics).0,
          ),
          child.height + STATE_HEADER_HEIGHT + STATE_INTERNAL_PADDING,
        )
      None => visible.state.leaf_size(metrics)
    }
    node.set_attr("width", (width / STATE_DPI).to_string())
    node.set_attr("height", (height / STATE_DPI).to_string())
    node.set_attr("fixedsize", "true")
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
    match transition.label {
      Some(label) => edge.set_attr("label", label)
      None => ()
    }
    match transition.direction {
      Leftward => edge.set_attr("dir", "back")
      _ => edge.set_attr("dir", "forward")
    }
    match transition.line_style {
      Some("dashed") | Some("dotted") => edge.set_attr("style", "dotted")
      Some("bold") => edge.set_attr("penwidth", "3")
      _ => ()
    }
  }
  let note_names : Map[String, Int] = Map([])
  for note_index, note in self.notes {
    guard self.note_scope(note) == scope else { continue }
    guard self.note_region_index(note, scope) == region_index else { continue }
    let name = state_graphviz_note_name(note_index)
    note_names[name] = note_index
    let node = graph.node(name)
    let (width, height) = state_note_size(note, metrics)
    node.set_attr("label", "")
    node.set_attr("shape", "note")
    node.set_attr("width", (width / STATE_DPI).to_string())
    node.set_attr("height", (height / STATE_DPI).to_string())
    node.set_attr("fixedsize", "true")
    match self.note_anchor(note, scope) {
      Some(anchor) =>
        match node_names.get(anchor) {
          Some(anchor_name) => {
            let edge = graph.edge(node, graph.node(anchor_name))
            edge.set_attr("dir", "none")
            edge.set_attr("style", "invis")
          }
          None => ()
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
  let laid_out = @dot_layout.layout_dot(graph, options={
    rankdir: Some(self.graphviz_rankdir()),
    nodesep: Some(plantuml_state_nodesep_in()),
    ranksep: Some(plantuml_state_ranksep_in()),
    splines: Some(@dot_layout.SplinesMode::Spline),
  })
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
      let (x, y) = state_graphviz_point_to_svg(node_layout.pos, bbox)
      let node_x = x - node_layout.width_in * STATE_DPI / 2.0
      let node_y = y - node_layout.height_in * STATE_DPI / 2.0
      let width = node_layout.width_in * STATE_DPI
      let height = node_layout.height_in * STATE_DPI
      output.nodes.push({
        code: visible.state.code,
        x: node_x,
        y: node_y,
        width,
        height,
      })
      match visible.child {
        Some(child) =>
          append_shifted_fragment(
            output,
            child,
            node_x + STATE_INTERNAL_PADDING,
            node_y + STATE_HEADER_HEIGHT,
          )
        None => ()
      }
    }
  }
  for edge_layout in laid_out.edges {
    guard transition_names.get(edge_layout.edge.id()) is Some(index_text) else {
      continue
    }
    let transition_index = @string.parse_int(index_text) catch { _ => continue }
    let paths = edge_layout.splines.map(spline => {
      state_graphviz_path_to_svg(spline, bbox)
    })
    let label = edge_layout.label_pos.map(point => {
      state_graphviz_point_to_svg(point, bbox)
    })
    output.edges.push({ transition_index, paths, label })
  }
  for node_layout in laid_out.nodes {
    guard note_names.get(node_layout.node.name()) is Some(note_index) else {
      continue
    }
    let (x, y) = state_graphviz_point_to_svg(node_layout.pos, bbox)
    output.notes.push({
      note_index,
      x: x - node_layout.width_in * STATE_DPI / 2.0,
      y: y - node_layout.height_in * STATE_DPI / 2.0,
      width: node_layout.width_in * STATE_DPI,
      height: node_layout.height_in * STATE_DPI,
    })
  }
  output
}

///|
fn stack_region_fragments(
  parent : String,
  regions : Array[StateRegion],
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
  let horizontal = regions.any(region => region.separator == Some(Vertical))
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
fn StateDiagram::layout_composite_state(
  self : StateDiagram,
  state : StateNode,
  metrics : @metrics.FontMetrics,
) -> StateFragment raise @dot_layout.DotLayoutError {
  let regions = self.regions_for(state.code)
  if regions.is_empty() {
    return self.layout_scope(Some(state.code), -1, metrics)
  }
  let fragments : Array[StateFragment] = []
  for region in regions {
    fragments.push(self.layout_scope(Some(state.code), region.index, metrics))
  }
  stack_region_fragments(state.code, regions, fragments)
}

///|
pub fn StateDiagram::layout(
  self : StateDiagram,
) -> StateLayout raise @dot_layout.DotLayoutError {
  let metrics = self.style.font_metrics(font_size=14)
  let fragment = self.layout_scope(None, -1, metrics)
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
