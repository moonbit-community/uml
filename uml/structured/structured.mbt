///|
pub(all) enum StructuredValueDisplay {
  Text(String)
  True
  False
  Null
  Compound
} derive(Eq, Debug)

///|
pub extend StructuredValueDisplay with Eq::{not_equal, equal}

///|
pub extend StructuredValueDisplay with Debug::{to_repr}

///|
pub(all) struct StructuredRow {
  key : String?
  value : StructuredValueDisplay
  child : StructuredNode?
} derive(Eq, Debug)

///|
pub extend StructuredRow with Eq::{not_equal, equal}

///|
pub extend StructuredRow with Debug::{to_repr}

///|
pub(all) enum StructuredNodeKind {
  Object
  Array
} derive(Eq, Debug)

///|
pub extend StructuredNodeKind with Eq::{not_equal, equal}

///|
pub extend StructuredNodeKind with Debug::{to_repr}

///|
/// Source format represented by a structured-data diagram.
pub(all) enum StructuredFormat {
  Json
  Yaml
  Toml
} derive(Eq, Debug)

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
pub(all) struct StructuredNode {
  kind : StructuredNodeKind
  rows : Array[StructuredRow]
} derive(Eq, Debug)

///|
pub extend StructuredNode with Eq::{not_equal, equal}

///|
pub extend StructuredNode with Debug::{to_repr}

///|
pub(all) struct StructuredDiagram {
  format : StructuredFormat
  root : StructuredNode
} derive(Eq, Debug)

///|
pub extend StructuredDiagram with Eq::{not_equal, equal}

///|
pub extend StructuredDiagram with Debug::{to_repr}

///|
