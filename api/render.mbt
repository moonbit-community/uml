///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(self : Document) -> String {
  match self.diagram {
    Sequence(diagram) => @sequence.render_svg(diagram)
    Class(diagram) | Object(diagram) | Component(diagram) | UseCase(diagram) =>
      @entity.render_svg(diagram)
    Mindmap(diagram) => @mindmap.render_svg(diagram)
    Json(diagram) => diagram.render_json_svg()
    Yaml(diagram) => diagram.render_yaml_svg()
    Toml(diagram) => diagram.render_toml_svg()
  }
}

///|
pub fn render_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}
