///|
/// The visual form selected for a WBS node.
pub(all) enum NodeShape {
  Box
  Boxless
  Pseudo
} derive(Eq, Debug)

///|
pub extend NodeShape with Eq::{not_equal, equal}

///|
pub extend NodeShape with Debug::{to_repr}

///|
/// One node in PlantUML's work-breakdown tree. `parent` indexes `WbsDiagram::nodes`.
pub(all) struct WbsNode {
  code : String?
  label : String
  level : Int
  direction : TreeDirection
  shape : NodeShape
  background_color : String?
  stereotype : String?
  parent : Int?
} derive(Eq, Debug)

///|
pub extend WbsNode with Eq::{not_equal, equal}

///|
pub extend WbsNode with Debug::{to_repr}

///|
/// A non-tree WBS arrow between two coded nodes.
pub(all) struct WbsLink {
  source : Int
  target : Int
  color : String?
  stereotype : String?
  label : String?
} derive(Eq, Debug)

///|
pub extend WbsLink with Eq::{not_equal, equal}

///|
pub extend WbsLink with Debug::{to_repr}

///|
/// One property from a PlantUML `<style>` block. Nested selectors are joined
/// from outermost to innermost, for example `wbsDiagram node`.
pub(all) struct WbsStyleProperty {
  selector : String
  name : String
  value : String
} derive(Eq, Debug)

///|
pub extend WbsStyleProperty with Eq::{not_equal, equal}

///|
pub extend WbsStyleProperty with Debug::{to_repr}

///|
/// Parsed PlantUML WBS state.
pub(all) struct WbsDiagram {
  nodes : Array[WbsNode]
  links : Array[WbsLink]
  style : @style.DocumentStyle
  style_properties : Array[WbsStyleProperty]
} derive(Eq, Debug)

///|
pub extend WbsDiagram with Eq::{not_equal, equal}

///|
pub extend WbsDiagram with Debug::{to_repr}
