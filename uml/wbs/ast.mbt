///|
/// The side on which a WBS node is attached to its parent.
pub(all) enum Direction {
  Left
  Right
} derive(Eq, Debug)

///|
/// The visual form selected for a WBS node.
pub(all) enum NodeShape {
  Box
  Boxless
  Pseudo
} derive(Eq, Debug)

///|
/// One node in PlantUML's work-breakdown tree. `parent` indexes `WbsDiagram::nodes`.
pub struct WbsNode {
  code : String?
  label : String
  level : Int
  direction : Direction
  shape : NodeShape
  background_color : String?
  stereotype : String?
  parent : Int?
} derive(Eq, Debug)

///|
/// A non-tree WBS arrow between two coded nodes.
pub struct WbsLink {
  source : Int
  target : Int
  color : String?
  stereotype : String?
  label : String?
} derive(Eq, Debug)

///|
/// One property from a PlantUML `<style>` block. Nested selectors are joined
/// from outermost to innermost, for example `wbsDiagram node`.
pub struct WbsStyleProperty {
  selector : String
  name : String
  value : String
} derive(Eq, Debug)

///|
/// Parsed PlantUML WBS state.
pub struct WbsDiagram {
  nodes : Array[WbsNode]
  links : Array[WbsLink]
  style : @style.DocumentStyle
  style_properties : Array[WbsStyleProperty]
} derive(Eq, Debug)
