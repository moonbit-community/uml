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
    Json(diagram) => diagram.render_json_svg()
    Yaml(diagram) => diagram.render_yaml_svg()
    Toml(diagram) => diagram.render_toml_svg()
  }
}
