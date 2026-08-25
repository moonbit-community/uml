///|
fn EntityParser::finish_entity(self : EntityParser) -> Unit {
  self.current_entity = None
  self.body_depth = 0
}

///|
fn EntityParser::parse_line(
  self : EntityParser,
  line : String,
) -> Unit raise @tokenizer.ParseError {
  let line = @tokenizer.strip_line_comment(line).trim().to_owned()
  guard line.length() > 0 else { return }
  match @tokenizer.common_block_terminator(line) {
    Some(terminator) => {
      self.consume_common_block(terminator)
      return
    }
    None => ()
  }
  match @tokenizer.parse_namespace_separator(line) {
    Some(separator) => {
      self.namespace_separator = separator
      self.style.apply(
        Property("namespace separator", separator.unwrap_or("none")),
      )
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
  guard parse_class_line(line) is Some(syntax) else {
    self.raise_parse_error(line)
  }
  self.apply_class_line_syntax(syntax)
}

///|
fn parse_with_family(
  input : String,
  family : @entity.EntityFamily,
) -> @entity.EntityDiagram raise @tokenizer.ParseError {
  let parser = EntityParser::new(
    input,
    allow_mixing=family.allow_mixing(),
    family~,
  )
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
    together_groups: parser.together_groups,
    style: parser.style,
  }
}

///|
/// Parse the shared entity-diagram grammar for the given diagram family.
///
/// The family selects both the mixing policy and, at render time, the SVG
/// symbols, so diagram-family packages no longer wrap this entry point.
pub fn parse_entity(
  input : String,
  family? : @entity.EntityFamily = ClassDiagram,
) -> @entity.EntityDiagram raise @tokenizer.ParseError {
  parse_with_family(input, family)
}

///|
priv struct EntityParser {
  lines : Array[String]
  mut index : Int
  package_stack : Array[String]
  entities : Array[@entity.Entity]
  entity_indices : Map[String, Int]
  entity_code_indices : Map[String, Int]
  ambiguous_entity_codes : Map[String, Unit]
  relations : Array[@entity.Relation]
  packages : Array[@entity.Package]
  notes : Array[@entity.Note]
  constraints : Array[@entity.LinkConstraint]
  entity_rules : Array[@entity.EntityRule]
  portion_rules : Array[@entity.PortionRule]
  style : @style.DocumentStyle
  mut current_entity : Int?
  mut last_entity : String?
  mut namespace_separator : String?
  mut allow_mixing : Bool
  family : @entity.EntityFamily
  mut body_depth : Int
  mut synthetic_sequence : Int
  together_groups : Array[Array[String]]
}

///|
fn EntityParser::new(
  input : String,
  allow_mixing? : Bool = false,
  family? : @entity.EntityFamily = ClassDiagram,
) -> EntityParser {
  {
    lines: @tokenizer.preprocess(input)
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
    family,
    body_depth: 0,
    synthetic_sequence: 0,
    together_groups: [],
  }
}

///|
fn EntityParser::current_package(self : EntityParser) -> String {
  self.package_stack.join(".")
}

///|
fn EntityParser::line_number(self : EntityParser) -> Int {
  @tokenizer.line_span(self.index + 1).line
}

///|
fn EntityParser::diagnostic(
  self : EntityParser,
  message : String,
) -> @tokenizer.ParseDiagnostic {
  @tokenizer.diagnostic_at_line(self.line_number(), message)
}

///|
fn[A] EntityParser::raise_parse_error(
  self : EntityParser,
  message : String,
) -> A raise @tokenizer.ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}
