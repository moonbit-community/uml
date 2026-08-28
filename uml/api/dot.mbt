///|
/// A `@startdot` diagram: the raw Graphviz DOT source forwarded to the shared
/// graphviz engine, mirroring PlantUML's pass-through to the `dot` executable.
pub struct DotDiagram {
  source : String
} derive(Eq, Debug)

///|
pub extend DotDiagram with Eq::{not_equal, equal}

///|
pub extend DotDiagram with Debug::{to_repr}

///|
fn dot_source_between_markers(input : String) -> String {
  let output = StringBuilder()
  let mut inside_markers = false
  let mut has_markers = false
  for line in input.split("\n") {
    let marker = line.trim().to_lower()
    guard marker != "@startdot" else {
      has_markers = true
      inside_markers = true
      continue
    }
    guard !((marker == "@enduml" || marker == "@enddot") && inside_markers) else {
      inside_markers = false
      continue
    }
    guard !has_markers || inside_markers else { continue }
    output.write_string(line.to_owned())
    output.write_char('\n')
  }
  guard has_markers else { input }
  output.to_string()
}

///|
/// Parse a PlantUML `@startdot` source by extracting the DOT text between the
/// markers. The source is validated only when rendered, like PlantUML's dot
/// factory which forwards the text verbatim to graphviz.
pub fn parse_dot_source(input : String) -> DotDiagram {
  { source: @tokenizer.preprocess(input) |> dot_source_between_markers, }
}

///|
/// Apply the color scheme to the graphviz defaults: the canvas, the default
/// node fill, and the default ink. Attributes written by the DOT source
/// always win over the scheme; a transparent canvas keeps the graphviz
/// default so the diagram still renders on a bare page.
fn apply_theme_defaults(
  graph : @cgraph.Graph,
  scheme : @style.ColorScheme,
) -> Unit {
  let canvas = scheme.canvas.to_lower()
  let paints_canvas = canvas != "none" && canvas != "transparent"
  if graph.get_attr("bgcolor") is None && paints_canvas {
    graph.set_attr("bgcolor", scheme.canvas)
  }
  for node in graph.nodes() {
    let explicit_color = node.get_attr("color")
    if explicit_color is None {
      node.set_attr("color", scheme.line)
    }
    if node.get_attr("fontcolor") is None {
      node.set_attr("fontcolor", scheme.text)
    }
    guard explicit_color is None else { continue }
    guard node.get_attr("fillcolor") is None else { continue }
    guard @attrs.parse_style(node.get_attr("style")).filled else { continue }
    node.set_attr("fillcolor", scheme.node)
  }
  for edge in graph.edges() {
    if edge.get_attr("color") is None {
      edge.set_attr("color", scheme.line)
    }
    if edge.get_attr("fontcolor") is None {
      edge.set_attr("fontcolor", scheme.text)
    }
  }
  apply_subgraph_defaults(graph, scheme)
}

///|
/// Set the graph text and border colors unless the source already painted
/// them, recursing into subgraph clusters.
fn apply_subgraph_defaults(
  graph : @cgraph.Graph,
  scheme : @style.ColorScheme,
) -> Unit {
  if graph.get_attr("fontcolor") is None {
    graph.set_attr("fontcolor", scheme.text)
  }
  if graph.get_attr("color") is None {
    graph.set_attr("color", scheme.line)
  }
  for subgraph in graph.subgraphs() {
    apply_subgraph_defaults(subgraph, scheme)
  }
}

///|
/// Render the raw DOT source with the shared graphviz engine.
pub fn DotDiagram::render_svg(
  self : DotDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise {
  let graph = @gv_dot.parse_dot(self.source)
  apply_theme_defaults(graph, color_scheme)
  let layout = @dot_layout.layout_dot(graph)
  @svg.render_svg(layout)
}
