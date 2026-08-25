///|
fn declaration_kind(word : String) -> @entity.EntityKind? {
  match word.to_lower() {
    "class" => Some(Class)
    "interface" => Some(@entity.EntityKind::Interface)
    "enum" => Some(@entity.EntityKind::Enum)
    "annotation" => Some(@entity.EntityKind::Annotation)
    "object" => Some(Object)
    "entity" => Some(@entity.Entity)
    "protocol" => Some(@entity.EntityKind::Protocol)
    "struct" => Some(@entity.EntityKind::Struct)
    "circle" => Some(Circle)
    "usecase" => Some(@entity.EntityKind::Usecase)
    "usecase/" => Some(@entity.EntityKind::BusinessUsecase)
    "person" => Some(Person)
    "actor/" => Some(@entity.EntityKind::BusinessActor)
    "exception" => Some(@entity.EntityKind::Exception)
    "metaclass" => Some(@entity.EntityKind::Metaclass)
    "stereotype" => Some(Stereotype)
    "dataclass" => Some(@entity.EntityKind::Dataclass)
    "record" => Some(Record)
    "map" => Some(Map)
    "json" => Some(Json)
    "diamond" => Some(Diamond)
    "component" => Some(@entity.EntityKind::Component)
    "boundary" => Some(@entity.EntityKind::Boundary)
    "control" => Some(@entity.EntityKind::Control)
    "port" => Some(Port)
    "portin" => Some(PortIn)
    "portout" => Some(PortOut)
    "actor" => Some(@entity.EntityKind::Actor)
    "database" => Some(@entity.EntityKind::Database)
    "queue" => Some(@entity.EntityKind::Queue)
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
    "collections" => Some(@entity.EntityKind::Collections)
    _ => None
  }
}

///|
fn native_class_kind(kind : @entity.EntityKind) -> Bool {
  kind
  is (Class
  | @entity.EntityKind::AbstractClass
  | @entity.EntityKind::Interface
  | @entity.EntityKind::Enum
  | @entity.EntityKind::Annotation
  | Object
  | @entity.Entity
  | @entity.EntityKind::Protocol
  | @entity.EntityKind::Struct
  | Circle
  | @entity.EntityKind::Exception
  | @entity.EntityKind::Metaclass
  | Stereotype
  | @entity.EntityKind::Dataclass
  | Record
  | Map
  | Json
  | Diamond
  | NamedNote)
}

///|
fn decode_shaped_entity(
  kind : @entity.EntityKind,
  display : String,
  code : String,
) -> (@entity.EntityKind, String, String) {
  let value = display.trim()
  let encoded = if value.length() >= 3 &&
    value.has_prefix("(") &&
    value.has_suffix(")/") {
    Some(
      (
        @entity.EntityKind::BusinessUsecase,
        value[1:value.length() - 2].trim().to_owned(),
      ),
    )
  } else if value.length() >= 2 &&
    value.has_prefix("(") &&
    value.has_suffix(")") {
    Some(
      (
        if kind is @entity.EntityKind::BusinessUsecase {
          @entity.EntityKind::BusinessUsecase
        } else {
          @entity.EntityKind::Usecase
        },
        value[1:value.length() - 1].trim().to_owned(),
      ),
    )
  } else if value.length() >= 3 &&
    value.has_prefix(":") &&
    value.has_suffix(":/") {
    Some(
      (
        @entity.EntityKind::BusinessActor,
        value[1:value.length() - 2].trim().to_owned(),
      ),
    )
  } else if value.length() >= 2 &&
    value.has_prefix(":") &&
    value.has_suffix(":") {
    Some(
      (
        if kind is @entity.EntityKind::BusinessActor {
          @entity.EntityKind::BusinessActor
        } else {
          @entity.EntityKind::Actor
        },
        value[1:value.length() - 1].trim().to_owned(),
      ),
    )
  } else if value.length() >= 2 &&
    value.has_prefix("[") &&
    value.has_suffix("]") {
    Some(
      (
        @entity.EntityKind::Component,
        value[1:value.length() - 1].trim().to_owned(),
      ),
    )
  } else if code.length() >= 3 && code.has_prefix("(") && code.has_suffix(")/") {
    Some(
      (
        @entity.EntityKind::BusinessUsecase,
        code[1:code.length() - 2].trim().to_owned(),
      ),
    )
  } else if code.length() >= 2 && code.has_prefix("(") && code.has_suffix(")") {
    Some(
      (
        if kind is @entity.EntityKind::BusinessUsecase {
          @entity.EntityKind::BusinessUsecase
        } else {
          @entity.EntityKind::Usecase
        },
        code[1:code.length() - 1].trim().to_owned(),
      ),
    )
  } else if code.length() >= 3 && code.has_prefix(":") && code.has_suffix(":/") {
    Some(
      (
        @entity.EntityKind::BusinessActor,
        code[1:code.length() - 2].trim().to_owned(),
      ),
    )
  } else if code.length() >= 2 && code.has_prefix(":") && code.has_suffix(":") {
    Some(
      (
        if kind is @entity.EntityKind::BusinessActor {
          @entity.EntityKind::BusinessActor
        } else {
          @entity.EntityKind::Actor
        },
        code[1:code.length() - 1].trim().to_owned(),
      ),
    )
  } else if code.length() >= 2 && code.has_prefix("[") && code.has_suffix("]") {
    Some(
      (
        @entity.EntityKind::Component,
        code[1:code.length() - 1].trim().to_owned(),
      ),
    )
  } else {
    None
  }
  match encoded {
    Some((shape, raw_inner)) => {
      let inner = @tokenizer.unquote_identifier(raw_inner)
      if inner.length() > 0 {
        let actual_code = if display == code { inner } else { code }
        return (shape, inner, actual_code)
      }
    }
    None => ()
  }
  (kind, display, code)
}

///|
fn visibility_of(raw : String) -> @entity.Visibility {
  match raw.to_array() {
    [] => Unknown
    [first, ..] =>
      match first {
        '+' => Public
        '-' => Private
        '#' => Protected
        '~' => @entity.Package
        _ => Unknown
      }
  }
}

///|
fn member_of(line : String) -> @entity.Member {
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
test "shaped entity decoder normalizes encoded declarations" {
  let (kind, display, code) = decode_shaped_entity(
    Class,
    "(Place order)",
    "(Place order)",
  )
  @test.assert_eq(kind, @entity.EntityKind::Usecase)
  @test.assert_eq(display, "Place order")
  @test.assert_eq(code, "Place order")
}
