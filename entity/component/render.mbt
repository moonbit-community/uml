///|
/// Render a component/description diagram through the shared layout engine.
///
/// Component-specific SVG behavior belongs in this package.
pub fn render_svg(diagram : @entity.EntityDiagram) -> String {
  @entity.render_svg(diagram)
}
