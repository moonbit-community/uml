///|
priv struct MapEntryLineSyntax {
  entry : @entity.MapEntry
  arrow : String?
}

///|
priv enum ParsedMapEntrySyntax {
  ParsedMapValue(key~ : String, value~ : String)
  ParsedMapLink(key~ : String, arrow~ : String, target~ : String)
}

///|
fn map_value_entry(cursor : @parse.Cursor) -> ParsedMapEntrySyntax? {
  let start = cursor.offset()
  let key = cursor.take_while(_ => !cursor.starts_with_literal("=>"))
  guard key.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume_literal("=>") else {
    ignore(cursor.restore(start))
    return None
  }
  let value = cursor.take_while(_ => true).trim().to_owned()
  let key = key.trim().to_owned()
  Some(ParsedMapValue(key~, value~))
}

///|
fn linked_map_arrow(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('*') else { return None }
  let dashes = cursor.take_while(char => char == '-')
  guard dashes.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  let underscore = cursor.consume('_')
  guard cursor.consume('>') else {
    ignore(cursor.restore(start))
    return None
  }
  Some("*" + dashes + (if underscore { "_" } else { "" }) + ">")
}

///|
fn starts_linked_arrow(cursor : @parse.Cursor) -> Bool {
  let offset = cursor.offset()
  let matched = linked_map_arrow(cursor) is Some(_)
  ignore(cursor.restore(offset))
  matched
}

///|
fn linked_map_arrow_parser(cursor : @parse.Cursor) -> (String, String)? {
  let start = cursor.offset()
  let prefix = cursor.take_while(_ => !starts_linked_arrow(cursor))
  guard linked_map_arrow(cursor) is Some(arrow) else {
    ignore(cursor.restore(start))
    return None
  }
  Some((prefix, arrow))
}

///|
fn map_link_entry(cursor : @parse.Cursor) -> ParsedMapEntrySyntax? {
  let start = cursor.offset()
  guard linked_map_arrow_parser(cursor) is Some((key, arrow)) else {
    return None
  }
  let key = key.trim().to_owned()
  guard key.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  let target = @parse.unquote_identifier(
    cursor.take_while(_ => true).trim().to_owned(),
  )
  if target.length() > 0 {
    Some(ParsedMapLink(key~, arrow~, target~))
  } else {
    ignore(cursor.restore(start))
    None
  }
}

///|
fn map_entry_line(cursor : @parse.Cursor) -> ParsedMapEntrySyntax? {
  let start = cursor.offset()
  if map_value_entry(cursor) is Some(value) {
    return Some(value)
  }
  ignore(cursor.restore(start))
  guard map_link_entry(cursor) is Some(value) else { return None }
  Some(value)
}

///|
fn parse_map_entry_line(line : String) -> MapEntryLineSyntax? {
  let cursor = @parse.Cursor::new(line)
  match map_entry_line(cursor) {
    Some(ParsedMapValue(key~, value~)) =>
      Some({
        entry: { key, value: Some(value), link_target: None, raw: line, },
        arrow: None,
      })
    Some(ParsedMapLink(key~, arrow~, target~)) =>
      Some({
        entry: { key, value: None, link_target: Some(target), raw: line, },
        arrow: Some(arrow),
      })
    None => None
  }
}

///|
priv struct MultilineElementHeader {
  declaration : @entity.Declaration
  first_line : String
  terminator : Char
}

///|
fn EntityParser::consume_multiline_element(
  self : EntityParser,
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
          { ..header.declaration, display: display.to_string(), },
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
  declaration : @entity.Declaration
  data : String
}

///|
fn valid_json(source : String) -> Bool {
  try {
    ignore(@bodierjson.parse_json_tree(source))
    true
  } catch {
    _ => false
  }
}

///|
fn EntityParser::add_single_line_json(
  self : EntityParser,
  value : JsonSingleDeclaration,
) -> Unit raise @parse.ParseError {
  let qualified_code = self.qualify(value.declaration.code)
  guard !self.has_entity(qualified_code) else {
    self.raise_parse_error("JSON already exists: \{value.declaration.code}")
  }
  self.add_entity(value.declaration, false)
  let tree = @bodierjson.parse_json_tree(value.data) catch { _ => return }
  if self.entity_index(qualified_code) is Some(index) {
    self.entities[index] = {
      ..self.entities[index],
      json_data: Some(value.data),
      json_tree: Some(tree),
    }
  }
}

///|
fn EntityParser::add_map_link(
  self : EntityParser,
  source : @entity.Entity,
  entry : @entity.MapEntry,
  arrow : String,
) -> Unit raise @parse.ParseError {
  guard entry.link_target is Some(target) else { return }
  let resolved = self.resolve(target)
  guard self.has_entity(resolved) else {
    self.raise_parse_error("No such entity " + target)
  }
  self.relations.push({
    ..@entity.Relation::new(
      source.qualified_code,
      resolved,
      @entity.RelationKind::Association,
      arrow,
      @entity.RelationEnd::Arrow,
      @entity.RelationEnd::Plain,
    ),
    left_port: Some(entry.key),
  })
}

///|
/// `BodierMap` stores entries in a `LinkedHashMap`: replacing a key changes
/// its value without moving its original row.
fn EntityParser::set_map_entry(
  self : EntityParser,
  entity_index : Int,
  entry : @entity.MapEntry,
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
fn EntityParser::consume_json_body_line(
  self : EntityParser,
  entity_index : Int,
  line : String,
) -> Unit raise @parse.ParseError {
  let delta = parse_brace_delta(line)
  if self.body_depth + delta <= 0 {
    let body = self.entities[entity_index].json_data.unwrap_or("")
    let wrapped = "{" + body + "}"
    match complete_json_source(wrapped, body) {
      Some((source, tree)) => {
        self.entities[entity_index] = {
          ..self.entities[entity_index],
          json_data: Some(source),
          json_tree: Some(tree),
        }
        self.finish_entity()
        return
      }
      None => self.raise_parse_error("bad JSON data")
    }
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
/// PlantUML first tries the body wrapped in braces, then the bare body. The
/// stored source and its ordered tree come from the first successful parse.
fn complete_json_source(
  wrapped : String,
  bare : String,
) -> (String, @bodierjson.JsonNode)? {
  let wrapped_tree = Some(@bodierjson.parse_json_tree(wrapped)) catch { _ => None }
  wrapped_tree.map_or(
    Some((bare, @bodierjson.parse_json_tree(bare))) catch {
      _ => None
    },
    tree => Some((wrapped, tree)),
  )
}

///|
fn EntityParser::consume_entity_body_line(
  self : EntityParser,
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
    if syntax.arrow is Some(arrow) {
      self.add_map_link(entity, syntax.entry, arrow)
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
fn parse_brace_delta(line : String) -> Int {
  @parse.unquoted_delimiter_delta(line, '{', '}')
}
