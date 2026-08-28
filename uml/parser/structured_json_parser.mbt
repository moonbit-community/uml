///|
fn json_scalar_display(value : Json) -> @structured.StructuredValueDisplay {
  match value {
    String(text) => @structured.Text(text)
    Number(_, repr~) => @structured.Text(repr.unwrap_or(value.stringify()))
    True => @structured.True
    False => @structured.False
    Null => @structured.Null
    Array(_) | Object(_) => @structured.Compound
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
fn json_root(value : Json) -> @structured.StructuredNode {
  structured_node_from_value(value, json_value_view)
}

///|
pub fn parse_structured_json(
  input : String,
) -> @structured.StructuredDiagram raise @json.ParseError {
  let source = source_between_markers(input, "@startjson", "@endjson")
  { format: @structured.Json, root: json_root(@json.parse(source)), }
}
