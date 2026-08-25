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
/// Major PlantUML diagram families supported by the document dispatcher.
pub(all) enum DiagramKind {
  Sequence
  Class
  Activity
  State
  Component
  Deployment
  Object
  UseCase
  Mindmap
  Mbti
  Json
  Yaml
  Toml
  Dot
}

///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(
  self : Document,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
  class_member_collapsible? : Bool = false,
) -> String raise {
  self.diagram.render_svg(color_scheme~, class_member_collapsible~)
}

///|
/// Parse a PlantUML source with the document heuristics and render the
/// selected diagram family to SVG.
///
/// `color_scheme` is the cross-diagram theme boundary. `text` and `line` are
/// required (the ink colors that become unreadable in a dark theme), and every
/// other role may be a CSS variable or a literal color. Diagram renderers own
/// skinparam precedence and the mapping from their role group to SVG elements.
///
/// When `class_member_collapsible` is set, class-diagram members (fields and
/// methods) are wrapped in a `<foreignObject>`/`<details>` disclosure so they
/// can be collapsed in the browser.
pub fn render_svg(
  source : String,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
  class_member_collapsible? : Bool = false,
) -> String raise {
  parse(source).render_svg(color_scheme~, class_member_collapsible~)
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
          { diagram: Class(@parser.parse_entity(source, family~)), }
        ObjectDiagram =>
          { diagram: Object(@parser.parse_entity(source, family~)), }
        ComponentDiagram =>
          { diagram: Component(@parser.parse_entity(source, family~)), }
        UseCaseDiagram =>
          { diagram: UseCase(@parser.parse_entity(source, family~)), }
        DeploymentDiagram =>
          { diagram: Deployment(@parser.parse_entity(source, family~)), }
        Mbti => raise @parse.SyntaxError(1, "unreachable mbti family")
      }
    _ => raise @parse.SyntaxError(1, "unknown diagram")
  }
}
