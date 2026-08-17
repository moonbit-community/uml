///|
pub(all) enum StructuredValueDisplay {
  Text(String)
  True
  False
  Null
  Compound
} derive(Eq, Debug)

pub extend StructuredValueDisplay with Eq::{not_equal, equal}
pub extend StructuredValueDisplay with Debug::{to_repr}


///|
pub struct StructuredRow {
  key : String?
  value : StructuredValueDisplay
  child : StructuredNode?
} derive(Eq, Debug)

pub extend StructuredRow with Eq::{not_equal, equal}
pub extend StructuredRow with Debug::{to_repr}


///|
pub(all) enum StructuredNodeKind {
  Object
  Array
} derive(Eq, Debug)

pub extend StructuredNodeKind with Eq::{not_equal, equal}
pub extend StructuredNodeKind with Debug::{to_repr}


///|
/// Source format represented by a structured-data diagram.
pub(all) enum StructuredFormat {
  Json
  Yaml
  Toml
} derive(Eq, Debug)

pub extend StructuredFormat with Eq::{not_equal, equal}
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
pub struct StructuredNode {
  kind : StructuredNodeKind
  rows : Array[StructuredRow]
} derive(Eq, Debug)

pub extend StructuredNode with Eq::{not_equal, equal}
pub extend StructuredNode with Debug::{to_repr}


///|
pub struct StructuredDiagram {
  format : StructuredFormat
  root : StructuredNode
} derive(Eq, Debug)

pub extend StructuredDiagram with Eq::{not_equal, equal}
pub extend StructuredDiagram with Debug::{to_repr}


///|
fn source_between_markers(
  input : String,
  start_marker : String,
  end_marker : String,
) -> String {
  let output = StringBuilder()
  let mut inside_markers = false
  let mut has_markers = false
  for line in input.split("\n") {
    let marker = line.trim().to_lower()
    if marker == start_marker {
      has_markers = true
      inside_markers = true
    } else if marker == end_marker && inside_markers {
      inside_markers = false
    } else if !has_markers || inside_markers {
      output.write_string(line.to_owned())
      output.write_char('\n')
    }
  }
  output.to_string()
}

///|
fn blank_node() -> StructuredNode {
  { kind: Array, rows: [{ key: None, value: Text(""), child: None }] }
}

///|
priv enum StructuredValueView[T] {
  ScalarView(StructuredValueDisplay)
  ObjectView(Array[(String, T)])
  ArrayView(Array[T])
  EmptyView
}

///|
fn[T] structured_row_from_view(
  key : String?,
  view : StructuredValueView[T],
  inspect : (T) -> StructuredValueView[T],
) -> StructuredRow {
  match view {
    ScalarView(value) => { key, value, child: None }
    ObjectView(_) | ArrayView(_) | EmptyView =>
      {
        key,
        value: Compound,
        child: Some(structured_node_from_view(view, inspect)),
      }
  }
}

///|
fn[T] structured_node_from_view(
  view : StructuredValueView[T],
  inspect : (T) -> StructuredValueView[T],
) -> StructuredNode {
  match view {
    EmptyView => blank_node()
    ScalarView(value) =>
      { kind: Array, rows: [{ key: None, value, child: None }] }
    ObjectView(entries) =>
      {
        kind: Object,
        rows: entries.map(entry => {
          structured_row_from_view(Some(entry.0), inspect(entry.1), inspect)
        }),
      }
    ArrayView(values) =>
      {
        kind: Array,
        rows: values.map(value => {
          structured_row_from_view(None, inspect(value), inspect)
        }),
      }
  }
}

///|
fn[T] structured_node_from_value(
  value : T,
  inspect : (T) -> StructuredValueView[T],
) -> StructuredNode {
  structured_node_from_view(inspect(value), inspect)
}