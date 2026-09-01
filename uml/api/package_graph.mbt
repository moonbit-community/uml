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
  let root = @json.parse(source) catch {
    error =>
      raise @dot_layout.DotLayoutError::InvalidGraph(message=error.to_string())
  }
  let graph = @cgraph.Graph::new(@cgraph.Directed, name="packages")
  let nodes = root.required_array("nodes")
  let local_index : Map[Int, Int] = Map([])
  let local_nodes : Array[Json] = []
  for index, node in nodes {
    if node.is_local_node() && !node.required_string("rel").is_empty() {
      local_index[index] = local_nodes.length()
      local_nodes.push(node)
    }
  }
  for new_index, node in local_nodes {
    let gv_node = graph.node("n\{new_index}")
    gv_node.set_attr(
      "label",
      "\{node.required_string("rel")}\n\{node.required_string("module")}",
    )
  }
  let edges = root.required_array("edges")
  for edge in edges {
    let from = edge.required_int("from")
    let to = edge.required_int("to")
    guard from >= 0 && from < nodes.length() && to >= 0 && to < nodes.length() else {
      raise @dot_layout.DotLayoutError::InvalidGraph(
        message="dependency edge index out of range",
      )
    }
    match local_index.get(from) {
      Some(new_from) =>
        match local_index.get(to) {
          Some(new_to) => {
            let kinds = edge.required_array("kinds")
            if kinds.any(kind => kind is String("source")) {
              let dep_edge = graph.edge(
                graph.node("n\{new_from}"),
                graph.node("n\{new_to}"),
              )
              dep_edge.set_attr("style", "solid")
            }
          }
          None => ()
        }
      None => ()
    }
  }
  graph
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
