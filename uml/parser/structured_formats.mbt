///|
fn yaml_value_display(value : @yaml.Yaml) -> @structured.StructuredValueDisplay {
  match value {
    String(text) => @structured.Text(text)
    Integer(number) => @structured.Text(number.to_string())
    Real(_, repr~) => @structured.Text(repr)
    Boolean(true) => @structured.True
    Boolean(false) => @structured.False
    Null => @structured.Null
    Array(_) | Map(_) | BadValue => @structured.Compound
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
fn yaml_root(documents : Array[@yaml.Yaml]) -> @structured.StructuredNode {
  match documents {
    [document] => structured_node_from_value(document, yaml_value_view)
    _ => structured_node_from_value(@yaml.Array(documents), yaml_value_view)
  }
}

///|
pub fn parse_structured_yaml(
  input : String,
) -> @structured.StructuredDiagram raise @yaml.YamlError {
  let source = source_between_markers(input, "@startyaml", "@endyaml")
  {
    format: @structured.Yaml,
    root: yaml_root(@yaml.Yaml::load_from_string(source)),
  }
}

///|
fn toml_value_display(
  value : @toml.TomlValue,
) -> @structured.StructuredValueDisplay {
  match value {
    TomlString(text) => @structured.Text(text)
    TomlInteger(number) => @structured.Text(number.to_string())
    TomlFloat(number) => @structured.Text(number.to_string())
    TomlBoolean(true) => @structured.True
    TomlBoolean(false) => @structured.False
    TomlDateTime(_) => @structured.Text(value.datetime_info().unwrap().1)
    TomlArray(_) | TomlTable(_) => @structured.Compound
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
pub fn parse_structured_toml(
  input : String,
) -> @structured.StructuredDiagram raise {
  let source = source_between_markers(input, "@starttoml", "@endtoml")
  {
    format: @structured.Toml,
    root: structured_node_from_value(@toml.parse(source), toml_value_view),
  }
}
