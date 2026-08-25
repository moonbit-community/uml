///|
/// Geometry returned by Graphviz for one class node.
pub struct GraphvizNodeLayout {
  code : String
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend GraphvizNodeLayout with Eq::{not_equal, equal}

///|
pub extend GraphvizNodeLayout with Debug::{to_repr}

///|
pub struct GraphvizPackageLayout {
  package_index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend GraphvizPackageLayout with Eq::{not_equal, equal}

///|
pub extend GraphvizPackageLayout with Debug::{to_repr}

///|
/// Complete Graphviz layout normalized to an SVG coordinate system.
pub struct GraphvizLayout {
  width : Double
  height : Double
  nodes : Array[GraphvizNodeLayout]
  edges : Array[@graphviz.GraphvizEdge]
  note_edges : Array[@graphviz.GraphvizEdge]
  relation_labels : Array[RelationLabelLayout]
  packages : Array[GraphvizPackageLayout]
  notes : Array[@graphviz.GraphvizNote]
} derive(Eq, Debug)

///|
pub extend GraphvizLayout with Eq::{not_equal, equal}

///|
pub extend GraphvizLayout with Debug::{to_repr}

///|
const PLANTUML_MIN_NODESEP_IN : Double = 35.0 / @graphviz.GRAPHVIZ_DPI

///|
const PLANTUML_MIN_RANKSEP_IN : Double = 60.0 / @graphviz.GRAPHVIZ_DPI

///|
const PLANTUML_RELATION_LABEL_FONT_SIZE : Int = 13

///|
/// Defaults returned by CucaDiagram#getLabeldistance/getLabelangle.
const PLANTUML_LABEL_DISTANCE : String = "1.7"

///|
const PLANTUML_LABEL_ANGLE : String = "25"

///|
fn graphviz_node_name(index : Int) -> String {
  "n\{index}"
}

///|
const LINK_NOTE_GAP : Double = 12.0

///|
/// PlantUML `ClusterDotString` title node height (the `za` title table).
const GROUP_POINT_TITLE_HEIGHT : Double = 16.0

///|
fn graphviz_cluster_name(index : Int) -> String {
  "cluster_package\{index}"
}

///|
fn graphviz_entity_index(
  diagram : @entity.EntityDiagram,
  node_name : String,
) -> Int? {
  for index, entity in diagram.entities {
    if !entity.is_hidden &&
      !entity.is_removed &&
      graphviz_node_name(index) == node_name {
      return Some(index)
    }
  }
  None
}

///|
/// PlantUML converts note positions into Graphviz's rank coordinate system
/// before it creates the attachment link. `Position.withRankdir` rotates the
/// four positions when the diagram is laid out from left to right.
fn @entity.NotePosition::with_rankdir(
  self : @entity.NotePosition,
  style : @style.DocumentStyle,
) -> @entity.NotePosition {
  guard style.layout_direction is Some(LeftToRight) else { return self }
  match self {
    Right => Bottom
    Left => Top
    Bottom => Right
    Top => Left
  }
}

///|
fn append_package_layouts(
  output : Array[GraphvizPackageLayout],
  layout : @dot_layout.DotLayoutGraph,
  root_bbox : @geom.Rect,
  package_indices : Map[String, Int],
) -> Unit {
  if layout.graph.name() is Some(name) {
    if package_indices.get(name) is Some(package_index) {
      let bbox = layout.bbox
      output.push({
        package_index,
        x: bbox.llx - root_bbox.llx,
        y: root_bbox.ury - bbox.ury,
        width: bbox.urx - bbox.llx,
        height: bbox.ury - bbox.lly,
      })
    }
  }
  for child in layout.subgraphs {
    append_package_layouts(output, child, root_bbox, package_indices)
  }
}

///|
fn note_size(
  note : @entity.Note,
  text_metrics : ClassTextMetrics,
) -> (Int, Int) {
  let lines = note.text.split("\n").to_array()
  let mut width = 0
  for line in lines {
    width = width.max(
      text_metrics.note.measure(line.to_owned()).width +
      NOTE_LEFT_PADDING +
      NOTE_RIGHT_PADDING,
    )
  }
  (
    width,
    lines.length().max(1) * text_metrics.note.line_height +
    2 * NOTE_VERTICAL_PADDING,
  )
}

///|
/// PlantUML parity: `CommandLinkElement` collapses the queue to a single
/// dash whenever an explicit left/right direction word is present, so those
/// links always carry dot `minlen=0`. Every other link counts its stroke
/// characters (`-=~.`) and maps `queue.length()` to `minlen = length - 1`.
fn @entity.Relation::graphviz_minlen(self : @entity.Relation) -> Int {
  if self.direction is Leftward || self.direction is Rightward {
    0
  } else {
    let mut segments = 0
    for char in self.raw_arrow {
      if char == '-' || char == '.' || char == '=' || char == '~' {
        segments += 1
      }
    }
    (segments - 1).max(0)
  }
}

///|
/// Build and execute the in-process Graphviz DOT layout.
fn @entity.EntityDiagram::graphviz_layout(
  self : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> GraphvizLayout raise @dot_layout.DotLayoutError {
  let family_capability = self.family.capability()
  let usecase = family_capability.usecase_relation_style
  let graph = @graphviz.new_directed_graph("class", self.style)
  graph.set_attr("remincross", "true")
  graph.set_attr("searchsize", "500")
  let package_content_graphs : Map[String, @cgraph.Graph] = Map([])
  let package_indices : Map[String, Int] = Map([])
  for package_index, group in self.packages {
    let parent = package_content_graphs.get(group.parent).unwrap_or(graph)
    let cluster_name = graphviz_cluster_name(package_index)
    // Java ClusterDotString places normal package nodes in nested p0/p1
    // protection clusters. These clusters affect sibling ordering in dot.
    let protection_before = parent.subgraph(name="\{cluster_name}p0")
    protection_before.set_attr("label", "")
    let cluster = protection_before.subgraph(name=cluster_name)
    // The stereotype line reserves cluster height for the package attribute,
    // matching Java's Cluster.getTitleAndAttributeHeight.
    let cluster_label = group.stereotype.map_or(group.display, stereotype => {
      group.display + "\n" + @tokenizer.display_stereotype(stereotype)
    })
    cluster.set_attr("label", cluster_label)
    cluster.set_attr("style", "rounded")
    cluster.set_attr("fontname", "Arial Bold")
    cluster.set_attr("fontsize", "14")
    cluster.set_attr("penwidth", "1.5")
    cluster.set_attr(
      "color",
      @svg.svg_color(group.color, @entity.package_border_color(self.style)),
    )
    let protection_after = cluster.subgraph(name="\{cluster_name}p1")
    protection_after.set_attr("label", "")
    package_content_graphs[group.qualified_name] = protection_after
    package_indices[cluster_name] = package_index
  }
  let node_names : Map[String, String] = Map([])
  let together_containers : Map[String, @cgraph.Graph] = Map([])
  for group_index, group in self.together_groups {
    let mut container : @cgraph.Graph? = None
    for code in group {
      match container {
        Some(subgraph) => together_containers[code] = subgraph
        None =>
          match self.entity(code) {
            Some(entity) => {
              let parent = match package_content_graphs.get(entity.scope) {
                Some(cluster) => cluster
                None => graph
              }
              // Java wraps each together block in an unlabeled subgraph so
              // dot keeps its members close without drawing a container.
              let subgraph = parent.subgraph(name="together\{group_index}")
              subgraph.set_attr("label", "")
              together_containers[code] = subgraph
              container = Some(subgraph)
            }
            None => ()
          }
      }
    }
  }
  for index, entity in self.entities {
    guard !entity.is_hidden && !entity.is_removed else { continue }
    let name = graphviz_node_name(index)
    node_names[entity.qualified_code] = name
    let node = match together_containers.get(entity.qualified_code) {
      Some(container) => container.node(name)
      None =>
        match package_content_graphs.get(entity.scope) {
          Some(cluster) => cluster.node(name)
          None => graph.node(name)
        }
    }
    let geometry = entity.node_geometry(text_metrics, self.family)
    let capability = entity.render_capability(self.family)
    @graphviz.set_fixed_node_size(
      node,
      geometry.width.to_double(),
      geometry.height.to_double(),
      shape=capability.graphviz_shape(),
    )
    if capability.ports is MapEntryPorts {
      node.set_attr(
        "label",
        entity.map_graphviz_port_label(text_metrics, geometry.width),
      )
      node.set_attr("margin", "0")
    }
  }
  let relation_names : Map[Int, String] = Map([])
  let source_ports : Map[String, Array[String]] = Map([])
  let sink_ports : Map[String, Array[String]] = Map([])
  for index, entity in self.entities {
    guard !entity.is_hidden && !entity.is_removed else { continue }
    match entity.kind {
      // PlantUML `CommandCreateElementFull` maps both `port` and `portin`
      // to `LeafType.PORTIN`, so plain ports pin to the source rank too.
      Port | PortIn => {
        let list = source_ports.get(entity.scope).unwrap_or([])
        list.push(graphviz_node_name(index))
        source_ports[entity.scope] = list
      }
      PortOut => {
        let list = sink_ports.get(entity.scope).unwrap_or([])
        list.push(graphviz_node_name(index))
        sink_ports[entity.scope] = list
      }
      _ => ()
    }
  }
  // PlantUML `ClusterDotString.printRanks` emits the port rank pins inside
  // the cluster subgraph; rank sets outside the cluster make dot remove the
  // ports from cluster membership (mark_clusters).
  let pin_port_ranks = (scope : String, entries : Array[String], rank : String) => {
    guard entries.length() > 0 else { return }
    let parent = package_content_graphs.get(scope).unwrap_or(graph)
    let subgraph = parent.subgraph(name="rank_\{rank}_ports")
    subgraph.set_attr("rank", rank)
    for name in entries {
      let _ = subgraph.node(name)
    }
  }
  for scope, entries in source_ports {
    pin_port_ranks(scope, entries, "source")
  }
  for scope, entries in sink_ports {
    pin_port_ranks(scope, entries, "sink")
  }
  let group_point_names : Map[String, String] = Map([])
  let group_point_node = (code : String) => {
    match group_point_names.get(code) {
      Some(name) => Some(name)
      None =>
        match package_content_graphs.get(code) {
          Some(cluster) => {
            // PlantUML `ClusterDotString` emits the cluster title as a node
            // (`za<uid>`) that receives the edges targeting the group and
            // reserves the title width inside the cluster.
            let name = "group_point_" + code
            let node = cluster.node(name)
            let title_width = match self.find_package(code) {
              Some(group) =>
                // PlantUML `USymbolNode.suppWidthBecauseOfShape` pads the
                // node-symbol title block by 60px.
                text_metrics.regular.measure(group.display).width.to_double() +
                (if group.symbol is Some("node") { 60.0 } else { 0.0 })
              None => 0.72
            }
            @graphviz.set_fixed_node_size(
              node,
              title_width,
              GROUP_POINT_TITLE_HEIGHT,
              shape="rect",
            )
            group_point_names[code] = name
            Some(name)
          }
          None => None
        }
    }
  }
  for relation_index, relation in self.relations {
    let mut tail_name = node_names.get(relation.left)
    if tail_name is None {
      tail_name = group_point_node(relation.left)
    }
    let mut head_name = node_names.get(relation.right)
    if head_name is None {
      head_name = group_point_node(relation.right)
    }
    guard tail_name is Some(tail_name) && head_name is Some(head_name) else {
      continue
    }
    if usecase && relation.dotted && relation.direction is Automatic {
      let rank = graph.subgraph(name="rank_dependency_\{relation_index}")
      rank.set_attr("rank", "same")
      let _ = rank.node(tail_name)
      let _ = rank.node(head_name)
    }
    let tail_port = self
      .entity(relation.left)
      .map_or(None, entity => entity.graphviz_port(relation.left_port))
    let head_port = self
      .entity(relation.right)
      .map_or(None, entity => entity.graphviz_port(relation.right_port))
    let tail = graph.node(tail_name)
    let head = graph.node(head_name)
    let edge = match (tail_port, head_port) {
      (Some(tail_port), Some(head_port)) =>
        graph.edge(
          tail,
          head,
          name="e\{relation_index}",
          tail_port~,
          head_port~,
        )
      (Some(tail_port), None) =>
        graph.edge(tail, head, name="e\{relation_index}", tail_port~)
      (None, Some(head_port)) =>
        graph.edge(tail, head, name="e\{relation_index}", head_port~)
      (None, None) => graph.edge(tail, head, name="e\{relation_index}")
    }
    relation_names[edge.id()] = "\{relation_index}"
    edge.set_attr("minlen", "\{relation.graphviz_minlen()}")
    let mut label = relation.label.unwrap_or("")
    for note in self.notes {
      if note.target_kind is @entity.NoteTargetKind::LinkNote &&
        note.relation_index == Some(relation_index) {
        label = if label.is_empty() {
          note.text
        } else {
          "\{label}\n\{note.text}"
        }
      }
    }
    if !label.is_empty() {
      if usecase {
        label = @tokenizer.display_stereotype(label)
      }
      edge.set_attr("label", label)
      let label_font_size = if usecase {
        @entity.arrow_font_size(
          self.style,
          fallback=PLANTUML_RELATION_LABEL_FONT_SIZE,
        )
      } else {
        text_metrics.relation_label_regular.font_size
      }
      let label_font_name = if usecase {
        @entity.arrow_font_family(self.style)
      } else {
        self.style.font_family()
      }
      edge.set_attr("fontsize", "\{label_font_size}")
      edge.set_attr("fontname", label_font_name)
    }
    if relation.left_cardinality is Some(text) {
      edge.set_attr("taillabel", text)
    }
    if relation.right_cardinality is Some(text) {
      edge.set_attr("headlabel", text)
    }
    if relation.left_role is Some(text) && edge.get_attr("taillabel") is None {
      edge.set_attr("taillabel", text)
    }
    if relation.right_role is Some(text) && edge.get_attr("headlabel") is None {
      edge.set_attr("headlabel", text)
    }
    if relation.left_cardinality is Some(_) ||
      relation.left_role is Some(_) ||
      relation.right_cardinality is Some(_) ||
      relation.right_role is Some(_) {
      edge.set_attr("labeldistance", PLANTUML_LABEL_DISTANCE)
      edge.set_attr("labelangle", PLANTUML_LABEL_ANGLE)
      edge.set_attr(
        "labelfontsize",
        "\{text_metrics.relation_end_regular.font_size}",
      )
      edge.set_attr("labelfontname", text_metrics.relation_end_font_family)
    }
    edge.set_attr("dir", "none")
    if relation.dotted {
      edge.set_attr("style", "dotted")
    }
  }
  let magma_edges = self.magma_grid_edges()
  for magma_seq in 0..<magma_edges.length() {
    let (tail, head, minlen) = magma_edges[magma_seq]
    let edge = graph.edge(
      graph.node(node_names[tail]),
      graph.node(node_names[head]),
      name="magma\{magma_seq}",
    )
    edge.set_attr("style", "invis")
    edge.set_attr("minlen", "\{minlen}")
    edge.set_attr("dir", "none")
  }
  let note_names : Map[String, Int] = Map([])
  let note_edge_names : Map[Int, String] = Map([])
  for note_index, note in self.notes {
    if note.target_kind is @entity.NoteTargetKind::LinkNote {
      continue
    }
    let name = @graphviz.graphviz_note_name(note_index)
    note_names[name] = note_index
    let node = graph.node(name)
    let (width, height) = note_size(note, text_metrics)
    @graphviz.set_fixed_node_size(
      node,
      width.to_double(),
      height.to_double(),
      shape="note",
    )
    let target = match note.target_kind {
      @entity.NoteTargetKind::EntityNote | @entity.NoteTargetKind::MemberTip =>
        Some(note.target)
      @entity.NoteTargetKind::LinkNote =>
        match note.relation_index {
          Some(relation_index) => Some(self.relations[relation_index].left)
          None => None
        }
      FloatingNote => None
    }
    if target is Some(target) {
      if node_names.get(target) is Some(target_name) {
        let position = note.position.with_rankdir(self.style)
        let (left_name, right_name, minlen, rank_same) = match position {
          Right => (target_name, name, 0, true)
          Left => (name, target_name, 0, true)
          Bottom => (target_name, name, 1, false)
          Top => (name, target_name, 1, false)
        }
        if rank_same {
          let rank = graph.subgraph(name="rank_note_\{note_index}")
          rank.set_attr("rank", "same")
          let _ = rank.node(left_name)
          let _ = rank.node(right_name)
        }
        let edge = graph.edge(
          graph.node(left_name),
          graph.node(right_name),
          name="note_edge\{note_index}",
        )
        note_edge_names[edge.id()] = "\{note_index}"
        edge.set_attr("dir", "none")
        edge.set_attr("style", "invis")
        edge.set_attr("minlen", "\{minlen}")
      }
    }
  }
  let laid_out = @graphviz.layout_dot(
    graph,
    self.style,
    PLANTUML_MIN_NODESEP_IN,
    PLANTUML_MIN_RANKSEP_IN,
  )
  let bbox = laid_out.bbox
  let nodes : Array[GraphvizNodeLayout] = []
  for node_layout in laid_out.nodes {
    let point = @graphviz.graphviz_point_to_svg(node_layout.pos, bbox)
    let x = point.x
    let y = point.y
    guard graphviz_entity_index(self, node_layout.node.name())
      is Some(entity_index) else {
      continue
    }
    let raw_width = @graphviz.inches_to_points(node_layout.width_in)
    let raw_height = @graphviz.inches_to_points(node_layout.height_in)
    let width = raw_width.ceil().max(1.0)
    let height = raw_height.ceil().max(1.0)
    let left = (x - raw_width / 2.0).floor()
    let top = (y - raw_height / 2.0).floor()
    nodes.push({
      code: self.entities[entity_index].qualified_code,
      x: left + width / 2.0,
      y: top + height / 2.0,
      width,
      height,
    })
  }
  let packages : Array[GraphvizPackageLayout] = []
  append_package_layouts(packages, laid_out, bbox, package_indices)
  let notes : Array[@graphviz.GraphvizNote] = @graphviz.graphviz_notes(
    laid_out,
    note_names,
    bbox,
    anchor=Center,
  )
  let raw_edges : Array[@graphviz.GraphvizEdge] = @graphviz.graphviz_edges(
    laid_out, relation_names, bbox,
  )
  let edges = normalize_relation_edges(self, text_metrics, nodes, raw_edges)
  let note_edges : Array[@graphviz.GraphvizEdge] = @graphviz.graphviz_edges(
    laid_out, note_edge_names, bbox,
  )
  let relation_labels = build_relation_label_layouts(
    self, text_metrics, nodes, edges,
  )
  for note_index, note in self.notes {
    guard note.target_kind is @entity.NoteTargetKind::LinkNote else { continue }
    guard note.relation_index is Some(relation_index) else { continue }
    let (width, height) = note_size(note, text_metrics)
    for edge in edges {
      guard edge.index == relation_index else { continue }
      guard edge.splines.length() > 0 && edge.splines[0].points.length() > 0 else {
        continue
      }
      let anchor_x = edge.splines[0].points[0].x
      let anchor_y = edge.label.map_or(edge.splines[0].points[0].y, point => {
        point.y
      })
      notes.push({
        note_index,
        x: anchor_x + LINK_NOTE_GAP + width.to_double() / 2.0,
        y: anchor_y + LINK_NOTE_GAP + height.to_double() / 2.0,
        width: width.to_double(),
        height: height.to_double(),
      })
    }
  }
  {
    width: bbox.urx - bbox.llx,
    height: bbox.ury - bbox.lly,
    nodes,
    edges,
    note_edges,
    relation_labels,
    packages,
    notes,
  }
}

///|
/// The Graphviz `minlen` of a relation, mirroring `LinkDecor.getMinlen`.
pub fn relation_graphviz_minlen(relation : @entity.Relation) -> Int {
  relation.graphviz_minlen()
}
