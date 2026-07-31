///|
/// The parsed PlantUML document. Diagram-specific state stays in its own package.
pub enum Diagram {
  Sequence(@sequence.SequenceDiagram)
  Activity(@activity.ActivityDiagram)
  Class(@entity.EntityDiagram)
  Object(@entity.EntityDiagram)
  Component(@entity.EntityDiagram)
  UseCase(@entity.EntityDiagram)
  State(@state.StateDiagram)
  Mindmap(@mindmap.MindmapDiagram)
  Json(@nonuml.StructuredDiagram)
  Yaml(@nonuml.StructuredDiagram)
  Toml(@nonuml.StructuredDiagram)
}

///|
pub struct Document {
  diagram : Diagram
}

///|
pub fn Document::kind(self : Document) -> @core.DiagramKind {
  match self.diagram {
    Sequence(_) => Sequence
    Activity(_) => Activity
    Class(_) => Class
    Object(_) => Object
    Component(_) => Component
    UseCase(_) => UseCase
    State(_) => State
    Mindmap(_) => Mindmap
    Json(_) => Json
    Yaml(_) => Yaml
    Toml(_) => Toml
  }
}

///|
/// Parse a source into the diagram family its syntax selects.
///
/// The `is_*_source` heuristics run in priority order, mirroring PlantUML's
/// per-diagram factory selection. A source matching none of them fails.
pub fn parse(source : String) -> Document raise {
  if is_json_source(source) {
    return { diagram: Json(@nonuml.parse_json(source)) }
  }
  if is_yaml_source(source) {
    return { diagram: Yaml(@nonuml.parse_yaml(source)) }
  }
  if is_toml_source(source) {
    return { diagram: Toml(@nonuml.parse_toml(source)) }
  }
  if is_mindmap_source(source) {
    return { diagram: Mindmap(@mindmap.parse(source)) }
  }
  if is_activity_source(source) {
    return { diagram: Activity(@activity.parse(source)) }
  }
  if is_sequence_source(source) {
    return { diagram: Sequence(@sequence.parse(source)) }
  }
  if is_state_source(source) {
    return { diagram: State(@state.parse(source)) }
  }
  if is_usecase_source(source) {
    return { diagram: UseCase(@entity_usecase.parse(source)) }
  }
  if is_component_source(source) {
    return { diagram: Component(@entity_component.parse(source)) }
  }
  if is_object_source(source) {
    return { diagram: Object(@entity_class.parse(source)) }
  }
  if is_class_source(source) {
    return { diagram: Class(@entity_class.parse(source)) }
  }
  fail("unknown diagram")
}

///|
fn meaningful_source_lines(input : String) -> Array[String] {
  input
  .split("\n")
  .map(line => @core.strip_line_comment(line.to_owned()).trim().to_owned())
  .filter(line => {
    line.length() > 0 &&
    !line.equal_ignore_ascii_case("@startuml") &&
    !line.equal_ignore_ascii_case("@enduml") &&
    !@core.is_preprocessor_directive(line)
  })
  .to_array()
}

///|
fn starts_with_keyword(line : String, keywords : Array[String]) -> Bool {
  let words = @core.syntax_words(line)
  words.length() > 0 && keywords.contains(words[0].to_lower())
}

///|
fn is_sequence_command(line : String) -> Bool {
  let lower = line.to_lower()
  let words = @core.syntax_words(line)
  let grouping_keyword = match words {
    ["&", keyword, ..] | [keyword, ..] =>
      sequence_grouping_keywords.contains(keyword.to_lower())
    _ => false
  }
  lower == "autonewpage" ||
  grouping_keyword ||
  lower.has_prefix("participant ") ||
  lower.has_prefix("create ") ||
  lower.has_prefix("box ") ||
  lower.has_prefix("autonumber") ||
  lower.has_prefix("autoactivate") ||
  lower == "hide footbox" ||
  lower == "show footbox" ||
  lower.has_prefix("ref over ") ||
  lower.has_prefix("ignore newpage")
}

///|
fn is_ambiguous_participant_declaration(line : String) -> Bool {
  starts_with_keyword(line, participant_shape_keywords())
}

///|
fn has_message_arrow(line : String) -> Bool {
  @core.find_unquoted_literal(line, "->") is Some(_) ||
  @core.find_unquoted_literal(line, "<-") is Some(_)
}

///|
fn has_component_declaration(line : String) -> Bool {
  starts_with_keyword(line, component_keywords())
}

///|
fn has_usecase_declaration(line : String) -> Bool {
  if starts_with_keyword(line, usecase_keywords()) {
    return true
  }
  let trimmed = line.trim().to_owned()
  (trimmed.has_prefix("(") && !trimmed.has_prefix("()")) ||
  trimmed.contains(">(") ||
  trimmed.contains("> (")
}

///|
/// These arrow forms are sequence-message syntax, never class relations.
fn has_sequence_only_message_arrow(line : String) -> Bool {
  sequence_message_arrows().any(arrow => {
    @core.find_unquoted_literal(line, arrow) is Some(_)
  })
}

///|
fn is_class_declaration(line : String) -> Bool {
  starts_with_keyword(line, class_keywords())
}

///|
/// Returns whether the source selects PlantUML's state-diagram factory.
pub fn is_state_source(input : String) -> Bool {
  for line in meaningful_source_lines(input) {
    let lower = line.to_lower()
    if lower.has_prefix("state ") ||
      lower.has_prefix("frame ") ||
      state_start_markers().contains(line) ||
      line.has_prefix("[*] ") ||
      line.has_suffix(" [*]") {
      return true
    }
  }
  false
}

///|
fn is_object_declaration(line : String) -> Bool {
  starts_with_keyword(line, object_keywords())
}

///|
fn is_non_object_entity_declaration(line : String) -> Bool {
  let lower = line.to_lower()
  is_class_declaration(line) &&
  !is_object_declaration(line) &&
  !lower.has_prefix("package ") &&
  !lower.has_prefix("namespace ")
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
/// Returns whether the source contains an unambiguous component-diagram
/// construct. Component diagrams share PlantUML's description grammar with
/// several other families, so sequence-only syntax is checked first.
pub fn is_component_source(input : String) -> Bool {
  guard !is_sequence_source(input) else { return false }
  for line in meaningful_source_lines(input) {
    if has_component_declaration(line) {
      return true
    }
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("[") &&
      (
        has_message_arrow(trimmed) ||
        @core.find_unquoted_literal(trimmed, "--") is Some(_)
      ) {
      return true
    }
  }
  false
}

///|
/// Returns whether the source contains a use-case-specific declaration.
pub fn is_usecase_source(input : String) -> Bool {
  guard !is_sequence_source(input) else { return false }
  meaningful_source_lines(input).any(has_usecase_declaration)
}

///|
/// Returns whether the first entity declaration selects the object facade.
///
/// Object commands are parsed by PlantUML's class-diagram factory, but this
/// project retains an object facade so its SVG behavior can evolve separately.
pub fn is_object_source(input : String) -> Bool {
  guard !is_sequence_source(input) else { return false }
  for line in meaningful_source_lines(input) {
    if is_object_declaration(line) {
      return true
    }
    if is_non_object_entity_declaration(line) {
      return false
    }
  }
  false
}

///|
/// Returns whether the source contains a class-diagram-specific construct.
///
/// PlantUML selects a diagram factory from the first meaningful command. The
/// facade deliberately uses only unambiguous class constructs here, so a
/// sequence message such as `Alice -> Bob` remains a sequence diagram.
pub fn is_class_source(input : String) -> Bool {
  guard !is_sequence_source(input) else { return false }
  guard !is_usecase_source(input) else { return false }
  for line in meaningful_source_lines(input) {
    let lower = line.to_lower()
    if is_class_declaration(line) ||
      class_relation_arrows().any(arrow => {
        @core.find_unquoted_literal(line, arrow) is Some(_)
      }) ||
      lower.has_prefix("allowmixing") ||
      lower.has_prefix("mix_") ||
      lower.has_prefix("note on link") ||
      lower.has_prefix("constraint on links") ||
      line.has_prefix("<>") {
      return true
    }
  }
  false
}

///|
/// Returns whether the source uses PlantUML's JSON diagram delimiters.
pub fn is_json_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@startjson")
}

///|
/// Returns whether the source uses PlantUML's YAML diagram delimiters.
pub fn is_yaml_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@startyaml")
}

///|
/// Returns whether the source uses this project's TOML diagram delimiters.
pub fn is_toml_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@starttoml")
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
    activity_commands().contains(lower) ||
    activity_command_prefixes().any(prefix => lower.has_prefix(prefix)) ||
    (line.has_prefix(":") && line.has_suffix(";"))
  })
}
