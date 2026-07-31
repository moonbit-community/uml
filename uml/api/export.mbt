///|
pub fn render_svg(source : String) -> String raise {
  match () {
    _ if is_json_source(source) => parse_json(source).render_svg()
    _ if is_yaml_source(source) => parse_yaml(source).render_svg()
    _ if is_toml_source(source) => parse_toml(source).render_svg()
    _ if is_mindmap_source(source) => parse_mindmap(source).render_svg()
    _ if is_activity_source(source) => parse_activity(source).render_svg()
    _ if is_sequence_source(source) => parse_sequence(source).render_svg()
    _ if is_state_source(source) => parse_state(source).render_svg()
    _ if is_usecase_source(source) => parse_usecase(source).render_svg()
    _ if is_component_source(source) => parse_component(source).render_svg()
    _ if is_object_source(source) => parse_object(source).render_svg()
    _ if is_class_source(source) => parse_class(source).render_svg()
    _ => fail("unknown diagram")
  }
}

test {
  let source = "@startuml\nAlice -> Bob: Request\nBob --> Alice: Response\n@enduml"
  source |> render_svg |> println
}
