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
fn meaningful_source_lines(input : String) -> Array[String] {
  input
  .split("\n")
  .map(line => @core.strip_line_comment(line.to_owned()).trim().to_owned())
  .filter(line => {
    line.length() > 0 &&
    !line.equal_ignore_ascii_case("@startuml") &&
    !line.equal_ignore_ascii_case("@enduml") &&
    !@core.is_preprocessor_directive(line)
  })
  .to_array()
}

///|
fn is_sequence_command(line : String) -> Bool {
  let lower = line.to_lower()
  let words = @core.syntax_words(line)
  let grouping_keyword = match words {
    ["&", keyword, ..] | [keyword, ..] =>
      match keyword.to_lower() {
        "opt"
        | "alt"
        | "loop"
        | "par"
        | "par2"
        | "break"
        | "critical"
        | "group"
        | "partition" => true
        _ => false
      }
    _ => false
  }
  lower == "autonewpage" ||
  grouping_keyword ||
  lower.has_prefix("participant ") ||
  lower.has_prefix("create ") ||
  lower.has_prefix("box ") ||
  lower.has_prefix("autonumber") ||
  lower.has_prefix("autoactivate") ||
  lower == "hide footbox" ||
  lower == "show footbox" ||
  lower.has_prefix("ref over ") ||
  lower.has_prefix("ignore newpage")
}

///|
fn is_ambiguous_participant_declaration(line : String) -> Bool {
  let words = @core.syntax_words(line)
  guard words.length() > 0 else { return false }
  match words[0].to_lower() {
    "actor"
    | "boundary"
    | "control"
    | "entity"
    | "database"
    | "queue"
    | "collections"
    | "port"
    | "portin"
    | "portout"
    | "participant" => true
    _ => false
  }
}

///|
fn has_message_arrow(line : String) -> Bool {
  @core.find_unquoted_literal(line, "->") is Some(_) ||
  @core.find_unquoted_literal(line, "<-") is Some(_)
}

///|
fn is_class_declaration(line : String) -> Bool {
  let words = @core.syntax_words(line)
  guard words.length() > 0 else { return false }
  match words[0].to_lower() {
    "class"
    | "interface"
    | "enum"
    | "annotation"
    | "abstract"
    | "object"
    | "entity"
    | "exception"
    | "metaclass"
    | "stereotype"
    | "dataclass"
    | "record"
    | "map"
    | "json"
    | "component"
    | "database"
    | "queue"
    | "actor"
    | "usecase"
    | "struct"
    | "protocol"
    | "state"
    | "folder"
    | "file"
    | "node"
    | "cloud"
    | "person"
    | "artifact"
    | "boundary"
    | "control"
    | "port"
    | "portin"
    | "portout"
    | "package"
    | "namespace"
    | "rectangle"
    | "hexagon"
    | "label"
    | "frame"
    | "action"
    | "process"
    | "stack"
    | "storage"
    | "agent"
    | "collections" => true
    _ => false
  }
}

///|
/// Returns whether the source contains a sequence-diagram-specific command.
///
/// This deliberately covers commands that cannot be inferred from an arrow
/// alone: a sequence reply such as `A --> B` otherwise looks like a class
/// relation to the class-diagram heuristic.
pub fn is_sequence_source(input : String) -> Bool {
  let lines = meaningful_source_lines(input)
  lines.any(is_sequence_command) ||
  (
    lines.any(is_ambiguous_participant_declaration) &&
    lines.any(has_message_arrow)
  )
}

///|
/// Returns whether the source contains a class-diagram-specific construct.
///
/// PlantUML selects a diagram factory from the first meaningful command. The
/// facade deliberately uses only unambiguous class constructs here, so a
/// sequence message such as `Alice -> Bob` remains a sequence diagram.
pub fn is_class_source(input : String) -> Bool {
  guard !is_sequence_source(input) else { return false }
  for line in meaningful_source_lines(input) {
    if is_class_declaration(line) ||
      @core.find_unquoted_literal(line, "--") is Some(_) ||
      @core.find_unquoted_literal(line, "..") is Some(_) ||
      @core.find_unquoted_literal(line, "<|") is Some(_) ||
      @core.find_unquoted_literal(line, ".>") is Some(_) ||
      @core.find_unquoted_literal(line, "<.") is Some(_) ||
      line.to_lower().has_prefix("allowmixing") ||
      line.to_lower().has_prefix("mix_") ||
      line.to_lower().has_prefix("note on link") ||
      line.to_lower().has_prefix("constraint on links") ||
      line.has_prefix("<>") {
      return true
    }
  }
  false
}

///|
/// Returns whether the source uses PlantUML's JSON diagram delimiters.
pub fn is_json_source(input : String) -> Bool {
  input.trim().to_lower().has_prefix("@startjson")
}
