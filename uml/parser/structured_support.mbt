///|
fn blank_node() -> @structured.StructuredNode {
  {
    kind: @structured.Array,
    rows: [{ key: None, value: @structured.Text(""), child: None, }],
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
    ScalarView(value) => { key, value, child: None, }
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
      { kind: @structured.Array, rows: [{ key: None, value, child: None, }], }
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
