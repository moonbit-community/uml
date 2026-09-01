///|
/// Render a `moon tree --package --json` package dependency graph to SVG.
///
/// The input is the JSON object emitted by the `moon tree --package --json`
/// command:
/// a list of `nodes` (each carrying a `rel` package path and a `source.kind`)
/// and a list of `edges` (`from`/`to` node indices, an `alias`, and dependency
/// `kinds`). It is not a PlantUML source, so the graph is built directly on the
/// graphviz model and rendered with the graphviz SVG engine.
///
/// Only nodes whose `source.kind` is `"local"` and whose `rel` is non-empty
/// are rendered; registry packages, workspace root modules, and every edge
/// touching a dropped node are removed. Only edges whose `kinds` include
/// `"source"` are kept. Each node is labelled with its `rel` over the module
/// name.
///
/// `keep_node` decides which nodes survive from their in/out degree and the
/// graph-wide maxima. The default keeps packages that depend on more than one
/// package or are depended on by more than one (`in > 1 or out > 1`).
pub fn render_package_dep_svg(
  source : String,
  keep_node? : (InOutDegrees) -> Bool = default_keep_node,
  related_edges? : RelatedEdges = Induced,
) -> String raise @dot_layout.DotLayoutError {
  let layout = @dot_layout.layout_dot(
    parse_package_dep_graph(source, keep_node~, related_edges~),
    options=@dot_layout.DotLayoutOptions::{
      rankdir: Some(@dot_layout.RankDir::TB),
      nodesep: None,
      ranksep: None,
      splines: None,
    },
  )
  @svg.render_svg(layout)
}

///|
/// The in/out degree of a node and the graph-wide maxima, as seen by
/// `keep_node`.
pub struct InOutDegrees {
  in_degree : Int
  out_degree : Int
  max_in : Int
  max_out : Int
}

///|
/// The default node filter: keep packages that depend on more than one
/// package or are depended on by more than one.
fn default_keep_node(degrees : InOutDegrees) -> Bool {
  degrees.in_degree > 1 || degrees.out_degree > 1
}

///|
/// How the edges of a selected node set are derived.
#warnings("-unused_constructor")
pub enum RelatedEdges {
  /// Keep only the edges between selected nodes.
  Induced
  /// Keep selected nodes plus their direct neighbours, and the edges within
  /// that closure.
  Neighborhood
}

///|
/// Build the graphviz model from the `moon tree --package --json` structure,
/// keeping only nodes whose `source.kind` is `"local"` with a non-empty `rel`.
fn parse_package_dep_graph(
  source : String,
  keep_node? : (InOutDegrees) -> Bool = default_keep_node,
  related_edges? : RelatedEdges = Induced,
) -> @cgraph.Graph raise @dot_layout.DotLayoutError {
  let filtered = filter_package_dep_graph(source, keep_node~, related_edges~)
  let graph = @cgraph.Graph::new(@cgraph.Directed, name="packages")
  for index, rel in filtered.rels {
    let gv_node = graph.node("n\{index}")
    gv_node.set_attr("label", "\{rel}\n\{filtered.modules[index]}")
  }
  for edge in filtered.edges {
    let (from, to) = edge
    let dep_edge = graph.edge(graph.node("n\{from}"), graph.node("n\{to}"))
    dep_edge.set_attr("style", "solid")
  }
  graph
}

///|
/// The package nodes and edges kept after filtering a `moon tree --package
/// --json` source.
priv struct FilteredPackageDepGraph {
  rels : Array[String]
  modules : Array[String]
  edges : Array[(Int, Int)]
}

///|
/// Parse `moon tree --package --json` and keep only local packages with a
/// non-empty `rel`, and only edges whose `kinds` include `"source"`. Nodes
/// are then selected by `keep_node`; `related_edges` decides whether the
/// edges are those between selected nodes or within their neighbourhood.
fn filter_package_dep_graph(
  source : String,
  keep_node? : (InOutDegrees) -> Bool = default_keep_node,
  related_edges? : RelatedEdges = Induced,
) -> FilteredPackageDepGraph raise @dot_layout.DotLayoutError {
  let root = @json.parse(source) catch {
    error =>
      raise @dot_layout.DotLayoutError::InvalidGraph(message=error.to_string())
  }
  let nodes = root.required_array("nodes")
  let local_index : Map[Int, Int] = Map([])
  let rels : Array[String] = []
  let modules : Array[String] = []
  for index, node in nodes {
    guard node.is_local_node() else { continue }
    let rel = node.required_string("rel")
    guard !rel.is_empty() else { continue }
    local_index[index] = rels.length()
    rels.push(rel)
    modules.push(node.required_string("module"))
  }
  let edges : Array[(Int, Int)] = []
  for edge in root.required_array("edges") {
    let from = edge.required_int("from")
    let to = edge.required_int("to")
    guard from >= 0 && from < nodes.length() && to >= 0 && to < nodes.length() else {
      raise @dot_layout.DotLayoutError::InvalidGraph(
        message="dependency edge index out of range",
      )
    }
    let kinds = edge.required_array("kinds")
    guard kinds.any(kind => kind is String("source")) else { continue }
    guard local_index.get(from) is Some(new_from) else { continue }
    guard local_index.get(to) is Some(new_to) else { continue }
    edges.push((new_from, new_to))
  }
  select_nodes(rels, modules, edges, keep_node, related_edges)
}

///|
/// Apply `keep_node` to every node and derive the surviving nodes and edges
/// according to `related_edges`, renumbering them to a dense index space.
fn select_nodes(
  rels : Array[String],
  modules : Array[String],
  edges : Array[(Int, Int)],
  keep_node : (InOutDegrees) -> Bool,
  related_edges : RelatedEdges,
) -> FilteredPackageDepGraph {
  let node_count = rels.length()
  let in_degree : Array[Int] = Array::make(node_count, 0)
  let out_degree : Array[Int] = Array::make(node_count, 0)
  for edge in edges {
    let (from, to) = edge
    in_degree[to] = in_degree[to] + 1
    out_degree[from] = out_degree[from] + 1
  }
  let max_in = in_degree.fold(init=0, (acc, value) => acc.max(value))
  let max_out = out_degree.fold(init=0, (acc, value) => acc.max(value))
  let kept : Array[Bool] = Array::make(node_count, false)
  for index in 0..<node_count {
    kept[index] = keep_node(
      {
        in_degree: in_degree[index],
        out_degree: out_degree[index],
        max_in,
        max_out,
      },
    )
  }
  if related_edges is Neighborhood {
    for edge in edges {
      let (from, to) = edge
      if kept[from] || kept[to] {
        kept[from] = true
        kept[to] = true
      }
    }
  }
  let kept_index : Map[Int, Int] = Map([])
  let kept_rels : Array[String] = []
  let kept_modules : Array[String] = []
  for index in 0..<node_count {
    guard kept[index] else { continue }
    kept_index[index] = kept_rels.length()
    kept_rels.push(rels[index])
    kept_modules.push(modules[index])
  }
  let kept_edges : Array[(Int, Int)] = []
  for edge in edges {
    let (from, to) = edge
    guard kept_index.get(from) is Some(new_from) else { continue }
    guard kept_index.get(to) is Some(new_to) else { continue }
    kept_edges.push((new_from, new_to))
  }
  { rels: kept_rels, modules: kept_modules, edges: kept_edges, }
}

///|
/// Render the filtered package dependency graph as a D2 source string. Each
/// node uses `module/rel` as its id and displays `rel` over the module name;
/// edges carry no labels and the diagram flows top-to-bottom. Node selection
/// follows `keep_node` and `related_edges`, as in `render_package_dep_svg`.
pub fn render_package_dep_d2(
  source : String,
  keep_node? : (InOutDegrees) -> Bool = default_keep_node,
  related_edges? : RelatedEdges = Induced,
) -> String raise @dot_layout.DotLayoutError {
  let filtered = filter_package_dep_graph(source, keep_node~, related_edges~)
  let sb = StringBuilder()
  sb.write_string("direction: down\n")
  for index, rel in filtered.rels {
    sb.write_string("\n`\{filtered.modules[index]}/\{rel}`: {\n")
    sb.write_string("  label: \"\{rel}\\n\{filtered.modules[index]}\"\n")
    sb.write_string("}\n")
  }
  for edge in filtered.edges {
    let (from, to) = edge
    sb.write_string(
      "\n`\{filtered.modules[from]}/\{filtered.rels[from]}` -> `\{filtered.modules[to]}/\{filtered.rels[to]}`\n",
    )
  }
  sb.to_string()
}

///|
/// Whether the `moon tree --package --json` node describes a local workspace
/// package. Nodes that carry no `source.kind` are treated as non-local.
fn Json::is_local_node(self : Json) -> Bool {
  if self is Object(obj) {
    obj.get("source") is Some(Object(source)) &&
    source.get("kind") is Some(String(kind)) &&
    kind == "local"
  } else {
    false
  }
}

///|
/// Fetch the required object member under `key`, or fail the graph build.
fn Json::required_member(
  self : Json,
  key : String,
) -> Json raise @dot_layout.DotLayoutError {
  guard self is Object(obj) else {
    raise @dot_layout.DotLayoutError::InvalidGraph(
      message="member \{key} is not an object",
    )
  }
  guard obj.get(key) is Some(value) else {
    raise @dot_layout.DotLayoutError::InvalidGraph(
      message="missing member \{key}",
    )
  }
  value
}

///|
/// Fetch the required array member under `key`.
fn Json::required_array(
  self : Json,
  key : String,
) -> Array[Json] raise @dot_layout.DotLayoutError {
  let value = self.required_member(key)
  guard value is Array(items) else {
    raise @dot_layout.DotLayoutError::InvalidGraph(
      message="member \{key} is not an array",
    )
  }
  items
}

///|
/// Fetch the required string member under `key`.
fn Json::required_string(
  self : Json,
  key : String,
) -> String raise @dot_layout.DotLayoutError {
  let value = self.required_member(key)
  guard value is String(text) else {
    raise @dot_layout.DotLayoutError::InvalidGraph(
      message="member \{key} is not a string",
    )
  }
  text
}

///|
/// Fetch the required integer member under `key`.
fn Json::required_int(
  self : Json,
  key : String,
) -> Int raise @dot_layout.DotLayoutError {
  let value = self.required_member(key)
  guard value is Number(number, ..) else {
    raise @dot_layout.DotLayoutError::InvalidGraph(
      message="member \{key} is not a number",
    )
  }
  number.to_int()
}
