///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(self : Document) -> String {
  match self.diagram {
    Sequence(diagram) => diagram.render_svg()
    Activity(diagram) => diagram.render_svg()
    Class(diagram) | Object(diagram) | Component(diagram) | UseCase(diagram) =>
      diagram.render_svg()
    State(diagram) => diagram.render_svg()
    Mindmap(diagram) => diagram.render_svg()
    Json(diagram) | Yaml(diagram) | Toml(diagram) => diagram.render_svg()
  }
}

///|
/// Parse a PlantUML source with the document heuristics and render the
/// selected diagram family to SVG.
pub fn render_svg(source : String) -> String raise {
  parse(source).render_svg()
}
