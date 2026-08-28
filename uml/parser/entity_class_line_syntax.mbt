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
  ParsedExternalMember(target~ : String, entry~ : @entity.Member)
  ParsedIgnoredDirective
}

///|
fn[T] validated_whole_line(
  cursor : @tokenizer.Cursor,
  classify : (String) -> T?,
) -> T? {
  let start = cursor.offset()
  let line = cursor.take_rest()
  ignore(cursor.restore(start))
  if line.length() == 0 {
    None
  } else {
    classify(line)
  }
}

///|
fn class_control_line(cursor : @tokenizer.Cursor) -> ClassLineSyntax? {
  validated_whole_line(cursor, line => {
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
fn ignored_class_directive(cursor : @tokenizer.Cursor) -> ClassLineSyntax? {
  validated_whole_line(cursor, line => {
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
fn class_line(cursor : @tokenizer.Cursor) -> ClassLineSyntax? {
  let start = cursor.offset()
  if class_control_line(cursor) is Some(value) {
    return Some(value)
  }
  if class_annotation_line(cursor) is Some(value) {
    return Some(ParsedAnnotation(value))
  }
  if filter_line(cursor) is Some(value) {
    return Some(ParsedFilter(value))
  }
  if class_command_line(cursor) is Some(value) {
    return Some(ParsedCommand(value))
  }
  if text_block_header(cursor) is Some(value) {
    return Some(ParsedTextBlock(value))
  }
  if multiline_element_header(cursor) is Some(value) {
    return Some(ParsedMultilineElement(value))
  }
  if json_single_declaration(cursor) is Some(value) {
    return Some(ParsedSingleLineJson(value))
  }
  if relation_line(cursor) is Some(value) {
    return Some(ParsedRelation(value))
  }
  if declaration_line(cursor) is Some(value) {
    return Some(ParsedDeclaration(value))
  }
  if external_member_line(cursor) is Some(value) {
    let (target, entry) = value
    return Some(ParsedExternalMember(target~, entry~))
  }
  if ignored_class_directive(cursor) is Some(value) {
    return Some(value)
  }
  ignore(cursor.restore(start))
  None
}

///|
fn parse_class_line(line : String) -> ClassLineSyntax? {
  let cursor = @tokenizer.Cursor::new(line)
  class_line(cursor)
}

///|
fn EntityParser::apply_declaration_syntax(
  self : EntityParser,
  syntax : DeclarationLineSyntax,
) -> Unit raise @tokenizer.ParseError {
  let declaration = syntax.declaration
  let is_usecase_element = declaration.kind is @entity.EntityKind::Usecase ||
    declaration.kind is @entity.EntityKind::BusinessUsecase ||
    declaration.kind is @entity.EntityKind::Actor ||
    declaration.kind is @entity.EntityKind::BusinessActor
  guard native_class_kind(declaration.kind) ||
    is_usecase_element ||
    self.allow_mixing ||
    syntax.mix_prefixed else {
    self.raise_parse_error(
      "use allowmixing to mix classes and other UML elements",
    )
  }
  if self.family.capability().description_only {
    // The Java description factory accepts only its registered symbol
    // keywords; everything else is a syntax error, and `{` bodies exist only
    // for `CommandPackageWithUSymbol` groups, which never reach this path.
    guard declaration.kind.is_description_kind() &&
      !syntax.opens_body &&
      !syntax.mix_prefixed else {
      self.raise_parse_error("Syntax Error? (Assumed diagram type: component)")
    }
  }
  let qualified_code = self.qualify(declaration.code)
  let exists = self.has_entity(qualified_code)
  if exists &&
    (
      declaration.kind is Map ||
      declaration.kind is Json ||
      declaration.kind is Diamond ||
      (syntax.symbol && declaration.kind is @entity.EntityKind::Interface) ||
      (declaration.kind is @entity.EntityKind::Object && !syntax.opens_body)
    ) {
    let kind = match declaration.kind {
      Map => "map"
      Json => "JSON"
      Diamond => "association"
      @entity.EntityKind::Interface if syntax.symbol => "interface"
      @entity.EntityKind::Object => "object"
      _ => "entity"
    }
    self.raise_parse_error("\{kind} already exists: \{declaration.code}")
  }
  let declaration = if exists &&
    declaration.kind is @entity.EntityKind::Object &&
    syntax.opens_body {
    let existing_kind = self
      .entity_index(qualified_code)
      .map_or(@entity.EntityKind::Object, index => self.entities[index].kind)
    { ..declaration, kind: existing_kind, }
  } else {
    declaration
  }
  self.add_entity(declaration, syntax.opens_body)
  let child = self.resolve(declaration.code)
  for parent in declaration.extends {
    let parent_kind = if declaration.kind is @entity.EntityKind::Interface {
      @entity.EntityKind::Interface
    } else {
      Class
    }
    let parent = self.ensure_entity_as(parent, parent_kind)
    self.relations.push(
      @entity.Relation::new(
        parent,
        child,
        @entity.RelationKind::Extension,
        "<|--",
        @entity.RelationEnd::Extension,
        @entity.RelationEnd::Plain,
      ),
    )
  }
  for interface in declaration.implements {
    let interface = self.ensure_entity_as(
      interface,
      @entity.EntityKind::Interface,
    )
    self.relations.push(
      @entity.Relation::new(
        interface,
        child,
        @entity.RelationKind::Realization,
        "<|..",
        @entity.RelationEnd::Extension,
        @entity.RelationEnd::Plain,
      ),
    )
  }
}

///|
fn EntityParser::apply_class_line_syntax(
  self : EntityParser,
  syntax : ClassLineSyntax,
) -> Unit raise @tokenizer.ParseError {
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
fn entity_note_position(word : String) -> @entity.NotePosition? {
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
  let value = line.to_lower()
  value == "end " + keyword || value == "end" + keyword
}

///|
fn EntityParser::consume_text_block(
  self : EntityParser,
  keyword : String,
) -> Unit raise @tokenizer.ParseError {
  self.buffer.advance()
  let text = StringBuilder()
  let mut first = true
  while !self.buffer.at_end() {
    if text_block_end(self.buffer.current_stripped(), keyword) {
      self.style.apply(TextBlock(keyword, text.to_string()))
      return
    }
    if !first {
      text.write_char('\n')
    }
    text.write_string(self.buffer.current())
    first = false
    self.buffer.advance()
  }
  self.raise_parse_error("unclosed \{keyword}")
}

///|
fn EntityParser::consume_braced_block(
  self : EntityParser,
  kind : String,
) -> Unit raise @tokenizer.ParseError {
  let package_depth = self.package_stack.length()
  self.buffer.advance()
  let members : Array[String] = []
  while !self.buffer.at_end() {
    let line = self.buffer.current_stripped()
    if line == "}" && self.package_stack.length() == package_depth {
      if kind == "together" {
        self.together_groups.push(members)
      }
      return
    }
    let reference = @tokenizer.unquote_identifier(line)
    let existing_reference = @tokenizer.syntax_words(line).length() == 1 &&
      (self.has_entity(self.resolve(reference)) || self.has_entity(reference))
    if !existing_reference {
      self.parse_line(self.buffer.current())
      if self.last_entity is Some(code) {
        if !members.contains(code) {
          members.push(code)
        }
      }
    } else {
      let resolved = self.resolve(reference)
      if !members.contains(resolved) {
        members.push(resolved)
      }
    }
    self.buffer.advance()
  }
  self.raise_parse_error("unclosed \{kind}")
}

///|
fn EntityParser::consume_skinparam_block(
  self : EntityParser,
) -> Unit raise @tokenizer.ParseError {
  self.buffer.advance()
  let closed = @style.consume_skinparam_body(
    () => {
      guard !self.buffer.at_end() else { return None }
      let line = self.buffer.current_stripped()
      if line.trim() != "}" {
        self.buffer.advance()
      }
      Some(line)
    },
    directive => self.style.apply(directive),
  )
  guard closed else { self.raise_parse_error("unclosed skinparam") }
}

///|
fn EntityParser::consume_common_block(
  self : EntityParser,
  terminator : String,
) -> Unit raise @tokenizer.ParseError {
  self.buffer.advance()
  while !self.buffer.at_end() {
    if self.buffer.current_stripped().to_lower() == terminator {
      return
    }
    self.buffer.advance()
  }
  self.raise_parse_error("unclosed common definition block")
}
