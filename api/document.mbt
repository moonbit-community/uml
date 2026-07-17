///|
/// The parsed PlantUML document. Diagram-specific state stays in its own package.
pub enum Diagram {
  Sequence(@sequence.SequenceDiagram)
}

///|
pub struct Document {
  diagram : Diagram
}

///|
pub fn Document::kind(self : Document) -> @core.DiagramKind {
  match self.diagram {
    Sequence(_) => Sequence
  }
}

///|
pub fn parse(input : String) -> Document raise @sequence.ParseError {
  { diagram: Sequence(@sequence.parse(input)) }
}
