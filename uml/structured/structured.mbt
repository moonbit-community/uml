///|
#derive(Eq, Debug)
pub(all) enum StructuredValueDisplay {
  Text(String)
  True
  False
  Null
  Compound
}

///|
pub extend StructuredValueDisplay with Eq::{not_equal, equal}

///|
pub extend StructuredValueDisplay with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StructuredRow {
  key : String?
  value : StructuredValueDisplay
  child : StructuredNode?
}

///|
pub extend StructuredRow with Eq::{not_equal, equal}

///|
pub extend StructuredRow with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum StructuredNodeKind {
  Object
  Array
}

///|
pub extend StructuredNodeKind with Eq::{not_equal, equal}

///|
pub extend StructuredNodeKind with Debug::{to_repr}

///|
/// Source format represented by a structured-data diagram.
#derive(Eq, Debug)
pub(all) enum StructuredFormat {
  Json
  Yaml
  Toml
}

///|
pub extend StructuredFormat with Eq::{not_equal, equal}

///|
pub extend StructuredFormat with Debug::{to_repr}

///|
pub fn StructuredFormat::aria_label(self : StructuredFormat) -> String {
  match self {
    Json => "JSON diagram"
    Yaml => "YAML diagram"
    Toml => "TOML diagram"
  }
}

///|
/// A structured-data record node shared by JSON, YAML, and TOML renderers.
/// Objects have key/value rows; arrays have single value rows. Compound rows
/// point to another record node.
#derive(Eq, Debug)
pub(all) struct StructuredNode {
  kind : StructuredNodeKind
  rows : Array[StructuredRow]
}

///|
pub extend StructuredNode with Eq::{not_equal, equal}

///|
pub extend StructuredNode with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StructuredDiagram {
  format : StructuredFormat
  root : StructuredNode
  presentation : Array[@style.StyleDirective]
  styles : Array[StructuredStyleProperty]
  highlights : Array[StructuredHighlight]
}

///|
pub extend StructuredDiagram with Eq::{not_equal, equal}

///|
pub extend StructuredDiagram with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct StructuredStyleProperty {
  selector : String
  name : String
  value : String
}

///|
#derive(Eq, Debug)
pub(all) struct StructuredHighlight {
  path : Array[String]
  stereotype : String?
}

///|

///|
pub extend StructuredStyleProperty with Eq::{not_equal, equal}

///|
pub extend StructuredStyleProperty with Debug::{to_repr}

///|
pub extend StructuredHighlight with Eq::{not_equal, equal}

///|
pub extend StructuredHighlight with Debug::{to_repr}
