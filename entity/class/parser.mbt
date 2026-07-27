///|
/// Parse a PlantUML class diagram through the shared entity-diagram engine.
pub fn parse(input : String) -> @entity.EntityDiagram raise @core.ParseError {
  @entity.parse_entity_diagram(
    input,
    allow_mixing=false,
    unclosed_body_message="unclosed class body",
  )
}
