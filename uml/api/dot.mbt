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
    if marker == "@startdot" {
      has_markers = true
      inside_markers = true
    } else if (marker == "@enduml" || marker == "@enddot") && inside_markers {
      inside_markers = false
    } else if !has_markers || inside_markers {
      output.write_string(line.to_owned())
      output.write_char('\n')
    }
  }
  if has_markers {
    output.to_string()
  } else {
    input
  }
}

///|
/// Parse a PlantUML `@startdot` source by extracting the DOT text between the
/// markers. The source is validated only when rendered, like PlantUML's dot
/// factory which forwards the text verbatim to graphviz.
pub fn parse_dot_source(input : String) -> DotDiagram {
  { source: @parse.preprocess(input) |> dot_source_between_markers, }
}

///|
/// Render the raw DOT source with the shared graphviz engine.
pub fn DotDiagram::render_svg(self : DotDiagram) -> String raise {
  let graph = @gv_dot.parse_dot(self.source)
  let layout = @dot_layout.layout_dot(graph)
  @svg.render_svg(layout)
}
