///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(self : Document) -> String {
  match self.diagram {
    Sequence(diagram) => @sequence.render_svg(diagram)
  }
}

///|
pub fn render_svg(input : String) -> String raise @sequence.ParseError {
  parse(input).render_svg()
}
