///|
/// Which side of the root a mindmap idea belongs to.
pub(all) enum Direction {
  Left
  Right
} derive(Eq, Debug)

///|
/// The visual form requested by a mindmap item.
pub(all) enum IdeaShape {
  Box
  None
} derive(Eq, Debug)

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
/// Parsed PlantUML mindmap state.
pub struct MindmapDiagram {
  ideas : Array[Idea]
  style : @core.DocumentStyle
  mindmap_style : MindmapStyle
} derive(Eq, Debug)
