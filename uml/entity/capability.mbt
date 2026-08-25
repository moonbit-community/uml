///|
/// Entity nodes are painted relative to relations in different orders across
/// PlantUML diagram families. Description/use-case diagrams put their symbols
/// down first, while class-like diagrams put relation paths behind the nodes.
pub(all) enum EntityPaintOrder {
  EntitiesBeforeRelations
  RelationsBeforeEntities
}

///|
/// Parser and diagram-level rendering policy owned by an entity family.
///
/// Node image selection intentionally lives in `EntityRenderCapability`: the
/// Java `GeneralImageBuilder` chooses an image from `LeafType`, even when that
/// leaf appears in a mixed-family source.
pub(all) struct EntityFamilyCapability {
  parser_allow_mixing : Bool
  unclosed_body_message : String
  aria_label : String
  usecase_relation_style : Bool
  class_members_collapsible : Bool
  paint_order : EntityPaintOrder
  renders_packages : Bool
  renders_notes : Bool
  /// Restricts declarations to PlantUML's description grammar
  /// (`CommandCreateElementFull.ALL_TYPES`), rejecting class-native kinds,
  /// body-opening declarations, and `mix_` prefixes, like the Java
  /// `DescriptionDiagramFactory`.
  description_only : Bool
}

///|
fn base_capability(
  unclosed_body_message : String,
  aria_label : String,
) -> EntityFamilyCapability {
  {
    parser_allow_mixing: false,
    unclosed_body_message,
    aria_label,
    usecase_relation_style: false,
    class_members_collapsible: false,
    paint_order: RelationsBeforeEntities,
    renders_packages: true,
    renders_notes: true,
    description_only: false,
  }
}

///|
pub fn EntityFamily::capability(self : EntityFamily) -> EntityFamilyCapability {
  match self {
    ClassDiagram =>
      {
        ..base_capability("unclosed class body", "Class diagram"),
        class_members_collapsible: true,
      }
    ObjectDiagram => base_capability("unclosed class body", "Object diagram")
    ComponentDiagram =>
      {
        ..base_capability("unclosed component body", "Component diagram"),
        parser_allow_mixing: true,
      }
    UseCaseDiagram =>
      {
        ..base_capability("unclosed use-case body", "Use case diagram"),
        parser_allow_mixing: true,
        usecase_relation_style: true,
        paint_order: EntitiesBeforeRelations,
      }
    DeploymentDiagram =>
      {
        ..base_capability("unclosed element body", "Deployment diagram"),
        parser_allow_mixing: true,
        paint_order: EntitiesBeforeRelations,
        description_only: true,
      }
    Mbti =>
      {
        ..base_capability("unclosed type body", "Mbti diagram"),
        class_members_collapsible: true,
      }
  }
}

///|
pub(all) enum EntityRendererKind {
  ClassRenderer
  ObjectRenderer
  MapRenderer
  JsonRenderer
  LollipopRenderer
  PointRenderer
  UsecaseRenderer
  ActorRenderer
  ComponentRenderer
  DescriptionRenderer
  PortRenderer
}

///|
pub(all) enum EntityHeaderCapability {
  ClassHeader
  ObjectHeader
  DescriptionHeader
}

///|
/// The body variant also fixes the AST field that later renderers consume.
/// Renderers must not parse `Member.raw`, `MapEntry.raw`, or `json_data` again
/// to rediscover a different private model.
pub(all) enum EntityBodyCapability {
  ClassCompartments
  OrderedMembers
  MapEntries
  JsonData
  NoBody
}

///|
pub(all) enum EntityPortCapability {
  MemberPorts
  MapEntryPorts
  JsonTreePorts
  NoPorts
}

///|
pub(all) enum EntitySpotCapability {
  ClassSpot
  NoSpot
}

///|
pub(all) enum EntityRelationEndpointCapability {
  CenterEndpoint
  ShapeBoundaryEndpoint
  PortOrShapeBoundaryEndpoint
}

///|
pub(all) enum EntityStyleRole {
  ClassStyle
  ObjectStyle
  MapStyle
  JsonStyle
  LollipopStyle
  UsecaseStyle
  ActorStyle
  ComponentStyle
  DescriptionStyle
}

///|
/// The single image contract consumed by metrics, Graphviz and SVG painting.
pub(all) struct EntityRenderCapability {
  renderer : EntityRendererKind
  header : EntityHeaderCapability
  body : EntityBodyCapability
  shape : NodeShape
  ports : EntityPortCapability
  spot : EntitySpotCapability
  renders_stereotype : Bool
  relation_endpoint : EntityRelationEndpointCapability
  style_role : EntityStyleRole
}

///|
/// The declaration kinds of PlantUML's description grammar
/// (`CommandCreateElementFull.ALL_TYPES` plus the shape-encoded interface,
/// use-case, actor, and component forms). Kind selection is the only
/// difference between description and class parsing: the Java description
/// factory rejects every other declaration without an `allowmixing` fallback.
pub fn EntityKind::is_description_kind(self : EntityKind) -> Bool {
  self
  is (Person
  | Artifact
  | Actor
  | BusinessActor
  | Folder
  | Card
  | File
  | Rectangle
  | Hexagon
  | Label
  | Node
  | Frame
  | Cloud
  | Action
  | Process
  | Database
  | Queue
  | Stack
  | Storage
  | Agent
  | Usecase
  | BusinessUsecase
  | Component
  | Boundary
  | Control
  | Entity
  | Interface
  | Circle
  | Collections
  | Port
  | PortIn
  | PortOut)
}

///|
/// The image contract of a description symbol leaf: a box with a symbol
/// painted by the description renderer, without compartments or ports.
fn description_leaf_capability() -> EntityRenderCapability {
  {
    renderer: DescriptionRenderer,
    header: DescriptionHeader,
    body: NoBody,
    shape: Box,
    ports: NoPorts,
    spot: NoSpot,
    renders_stereotype: true,
    relation_endpoint: ShapeBoundaryEndpoint,
    style_role: DescriptionStyle,
  }
}

///|
/// The description kinds that render as a plain box symbol leaf, without a
/// dedicated renderer (use-case, actor, component, port) or a non-box shape.
fn EntityKind::is_description_symbol_kind(self : EntityKind) -> Bool {
  self
  is (Person
  | Artifact
  | Folder
  | Card
  | File
  | Rectangle
  | Label
  | Frame
  | Action
  | Process
  | Stack
  | Storage
  | Agent
  | Boundary
  | Control
  | Collections
  | Database
  | Queue
  | Node
  | Cloud
  | Circle)
}

///|
/// Mirrors `GeneralImageBuilder`'s `LeafType` image dispatch. Diagram-family
/// policy is deliberately not used here, so a mixed `object` remains an object
/// image instead of inheriting class compartments from its surrounding source.
///
/// `Interface` and `Entity` are the two kinds whose Java `LeafType` differs
/// across families: the class factory parses them as class-like leaves, while
/// the description factories (component, deployment, use-case) produce a
/// `DESCRIPTION` leaf with the corresponding symbol.
pub fn EntityKind::render_capability(
  self : EntityKind,
  family : EntityFamily,
) -> EntityRenderCapability {
  match self {
    Object =>
      {
        renderer: ObjectRenderer,
        header: ObjectHeader,
        body: OrderedMembers,
        shape: Box,
        ports: MemberPorts,
        spot: NoSpot,
        renders_stereotype: true,
        relation_endpoint: ShapeBoundaryEndpoint,
        style_role: ObjectStyle,
      }
    Map =>
      {
        renderer: MapRenderer,
        header: ObjectHeader,
        body: MapEntries,
        shape: Box,
        ports: MapEntryPorts,
        spot: NoSpot,
        renders_stereotype: true,
        relation_endpoint: PortOrShapeBoundaryEndpoint,
        style_role: MapStyle,
      }
    Json =>
      {
        renderer: JsonRenderer,
        header: ObjectHeader,
        body: JsonData,
        shape: Box,
        ports: JsonTreePorts,
        spot: NoSpot,
        renders_stereotype: true,
        relation_endpoint: PortOrShapeBoundaryEndpoint,
        style_role: JsonStyle,
      }
    Usecase | BusinessUsecase =>
      {
        renderer: UsecaseRenderer,
        header: DescriptionHeader,
        body: NoBody,
        shape: Ellipse,
        ports: NoPorts,
        spot: NoSpot,
        renders_stereotype: true,
        relation_endpoint: ShapeBoundaryEndpoint,
        style_role: UsecaseStyle,
      }
    Actor | BusinessActor =>
      {
        renderer: ActorRenderer,
        header: DescriptionHeader,
        body: NoBody,
        shape: Box,
        ports: NoPorts,
        spot: NoSpot,
        renders_stereotype: true,
        relation_endpoint: ShapeBoundaryEndpoint,
        style_role: ActorStyle,
      }
    Component =>
      {
        renderer: ComponentRenderer,
        header: DescriptionHeader,
        body: NoBody,
        shape: Box,
        ports: NoPorts,
        spot: NoSpot,
        renders_stereotype: false,
        relation_endpoint: ShapeBoundaryEndpoint,
        style_role: ComponentStyle,
      }
    LollipopFull | LollipopHalf =>
      {
        renderer: LollipopRenderer,
        header: DescriptionHeader,
        body: NoBody,
        shape: Circle,
        ports: NoPorts,
        spot: NoSpot,
        renders_stereotype: false,
        relation_endpoint: ShapeBoundaryEndpoint,
        style_role: LollipopStyle,
      }
    Point =>
      {
        renderer: PointRenderer,
        header: DescriptionHeader,
        body: NoBody,
        shape: Circle,
        ports: NoPorts,
        spot: NoSpot,
        renders_stereotype: false,
        relation_endpoint: CenterEndpoint,
        style_role: LollipopStyle,
      }
    Interface if family
      is (ComponentDiagram | DeploymentDiagram | UseCaseDiagram) =>
      description_leaf_capability()
    Entity if family is (ComponentDiagram | DeploymentDiagram | UseCaseDiagram) =>
      description_leaf_capability()
    Port | PortIn | PortOut =>
      {
        ..description_leaf_capability(),
        renderer: PortRenderer,
        renders_stereotype: false,
      }
    _ if self.is_description_symbol_kind() => description_leaf_capability()
    Hexagon => { ..description_leaf_capability(), shape: Hexagon, }
    _ =>
      {
        renderer: ClassRenderer,
        header: ClassHeader,
        body: ClassCompartments,
        shape: Box,
        ports: MemberPorts,
        spot: ClassSpot,
        renders_stereotype: true,
        relation_endpoint: CenterEndpoint,
        style_role: ClassStyle,
      }
  }
}

///|
pub fn Entity::render_capability(
  self : Entity,
  family : EntityFamily,
) -> EntityRenderCapability {
  self.kind.render_capability(family)
}

///|
pub fn EntityRenderCapability::node_class(
  self : EntityRenderCapability,
) -> String {
  match self.style_role {
    ClassStyle => "class-node"
    ObjectStyle => "object-node"
    MapStyle => "map-node"
    JsonStyle => "json-node"
    LollipopStyle => "lollipop-node"
    UsecaseStyle => "usecase-node"
    ActorStyle => "actor-node"
    ComponentStyle => "component-node"
    DescriptionStyle => "description-node"
  }
}

///|
pub fn EntityRenderCapability::title_class(
  self : EntityRenderCapability,
) -> String {
  match self.style_role {
    ObjectStyle => "object-title"
    MapStyle => "map-title"
    JsonStyle => "json-title"
    UsecaseStyle | ActorStyle | ComponentStyle => "usecase-title"
    ClassStyle | LollipopStyle => "class-title"
    DescriptionStyle => "description-title"
  }
}

///|
pub fn EntityRenderCapability::stereotype_class(
  self : EntityRenderCapability,
) -> String {
  match self.style_role {
    ObjectStyle => "object-stereotype"
    MapStyle => "map-stereotype"
    JsonStyle => "json-stereotype"
    UsecaseStyle | ActorStyle => "usecase-stereotype"
    ClassStyle | ComponentStyle | LollipopStyle => "class-stereotype"
    DescriptionStyle => "description-stereotype"
  }
}

///|
pub fn EntityRenderCapability::graphviz_shape(
  self : EntityRenderCapability,
) -> String {
  match (self.shape, self.ports) {
    (Box, MemberPorts | MapEntryPorts | JsonTreePorts | NoPorts) => "box"
    (Ellipse, NoPorts) => "ellipse"
    (Ellipse, _) => "ellipse"
    (Circle, NoPorts) => "circle"
    (Circle, _) => "circle"
    (InterfaceCircle, _) => "box"
    (Hexagon, _) => "hexagon"
  }
}

///|
/// The geometric shape of an entity node, selected by its family and kind.
pub(all) enum NodeShape {
  Box
  Ellipse
  Circle
  InterfaceCircle
  Hexagon
}
