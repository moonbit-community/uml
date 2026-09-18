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
  note_connections : Array[StateNoteConnection]
  cluster_titles : Map[String, Double]
}

///|
priv struct StateVisibleNode {
  state : @flow.StateNode
  child : StateFragment?
}

///|
const STATE_EMPTY_NODE_MIN_WIDTH : Double = 50.0

///|
const STATE_EMPTY_NODE_MIN_HEIGHT : Double = 40.0

///|
const STATE_COMPARTMENT_MIN_WIDTH : Double = 50.0

///|
const STATE_COMPARTMENT_MIN_HEIGHT : Double = 50.0

///|
const STATE_EMPTY_NODE_PADDING : Double = STATE_TEXT_MARGIN * 2.0

///|
const STATE_COMPARTMENT_PADDING : Double = (
    STATE_TEXT_MARGIN + STATE_SEPARATOR_MARGIN
  ) *
  2.0

///|
/// EntityImageSynchroBar: the long axis is perpendicular to the rank direction.
const STATE_SYNC_WIDTH : Double = 80.0

///|
const STATE_SYNC_HEIGHT : Double = 8.0

///|
/// CircleStart, CircleEnd, EntityImagePseudoState, and EntityImageBranch.
/// These sizes also agree with the checked-in PlantUML reference SVGs.
const STATE_INITIAL_SIZE : Double = 20.0

///|
const STATE_FINAL_SIZE : Double = 22.0

///|
const STATE_HISTORY_SIZE : Double = 22.0

///|
const STATE_CHOICE_SIZE : Double = 24.0

///|
/// SvekNode uses the actual outline for Graphviz endpoint clipping.
fn @flow.StateKind::graphviz_shape(self : @flow.StateKind) -> String {
  match self {
    Initial | Final | History | DeepHistory => "circle"
    Choice => "diamond"
    Normal | Frame | Synchronization => "box"
  }
}

///|
/// DotStringFactory minimum spacing for non-activity diagrams.
const STATE_MIN_NODESEP : Double = 35.0

///|
const STATE_MIN_RANKSEP : Double = 60.0

///|
/// LinkDecor.ARROW / ARROW_AND_CIRCLE.getMargin; CIRCLE_CROSS adds no margin.
const STATE_LINK_DECORATION_MARGIN : Double = 10.0

///|
/// DotStringFactory scales the largest label-plus-decoration extent by ten.
const STATE_SPACING_EXTENT_DIVISOR : Double = 10.0

///|
fn state_spacing_override(
  style : @style.DocumentStyle,
  key : String,
  fallback : Double,
) -> Double {
  guard style.property(key) is Some(text) else { return fallback }
  let value = @string.parse_int(text) catch { _ => return fallback }
  if value > 0 {
    value.to_double()
  } else {
    fallback
  }
}

///|
/// DotStringFactory and SvekEdge account for link labels before applying
/// the explicit nodesep/ranksep skin parameters, in points before DOT inches.
fn @flow.StateDiagram::graphviz_spacing(
  self : @flow.StateDiagram,
  scope : String?,
  region_index : Int,
) -> (Double, Double) {
  let mut nodesep = STATE_MIN_NODESEP
  let mut ranksep = STATE_MIN_RANKSEP
  for transition_index, transition in self.transitions {
    guard self.transition_scope(transition) == scope &&
      self.transition_region_index(transition, scope) == region_index else {
      continue
    }
    guard transition.source != transition.target else { continue }
    let label = self.transition_label_geometry(transition_index)
    let (width, height) = (label.width, label.height)
    if transition.length == 1 {
      nodesep = nodesep.max(
        (width + STATE_LINK_DECORATION_MARGIN) / STATE_SPACING_EXTENT_DIVISOR,
      )
    } else {
      ranksep = ranksep.max(
        (height + STATE_LINK_DECORATION_MARGIN) / STATE_SPACING_EXTENT_DIVISOR,
      )
    }
  }
  (
    @graphviz.points_to_inches(
      state_spacing_override(self.style, "nodesep", nodesep),
    ),
    @graphviz.points_to_inches(
      state_spacing_override(self.style, "ranksep", ranksep),
    ),
  )
}

///|
fn state_graphviz_node_name(index : Int) -> String {
  "s" + index.to_string()
}

///|
/// CommandLinkStateCommon inverts the DOT edge for left/up while preserving
/// the semantic transition ends. Drawing paths must be restored to that order.
fn @flow.StateTransition::layout_reversed(self : @flow.StateTransition) -> Bool {
  self.direction
  is (@flow.TransitionDirection::Leftward | @flow.TransitionDirection::Upward)
}

///|
fn shift_state_node(
  node : StateNodeLayout,
  dx : Double,
  dy : Double,
) -> StateNodeLayout {
  { ..node, x: node.x + dx, y: node.y + dy, }
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
  { ..region, x: region.x + dx, y: region.y + dy, }
}

///|
fn shift_state_note(
  note : StateNoteLayout,
  dx : Double,
  dy : Double,
) -> StateNoteLayout {
  { ..note, x: note.x + dx, y: note.y + dy, }
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
  self.regions.any(region => {
    region.parent == code && region.separator is Some(_)
  }) ||
  self.notes.any(note => {
    note.parent == Some(code) && !(note.target is @flow.TransitionNote(_))
  })
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
/// EntityUtils.isPureInnerLink3: a state is an autonomous image only when
/// no transition or entity-note edge crosses its boundary. The group itself
/// is outside its contents; package groups never become autonomous images.
fn @flow.StateDiagram::is_autonomous_state(
  self : @flow.StateDiagram,
  code : String,
) -> Bool {
  guard !self.state(code).map_or(false, state => state.kind == @flow.Frame) else {
    return false
  }
  let inside_note = (note : @flow.StateNote) => {
    note.parent.map_or(false, parent => self.scope_path(parent).contains(code))
  }
  self.notes.all(note => {
    let target_inside = match note.target {
      @flow.StateNote(target) =>
        target != code && self.scope_path(target).contains(code)
      @flow.NoteNote(index) => self.notes.get(index).map_or(false, inside_note)
      @flow.TransitionNote(_) => return true
    }
    inside_note(note) == target_inside
  }) &&
  self.transitions.all(transition => {
    let inside = endpoint => {
      endpoint != code && self.scope_path(endpoint).contains(code)
    }
    inside(transition.source) == inside(transition.target)
  })
}

///|
fn @flow.StateDiagram::is_state_cluster(
  self : @flow.StateDiagram,
  code : String,
) -> Bool {
  self.has_children(code) && !self.is_autonomous_state(code)
}

///|
/// CucaDiagramSimplifierState collapses autonomous groups from the inside
/// out. Concurrent groups always remain separate inner images (isAutarkic).
fn @flow.StateDiagram::state_graph_scope(
  self : @flow.StateDiagram,
  code : String,
) -> (String?, Int) {
  guard self.state(code) is Some(state) else { return (None, -1) }
  self.location_graph_scope(state.parent, state.region_index)
}

///|
fn @flow.StateDiagram::location_graph_scope(
  self : @flow.StateDiagram,
  parent : String?,
  region_index : Int,
) -> (String?, Int) {
  let mut current = parent
  let mut region_index = region_index
  while current is Some(parent) {
    if self.is_autonomous_state(parent) ||
      self.regions.any(region => {
        region.index == region_index && region.separator is Some(_)
      }) {
      return (Some(parent), region_index)
    }
    guard self.state(parent) is Some(state) else { break }
    current = state.parent
    region_index = state.region_index
  }
  (None, -1)
}

///|
fn @flow.StateDiagram::transition_scope(
  self : @flow.StateDiagram,
  transition : @flow.StateTransition,
) -> String? {
  self.state_graph_scope(transition.source).0
}

///|
fn @flow.StateDiagram::transition_region_index(
  self : @flow.StateDiagram,
  transition : @flow.StateTransition,
  _scope : String?,
) -> Int {
  self.state_graph_scope(transition.source).1
}

///|
fn @flow.StateDiagram::note_scope(
  self : @flow.StateDiagram,
  note : @flow.StateNote,
) -> String? {
  match note.target {
    @flow.StateNote(_) | @flow.NoteNote(_) =>
      self.location_graph_scope(note.parent, note.region_index).0
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
    @flow.StateNote(_) | @flow.NoteNote(_) =>
      self.location_graph_scope(note.parent, note.region_index).1
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
) -> String? {
  match note.target {
    @flow.StateNote(target) => Some(target)
    @flow.NoteNote(_) => None
    @flow.StateNoteTarget::TransitionNote(index) =>
      self.transitions.get(index).map(transition => transition.source)
  }
}

///|
fn state_text_size(
  text : String,
  metrics : @metrics.FontMetrics,
  wrap_width? : Double = 0.0,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
  literal_newlines? : Bool = false,
) -> (Double, Double) {
  if state_rich_text(
      text,
      metrics,
      wrap_width,
      monospaced_family~,
      literal_newlines~,
    )
    is Some(rich) {
    return (rich.width, rich.height)
  }
  let measured = metrics.measure(
    state_display(text, literal_newlines~).wrap(metrics, wrap_width).text,
  )
  (measured.width.to_double(), measured.height.to_double())
}

///|
/// SvekEdge.appendTable reserves the already measured label dimensions in
/// DOT. Graphviz must not remeasure the text using its own default font.
/// graphviz.mbt supports cell dimensions, so a borderless, unpadded cell
/// supplies the same rectangle as PlantUML's fixed-size table.
fn state_transition_label(width : Double, height : Double) -> String {
  let width = width.to_int()
  let height = height.to_int()
  (
    $|<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0"><TR><TD WIDTH="\{width}" HEIGHT="\{height}"></TD></TR></TABLE>>
  )
}

///|
fn @flow.StateNode::leaf_size(
  self : @flow.StateNode,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
  hide_empty_description : Bool,
  left_to_right~ : Bool,
  wrap_width? : Double = 0.0,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
  stereotype_size? : (Double, Double) = (0.0, 0.0),
) -> (Double, Double) {
  match self.kind {
    @flow.StateKind::Frame => {
      let title = state_text_size(
        self.display,
        name_metrics,
        monospaced_family~,
      )
      (
        title.0.max(stereotype_size.0) + STATE_PACKAGE_MARGIN * 2.0,
        (title.1 + stereotype_size.1).max(title.1 * 2.0) +
        STATE_PACKAGE_MARGIN * 2.0,
      )
    }
    @flow.StateKind::Initial => (STATE_INITIAL_SIZE, STATE_INITIAL_SIZE)
    @flow.StateKind::Final => (STATE_FINAL_SIZE, STATE_FINAL_SIZE)
    @flow.StateKind::History | @flow.StateKind::DeepHistory =>
      (STATE_HISTORY_SIZE, STATE_HISTORY_SIZE)
    @flow.StateKind::Choice => (STATE_CHOICE_SIZE, STATE_CHOICE_SIZE)
    @flow.StateKind::Synchronization =>
      if left_to_right {
        (STATE_SYNC_HEIGHT, STATE_SYNC_WIDTH)
      } else {
        (STATE_SYNC_WIDTH, STATE_SYNC_HEIGHT)
      }
    @flow.StateKind::Normal => {
      let name = state_text_size(
        self.display,
        name_metrics,
        wrap_width~,
        monospaced_family~,
      )
      if !self.has_description() && hide_empty_description {
        (
          (name.0 + STATE_EMPTY_NODE_PADDING).max(STATE_EMPTY_NODE_MIN_WIDTH),
          (name.1 + STATE_EMPTY_NODE_PADDING).max(STATE_EMPTY_NODE_MIN_HEIGHT),
        )
      } else {
        let description = self.description_size(
          description_metrics,
          wrap_width~,
          monospaced_family~,
        )
        let padding = STATE_COMPARTMENT_PADDING + self.submachine_extent()
        (
          (name.0.max(description.0) + padding).max(STATE_COMPARTMENT_MIN_WIDTH),
          (name.1 + description.1 + padding).max(STATE_COMPARTMENT_MIN_HEIGHT),
        )
      }
    }
  }
}

///|
fn @flow.StateDiagram::composite_fragment(
  self : @flow.StateDiagram,
  state : @flow.StateNode,
) -> StateFragment? raise @dot_layout.DotLayoutError {
  guard self.has_children(state.code) && self.is_autonomous_state(state.code) else {
    return None
  }
  Some(self.layout_composite_state(state))
}

///|
fn @flow.StateDiagram::visible_nodes_for_scope(
  self : @flow.StateDiagram,
  scope : String?,
  region_index : Int,
) -> Array[StateVisibleNode] raise @dot_layout.DotLayoutError {
  let output : Array[StateVisibleNode] = []
  for state in self.states {
    guard state.parent == scope else { continue }
    guard region_index < 0 || state.region_index == region_index else {
      continue
    }
    output.push({ state, child: self.composite_fragment(state), })
    if self.is_state_cluster(state.code) {
      // Later concurrent regions are independent image nodes, not flattened
      // into their parent's cluster. Only the initial region stays in this DOT.
      let initial_region = self
        .regions_for(state.code)
        .filter(region => region.separator is None)
        .get(0)
        .map_or(-1, region => region.index)
      output.append(
        self.visible_nodes_for_scope(Some(state.code), initial_region),
      )
    }
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
  for code, top in fragment.cluster_titles {
    output.cluster_titles[code] = top + dy
  }
  for connection in fragment.note_connections {
    output.note_connections.push(connection.shift(dx, dy))
  }
}

///|
/// Verified before Graphviz 0.1.10: semantic endpoint contacts, spacing,
/// reopened/qualified scopes, concurrent regions, child padding and note
/// placement in both rank directions. The cluster branch added for Graphviz
/// 0.1.10 has only been checked against Java source and compilation.
fn @flow.StateDiagram::layout_scope(
  self : @flow.StateDiagram,
  scope : String?,
  region_index : Int,
) -> StateFragment raise @dot_layout.DotLayoutError {
  let monospaced_family = state_monospaced_family(self.style)
  let visible_nodes = self.visible_nodes_for_scope(scope, region_index)
  let graph = @graphviz.new_directed_graph("state", self.style)
  let routing = state_graphviz_routing(self.style)
  graph.set_attr("splines", routing)
  let external_labels = routing == "ortho"
  if external_labels {
    graph.set_attr("forcelabels", "true")
  }
  let node_names : Map[String, String] = Map([])
  let containers : Map[String, @cgraph.Graph] = Map([])
  let cluster_codes : Map[String, String] = Map([])
  let region_images : Map[String, (StateFragment, @flow.StateRegion)] = Map([])
  let left_to_right = self.style.layout_direction is Some(LeftToRight)
  for index, visible in visible_nodes {
    let name_metrics = resolve_state_node_font(self, visible.state, StateLabel).metrics
    let description_metrics = resolve_state_font(
        self.style,
        StateDescription,
        state=Some(visible.state),
      ).metrics
    let name = state_graphviz_node_name(index)
    node_names[visible.state.code] = name
    let parent = visible.state.parent
      .bind(code => containers.get(code))
      .unwrap_or(graph)
    if self.is_state_cluster(visible.state.code) {
      let cluster_name = "cluster_state" + index.to_string()
      cluster_codes[cluster_name] = visible.state.code
      let has_endpoint = self.transitions.any(transition => {
          transition.source == visible.state.code ||
          transition.target == visible.state.code
        }) ||
        self.notes.any(note => {
          note.target == @flow.StateNote(visible.state.code)
        })
      let container = create_state_cluster(
        parent,
        cluster_name,
        visible.state,
        has_endpoint,
        name,
        name_metrics,
        description_metrics,
        self.style,
      )
      containers[visible.state.code] = container
      for region in self.regions_for(visible.state.code) {
        guard region.separator is Some(_) else { continue }
        let fragment = self.layout_state_region(region)
        let region_name = "region" + region.index.to_string()
        region_images[region_name] = (fragment, region)
        @graphviz.set_fixed_node_size(
          container.node(region_name),
          fragment.width,
          fragment.height,
        )
      }
      continue
    }
    let node = parent.node(name)
    let leaf_size = visible.state.leaf_size(
      name_metrics,
      description_metrics,
      self.state_uses_empty_image(visible.state),
      left_to_right~,
      wrap_width=state_wrap_width(self.style, state=Some(visible.state)),
      monospaced_family~,
      stereotype_size=if visible.state.kind == @flow.Frame {
        state_frame_stereotype_size(
          visible.state,
          self.style,
          PackageStereotype,
        )
      } else {
        (0.0, 0.0)
      },
    )
    let (width, height) = visible.child.map_or(leaf_size, child => {
      visible.state.composite_size(
        child,
        name_metrics,
        description_metrics,
        monospaced_family~,
      )
    })
    @graphviz.set_fixed_node_size(
      node,
      width,
      height,
      shape=visible.state.kind.graphviz_shape(),
    )
  }
  let transition_names : Map[Int, String] = Map([])
  for transition_index, transition in self.transitions {
    let route_scope = self.transition_scope(transition)
    guard route_scope == scope else { continue }
    guard self.transition_region_index(transition, scope) == region_index else {
      continue
    }
    let source = transition.source
    let target = transition.target
    guard node_names.get(source) is Some(source_name) else { continue }
    guard node_names.get(target) is Some(target_name) else { continue }
    let (tail_name, head_name) = if transition.layout_reversed() {
      (target_name, source_name)
    } else {
      (source_name, target_name)
    }
    if transition.length == 1 {
      let common = longest_common_state_path(
        self
        .state(source)
        .bind(state => state.parent)
        .map_or([], code => self.scope_path(code)),
        self
        .state(target)
        .bind(state => state.parent)
        .map_or([], code => self.scope_path(code)),
      )
      let same_rank = common
        .bind(code => containers.get(code))
        .unwrap_or(graph)
        .subgraph()
      same_rank.set_attr("rank", "same")
      ignore(same_rank.node(tail_name))
      ignore(same_rank.node(head_name))
    }
    let edge = graph.edge(
      graph.node(tail_name),
      graph.node(head_name),
      name="t" + transition_index.to_string(),
    )
    transition_names[edge.id()] = transition_index.to_string()
    if transition.has_line_style("norank") {
      edge.set_attr("constraint", "false")
    }
    if transition.length != 1 {
      edge.set_attr("minlen", (transition.length - 1).to_string())
    }
    let label = self.transition_label_geometry(transition_index)
    if label.width > 0.0 && label.height > 0.0 {
      edge.set_attr_value(
        if external_labels {
          "xlabel"
        } else {
          "label"
        },
        @cgraph.Html(state_transition_label(label.width, label.height)),
      )
    }
    // Link.getLinkStrategy / LinkType.getSpecificDecorationSvek: PlantUML
    // requests full node contacts, then creates and trims its own extremities.
    // Paint styles must not alter Graphviz's arrow clipping or path geometry.
    edge.set_attr("arrowhead", "none")
    edge.set_attr("arrowtail", "none")
  }
  let note_names : Map[String, Int] = Map([])
  let note_edge_names : Map[Int, String] = Map([])
  let note_metrics = resolve_state_font(self.style, NoteLabel).metrics
  for note_index, note in self.notes {
    guard !(note.target is @flow.TransitionNote(_)) else { continue }
    guard self.note_scope(note) == scope else { continue }
    guard self.note_region_index(note, scope) == region_index else { continue }
    let name = @graphviz.graphviz_note_name(note_index)
    note_names[name] = note_index
    let parent = note.parent.bind(code => containers.get(code)).unwrap_or(graph)
    let node = parent.node(name)
    let (width, height) = state_note_size(note, note_metrics, self.style)
    @graphviz.set_fixed_node_size(node, width, height, shape="box")
    let anchor_name = match note.target {
      @flow.StateNote(code) => node_names.get(code)
      @flow.NoteNote(index) => Some(@graphviz.graphviz_note_name(index))
      @flow.TransitionNote(_) => None
    }
    guard anchor_name is Some(anchor_name) else { continue }
    let anchor_node = graph.node(anchor_name)
    let position = note.position.map(position => {
      position.with_rankdir(self.style)
    })
    let edge = if position is Some(NoteRight) || position is Some(NoteBottom) {
      graph.edge(anchor_node, node)
    } else {
      graph.edge(node, anchor_node)
    }
    note_edge_names[edge.id()] = note_index.to_string()
    edge.set_attr("dir", "none")
    edge.set_attr("arrowhead", "none")
    edge.set_attr("arrowtail", "none")
    if position is Some(NoteLeft) || position is Some(NoteRight) {
      let anchor_parent = match note.target {
        @flow.StateNote(code) => self.state(code).bind(state => state.parent)
        @flow.NoteNote(index) => self.notes.get(index).bind(note => note.parent)
        @flow.TransitionNote(_) => None
      }
      let common = longest_common_state_path(
          note.parent.map_or([], code => self.scope_path(code)),
          anchor_parent.map_or([], code => self.scope_path(code)),
        )
        .bind(code => containers.get(code))
        .unwrap_or(graph)
      let same_rank = common.subgraph()
      same_rank.set_attr("rank", "same")
      ignore(same_rank.node(name))
      ignore(same_rank.node(anchor_name))
    }
  }
  if visible_nodes.is_empty() && note_names.is_empty() {
    return {
      width: 1.0,
      height: 1.0,
      nodes: [],
      edges: [],
      regions: [],
      notes: [],
      note_connections: [],
      cluster_titles: Map([]),
    }
  }
  let laid_out = if scope is Some(_) {
    // GroupMakerState.buildImage supplies no outer graph attributes: DOT
    // uses its internal defaults, while rankdir is still set on the graph.
    @dot_layout.layout_dot(graph)
  } else {
    let (nodesep, ranksep) = self.graphviz_spacing(scope, region_index)
    @graphviz.layout_dot(graph, self.style, nodesep, ranksep)
  }
  let bbox = laid_out.bbox
  let output : StateFragment = {
    width: bbox.urx - bbox.llx,
    height: bbox.ury - bbox.lly,
    nodes: [],
    edges: [],
    regions: [],
    notes: [],
    note_connections: [],
    cluster_titles: Map([]),
  }
  append_state_cluster_layouts(self, output, laid_out, bbox, cluster_codes)
  for node_layout in laid_out.nodes {
    let node_name = node_layout.node.name()
    if region_images.get(node_name) is Some((fragment, region)) {
      let (x, y, width, height) = @graphviz.graphviz_node_rect(
        node_layout, bbox,
      )
      output.regions.push({
        parent: region.parent,
        region_index: region.index,
        separator: region.separator,
        x,
        y,
        width,
        height,
      })
      append_shifted_fragment(output, fragment, x, y)
      continue
    }
    for index, visible in visible_nodes {
      guard state_graphviz_node_name(index) == node_name &&
        !self.is_state_cluster(visible.state.code) else {
        continue
      }
      let (node_x, node_y, width, height) = @graphviz.graphviz_node_rect(
        node_layout, bbox,
      )
      output.nodes.push({
        code: visible.state.code,
        x: node_x,
        y: node_y,
        width,
        height,
      })
      if visible.child is Some(child) {
        let name_metrics = resolve_state_font(
            self.style,
            StateLabel,
            state=Some(visible.state),
          ).metrics
        let description_metrics = resolve_state_font(
            self.style,
            StateDescription,
            state=Some(visible.state),
          ).metrics
        append_shifted_fragment(
          output,
          child,
          node_x + STATE_TEXT_MARGIN,
          node_y +
          visible.state.composite_content_y(
            name_metrics,
            description_metrics,
            monospaced_family~,
          ),
        )
      }
    }
  }
  for
    edge in @graphviz.graphviz_edges(
      laid_out,
      transition_names,
      bbox,
      external_labels~,
    ) {
    let label = self.transition_label_geometry(edge.index)
    let label_origin = edge.label.map(center => {
      (center.x - label.width / 2.0, center.y - label.height / 2.0)
    })
    if label_origin is Some(origin) && label.note is Some(note) {
      output.notes.push(shift_state_note(note, origin.0, origin.1))
    }
    output.edges.push({
      transition_index: edge.index,
      paths: edge.splines.map(spline => {
        let points = spline.points.map(point => point.pair())
        let transition = self.transitions[edge.index]
        let points = if transition.layout_reversed() {
          points.rev()
        } else {
          points
        }
        let cluster = code => {
          guard self.is_state_cluster(code) else { return None }
          output.nodes
          .search_by(node => node.code == code)
          .map(index => output.nodes[index])
        }
        clip_state_cluster_path(
          points,
          cluster(transition.source),
          cluster(transition.target),
        )
      }),
      label: label_origin.bind(origin => {
        label.text_center.map(center => {
          (origin.0 + center.0, origin.1 + center.1)
        })
      }),
    })
  }
  for note in @graphviz.graphviz_notes(laid_out, note_names, bbox) {
    output.notes.push({
      note_index: note.note_index,
      x: note.x,
      y: note.y,
      width: note.width,
      height: note.height,
    })
  }
  for edge in @graphviz.graphviz_edges(laid_out, note_edge_names, bbox) {
    guard output.notes.search_by(note => note.note_index == edge.index)
      is Some(index) else {
      continue
    }
    let note = output.notes[index]
    let anchor = self.note_anchor(self.notes[edge.index])
    let cluster = anchor
      .filter(code => self.is_state_cluster(code))
      .bind(code => output.nodes.search_by(node => node.code == code))
      .map(index => output.nodes[index])
    let edge = {
      ..edge,
      splines: edge.splines.map(spline => {
        let points = clip_state_cluster_path(
          spline.points.map(point => point.pair()),
          cluster,
          cluster,
        )
        {
          ..spline,
          points: points.map(point => @graphviz.GraphvizPoint::{
            x: point.0,
            y: point.1,
          }),
        }
      }),
    }
    if state_note_connection(edge, note) is Some(connection) {
      output.note_connections.push(connection)
    }
  }
  output
}

///|
/// ConcurrentStates stacks complete inner images with no extra inter-region
/// gap. Separators span the total cross-axis extent, including narrower regions.
fn stack_region_fragments(
  parent : String,
  regions : Array[@flow.StateRegion],
  fragments : Array[StateFragment],
) -> StateFragment {
  let separator = regions
    .search_by(region => region.separator is Some(_))
    .bind(index => regions[index].separator)
    .unwrap_or(@flow.StateRegionSeparator::Horizontal)
  let side_by_side = separator == @flow.StateRegionSeparator::Vertical
  let (width, height) = fragments.fold(init=(0.0, 0.0), (total, fragment) => {
    if side_by_side {
      (total.0 + fragment.width, total.1.max(fragment.height))
    } else {
      (total.0.max(fragment.width), total.1 + fragment.height)
    }
  })
  let output : StateFragment = {
    width,
    height,
    nodes: [],
    edges: [],
    regions: [],
    notes: [],
    note_connections: [],
    cluster_titles: Map([]),
  }
  let mut offset = 0.0
  for index, fragment in fragments {
    let region = regions[index]
    let x = if side_by_side { offset } else { 0.0 }
    let y = if side_by_side { 0.0 } else { offset }
    output.regions.push({
      parent,
      region_index: region.index,
      separator: region.separator.map(_ => separator),
      x,
      y,
      width: if side_by_side {
        fragment.width
      } else {
        width
      },
      height: if side_by_side {
        height
      } else {
        fragment.height
      },
    })
    append_shifted_fragment(output, fragment, x, y)
    offset += if side_by_side { fragment.width } else { fragment.height }
  }
  output
}

///|
fn @flow.StateDiagram::layout_composite_state(
  self : @flow.StateDiagram,
  state : @flow.StateNode,
) -> StateFragment raise @dot_layout.DotLayoutError {
  let regions = self.regions_for(state.code)
  if regions.is_empty() {
    return normalize_state_fragment(
      self,
      self.layout_scope(Some(state.code), -1),
      STATE_IMAGE_MARGIN,
    )
  }
  let fragments = regions.map(region => self.layout_state_region(region))
  stack_region_fragments(state.code, regions, fragments)
}

///|
fn @flow.StateDiagram::drawing_layout(
  self : @flow.StateDiagram,
) -> StateDrawingLayout raise @dot_layout.DotLayoutError {
  // Baseline SVGs reserve the image margin after the translated drawing's
  // maximum coordinate. Inner images use SvekResult's unshifted dimension.
  let fragment = normalize_state_fragment(
    self,
    self.layout_scope(None, -1),
    STATE_IMAGE_ORIGIN + STATE_IMAGE_MARGIN,
  )
  decorate_state_document(self, {
    layout: fragment.as_layout(),
    note_connections: fragment.note_connections,
    cluster_titles: fragment.cluster_titles,
    document: [],
  })
}

///|
fn @flow.StateDiagram::layout(
  self : @flow.StateDiagram,
) -> StateLayout raise @dot_layout.DotLayoutError {
  self.drawing_layout().layout
}

///|
/// Calculate PlantUML-style state-diagram geometry without rendering it.
pub fn layout_state(
  diagram : @flow.StateDiagram,
) -> StateLayout raise @dot_layout.DotLayoutError {
  diagram.layout()
}

///|
fn @flow.StateDiagram::layout_state_region(
  self : @flow.StateDiagram,
  region : @flow.StateRegion,
) -> StateFragment raise @dot_layout.DotLayoutError {
  if self.empty_state_region_fragment(region) is Some(fragment) {
    return fragment
  }
  normalize_state_fragment(
    self,
    self.layout_scope(Some(region.parent), region.index),
    STATE_IMAGE_MARGIN,
  )
}

///|
/// ClusterDotString uses a point node for links naming a non-autonomous group.
const STATE_CLUSTER_ENDPOINT_SIZE : Double = 0.01

///|
/// ClusterHeader includes the title and optional fields; ClusterDotString
/// subtracts the title margin when reserving the HTML label rectangle.
fn state_cluster_label_size(
  state : @flow.StateNode,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
  style : @style.DocumentStyle,
) -> (Double, Double) {
  let monospaced_family = state_monospaced_family(style)
  let title = state_text_size(state.display, name_metrics, monospaced_family~)
  let title = if state.kind == @flow.Frame {
    let stereo = state_frame_stereotype_size(state, style, StateStereotype)
    (title.0.max(stereo.0), title.1 + stereo.1)
  } else {
    title
  }
  guard title.0 > 0.0 else { return (0.0, 0.0) }
  let description = state.description_size(
    description_metrics,
    monospaced_family~,
  )
  (
    title.0.max(description.0).to_int().to_double(),
    (title.1 +
    state.description_compartment_height(
      description_metrics,
      monospaced_family~,
    ))
    .to_int()
    .to_double() -
    STATE_TEXT_MARGIN,
  )
}

///|
/// ClusterDotString preserves p0/p1 protection clusters. A group endpoint
/// adds outer/inner protection and a point outside the protected contents.
fn create_state_cluster(
  parent : @cgraph.Graph,
  name : String,
  state : @flow.StateNode,
  has_endpoint : Bool,
  endpoint_name : String,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
  style : @style.DocumentStyle,
) -> @cgraph.Graph {
  let parent = if has_endpoint {
    let protection = parent.subgraph(name=name + "a")
    protection.set_attr("label", "")
    protection
  } else {
    parent
  }
  let before = parent.subgraph(name=name + "p0")
  before.set_attr("label", "")
  let cluster = before.subgraph(name~)
  let (width, height) = state_cluster_label_size(
    state, name_metrics, description_metrics, style,
  )
  if width > 0.0 {
    cluster.set_attr_value(
      "label",
      @cgraph.Html(state_transition_label(width, height)),
    )
  } else {
    cluster.set_attr("label", "")
  }
  cluster.set_attr("labelloc", "t")
  let alignment = state_skinparam_alignment(
    style,
    "packageTitleAlignment",
    Middle,
  )
  cluster.set_attr(
    "labeljust",
    match alignment {
      Start => "l"
      Middle => "c"
      End => "r"
    },
  )
  let content = if has_endpoint {
    let point = cluster.node(endpoint_name)
    point.set_attr("shape", "point")
    point.set_attr("width", STATE_CLUSTER_ENDPOINT_SIZE.to_string())
    point.set_attr("label", "")
    let protection = cluster.subgraph(name=name + "i")
    protection.set_attr("label", "")
    protection
  } else {
    cluster
  }
  let after = content.subgraph(name=name + "p1")
  after.set_attr("label", "")
  after
}

///|
/// DOT cluster boxes and label locations share the root coordinate system.
/// Keep title positions with the drawing so normalization cannot detach them.
fn append_state_cluster_layouts(
  diagram : @flow.StateDiagram,
  output : StateFragment,
  layout : @dot_layout.DotLayoutGraph,
  root_bbox : @geom.Rect,
  cluster_codes : Map[String, String],
) -> Unit {
  if layout.graph.name().bind(name => cluster_codes.get(name)) is Some(code) {
    let bbox = layout.bbox
    output.nodes.push({
      code,
      x: bbox.llx - root_bbox.llx,
      y: root_bbox.ury - bbox.ury,
      width: bbox.urx - bbox.llx,
      height: bbox.ury - bbox.lly,
    })
    if layout.label_pos is Some(center) && diagram.state(code) is Some(state) {
      let (_, height) = state_cluster_label_size(
        state,
        resolve_state_node_font(diagram, state, StateLabel).metrics,
        resolve_state_font(diagram.style, StateDescription, state=Some(state)).metrics,
        diagram.style,
      )
      output.cluster_titles[code] = root_bbox.ury - center.y - height / 2.0
    }
  }
  for child in layout.subgraphs {
    append_state_cluster_layouts(
      diagram, output, child, root_bbox, cluster_codes,
    )
  }
}
