///|
/// A diagram parsed from a `@startuml '.mbti` source.
///
/// The `.mbti` interface is adapted to the shared entity graph, so the layout
/// and SVG pipeline of the class diagram engine render it unchanged. The
/// package and imports are retained for callers; the rendered graph is the
/// `graph` field.
pub(all) struct MbtiDiagram {
  package_name : String
  imports : Array[String]
  graph : EntityDiagram
} derive(Eq, Debug)

///|
pub extend MbtiDiagram with Eq::{not_equal, equal}

///|
pub extend MbtiDiagram with Debug::{to_repr}
