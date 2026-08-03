///|
priv enum ClassLineSyntax {
  ParsedAllowMixing
  ParsedPackageClose
  ParsedAnnotation(ClassAnnotationLineSyntax)
  ParsedFilter(FilterLineSyntax)
  ParsedCommand(ClassCommandLineSyntax)
  ParsedTextBlock(String)
  ParsedSkinparamBlock
  ParsedTogetherBlock
  ParsedMultilineElement(MultilineElementHeader)
  ParsedSingleLineJson(JsonSingleDeclaration)
  ParsedRelation(RelationLineSyntax)
  ParsedDeclaration(DeclarationLineSyntax)
  ParsedExternalMember(target~ : String, entry~ : Member)
  ParsedIgnoredDirective
}

///|
fn[T] validated_whole_line_parser(
  label : String,
  classify : (String) -> T?,
) -> @talc.StringParser[T] {
  @talc.many_chars1(@talc.satisfy(label, _ => true)).bind(line => {
    match classify(line) {
      Some(value) => @talc.pure(value)
      None => @talc.fail(label)
    }
  })
}

///|
fn class_control_line_parser() -> @talc.StringParser[ClassLineSyntax] {
  validated_whole_line_parser("class control line", line => {
    match line.to_lower() {
      "allowmixing" | "allow_mixing" => Some(ParsedAllowMixing)
      "}" | "};" | "end package" | "end namespace" => Some(ParsedPackageClose)
      "together {" => Some(ParsedTogetherBlock)
      value if value.has_prefix("skinparam") && line.has_suffix("{") =>
        Some(ParsedSkinparamBlock)
      _ => None
    }
  })
}

///|
fn ignored_class_directive_parser() -> @talc.StringParser[ClassLineSyntax] {
  validated_whole_line_parser("ignored class directive", line => {
    let lower = line.to_lower()
    if lower.has_prefix("skinparam ") ||
      lower.has_prefix("set namespace_separator ") ||
      lower.has_prefix("set namespaceseparator ") ||
      lower == "footbox" ||
      lower == "newpage" ||
      lower.has_prefix("newpage ") ||
      lower == "layout newline" ||
      lower.has_prefix("left to right") ||
      lower.has_prefix("top to bottom") ||
      lower.has_prefix("title ") {
      Some(ParsedIgnoredDirective)
    } else {
      None
    }
  })
}

///|
fn class_line_parser() -> @talc.StringParser[ClassLineSyntax] {
  @talc.choice([
    class_control_line_parser().attempt(),
    class_annotation_line_parser()
    .map(syntax => ParsedAnnotation(syntax))
    .attempt(),
    filter_line_parser().map(syntax => ParsedFilter(syntax)).attempt(),
    class_command_line_parser().map(syntax => ParsedCommand(syntax)).attempt(),
    text_block_header_parser()
    .map(keyword => ParsedTextBlock(keyword))
    .attempt(),
    multiline_element_header_parser()
    .map(header => ParsedMultilineElement(header))
    .attempt(),
    json_single_declaration_parser()
    .map(value => ParsedSingleLineJson(value))
    .attempt(),
    relation_line_parser().map(syntax => ParsedRelation(syntax)).attempt(),
    declaration_line_parser().map(syntax => ParsedDeclaration(syntax)).attempt(),
    external_member_line_parser()
    .map(value => {
      let (target, entry) = value
      ParsedExternalMember(target~, entry~)
    })
    .attempt(),
    ignored_class_directive_parser(),
  ]).skip(@talc.eof())
}

///|
fn parse_class_line(line : String) -> ClassLineSyntax? {
  match class_line_parser().parse(@talc.Input::new(line)) {
    Ok(syntax) => Some(syntax)
    Err(_) => None
  }
}

///|
fn Parser::apply_declaration_syntax(
  self : Parser,
  syntax : DeclarationLineSyntax,
) -> Unit raise @parse.ParseError {
  let declaration = syntax.declaration
  let is_usecase_element = declaration.kind is Usecase ||
    declaration.kind is BusinessUsecase ||
    declaration.kind is Actor ||
    declaration.kind is BusinessActor
  guard native_class_kind(declaration.kind) ||
    is_usecase_element ||
    self.allow_mixing ||
    syntax.mix_prefixed else {
    self.raise_parse_error(
      "use allowmixing to mix classes and other UML elements",
    )
  }
  let qualified_code = self.qualify(declaration.code)
  let exists = self.has_entity(qualified_code)
  if exists &&
    (
      declaration.kind is Map ||
      declaration.kind is Json ||
      declaration.kind is Diamond ||
      (syntax.symbol && declaration.kind is Interface) ||
      (declaration.kind is Object && !syntax.opens_body)
    ) {
    let kind = match declaration.kind {
      Map => "map"
      Json => "JSON"
      Diamond => "association"
      Interface if syntax.symbol => "interface"
      Object => "object"
      _ => "entity"
    }
    self.raise_parse_error("\{kind} already exists: \{declaration.code}")
  }
  let declaration = if exists && declaration.kind is Object && syntax.opens_body {
    let existing_kind = match self.entity_index(qualified_code) {
      Some(index) => self.entities[index].kind
      None => Object
    }
    { ..declaration, kind: existing_kind }
  } else {
    declaration
  }
  self.add_entity(declaration, syntax.opens_body)
  for parent in declaration.extends {
    let child = self.resolve(declaration.code)
    let parent_kind = if declaration.kind is Interface {
      Interface
    } else {
      Class
    }
    let parent = self.ensure_entity_as(parent, parent_kind)
    self.relations.push({
      left: parent,
      right: child,
      kind: Extension,
      left_cardinality: None,
      right_cardinality: None,
      left_role: None,
      right_role: None,
      left_qualifier: None,
      right_qualifier: None,
      label: None,
      dotted: false,
      raw_arrow: "<|--",
      left_end: Extension,
      right_end: Plain,
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
      left: interface,
      right: child,
      kind: Realization,
      left_cardinality: None,
      right_cardinality: None,
      left_role: None,
      right_role: None,
      left_qualifier: None,
      right_qualifier: None,
      label: None,
      dotted: true,
      raw_arrow: "<|..",
      left_end: Extension,
      right_end: Plain,
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
}

///|
fn Parser::apply_class_line_syntax(
  self : Parser,
  syntax : ClassLineSyntax,
) -> Unit raise @parse.ParseError {
  match syntax {
    ParsedAllowMixing => self.allow_mixing = true
    ParsedPackageClose => {
      guard !self.package_stack.is_empty() else {
        self.raise_parse_error("unexpected package end")
      }
      let _ = self.package_stack.pop()
    }
    ParsedAnnotation(value) => self.apply_annotation_syntax(value)
    ParsedFilter(value) => self.apply_filter_syntax(value)
    ParsedCommand(value) => self.apply_class_command(value)
    ParsedTextBlock(keyword) => self.consume_text_block(keyword)
    ParsedSkinparamBlock => self.consume_skinparam_block()
    ParsedTogetherBlock => self.consume_braced_block("together")
    ParsedMultilineElement(header) => self.consume_multiline_element(header)
    ParsedSingleLineJson(value) => self.add_single_line_json(value)
    ParsedRelation(value) => self.apply_relation_syntax(value)
    ParsedDeclaration(value) => self.apply_declaration_syntax(value)
    ParsedExternalMember(target~, entry~) => self.add_member_to(target, entry)
    ParsedIgnoredDirective => ()
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
) -> Unit raise @parse.ParseError {
  self.index += 1
  let text = StringBuilder()
  let mut first = true
  while self.index < self.lines.length() {
    if text_block_end(@parse.strip_line_comment(self.lines[self.index]), keyword) {
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
) -> Unit raise @parse.ParseError {
  let package_depth = self.package_stack.length()
  self.index += 1
  while self.index < self.lines.length() {
    let line = @parse.strip_line_comment(self.lines[self.index])
    if line == "}" && self.package_stack.length() == package_depth {
      return
    }
    let reference = @parse.unquote_identifier(line)
    let existing_reference = @parse.syntax_words(line).length() == 1 &&
      (self.has_entity(self.resolve(reference)) || self.has_entity(reference))
    if !existing_reference {
      self.parse_line(self.lines[self.index])
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed \{kind}")
}

///|
fn Parser::consume_skinparam_block(
  self : Parser,
) -> Unit raise @parse.ParseError {
  self.index += 1
  let closed = @style.consume_skinparam_body(
    fn() {
      guard self.index < self.lines.length() else { return None }
      let line = @parse.strip_line_comment(self.lines[self.index])
      if line.trim() != "}" {
        self.index += 1
      }
      Some(line)
    },
    fn(directive) { self.style.apply(directive) },
  )
  guard closed else { self.raise_parse_error("unclosed skinparam") }
}

///|
fn Parser::consume_common_block(
  self : Parser,
  terminator : String,
) -> Unit raise @parse.ParseError {
  self.index += 1
  while self.index < self.lines.length() {
    if @parse.strip_line_comment(self.lines[self.index]).to_lower() == terminator {
      return
    }
    self.index += 1
  }
  self.raise_parse_error("unclosed common definition block")
}
