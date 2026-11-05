///|
/// The visual form requested by a mindmap item.
#derive(Eq, Debug)
pub(all) enum IdeaShape {
  Box
  Boxless
}

///|
pub extend IdeaShape with Eq::{not_equal, equal}

///|
pub extend IdeaShape with Debug::{to_repr}

///|
/// A parsed mindmap item. `parent` is the index of its parent in
/// `MindmapDiagram::ideas`; the root has no parent.
#derive(Eq, Debug)
pub(all) struct Idea {
  label : String
  level : Int32
  direction : TreeDirection
  shape : IdeaShape
  background_color : String?
  stereotype : String?
  parent : Int32?
}

///|
pub extend Idea with Eq::{not_equal, equal}

///|
pub extend Idea with Debug::{to_repr}

///|
/// Parsed PlantUML mindmap state.
#derive(Eq, Debug)
pub(all) struct MindmapDiagram {
  ideas : Array[Idea]
  style : @style.DocumentStyle
  mindmap_style : MindmapStyle
  style_properties : Array[WbsStyleProperty]
}

///|
pub extend MindmapDiagram with Eq::{not_equal, equal}

///|
pub extend MindmapDiagram with Debug::{to_repr}
