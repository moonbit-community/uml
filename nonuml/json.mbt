///|
pub(all) enum JsonValueDisplay {
  Text(String)
  True
  False
  Null
  Compound
} derive(Eq, Debug)

///|
pub struct JsonRow {
  key : String?
  value : JsonValueDisplay
  child : JsonNode?
} derive(Eq, Debug)

///|
pub(all) enum JsonNodeKind {
  Object
  Array
} derive(Eq, Debug)

///|
/// A PlantUML JSON record node. Objects have key/value rows; arrays have
/// single value rows. Compound rows point to another record node.
pub struct JsonNode {
  kind : JsonNodeKind
  rows : Array[JsonRow]
} derive(Eq, Debug)

///|
pub struct JsonDiagram {
  root : JsonNode
} derive(Eq, Debug)

///|
fn source_between_json_markers(input : String) -> String {
  let output = StringBuilder()
  let mut inside_markers = false
  let mut has_markers = false
  for line in input.split("\n") {
    let marker = line.trim().to_lower()
    if marker == "@startjson" {
      has_markers = true
      inside_markers = true
    } else if marker == "@endjson" && inside_markers {
      inside_markers = false
    } else if !has_markers || inside_markers {
      output.write_string(line.to_owned())
      output.write_char('\n')
    }
  }
  output.to_string()
}

///|
fn scalar_display(value : Json) -> JsonValueDisplay {
  match value {
    String(text) => Text(text)
    Number(_, repr~) => Text(repr.unwrap_or(value.stringify()))
    True => True
    False => False
    Null => Null
    Array(_) | Object(_) => Compound
  }
}

///|
fn blank_node() -> JsonNode {
  { kind: Array, rows: [{ key: None, value: Text(""), child: None }] }
}

///|
fn node_from_value(value : Json) -> JsonNode {
  match value {
    Object(object) if object.is_empty() => blank_node()
    Array(array) if array.is_empty() => blank_node()
    Object(object) => {
      let rows = []
      for key, child_value in object {
        let child = match child_value {
          Object(_) | Array(_) => Some(node_from_value(child_value))
          _ => None
        }
        rows.push({ key: Some(key), value: scalar_display(child_value), child })
      }
      { kind: Object, rows }
    }
    Array(array) => {
      let rows = []
      for child_value in array {
        let child = match child_value {
          Object(_) | Array(_) => Some(node_from_value(child_value))
          _ => None
        }
        rows.push({ key: None, value: scalar_display(child_value), child })
      }
      { kind: Array, rows }
    }
    _ =>
      {
        kind: Array,
        rows: [{ key: None, value: scalar_display(value), child: None }],
      }
  }
}

///|
fn normalized_root(value : Json) -> JsonNode {
  match value {
    Object(object) if object.is_empty() => blank_node()
    Array(array) if array.is_empty() => blank_node()
    Object(_) | Array(_) => node_from_value(value)
    _ =>
      {
        kind: Array,
        rows: [{ key: None, value: scalar_display(value), child: None }],
      }
  }
}

///|
pub fn parse_json(input : String) -> JsonDiagram raise @json.ParseError {
  let source = source_between_json_markers(input)
  let value = @json.parse(source)
  { root: normalized_root(value) }
}
