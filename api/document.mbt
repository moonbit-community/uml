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
  let input = input.to_lower()
  input.contains("--") ||
  input.contains("..") ||
  input.contains("<|") ||
  input.contains("class ") ||
  input.contains("interface ") ||
  input.contains("enum ") ||
  input.contains("annotation ") ||
  input.contains("abstract ") ||
  input.contains("object ") ||
  input.contains("entity ") ||
  input.contains("exception ") ||
  input.contains("metaclass ") ||
  input.contains("stereotype ") ||
  input.contains("dataclass ") ||
  input.contains("record ") ||
  input.contains("circle ") ||
  input.contains("map ") ||
  input.contains("json ") ||
  input.contains("component ") ||
  input.contains("database ") ||
  input.contains("queue ") ||
  input.contains("actor ") ||
  input.contains("usecase ") ||
  input.contains("struct ") ||
  input.contains("protocol ") ||
  input.contains("state ") ||
  input.contains("folder ") ||
  input.contains("file ") ||
  input.contains("node ") ||
  input.contains("cloud ") ||
  input.contains("person ") ||
  input.contains("artifact ") ||
  input.contains("boundary ") ||
  input.contains("control ") ||
  input.contains("port ") ||
  input.contains("portin ") ||
  input.contains("portout ") ||
  input.contains("mix_") ||
  input.contains("() ") ||
  input.contains("usecase (") ||
  input.contains("actor :") ||
  input.contains("component [") ||
  input.contains(" .>") ||
  input.contains(" <.") ||
  input.contains("note on link") ||
  input.contains("constraint on links") ||
  input.contains("<> ") ||
  input.contains("package ") ||
  input.contains("namespace ")
}

///|
/// Returns whether the source uses PlantUML's JSON diagram delimiters.
pub fn is_json_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@startjson")
}
