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
pub struct GraphvizPackageLayout {
  package_index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
/// Complete Graphviz layout normalized to an SVG coordinate system.
pub struct GraphvizLayout {
  width : Double
  height : Double
  nodes : Array[GraphvizNodeLayout]
  edges : Array[@graphviz.GraphvizEdge]
  relation_labels : Array[RelationLabelLayout]
  packages : Array[GraphvizPackageLayout]
  notes : Array[@graphviz.GraphvizNote]
} derive(Eq, Debug)

///|
const PLANTUML_MIN_NODESEP_IN : Double = 35.0 / 72.0

///|
const PLANTUML_MIN_RANKSEP_IN : Double = 60.0 / 72.0

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
fn graphviz_cluster_name(index : Int) -> String {
  "cluster_package\{index}"
}

///|
fn graphviz_entity_index(diagram : EntityDiagram, node_name : String) -> Int? {
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
fn append_package_layouts(
  output : Array[GraphvizPackageLayout],
  layout : @dot_layout.DotLayoutGraph,
  root_bbox : @geom.Rect,
  package_indices : Map[String, Int],
) -> Unit {
  match layout.graph.name() {
    Some(name) =>
      match package_indices.get(name) {
        Some(package_index) => {
          let bbox = layout.bbox
          output.push({
            package_index,
            x: bbox.llx - root_bbox.llx,
            y: root_bbox.ury - bbox.ury,
            width: bbox.urx - bbox.llx,
            height: bbox.ury - bbox.lly,
          })
        }
        None => ()
      }
    None => ()
  }
  for child in layout.subgraphs {
    append_package_layouts(output, child, root_bbox, package_indices)
  }
}

///|
fn note_size(note : Note, text_metrics : ClassTextMetrics) -> (Int, Int) {
  let lines = note.text.split("\n").to_array()
  let mut width = 0
  for line in lines {
    width = width.max(
      @metrics.measure_text_with(line.to_owned(), text_metrics.note).width +
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
fn Relation::graphviz_minlen(self : Relation) -> Int {
  let mut segments = 0
  for char in self.raw_arrow {
    if char == '-' || char == '.' {
      segments += 1
    }
  }
  (segments - 1).max(0)
}

///|

///|
/// Build and execute the in-process Graphviz DOT layout.
fn EntityDiagram::graphviz_layout(
  self : EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> GraphvizLayout raise @dot_layout.DotLayoutError {
  let usecase = self.family.is_usecase()
  let graph = @cgraph.Graph::new(@cgraph.Directed, name="class", strict=false)
  graph.set_attr(
    "rankdir",
    @graphviz.graphviz_rankdir_attr(@graphviz.graphviz_rankdir(self.style)),
  )
  graph.set_attr("splines", "spline")
  graph.set_attr("remincross", "true")
  graph.set_attr("searchsize", "500")
  let package_content_graphs : Map[String, @cgraph.Graph] = Map([])
  let package_indices : Map[String, Int] = Map([])
  for package_index, group in self.packages {
    let parent = match package_content_graphs.get(group.parent) {
      Some(parent) => parent
      None => graph
    }
    let cluster_name = graphviz_cluster_name(package_index)
    // Java ClusterDotString places normal package nodes in nested p0/p1
    // protection clusters. These clusters affect sibling ordering in dot.
    let protection_before = parent.subgraph(name="\{cluster_name}p0")
    protection_before.set_attr("label", "")
    let cluster = protection_before.subgraph(name=cluster_name)
    cluster.set_attr("label", group.display)
    cluster.set_attr("style", "rounded")
    cluster.set_attr("fontname", "Arial Bold")
    cluster.set_attr("fontsize", "14")
    cluster.set_attr("penwidth", "1.5")
    cluster.set_attr(
      "color",
      @style.svg_color(group.color, self.style.package_border_color()),
    )
    let protection_after = cluster.subgraph(name="\{cluster_name}p1")
    protection_after.set_attr("label", "")
    package_content_graphs[group.qualified_name] = protection_after
    package_indices[cluster_name] = package_index
  }
  let node_names : Map[String, String] = Map([])
  for index, entity in self.entities {
    guard !entity.is_hidden && !entity.is_removed else { continue }
    let name = graphviz_node_name(index)
    node_names[entity.qualified_code] = name
    let node = match package_content_graphs.get(entity.scope) {
      Some(cluster) => cluster.node(name)
      None => graph.node(name)
    }
    let geometry = entity.node_geometry(text_metrics, self.family)
    node.set_attr("label", "")
    node.set_attr(
      "shape",
      match geometry.shape {
        Box => "box"
        Ellipse => "ellipse"
      },
    )
    node.set_attr("width", "\{(geometry.width.to_double() / 72.0)}")
    node.set_attr("height", "\{(geometry.height.to_double() / 72.0)}")
    node.set_attr("fixedsize", "true")
  }
  let relation_names : Map[Int, String] = Map([])
  for relation_index, relation in self.relations {
    guard node_names.contains(relation.left) &&
      node_names.contains(relation.right) else {
      continue
    }
    if usecase && relation.dotted && relation.direction is Automatic {
      let rank = graph.subgraph(name="rank_dependency_\{relation_index}")
      rank.set_attr("rank", "same")
      let _ = rank.node(node_names[relation.left])
      let _ = rank.node(node_names[relation.right])
    }
    let edge = graph.edge(
      graph.node(node_names[relation.left]),
      graph.node(node_names[relation.right]),
      name="e\{relation_index}",
    )
    relation_names[edge.id()] = "\{relation_index}"
    edge.set_attr("minlen", "\{relation.graphviz_minlen()}")
    let mut label = relation.label.unwrap_or("")
    for note in self.notes {
      if note.target_kind is LinkNote &&
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
        label = @parse.display_stereotype(label)
      }
      edge.set_attr("label", label)
      let label_font_size = if usecase {
        self.style.arrow_font_size(fallback=PLANTUML_RELATION_LABEL_FONT_SIZE)
      } else {
        text_metrics.relation_label_regular.font_size
      }
      let label_font_name = if usecase {
        self.style.arrow_font_family()
      } else {
        @style.font_family(self.style)
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
  let note_names : Map[String, Int] = Map([])
  for note_index, note in self.notes {
    if note.target_kind is LinkNote {
      continue
    }
    let name = @graphviz.graphviz_note_name(note_index)
    note_names[name] = note_index
    let node = graph.node(name)
    let (width, height) = note_size(note, text_metrics)
    node.set_attr("label", "")
    node.set_attr("shape", "note")
    node.set_attr("width", "\{width.to_double() / 72.0}")
    node.set_attr("height", "\{height.to_double() / 72.0}")
    node.set_attr("fixedsize", "true")
    let target = match note.target_kind {
      EntityNote | MemberTip => Some(note.target)
      LinkNote =>
        match note.relation_index {
          Some(relation_index) => Some(self.relations[relation_index].left)
          None => None
        }
      FloatingNote => None
    }
    match target {
      Some(target) =>
        match node_names.get(target) {
          Some(target_name) => {
            let left = match note.position {
              Left | Top if usecase => node
              _ => graph.node(target_name)
            }
            let right = match note.position {
              Left | Top if usecase => graph.node(target_name)
              _ => node
            }
            let edge = graph.edge(left, right, name="note_edge\{note_index}")
            edge.set_attr("dir", "none")
            edge.set_attr("style", if usecase { "dotted" } else { "invis" })
            if !usecase {
              edge.set_attr("constraint", "false")
            }
            if usecase {
              let minlen = match note.position {
                Top | Bottom => 1
                Left | Right => 0
              }
              edge.set_attr("minlen", "\{minlen}")
            }
          }
          None => ()
        }
      None => ()
    }
  }
  let laid_out = @dot_layout.layout_dot(graph, options={
    rankdir: Some(@graphviz.graphviz_rankdir(self.style)),
    nodesep: Some(PLANTUML_MIN_NODESEP_IN),
    ranksep: Some(PLANTUML_MIN_RANKSEP_IN),
    splines: Some(@dot_layout.SplinesMode::Spline),
  })
  let bbox = laid_out.bbox
  let nodes : Array[GraphvizNodeLayout] = []
  for node_layout in laid_out.nodes {
    let (x, y) = @graphviz.graphviz_point_to_svg(node_layout.pos, bbox)
    match graphviz_entity_index(self, node_layout.node.name()) {
      Some(entity_index) =>
        nodes.push({
          code: self.entities[entity_index].qualified_code,
          x,
          y,
          width: node_layout.width_in * 72.0,
          height: node_layout.height_in * 72.0,
        })
      None => ()
    }
  }
  let packages : Array[GraphvizPackageLayout] = []
  append_package_layouts(packages, laid_out, bbox, package_indices)
  let notes : Array[@graphviz.GraphvizNote] = @graphviz.graphviz_notes(
    laid_out,
    note_names,
    bbox,
    offset=false,
  )
  let edges : Array[@graphviz.GraphvizEdge] = @graphviz.graphviz_edges(
    laid_out, relation_names, bbox,
  )
  let relation_labels = build_relation_label_layouts(
    self, text_metrics, nodes, edges,
  )
  for note_index, note in self.notes {
    guard note.target_kind is LinkNote else { continue }
    guard note.relation_index is Some(relation_index) else { continue }
    let (width, height) = note_size(note, text_metrics)
    for edge in edges {
      guard edge.index == relation_index else { continue }
      guard edge.paths.length() > 0 && edge.paths[0].length() > 0 else {
        continue
      }
      let anchor_x = edge.paths[0][0].0
      let anchor_y = match edge.label {
        Some((_, y)) => y
        None => edge.paths[0][0].1
      }
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
    relation_labels,
    packages,
    notes,
  }
}
