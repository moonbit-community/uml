///|
fn json_scalar_display(value : Json) -> StructuredValueDisplay {
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
fn json_node_from_value(value : Json) -> StructuredNode {
  match value {
    Object(object) if object.is_empty() => blank_node()
    Array(array) if array.is_empty() => blank_node()
    Object(object) => {
      let rows = []
      for key, child_value in object {
        let child = match child_value {
          Object(_) | Array(_) => Some(json_node_from_value(child_value))
          _ => None
        }
        rows.push({
          key: Some(key),
          value: json_scalar_display(child_value),
          child,
        })
      }
      { kind: Object, rows }
    }
    Array(array) => {
      let rows = []
      for child_value in array {
        let child = match child_value {
          Object(_) | Array(_) => Some(json_node_from_value(child_value))
          _ => None
        }
        rows.push({ key: None, value: json_scalar_display(child_value), child })
      }
      { kind: Array, rows }
    }
    _ =>
      {
        kind: Array,
        rows: [{ key: None, value: json_scalar_display(value), child: None }],
      }
  }
}

///|
fn json_root(value : Json) -> StructuredNode {
  match value {
    Object(object) if object.is_empty() => blank_node()
    Array(array) if array.is_empty() => blank_node()
    Object(_) | Array(_) => json_node_from_value(value)
    _ =>
      {
        kind: Array,
        rows: [{ key: None, value: json_scalar_display(value), child: None }],
      }
  }
}

///|
pub fn parse_json(input : String) -> StructuredDiagram raise @json.ParseError {
  let source = source_between_markers(input, "@startjson", "@endjson")
  { root: json_root(@json.parse(source)) }
}
