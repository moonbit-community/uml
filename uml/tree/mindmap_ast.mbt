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
pub(all) struct Idea {
  label : String
  level : Int
  direction : TreeDirection
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
pub(all) struct MindmapDiagram {
  ideas : Array[Idea]
  style : @style.DocumentStyle
  mindmap_style : MindmapStyle
} derive(Eq, Debug)

///|
pub extend MindmapDiagram with Eq::{not_equal, equal}

///|
pub extend MindmapDiagram with Debug::{to_repr}
