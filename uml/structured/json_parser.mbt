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
fn json_value_view(value : Json) -> StructuredValueView[Json] {
  match value {
    Object(object) if object.is_empty() => EmptyView
    Array(array) if array.is_empty() => EmptyView
    Object(object) => ObjectView(object.to_array())
    Array(array) => ArrayView(array)
    _ => ScalarView(json_scalar_display(value))
  }
}

///|
fn json_root(value : Json) -> StructuredNode {
  structured_node_from_value(value, json_value_view)
}

///|
pub fn parse_json(input : String) -> StructuredDiagram raise @json.ParseError {
  let source = source_between_markers(input, "@startjson", "@endjson")
  { format: Json, root: json_root(@json.parse(source)), }
}
