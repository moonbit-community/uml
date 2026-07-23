///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(self : Document) -> String {
  match self.diagram {
    Sequence(diagram) => @sequence.render_svg(diagram)
    Class(diagram) => @class.render_svg(diagram)
    Json(diagram) => @nonuml.render_json_svg(diagram)
  }
}

///|
pub fn render_class_svg(input : String) -> String raise @core.ParseError {
  parse_class(input).render_svg()
}

///|
pub fn render_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}

///|
pub fn render_json_svg(input : String) -> String raise @json.ParseError {
  parse_json(input).render_svg()
}
