///|
/// Parse PlantUML's class-diagram command family through the shared engine.
///
/// PlantUML registers `object`, `map`, and `json` commands in this family.
pub fn parse(input : String) -> @entity.EntityDiagram raise @core.ParseError {
  @entity.parse_entity_diagram(
    input,
    allow_mixing=false,
    unclosed_body_message="unclosed class body",
  )
}
