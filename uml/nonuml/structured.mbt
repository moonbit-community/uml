///|
pub(all) enum StructuredValueDisplay {
  Text(String)
  True
  False
  Null
  Compound
} derive(Eq, Debug)

///|
pub struct StructuredRow {
  key : String?
  value : StructuredValueDisplay
  child : StructuredNode?
} derive(Eq, Debug)

///|
pub(all) enum StructuredNodeKind {
  Object
  Array
} derive(Eq, Debug)

///|
/// A structured-data record node shared by JSON, YAML, and TOML renderers.
/// Objects have key/value rows; arrays have single value rows. Compound rows
/// point to another record node.
pub struct StructuredNode {
  kind : StructuredNodeKind
  rows : Array[StructuredRow]
} derive(Eq, Debug)

///|
pub struct StructuredDiagram {
  root : StructuredNode
} derive(Eq, Debug)

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
