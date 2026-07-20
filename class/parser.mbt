///|
priv struct Parser {
  lines : Array[String]
  mut index : Int
  package_stack : Array[String]
  entities : Array[Entity]
  relations : Array[Relation]
  packages : Array[Package]
  notes : Array[Note]
  hidden : Map[String, Bool]
  style : @core.DocumentStyle
  mut current_entity : Int?
}

///|
fn Parser::new(input : String) -> Parser {
  {
    lines: @core.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array(),
    index: 0,
    package_stack: [],
    entities: [],
    relations: [],
    packages: [],
    notes: [],
    hidden: Map([]),
    style: @core.DocumentStyle::empty(),
    current_entity: None,
  }
}

///|
fn Parser::current_package(self : Parser) -> String {
  self.package_stack.join(".")
}

///|
fn Parser::line_number(self : Parser) -> Int {
  @core.line_span(self.index + 1).line
}

///|
fn Parser::diagnostic(self : Parser, message : String) -> @core.ParseDiagnostic {
  @core.diagnostic_at_line(self.line_number(), message)
}

///|
fn Parser::raise_parse_error(
  self : Parser,
  message : String,
) -> Unit raise ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}

///|
fn strip_comment(line : String) -> String {
  let mut quoted = false
  let result = StringBuilder()
  for char in line {
    if char == '"' {
      quoted = !quoted
    }
    if char == '\'' && !quoted {
      break
    }
    result.write_char(char)
  }
  result.to_string().trim().to_owned()
}

///|
fn words(line : String) -> Array[String] {
  line
  .split(" ")
  .map(item => item.trim().to_owned())
  .filter(item => item.length() > 0)
  .to_array()
}

///|
fn normalize_name(raw : String) -> String {
  let value = raw.trim()
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value.to_owned()
  }
}

///|
fn declaration_kind(word : String) -> EntityKind? {
  match word.to_lower() {
    "class" => Some(Class)
    "interface" => Some(Interface)
    "enum" => Some(Enum)
    "annotation" => Some(Annotation)
    "object" => Some(Object)
    "entity" => Some(Entity)
    "protocol" => Some(Protocol)
    "struct" => Some(Struct)
    "circle" => Some(Circle)
    "usecase" => Some(Usecase)
    "exception" => Some(Exception)
    "metaclass" => Some(Metaclass)
    "stereotype" => Some(Stereotype)
    "dataclass" => Some(Dataclass)
    "record" => Some(Record)
    "map" => Some(Map)
    "diamond" => Some(Diamond)
    "component" => Some(Component)
    "actor" => Some(Actor)
    "database" => Some(Database)
    "queue" => Some(Queue)
    "folder" => Some(Folder)
    "file" => Some(File)
    "node" => Some(Node)
    "cloud" => Some(Cloud)
    "state" => Some(State)
    _ => None
  }
}

///|
fn leading_visibility(line : String) -> (Visibility, String) {
  let chars = line.to_array()
  guard chars.length() > 0 else { (Unknown, line) }
  let visibility = match chars[0] {
    '+' => Public
    '-' => Private
    '#' => Protected
    '~' => Package
    _ => return (Unknown, line)
  }
  (visibility, line[1:].trim().to_owned())
}

///|
fn extract_stereotype(body : String) -> (String, String?) {
  guard find_substring(body, "<<") is Some(start) else { (body, None) }
  let chars = body.to_array()
  for end in (start + 2)..<(chars.length() - 1) {
    if chars[end] == '>' && chars[end + 1] == '>' {
      return (
        body[0:start].trim().to_owned(),
        @core.normalize_stereotype(body[start:end + 2].to_owned()),
      )
    }
  }
  (body, None)
}

///|
fn extract_shared_url(body : String) -> (String, String?) {
  guard find_substring(body, "[[") is Some(start) else { (body, None) }
  match @core.parse_url_target(body[start:].to_owned()) {
    Some(url) => (body[0:start].trim().to_owned(), Some(url.target))
    None => (body, None)
  }
}

///|
fn declaration_color(body : String) -> String? {
  guard find_substring(body, " #") is Some(start) else { return None }
  let suffix = body[start + 2:].trim().to_owned()
  match find_substring(suffix, " ") {
    Some(end) => Some(suffix[0:end].to_owned())
    None => Some(suffix)
  }
}

///|
fn extract_generic(body : String) -> (String, String?) {
  guard find_substring(body, "<") is Some(start) else { (body, None) }
  let chars = body.to_array()
  for end in (start + 1)..<chars.length() {
    if chars[end] == '>' {
      return (
        body[0:start].trim().to_owned(),
        Some(body[start + 1:end].to_owned()),
      )
    }
  }
  (body, None)
}

///|
fn tail_target(body : String, keyword : String) -> String? {
  guard find_substring(body.to_lower(), keyword) is Some(start) else {
    return None
  }
  let target = body[start + keyword.length():].trim()
  let target = match find_substring(target.to_owned(), " ") {
    Some(end) => target[0:end].to_owned()
    None => target.to_owned()
  }
  let target = normalize_name(target)
  if target.length() == 0 {
    None
  } else {
    Some(target)
  }
}

///|
fn parse_declaration(line : String) -> Declaration? {
  let (visibility, line) = leading_visibility(line)
  if line.has_prefix("()") {
    let body = line[2:].trim().to_owned()
    let (display, code) = match body.split(" as ").to_array() {
      [name, alternate] =>
        (normalize_name(name.to_owned()), normalize_name(alternate.to_owned()))
      _ => {
        let name = normalize_name(body)
        (name, name)
      }
    }
    guard code.length() > 0 else { return None }
    return Some({
      kind: Interface,
      code,
      display,
      visibility,
      is_static: false,
      generic: None,
      stereotype: None,
      extends: None,
      implements: None,
      url: None,
      color: None,
    })
  }
  let mut parts = words(line)
  guard parts.length() > 1 else { return None }
  let mut is_static = false
  let kind = if parts[0].to_lower() == "static" && parts.length() > 2 {
    is_static = true
    parts = parts[1:].to_owned()
    guard declaration_kind(parts[0]) is Some(kind) else { return None }
    kind
  } else if parts[0].to_lower() == "abstract" && parts.length() > 1 {
    if parts.length() > 2 && declaration_kind(parts[1]) is Some(_) {
      parts = parts[1:].to_owned()
    }
    AbstractClass
  } else {
    guard declaration_kind(parts[0]) is Some(kind) else { return None }
    kind
  }
  let mut body = parts[1:].join(" ").trim().to_owned()
  if body.has_suffix("{}") {
    body = body[0:body.length() - 2].trim().to_owned()
  } else if body.has_suffix("{") {
    body = body[0:body.length() - 1].trim().to_owned()
  }
  let extends = tail_target(body, "extends ")
  let implements = tail_target(body, "implements ")
  let color = declaration_color(body)
  for keyword in [" extends ", " implements ", " #", " ##"] {
    if find_substring(body, keyword) is Some(index) {
      body = body[0:index].trim().to_owned()
    }
  }
  let (body, stereotype) = extract_stereotype(body)
  let (body, url) = extract_shared_url(body)
  let (body, generic) = extract_generic(body)
  let (display, code) = match body.split(" as ").to_array() {
    [name, alternate] => {
      let name = name.trim()
      let alternate = alternate.trim()
      if alternate.has_prefix("\"") && alternate.has_suffix("\"") {
        (normalize_name(alternate.to_owned()), normalize_name(name.to_owned()))
      } else {
        (normalize_name(name.to_owned()), normalize_name(alternate.to_owned()))
      }
    }
    _ => {
      let name = normalize_name(body)
      (name, name)
    }
  }
  guard code.length() > 0 else { return None }
  Some({
    kind,
    code,
    display,
    visibility,
    is_static,
    generic,
    stereotype,
    extends,
    implements,
    url,
    color,
  })
}

///|
fn declaration_opens_body(line : String) -> Bool {
  line.trim().has_suffix("{") && !line.trim().has_suffix("{}")
}

///|
fn visibility_of(raw : String) -> Visibility {
  match raw.to_array() {
    [] => Unknown
    [first, ..] =>
      match first {
        '+' => Public
        '-' => Private
        '#' => Protected
        '~' => Package
        _ => Unknown
      }
  }
}

///|
fn member_of(line : String) -> Member {
  let raw = line.trim().to_owned()
  let is_separator = raw == "--" ||
    raw == ".." ||
    (raw.has_prefix("==") && raw.has_suffix("=="))
  {
    raw,
    visibility: visibility_of(raw),
    is_method: raw.contains("(") && raw.contains(")"),
    is_static: raw.contains("{static}") || raw.contains("static "),
    is_abstract: raw.contains("{abstract}") || raw.contains("abstract "),
    is_separator,
  }
}

///|
fn Parser::add_entity(
  self : Parser,
  declaration : Declaration,
  open : Bool,
) -> Unit {
  for index, entity in self.entities {
    if entity.code == declaration.code {
      self.entities[index] = {
        ..entity,
        display: declaration.display,
        kind: declaration.kind,
        scope: self.current_package(),
        visibility: declaration.visibility,
        is_static: declaration.is_static,
        generic: declaration.generic,
        stereotype: declaration.stereotype,
        url: declaration.url,
        color: declaration.color,
      }
      if open {
        self.current_entity = Some(index)
      }
      return
    }
  }
  self.entities.push({
    code: declaration.code,
    display: declaration.display,
    kind: declaration.kind,
    scope: self.current_package(),
    visibility: declaration.visibility,
    is_static: declaration.is_static,
    generic: declaration.generic,
    stereotype: declaration.stereotype,
    is_hidden: self.hidden.get(declaration.code).unwrap_or(false),
    url: declaration.url,
    color: declaration.color,
    members: [],
  })
  if open {
    self.current_entity = Some(self.entities.length() - 1)
  }
}

///|
fn Parser::ensure_entity(self : Parser, code : String) -> Unit {
  guard !self.entities.any(entity => entity.code == code) else { return }
  self.entities.push({
    code,
    display: code,
    kind: Class,
    scope: self.current_package(),
    visibility: Unknown,
    is_static: false,
    generic: None,
    stereotype: None,
    is_hidden: self.hidden.get(code).unwrap_or(false),
    url: None,
    color: None,
    members: [],
  })
}

///|
fn Parser::set_entity_hidden(
  self : Parser,
  code : String,
  hidden : Bool,
) -> Unit {
  self.hidden[code] = hidden
  for index, entity in self.entities {
    if entity.code == code {
      self.entities[index] = { ..entity, is_hidden: hidden }
      return
    }
  }
}

///|
fn Parser::set_entity_stereotype(
  self : Parser,
  code : String,
  stereotype : String,
) -> Unit {
  self.ensure_entity(code)
  for index, entity in self.entities {
    if entity.code == code {
      self.entities[index] = { ..entity, stereotype: Some(stereotype) }
      return
    }
  }
}

///|
fn stereotype_assignment(line : String) -> (String, String)? {
  guard find_substring(line, " <<") is Some(start) else { return None }
  let code = normalize_name(line[0:start].trim().to_owned())
  let stereotype = line[start + 1:].trim().to_owned()
  guard code.length() > 0 &&
    @core.normalize_stereotype(stereotype) is Some(normalized) else {
    return None
  }
  Some((code, normalized))
}

///|
fn visibility_command(line : String) -> (String, Bool)? {
  let tokens = words(line)
  guard tokens.length() == 2 else { return None }
  let hidden = match tokens[0].to_lower() {
    "hide" => true
    "show" => false
    "remove" => true
    "restore" => false
    _ => return None
  }
  let code = normalize_name(tokens[1])
  if code.length() == 0 {
    None
  } else {
    Some((code, hidden))
  }
}

///|
fn Parser::add_member_to(self : Parser, code : String, entry : Member) -> Unit {
  self.ensure_entity(code)
  for index, entity in self.entities {
    if entity.code == code {
      self.entities[index].members.push(entry)
      return
    }
  }
}

///|
fn parse_external_member(line : String) -> (String, Member)? {
  guard find_substring(line, ":") is Some(separator) else { return None }
  let target = line[0:separator].trim().to_owned()
  let body = line[separator + 1:].trim().to_owned()
  guard target.length() > 0 && body.length() > 0 else { return None }
  guard !target.contains("-") &&
    !target.contains(".") &&
    !target.contains("<") &&
    !target.contains("[[") else {
    return None
  }
  Some((normalize_name(target), member_of(body)))
}

///|
fn package_name(line : String) -> String? {
  let prefix = if line.has_prefix("package ") {
    8
  } else if line.has_prefix("namespace ") {
    10
  } else {
    return None
  }
  let value = line[prefix:].trim()
  guard value.length() > 0 else { return None }
  let value = if value.has_suffix("{") {
    value[0:value.length() - 1].trim()
  } else {
    value
  }
  Some(normalize_name(value.to_owned()))
}

///|
fn find_substring(haystack : String, needle : String) -> Int? {
  let source = haystack.to_array()
  let target = needle.to_array()
  guard target.length() <= source.length() else { return None }
  for start in 0..<(source.length() - target.length() + 1) {
    let mut matches = true
    for offset in 0..<target.length() {
      if source[start + offset] != target[offset] {
        matches = false
      }
    }
    if matches {
      return Some(start)
    }
  }
  None
}

///|
fn relation_arrow(line : String) -> (String, Int, Int)? {
  let arrows = [
    "..|>", "--|>", "<|..", "<|--", "*--", "o--", "--*", "--o", "..>", "<..", "-->",
    "<--", "->", "<-", "--", "..",
  ]
  for arrow in arrows {
    if find_substring(line, arrow) is Some(index) {
      return Some((arrow, index, index + arrow.length()))
    }
  }
  None
}

///|
fn relation_kind(arrow : String) -> RelationKind {
  if arrow.contains("|>") {
    if arrow.contains("..") {
      Realization
    } else {
      Extension
    }
  } else if arrow.contains("..") {
    Dependency
  } else if arrow.contains("o") {
    Aggregation
  } else if arrow.contains("*") {
    Composition
  } else {
    Association
  }
}

///|
fn note_position(word : String) -> NotePosition? {
  match word.to_lower() {
    "left" => Some(Left)
    "right" => Some(Right)
    "top" => Some(Top)
    "bottom" => Some(Bottom)
    _ => None
  }
}

///|
fn parse_single_line_note(line : String) -> Note? {
  let tokens = words(line)
  guard tokens.length() >= 4 && tokens[0].to_lower() == "note" else {
    return None
  }
  guard note_position(tokens[1]) is Some(position) else { return None }
  guard tokens[2].to_lower() == "of" else { return None }
  let rest = tokens[3:].join(" ")
  guard find_substring(rest, ":") is Some(separator) else { return None }
  let target = normalize_name(rest[0:separator].trim().to_owned())
  let text = rest[separator + 1:].trim().to_owned()
  guard target.length() > 0 else { return None }
  Some({ target, position, text })
}

///|
fn parse_multiline_note_header(line : String) -> (String, NotePosition)? {
  let tokens = words(line)
  guard tokens.length() == 4 && tokens[0].to_lower() == "note" else {
    return None
  }
  guard note_position(tokens[1]) is Some(position) else { return None }
  guard tokens[2].to_lower() == "of" else { return None }
  let target = normalize_name(tokens[3])
  if target.length() == 0 {
    None
  } else {
    Some((target, position))
  }
}

///|
fn Parser::consume_multiline_note(
  self : Parser,
  target : String,
  position : NotePosition,
) -> Unit raise ParseError {
  let text = StringBuilder()
  let mut first = true
  self.index += 1
  while self.index < self.lines.length() {
    let line = self.lines[self.index]
    if strip_comment(line).to_lower() == "end note" {
      self.notes.push({ target, position, text: text.to_string() })
      return
    }
    if !first {
      text.write_char('\n')
    }
    text.write_string(line)
    first = false
    self.index += 1
  }
  self.raise_parse_error("unclosed note")
}

///|
fn text_block_header(line : String) -> String? {
  let keyword = line.to_lower()
  match keyword {
    "title" => Some("title")
    "legend" => Some("legend")
    "header" => Some("header")
    "footer" => Some("footer")
    "caption" => Some("caption")
    _ => None
  }
}

///|
fn Parser::consume_text_block(
  self : Parser,
  keyword : String,
) -> Unit raise ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    if strip_comment(self.lines[self.index]).to_lower() == "end \{keyword}" {
      return
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed \{keyword}")
}

///|
fn Parser::consume_braced_block(
  self : Parser,
  kind : String,
) -> Unit raise ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    if strip_comment(self.lines[self.index]) == "}" {
      return
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed \{kind}")
}

///|
fn Parser::consume_skinparam_block(self : Parser) -> Unit raise ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    let property = strip_comment(self.lines[self.index])
    if property == "}" {
      return
    }
    match @core.parse_style_property(property) {
      Some(directive) => self.style.apply(directive)
      None => ()
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed skinparam")
}

///|
fn quoted_end(raw : Array[Char], start : Int) -> Int? {
  for index in (start + 1)..<raw.length() {
    if raw[index] == '"' {
      return Some(index)
    }
  }
  None
}

///|
fn endpoint(raw : String, cardinality_before : Bool) -> (String, String?) {
  let chars = raw.to_array()
  let mut quote_start = None
  for index in 0..<chars.length() {
    if chars[index] == '"' {
      quote_start = Some(index)
      break
    }
  }
  match quote_start {
    Some(start) =>
      match quoted_end(chars, start) {
        Some(end) => {
          let cardinality = raw[start + 1:end].to_owned()
          let before = raw[0:start].trim().to_owned()
          let after = raw[end + 1:].trim().to_owned()
          let code = if cardinality_before { before } else { after }
          (normalize_name(code), Some(cardinality))
        }
        None => (normalize_name(raw), None)
      }
    None => (normalize_name(raw), None)
  }
}

///|
fn split_role(raw : String, role_after_entity : Bool) -> (String, String?) {
  guard find_substring(raw, "/") is Some(separator) else { (raw, None) }
  let before = raw[0:separator].trim().to_owned()
  let after = raw[separator + 1:].trim()
  if role_after_entity {
    let role = after.to_owned()
    if before.length() == 0 || role.length() == 0 {
      (raw, None)
    } else {
      (before, Some(role))
    }
  } else {
    let parts = words(after.to_owned())
    guard parts.length() >= 2 else { return (raw, None) }
    (parts[1:].join(" "), Some(parts[0]))
  }
}

///|
fn split_qualifier(
  raw : String,
  qualifier_after_entity : Bool,
) -> (String, String?) {
  guard find_substring(raw, "[") is Some(start) else { (raw, None) }
  let chars = raw.to_array()
  let mut end = None
  for index in (start + 1)..<chars.length() {
    if chars[index] == ']' {
      end = Some(index)
      break
    }
  }
  match end {
    Some(end) => {
      let qualifier = raw[start + 1:end].trim().to_owned()
      let before = raw[0:start].trim().to_owned()
      let after = raw[end + 1:].trim().to_owned()
      let entity = if qualifier_after_entity { before } else { after }
      if entity.length() == 0 || qualifier.length() == 0 {
        (raw, None)
      } else {
        (entity, Some(qualifier))
      }
    }
    None => (raw, None)
  }
}

///|
fn Parser::parse_relation(self : Parser, line : String) -> Bool {
  guard relation_arrow(line) is Some((arrow, start, end)) else { false }
  let mut left_raw = line[0:start].trim().to_owned()
  for direction in ["-left", "-right", "-up", "-down", "-le", "-ri", "-do"] {
    if left_raw.has_suffix(direction) {
      left_raw = left_raw[0:left_raw.length() - direction.length()]
        .trim()
        .to_owned()
    }
  }
  let right_raw = line[end:].trim()
  guard left_raw.length() > 0 && right_raw.length() > 0 else { false }
  let label_index = find_substring(right_raw.to_owned(), " : ")
  let label = if label_index is Some(index) {
    Some(right_raw[index + 3:].trim().to_owned())
  } else {
    None
  }
  let right_target = match label_index {
    Some(index) => right_raw[0:index].trim().to_owned()
    None => right_raw.to_owned()
  }
  let (left_raw, left_role) = split_role(left_raw, true)
  let (right_raw, right_role) = split_role(right_target, false)
  let (left_raw, left_qualifier) = split_qualifier(left_raw, true)
  let (right_raw, right_qualifier) = split_qualifier(right_raw, false)
  let (left, left_cardinality) = endpoint(left_raw, true)
  let (right, right_cardinality) = endpoint(right_raw, false)
  guard left.length() > 0 && right.length() > 0 else { false }
  self.ensure_entity(left)
  self.ensure_entity(right)
  self.relations.push({
    left,
    right,
    kind: relation_kind(arrow),
    left_cardinality,
    right_cardinality,
    left_role,
    right_role,
    left_qualifier,
    right_qualifier,
    label,
    dotted: arrow.contains(".."),
    raw_arrow: arrow,
  })
  true
}

///|
fn Parser::finish_entity(self : Parser) -> Unit {
  self.current_entity = None
}

///|
fn Parser::parse_line(self : Parser, line : String) -> Unit raise ParseError {
  let line = strip_comment(line)
  guard line.length() > 0 else { return }
  match @core.parse_style_directive(line) {
    Some(directive) => {
      self.style.apply(directive)
      return
    }
    None => ()
  }
  guard !line.has_prefix("@startuml") && !line.has_prefix("@enduml") else {
    return
  }
  guard !@core.is_preprocessor_directive(line) else { return }
  if self.current_entity is Some(entity_index) {
    if line == "}" || line == "};" {
      self.finish_entity()
      return
    }
    if line.contains("}") {
      self.finish_entity()
      return
    }
    self.entities[entity_index].members.push(member_of(line))
    return
  }
  if line == "}" || line == "};" {
    guard !self.package_stack.is_empty() else {
      self.raise_parse_error("unexpected }")
    }
    let _ = self.package_stack.pop()
    return
  }
  if line.to_lower() == "end package" || line.to_lower() == "end namespace" {
    guard !self.package_stack.is_empty() else {
      self.raise_parse_error("unexpected package end")
    }
    let _ = self.package_stack.pop()
    return
  }
  match parse_single_line_note(line) {
    Some(note) => {
      self.ensure_entity(note.target)
      self.notes.push(note)
      return
    }
    None => ()
  }
  match visibility_command(line) {
    Some((code, hidden)) => {
      self.set_entity_hidden(code, hidden)
      return
    }
    None => ()
  }
  match stereotype_assignment(line) {
    Some((code, stereotype)) => {
      self.set_entity_stereotype(code, stereotype)
      return
    }
    None => ()
  }
  match parse_external_member(line) {
    Some((target, entry)) => {
      self.add_member_to(target, entry)
      return
    }
    None => ()
  }
  match parse_multiline_note_header(line) {
    Some((target, position)) => {
      self.ensure_entity(target)
      self.consume_multiline_note(target, position)
      return
    }
    None => ()
  }
  match text_block_header(line) {
    Some(keyword) => {
      self.consume_text_block(keyword)
      return
    }
    None => ()
  }
  if line.to_lower().has_prefix("skinparam") && line.has_suffix("{") {
    self.consume_skinparam_block()
    return
  }
  if line.to_lower() == "together {" {
    self.consume_braced_block("together")
    return
  }
  match package_name(line) {
    Some(name) => {
      let parent = self.current_package()
      self.packages.push({ name, parent })
      self.package_stack.push(name)
      return
    }
    None => ()
  }
  match parse_declaration(line) {
    Some(declaration) => {
      self.add_entity(declaration, declaration_opens_body(line))
      match declaration.extends {
        Some(parent) => {
          self.ensure_entity(parent)
          self.relations.push({
            left: declaration.code,
            right: parent,
            kind: Extension,
            left_cardinality: None,
            right_cardinality: None,
            left_role: None,
            right_role: None,
            left_qualifier: None,
            right_qualifier: None,
            label: None,
            dotted: false,
            raw_arrow: "--|>",
          })
        }
        None => ()
      }
      match declaration.implements {
        Some(interface) => {
          self.ensure_entity(interface)
          self.relations.push({
            left: declaration.code,
            right: interface,
            kind: Realization,
            left_cardinality: None,
            right_cardinality: None,
            left_role: None,
            right_role: None,
            left_qualifier: None,
            right_qualifier: None,
            label: None,
            dotted: true,
            raw_arrow: "..|>",
          })
        }
        None => ()
      }
      return
    }
    None => ()
  }
  if self.parse_relation(line) {
    return
  }
  // PlantUML accepts many global/style commands. They do not alter the core
  // class graph and are intentionally retained as no-op parser directives.
  if line.has_prefix("skinparam ") ||
    line.to_lower() == "allowmixing" ||
    line.has_prefix("hide ") ||
    line.has_prefix("show ") ||
    line.has_prefix("left to right") ||
    line.has_prefix("top to bottom") ||
    line.has_prefix("title ") {
    return
  }
  self.raise_parse_error(line)
}

///|
/// Parse a PlantUML class diagram source.
pub fn parse(input : String) -> ClassDiagram raise ParseError {
  let parser = Parser::new(input)
  while parser.index < parser.lines.length() {
    let line = parser.lines[parser.index]
    parser.parse_line(line)
    parser.index += 1
  }
  guard parser.current_entity is None else {
    raise SyntaxError(parser.line_number(), "unclosed class body")
  }
  guard parser.package_stack.is_empty() else {
    raise SyntaxError(parser.line_number(), "unclosed package")
  }
  {
    entities: parser.entities,
    relations: parser.relations,
    packages: parser.packages,
    notes: parser.notes,
    style: parser.style,
  }
}
