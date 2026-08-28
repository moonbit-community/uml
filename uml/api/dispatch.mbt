///|
fn meaningful_source_lines(input : String) -> Array[String] {
  input
  .split("\n")
  .map(line => @tokenizer.strip_line_comment(line.to_owned()).trim().to_owned())
  .filter(line => {
    line.length() > 0 &&
    !line.equal_ignore_ascii_case("@startuml") &&
    !line.equal_ignore_ascii_case("@enduml") &&
    !@style.is_preprocessor_directive(line)
  })
  .to_array()
}

///|
fn starts_with_keyword(line : String, keywords : FixedArray[String]) -> Bool {
  let words = @tokenizer.syntax_words(line)
  words.length() > 0 && keywords.contains(words[0].to_lower())
}

///|
fn is_sequence_command(line : String) -> Bool {
  let lower = line.to_lower()
  let words = @tokenizer.syntax_words(line)
  let grouping_keyword = match words {
    ["&", keyword, ..] | [keyword, ..] =>
      sequence_grouping_keywords.contains(keyword.to_lower()) &&
      // An activity `partition Name {` opens a block; sequence partitions are
      // single-line groups closed by `end`.
      !(keyword.equal_ignore_ascii_case("partition") && line.contains(" {"))
    _ => false
  }
  lower == "autonewpage" ||
  grouping_keyword ||
  lower.has_prefix("participant ") ||
  lower.has_prefix("create ") ||
  lower.has_prefix("box ") ||
  lower.has_prefix("autonumber") ||
  lower.has_prefix("autoactivate") ||
  lower.has_prefix("activate ") ||
  lower.has_prefix("deactivate") ||
  lower.has_prefix("destroy ") ||
  lower.has_prefix("hnote ") ||
  lower.has_prefix("rnote ") ||
  lower.has_prefix("ref over ") ||
  lower.has_prefix("ignore newpage") ||
  lower == "hide footbox" ||
  lower == "show footbox" ||
  lower.has_prefix("==") ||
  lower.has_prefix("...")
}

///|
fn is_ambiguous_participant_declaration(line : String) -> Bool {
  starts_with_keyword(line, participant_shape_keywords)
}

///|
fn has_message_arrow(line : String) -> Bool {
  @tokenizer.find_unquoted_literal(line, "->") is Some(_) ||
  @tokenizer.find_unquoted_literal(line, "<-") is Some(_)
}

///|
fn has_component_declaration(line : String) -> Bool {
  starts_with_keyword(line, component_keywords)
}

///|
/// Whether a line declares a use-case element: a `usecase`/`actor`
/// declaration, a `(usecase)` or `:actor:` shape, or a relation pointing at
/// such a shape. An association-class declaration `(A, B) -- C` is a class
/// construct and is excluded.
fn is_usecase_element(line : String) -> Bool {
  starts_with_keyword(line, actor_keywords) || has_usecase_declaration(line)
}

///|
/// A use-case construct that excludes a source from the sequence grammar: a
/// `usecase` declaration or a `(shape)`/`:actor:` leaf. Bare `actor`
/// declarations stay ambiguous (sequence participant vs use-case actor) and
/// are resolved by the message arrows.
fn has_usecase_declaration(line : String) -> Bool {
  let trimmed = line.trim().to_owned()
  starts_with_keyword(line, usecase_keywords) ||
  (
    trimmed.has_prefix("(") &&
    !trimmed.has_prefix("()") &&
    !is_association_class_declaration(trimmed)
  ) ||
  is_actor_shape(trimmed) ||
  trimmed.contains(">(") ||
  trimmed.contains("> (")
}

///|
/// Whether the line starts with a `:actor:` shape.
fn is_actor_shape(line : String) -> Bool {
  guard line.has_prefix(":") else { return false }
  let cursor = @tokenizer.Cursor::new(line)
  ignore(cursor.advance())
  ignore(cursor.skip_while(char => char != ':'))
  cursor.consume(':')
}

///|
/// An association-class declaration `(A, B) -- C` starts with a parenthesis
/// pair but belongs to the class grammar: the pair contains a comma and a
/// relation arrow follows it.
fn is_association_class_declaration(line : String) -> Bool {
  let trimmed = line.trim().to_owned()
  guard trimmed.has_prefix("(") else { return false }
  let cursor = @tokenizer.Cursor::new(trimmed)
  ignore(cursor.advance())
  let mut comma = false
  while cursor.peek() is Some(char) && char != ')' {
    if char == ',' {
      comma = true
    }
    ignore(cursor.advance())
  }
  guard comma && cursor.consume(')') else { return false }
  ignore(cursor.skip_while(char => char.is_whitespace()))
  cursor
  .peek()
  .map_or(false, char => {
    char == '-' || char == '.' || char == '<' || char == '>'
  })
}

///|
/// These arrow forms are sequence-message syntax, never class relations.
fn has_sequence_only_message_arrow(line : String) -> Bool {
  sequence_message_arrows.any(arrow => {
    @tokenizer.find_unquoted_literal(line, arrow) is Some(_)
  })
}

///|
fn is_class_declaration(line : String) -> Bool {
  starts_with_keyword(line, class_keywords)
}

///|
/// Returns whether the source selects PlantUML's state-diagram factory.
///
/// `frame X {` bodies claim the source only through their state content:
/// PlantUML's description factory wins for a bare `frame X`, while a frame
/// wrapping `state` declarations stays a state diagram.
pub fn is_state_source(input : String) -> Bool {
  for line in meaningful_source_lines(input) {
    let lower = line.to_lower()
    if lower.has_prefix("state ") ||
      state_start_markers.contains(line) ||
      line.has_prefix("[*] ") ||
      line.has_suffix(" [*]") {
      return true
    }
  }
  false
}

///|
fn is_object_declaration(line : String) -> Bool {
  starts_with_keyword(line, object_keywords)
}

///|
/// Returns whether the source contains a sequence-diagram-specific command.
///
/// This deliberately covers commands that cannot be inferred from an arrow
/// alone: a sequence reply such as `A --> B` otherwise looks like a class
/// relation to the class-diagram heuristic.
pub fn is_sequence_source(input : String) -> Bool {
  let lines = meaningful_source_lines(input)
  !lines.any(has_component_declaration) &&
  !lines.any(has_usecase_declaration) &&
  !lines.any(line => {
    is_class_declaration(line) && !is_ambiguous_participant_declaration(line)
  }) &&
  (
    lines.any(is_sequence_command) ||
    lines.any(has_sequence_only_message_arrow) ||
    (
      lines.any(is_ambiguous_participant_declaration) &&
      lines.any(has_message_arrow)
    )
  )
}

///|
/// The entity-grammar family a source line belongs to. Lines are classified
/// once per scan and aggregated by `entity_family_from_lines`, mirroring
/// PlantUML's per-factory command lists without reparsing the source.
priv enum EntityLineKind {
  MixingDirective
  ClassOnlyDeclaration
  ObjectDeclaration
  ComponentDeclaration
  UseCaseDeclaration
  DeploymentDeclaration
  RelationLine
  CommonLine
}

///|
fn has_deployment_declaration(line : String) -> Bool {
  starts_with_keyword(line, deployment_keywords)
}

///|
fn is_mixing_directive(line : String) -> Bool {
  let lower = line.to_lower()
  lower == "allowmixing" || lower == "allow_mixing"
}

///|
fn is_class_only_declaration(line : String) -> Bool {
  starts_with_keyword(line, class_only_keywords)
}

///|
fn has_component_arrow(line : String) -> Bool {
  let trimmed = line.trim().to_owned()
  trimmed.has_prefix("[") &&
  (
    has_message_arrow(trimmed) ||
    @tokenizer.find_unquoted_literal(trimmed, "--") is Some(_)
  )
}

///|
/// Classifies a line in a single scan. Keyword and shape checks are ordered
/// by specificity: association classes and class-only keywords beat shapes,
/// and `usecase`/`actor`/`(...)` leaves beat plain deployment keywords.
fn classify_entity_line(line : String) -> EntityLineKind {
  if is_mixing_directive(line) {
    return MixingDirective
  }
  if is_association_class_declaration(line) ||
    is_class_only_declaration(line) ||
    line.trim().has_prefix("<>") ||
    line.trim().to_lower().has_prefix("mix_") {
    return ClassOnlyDeclaration
  }
  if is_object_declaration(line) {
    return ObjectDeclaration
  }
  if has_component_declaration(line) || has_component_arrow(line) {
    return ComponentDeclaration
  }
  if is_usecase_element(line) {
    return UseCaseDeclaration
  }
  if has_deployment_declaration(line) {
    return DeploymentDeclaration
  }
  if class_relation_arrows.any(arrow => {
      @tokenizer.find_unquoted_literal(line, arrow) is Some(_)
    }) {
    return RelationLine
  }
  CommonLine
}

///|
/// Selects the entity-grammar family of a source in a single scan.
///
/// The aggregation mirrors PlantUML's factory order: the class grammar wins
/// with `allowmixing` or any class-only declaration (a mixing source then
/// reports the class facade's mixing error), and description elements are
/// split into the use-case, component, and deployment facades by the
/// strongest element present.
fn entity_family_from_lines(lines : Array[String]) -> @entity.EntityFamily? {
  let mut mixing = false
  let mut class_only = false
  let mut object = false
  let mut component = false
  let mut usecase = false
  let mut deployment = false
  let mut relation = false
  for line in lines {
    match classify_entity_line(line) {
      MixingDirective => mixing = true
      ClassOnlyDeclaration => class_only = true
      ObjectDeclaration => object = true
      ComponentDeclaration => component = true
      UseCaseDeclaration => usecase = true
      DeploymentDeclaration => deployment = true
      RelationLine => relation = true
      CommonLine => ()
    }
  }
  if mixing || class_only {
    return Some(@entity.ClassDiagram)
  }
  if usecase && !component && !deployment {
    return Some(@entity.UseCaseDiagram)
  }
  if component {
    return Some(@entity.ComponentDiagram)
  }
  if deployment {
    return Some(@entity.DeploymentDiagram)
  }
  if object {
    return Some(@entity.ObjectDiagram)
  }
  // A source with only relations and common lines belongs to the class
  // grammar, which PlantUML tries before the description factory.
  if relation {
    return Some(@entity.ClassDiagram)
  }
  None
}

///|
/// Returns whether the source starts with a `@startX` diagram marker.
///
/// Shared by the structured and dot dispatch predicates below; use this
/// helper (or the `is_*_source` wrappers) instead of re-checking the marker
/// prefix locally.
fn has_start_marker(input : String, marker : String) -> Bool {
  input.trim().to_lower().has_prefix(marker)
}

///|
/// Returns whether the source uses PlantUML's JSON diagram delimiters.
pub fn is_json_source(input : String) -> Bool {
  has_start_marker(input, "@startjson")
}

///|
/// Returns whether the source uses PlantUML's YAML diagram delimiters.
pub fn is_yaml_source(input : String) -> Bool {
  has_start_marker(input, "@startyaml")
}

///|
/// Returns whether the source uses this project's TOML diagram delimiters.
pub fn is_toml_source(input : String) -> Bool {
  has_start_marker(input, "@starttoml")
}

///|
/// Returns whether the source uses PlantUML's DOT diagram delimiters.
pub fn is_dot_source(input : String) -> Bool {
  has_start_marker(input, "@startdot")
}

///|
/// Returns whether the document explicitly selects PlantUML's mindmap factory.
pub fn is_mindmap_source(input : String) -> Bool {
  input
  .split("\n")
  .any(line => line.trim().equal_ignore_ascii_case("@startmindmap"))
}

///|
/// Returns whether the source selects PlantUML's activity-diagram parser.
pub fn is_activity_source(input : String) -> Bool {
  let lines = meaningful_source_lines(input)
  input
  .split("\n")
  .any(line => line.trim().equal_ignore_ascii_case("@startactivity")) ||
  lines.any(line => {
    let lower = line.to_lower()
    activity_commands.contains(lower) ||
    activity_command_prefixes.any(prefix => lower.has_prefix(prefix)) ||
    (line.has_prefix(":") && line.has_suffix(";"))
  })
}

///|
/// Sequence-diagram grouping keywords.
pub let sequence_grouping_keywords : FixedArray[String] = [
  "opt", "alt", "loop", "par", "par2", "break", "critical", "group", "partition",
]

///|
/// Participant shape keywords shared by the sequence and entity grammars.
pub let participant_shape_keywords : FixedArray[String] = [
  "actor", "boundary", "control", "entity", "database", "queue", "collections", "port",
  "portin", "portout", "participant",
]

///|
/// Keywords that unambiguously select PlantUML's component grammar.
///
/// `boundary`, `control`, `collections`, `port`, and friends are deliberately
/// excluded: they are sequence-diagram participant shapes first, and PlantUML
/// resolves such declarations as sequence participants even without messages.
pub let component_keywords : FixedArray[String] = ["component"]

///|
/// Keywords that select PlantUML's description grammar, the factory behind
/// deployment diagrams.
///
/// This is PlantUML's `CommandCreateElementFull.ALL_TYPES` minus the keywords
/// claimed earlier by the sequence, use-case, and component heuristics, and
/// minus the class-native kinds (`class`, `entity`, `interface`, `circle`, ...)
/// which PlantUML's class factory accepts without `allowmixing`. With
/// `allowmixing` present the class factory wins in PlantUML, so those sources
/// stay class diagrams.
pub let deployment_keywords : FixedArray[String] = [
  "node", "folder", "frame", "cloud", "storage", "agent", "artifact", "card", "rectangle",
  "hexagon", "label", "action", "process", "stack", "file", "person",
]

///|
/// Keywords that only PlantUML's class factory parses, never its description
/// factory. A source mixing them with description declarations stays an
/// error unless `allowmixing` moves it to the class grammar.
pub let class_only_keywords : FixedArray[String] = [
  "class", "enum", "annotation", "exception", "metaclass", "stereotype", "dataclass",
  "record", "struct", "protocol", "abstract",
]

///|
/// Keywords that select PlantUML's class-diagram grammar.
pub let class_keywords : FixedArray[String] = [
  "class", "interface", "enum", "annotation", "abstract", "object", "entity", "exception",
  "metaclass", "stereotype", "dataclass", "record", "map", "json", "component", "database",
  "queue", "actor", "usecase", "struct", "protocol", "state", "folder", "file", "node",
  "cloud", "person", "artifact", "boundary", "control", "port", "portin", "portout",
  "package", "namespace", "rectangle", "hexagon", "label", "frame", "action", "process",
  "stack", "storage", "agent", "collections",
]

///|
/// Keywords that select the object facade over the class grammar.
pub let object_keywords : FixedArray[String] = ["object", "map", "json"]

///|
/// Keywords that select PlantUML's use-case grammar.
pub let usecase_keywords : FixedArray[String] = ["usecase", "usecase/"]

///|
/// Actor keywords of the use-case grammar (`CommandCreateElementFull.ALL_TYPES`).
pub let actor_keywords : FixedArray[String] = ["actor", "actor/"]

///|
/// Arrow dressings that only sequence-message syntax uses.
pub let sequence_message_arrows : FixedArray[String] = [
  "->>", "<<-", "\\->", "\\-->", "/->", "/-->",
]

///|
/// Dotted and dashed arrows that select the class grammar.
pub let class_relation_arrows : FixedArray[String] = [
  "--", "..", "<|", ".>", "<.",
]

///|
/// Activity-diagram commands that stand alone on a line.
pub let activity_commands : FixedArray[String] = [
  "start", "stop", "endif", "endwhile", "repeat", "fork", "fork again", "end fork",
  "endfork", "endswitch", "else",
]

///|
/// Activity-diagram commands that prefix a line.
///
/// `label` is deliberately excluded: PlantUML's description factory parses a
/// bare `label X` as an element declaration, while activity diagrams reach the
/// label command through their other markers (`:work;`, `start`, ...).
pub let activity_command_prefixes : FixedArray[String] = [
  "repeat while ", "if ", "elseif ", "else ", "while ", "switch ", "case ", "goto ",
]

///|
/// State-diagram start markers.
pub let state_start_markers : FixedArray[String] = ["[*]", "[H]", "[H*]"]
