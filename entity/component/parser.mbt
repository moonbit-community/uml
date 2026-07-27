///|
/// Parse a PlantUML component/description diagram through the shared engine.
pub fn parse(input : String) -> @entity.EntityDiagram raise @core.ParseError {
  @entity.parse_entity_diagram(
    input,
    allow_mixing=true,
    unclosed_body_message="unclosed component body",
  )
}
