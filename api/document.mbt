///|
/// The parsed PlantUML document. Diagram-specific state stays in its own package.
pub enum Diagram {
  Sequence(@sequence.SequenceDiagram)
  Class(@class.ClassDiagram)
  Json(@nonuml.JsonDiagram)
}

///|
pub struct Document {
  diagram : Diagram
}

///|
pub fn Document::kind(self : Document) -> @core.DiagramKind {
  match self.diagram {
    Sequence(_) => Sequence
    Class(_) => Class
    Json(_) => Json
  }
}

///|
pub fn parse_class(input : String) -> Document raise @class.ParseError {
  { diagram: Class(@class.parse(input)) }
}

///|
pub fn parse(input : String) -> Document raise @sequence.ParseError {
  { diagram: Sequence(@sequence.parse(input)) }
}

///|
pub fn parse_json(input : String) -> Document raise @json.ParseError {
  { diagram: Json(@nonuml.parse_json(input)) }
}

///|
/// Returns whether the source contains a class-diagram-specific construct.
///
/// PlantUML selects a diagram factory from the first meaningful command. The
/// facade deliberately uses only unambiguous class constructs here, so a
/// sequence message such as `Alice -> Bob` remains a sequence diagram.
pub fn is_class_source(input : String) -> Bool {
  input.contains("--") ||
  input.contains("..") ||
  input.contains("<|") ||
  input.contains("class ") ||
  input.contains("interface ") ||
  input.contains("enum ") ||
  input.contains("package ") ||
  input.contains("namespace ")
}

///|
/// Returns whether the source uses PlantUML's JSON diagram delimiters.
pub fn is_json_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@startjson")
}
