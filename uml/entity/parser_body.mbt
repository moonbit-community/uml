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
fn map_value_entry_parser() -> @talc.StringParser[ParsedMapEntrySyntax] {
  let separator = @talc.string("=>")
  separator
  .not_followed_by("map value separator")
  .then(@talc.satisfy("map key", _ => true))
  .string_map(char => char.to_string())
  .many()
  .map(parts => parts.join("").trim().to_owned())
  .skip(separator)
  .bind(key => {
    guard key.length() > 0 else { return @talc.fail("map key") }
    @talc.many_chars(@talc.satisfy("map value", _ => true)).map(value => {
      let value = value.trim().to_owned()
      ParsedMapValue(key~, value~)
    })
  })
}

///|
fn map_link_entry_parser() -> @talc.StringParser[ParsedMapEntrySyntax] {
  linked_map_arrow_parser().bind(prefix => {
    let (key, arrow) = prefix
    let key = key.trim().to_owned()
    guard key.length() > 0 else { return @talc.fail("map link key") }
    @talc.many_chars1(@talc.satisfy("map link target", _ => true)).bind(target => {
      let target = @parse.unquote_identifier(target.trim().to_owned())
      if target.length() > 0 {
        @talc.pure(ParsedMapLink(key~, arrow~, target~))
      } else {
        @talc.fail("map link target")
      }
    })
  })
}

///|
fn map_entry_line_parser() -> @talc.StringParser[ParsedMapEntrySyntax] {
  map_value_entry_parser()
  .attempt()
  .or(map_link_entry_parser())
  .skip(@talc.eof())
}

///|
fn parse_map_entry_line(line : String) -> MapEntryLineSyntax? {
  match map_entry_line_parser().parse(@talc.Input::new(line)) {
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
priv struct MultilineElementHeader {
  declaration : Declaration
  first_line : String
  terminator : Char
}

///|
fn Parser::consume_multiline_element(
  self : Parser,
  header : MultilineElementHeader,
) -> Unit raise @parse.ParseError {
  let display = StringBuilder()
  if header.first_line.length() > 0 {
    display.write_string(header.first_line)
  }
  self.index += 1
  while self.index < self.lines.length() {
    let line = @parse.strip_line_comment(self.lines[self.index])
    let cursor = @parse.Cursor::new(line)
    match @parse.find_literal(line, header.terminator.to_string()) {
      Some(index) => {
        let tail = cursor.slice(0, index)
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
) -> Unit raise @parse.ParseError {
  let qualified_code = self.qualify(value.declaration.code)
  guard !self.has_entity(qualified_code) else {
    self.raise_parse_error("JSON already exists: \{value.declaration.code}")
  }
  self.add_entity(value.declaration, false)
  if self.entity_index(qualified_code) is Some(index) {
    self.entities[index] = {
      ..self.entities[index],
      json_data: Some(value.data),
    }
  }
}

///|
fn Parser::add_map_link(
  self : Parser,
  source : Entity,
  entry : MapEntry,
  arrow : String,
) -> Unit raise @parse.ParseError {
  guard entry.link_target is Some(target) else { return }
  let resolved = self.resolve(target)
  guard self.has_entity(resolved) else {
    self.raise_parse_error("No such entity " + target)
  }
  self.relations.push({
    ..Relation::new(
      source.qualified_code,
      resolved,
      Association,
      arrow,
      Arrow,
      Plain,
    ),
    left_port: Some(entry.key),
  })
}

///|
/// `BodierMap` stores entries in a `LinkedHashMap`: replacing a key changes
/// its value without moving its original row.
fn Parser::set_map_entry(
  self : Parser,
  entity_index : Int,
  entry : MapEntry,
) -> Unit {
  let entries = self.entities[entity_index].map_entries
  for index, current in entries {
    if current.key == entry.key {
      entries[index] = entry
      return
    }
  }
  entries.push(entry)
}

///|
fn Parser::consume_json_body_line(
  self : Parser,
  entity_index : Int,
  line : String,
) -> Unit raise @parse.ParseError {
  let delta = parse_brace_delta(line)
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
) -> Unit raise @parse.ParseError {
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
    self.set_map_entry(entity_index, syntax.entry)
    match syntax.arrow {
      Some(arrow) => self.add_map_link(entity, syntax.entry, arrow)
      None => ()
    }
    return
  }
  self.entities[entity_index].members.push(member_of(line))
}

///|
test "parse map value entry as one line grammar" {
  guard parse_map_entry_line("id => 42") is Some(syntax) else {
    fail("expected map value entry")
  }
  @test.assert_eq(syntax.entry.key, "id")
  @test.assert_eq(syntax.entry.value, Some("42"))
  @test.assert_eq(syntax.entry.link_target, None)
  @test.assert_eq(syntax.arrow, None)
}

///|
test "parse map link entry as one line grammar" {
  guard parse_map_entry_line("customer *--> Customer") is Some(syntax) else {
    fail("expected map link entry")
  }
  @test.assert_eq(syntax.entry.key, "customer")
  @test.assert_eq(syntax.entry.value, None)
  @test.assert_eq(syntax.entry.link_target, Some("Customer"))
  @test.assert_eq(syntax.arrow, Some("*-->"))
}

///|
test "reject invalid map entry line" {
  guard parse_map_entry_line("invalid line") is None else {
    fail("expected invalid map entry")
  }
}

///|
fn linked_map_arrow_parser() -> @talc.StringParser[(String, String)] {
  let arrow = @talc.char('*').bind(_ => {
    @talc.many_chars1(@talc.char('-')).bind(dashes => {
      @talc.char('_')
      .optional()
      .bind(underscore => {
        @talc.char('>').map(_ => {
          "*" + dashes + underscore.map_or("", _ => "_") + ">"
        })
      })
    })
  })
  let prefix_character = arrow
    .not_followed_by("map link arrow")
    .then(@talc.satisfy("map entry text", _ => true))
  @talc.many_chars(prefix_character).bind(prefix => {
    arrow.map(arrow => (prefix, arrow))
  })
}

///|
fn parse_brace_delta(line : String) -> Int {
  @parse.unquoted_delimiter_delta(line, '{', '}')
}
