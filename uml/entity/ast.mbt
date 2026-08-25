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
  BusinessUsecase
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
  BusinessActor
  Person
  Artifact
  Card
  Rectangle
  Hexagon
  Label
  Frame
  Action
  Process
  Stack
  Storage
  Agent
  Boundary
  Control
  Collections
  Port
  PortIn
  PortOut
  Database
  Queue
  Folder
  File
  Node
  Cloud
  State
  LollipopFull
  LollipopHalf
  Point
} derive(Eq, Debug)

///|
pub extend EntityKind with Eq::{not_equal, equal}

///|
pub extend EntityKind with Debug::{to_repr}

///|
pub(all) enum Visibility {
  Public
  Private
  Protected
  Package
  Unknown
} derive(Eq, Debug)

///|
pub extend Visibility with Eq::{not_equal, equal}

///|
pub extend Visibility with Debug::{to_repr}

///|
pub(all) struct Member {
  raw : String
  visibility : Visibility
  is_method : Bool
  is_static : Bool
  is_abstract : Bool
  is_separator : Bool
  is_hidden : Bool
} derive(Eq, Debug)

///|
pub extend Member with Eq::{not_equal, equal}

///|
pub extend Member with Debug::{to_repr}

///|
pub(all) struct Entity {
  code : String
  qualified_code : String
  display : String
  kind : EntityKind
  scope : String
  visibility : Visibility
  is_static : Bool
  generic : String?
  stereotype : String?
  annotation : String?
  is_hidden : Bool
  is_removed : Bool
  fields_hidden : Bool
  methods_hidden : Bool
  stereotype_hidden : Bool
  circle_hidden : Bool
  url : String?
  color : String?
  line_color : String?
  line_style : String?
  tags : Array[String]
  members : Array[Member]
  map_entries : Array[MapEntry]
  json_data : String?
  json_tree : JsonNode?
} derive(Eq, Debug)

///|
pub extend Entity with Eq::{not_equal, equal}

///|
pub extend Entity with Debug::{to_repr}

///|
pub(all) struct MapEntry {
  key : String
  value : String?
  link_target : String?
  raw : String
} derive(Eq, Debug)

///|
pub extend MapEntry with Eq::{not_equal, equal}

///|
pub extend MapEntry with Debug::{to_repr}

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
pub extend RelationKind with Eq::{not_equal, equal}

///|
pub extend RelationKind with Debug::{to_repr}

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
pub extend RelationEnd with Eq::{not_equal, equal}

///|
pub extend RelationEnd with Debug::{to_repr}

///|
pub(all) enum RelationDirection {
  Automatic
  Leftward
  Rightward
  Upward
  Downward
} derive(Eq, Debug)

///|
pub extend RelationDirection with Eq::{not_equal, equal}

///|
pub extend RelationDirection with Debug::{to_repr}

///|
pub(all) struct Relation {
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
  left_couple : (String, String)?
  right_couple : (String, String)?
} derive(Eq, Debug)

///|
pub extend Relation with Eq::{not_equal, equal}

///|
pub extend Relation with Debug::{to_repr}

///|
pub fn Relation::new(
  left : String,
  right : String,
  kind : RelationKind,
  raw_arrow : String,
  left_end : RelationEnd,
  right_end : RelationEnd,
) -> Relation {
  {
    left,
    right,
    kind,
    left_cardinality: None,
    right_cardinality: None,
    left_role: None,
    right_role: None,
    left_qualifier: None,
    right_qualifier: None,
    label: None,
    dotted: raw_arrow.contains("."),
    raw_arrow,
    left_end,
    right_end,
    direction: Automatic,
    line_style: None,
    color: None,
    url: None,
    stereotype: None,
    weight: None,
    inside: None,
    left_port: None,
    right_port: None,
    left_couple: None,
    right_couple: None,
  }
}

///|
pub(all) struct Package {
  name : String
  qualified_name : String
  display : String
  parent : String
  is_namespace : Bool
  visibility : Visibility
  stereotype : String?
  url : String?
  color : String?
  /// PlantUML `CommandPackageWithUSymbol` symbol ("node", "cloud", ...) for
  /// groups opened by a declaration keyword, `None` for plain packages and
  /// namespaces.
  symbol : String?
} derive(Eq, Debug)

///|
pub extend Package with Eq::{not_equal, equal}

///|
pub extend Package with Debug::{to_repr}

///|
pub(all) enum NotePosition {
  Left
  Right
  Top
  Bottom
} derive(Eq, Debug)

///|
pub extend NotePosition with Eq::{not_equal, equal}

///|
pub extend NotePosition with Debug::{to_repr}

///|
pub(all) enum NoteTargetKind {
  EntityNote
  LinkNote
  MemberTip
  FloatingNote
} derive(Eq, Debug)

///|
pub extend NoteTargetKind with Eq::{not_equal, equal}

///|
pub extend NoteTargetKind with Debug::{to_repr}

///|
pub(all) struct Note {
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
  tags : Array[String]
} derive(Eq, Debug)

///|
pub extend Note with Eq::{not_equal, equal}

///|
pub extend Note with Debug::{to_repr}

///|
pub(all) struct LinkConstraint {
  first_relation : Int
  second_relation : Int
  text : String
  color : String?
} derive(Eq, Debug)

///|
pub extend LinkConstraint with Eq::{not_equal, equal}

///|
pub extend LinkConstraint with Debug::{to_repr}

///|
/// The PlantUML diagram family a parsed entity graph belongs to.
///
/// The family selects the parsing policy (`allow_mixing`) and the SVG rendering
/// mode, so diagram-family packages do not need to wrap the shared engine.
pub(all) enum EntityFamily {
  ClassDiagram
  ObjectDiagram
  ComponentDiagram
  UseCaseDiagram
  DeploymentDiagram
  Mbti
} derive(Eq, Debug)

///|
pub extend EntityFamily with Eq::{not_equal, equal}

///|
pub extend EntityFamily with Debug::{to_repr}

///|
/// Whether declarations outside the class grammar may appear without an
/// explicit `allowmixing` directive.
pub fn EntityFamily::allow_mixing(self : EntityFamily) -> Bool {
  self.capability().parser_allow_mixing
}

///|
/// Error text reported when a body block is left open.
pub fn EntityFamily::unclosed_body_message(self : EntityFamily) -> String {
  self.capability().unclosed_body_message
}

///|
/// Whether this family renders with PlantUML's use-case symbols.
pub fn EntityFamily::is_usecase(self : EntityFamily) -> Bool {
  self.capability().usecase_relation_style
}

///|
pub(all) struct EntityDiagram {
  family : EntityFamily
  entities : Array[Entity]
  relations : Array[Relation]
  packages : Array[Package]
  notes : Array[Note]
  constraints : Array[LinkConstraint]
  together_groups : Array[Array[String]]
  style : @style.DocumentStyle
} derive(Eq, Debug)

///|
pub extend EntityDiagram with Eq::{not_equal, equal}

///|
pub extend EntityDiagram with Debug::{to_repr}

///|
pub(all) struct Declaration {
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
  line_color : String?
  line_style : String?
  tags : Array[String]
}

///|
pub(all) struct GroupDeclaration {
  code : String
  display : String
  is_namespace : Bool
  visibility : Visibility
  stereotype : String?
  url : String?
  color : String?
  empty : Bool
  symbol : String?
}

///|
pub(all) enum EntitySelector {
  AllEntities
  KindEntities(EntityKind)
  StereotypedEntities(String)
  NamedEntity(String)
  AnyEntities(Array[EntitySelector])
}

///|
pub(all) enum EntityPortion {
  MemberPortion
  FieldPortion
  MethodPortion
  CirclePortion
  StereotypePortion
}

///|
pub(all) struct PortionRule {
  selector : EntitySelector
  portion : EntityPortion
  show : Bool
  empty_only : Bool
  visibilities : Array[Visibility]
  scope : String
}

///|
pub(all) enum EntityAction {
  HideEntity
  ShowEntity
  RemoveEntity
  RestoreEntity
}

///|
pub(all) struct EntityRule {
  selector : EntitySelector
  action : EntityAction
}

///|
pub fn EntityDiagram::entity(self : EntityDiagram, code : String) -> Entity? {
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
pub fn EntityDiagram::has_entity(self : EntityDiagram, code : String) -> Bool {
  self.entity(code) is Some(_)
}
