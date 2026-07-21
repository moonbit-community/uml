///|
fn linked_map_arrow(line : String) -> (String, Int, Int)? {
  let chars = line.to_array()
  for start in 0..<chars.length() {
    guard chars[start] == '*' else { continue }
    let mut end = start + 1
    while end < chars.length() && chars[end] == '-' {
      end += 1
    }
    if end < chars.length() && chars[end] == '_' {
      end += 1
    }
    if end < chars.length() && chars[end] == '>' && end > start + 1 {
      return Some((line[start:end + 1].to_owned(), start, end + 1))
    }
  }
  None
}

///|
fn parse_map_entry(line : String) -> MapEntry? {
  guard find_substring(line, "=>") is Some(separator) else {
    guard linked_map_arrow(line) is Some((_, start, end)) else { return None }
    let key = line[0:start].trim().to_owned()
    let target = normalize_name(line[end:].trim().to_owned())
    guard key.length() > 0 && target.length() > 0 else { return None }
    return Some({ key, value: None, link_target: Some(target), raw: line })
  }
  let key = line[0:separator].trim().to_owned()
  let value = line[separator + 2:].trim().to_owned()
  guard key.length() > 0 else { return None }
  Some({ key, value: Some(value), link_target: None, raw: line })
}

///|
fn brace_delta(line : String) -> Int {
  let mut quoted = false
  let mut escaped = false
  let mut delta = 0
  for char in line {
    if escaped {
      escaped = false
      continue
    }
    if char == '\\' && quoted {
      escaped = true
      continue
    }
    if char == '"' {
      quoted = !quoted
      continue
    }
    if !quoted && char == '{' {
      delta += 1
    } else if !quoted && char == '}' {
      delta -= 1
    }
  }
  delta
}

///|
priv struct JsonSingleDeclaration {
  declaration : Declaration
  data : String
}

///|
fn valid_json(source : String) -> Bool {
  try {
    ignore(@json.parse(source))
    true
  } catch {
    _ => false
  }
}

///|
fn parse_single_line_json(line : String) -> JsonSingleDeclaration? {
  guard line.to_lower().has_prefix("json ") && !line.trim().has_suffix("{") else {
    return None
  }
  let chars = line.to_array()
  for separator in 5..<chars.length() {
    guard chars[separator] == ' ' else { continue }
    let data = line[separator + 1:].trim().to_owned()
    guard data.length() > 0 && valid_json(data) else { continue }
    guard parse_declaration(line[0:separator].trim().to_owned())
      is Some(declaration) &&
      declaration.kind is Json else {
      continue
    }
    return Some({ declaration, data })
  }
  None
}

///|
fn Parser::add_single_line_json(
  self : Parser,
  value : JsonSingleDeclaration,
) -> Unit raise ParseError {
  let qualified_code = self.qualify(value.declaration.code)
  guard !self.entities.any(entity => entity.qualified_code == qualified_code) else {
    self.raise_parse_error("JSON already exists: \{value.declaration.code}")
  }
  self.add_entity(value.declaration, false)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = { ..entity, json_data: Some(value.data) }
      return
    }
  }
}

///|
fn Parser::add_map_link(
  self : Parser,
  source : Entity,
  entry : MapEntry,
) -> Unit raise ParseError {
  guard entry.link_target is Some(target) else { return }
  let resolved = self.resolve(target)
  guard self.entities.any(entity => entity.qualified_code == resolved) else {
    self.raise_parse_error("no such entity \{target}")
  }
  let arrow = linked_map_arrow(entry.raw).unwrap().0
  self.relations.push({
    left: source.qualified_code,
    right: resolved,
    kind: Association,
    left_cardinality: None,
    right_cardinality: None,
    left_role: None,
    right_role: None,
    left_qualifier: None,
    right_qualifier: None,
    label: None,
    dotted: false,
    raw_arrow: arrow,
    left_end: Arrow,
    right_end: Plain,
    direction: Automatic,
    line_style: None,
    color: None,
    url: None,
    stereotype: None,
    weight: None,
    inside: None,
    left_port: Some(entry.key),
    right_port: None,
    left_couple: None,
    right_couple: None,
  })
}

///|
fn Parser::consume_json_body_line(
  self : Parser,
  entity_index : Int,
  line : String,
) -> Unit raise ParseError {
  let delta = brace_delta(line)
  if self.body_depth + delta <= 0 {
    let body = self.entities[entity_index].json_data.unwrap_or("")
    let wrapped = "{" + body + "}"
    let source = if valid_json(wrapped) {
      wrapped
    } else if valid_json(body) {
      body
    } else {
      self.raise_parse_error("bad JSON data")
      return
    }
    self.entities[entity_index] = {
      ..self.entities[entity_index],
      json_data: Some(source),
    }
    self.finish_entity()
    return
  }
  let current = self.entities[entity_index].json_data.unwrap_or("")
  let separator = if current.length() == 0 { "" } else { "\n" }
  self.entities[entity_index] = {
    ..self.entities[entity_index],
    json_data: Some(current + separator + line),
  }
  self.body_depth += delta
}

///|
fn Parser::consume_entity_body_line(
  self : Parser,
  entity_index : Int,
  line : String,
) -> Unit raise ParseError {
  let entity = self.entities[entity_index]
  if entity.kind is Json {
    self.consume_json_body_line(entity_index, line)
    return
  }
  if line == "}" || line == "};" {
    self.finish_entity()
    return
  }
  if entity.kind is Map {
    guard parse_map_entry(line) is Some(entry) else {
      self.raise_parse_error("map definition should contain key => value")
    }
    self.entities[entity_index].map_entries.push(entry)
    self.add_map_link(entity, entry)
    return
  }
  self.entities[entity_index].members.push(member_of(line))
}
