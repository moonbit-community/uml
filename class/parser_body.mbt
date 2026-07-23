///|
priv struct MapEntryLineSyntax {
  entry : MapEntry
  arrow : String?
}

///|
priv enum ParsedMapEntrySyntax {
  ParsedMapValue(key~ : String, value~ : String)
  ParsedMapLink(key~ : String, arrow~ : String, target~ : String)
}

///|
fn map_value_entry_parser() -> @talcparsec.StringParser[ParsedMapEntrySyntax] {
  let separator = @talcparsec.string("=>")
  separator
  .not_followed_by("map value separator")
  .then(@talcparsec.satisfy("map key", _ => true))
  .string_map(char => char.to_string())
  .many()
  .map(parts => parts.join("").trim().to_owned())
  .skip(separator)
  .bind(key => {
    guard key.length() > 0 else { return @talcparsec.fail("map key") }
    @talcparsec.many_chars(@talcparsec.satisfy("map value", _ => true)).map(value => {
      let value = value.trim().to_owned()
      ParsedMapValue(key~, value~)
    })
  })
}

///|
fn map_link_entry_parser() -> @talcparsec.StringParser[ParsedMapEntrySyntax] {
  linked_map_arrow_parser().bind(prefix => {
    let (key, arrow) = prefix
    let key = key.trim().to_owned()
    guard key.length() > 0 else { return @talcparsec.fail("map link key") }
    @talcparsec.many_chars1(@talcparsec.satisfy("map link target", _ => true)).bind(target => {
        let target = normalize_name(target.trim().to_owned())
        if target.length() > 0 {
          @talcparsec.pure(ParsedMapLink(key~, arrow~, target~))
        } else {
          @talcparsec.fail("map link target")
        }
      },
    )
  })
}

///|
fn map_entry_line_parser() -> @talcparsec.StringParser[ParsedMapEntrySyntax] {
  map_value_entry_parser()
  .attempt()
  .or(map_link_entry_parser())
  .skip(@talcparsec.eof())
}

///|
fn parse_map_entry_line(line : String) -> MapEntryLineSyntax? {
  match map_entry_line_parser().parse(@talcparsec.Input::new(line)) {
    Ok(ParsedMapValue(key~, value~)) =>
      Some({
        entry: { key, value: Some(value), link_target: None, raw: line },
        arrow: None,
      })
    Ok(ParsedMapLink(key~, arrow~, target~)) =>
      Some({
        entry: { key, value: None, link_target: Some(target), raw: line },
        arrow: Some(arrow),
      })
    Err(_) => None
  }
}

///|
fn brace_delta(line : String) -> Int {
  parse_brace_delta(line)
}

///|
priv struct MultilineElementHeader {
  declaration : Declaration
  first_line : String
  terminator : Char
}

///|
fn Parser::consume_multiline_element(
  self : Parser,
  header : MultilineElementHeader,
) -> Unit raise ParseError {
  let display = StringBuilder()
  if header.first_line.length() > 0 {
    display.write_string(header.first_line)
  }
  self.index += 1
  while self.index < self.lines.length() {
    let line = strip_comment(self.lines[self.index])
    let chars = line.to_array()
    let mut closing = None
    for index in 0..<chars.length() {
      if chars[index] == header.terminator {
        closing = Some(index)
        break
      }
    }
    match closing {
      Some(index) => {
        let tail = line[0:index].to_owned()
        if display.to_string().length() > 0 && tail.length() > 0 {
          display.write_char('\n')
        }
        display.write_string(tail)
        self.add_entity(
          { ..header.declaration, display: display.to_string() },
          false,
        )
        return
      }
      None => {
        if display.to_string().length() > 0 {
          display.write_char('\n')
        }
        display.write_string(line)
      }
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed multiline element description")
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
  arrow : String,
) -> Unit raise ParseError {
  guard entry.link_target is Some(target) else { return }
  let resolved = self.resolve(target)
  guard self.entities.any(entity => entity.qualified_code == resolved) else {
    self.raise_parse_error("no such entity \{target}")
  }
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
    guard parse_map_entry_line(line) is Some(syntax) else {
      self.raise_parse_error("map definition should contain key => value")
    }
    self.entities[entity_index].map_entries.push(syntax.entry)
    match syntax.arrow {
      Some(arrow) => self.add_map_link(entity, syntax.entry, arrow)
      None => ()
    }
    return
  }
  self.entities[entity_index].members.push(member_of(line))
}
