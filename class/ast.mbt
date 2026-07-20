///|
pub(all) enum EntityKind {
  Class
  AbstractClass
  Interface
  Enum
  Annotation
  Object
  Entity
  Protocol
  Struct
  Circle
  Usecase
  Exception
  Metaclass
  Stereotype
  Dataclass
  Record
  Map
  Diamond
  Component
  Actor
  Database
  Queue
  Folder
  File
  Node
  Cloud
  State
} derive(Eq, Debug)

///|
pub(all) enum Visibility {
  Public
  Private
  Protected
  Package
  Unknown
} derive(Eq, Debug)

///|
pub struct Member {
  raw : String
  visibility : Visibility
  is_method : Bool
  is_static : Bool
  is_abstract : Bool
  is_separator : Bool
} derive(Eq, Debug)

///|
pub struct Entity {
  code : String
  display : String
  kind : EntityKind
  scope : String
  visibility : Visibility
  is_static : Bool
  generic : String?
  stereotype : String?
  is_hidden : Bool
  url : String?
  color : String?
  members : Array[Member]
} derive(Eq, Debug)

///|
pub(all) enum RelationKind {
  Association
  Dependency
  Extension
  Aggregation
  Composition
  Realization
} derive(Eq, Debug)

///|
pub struct Relation {
  left : String
  right : String
  kind : RelationKind
  left_cardinality : String?
  right_cardinality : String?
  left_role : String?
  right_role : String?
  left_qualifier : String?
  right_qualifier : String?
  label : String?
  dotted : Bool
  raw_arrow : String
} derive(Eq, Debug)

///|
pub struct Package {
  name : String
  parent : String
} derive(Eq, Debug)

///|
pub(all) enum NotePosition {
  Left
  Right
  Top
  Bottom
} derive(Eq, Debug)

///|
pub struct Note {
  target : String
  position : NotePosition
  text : String
} derive(Eq, Debug)

///|
pub struct ClassDiagram {
  entities : Array[Entity]
  relations : Array[Relation]
  packages : Array[Package]
  notes : Array[Note]
  style : @core.DocumentStyle
} derive(Eq, Debug)

///|
priv struct Declaration {
  kind : EntityKind
  code : String
  display : String
  visibility : Visibility
  is_static : Bool
  generic : String?
  stereotype : String?
  extends : String?
  implements : String?
  url : String?
  color : String?
}

///|
pub fn ClassDiagram::entity(self : ClassDiagram, code : String) -> Entity? {
  for entity in self.entities {
    if entity.code == code {
      return Some(entity)
    }
  }
  None
}

///|
pub fn ClassDiagram::has_entity(self : ClassDiagram, code : String) -> Bool {
  self.entity(code) is Some(_)
}
