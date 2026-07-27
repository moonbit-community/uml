///|
fn strip_comment(line : String) -> String {
  @core.strip_line_comment(line)
}

///|
fn normalize_name(raw : String) -> String {
  @core.unquote_identifier(raw)
}

///|
fn declaration_kind(word : String) -> EntityKind? {
  match word.to_lower() {
    "class" => Some(Class)
    "interface" => Some(Interface)
    "enum" => Some(Enum)
    "annotation" => Some(Annotation)
    "object" => Some(Object)
    "entity" => Some(Entity)
    "protocol" => Some(Protocol)
    "struct" => Some(Struct)
    "circle" => Some(Circle)
    "usecase" => Some(Usecase)
    "usecase/" => Some(BusinessUsecase)
    "person" => Some(Person)
    "actor/" => Some(BusinessActor)
    "exception" => Some(Exception)
    "metaclass" => Some(Metaclass)
    "stereotype" => Some(Stereotype)
    "dataclass" => Some(Dataclass)
    "record" => Some(Record)
    "map" => Some(Map)
    "json" => Some(Json)
    "diamond" => Some(Diamond)
    "component" => Some(Component)
    "boundary" => Some(Boundary)
    "control" => Some(Control)
    "port" => Some(Port)
    "portin" => Some(PortIn)
    "portout" => Some(PortOut)
    "actor" => Some(Actor)
    "database" => Some(Database)
    "queue" => Some(Queue)
    "folder" => Some(Folder)
    "file" => Some(File)
    "node" => Some(Node)
    "cloud" => Some(Cloud)
    "state" => Some(State)
    "artifact" => Some(Artifact)
    "card" => Some(Card)
    "package" => Some(Folder)
    "rectangle" => Some(Rectangle)
    "hexagon" => Some(Hexagon)
    "label" => Some(Label)
    "frame" => Some(Frame)
    "action" => Some(Action)
    "process" => Some(Process)
    "stack" => Some(Stack)
    "storage" => Some(Storage)
    "agent" => Some(Agent)
    "collections" => Some(Collections)
    _ => None
  }
}

///|
fn native_class_kind(kind : EntityKind) -> Bool {
  match kind {
    Class
    | AbstractClass
    | Interface
    | Enum
    | Annotation
    | Object
    | Entity
    | Protocol
    | Struct
    | Circle
    | Exception
    | Metaclass
    | Stereotype
    | Dataclass
    | Record
    | Map
    | Json
    | Diamond
    | NamedNote => true
    _ => false
  }
}

///|
fn shaped_declaration(
  kind : EntityKind,
  display : String,
  code : String,
) -> (EntityKind, String, String) {
  let value = display.trim()
  let encoded = if value.length() >= 3 &&
    value.has_prefix("(") &&
    value.has_suffix(")/") {
    Some((BusinessUsecase, value[1:value.length() - 2].trim().to_owned()))
  } else if value.length() >= 2 &&
    value.has_prefix("(") &&
    value.has_suffix(")") {
    Some(
      (
        if kind is BusinessUsecase {
          BusinessUsecase
        } else {
          Usecase
        },
        value[1:value.length() - 1].trim().to_owned(),
      ),
    )
  } else if value.length() >= 3 &&
    value.has_prefix(":") &&
    value.has_suffix(":/") {
    Some((BusinessActor, value[1:value.length() - 2].trim().to_owned()))
  } else if value.length() >= 2 &&
    value.has_prefix(":") &&
    value.has_suffix(":") {
    Some(
      (
        if kind is BusinessActor {
          BusinessActor
        } else {
          Actor
        },
        value[1:value.length() - 1].trim().to_owned(),
      ),
    )
  } else if value.length() >= 2 &&
    value.has_prefix("[") &&
    value.has_suffix("]") {
    Some((Component, value[1:value.length() - 1].trim().to_owned()))
  } else if code.length() >= 3 && code.has_prefix("(") && code.has_suffix(")/") {
    Some((BusinessUsecase, code[1:code.length() - 2].trim().to_owned()))
  } else if code.length() >= 2 && code.has_prefix("(") && code.has_suffix(")") {
    Some(
      (
        if kind is BusinessUsecase {
          BusinessUsecase
        } else {
          Usecase
        },
        code[1:code.length() - 1].trim().to_owned(),
      ),
    )
  } else if code.length() >= 3 && code.has_prefix(":") && code.has_suffix(":/") {
    Some((BusinessActor, code[1:code.length() - 2].trim().to_owned()))
  } else if code.length() >= 2 && code.has_prefix(":") && code.has_suffix(":") {
    Some(
      (
        if kind is BusinessActor {
          BusinessActor
        } else {
          Actor
        },
        code[1:code.length() - 1].trim().to_owned(),
      ),
    )
  } else if code.length() >= 2 && code.has_prefix("[") && code.has_suffix("]") {
    Some((Component, code[1:code.length() - 1].trim().to_owned()))
  } else {
    None
  }
  match encoded {
    Some((shape, raw_inner)) => {
      let inner = normalize_name(raw_inner)
      if inner.length() > 0 {
        let actual_code = if display == code { inner } else { code }
        return (shape, inner, actual_code)
      }
    }
    None => ()
  }
  let value = code.trim()
  if value.length() >= 3 && value.has_prefix("(") && value.has_suffix(")/") {
    let inner = normalize_name(value[1:value.length() - 2].trim().to_owned())
    if inner.length() > 0 {
      return (BusinessUsecase, inner, inner)
    }
  }
  if value.length() >= 2 && value.has_prefix("(") && value.has_suffix(")") {
    let inner = normalize_name(value[1:value.length() - 1].trim().to_owned())
    if inner.length() > 0 {
      return (
        if kind is BusinessUsecase {
          BusinessUsecase
        } else {
          Usecase
        },
        inner,
        inner,
      )
    }
  }
  if value.length() >= 3 && value.has_prefix(":") && value.has_suffix(":/") {
    let inner = normalize_name(value[1:value.length() - 2].trim().to_owned())
    if inner.length() > 0 {
      return (BusinessActor, inner, inner)
    }
  }
  if value.length() >= 2 && value.has_prefix(":") && value.has_suffix(":") {
    let inner = normalize_name(value[1:value.length() - 1].trim().to_owned())
    if inner.length() > 0 {
      return (
        if kind is BusinessActor {
          BusinessActor
        } else {
          Actor
        },
        inner,
        inner,
      )
    }
  }
  if value.length() >= 2 && value.has_prefix("[") && value.has_suffix("]") {
    let inner = normalize_name(value[1:value.length() - 1].trim().to_owned())
    if inner.length() > 0 {
      return (Component, inner, inner)
    }
  }
  (kind, display, code)
}

///|
fn visibility_of(raw : String) -> Visibility {
  match raw.to_array() {
    [] => Unknown
    [first, ..] =>
      match first {
        '+' => Public
        '-' => Private
        '#' => Protected
        '~' => Package
        _ => Unknown
      }
  }
}

///|
fn member_of(line : String) -> Member {
  let raw = line.trim().to_owned()
  let is_separator = raw == "--" ||
    raw == ".." ||
    (raw.has_prefix("==") && raw.has_suffix("=="))
  {
    raw,
    visibility: visibility_of(raw),
    is_method: raw.contains("(") && raw.contains(")"),
    is_static: raw.contains("{static}") || raw.contains("static "),
    is_abstract: raw.contains("{abstract}") || raw.contains("abstract "),
    is_separator,
    is_hidden: false,
  }
}

///|
