///|
/// Render object-diagram entities through the shared layout engine.
///
/// Object, map, and JSON node SVG behavior belongs in this package. Parsing is
/// intentionally owned by the class-diagram family, matching PlantUML.
pub fn render_svg(diagram : @entity.EntityDiagram) -> String {
  @entity.render_svg(diagram)
}
