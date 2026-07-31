///|
/// Sequence-diagram grouping keywords.
pub let sequence_grouping_keywords : FixedArray[String] = [
  "opt", "alt", "loop", "par", "par2", "break", "critical", "group", "partition",
]

///|
/// Participant shape keywords shared by the sequence and entity grammars.
pub let participant_shape_keywords : FixedArray[String] = [
  "actor", "boundary", "control", "entity", "database", "queue", "collections", "port",
  "portin", "portout", "participant",
]

///|
/// Keywords that select PlantUML's component grammar.
pub let component_keywords : FixedArray[String] = [
  "component", "boundary", "control", "port", "portin", "portout", "collections",
]

///|
/// Keywords that select PlantUML's class-diagram grammar.
pub let class_keywords : FixedArray[String] = [
  "class", "interface", "enum", "annotation", "abstract", "object", "entity", "exception",
  "metaclass", "stereotype", "dataclass", "record", "map", "json", "component", "database",
  "queue", "actor", "usecase", "struct", "protocol", "state", "folder", "file", "node",
  "cloud", "person", "artifact", "boundary", "control", "port", "portin", "portout",
  "package", "namespace", "rectangle", "hexagon", "label", "frame", "action", "process",
  "stack", "storage", "agent", "collections",
]

///|
/// Keywords that select the object facade over the class grammar.
pub let object_keywords : FixedArray[String] = ["object", "map", "json"]

///|
/// Keywords that select PlantUML's use-case grammar.
pub let usecase_keywords : FixedArray[String] = ["usecase", "usecase/"]

///|
/// Arrow dressings that only sequence-message syntax uses.
pub let sequence_message_arrows : FixedArray[String] = [
  "->>", "<<-", "\\->", "\\-->", "/->", "/-->",
]

///|
/// Dotted and dashed arrows that select the class grammar.
pub let class_relation_arrows : FixedArray[String] = [
  "--", "..", "<|", ".>", "<.",
]

///|
/// Activity-diagram commands that stand alone on a line.
pub let activity_commands : FixedArray[String] = [
  "start", "stop", "endif", "endwhile", "repeat", "fork", "fork again", "end fork",
  "endfork", "endswitch", "else",
]

///|
/// Activity-diagram commands that prefix a line.
pub let activity_command_prefixes : FixedArray[String] = [
  "repeat while ", "if ", "elseif ", "else ", "while ", "switch ", "case ", "goto ",
  "label ",
]

///|
/// State-diagram start markers.
pub let state_start_markers : FixedArray[String] = ["[*]", "[H]", "[H*]"]
