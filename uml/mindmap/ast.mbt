///|
/// Which side of the root a mindmap idea belongs to.
pub(all) enum Direction {
  Left
  Right
} derive(Eq, Debug)

///|
pub extend Direction with Eq::{not_equal, equal}

///|
pub extend Direction with Debug::{to_repr}

///|
/// The visual form requested by a mindmap item.
pub(all) enum IdeaShape {
  Box
  Boxless
} derive(Eq, Debug)

///|
pub extend IdeaShape with Eq::{not_equal, equal}

///|
pub extend IdeaShape with Debug::{to_repr}

///|
/// A parsed mindmap item. `parent` is the index of its parent in
/// `MindmapDiagram::ideas`; the root has no parent.
pub struct Idea {
  label : String
  level : Int
  direction : Direction
  shape : IdeaShape
  background_color : String?
  stereotype : String?
  parent : Int?
} derive(Eq, Debug)

///|
pub extend Idea with Eq::{not_equal, equal}

///|
pub extend Idea with Debug::{to_repr}

///|
/// Parsed PlantUML mindmap state.
pub struct MindmapDiagram {
  ideas : Array[Idea]
  style : @style.DocumentStyle
  mindmap_style : MindmapStyle
} derive(Eq, Debug)

///|
pub extend MindmapDiagram with Eq::{not_equal, equal}

///|
pub extend MindmapDiagram with Debug::{to_repr}
