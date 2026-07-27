///|
/// Render the class-diagram family through the shared entity layout engine.
///
/// Class parsing and rendering share entity syntax, relations, and Graphviz
/// layout with object diagrams. Class-specific SVG behavior belongs here.
pub fn render_svg(diagram : @entity.EntityDiagram) -> String {
  @entity.render_svg(diagram)
}
