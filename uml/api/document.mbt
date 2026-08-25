///|
/// The parsed PlantUML document. Diagram-specific state stays in its own package.
pub enum Diagram {
  Sequence(@seq.SequenceDiagram)
  Activity(@flow.ActivityDiagram)
  Class(@entity.EntityDiagram)
  Object(@entity.EntityDiagram)
  Component(@entity.EntityDiagram)
  Deployment(@entity.EntityDiagram)
  UseCase(@entity.EntityDiagram)
  State(@flow.StateDiagram)
  Mindmap(@tree.MindmapDiagram)
  Mbti(@entity.MbtiDiagram)
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
    Sequence(diagram) => @render.render_sequence_svg(diagram, color_scheme~)
    Activity(diagram) => @render.render_activity_svg(diagram, color_scheme~)
    Class(diagram)
    | Object(diagram)
    | Component(diagram)
    | UseCase(diagram)
    | Deployment(diagram) =>
      @render.render_entity_svg(
        diagram,
        color_scheme~,
        class_member_collapsible~,
      )
    State(diagram) => @render.render_state_svg(diagram, color_scheme~)
    Mindmap(diagram) => @render.render_mindmap_svg(diagram, color_scheme~)
    Mbti(diagram) =>
      @render.render_mbti_svg(diagram, color_scheme~, class_member_collapsible~)
    Json(diagram) | Yaml(diagram) | Toml(diagram) =>
      @render.render_structured_svg(diagram, color_scheme~)
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
    Deployment(_) => Deployment
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
/// per-diagram factory selection; the entity-grammar facades are selected by
/// one classifier scan. A source matching none of them fails.
pub fn parse(source : String) -> Document raise {
  match () {
    _ if @parser.is_mbti_source(source) =>
      { diagram: Mbti(@parser.parse_mbti(source)), }
    _ if is_json_source(source) =>
      { diagram: Json(@parser.parse_structured_json(source)), }
    _ if is_yaml_source(source) =>
      { diagram: Yaml(@parser.parse_structured_yaml(source)), }
    _ if is_toml_source(source) =>
      { diagram: Toml(@parser.parse_structured_toml(source)), }
    _ if is_dot_source(source) => { diagram: Dot(parse_dot_source(source)), }
    _ if is_mindmap_source(source) =>
      { diagram: Mindmap(@parser.parse_mindmap(source)), }
    _ if is_sequence_source(source) =>
      { diagram: Sequence(@parser.parse_sequence(source)), }
    _ if is_activity_source(source) =>
      { diagram: Activity(@parser.parse_activity(source)), }
    _ if is_state_source(source) =>
      { diagram: State(@parser.parse_state(source)), }
    _ if entity_family_from_lines(meaningful_source_lines(source))
      is Some(family) =>
      match family {
        ClassDiagram =>
          {
            diagram: Class(
              @parser.parse_entity(source, family=@entity.ClassDiagram),
            ),
          }
        ObjectDiagram =>
          {
            diagram: Object(
              @parser.parse_entity(source, family=@entity.ObjectDiagram),
            ),
          }
        ComponentDiagram =>
          {
            diagram: Component(
              @parser.parse_entity(source, family=@entity.ComponentDiagram),
            ),
          }
        UseCaseDiagram =>
          {
            diagram: UseCase(
              @parser.parse_entity(source, family=@entity.UseCaseDiagram),
            ),
          }
        DeploymentDiagram =>
          {
            diagram: Deployment(
              @parser.parse_entity(source, family=@entity.DeploymentDiagram),
            ),
          }
        Mbti => raise @parse.SyntaxError(1, "unreachable mbti family")
      }
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
  @parse.find_unquoted_literal(line, "->") is Some(_) ||
  @parse.find_unquoted_literal(line, "<-") is Some(_)
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
  let cursor = @parse.Cursor::new(line)
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
  let cursor = @parse.Cursor::new(trimmed)
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
    @parse.find_unquoted_literal(line, arrow) is Some(_)
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
    @parse.find_unquoted_literal(trimmed, "--") is Some(_)
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
      @parse.find_unquoted_literal(line, arrow) is Some(_)
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
