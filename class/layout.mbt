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
/// Geometry returned by Graphviz for one relation. Points are in SVG space.
pub struct GraphvizEdgeLayout {
  relation_index : Int
  paths : Array[Array[(Double, Double)]]
  label : (Double, Double)?
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
pub struct GraphvizNoteLayout {
  note_index : Int
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
  edges : Array[GraphvizEdgeLayout]
  packages : Array[GraphvizPackageLayout]
  notes : Array[GraphvizNoteLayout]
} derive(Eq, Debug)

///|
fn graphviz_quote(value : String) -> String {
  "\"" +
  value.replace(old="\\", new="\\\\").replace(old="\"", new="\\\"") +
  "\""
}

///|
fn graphviz_rankdir(style : @core.DocumentStyle) -> @rankdir.RankDir {
  match style.layout_direction {
    Some(@core.LeftToRight) => @rankdir.LR
    _ => @rankdir.TB
  }
}

///|
fn graphviz_node_name(index : Int) -> String {
  "n\{index}"
}

///|
fn graphviz_note_name(index : Int) -> String {
  "note\{index}"
}

///|
fn graphviz_cluster_name(index : Int) -> String {
  "cluster_package\{index}"
}

///|
fn graphviz_entity_index(diagram : ClassDiagram, node_name : String) -> Int? {
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
fn graphviz_point_to_svg(
  point : @geom.Point,
  bbox : @geom.Rect,
) -> (Double, Double) {
  (point.x - bbox.llx, bbox.ury - point.y)
}

///|
fn graphviz_path_to_svg(
  spline : @geom.Spline,
  bbox : @geom.Rect,
) -> Array[(Double, Double)] {
  spline.points.map(point => graphviz_point_to_svg(point, bbox))
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
  let mut width = 80
  for line in lines {
    width = width.max(
      @metrics.measure_text_with(line.to_owned(), text_metrics.regular).width +
      24,
    )
  }
  (width, (lines.length().max(1) * text_metrics.row_height() + 18).max(34))
}

///|
/// Build and execute the in-process Graphviz DOT layout.
fn ClassDiagram::graphviz_layout(
  self : ClassDiagram,
  text_metrics : ClassTextMetrics,
) -> GraphvizLayout raise @dot_layout.DotLayoutError {
  let graph = @cgraph.Graph::new(@cgraph.Directed, name="class", strict=false)
  graph.set_attr(
    "rankdir",
    match graphviz_rankdir(self.style) {
      @rankdir.LR => "LR"
      @rankdir.TB => "TB"
      @rankdir.BT => "BT"
      @rankdir.RL => "RL"
    },
  )
  graph.set_attr("splines", "spline")
  let package_graphs : Map[String, @cgraph.Graph] = Map([])
  let package_indices : Map[String, Int] = Map([])
  for package_index, group in self.packages {
    let parent = match package_graphs.get(group.parent) {
      Some(parent) => parent
      None => graph
    }
    let cluster_name = graphviz_cluster_name(package_index)
    let cluster = parent.subgraph(name=cluster_name)
    cluster.set_attr("label", graphviz_quote(group.display))
    cluster.set_attr("style", "rounded")
    cluster.set_attr("color", @core.svg_color(group.color, "#181818"))
    package_graphs[group.qualified_name] = cluster
    package_indices[cluster_name] = package_index
  }
  let node_names : Map[String, String] = Map([])
  for index, entity in self.entities {
    guard !entity.is_hidden && !entity.is_removed else { continue }
    let name = graphviz_node_name(index)
    node_names[entity.qualified_code] = name
    let node = match package_graphs.get(entity.scope) {
      Some(cluster) => cluster.node(name)
      None => graph.node(name)
    }
    node.set_attr("label", graphviz_quote(entity.display))
    node.set_attr("shape", "box")
    node.set_attr("width", "\{(entity.width(text_metrics).to_double() / 72.0)}")
    node.set_attr(
      "height",
      "\{(entity.height(text_metrics).to_double() / 72.0)}",
    )
    node.set_attr("fixedsize", "true")
  }
  let relation_names : Map[Int, String] = Map([])
  for relation_index, relation in self.relations {
    guard node_names.contains(relation.left) &&
      node_names.contains(relation.right) else {
      continue
    }
    let edge = graph.edge(
      graph.node(node_names[relation.left]),
      graph.node(node_names[relation.right]),
      name="e\{relation_index}",
    )
    relation_names[edge.id()] = "\{relation_index}"
    edge.set_attr("label", graphviz_quote(relation.label.unwrap_or("")))
    edge.set_attr("dir", "none")
    if relation.dotted {
      edge.set_attr("style", "dotted")
    }
  }
  let note_names : Map[String, Int] = Map([])
  for note_index, note in self.notes {
    let name = graphviz_note_name(note_index)
    note_names[name] = note_index
    let node = graph.node(name)
    let (width, height) = note_size(note, text_metrics)
    node.set_attr("label", graphviz_quote(note.text))
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
            let edge = graph.edge(node, graph.node(target_name), name="note_edge\{note_index}")
            edge.set_attr("dir", "none")
            edge.set_attr("style", "invis")
          }
          None => ()
        }
      None => ()
    }
  }
  let laid_out = @dot_layout.layout_dot(graph, options={
    rankdir: Some(graphviz_rankdir(self.style)),
    nodesep: Some(0.35),
    ranksep: Some(0.6),
    splines: Some(@dot_layout.SplinesMode::Spline),
  })
  let bbox = laid_out.bbox
  let nodes : Array[GraphvizNodeLayout] = []
  for node_layout in laid_out.nodes {
    let (x, y) = graphviz_point_to_svg(node_layout.pos, bbox)
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
  let notes : Array[GraphvizNoteLayout] = []
  for node_layout in laid_out.nodes {
    guard note_names.get(node_layout.node.name()) is Some(note_index) else {
      continue
    }
    let (x, y) = graphviz_point_to_svg(node_layout.pos, bbox)
    notes.push({
      note_index,
      x,
      y,
      width: node_layout.width_in * 72.0,
      height: node_layout.height_in * 72.0,
    })
  }
  let edges : Array[GraphvizEdgeLayout] = []
  for edge_layout in laid_out.edges {
    guard relation_names.get(edge_layout.edge.id()) is Some(index_text) else {
      continue
    }
    let relation_index = @string.parse_int(index_text) catch { _ => continue }
    let paths = edge_layout.splines.map(spline => {
      graphviz_path_to_svg(spline, bbox)
    })
    let label = edge_layout.label_pos.map(point => {
      graphviz_point_to_svg(point, bbox)
    })
    edges.push({ relation_index, paths, label })
  }
  {
    width: bbox.urx - bbox.llx,
    height: bbox.ury - bbox.lly,
    nodes,
    edges,
    packages,
    notes,
  }
}
