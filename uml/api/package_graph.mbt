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
pub fn render_package_dep_svg(
  source : String,
) -> String raise @dot_layout.DotLayoutError {
  let layout = @dot_layout.layout_dot(
    parse_package_dep_graph(source),
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
/// Build the graphviz model from the `moon tree --package --json` structure,
/// keeping only nodes whose `source.kind` is `"local"` with a non-empty `rel`.
fn parse_package_dep_graph(
  source : String,
) -> @cgraph.Graph raise @dot_layout.DotLayoutError {
  let filtered = filter_package_dep_graph(source)
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
/// non-empty `rel`, and only edges whose `kinds` include `"source"`. Edge
/// indices are renumbered to the kept node set.
fn filter_package_dep_graph(
  source : String,
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
    if node.is_local_node() && !node.required_string("rel").is_empty() {
      local_index[index] = rels.length()
      rels.push(node.required_string("rel"))
      modules.push(node.required_string("module"))
    }
  }
  let edges : Array[(Int, Int)] = []
  let all_edges = root.required_array("edges")
  for edge in all_edges {
    let from = edge.required_int("from")
    let to = edge.required_int("to")
    guard from >= 0 && from < nodes.length() && to >= 0 && to < nodes.length() else {
      raise @dot_layout.DotLayoutError::InvalidGraph(
        message="dependency edge index out of range",
      )
    }
    let kinds = edge.required_array("kinds")
    if kinds.any(kind => kind is String("source")) {
      match local_index.get(from) {
        Some(new_from) =>
          match local_index.get(to) {
            Some(new_to) => edges.push((new_from, new_to))
            None => ()
          }
        None => ()
      }
    }
  }
  { rels, modules, edges, }
}

///|
/// Render the filtered package dependency graph as a D2 source string. Each
/// node uses `module/rel` as its id and displays `rel` over the module name;
/// edges carry no labels and the diagram flows top-to-bottom.
pub fn render_package_dep_d2(
  source : String,
) -> String raise @dot_layout.DotLayoutError {
  let filtered = filter_package_dep_graph(source)
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
    match obj.get("source") {
      Some(Object(source)) =>
        match source.get("kind") {
          Some(String(kind)) => kind == "local"
          _ => false
        }
      _ => false
    }
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
