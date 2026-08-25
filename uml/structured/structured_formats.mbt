///|
fn yaml_value_display(value : @yaml.Yaml) -> StructuredValueDisplay {
  match value {
    String(text) => Text(text)
    Integer(number) => Text(number.to_string())
    Real(_, repr~) => Text(repr)
    Boolean(true) => True
    Boolean(false) => False
    Null => Null
    Array(_) | Map(_) | BadValue => Compound
  }
}

///|
fn yaml_value_view(value : @yaml.Yaml) -> StructuredValueView[@yaml.Yaml] {
  match value {
    Map(map) if map.is_empty() => EmptyView
    Array(values) if values.is_empty() => EmptyView
    Map(map) => ObjectView(map.to_array())
    Array(values) => ArrayView(values)
    _ => ScalarView(yaml_value_display(value))
  }
}

///|
fn yaml_root(documents : Array[@yaml.Yaml]) -> StructuredNode {
  match documents {
    [document] => structured_node_from_value(document, yaml_value_view)
    _ => structured_node_from_value(@yaml.Array(documents), yaml_value_view)
  }
}

///|
pub fn parse_yaml(input : String) -> StructuredDiagram raise @yaml.YamlError {
  let source = source_between_markers(input, "@startyaml", "@endyaml")
  { format: Yaml, root: yaml_root(@yaml.Yaml::load_from_string(source)), }
}

///|
fn toml_value_display(value : @toml.TomlValue) -> StructuredValueDisplay {
  match value {
    TomlString(text) => Text(text)
    TomlInteger(number) => Text(number.to_string())
    TomlFloat(number) => Text(number.to_string())
    TomlBoolean(true) => True
    TomlBoolean(false) => False
    TomlDateTime(_) => Text(value.datetime_info().unwrap().1)
    TomlArray(_) | TomlTable(_) => Compound
  }
}

///|
fn toml_value_view(
  value : @toml.TomlValue,
) -> StructuredValueView[@toml.TomlValue] {
  match value {
    TomlTable(table) if table.is_empty() => EmptyView
    TomlArray(values) if values.is_empty() => EmptyView
    TomlTable(table) => ObjectView(table.to_array())
    TomlArray(values) => ArrayView(values)
    _ => ScalarView(toml_value_display(value))
  }
}

///|
pub fn parse_toml(input : String) -> StructuredDiagram raise {
  let source = source_between_markers(input, "@starttoml", "@endtoml")
  {
    format: Toml,
    root: structured_node_from_value(@toml.parse(source), toml_value_view),
  }
}
