///|
/// Entity nodes are painted relative to relations in different orders across
/// PlantUML diagram families. Description/use-case diagrams put their symbols
/// down first, while class-like diagrams put relation paths behind the nodes.
priv enum EntityPaintOrder {
  EntitiesBeforeRelations
  RelationsBeforeEntities
}

///|
/// Parser and diagram-level rendering policy owned by an entity family.
///
/// Node image selection intentionally lives in `EntityRenderCapability`: the
/// Java `GeneralImageBuilder` chooses an image from `LeafType`, even when that
/// leaf appears in a mixed-family source.
priv struct EntityFamilyCapability {
  parser_allow_mixing : Bool
  unclosed_body_message : String
  aria_label : String
  usecase_relation_style : Bool
  class_members_collapsible : Bool
  paint_order : EntityPaintOrder
  renders_packages : Bool
  renders_notes : Bool
}

///|
fn EntityFamily::capability(self : EntityFamily) -> EntityFamilyCapability {
  match self {
    ClassDiagram =>
      {
        parser_allow_mixing: false,
        unclosed_body_message: "unclosed class body",
        aria_label: "Class diagram",
        usecase_relation_style: false,
        class_members_collapsible: true,
        paint_order: RelationsBeforeEntities,
        renders_packages: true,
        renders_notes: true,
      }
    ObjectDiagram =>
      {
        parser_allow_mixing: false,
        unclosed_body_message: "unclosed class body",
        aria_label: "Object diagram",
        usecase_relation_style: false,
        class_members_collapsible: false,
        paint_order: RelationsBeforeEntities,
        renders_packages: true,
        renders_notes: true,
      }
    ComponentDiagram =>
      {
        parser_allow_mixing: true,
        unclosed_body_message: "unclosed component body",
        aria_label: "Component diagram",
        usecase_relation_style: false,
        class_members_collapsible: false,
        paint_order: RelationsBeforeEntities,
        renders_packages: true,
        renders_notes: true,
      }
    UseCaseDiagram =>
      {
        parser_allow_mixing: true,
        unclosed_body_message: "unclosed use-case body",
        aria_label: "Use case diagram",
        usecase_relation_style: true,
        class_members_collapsible: false,
        paint_order: EntitiesBeforeRelations,
        renders_packages: true,
        renders_notes: true,
      }
    Mbti =>
      {
        parser_allow_mixing: false,
        unclosed_body_message: "unclosed type body",
        aria_label: "Mbti diagram",
        usecase_relation_style: false,
        class_members_collapsible: true,
        paint_order: RelationsBeforeEntities,
        renders_packages: true,
        renders_notes: true,
      }
  }
}

///|
priv enum EntityRendererKind {
  ClassRenderer
  ObjectRenderer
  MapRenderer
  JsonRenderer
  LollipopRenderer
  PointRenderer
  UsecaseRenderer
  ActorRenderer
  ComponentRenderer
}

///|
priv enum EntityHeaderCapability {
  ClassHeader
  ObjectHeader
  DescriptionHeader
}

///|
/// The body variant also fixes the AST field that later renderers consume.
/// Renderers must not parse `Member.raw`, `MapEntry.raw`, or `json_data` again
/// to rediscover a different private model.
priv enum EntityBodyCapability {
  ClassCompartments
  OrderedMembers
  MapEntries
  JsonData
  NoBody
}

///|
priv enum EntityPortCapability {
  MemberPorts
  MapEntryPorts
  JsonTreePorts
  NoPorts
}

///|
priv enum EntitySpotCapability {
  ClassSpot
  NoSpot
}

///|
priv enum EntityRelationEndpointCapability {
  CenterEndpoint
  ShapeBoundaryEndpoint
  PortOrShapeBoundaryEndpoint
}

///|
priv enum EntityStyleRole {
  ClassStyle
  ObjectStyle
  MapStyle
  JsonStyle
  LollipopStyle
  UsecaseStyle
  ActorStyle
  ComponentStyle
}

///|
/// The single image contract consumed by metrics, Graphviz and SVG painting.
priv struct EntityRenderCapability {
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
/// Mirrors `GeneralImageBuilder`'s `LeafType` image dispatch. Diagram-family
/// policy is deliberately not used here, so a mixed `object` remains an object
/// image instead of inheriting class compartments from its surrounding source.
fn EntityKind::render_capability(self : EntityKind) -> EntityRenderCapability {
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
fn Entity::render_capability(self : Entity) -> EntityRenderCapability {
  self.kind.render_capability()
}

///|
fn EntityRenderCapability::node_class(self : EntityRenderCapability) -> String {
  match self.style_role {
    ClassStyle => "class-node"
    ObjectStyle => "object-node"
    MapStyle => "map-node"
    JsonStyle => "json-node"
    LollipopStyle => "lollipop-node"
    UsecaseStyle => "usecase-node"
    ActorStyle => "actor-node"
    ComponentStyle => "component-node"
  }
}

///|
fn EntityRenderCapability::title_class(self : EntityRenderCapability) -> String {
  match self.style_role {
    ObjectStyle => "object-title"
    MapStyle => "map-title"
    JsonStyle => "json-title"
    UsecaseStyle | ActorStyle | ComponentStyle => "usecase-title"
    ClassStyle | LollipopStyle => "class-title"
  }
}

///|
fn EntityRenderCapability::stereotype_class(
  self : EntityRenderCapability,
) -> String {
  match self.style_role {
    ObjectStyle => "object-stereotype"
    MapStyle => "map-stereotype"
    JsonStyle => "json-stereotype"
    UsecaseStyle | ActorStyle => "usecase-stereotype"
    ClassStyle | ComponentStyle | LollipopStyle => "class-stereotype"
  }
}

///|
fn EntityRenderCapability::graphviz_shape(
  self : EntityRenderCapability,
) -> String {
  match (self.shape, self.ports) {
    (Box, MemberPorts | MapEntryPorts | JsonTreePorts | NoPorts) => "box"
    (Ellipse, NoPorts) => "ellipse"
    (Ellipse, _) => "ellipse"
    (Circle, NoPorts) => "circle"
    (Circle, _) => "circle"
  }
}
