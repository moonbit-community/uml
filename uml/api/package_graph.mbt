///|
/// Render a `moon tree --package --json` package dependency graph to SVG.
///
/// The input is the JSON object emitted by the `moon tree --package --json`
/// command:
/// a list of `nodes` (each carrying a `rel` package path) and a list of `edges`
/// (`from`/`to` node indices, an `alias`, and dependency `kinds`). It is not a
/// PlantUML source, so the graph is built directly on the graphviz model and
/// rendered with the graphviz SVG engine.
pub fn render_package_dep_svg(
  source : String,
) -> String raise @dot_layout.DotLayoutError {
  let layout = @dot_layout.layout_dot(parse_package_dep_graph(source))
  @svg.render_svg(layout)
}

///|
/// Build the graphviz model from the `moon pkg tree --json` structure.
fn parse_package_dep_graph(
  source : String,
) -> @cgraph.Graph raise @dot_layout.DotLayoutError {
  let root = @json.parse(source) catch {
    error =>
      raise @dot_layout.DotLayoutError::InvalidGraph(message=error.to_string())
  }
  let graph = @cgraph.Graph::new(@cgraph.Directed, name="packages")
  let nodes = root.required_array("nodes")
  for index, node in nodes {
    let gv_node = graph.node("n\{index}")
    gv_node.set_attr("label", node.required_string("rel"))
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
    let dep_edge = graph.edge(graph.node("n\{from}"), graph.node("n\{to}"))
    let label = edge.optional_string("alias")
    if label.length() > 0 {
      dep_edge.set_attr("label", label)
    }
    let kinds = edge.required_array("kinds")
    let dashed = kinds.any(kind => kind is String("blackbox-test"))
    dep_edge.set_attr("style", if dashed { "dashed" } else { "solid" })
  }
  graph
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
/// Fetch the string member under `key`, defaulting to `""` when absent.
fn Json::optional_string(self : Json, key : String) -> String {
  if self is Object(obj) {
    obj
    .get(key)
    .map_or("", value => if value is String(text) { text } else { "" })
  } else {
    ""
  }
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
