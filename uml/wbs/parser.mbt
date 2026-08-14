///|
priv struct ItemLine {
  marker : String
  code : String?
  label : String?
  direction : Direction
  shape : NodeShape
  background_color : String?
  multiline : Bool
}

///|
priv struct ItemPrefix {
  code : String?
  direction : Direction?
  shape : NodeShape
  background_color : String?
  end : Int
}

///|
priv struct Parser {
  lines : Array[String]
  nodes : Array[WbsNode]
  links : Array[WbsLink]
  codes : Map[String, Int]
  style : @style.DocumentStyle
  style_properties : Array[WbsStyleProperty]
  mut first_marker : String?
  mut index : Int
}

///|
fn continuation_prefix(line : String) -> String? {
  let value = line.trim_end().to_owned()
  guard value.has_suffix("\\") else { return None }
  Some(value[:value.length() - 1].trim_end().to_owned())
}

///|
fn logical_wbs_lines(input : String) -> Array[String] {
  let lines = input.split("\n").map(StringView::to_owned).to_array()
  let mut index = 0
  while index < lines.length() {
    let mut logical = lines[index]
    let mut next = index + 1
    while next < lines.length() && continuation_prefix(logical) is Some(prefix) {
      logical = prefix + " " + lines[next].trim_start().to_owned()
      lines[next] = ""
      next += 1
    }
    lines[index] = logical
    index = next
  }
  lines
}

///|
fn Parser::new(input : String) -> Parser {
  {
    lines: logical_wbs_lines(@parse.preprocess(input)),
    nodes: [],
    links: [],
    codes: {},
    style: @style.DocumentStyle::empty(),
    style_properties: [],
    first_marker: None,
    index: 0,
  }
}

///|
fn is_marker_char(char : Char) -> Bool {
  char == '*' || char == '+' || char == '-'
}

///|
fn marker_end(cursor : @parse.Cursor) -> Int? {
  ignore(cursor.skip_while(char => char == ' ' || char == '\t'))
  let first = cursor.offset()
  ignore(cursor.skip_while(is_marker_char))
  if cursor.offset() > first {
    Some(cursor.offset())
  } else {
    None
  }
}

///|
fn marker_direction(marker : String) -> Direction {
  if marker.contains("-") {
    Left
  } else {
    Right
  }
}

///|
fn parse_modifiers(cursor : @parse.Cursor) -> (NodeShape, Direction?, Int) {
  let parse_direction = fn() -> Direction? {
    match cursor.peek() {
      Some('<') => {
        ignore(cursor.advance())
        Some(Direction::Left)
      }
      Some('>') => {
        ignore(cursor.advance())
        Some(Direction::Right)
      }
      _ => None
    }
  }
  let (shape, direction) = match cursor.peek() {
    Some('_') => {
      ignore(cursor.advance())
      (Boxless, parse_direction())
    }
    Some('<') | Some('>') => {
      let direction = parse_direction()
      let shape = if cursor.consume('_') { Boxless } else { Box }
      (shape, direction)
    }
    _ => (Box, None)
  }
  (shape, direction, cursor.offset())
}

///|
fn is_word_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_'
}

///|
fn parse_color(cursor : @parse.Cursor) -> String? {
  let checkpoint = cursor.offset()
  guard cursor.consume('[') && cursor.consume('#') else {
    ignore(cursor.restore(checkpoint))
    return None
  }
  let value = cursor.take_while(is_word_char)
  guard value.length() > 0 && cursor.consume(']') else {
    ignore(cursor.restore(checkpoint))
    return None
  }
  Some("#" + value)
}

///|
fn valid_code(code : String) -> Bool {
  code.length() > 0 && code.to_array().all(char => !char.is_whitespace())
}

///|
fn parse_parenthesized_code(cursor : @parse.Cursor) -> String? {
  let checkpoint = cursor.offset()
  guard cursor.consume('(') else { return None }
  let code = cursor.take_while(char => char != ')')
  guard cursor.consume(')') && valid_code(code) else {
    ignore(cursor.restore(checkpoint))
    return None
  }
  Some(code)
}

///|
fn parse_attributes(cursor : @parse.Cursor) -> (String?, String?, Int) {
  let mut color = None
  let mut code = None
  let mut count = 0
  while count < 2 {
    if color is None && parse_color(cursor) is Some(value) {
      color = Some(value)
      count += 1
      continue
    }
    if code is None && parse_parenthesized_code(cursor) is Some(value) {
      code = Some(value)
      count += 1
      continue
    }
    break
  }
  (color, code, cursor.offset())
}

///|
fn parse_prefix(
  cursor : @parse.Cursor,
  start : Int,
  attributes_first : Bool,
) -> ItemPrefix {
  ignore(cursor.restore(start))
  if attributes_first {
    let (background_color, code, _) = parse_attributes(cursor)
    let (shape, direction, end) = parse_modifiers(cursor)
    { code, direction, shape, background_color, end }
  } else {
    let (shape, direction, _) = parse_modifiers(cursor)
    let (background_color, code, end) = parse_attributes(cursor)
    { code, direction, shape, background_color, end }
  }
}

///|
fn quoted_alias(value : String) -> (String, String)? {
  let cursor = @parse.Cursor::new(value)
  guard cursor.peek() == Some('"') else { return None }
  let mut close = cursor.length() - 1
  while close > 0 {
    if cursor.char_at(close) == Some('"') {
      let suffix = cursor.slice(close + 1, cursor.length()).trim().to_owned()
      let words = @parse.syntax_words(suffix)
      if words.length() == 2 &&
        words[0].equal_ignore_ascii_case("as") &&
        valid_code(words[1]) {
        return Some((cursor.slice(1, close), words[1]))
      }
    }
    close -= 1
  }
  None
}

///|
fn item_from_prefix(
  cursor : @parse.Cursor,
  marker : String,
  prefix : ItemPrefix,
) -> ItemLine? {
  ignore(cursor.restore(prefix.end))
  let direction = prefix.direction.unwrap_or(marker_direction(marker))
  if cursor.is_eof() {
    let shape = match prefix.shape {
      Boxless => Pseudo
      Box => Box
      Pseudo => Pseudo
    }
    return Some({
      marker,
      code: prefix.code,
      label: None,
      direction,
      shape,
      background_color: prefix.background_color,
      multiline: false,
    })
  }
  if cursor.consume(':') {
    return Some({
      marker,
      code: prefix.code,
      label: Some(cursor.remaining()),
      direction,
      shape: prefix.shape,
      background_color: prefix.background_color,
      multiline: true,
    })
  }
  guard cursor.peek() is Some(char) && char.is_whitespace() else { return None }
  ignore(cursor.skip_while(char => char.is_whitespace()))
  guard !cursor.is_eof() else {
    let shape = match prefix.shape {
      Boxless => Pseudo
      Box => Box
      Pseudo => Pseudo
    }
    return Some({
      marker,
      code: prefix.code,
      label: None,
      direction,
      shape,
      background_color: prefix.background_color,
      multiline: false,
    })
  }
  let raw_label = cursor.remaining()
  let (label, code) = match prefix.code {
    None =>
      match quoted_alias(raw_label) {
        Some((label, code)) => (label, Some(code))
        None => (raw_label, None)
      }
    Some(code) => (raw_label, Some(code))
  }
  Some({
    marker,
    code,
    label: Some(label),
    direction,
    shape: prefix.shape,
    background_color: prefix.background_color,
    multiline: false,
  })
}

///|
fn parse_item_line(line : String) -> ItemLine? {
  let cursor = @parse.Cursor::new(line)
  guard marker_end(cursor) is Some(end) else { return None }
  let marker = cursor.slice(0, end)
  let modern = parse_prefix(cursor, end, false)
  match item_from_prefix(cursor, marker, modern) {
    Some(item) => Some(item)
    None => {
      let legacy = parse_prefix(cursor, end, true)
      item_from_prefix(cursor, marker, legacy)
    }
  }
}

///|
fn ending_stereotype(label : String) -> (String, String?) {
  let value = label.trim_end().to_owned()
  guard value.has_suffix(">>") else { return (value, None) }
  match value.rev_find("<<") {
    Some(start) =>
      (
        value[:start].trim_end().to_owned(),
        Some(value[start:].trim().to_owned()),
      )
    None => (value, None)
  }
}

///|
fn multiline_end(line : String) -> (String, String?)? {
  let value = line.trim().to_owned()
  if value.has_suffix(">>") && value.rev_find("<<") is Some(start) {
    guard start + 2 < value.length() - 2 else { return None }
    let before = value[:start].trim_end().to_owned()
    guard before.has_suffix(";") else { return None }
    return Some(
      (
        before[:before.length() - 1].trim_end().to_owned(),
        Some(value[start:].trim().to_owned()),
      ),
    )
  }
  guard value.has_suffix(";") else { return None }
  Some((value[:value.length() - 1].trim_end().to_owned(), None))
}

///|
fn Parser::complete_multiline(
  self : Parser,
  first : String,
) -> (String, String?) raise @parse.ParseError {
  let values = []
  let start = self.index
  let mut current = first.trim().to_owned()
  while true {
    match multiline_end(current) {
      Some((last, stereotype)) => {
        values.push(last)
        return (values.join("\n"), stereotype)
      }
      None => values.push(current)
    }
    self.index += 1
    guard self.index < self.lines.length() else {
      raise SyntaxError(start + 1, "unclosed WBS item")
    }
    current = @parse.strip_line_comment_preserving_indent(
        self.lines[self.index],
      )
      .trim()
      .to_owned()
  }
  raise SyntaxError(start + 1, "unclosed WBS item")
}

///|
fn Parser::smart_level(
  self : Parser,
  marker : String,
) -> Int raise @parse.ParseError {
  guard self.first_marker is Some(first) else {
    self.first_marker = Some(marker)
    return 0
  }
  let normalized = marker.replace(old="\t", new=" ")
  if !normalized.contains(" ") {
    return normalized.length() - 1
  }
  if normalized.has_suffix(first) {
    return normalized.length() - first.length()
  }
  if normalized.trim().length() == 1 {
    return normalized.length() - 1
  }
  if normalized.has_prefix(first) {
    return normalized.length() - first.length()
  }
  raise SyntaxError(self.index + 1, "unsupported WBS indentation")
}

///|
fn Parser::parent_for(
  self : Parser,
  level : Int,
) -> Int raise @parse.ParseError {
  let last_index = self.nodes.length() - 1
  let last = self.nodes[last_index]
  guard level <= last.level + 1 else {
    raise SyntaxError(self.index + 1, "Bad tree structure")
  }
  if level == last.level + 1 {
    return last_index
  }
  let mut parent = Some(last_index)
  let mut remaining = last.level - level + 1
  while remaining > 0 {
    guard parent is Some(index) else {
      raise SyntaxError(self.index + 1, "Bad tree structure")
    }
    parent = self.nodes[index].parent
    remaining -= 1
  }
  guard parent is Some(index) else {
    raise SyntaxError(self.index + 1, "Bad tree structure")
  }
  index
}

///|
fn Parser::add_item(
  self : Parser,
  item : ItemLine,
) -> Unit raise @parse.ParseError {
  let level = self.smart_level(item.marker)
  guard item.label is Some(_) || item.shape is Pseudo else {
    raise SyntaxError(self.index + 1, "Missing label for WBS node.")
  }
  if self.nodes.is_empty() {
    let (label, stereotype) = if item.multiline {
      self.complete_multiline(item.label.unwrap_or(""))
    } else {
      ending_stereotype(item.label.unwrap_or(""))
    }
    self.nodes.push({
      code: item.code,
      label,
      level,
      direction: item.direction,
      shape: item.shape,
      background_color: item.background_color,
      stereotype,
      parent: None,
    })
    return
  }
  guard level > 0 else {
    raise SyntaxError(
      self.index + 1,
      "WBS diagram only accepts one root first declared.",
    )
  }
  let parent = self.parent_for(level)
  let (label, stereotype) = if item.multiline {
    self.complete_multiline(item.label.unwrap_or(""))
  } else {
    ending_stereotype(item.label.unwrap_or(""))
  }
  let node_index = self.nodes.length()
  self.nodes.push({
    code: item.code,
    label,
    level,
    direction: item.direction,
    shape: item.shape,
    background_color: item.background_color,
    stereotype,
    parent: Some(parent),
  })
  if item.code is Some(code) {
    self.codes[code] = node_index
  }
}

///|
fn parse_link_color(cursor : @parse.Cursor) -> String? {
  let checkpoint = cursor.offset()
  guard cursor.consume('#') else { return None }
  let value = cursor.take_while(is_word_char)
  guard value.length() > 0 else {
    ignore(cursor.restore(checkpoint))
    return None
  }
  Some("#" + value)
}

///|
fn Parser::parse_link(
  self : Parser,
  line : String,
) -> Bool raise @parse.ParseError {
  let cursor = @parse.Cursor::new(line)
  while cursor.peek() is Some(char) && char != '>' {
    ignore(cursor.advance())
  }
  guard cursor.peek() == Some('>') else { return false }
  let arrow_end = cursor.offset()
  let mut arrow_start = arrow_end
  while arrow_start > 0 &&
        (
          cursor.char_at(arrow_start - 1) == Some('.') ||
          cursor.char_at(arrow_start - 1) == Some('-')
        ) {
    arrow_start -= 1
  }
  guard arrow_start < arrow_end else { return false }
  let source_code = cursor.slice(0, arrow_start).trim().to_owned()
  guard valid_code(source_code) else { return false }
  ignore(cursor.restore(arrow_end + 1))
  ignore(cursor.skip_while(char => char.is_whitespace()))
  let target_code = cursor.take_while(char => {
    !char.is_whitespace() && char != '#' && char != '<' && char != ':'
  })
  guard valid_code(target_code) else { return false }
  ignore(cursor.skip_while(char => char.is_whitespace()))
  let mut color = None
  let mut stereotype = None
  let mut label = None
  if parse_link_color(cursor) is Some(value) {
    color = Some(value)
    ignore(cursor.skip_while(char => char.is_whitespace()))
  }
  if cursor.peek() == Some('<') && cursor.peek_ahead(1) == Some('<') {
    let start = cursor.offset()
    ignore(cursor.consume_literal("<<"))
    let content_start = cursor.offset()
    while !cursor.is_eof() &&
          !(cursor.peek() == Some('>') && cursor.peek_ahead(1) == Some('>')) {
      ignore(cursor.advance())
    }
    guard cursor.offset() > content_start && cursor.consume_literal(">>") else {
      return false
    }
    stereotype = Some(cursor.slice(start, cursor.offset()))
    ignore(cursor.skip_while(char => char.is_whitespace()))
  }
  if cursor.consume(':') {
    label = Some(cursor.remaining().trim().to_owned())
    ignore(cursor.restore(cursor.length()))
  }
  ignore(cursor.skip_while(char => char.is_whitespace()))
  guard cursor.is_eof() else { return false }
  guard self.codes.get(source_code) is Some(source) else {
    raise SyntaxError(self.index + 1, "No such node \{source_code}")
  }
  guard self.codes.get(target_code) is Some(target) else {
    raise SyntaxError(self.index + 1, "No such node \{target_code}")
  }
  self.links.push({ source, target, color, stereotype, label })
  true
}

///|
fn Parser::consume_style_block(self : Parser) -> Unit raise @parse.ParseError {
  let start = self.index
  let selectors = []
  self.index += 1
  while self.index < self.lines.length() {
    let line = @parse.strip_line_comment(self.lines[self.index])
      .trim()
      .to_owned()
    if line.equal_ignore_ascii_case("</style>") {
      guard selectors.is_empty() else {
        raise SyntaxError(self.index + 1, "unclosed WBS style selector")
      }
      return
    }
    if line.length() == 0 {
      self.index += 1
      continue
    }
    if line.has_suffix("{") {
      selectors.push(line[:line.length() - 1].trim().to_owned())
      self.index += 1
      continue
    }
    if line == "}" {
      guard selectors.pop() is Some(_) else {
        raise SyntaxError(self.index + 1, "unexpected WBS style closing brace")
      }
      self.index += 1
      continue
    }
    let words = @parse.syntax_words(line)
    guard !selectors.is_empty() && words.length() >= 2 else {
      raise SyntaxError(self.index + 1, "invalid WBS style property")
    }
    self.style_properties.push({
      selector: selectors.join(" "),
      name: words[0],
      value: words[1:].to_owned().join(" "),
    })
    self.index += 1
  }
  raise SyntaxError(start + 1, "unclosed WBS style block")
}

///|
fn Parser::consume_text_block(
  self : Parser,
  kind : String,
) -> Unit raise @parse.ParseError {
  let start = self.index
  let values = []
  self.index += 1
  while self.index < self.lines.length() {
    let line = @parse.strip_line_comment_preserving_indent(
        self.lines[self.index],
      )
      .trim()
      .to_owned()
    if line.equal_ignore_ascii_case("end \{kind}") ||
      line.equal_ignore_ascii_case("end\{kind}") {
      self.style.apply(@style.TextBlock(kind, values.join("\n")))
      return
    }
    values.push(line)
    self.index += 1
  }
  raise SyntaxError(start + 1, "unclosed \{kind}")
}

///|
fn Parser::parse_line(self : Parser) -> Unit raise @parse.ParseError {
  let line = @parse.strip_line_comment_preserving_indent(self.lines[self.index])
  let trimmed = line.trim().to_owned()
  let lower = trimmed.to_lower()
  if trimmed.length() == 0 ||
    lower == "@startwbs" ||
    lower == "@endwbs" ||
    lower == "@startuml" ||
    lower == "@enduml" ||
    @style.is_preprocessor_directive(trimmed) {
    return
  }
  if lower == "skinparam {" {
    self.index += 1
    let closed = @style.consume_skinparam_body(
      fn() {
        guard self.index < self.lines.length() else { return None }
        let next = @parse.strip_line_comment(self.lines[self.index])
        self.index += 1
        Some(next)
      },
      fn(directive) { self.style.apply(directive) },
    )
    guard closed else {
      raise SyntaxError(self.lines.length(), "unclosed skinparam")
    }
    self.index -= 1
    return
  }
  if lower == "<style>" {
    self.consume_style_block()
    return
  }
  if lower == "title" ||
    lower == "caption" ||
    lower == "header" ||
    lower == "footer" ||
    lower == "legend" ||
    lower == "legend left" ||
    lower == "legend right" ||
    lower == "legend top" ||
    lower == "legend bottom" {
    let kind = if lower.has_prefix("legend") { "legend" } else { lower }
    self.consume_text_block(kind)
    return
  }
  if @style.parse_style_directive(trimmed) is Some(directive) {
    self.style.apply(directive)
    return
  }
  if lower.has_prefix("skinparam ") {
    return
  }
  if parse_item_line(line) is Some(item) {
    self.add_item(item)
    return
  }
  if self.parse_link(trimmed) {
    return
  }
  raise SyntaxError(self.index + 1, "unsupported WBS command")
}

///|
/// Parse the command family registered by PlantUML's `WBSDiagramFactory`.
/// Both modern and legacy modifier order are accepted, together with coded
/// nodes, multiline labels, pseudo nodes, and non-tree links.
pub fn parse(input : String) -> WbsDiagram raise @parse.ParseError {
  let parser = Parser::new(input)
  while parser.index < parser.lines.length() {
    parser.parse_line()
    parser.index += 1
  }
  guard !parser.nodes.is_empty() else {
    raise SyntaxError(parser.lines.length().max(1), "Empty description")
  }
  {
    nodes: parser.nodes,
    links: parser.links,
    style: parser.style,
    style_properties: parser.style_properties,
  }
}
