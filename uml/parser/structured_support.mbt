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
fn blank_node() -> @structured.StructuredNode {
  {
    kind: @structured.Array,
    rows: [{ key: None, value: @structured.Text(""), child: None }],
  }
}

///|
priv enum StructuredValueView[T] {
  ScalarView(@structured.StructuredValueDisplay)
  ObjectView(Array[(String, T)])
  ArrayView(Array[T])
  EmptyView
}

///|
fn[T] structured_row_from_view(
  key : String?,
  view : StructuredValueView[T],
  inspect : (T) -> StructuredValueView[T],
) -> @structured.StructuredRow {
  match view {
    ScalarView(value) => { key, value, child: None }
    ObjectView(_) | ArrayView(_) | EmptyView =>
      {
        key,
        value: @structured.Compound,
        child: Some(structured_node_from_view(view, inspect)),
      }
  }
}

///|
fn[T] structured_node_from_view(
  view : StructuredValueView[T],
  inspect : (T) -> StructuredValueView[T],
) -> @structured.StructuredNode {
  match view {
    EmptyView => blank_node()
    ScalarView(value) =>
      { kind: @structured.Array, rows: [{ key: None, value, child: None }] }
    ObjectView(entries) =>
      {
        kind: @structured.Object,
        rows: entries.map(entry => {
          structured_row_from_view(Some(entry.0), inspect(entry.1), inspect)
        }),
      }
    ArrayView(values) =>
      {
        kind: @structured.Array,
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
) -> @structured.StructuredNode {
  structured_node_from_view(inspect(value), inspect)
}
