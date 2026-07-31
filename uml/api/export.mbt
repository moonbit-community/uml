///|
/// Parse a PlantUML source with the document heuristics and render the
/// selected diagram family to SVG.
pub fn render_svg(source : String) -> String raise {
  parse(source).render_svg()
}
