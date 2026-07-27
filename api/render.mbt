///|
/// Render a parsed document to SVG by dispatching to its diagram-specific renderer.
pub fn Document::render_svg(self : Document) -> String {
  match self.diagram {
    Sequence(diagram) => @sequence.render_svg(diagram)
    Class(diagram) => @entity_class.render_svg(diagram)
    Object(diagram) => @entity_object.render_svg(diagram)
    Component(diagram) => @entity_component.render_svg(diagram)
    UseCase(diagram) => @entity_usecase.render_svg(diagram)
    Mindmap(diagram) => @mindmap.render_svg(diagram)
    Json(diagram) => diagram.render_json_svg()
    Yaml(diagram) => diagram.render_yaml_svg()
    Toml(diagram) => diagram.render_toml_svg()
  }
}

///|
pub fn render_class_svg(input : String) -> String raise @core.ParseError {
  parse_class(input).render_svg()
}

///|
pub fn render_object_svg(input : String) -> String raise @core.ParseError {
  parse_object(input).render_svg()
}

///|
pub fn render_component_svg(input : String) -> String raise @core.ParseError {
  parse_component(input).render_svg()
}

///|
pub fn render_usecase_svg(input : String) -> String raise @core.ParseError {
  parse_usecase(input).render_svg()
}

///|
pub fn render_mindmap_svg(input : String) -> String raise @core.ParseError {
  parse_mindmap(input).render_svg()
}

///|
pub fn render_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}

///|
pub fn render_json_svg(input : String) -> String raise @json.ParseError {
  parse_json(input).render_svg()
}

///|
pub fn render_yaml_svg(input : String) -> String raise @yaml.YamlError {
  parse_yaml(input).render_svg()
}

///|
pub fn render_toml_svg(input : String) -> String raise {
  parse_toml(input).render_svg()
}
