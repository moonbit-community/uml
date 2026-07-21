///|
priv struct Parser {
  lines : Array[String]
  mut index : Int
  package_stack : Array[String]
  entities : Array[Entity]
  relations : Array[Relation]
  packages : Array[Package]
  notes : Array[Note]
  constraints : Array[LinkConstraint]
  entity_rules : Array[EntityRule]
  portion_rules : Array[PortionRule]
  style : @core.DocumentStyle
  mut current_entity : Int?
  mut body_depth : Int
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
    constraints: [],
    entity_rules: [],
    portion_rules: [],
    style: @core.DocumentStyle::empty(),
    current_entity: None,
    body_depth: 0,
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
  @core.strip_line_comment(line)
}

///|
fn words(line : String) -> Array[String] {
  @core.syntax_words(line)
}

///|
fn normalize_name(raw : String) -> String {
  @core.unquote_identifier(raw)
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
    "json" => Some(Json)
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
fn tail_targets(
  body : String,
  keyword : String,
  following_keyword : String?,
) -> Array[String] {
  guard find_substring(body.to_lower(), keyword) is Some(start) else {
    return []
  }
  let tail = body[start + keyword.length():].trim().to_owned()
  let targets = match following_keyword {
    Some(next) =>
      match find_substring(tail.to_lower(), next) {
        Some(end) => tail[0:end].trim().to_owned()
        None => tail
      }
    None => tail
  }
  let result : Array[String] = []
  for raw in @core.split_unquoted(targets, ',') {
    let target = normalize_name(raw)
    if target.length() > 0 {
      result.push(target)
    }
  }
  result
}

///|
fn parse_declaration(line : String) -> Declaration? {
  let (visibility, line) = leading_visibility(line)
  if line.has_prefix("<>") {
    let code = normalize_name(line[2:].trim().to_owned())
    guard code.length() > 0 else { return None }
    return Some({
      kind: Diamond,
      code,
      display: "",
      visibility,
      is_static: false,
      generic: None,
      stereotype: None,
      extends: [],
      implements: [],
      url: None,
      color: None,
    })
  }
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
      extends: [],
      implements: [],
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
  let extends = tail_targets(body, "extends ", Some(" implements "))
  let implements = tail_targets(body, "implements ", None)
  let color = declaration_color(body)
  for keyword in [" extends ", " implements ", " #", " ##"] {
    if find_substring(body, keyword) is Some(index) {
      body = body[0:index].trim().to_owned()
    }
  }
  let (_, stereotype) = extract_stereotype(body)
  let url = match @core.extract_url(body) {
    Some(value) => Some(value.target.target)
    None => None
  }
  let mut name_end = body.length()
  name_end = earlier(name_end, find_substring(body, " <<"))
  name_end = earlier(name_end, find_substring(body, " [["))
  let (body, generic) = extract_generic(body[0:name_end].trim().to_owned())
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
    is_hidden: false,
  }
}

///|
fn Parser::add_entity(
  self : Parser,
  declaration : Declaration,
  open : Bool,
) -> Unit {
  let qualified_code = self.qualify(declaration.code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
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
        self.body_depth = 1
      }
      return
    }
  }
  self.entities.push({
    code: declaration.code,
    qualified_code,
    display: declaration.display,
    kind: declaration.kind,
    scope: self.current_package(),
    visibility: declaration.visibility,
    is_static: declaration.is_static,
    generic: declaration.generic,
    stereotype: declaration.stereotype,
    is_hidden: false,
    is_removed: false,
    fields_hidden: false,
    methods_hidden: false,
    stereotype_hidden: false,
    circle_hidden: false,
    url: declaration.url,
    color: declaration.color,
    members: [],
    map_entries: [],
    json_data: None,
  })
  if open {
    self.current_entity = Some(self.entities.length() - 1)
    self.body_depth = 1
  }
}

///|
fn Parser::qualify(self : Parser, code : String) -> String {
  if self.current_package().length() == 0 ||
    code.contains(".") ||
    code.contains("::") {
    code
  } else {
    self.current_package() + "." + code
  }
}

///|
fn Parser::resolve(self : Parser, code : String) -> String {
  for entity in self.entities {
    if entity.qualified_code == code {
      return entity.qualified_code
    }
  }
  let qualified = self.qualify(code)
  for entity in self.entities {
    if entity.qualified_code == qualified {
      return entity.qualified_code
    }
  }
  if self.current_package().length() > 0 {
    return qualified
  }
  let mut found = None
  for entity in self.entities {
    if entity.code == code {
      if found is Some(_) {
        return qualified
      }
      found = Some(entity.qualified_code)
    }
  }
  found.unwrap_or(qualified)
}

///|
fn Parser::ensure_entity(self : Parser, code : String) -> String {
  let qualified_code = self.resolve(code)
  guard !self.entities.any(entity => entity.qualified_code == qualified_code) else {
    return qualified_code
  }
  self.entities.push({
    code,
    qualified_code,
    display: code,
    kind: Class,
    scope: self.current_package(),
    visibility: Unknown,
    is_static: false,
    generic: None,
    stereotype: None,
    is_hidden: false,
    is_removed: false,
    fields_hidden: false,
    methods_hidden: false,
    stereotype_hidden: false,
    circle_hidden: false,
    url: None,
    color: None,
    members: [],
    map_entries: [],
    json_data: None,
  })
  qualified_code
}

///|
fn Parser::ensure_entity_as(
  self : Parser,
  code : String,
  kind : EntityKind,
) -> String {
  let qualified_code = self.resolve(code)
  let existed = self.entities.any(entity => {
    entity.qualified_code == qualified_code
  })
  let qualified_code = self.ensure_entity(code)
  if !existed {
    for index, entity in self.entities {
      if entity.qualified_code == qualified_code {
        self.entities[index] = { ..entity, kind, }
        break
      }
    }
  }
  qualified_code
}

///|
fn Parser::set_entity_url(self : Parser, code : String, url : String) -> Bool {
  let qualified_code = self.resolve(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = { ..entity, url: Some(url) }
      return true
    }
  }
  false
}

///|
fn Parser::set_entity_stereotype(
  self : Parser,
  code : String,
  stereotype : String,
) -> Unit {
  let qualified_code = self.ensure_entity(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = { ..entity, stereotype: Some(stereotype) }
      return
    }
  }
}

///|
fn stereotype_assignment(line : String) -> (String, String)? {
  guard parse_declaration(line) is None else { return None }
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
fn url_assignment(line : String) -> (String, String)? {
  guard line.to_lower().has_prefix("url ") ||
    line.to_lower().has_prefix("url of ") ||
    line.to_lower().has_prefix("url for ") else {
    return None
  }
  guard find_substring(line, "[[") is Some(url_start) else { return None }
  guard @core.parse_url_target(line[url_start:].to_owned()) is Some(url) else {
    return None
  }
  let prefix = words(line[0:url_start].trim().to_owned())
  guard prefix.length() >= 2 else { return None }
  let mut code_index = prefix.length() - 1
  if prefix[code_index].to_lower() == "is" && code_index > 0 {
    code_index -= 1
  }
  let code = normalize_name(prefix[code_index])
  guard code.length() > 0 else { return None }
  Some((code, url.target))
}

///|
fn Parser::add_member_to(self : Parser, code : String, entry : Member) -> Unit {
  let qualified_code = self.ensure_entity(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
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
fn package_declaration(raw : String) -> GroupDeclaration? {
  let (visibility, line) = leading_visibility(raw)
  let (prefix, is_namespace) = if line.has_prefix("package ") {
    (8, false)
  } else if line.has_prefix("namespace ") {
    (10, true)
  } else {
    return None
  }
  let value = line[prefix:].trim()
  guard value.length() > 0 else { return None }
  let empty = value.has_suffix("{}")
  let mut body = if empty {
    value[0:value.length() - 2].trim().to_owned()
  } else if value.has_suffix("{") {
    value[0:value.length() - 1].trim().to_owned()
  } else {
    value.to_owned()
  }
  let color = declaration_color(body)
  if find_substring(body, " #") is Some(start) {
    body = body[0:start].trim().to_owned()
  }
  let (_, stereotype) = extract_stereotype(body)
  let url = match @core.extract_url(body) {
    Some(value) => Some(value.target.target)
    None => None
  }
  let mut name_end = body.length()
  name_end = earlier(name_end, find_substring(body, " <<"))
  name_end = earlier(name_end, find_substring(body, " [["))
  body = body[0:name_end].trim().to_owned()
  let (display, code) = match body.split(" as ").to_array() {
    [name, alternate] =>
      (normalize_name(name.to_owned()), normalize_name(alternate.to_owned()))
    _ => {
      let name = normalize_name(body)
      (name, name)
    }
  }
  guard code.length() > 0 else { return None }
  Some({
    code,
    display,
    is_namespace,
    visibility,
    stereotype,
    url,
    color,
    empty,
  })
}

///|
fn find_substring(haystack : String, needle : String) -> Int? {
  @core.find_literal(haystack, needle)
}

///|
fn arrow_body_char(char : Char) -> Bool {
  char == '-' || char == '=' || char == '.'
}

///|
fn prefix_at(line : String, index : Int, prefix : String) -> Bool {
  index + prefix.length() <= line.length() &&
  line[index:index + prefix.length()].to_owned() == prefix
}

///|
fn longest_prefix_at(
  line : String,
  index : Int,
  candidates : Array[String],
) -> String? {
  for candidate in candidates {
    if prefix_at(line, index, candidate) {
      return Some(candidate)
    }
  }
  None
}

///|
fn consume_style(line : String, start : Int) -> Int {
  guard start < line.length() && line[start] == '[' else { start }
  for index in (start + 1)..<line.length() {
    if line[index] == ']' {
      return index + 1
    }
  }
  start
}

///|
fn relation_arrow(line : String) -> (String, Int, Int)? {
  let chars = line.to_array()
  let left_decors = [
    "<|:", "<||", "}o", "|o", "}|", "<|", "<<", "0)", "||", "*", "o", "x", "}", "<",
    "0", "@", ")", "#", "+",
  ]
  let right_decors = [
    ":|>", "||>", "o{", "o|", "|{", "|>", ">>", "(0", "||", "*", "o", "x", "{", ">",
    "0", "@", "(", "#", "+", "\\", "//",
  ]
  let directions = [
    "right", "down", "left", "up", "ri", "do", "le", "r", "d", "l", "u",
  ]
  let insides = ["(0)", "(0", "0)", "0"]
  let mut quoted = false
  for body_start in 0..<chars.length() {
    if chars[body_start] == '"' {
      quoted = !quoted
      continue
    }
    guard !quoted && arrow_body_char(chars[body_start]) else { continue }
    let mut start = body_start
    for decor in left_decors {
      if decor.length() <= body_start &&
        line[body_start - decor.length():body_start].to_owned() == decor {
        start = body_start - decor.length()
        break
      }
    }
    let mut end = body_start
    while end < chars.length() && arrow_body_char(chars[end]) {
      end += 1
    }
    end = consume_style(line, end)
    if longest_prefix_at(line, end, directions) is Some(direction) {
      end += direction.length()
    }
    if longest_prefix_at(line, end, insides) is Some(inside) &&
      end + inside.length() < chars.length() &&
      arrow_body_char(chars[end + inside.length()]) {
      end += inside.length()
    }
    end = consume_style(line, end)
    while end < chars.length() && arrow_body_char(chars[end]) {
      end += 1
    }
    if longest_prefix_at(line, end, right_decors) is Some(decor) {
      end += decor.length()
    }
    guard end > body_start else { continue }
    return Some((line[start:end].to_owned(), start, end))
  }
  None
}

///|
fn left_relation_end(arrow : String) -> RelationEnd {
  if arrow.has_prefix("<|:") {
    DefinedBy
  } else if arrow.has_prefix("<||") {
    Redefines
  } else if arrow.has_prefix("<|") || arrow.has_prefix("^") {
    Extension
  } else if arrow.has_prefix("}o") {
    CircleCrowfoot
  } else if arrow.has_prefix("|o") {
    CircleLine
  } else if arrow.has_prefix("}|") {
    LineCrowfoot
  } else if arrow.has_prefix("||") {
    DoubleLine
  } else if arrow.has_prefix("*") {
    CompositionEnd
  } else if arrow.has_prefix("o") {
    AggregationEnd
  } else if arrow.has_prefix("x") {
    NotNavigable
  } else if arrow.has_prefix("}") {
    Crowfoot
  } else if arrow.has_prefix("<<") {
    TriangleArrow
  } else if arrow.has_prefix("<") {
    Arrow
  } else if arrow.has_prefix("0)") {
    CircleConnect
  } else if arrow.has_prefix("0") {
    CircleEnd
  } else if arrow.has_prefix("@") {
    FilledCircle
  } else if arrow.has_prefix(")") {
    Parenthesis
  } else if arrow.has_prefix("#") {
    Square
  } else if arrow.has_prefix("+") {
    Plus
  } else {
    Plain
  }
}

///|
fn right_relation_end(arrow : String) -> RelationEnd {
  if arrow.has_suffix(":|>") {
    DefinedBy
  } else if arrow.has_suffix("||>") {
    Redefines
  } else if arrow.has_suffix("|>") || arrow.has_suffix("^") {
    Extension
  } else if arrow.has_suffix("o{") {
    CircleCrowfoot
  } else if arrow.has_suffix("o|") {
    CircleLine
  } else if arrow.has_suffix("|{") {
    LineCrowfoot
  } else if arrow.has_suffix("||") {
    DoubleLine
  } else if arrow.has_suffix("*") {
    CompositionEnd
  } else if arrow.has_suffix("o") {
    AggregationEnd
  } else if arrow.has_suffix("x") {
    NotNavigable
  } else if arrow.has_suffix("{") {
    Crowfoot
  } else if arrow.has_suffix(">>") {
    TriangleArrow
  } else if arrow.has_suffix(">") {
    Arrow
  } else if arrow.has_suffix("(0") {
    CircleConnect
  } else if arrow.has_suffix("0") {
    CircleEnd
  } else if arrow.has_suffix("@") {
    FilledCircle
  } else if arrow.has_suffix("(") {
    Parenthesis
  } else if arrow.has_suffix("#") {
    Square
  } else if arrow.has_suffix("+") {
    Plus
  } else if arrow.has_suffix("\\") {
    HalfArrowUp
  } else if arrow.has_suffix("//") {
    HalfArrowDown
  } else {
    Plain
  }
}

///|
fn relation_kind(
  left : RelationEnd,
  right : RelationEnd,
  arrow : String,
) -> RelationKind {
  if left is Extension ||
    right is Extension ||
    left is Redefines ||
    right is Redefines ||
    left is DefinedBy ||
    right is DefinedBy {
    if arrow.contains(".") {
      Realization
    } else {
      Extension
    }
  } else if left is CompositionEnd || right is CompositionEnd {
    Composition
  } else if left is AggregationEnd || right is AggregationEnd {
    Aggregation
  } else if arrow.contains(".") {
    Dependency
  } else {
    Association
  }
}

///|
fn relation_direction(arrow : String) -> RelationDirection {
  if arrow.contains("left") || arrow.contains("-le") || arrow.contains("-l") {
    Leftward
  } else if arrow.contains("right") ||
    arrow.contains("-ri") ||
    arrow.contains("-r") {
    Rightward
  } else if arrow.contains("up") || arrow.contains("-u") {
    Upward
  } else if arrow.contains("down") ||
    arrow.contains("-do") ||
    arrow.contains("-d") {
    Downward
  } else {
    Automatic
  }
}

///|
fn relation_style(arrow : String) -> String? {
  guard find_substring(arrow, "[") is Some(start) else { return None }
  guard find_substring(arrow[start + 1:].to_owned(), "]") is Some(length) else {
    return None
  }
  Some(arrow[start + 1:start + 1 + length].to_owned())
}

///|
fn relation_inside(arrow : String) -> String? {
  for inside in ["(0)", "(0", "0)"] {
    if arrow.contains(inside) {
      return Some(inside)
    }
  }
  None
}

///|
fn earlier(current : Int, candidate : Int?) -> Int {
  match candidate {
    Some(value) => current.min(value)
    None => current
  }
}

///|
fn relation_suffix(raw : String) -> (String, String?, String?, String?) {
  let color_start = if raw.has_prefix("#") {
    Some(0)
  } else {
    find_substring(raw, " #")
  }
  let url_start = if raw.has_prefix("[[") {
    Some(0)
  } else {
    find_substring(raw, " [[")
  }
  let stereotype_start = if raw.has_prefix("<<") {
    Some(0)
  } else {
    find_substring(raw, " <<")
  }
  let mut target_end = raw.length()
  target_end = earlier(target_end, color_start)
  target_end = earlier(target_end, url_start)
  target_end = earlier(target_end, stereotype_start)
  let target = raw[0:target_end].trim().to_owned()
  let color = match color_start {
    Some(start) => {
      let offset = if start == 0 { 1 } else { start + 2 }
      let suffix = raw[offset:].trim().to_owned()
      let value = match find_substring(suffix, " ") {
        Some(end) => suffix[0:end].to_owned()
        None => suffix
      }
      Some(value)
    }
    None => None
  }
  let url = match url_start {
    Some(start) => {
      let offset = if start == 0 { 0 } else { start + 1 }
      match @core.extract_url(raw[offset:].to_owned()) {
        Some(value) => Some(value.target.target)
        None => None
      }
    }
    None => None
  }
  let stereotype = match stereotype_start {
    Some(start) => {
      let offset = if start == 0 { 0 } else { start + 1 }
      let (_, stereotype) = extract_stereotype(raw[offset:].to_owned())
      stereotype
    }
    None => None
  }
  (target, color, url, stereotype)
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
  Some({
    target,
    position,
    text,
    target_kind: EntityNote,
    relation_index: None,
    member_name: None,
    code: None,
    color: None,
    url: None,
    stereotype: None,
  })
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
      self.notes.push({
        target,
        position,
        text: text.to_string(),
        target_kind: EntityNote,
        relation_index: None,
        member_name: None,
        code: None,
        color: None,
        url: None,
        stereotype: None,
      })
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
  let weight = if left_raw.has_prefix("@") &&
    find_substring(left_raw, " ") is Some(separator) {
    let value = left_raw[1:separator].to_owned()
    left_raw = left_raw[separator + 1:].trim().to_owned()
    Some(value)
  } else {
    None
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
  let (right_target, color, url, stereotype) = relation_suffix(right_target)
  let (left_raw, left_role) = split_role(left_raw, true)
  let (right_raw, right_role) = split_role(right_target, false)
  let (left_raw, left_qualifier) = split_qualifier(left_raw, true)
  let (right_raw, right_qualifier) = split_qualifier(right_raw, false)
  let (left, left_cardinality) = endpoint(left_raw, true)
  let (right, right_cardinality) = endpoint(right_raw, false)
  guard left.length() > 0 && right.length() > 0 else { false }
  let left_end = left_relation_end(arrow)
  let right_end = right_relation_end(arrow)
  let left = if left_end is Parenthesis {
    self.ensure_entity_as(left, Interface)
  } else {
    self.ensure_entity(left)
  }
  let right = if right_end is Parenthesis {
    self.ensure_entity_as(right, Interface)
  } else {
    self.ensure_entity(right)
  }
  self.relations.push({
    left,
    right,
    kind: relation_kind(left_end, right_end, arrow),
    left_cardinality,
    right_cardinality,
    left_role,
    right_role,
    left_qualifier,
    right_qualifier,
    label,
    dotted: arrow.contains(".."),
    raw_arrow: arrow,
    left_end,
    right_end,
    direction: relation_direction(arrow),
    line_style: relation_style(arrow),
    color,
    url,
    stereotype,
    weight,
    inside: relation_inside(arrow),
    left_port: None,
    right_port: None,
  })
  true
}

///|
fn Parser::finish_entity(self : Parser) -> Unit {
  self.current_entity = None
  self.body_depth = 0
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
    self.consume_entity_body_line(entity_index, line)
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
  match parse_link_note_header(line) {
    Some((header, Some(text))) => {
      self.push_special_note(header, text)
      return
    }
    Some((header, None)) => {
      self.consume_special_note(header)
      return
    }
    None => ()
  }
  match parse_member_tip_header(line) {
    Some(header) => {
      self.consume_special_note(header)
      return
    }
    None => ()
  }
  match parse_named_note(line) {
    Some((header, Some(text))) => {
      self.push_special_note(header, text)
      return
    }
    Some((header, None)) => {
      self.consume_special_note(header)
      return
    }
    None => ()
  }
  match parse_link_constraint(line, self.relations.length()) {
    Some(constraint) => {
      self.constraints.push(constraint)
      return
    }
    None => ()
  }
  match parse_single_line_note(line) {
    Some(note) => {
      let target = self.ensure_entity(note.target)
      self.notes.push({ ..note, target, })
      return
    }
    None => ()
  }
  match parse_portion_rule(line, self.current_package()) {
    Some(rule) => {
      self.portion_rules.push(rule)
      return
    }
    None => ()
  }
  match parse_entity_rule(line) {
    Some(rule) => {
      self.entity_rules.push(rule)
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
  match url_assignment(line) {
    Some((code, url)) => {
      guard self.set_entity_url(code, url) else {
        self.raise_parse_error("unknown entity \{code}")
      }
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
      let target = self.ensure_entity(target)
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
  match package_declaration(line) {
    Some(group) => {
      let parent = self.current_package()
      let qualified_name = if parent.length() == 0 {
        group.code
      } else {
        parent + "." + group.code
      }
      self.packages.push({
        name: group.code,
        qualified_name,
        display: group.display,
        parent,
        is_namespace: group.is_namespace,
        visibility: group.visibility,
        stereotype: group.stereotype,
        url: group.url,
        color: group.color,
      })
      if !group.empty {
        self.package_stack.push(group.code)
      }
      return
    }
    None => ()
  }
  match parse_single_line_json(line) {
    Some(value) => {
      self.add_single_line_json(value)
      return
    }
    None => ()
  }
  match parse_declaration(line) {
    Some(declaration) => {
      self.add_entity(declaration, declaration_opens_body(line))
      for parent in declaration.extends {
        let child = self.resolve(declaration.code)
        let parent_kind = if declaration.kind is Interface {
          Interface
        } else {
          Class
        }
        let parent = self.ensure_entity_as(parent, parent_kind)
        self.relations.push({
          left: child,
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
          left_end: Plain,
          right_end: Extension,
          direction: Automatic,
          line_style: None,
          color: None,
          url: None,
          stereotype: None,
          weight: None,
          inside: None,
          left_port: None,
          right_port: None,
        })
      }
      for interface in declaration.implements {
        let child = self.resolve(declaration.code)
        let interface = self.ensure_entity_as(interface, Interface)
        self.relations.push({
          left: child,
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
          left_end: Plain,
          right_end: Extension,
          direction: Automatic,
          line_style: None,
          color: None,
          url: None,
          stereotype: None,
          weight: None,
          inside: None,
          left_port: None,
          right_port: None,
        })
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
  parser.apply_filter_rules()
  {
    entities: parser.entities,
    relations: parser.relations,
    packages: parser.packages,
    notes: parser.notes,
    constraints: parser.constraints,
    style: parser.style,
  }
}
