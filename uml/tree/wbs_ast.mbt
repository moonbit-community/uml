///|
/// The visual form selected for a WBS node.
#derive(Eq, Debug)
pub(all) enum NodeShape {
  Box
  Boxless
  Pseudo
}

///|
pub extend NodeShape with Eq::{not_equal, equal}

///|
pub extend NodeShape with Debug::{to_repr}

///|
/// One node in PlantUML's work-breakdown tree. `parent` indexes `WbsDiagram::nodes`.
#derive(Eq, Debug)
pub(all) struct WbsNode {
  code : String?
  label : String
  level : Int32
  direction : TreeDirection
  shape : NodeShape
  background_color : String?
  stereotype : String?
  parent : Int32?
}

///|
pub extend WbsNode with Eq::{not_equal, equal}

///|
pub extend WbsNode with Debug::{to_repr}

///|
/// A non-tree WBS arrow between two coded nodes.
#derive(Eq, Debug)
pub(all) struct WbsLink {
  source : Int32
  target : Int32
  color : String?
  stereotype : String?
  label : String?
}

///|
pub extend WbsLink with Eq::{not_equal, equal}

///|
pub extend WbsLink with Debug::{to_repr}

///|
/// One property from a PlantUML `<style>` block. Nested selectors are joined
/// from outermost to innermost, for example `wbsDiagram node`.
#derive(Eq, Debug)
pub(all) struct WbsStyleProperty {
  selector : String
  name : String
  value : String
}

///|
pub extend WbsStyleProperty with Eq::{not_equal, equal}

///|
pub extend WbsStyleProperty with Debug::{to_repr}

///|
/// Parsed PlantUML WBS state.
#derive(Eq, Debug)
pub(all) struct WbsDiagram {
  nodes : Array[WbsNode]
  links : Array[WbsLink]
  style : @style.DocumentStyle
  style_properties : Array[WbsStyleProperty]
}

///|
pub extend WbsDiagram with Eq::{not_equal, equal}

///|
pub extend WbsDiagram with Debug::{to_repr}
