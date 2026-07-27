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
  style : @core.DocumentStyle
  mut current_entity : Int?
  mut last_entity : String?
  mut namespace_separator : String?
  mut allow_mixing : Bool
  mut body_depth : Int
}

///|
fn Parser::new(input : String, allow_mixing? : Bool = false) -> Parser {
  {
    lines: @core.preprocess(input)
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
    style: @core.DocumentStyle::empty(),
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
) -> Unit raise @core.ParseError {
  let diagnostic = self.diagnostic(message)
  raise SyntaxError(diagnostic.line_number(), diagnostic.message)
}

///|
