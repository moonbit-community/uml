///|
fn Parser::finish_entity(self : Parser) -> Unit {
  self.current_entity = None
  self.body_depth = 0
}

///|
fn Parser::parse_line(
  self : Parser,
  line : String,
) -> Unit raise @parse.ParseError {
  let line = @parse.strip_line_comment(line).trim().to_owned()
  guard line.length() > 0 else { return }
  match @parse.common_block_terminator(line) {
    Some(terminator) => {
      self.consume_common_block(terminator)
      return
    }
    None => ()
  }
  match @parse.parse_namespace_separator(line) {
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
  match @style.parse_style_directive(line) {
    Some(directive) => {
      self.style.apply(directive)
      return
    }
    None => ()
  }
  let marker = line.to_lower()
  guard marker != "@startuml" && marker != "@enduml" else { return }
  guard !@style.is_preprocessor_directive(line) else { return }
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
fn parse_with_family(input : String, family : EntityFamily) -> EntityDiagram raise @parse.ParseError {
  let parser = Parser::new(input, allow_mixing=family.allow_mixing())
  while parser.index < parser.lines.length() {
    let line = parser.lines[parser.index]
    parser.parse_line(line)
    parser.index += 1
  }
  guard parser.current_entity is None else {
    raise SyntaxError(parser.line_number(), family.unclosed_body_message())
  }
  guard parser.package_stack.is_empty() else {
    raise SyntaxError(parser.line_number(), "unclosed package")
  }
  parser.apply_filter_rules()
  {
    family,
    entities: parser.entities,
    relations: parser.relations,
    packages: parser.packages,
    notes: parser.notes,
    constraints: parser.constraints,
    style: parser.style,
  }
}

///|
/// Parse the shared entity-diagram grammar for the given diagram family.
///
/// The family selects both the mixing policy and, at render time, the SVG
/// symbols, so diagram-family packages no longer wrap this entry point.
pub fn parse(
  input : String,
  family? : EntityFamily = ClassDiagram,
) -> EntityDiagram raise @parse.ParseError {
  parse_with_family(input, family)
}

///|
priv struct Parser {
  lines : Array[String]
  mut index : Int
  package_stack : Array[String]
  entities : Array[Entity]
  entity_indices : Map[String, Int]
  entity_code_indices : Map[String, Int]
  ambiguous_entity_codes : Map[String, Unit]
  relations : Array[Relation]
  packages : Array[Package]
  notes : Array[Note]
  constraints : Array[LinkConstraint]
  entity_rules : Array[EntityRule]
  portion_rules : Array[PortionRule]
  style : @style.DocumentStyle
  mut current_entity : Int?
  mut last_entity : String?
  mut namespace_separator : String?
  mut allow_mixing : Bool
  mut body_depth : Int
}

///|
fn Parser::new(input : String, allow_mixing? : Bool = false) -> Parser {
  {
    lines: @parse.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array(),
    index: 0,
    package_stack: [],
    entities: [],
    entity_indices: Map([]),
    entity_code_indices: Map([]),
    ambiguous_entity_codes: Map([]),
    relations: [],
    packages: [],
    notes: [],
    constraints: [],
    entity_rules: [],
    portion_rules: [],
    style: @style.DocumentStyle::empty(),
    current_entity: None,
    last_entity: None,
    namespace_separator: Some("."),
    allow_mixing,
    body_depth: 0,
  }
}

///|
fn Parser::current_package(self : Parser) -> String {
  self.package_stack.join(".")
}

///|
fn Parser::line_number(self : Parser) -> Int {
  @parse.line_span(self.index + 1).line
}

///|
fn Parser::diagnostic(self : Parser, message : String) -> @parse.ParseDiagnostic {
  @parse.diagnostic_at_line(self.line_number(), message)
}

///|
fn Parser::raise_parse_error(
  self : Parser,
  message : String,
) -> Unit raise @parse.ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}
