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
  Mbti(@mbti.MbtiDiagram)
  Json(@structured.StructuredDiagram)
  Yaml(@structured.StructuredDiagram)
  Toml(@structured.StructuredDiagram)
  Dot(DotDiagram)
}

///|
pub struct Document {
  diagram : Diagram
}

///|
/// Render a parsed diagram family to SVG.
///
/// This is the single boundary between document parsing and diagram-specific
/// rendering. Each family still owns its parser, layout, and SVG painter; the
/// API only dispatches after parsing has selected the family.
pub fn Diagram::render_svg(
  self : Diagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
  class_member_collapsible? : Bool = false,
) -> String raise {
  match self {
    Sequence(diagram) => diagram.render_svg(color_scheme~)
    Activity(diagram) => diagram.render_svg(color_scheme~)
    Class(diagram) | Object(diagram) | Component(diagram) | UseCase(diagram) =>
      diagram.render_svg(color_scheme~, class_member_collapsible~)
    State(diagram) => diagram.render_svg(color_scheme~)
    Mindmap(diagram) => diagram.render_svg(color_scheme~)
    Mbti(diagram) =>
      diagram.render_svg(color_scheme~, class_member_collapsible~)
    Json(diagram) | Yaml(diagram) | Toml(diagram) =>
      diagram.render_svg(color_scheme~)
    Dot(diagram) => diagram.render_svg()
  }
}

///|
pub fn Document::kind(self : Document) -> DiagramKind {
  match self.diagram {
    Sequence(_) => Sequence
    Activity(_) => Activity
    Class(_) => Class
    Object(_) => Object
    Component(_) => Component
    UseCase(_) => UseCase
    State(_) => State
    Mindmap(_) => Mindmap
    Mbti(_) => Mbti
    Json(_) => Json
    Yaml(_) => Yaml
    Toml(_) => Toml
    Dot(_) => Dot
  }
}

///|
/// Parse a source into the diagram family its syntax selects.
///
/// The `is_*_source` heuristics run in priority order, mirroring PlantUML's
/// per-diagram factory selection. A source matching none of them fails.
pub fn parse(source : String) -> Document raise {
  match () {
    _ if @mbti.is_mbti_source(source) => { diagram: Mbti(@mbti.parse(source)) }
    _ if is_json_source(source) =>
      { diagram: Json(@structured.parse_json(source)) }
    _ if is_yaml_source(source) =>
      { diagram: Yaml(@structured.parse_yaml(source)) }
    _ if is_toml_source(source) =>
      { diagram: Toml(@structured.parse_toml(source)) }
    _ if is_dot_source(source) => { diagram: Dot(parse_dot_source(source)) }
    _ if is_mindmap_source(source) =>
      { diagram: Mindmap(@mindmap.parse(source)) }
    _ if is_sequence_source(source) =>
      { diagram: Sequence(@sequence.parse(source)) }
    _ if is_activity_source(source) =>
      { diagram: Activity(@activity.parse(source)) }
    _ if is_state_source(source) => { diagram: State(@state.parse(source)) }
    _ if is_usecase_source(source) =>
      { diagram: UseCase(@entity.parse(source, family=@entity.UseCaseDiagram)) }
    _ if is_component_source(source) =>
      {
        diagram: Component(
          @entity.parse(source, family=@entity.ComponentDiagram),
        ),
      }
    _ if is_object_source(source) =>
      { diagram: Object(@entity.parse(source, family=@entity.ObjectDiagram)) }
    _ if is_class_source(source) =>
      { diagram: Class(@entity.parse(source, family=@entity.ClassDiagram)) }
    _ => raise @parse.SyntaxError(1, "unknown diagram")
  }
}

///|
fn meaningful_source_lines(input : String) -> Array[String] {
  input
  .split("\n")
  .map(line => @parse.strip_line_comment(line.to_owned()).trim().to_owned())
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
  let words = @parse.syntax_words(line)
  words.length() > 0 && keywords.contains(words[0].to_lower())
}

///|
fn is_sequence_command(line : String) -> Bool {
  let lower = line.to_lower()
  let words = @parse.syntax_words(line)
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
  lower == "hide footbox" ||
  lower == "show footbox" ||
  lower.has_prefix("ref over ") ||
  lower.has_prefix("ignore newpage")
}

///|
fn is_ambiguous_participant_declaration(line : String) -> Bool {
  starts_with_keyword(line, participant_shape_keywords)
}

///|
fn has_message_arrow(line : String) -> Bool {
  @parse.find_unquoted_literal(line, "->") is Some(_) ||
  @parse.find_unquoted_literal(line, "<-") is Some(_)
}

///|
fn has_component_declaration(line : String) -> Bool {
  starts_with_keyword(line, component_keywords)
}

///|
fn has_usecase_declaration(line : String) -> Bool {
  let trimmed = line.trim().to_owned()
  starts_with_keyword(line, usecase_keywords) ||
  (trimmed.has_prefix("(") && !trimmed.has_prefix("()")) ||
  trimmed.contains(">(") ||
  trimmed.contains("> (")
}

///|
/// These arrow forms are sequence-message syntax, never class relations.
fn has_sequence_only_message_arrow(line : String) -> Bool {
  sequence_message_arrows.any(arrow => {
    @parse.find_unquoted_literal(line, arrow) is Some(_)
  })
}

///|
fn is_class_declaration(line : String) -> Bool {
  starts_with_keyword(line, class_keywords)
}

///|
/// Returns whether the source selects PlantUML's state-diagram factory.
pub fn is_state_source(input : String) -> Bool {
  for line in meaningful_source_lines(input) {
    let lower = line.to_lower()
    if lower.has_prefix("state ") ||
      lower.has_prefix("frame ") ||
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
        @parse.find_unquoted_literal(trimmed, "--") is Some(_)
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
      class_relation_arrows.any(arrow => {
        @parse.find_unquoted_literal(line, arrow) is Some(_)
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
/// Returns whether the source uses PlantUML's DOT diagram delimiters.
pub fn is_dot_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@startdot")
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
