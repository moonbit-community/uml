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
fn yaml_value_display(value : @yaml.Yaml) -> JsonValueDisplay {
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
fn yaml_node_from_value(value : @yaml.Yaml) -> JsonNode {
  match value {
    Map(map) if map.is_empty() => blank_node()
    Array(values) if values.is_empty() => blank_node()
    Map(map) => {
      let rows = []
      for key, child_value in map {
        let child = match child_value {
          Map(_) | Array(_) => Some(yaml_node_from_value(child_value))
          _ => None
        }
        rows.push({
          key: Some(key),
          value: yaml_value_display(child_value),
          child,
        })
      }
      { kind: Object, rows }
    }
    Array(values) => {
      let rows = []
      for child_value in values {
        let child = match child_value {
          Map(_) | Array(_) => Some(yaml_node_from_value(child_value))
          _ => None
        }
        rows.push({ key: None, value: yaml_value_display(child_value), child })
      }
      { kind: Array, rows }
    }
    _ =>
      {
        kind: Array,
        rows: [{ key: None, value: yaml_value_display(value), child: None }],
      }
  }
}

///|
fn yaml_root(documents : Array[@yaml.Yaml]) -> JsonNode {
  match documents {
    [document] => yaml_node_from_value(document)
    _ => yaml_node_from_value(Array(documents))
  }
}

///|
pub fn parse_yaml(input : String) -> JsonDiagram raise @yaml.YamlError {
  let source = source_between_markers(input, "@startyaml", "@endyaml")
  { root: yaml_root(@yaml.Yaml::load_from_string(source)) }
}

///|
fn toml_value_display(value : @toml.TomlValue) -> JsonValueDisplay {
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
fn toml_node_from_value(value : @toml.TomlValue) -> JsonNode {
  match value {
    TomlTable(table) if table.is_empty() => blank_node()
    TomlArray(values) if values.is_empty() => blank_node()
    TomlTable(table) => {
      let rows = []
      for key, child_value in table {
        let child = match child_value {
          TomlTable(_) | TomlArray(_) => Some(toml_node_from_value(child_value))
          _ => None
        }
        rows.push({
          key: Some(key),
          value: toml_value_display(child_value),
          child,
        })
      }
      { kind: Object, rows }
    }
    TomlArray(values) => {
      let rows = []
      for child_value in values {
        let child = match child_value {
          TomlTable(_) | TomlArray(_) => Some(toml_node_from_value(child_value))
          _ => None
        }
        rows.push({ key: None, value: toml_value_display(child_value), child })
      }
      { kind: Array, rows }
    }
    _ =>
      {
        kind: Array,
        rows: [{ key: None, value: toml_value_display(value), child: None }],
      }
  }
}

///|
pub fn parse_toml(input : String) -> JsonDiagram raise {
  let source = source_between_markers(input, "@starttoml", "@endtoml")
  { root: toml_node_from_value(@toml.parse(source)) }
}
