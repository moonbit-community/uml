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
  Json
  NamedNote
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
  is_hidden : Bool
} derive(Eq, Debug)

///|
pub struct Entity {
  code : String
  qualified_code : String
  display : String
  kind : EntityKind
  scope : String
  visibility : Visibility
  is_static : Bool
  generic : String?
  stereotype : String?
  is_hidden : Bool
  is_removed : Bool
  fields_hidden : Bool
  methods_hidden : Bool
  stereotype_hidden : Bool
  circle_hidden : Bool
  url : String?
  color : String?
  members : Array[Member]
  map_entries : Array[MapEntry]
  json_data : String?
} derive(Eq, Debug)

///|
pub struct MapEntry {
  key : String
  value : String?
  link_target : String?
  raw : String
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
pub(all) enum RelationEnd {
  Plain
  Arrow
  Extension
  CompositionEnd
  AggregationEnd
  NotNavigable
  Redefines
  DefinedBy
  Crowfoot
  CircleCrowfoot
  CircleLine
  DoubleLine
  LineCrowfoot
  TriangleArrow
  CircleEnd
  FilledCircle
  CircleConnect
  Parenthesis
  Square
  Plus
  HalfArrowUp
  HalfArrowDown
} derive(Eq, Debug)

///|
pub(all) enum RelationDirection {
  Automatic
  Leftward
  Rightward
  Upward
  Downward
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
  left_end : RelationEnd
  right_end : RelationEnd
  direction : RelationDirection
  line_style : String?
  color : String?
  url : String?
  stereotype : String?
  weight : String?
  inside : String?
  left_port : String?
  right_port : String?
} derive(Eq, Debug)

///|
pub struct Package {
  name : String
  qualified_name : String
  display : String
  parent : String
  is_namespace : Bool
  visibility : Visibility
  stereotype : String?
  url : String?
  color : String?
} derive(Eq, Debug)

///|
pub(all) enum NotePosition {
  Left
  Right
  Top
  Bottom
} derive(Eq, Debug)

///|
pub(all) enum NoteTargetKind {
  EntityNote
  LinkNote
  MemberTip
  FloatingNote
} derive(Eq, Debug)

///|
pub struct Note {
  target : String
  position : NotePosition
  text : String
  target_kind : NoteTargetKind
  relation_index : Int?
  member_name : String?
  code : String?
  color : String?
  url : String?
  stereotype : String?
} derive(Eq, Debug)

///|
pub struct LinkConstraint {
  first_relation : Int
  second_relation : Int
  text : String
  color : String?
} derive(Eq, Debug)

///|
pub struct ClassDiagram {
  entities : Array[Entity]
  relations : Array[Relation]
  packages : Array[Package]
  notes : Array[Note]
  constraints : Array[LinkConstraint]
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
  extends : Array[String]
  implements : Array[String]
  url : String?
  color : String?
}

///|
priv struct GroupDeclaration {
  code : String
  display : String
  is_namespace : Bool
  visibility : Visibility
  stereotype : String?
  url : String?
  color : String?
  empty : Bool
}

///|
priv enum EntitySelector {
  AllEntities
  KindEntities(EntityKind)
  StereotypedEntities(String)
  NamedEntity(String)
}

///|
priv enum EntityPortion {
  MemberPortion
  FieldPortion
  MethodPortion
  CirclePortion
  StereotypePortion
}

///|
priv struct PortionRule {
  selector : EntitySelector
  portion : EntityPortion
  show : Bool
  empty_only : Bool
  visibilities : Array[Visibility]
  scope : String
}

///|
priv enum EntityAction {
  HideEntity
  ShowEntity
  RemoveEntity
  RestoreEntity
}

///|
priv struct EntityRule {
  selector : EntitySelector
  action : EntityAction
}

///|
pub fn ClassDiagram::entity(self : ClassDiagram, code : String) -> Entity? {
  for entity in self.entities {
    if entity.qualified_code == code {
      return Some(entity)
    }
  }
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
