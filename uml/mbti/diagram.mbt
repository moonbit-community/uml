///|
/// A diagram parsed from a `@startuml '.mbti` source.
///
/// The `.mbti` interface is adapted to the shared entity graph, so the layout
/// and SVG pipeline of the class diagram engine render it unchanged. The
/// package and imports are retained for callers; the rendered graph is the
/// `graph` field.
pub struct MbtiDiagram {
  package_name : String
  imports : Array[String]
  graph : @entity.EntityDiagram
} derive(Eq, Debug)

///|
pub extend MbtiDiagram with Eq::{not_equal, equal}

///|
pub extend MbtiDiagram with Debug::{to_repr}

///|
/// Render the adapted interface graph to SVG with the mindmap tree layout:
/// entities with no incoming relation are the roots and every other class
/// hangs under the target of its first relation.
pub fn MbtiDiagram::render_svg(
  self : MbtiDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
  class_member_collapsible? : Bool = false,
) -> String raise @dot_layout.DotLayoutError {
  self.graph.render_mbti_svg(color_scheme~, class_member_collapsible~)
}
