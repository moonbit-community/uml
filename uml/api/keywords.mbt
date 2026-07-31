///|
/// Sequence-diagram grouping keywords.
pub let sequence_grouping_keywords : FixedArray[String] = [
  "opt", "alt", "loop", "par", "par2", "break", "critical", "group", "partition",
]

///|
/// Participant shape keywords shared by the sequence and entity grammars.
fn participant_shape_keywords() -> Array[String] {
  [
    "actor", "boundary", "control", "entity", "database", "queue", "collections",
    "port", "portin", "portout", "participant",
  ]
}

///|
/// Keywords that select PlantUML's component grammar.
fn component_keywords() -> Array[String] {
  [
    "component", "boundary", "control", "port", "portin", "portout", "collections",
  ]
}

///|
/// Keywords that select PlantUML's class-diagram grammar.
fn class_keywords() -> Array[String] {
  [
    "class", "interface", "enum", "annotation", "abstract", "object", "entity", "exception",
    "metaclass", "stereotype", "dataclass", "record", "map", "json", "component",
    "database", "queue", "actor", "usecase", "struct", "protocol", "state", "folder",
    "file", "node", "cloud", "person", "artifact", "boundary", "control", "port",
    "portin", "portout", "package", "namespace", "rectangle", "hexagon", "label",
    "frame", "action", "process", "stack", "storage", "agent", "collections",
  ]
}

///|
/// Keywords that select the object facade over the class grammar.
fn object_keywords() -> Array[String] {
  ["object", "map", "json"]
}

///|
/// Keywords that select PlantUML's use-case grammar.
fn usecase_keywords() -> Array[String] {
  ["usecase", "usecase/"]
}

///|
/// Arrow dressings that only sequence-message syntax uses.
fn sequence_message_arrows() -> Array[String] {
  ["->>", "<<-", "\\->", "\\-->", "/->", "/-->"]
}

///|
/// Dotted and dashed arrows that select the class grammar.
fn class_relation_arrows() -> Array[String] {
  ["--", "..", "<|", ".>", "<."]
}

///|
/// Activity-diagram commands that stand alone on a line.
fn activity_commands() -> Array[String] {
  [
    "start", "stop", "endif", "endwhile", "repeat", "fork", "fork again", "end fork",
    "endfork", "endswitch", "else",
  ]
}

///|
/// Activity-diagram commands that prefix a line.
fn activity_command_prefixes() -> Array[String] {
  [
    "repeat while ", "if ", "elseif ", "else ", "while ", "switch ", "case ", "goto ",
    "label ",
  ]
}

///|
/// State-diagram start markers.
fn state_start_markers() -> Array[String] {
  ["[*]", "[H]", "[H*]"]
}
