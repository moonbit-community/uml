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
/// Keywords that unambiguously select PlantUML's component grammar.
///
/// `boundary`, `control`, `collections`, `port`, and friends are deliberately
/// excluded: they are sequence-diagram participant shapes first, and PlantUML
/// resolves such declarations as sequence participants even without messages.
pub let component_keywords : FixedArray[String] = ["component"]

///|
/// Keywords that select PlantUML's description grammar, the factory behind
/// deployment diagrams.
///
/// This is PlantUML's `CommandCreateElementFull.ALL_TYPES` minus the keywords
/// claimed earlier by the sequence, use-case, and component heuristics, and
/// minus the class-native kinds (`class`, `entity`, `interface`, `circle`, ...)
/// which PlantUML's class factory accepts without `allowmixing`. With
/// `allowmixing` present the class factory wins in PlantUML, so those sources
/// stay class diagrams.
pub let deployment_keywords : FixedArray[String] = [
  "node", "folder", "frame", "cloud", "storage", "agent", "artifact", "card", "rectangle",
  "hexagon", "label", "action", "process", "stack", "file", "person",
]

///|
/// Keywords that only PlantUML's class factory parses, never its description
/// factory. A source mixing them with description declarations stays an
/// error unless `allowmixing` moves it to the class grammar.
pub let class_only_keywords : FixedArray[String] = [
  "class", "enum", "annotation", "exception", "metaclass", "stereotype", "dataclass",
  "record", "struct", "protocol", "abstract",
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
/// Actor keywords of the use-case grammar (`CommandCreateElementFull.ALL_TYPES`).
pub let actor_keywords : FixedArray[String] = ["actor", "actor/"]

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
///
/// `label` is deliberately excluded: PlantUML's description factory parses a
/// bare `label X` as an element declaration, while activity diagrams reach the
/// label command through their other markers (`:work;`, `start`, ...).
pub let activity_command_prefixes : FixedArray[String] = [
  "repeat while ", "if ", "elseif ", "else ", "while ", "switch ", "case ", "goto ",
]

///|
/// State-diagram start markers.
pub let state_start_markers : FixedArray[String] = ["[*]", "[H]", "[H*]"]
