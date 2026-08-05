///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(
  self : Document,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  match self.diagram {
    Sequence(diagram) => diagram.render_svg(color_scheme~)
    Activity(diagram) => diagram.render_svg(color_scheme~)
    Class(diagram) | Object(diagram) | Component(diagram) | UseCase(diagram) =>
      diagram.render_svg(color_scheme~)
    State(diagram) => diagram.render_svg(color_scheme~)
    Mindmap(diagram) => diagram.render_svg(color_scheme~)
    Json(diagram) | Yaml(diagram) | Toml(diagram) =>
      diagram.render_svg(color_scheme~)
  }
}

///|
/// Parse a PlantUML source with the document heuristics and render the
/// selected diagram family to SVG.
///
/// `color_scheme` overrides the default paint palette: `text` and `line` are
/// required (the ink colors that become unreadable in a dark theme), and every
/// other role may be a CSS variable or a literal color.
pub fn render_svg(
  source : String,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise {
  parse(source).render_svg(color_scheme~)
}
