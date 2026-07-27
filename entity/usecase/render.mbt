///|
/// Render a use-case diagram through the shared layout engine.
///
/// Use-case-specific SVG behavior belongs in this package.
pub fn render_svg(diagram : @entity.EntityDiagram) -> String {
  @entity.render_svg(diagram)
}
