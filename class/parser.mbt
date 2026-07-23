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
  mut last_entity : String?
  mut namespace_separator : String?
  mut allow_mixing : Bool
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
    last_entity: None,
    namespace_separator: Some("."),
    allow_mixing: false,
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
    "usecase/" => Some(BusinessUsecase)
    "person" => Some(Person)
    "actor/" => Some(BusinessActor)
    "exception" => Some(Exception)
    "metaclass" => Some(Metaclass)
    "stereotype" => Some(Stereotype)
    "dataclass" => Some(Dataclass)
    "record" => Some(Record)
    "map" => Some(Map)
    "json" => Some(Json)
    "diamond" => Some(Diamond)
    "component" => Some(Component)
    "boundary" => Some(Boundary)
    "control" => Some(Control)
    "port" => Some(Port)
    "portin" => Some(PortIn)
    "portout" => Some(PortOut)
    "actor" => Some(Actor)
    "database" => Some(Database)
    "queue" => Some(Queue)
    "folder" => Some(Folder)
    "file" => Some(File)
    "node" => Some(Node)
    "cloud" => Some(Cloud)
    "state" => Some(State)
    "artifact" => Some(Artifact)
    "card" => Some(Card)
    "package" => Some(Folder)
    "rectangle" => Some(Rectangle)
    "hexagon" => Some(Hexagon)
    "label" => Some(Label)
    "frame" => Some(Frame)
    "action" => Some(Action)
    "process" => Some(Process)
    "stack" => Some(Stack)
    "storage" => Some(Storage)
    "agent" => Some(Agent)
    "collections" => Some(Collections)
    _ => None
  }
}

///|
fn native_class_kind(kind : EntityKind) -> Bool {
  match kind {
    Class
    | AbstractClass
    | Interface
    | Enum
    | Annotation
    | Object
    | Entity
    | Protocol
    | Struct
    | Circle
    | Exception
    | Metaclass
    | Stereotype
    | Dataclass
    | Record
    | Map
    | Json
    | Diamond
    | NamedNote => true
    _ => false
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
  match parse_stereotype_split(body) {
    Some((prefix, stereotype)) =>
      (prefix.trim().to_owned(), @core.normalize_stereotype(stereotype))
    None => (body, None)
  }
}

///|
fn declaration_color(body : String) -> String? {
  guard @core.find_unquoted_literal(body, " #") is Some(start) else {
    return None
  }
  guard start + 2 < body.length() && body[start + 2] != '#' else { return None }
  let suffix = body[start + 2:].trim().to_owned()
  match find_substring(suffix, " ") {
    Some(end) => Some(suffix[0:end].to_owned())
    None => Some(suffix)
  }
}

///|
fn name_and_code(body : String) -> (String, String) {
  match @core.parse_alias_identifier(body) {
    Some((name, alternate)) => {
      let name = name.trim()
      let alternate = alternate.trim()
      if alternate.has_prefix("\"") && alternate.has_suffix("\"") {
        (normalize_name(alternate.to_owned()), normalize_name(name.to_owned()))
      } else {
        (normalize_name(name.to_owned()), normalize_name(alternate.to_owned()))
      }
    }
    None => {
      let name = normalize_name(body)
      (name, name)
    }
  }
}

///|
fn parse_declaration(line : String) -> Declaration? {
  parse_declaration_line(line)
}

///|
fn shaped_declaration(
  kind : EntityKind,
  display : String,
  code : String,
) -> (EntityKind, String, String) {
  let value = display.trim()
  let encoded = if value.length() >= 2 &&
    value.has_prefix("(") &&
    value.has_suffix(")") {
    Some((Usecase, value[1:value.length() - 1].trim().to_owned()))
  } else if value.length() >= 2 &&
    value.has_prefix(":") &&
    value.has_suffix(":") {
    Some((Actor, value[1:value.length() - 1].trim().to_owned()))
  } else if value.length() >= 2 &&
    value.has_prefix("[") &&
    value.has_suffix("]") {
    Some((Component, value[1:value.length() - 1].trim().to_owned()))
  } else if code.length() >= 2 && code.has_prefix("(") && code.has_suffix(")") {
    Some((Usecase, code[1:code.length() - 1].trim().to_owned()))
  } else if code.length() >= 2 && code.has_prefix(":") && code.has_suffix(":") {
    Some((Actor, code[1:code.length() - 1].trim().to_owned()))
  } else if code.length() >= 2 && code.has_prefix("[") && code.has_suffix("]") {
    Some((Component, code[1:code.length() - 1].trim().to_owned()))
  } else {
    None
  }
  match encoded {
    Some((shape, raw_inner)) => {
      let inner = normalize_name(raw_inner)
      if inner.length() > 0 {
        let actual_code = if display == code { inner } else { code }
        return (shape, inner, actual_code)
      }
    }
    None => ()
  }
  let value = code.trim()
  if value.length() >= 2 && value.has_prefix("(") && value.has_suffix(")") {
    let inner = normalize_name(value[1:value.length() - 1].trim().to_owned())
    if inner.length() > 0 {
      return (Usecase, inner, inner)
    }
  }
  if value.length() >= 2 && value.has_prefix(":") && value.has_suffix(":") {
    let inner = normalize_name(value[1:value.length() - 1].trim().to_owned())
    if inner.length() > 0 {
      return (Actor, inner, inner)
    }
  }
  if value.length() >= 2 && value.has_prefix("[") && value.has_suffix("]") {
    let inner = normalize_name(value[1:value.length() - 1].trim().to_owned())
    if inner.length() > 0 {
      return (Component, inner, inner)
    }
  }
  (kind, display, code)
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
fn Parser::implicit_namespace_scope(self : Parser, code : String) -> String {
  guard self.current_package().length() == 0 &&
    self.namespace_separator is Some(separator) &&
    separator.length() > 0 else {
    return self.current_package()
  }
  let segments = code
    .split(separator)
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  guard segments.length() > 1 else { return self.current_package() }
  segments[0:segments.length() - 1].to_owned().join(separator)
}

///|
fn Parser::ensure_implicit_namespaces(self : Parser, code : String) -> Unit {
  guard self.current_package().length() == 0 &&
    self.namespace_separator is Some(separator) &&
    separator.length() > 0 else {
    return
  }
  let segments = code
    .split(separator)
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  guard segments.length() > 1 else { return }
  let mut parent = ""
  for index in 0..<(segments.length() - 1) {
    let segment = segments[index]
    let qualified_name = if parent.length() == 0 {
      segment
    } else {
      parent + separator + segment
    }
    if !self.packages.any(group => group.qualified_name == qualified_name) {
      self.packages.push({
        name: segment,
        qualified_name,
        display: segment,
        parent,
        is_namespace: true,
        visibility: Unknown,
        stereotype: None,
        url: None,
        color: None,
      })
    }
    parent = qualified_name
  }
}

///|
fn Parser::add_entity(
  self : Parser,
  declaration : Declaration,
  open : Bool,
) -> Unit {
  self.ensure_implicit_namespaces(declaration.code)
  let qualified_code = self.qualify(declaration.code)
  let scope = self.implicit_namespace_scope(declaration.code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = {
        ..entity,
        display: declaration.display,
        kind: declaration.kind,
        scope,
        visibility: declaration.visibility,
        is_static: declaration.is_static,
        generic: declaration.generic,
        stereotype: declaration.stereotype,
        url: declaration.url,
        color: declaration.color,
        line_color: declaration.line_color,
        line_style: declaration.line_style,
        tags: declaration.tags,
      }
      if open {
        self.current_entity = Some(index)
        self.body_depth = 1
      }
      self.last_entity = Some(qualified_code)
      return
    }
  }
  self.entities.push({
    code: declaration.code,
    qualified_code,
    display: declaration.display,
    kind: declaration.kind,
    scope,
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
    line_color: declaration.line_color,
    line_style: declaration.line_style,
    tags: declaration.tags,
    members: [],
    map_entries: [],
    json_data: None,
  })
  if open {
    self.current_entity = Some(self.entities.length() - 1)
    self.body_depth = 1
  }
  self.last_entity = Some(qualified_code)
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
  self.ensure_implicit_namespaces(code)
  let qualified_code = self.resolve(code)
  guard !self.entities.any(entity => entity.qualified_code == qualified_code) else {
    return qualified_code
  }
  self.entities.push({
    code,
    qualified_code,
    display: code,
    kind: Class,
    scope: self.implicit_namespace_scope(code),
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
    line_color: None,
    line_style: None,
    tags: [],
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
) -> Bool {
  let qualified_code = self.resolve(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = { ..entity, stereotype: Some(stereotype) }
      return true
    }
  }
  false
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
  let head = words(line)
  guard head.length() > 0 &&
    !head[0].to_lower().has_prefix("mix_") &&
    declaration_kind(head[0]) is None else {
    return None
  }
  guard find_substring(line, ":") is Some(separator) else { return None }
  let target = line[0:separator].trim().to_owned()
  let body = line[separator + 1:].trim().to_owned()
  guard target.length() > 0 && body.length() > 0 else { return None }
  guard !target.contains("-") && !target.contains("<") && !target.contains("[[") else {
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
  if @core.find_unquoted_literal(body, " #") is Some(start) {
    body = body[0:start].trim().to_owned()
  }
  let (_, stereotype) = extract_stereotype(body)
  let url = match @core.extract_url(body) {
    Some(value) => Some(value.target.target)
    None => None
  }
  let mut name_end = body.length()
  name_end = earlier(name_end, @core.find_unquoted_literal(body, " <<"))
  name_end = earlier(name_end, @core.find_unquoted_literal(body, " [["))
  body = body[0:name_end].trim().to_owned()
  let (display, code) = name_and_code(body)
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
  } else if arrow.has_prefix("()") ||
    arrow.has_prefix("))") ||
    arrow.has_prefix(")") {
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
  } else if arrow.has_suffix("()") ||
    arrow.has_suffix("((") ||
    arrow.has_suffix("(") {
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
fn text_block_header(line : String) -> String? {
  let tokens = words(line.to_lower())
  if tokens.length() > 1 && tokens[0] == "legend" {
    let alignments = tokens[1:].to_owned()
    if alignments.all(word => {
        word == "top" ||
        word == "bottom" ||
        word == "left" ||
        word == "right" ||
        word == "center"
      }) {
      return Some("legend")
    }
  }
  if tokens.length() == 2 &&
    (tokens[0] == "left" || tokens[0] == "right" || tokens[0] == "center") &&
    (tokens[1] == "header" || tokens[1] == "footer") {
    return Some(tokens[1])
  }
  match tokens {
    [keyword] =>
      match keyword {
        "title" => Some("title")
        "legend" => Some("legend")
        "header" => Some("header")
        "footer" => Some("footer")
        "caption" => Some("caption")
        _ => None
      }
    _ => None
  }
}

///|
fn text_block_end(line : String, keyword : String) -> Bool {
  match line.to_lower() {
    value if value == "end " + keyword || value == "end" + keyword => true
    _ => false
  }
}

///|
fn Parser::consume_text_block(
  self : Parser,
  keyword : String,
) -> Unit raise ParseError {
  self.index += 1
  let text = StringBuilder()
  let mut first = true
  while self.index < self.lines.length() {
    if text_block_end(strip_comment(self.lines[self.index]), keyword) {
      self.style.apply(TextBlock(keyword, text.to_string()))
      return
    }
    if !first {
      text.write_char('\n')
    }
    text.write_string(self.lines[self.index])
    first = false
    self.index += 1
  }
  self.raise_parse_error("unclosed \{keyword}")
}

///|
fn Parser::consume_braced_block(
  self : Parser,
  kind : String,
) -> Unit raise ParseError {
  let package_depth = self.package_stack.length()
  self.index += 1
  while self.index < self.lines.length() {
    let line = strip_comment(self.lines[self.index])
    if line == "}" && self.package_stack.length() == package_depth {
      return
    }
    let reference = normalize_name(line)
    let existing_reference = words(line).length() == 1 &&
      self.entities.any(entity => {
        entity.qualified_code == self.resolve(reference) ||
        entity.code == reference
      })
    if !existing_reference {
      self.parse_line(self.lines[self.index])
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
fn Parser::consume_common_block(
  self : Parser,
  terminator : String,
) -> Unit raise ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    if strip_comment(self.lines[self.index]).to_lower() == terminator {
      return
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed common definition block")
}

///|
fn Parser::resolve_relation_name(
  self : Parser,
  syntax : RelationNameSyntax,
) -> (String, String?) {
  let full = normalize_name(syntax.name)
  guard syntax.port_base is Some(base) && syntax.port_value is Some(port) else {
    return (full, None)
  }
  let base = normalize_name(base)
  let base_code = self.resolve(base)
  if self.entities.any(entity => entity.qualified_code == full) {
    (full, None)
  } else if self.entities.any(entity => entity.qualified_code == base_code) {
    (base, Some(port))
  } else {
    (full, None)
  }
}

///|
fn Parser::apply_relation_syntax(
  self : Parser,
  syntax : RelationLineSyntax,
) -> Unit {
  let arrow = syntax.arrow
  let left_end = left_relation_end(arrow)
  let right_end = right_relation_end(arrow)
  let (left_name, left_port) = self.resolve_relation_name(syntax.left.name)
  let (right_name, right_port) = self.resolve_relation_name(syntax.right.name)
  let left = if syntax.left.couple is Some((couple_left, _)) {
    self.ensure_entity(couple_left)
  } else if left_end is Parenthesis {
    self.ensure_entity_as(left_name, Interface)
  } else {
    self.ensure_entity(left_name)
  }
  let right = if syntax.right.couple is Some((_, couple_right)) {
    self.ensure_entity(couple_right)
  } else if right_end is Parenthesis {
    self.ensure_entity_as(right_name, Interface)
  } else {
    self.ensure_entity(right_name)
  }
  self.relations.push({
    left,
    right,
    kind: relation_kind(left_end, right_end, arrow),
    left_cardinality: syntax.left.cardinality,
    right_cardinality: syntax.right.cardinality,
    left_role: syntax.left.role,
    right_role: syntax.right.role,
    left_qualifier: syntax.left.qualifier,
    right_qualifier: syntax.right.qualifier,
    label: syntax.label,
    dotted: arrow.contains(".."),
    raw_arrow: arrow,
    left_end,
    right_end,
    direction: relation_direction(arrow),
    line_style: relation_style(arrow),
    color: syntax.color,
    url: syntax.url,
    stereotype: syntax.stereotype,
    weight: syntax.weight,
    inside: relation_inside(arrow),
    left_port,
    right_port,
    left_couple: match syntax.left.couple {
      Some((first, second)) => Some((self.resolve(first), self.resolve(second)))
      None => None
    },
    right_couple: match syntax.right.couple {
      Some((first, second)) => Some((self.resolve(first), self.resolve(second)))
      None => None
    },
  })
}

///|
fn Parser::parse_relation(self : Parser, line : String) -> Bool {
  guard parse_relation_line(line) is Some(syntax) else { false }
  self.apply_relation_syntax(syntax)
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
  match @core.common_block_terminator(line) {
    Some(terminator) => {
      self.consume_common_block(terminator)
      return
    }
    None => ()
  }
  match @core.parse_namespace_separator(line) {
    Some(separator) => {
      self.namespace_separator = separator
      match separator {
        Some(value) => self.style.apply(Property("namespace separator", value))
        None => self.style.apply(Property("namespace separator", "none"))
      }
      return
    }
    None => ()
  }
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
  if line.to_lower() == "allowmixing" || line.to_lower() == "allow_mixing" {
    self.allow_mixing = true
    return
  }
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
  match parse_class_annotation_line(line) {
    Some(syntax) => {
      self.apply_annotation_syntax(syntax)
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
      guard self.set_entity_stereotype(code, stereotype) else {
        self.raise_parse_error("no such class \{code}")
      }
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
  match parse_multiline_element_header(line) {
    Some(header) => {
      self.consume_multiline_element(header)
      return
    }
    None => ()
  }
  match package_declaration(line) {
    Some(group) => {
      let parent = self.current_package()
      let segments = @core.split_unquoted(group.code, '.')
      let mut prefix = parent
      for segment_index, segment in segments {
        let qualified_name = if prefix.length() == 0 {
          segment
        } else {
          prefix + "." + segment
        }
        let is_last = segment_index == segments.length() - 1
        let display = if is_last { group.display } else { segment }
        let package_value : Package = {
          name: segment,
          qualified_name,
          display,
          parent: prefix,
          is_namespace: group.is_namespace,
          visibility: if is_last {
            group.visibility
          } else {
            Unknown
          },
          stereotype: if is_last {
            group.stereotype
          } else {
            None
          },
          url: if is_last {
            group.url
          } else {
            None
          },
          color: if is_last {
            group.color
          } else {
            None
          },
        }
        let mut existing = None
        for index, item in self.packages {
          if item.qualified_name == qualified_name {
            existing = Some(index)
            break
          }
        }
        match existing {
          Some(index) => if is_last { self.packages[index] = package_value }
          None => self.packages.push(package_value)
        }
        prefix = qualified_name
      }
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
  // Relations may contain endpoint ports (`A::out --> B::in`) and may start
  // with words that are also element keywords (for example `Port ()-- A`).
  if self.parse_relation(line) {
    return
  }
  match parse_declaration(line) {
    Some(declaration) => {
      let (_, declaration_line) = leading_visibility(line)
      let mix_prefixed = declaration_line.to_lower().has_prefix("mix_")
      guard native_class_kind(declaration.kind) ||
        self.allow_mixing ||
        mix_prefixed else {
        self.raise_parse_error(
          "use allowmixing to mix classes and other UML elements",
        )
      }
      let opens_body = declaration_opens_body(line)
      let qualified_code = self.qualify(declaration.code)
      let exists = self.entities.any(entity => {
        entity.qualified_code == qualified_code
      })
      if exists &&
        (
          declaration.kind is Map ||
          declaration.kind is Json ||
          line.trim().has_prefix("<>") ||
          line.trim().has_prefix("()") ||
          (declaration.kind is Object && !opens_body)
        ) {
        let kind = match declaration.kind {
          Map => "map"
          Json => "JSON"
          Diamond => "association"
          Interface if line.trim().has_prefix("()") => "interface"
          Object => "object"
          _ => "entity"
        }
        self.raise_parse_error("\{kind} already exists: \{declaration.code}")
      }
      let declaration = if exists && declaration.kind is Object && opens_body {
        let mut existing_kind = Object
        for entity in self.entities {
          if entity.qualified_code == qualified_code {
            existing_kind = entity.kind
            break
          }
        }
        { ..declaration, kind: existing_kind }
      } else {
        declaration
      }
      self.add_entity(declaration, opens_body)
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
          left_couple: None,
          right_couple: None,
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
          left_couple: None,
          right_couple: None,
        })
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
  // PlantUML accepts many global/style commands. They do not alter the core
  // class graph and are intentionally retained as no-op parser directives.
  if line.has_prefix("skinparam ") ||
    line.to_lower() == "allowmixing" ||
    line.to_lower() == "allow_mixing" ||
    line.to_lower().has_prefix("set namespace_separator ") ||
    line.to_lower().has_prefix("set namespaceseparator ") ||
    line.to_lower() == "footbox" ||
    line.to_lower() == "newpage" ||
    line.to_lower().has_prefix("newpage ") ||
    line.to_lower() == "layout newline" ||
    line.to_lower().has_prefix("left to right") ||
    line.to_lower().has_prefix("top to bottom") ||
    line.to_lower().has_prefix("title ") {
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
