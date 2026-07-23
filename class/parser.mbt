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
    let existing_reference = @core.syntax_words(line).length() == 1 &&
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
fn relation_shape(raw : String) -> (String, EntityKind)? {
  let value = raw.trim()
  if value.has_prefix("()") {
    Some((value[2:].trim().to_owned(), Interface))
  } else if value.length() >= 2 &&
    value.has_prefix("(") &&
    value.has_suffix(")") {
    Some((value[1:value.length() - 1].trim().to_owned(), Usecase))
  } else if value.length() >= 2 &&
    value.has_prefix(":") &&
    value.has_suffix(":") {
    Some((value[1:value.length() - 1].trim().to_owned(), Actor))
  } else if value.length() >= 2 &&
    value.has_prefix("[") &&
    value.has_suffix("]") {
    Some((value[1:value.length() - 1].trim().to_owned(), Component))
  } else {
    None
  }
}

///|
fn Parser::ensure_relation_entity(
  self : Parser,
  raw : String,
  endpoint : RelationEnd,
) -> String {
  match relation_shape(raw) {
    Some((code, kind)) => self.ensure_entity_as(normalize_name(code), kind)
    None if endpoint is Parenthesis => self.ensure_entity_as(raw, Interface)
    None => self.ensure_entity(raw)
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
  } else {
    self.ensure_relation_entity(left_name, left_end)
  }
  let right = if syntax.right.couple is Some((_, couple_right)) {
    self.ensure_entity(couple_right)
  } else {
    self.ensure_relation_entity(right_name, right_end)
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
  let marker = line.to_lower()
  guard marker != "@startuml" && marker != "@enduml" else { return }
  guard !@core.is_preprocessor_directive(line) else { return }
  if self.current_entity is Some(entity_index) {
    self.consume_entity_body_line(entity_index, line)
    return
  }
  match parse_class_line(line) {
    Some(syntax) => self.apply_class_line_syntax(syntax)
    None => self.raise_parse_error(line)
  }
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
