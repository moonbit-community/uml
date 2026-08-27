///|
/// SVG rendering of the PlantUML description-family symbols (`USymbol`):
/// the node images of deployment, component and use-case diagrams. Geometry
/// and painting mirror `EntityImageDescription` + each `USymbol.asSmall` /
/// `USymbol.asBig`, while the seeded cloud outline replicates the Java
/// `Random`-driven `USymbolCloud` frontier.

///|
/// One description symbol, mirroring `USymbols` for the description grammar.
priv enum DescriptionSymbol {
  NodeSymbol
  FrameSymbol
  CloudSymbol
  StorageSymbol
  DatabaseSymbol
  QueueSymbol
  StackSymbol
  ArtifactSymbol
  FolderSymbol
  CardSymbol
  FileSymbol
  RectangleSymbol
  HexagonSymbol
  LabelSymbol
  ActionSymbol
  ProcessSymbol
  BoundarySymbol
  ControlSymbol
  EntityDomainSymbol
  CollectionsSymbol
  PersonSymbol
  CircleSymbol
}

///|
/// `EntityImageDescription.getUSymbol`: kind selects the symbol, except the
/// `@entity.EntityKind::Interface`/`@entity.Entity` kinds whose description renderer the capability
/// already restricted to the description families.
fn @entity.Entity::description_symbol(
  self : @entity.Entity,
) -> DescriptionSymbol {
  match self.kind {
    Node => NodeSymbol
    Frame => FrameSymbol
    Cloud => CloudSymbol
    Storage => StorageSymbol
    @entity.EntityKind::Database => DatabaseSymbol
    @entity.EntityKind::Queue => QueueSymbol
    Stack => StackSymbol
    Artifact => ArtifactSymbol
    Folder => FolderSymbol
    Card => CardSymbol
    File => FileSymbol
    Rectangle | Agent => RectangleSymbol
    Hexagon => HexagonSymbol
    Label => LabelSymbol
    Action => ActionSymbol
    Process => ProcessSymbol
    @entity.EntityKind::Boundary => BoundarySymbol
    @entity.EntityKind::Control => ControlSymbol
    @entity.EntityKind::Collections => CollectionsSymbol
    Person => PersonSymbol
    @entity.Entity => EntityDomainSymbol
    Circle | @entity.EntityKind::Interface => CircleSymbol
    _ => panic()
  }
}

///|
/// The label block drawn inside every symbol: the stereotype stacked above
/// the display text, merged to the widest column like `TextBlockUtils.mergeTB`.
priv struct DescriptionTextLayout {
  label_width : Int
  label_height : Int
  block_width : Int
  block_height : Int
  stereotype : String?
  stereotype_width : Int
  stereotype_height : Int
}

///|
fn @entity.Entity::description_text_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> DescriptionTextLayout {
  let label = text_metrics.regular.measure(self.display)
  match self.stereotype {
    Some(value) if !self.stereotype_hidden => {
      let display = @tokenizer.display_stereotype(value)
      // The description stereotype style has no font-size key of its own, so
      // it inherits the element size (italic, same family as the label).
      let stereo = text_metrics.italic.measure(display)
      // `withMargin(block, 1, 0)`: 1px horizontal stereotype margin.
      let stereo_width = stereo.width + 2
      {
        label_width: label.width,
        label_height: label.height,
        block_width: label.width.max(stereo_width),
        block_height: label.height + stereo.height,
        stereotype: Some(display),
        stereotype_width: stereo_width,
        stereotype_height: stereo.height,
      }
    }
    _ =>
      {
        label_width: label.width,
        label_height: label.height,
        block_width: label.width,
        block_height: label.height,
        stereotype: None,
        stereotype_width: 0,
        stereotype_height: 0,
      }
  }
}

///|
/// One symbol margin (left, right, top, bottom) from `USymbol.getMargin`.
fn DescriptionSymbol::margin(self : DescriptionSymbol) -> (Int, Int, Int, Int) {
  match self {
    // `USymbolNode` / `USymbolFrame`
    NodeSymbol | FrameSymbol => (15, 25, 20, 10)
    // `USymbolCloud` with NEW = true
    CloudSymbol => (15, 15, 15, 15)
    StorageSymbol => (10, 10, 10, 10)
    // `USymbolDatabase`
    DatabaseSymbol => (10, 10, 24, 5)
    // `USymbolQueue`
    QueueSymbol => (5, 15, 5, 5)
    // `USymbolStack`
    StackSymbol => (25, 25, 10, 10)
    // `USymbolArtifact` / `USymbolFolder`
    ArtifactSymbol | FolderSymbol => (10, 20, 13, 10)
    // `USymbolCard`
    CardSymbol => (10, 10, 3, 3)
    FileSymbol | RectangleSymbol | HexagonSymbol | LabelSymbol =>
      (10, 10, 10, 10)
    // `USymbolAction`
    ActionSymbol => (10, 20, 10, 10)
    // `USymbolProcess`
    ProcessSymbol => (20, 20, 10, 10)
    // `USymbolPerson`
    PersonSymbol => (10, 10, 10, 10)
    _ => (0, 0, 0, 0)
  }
}

///|
/// Fixed figure sizes of the "simple" symbols: `@entity.EntityKind::Boundary`, `@entity.EntityKind::Control`,
/// `EntityDomain` and `CircleInterface2` all expose a figure whose dimension
/// enters the stacked `mergeLayoutT12B3` layout instead of a margin.
fn DescriptionSymbol::figure_dimension(self : DescriptionSymbol) -> (Int, Int)? {
  match self {
    BoundarySymbol => Some((49, 32))
    ControlSymbol | EntityDomainSymbol => Some((32, 32))
    CircleSymbol => Some((18, 18))
    _ => None
  }
}

///|
/// `USymbol.asSmall.calculateDimension` for the given symbol.
fn @entity.Entity::description_geometry(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int) {
  let text = self.description_text_layout(text_metrics)
  match self.description_symbol() {
    FolderSymbol => {
      // `dimName` is fixed at (40, 15) when the title is hidden.
      let width = 10 + (40).max(text.block_width) + 20
      let height = 13 + 15 + text.block_height + 10
      (width, height)
    }
    HexagonSymbol =>
      // `USymbolHexagon`: twice the text width, text height + 2 * 5 margin.
      (text.block_width * 2, text.block_height + 10)
    PersonSymbol => {
      let body_width = 10 + text.block_width + 10
      let body_height = 10 + text.block_height + 10
      let head_size = (body_width.to_double() * body_height.to_double()).sqrt() *
        0.42
      (body_width, (body_height.to_double() + head_size).ceil().to_int())
    }
    BoundarySymbol | ControlSymbol | EntityDomainSymbol | CircleSymbol => {
      let (figure_width, figure_height) = self
        .description_symbol()
        .figure_dimension()
        .unwrap()
      (
        text.label_width.max(text.stereotype_width).max(figure_width),
        text.stereotype_height + figure_height + text.label_height,
      )
    }
    _ => {
      let (left, right, top, bottom) = self.description_symbol().margin()
      (left + text.block_width + right, top + text.block_height + bottom)
    }
  }
}

///|
/// Top offset of the label block inside the symbol, in node-local
/// coordinates. Margin symbols start their merged block at their vertical
/// margin; the folder reserves its fixed title strip, the hexagon its 5px
/// inset, and the person its head.
fn @entity.Entity::description_label_top(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> Double {
  let (_, _, top, _) = self.description_symbol().margin()
  match self.description_symbol() {
    FolderSymbol => (top + 15).to_double()
    HexagonSymbol => 5.0
    PersonSymbol => {
      let body_width = (10 +
      self.description_text_layout(text_metrics).block_width +
      10).to_double()
      let body_height = (10 +
      self.description_text_layout(text_metrics).block_height +
      10).to_double()
      top.to_double() + (body_width * body_height).sqrt() * 0.42
    }
    _ => top.to_double()
  }
}

///|
/// Where the label block and its stereotype baseline sit inside the symbol,
/// in node-local coordinates.
fn @entity.Entity::description_text_placement(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  width : Int,
  _height : Int,
) -> ((Int, Int), (Int, Int)?) {
  let text = self.description_text_layout(text_metrics)
  match self.description_symbol() {
    BoundarySymbol | ControlSymbol | EntityDomainSymbol => {
      // `mergeLayoutT12B3`: stereotype above the figure, label below it,
      // each centered on the widest column.
      let (_, figure_height) = self
        .description_symbol()
        .figure_dimension()
        .unwrap()
      let label_x = ((width - text.label_width).to_double() / 2.0)
        .round()
        .to_int()
      let label_baseline = text.stereotype_height +
        figure_height +
        text.label_height -
        3
      let stereo_x = ((width - text.stereotype_width).to_double() / 2.0)
        .round()
        .to_int()
      (
        (label_x, label_baseline),
        text.stereotype.map(_stereotype => {
          (stereo_x, text.stereotype_height - 3)
        }),
      )
    }
    CircleSymbol => {
      // The interface hides its text inside the figure (`hideText`): the
      // description is drawn 8px below the 18px figure and the stereotype
      // 8px above it, both overflowing the node box like the Java image.
      let label_x = ((width - text.label_width).to_double() / 2.0)
        .round()
        .to_int()
      let stereo_x = ((width - text.stereotype_width).to_double() / 2.0)
        .round()
        .to_int()
      (
        (label_x, 8 + 18 + text.label_height - 3),
        text.stereotype.map(_stereotype => (stereo_x, -8 - 3)),
      )
    }
    _ => {
      let (left, _right, _, _) = self.description_symbol().margin()
      let label_top = self.description_label_top(text_metrics)
      let block_x = match self.description_symbol() {
        // `USymbolHexagon` starts its block at width/4, not its margin.
        HexagonSymbol => (width.to_double() / 4.0).round().to_int()
        _ => left
      }
      let label_x = block_x + (text.block_width - text.label_width) / 2
      let stereo_x = block_x + (text.block_width - text.stereotype_width) / 2
      let label_baseline = label_top.to_int() +
        text.stereotype_height +
        text.label_height -
        3
      let stereo_baseline = label_top.to_int() + text.stereotype_height - 3
      (
        (label_x, label_baseline),
        text.stereotype.map(_stereotype => (stereo_x, stereo_baseline)),
      )
    }
  }
}

///|
/// Paint one description-symbol node. The border geometry per symbol mirrors
/// the matching `USymbol.drawX` in node-local coordinates.
fn EntityPaintContext::append_description(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let diagram = self.diagram
  let text_metrics = self.text_metrics
  let output = self.output
  let capability = entity.render_capability(diagram.family)
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let fill = @svg.svg_color(
    entity.color,
    capability.style_role.background_color(diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    capability.style_role.border_color(diagram.style),
  )
  let text_color = capability.style_role.font_color(diagram.style)
  let line_attributes = @svg.stroke_style(entity.line_style)
  let stroke_attributes =
    $| stroke="\{stroke}" style="\{line_attributes}"
  let text = entity.description_text_layout(text_metrics)
  let (label_position, stereotype_position) = entity.description_text_placement(
    text_metrics, width, height,
  )
  output <+
    $|<g class="description-node" data-code="\{@svg.xml_escape(entity.qualified_code)}">
  if entity.url is Some(url) {
    output <+
      $|<a href="\{@svg.xml_escape(url)}">
  }
  let symbol_ctx : DescriptionSymbolContext = {
    output,
    entity,
    text_metrics,
    x,
    y,
    width,
    height,
    fill,
    stroke,
    stroke_attributes,
    line_attributes,
  }
  symbol_ctx.append_symbol(entity.description_symbol())
  append_description_text(
    output, entity, text_metrics, text_color, x, y, label_position, stereotype_position,
    text,
  )
  if entity.url is Some(_) {
    output.write_string("</a>")
  }
  output.write_string("</g>\n")
}

///|
/// Everything a description symbol shape needs, bundled so each per-symbol
/// painter stays single-purpose.
priv struct DescriptionSymbolContext {
  output : StringBuilder
  entity : @entity.Entity
  text_metrics : ClassTextMetrics
  x : Int
  y : Int
  width : Int
  height : Int
  fill : String
  stroke : String
  stroke_attributes : String
  line_attributes : String
}

///|
fn DescriptionSymbolContext::append_symbol(
  self : DescriptionSymbolContext,
  symbol : DescriptionSymbol,
) -> Unit {
  match symbol {
    NodeSymbol => self.append_node()
    FrameSymbol => self.append_frame()
    CloudSymbol => self.append_cloud()
    StorageSymbol => self.append_storage()
    DatabaseSymbol => self.append_database()
    QueueSymbol => self.append_queue()
    StackSymbol => self.append_stack()
    ArtifactSymbol => self.append_artifact()
    FolderSymbol => self.append_folder()
    CardSymbol | RectangleSymbol => self.append_rectangle()
    FileSymbol => self.append_file()
    HexagonSymbol => self.append_hexagon()
    LabelSymbol => ()
    ActionSymbol => self.append_action()
    ProcessSymbol => self.append_process()
    BoundarySymbol => self.append_boundary()
    ControlSymbol => self.append_control()
    EntityDomainSymbol => self.append_entity_domain()
    CollectionsSymbol => self.append_collections()
    PersonSymbol => self.append_person()
    CircleSymbol => self.append_circle()
  }
}

///|
fn DescriptionSymbolContext::append_node(
  self : DescriptionSymbolContext,
) -> Unit {
  let output = self.output
  let x = self.x
  let y = self.y
  let width = self.width
  let height = self.height
  output <+
    $|<polygon points="\{x},\{y + 10} \{x + 10},\{y} \{x + width},\{y} \{x + width},\{y + height - 10} \{x + width - 10},\{y + height} \{x},\{y + height} \{x},\{y + 10}" fill="\{self.fill}" \{self.stroke_attributes}/><line x1="\{x + width - 10}" y1="\{y + 10}" x2="\{x + width}" y2="\{y}" stroke="\{self.stroke}" style="\{self.line_attributes}"/><line x1="\{x}" y1="\{y + 10}" x2="\{x + width - 10}" y2="\{y + 10}" stroke="\{self.stroke}" style="\{self.line_attributes}"/><line x1="\{x + width - 10}" y1="\{y + 10}" x2="\{x + width - 10}" y2="\{y + height}" stroke="\{self.stroke}" style="\{self.line_attributes}"/>
}

///|
fn DescriptionSymbolContext::append_frame(
  self : DescriptionSymbolContext,
) -> Unit {
  let text_width = (self.width.to_double() / 3.0).round().to_int()
  self.output <+
    $|<rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="\{self.fill}" \{self.stroke_attributes}/><path d="M \{self.x + text_width} \{self.y} L \{self.x + text_width} \{self.y + 5} L \{self.x + text_width - 7} \{self.y + 12} L \{self.x} \{self.y + 12}" fill="none" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_cloud(
  self : DescriptionSymbolContext,
) -> Unit {
  let path = description_cloud_path(
    self.width.to_double(),
    self.height.to_double(),
    self.x.to_double(),
    self.y.to_double(),
  )
  self.output <+
    $|<path d="\{path}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_storage(
  self : DescriptionSymbolContext,
) -> Unit {
  let radius = (35).min(self.width / 2)
  self.output <+
    $|<rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="\{radius}" ry="\{radius}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_database(
  self : DescriptionSymbolContext,
) -> Unit {
  let half = self.width / 2
  let x = self.x
  let y = self.y
  let width = self.width
  let height = self.height
  self.output <+
    $|<path d="M \{x} \{y + 10} C \{x} \{y} \{x + half} \{y} \{x + half} \{y} C \{x + half} \{y} \{x + width} \{y} \{x + width} \{y + 10} L \{x + width} \{y + height - 10} C \{x + width} \{y + height} \{x + half} \{y + height} \{x + half} \{y + height} C \{x + half} \{y + height} \{x} \{y + height} \{x} \{y + height - 10} L \{x} \{y + 10}" fill="\{self.fill}" \{self.stroke_attributes}/><path d="M \{x} \{y + 10} C \{x} \{y + 20} \{x + half} \{y + 20} \{x + half} \{y + 20} C \{x + half} \{y + 20} \{x + width} \{y + 20} \{x + width} \{y + 10}" fill="none" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_queue(
  self : DescriptionSymbolContext,
) -> Unit {
  let half = self.y + self.height / 2
  let x = self.x
  let y = self.y
  let width = self.width
  let height = self.height
  self.output <+
    $|<path d="M \{x + 5} \{y} L \{x + width - 5} \{y} C \{x + width} \{y} \{x + width} \{half} \{x + width} \{half} C \{x + width} \{half} \{x + width} \{y + height} \{x + width - 5} \{y + height} L \{x + 5} \{y + height} C \{x} \{y + height} \{x} \{half} \{x} \{half} C \{x} \{half} \{x} \{y} \{x + 5} \{y}" fill="\{self.fill}" \{self.stroke_attributes}/><path d="M \{x + width - 5} \{y} C \{x + width - 10} \{y} \{x + width - 10} \{half} \{x + width - 10} \{half} C \{x + width - 10} \{y + height} \{x + width - 5} \{y + height} \{x + width - 5} \{y + height}" fill="none" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_stack(
  self : DescriptionSymbolContext,
) -> Unit {
  let border = 15.0
  let x = self.x.to_double()
  let y = self.y.to_double()
  let width = self.width.to_double()
  let height = self.height.to_double()
  self.output <+
    $|<rect x="\{x + border}" y="\{y}" width="\{width - 2 * border}" height="\{height}" rx="2.5" ry="2.5" fill="\{self.fill}" stroke="none"/><path d="M \{x} \{y} L \{x + border - 2.5} \{y} A2.5,2.5 0 0 1 \{x + border} \{y + 2.5} L \{x + border} \{y + height - 2.5} A2.5,2.5 0 0 0 \{x + border + 2.5} \{y + height} L \{x + width - border - 2.5} \{y + height} A2.5,2.5 0 0 0 \{x + width - border} \{y + height - 2.5} L \{x + width - border} \{y + 2.5} A2.5,2.5 0 0 1 \{x + width - border + 2.5} \{y} L \{x + width} \{y}" fill="none" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_rectangle(
  self : DescriptionSymbolContext,
) -> Unit {
  self.output <+
    $|<rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_artifact(
  self : DescriptionSymbolContext,
) -> Unit {
  let x_symbol = self.x + self.width - 12 - 5
  let y_symbol = self.y + 5
  self.output <+
    $|<rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="\{self.fill}" \{self.stroke_attributes}/><polygon points="\{x_symbol},\{y_symbol} \{x_symbol},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 6} \{x_symbol + 6},\{y_symbol} \{x_symbol},\{y_symbol}" fill="\{self.fill}" \{self.stroke_attributes}/><line x1="\{x_symbol + 6}" y1="\{y_symbol}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" stroke="\{self.stroke}" style="\{self.line_attributes}"/><line x1="\{x_symbol + 12}" y1="\{y_symbol + 6}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" stroke="\{self.stroke}" style="\{self.line_attributes}"/>
}

///|
fn DescriptionSymbolContext::append_folder(
  self : DescriptionSymbolContext,
) -> Unit {
  let x = self.x.to_double()
  let y = self.y.to_double()
  let width = self.width.to_double()
  let height = self.height.to_double()
  let wtitle = 46.0
  let htitle = 21.0
  self.output <+
    $|<path d="M \{x + 2.5} \{y} L \{x + wtitle - 2.5} \{y} A3.75,3.75 0 0 1 \{x + wtitle} \{y + 2.5} L \{x + wtitle + 7} \{y + htitle} L \{x + width - 2.5} \{y + htitle} A2.5,2.5 0 0 1 \{x + width} \{y + htitle + 2.5} L \{x + width} \{y + height - 2.5} A2.5,2.5 0 0 1 \{x + width - 2.5} \{y + height} L \{x + 2.5} \{y + height} A2.5,2.5 0 0 1 \{x} \{y + height - 2.5} L \{x} \{y + 2.5} A2.5,2.5 0 0 1 \{x + 2.5} \{y}" fill="\{self.fill}" \{self.stroke_attributes}/><line x1="\{x}" y1="\{y + htitle}" x2="\{x + wtitle + 7}" y2="\{y + htitle}" stroke="\{self.stroke}" style="\{self.line_attributes}"/>
}

///|
fn DescriptionSymbolContext::append_file(
  self : DescriptionSymbolContext,
) -> Unit {
  let x = self.x.to_double()
  let y = self.y.to_double()
  let width = self.width.to_double()
  let height = self.height.to_double()
  self.output <+
    $|<path d="M \{x} \{y + 2.5} L \{x} \{y + height - 2.5} A2.5,2.5 0 0 0 \{x + 2.5} \{y + height} L \{x + width - 2.5} \{y + height} A2.5,2.5 0 0 0 \{x + width} \{y + height - 2.5} L \{x + width} \{y + 10} L \{x + width - 10} \{y} L \{x + 2.5} \{y} A2.5,2.5 0 0 0 \{x} \{y + 2.5}" fill="\{self.fill}" \{self.stroke_attributes}/><path d="M \{x + width - 10} \{y} L \{x + width - 10} \{y + 7.5} A2.5,2.5 0 0 0 \{x + width - 7.5} \{y + 10} L \{x + width} \{y + 10}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_hexagon(
  self : DescriptionSymbolContext,
) -> Unit {
  let quarter_width = self.width / 4
  let half_height = self.height / 2
  self.output <+
    $|<polygon points="\{self.x + self.width},\{self.y + half_height} \{self.x + self.width - quarter_width},\{self.y} \{self.x + quarter_width},\{self.y} \{self.x},\{self.y + half_height} \{self.x + quarter_width},\{self.y + self.height} \{self.x + self.width - quarter_width},\{self.y + self.height}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_action(
  self : DescriptionSymbolContext,
) -> Unit {
  let half = self.y + self.height / 2
  self.output <+
    $|<polygon points="\{self.x},\{self.y} \{self.x + self.width - 10},\{self.y} \{self.x + self.width},\{half} \{self.x + self.width - 10},\{self.y + self.height} \{self.x},\{self.y + self.height}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_process(
  self : DescriptionSymbolContext,
) -> Unit {
  let half = self.y + self.height / 2
  self.output <+
    $|<polygon points="\{self.x},\{self.y} \{self.x + self.width - 10},\{self.y} \{self.x + self.width},\{half} \{self.x + self.width - 10},\{self.y + self.height} \{self.x},\{self.y + self.height} \{self.x + 10},\{half}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_boundary(
  self : DescriptionSymbolContext,
) -> Unit {
  let (figure_x, figure_y) = self.entity.description_figure_origin(
    self.text_metrics,
    self.width,
  )
  let left = self.x.to_double() + figure_x + 4.0
  let top = self.y.to_double() + figure_y + 4.0
  self.output <+
    $|<path d="M \{left} \{top} L \{left} \{top + 24} M \{left} \{top + 12} L \{left + 17} \{top + 12}" fill="none" \{self.stroke_attributes}/><ellipse cx="\{self.x.to_double() + figure_x + 33}" cy="\{self.y.to_double() + figure_y + 16}" rx="12" ry="12" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_control(
  self : DescriptionSymbolContext,
) -> Unit {
  let (figure_x, figure_y) = self.entity.description_figure_origin(
    self.text_metrics,
    self.width,
  )
  let wing_x = self.x.to_double() + figure_x + 12.0
  let wing_y = self.y.to_double() + figure_y + 4.0
  self.output <+
    $|<ellipse cx="\{self.x.to_double() + figure_x + 16}" cy="\{self.y.to_double() + figure_y + 16}" rx="12" ry="12" fill="\{self.fill}" \{self.stroke_attributes}/><polygon points="\{wing_x},\{wing_y} \{wing_x + 6},\{wing_y - 5} \{wing_x + 4},\{wing_y} \{wing_x + 6},\{wing_y + 5} \{wing_x},\{wing_y}" fill="\{self.stroke}" stroke="\{self.stroke}" stroke-width="1"/>
}

///|
fn DescriptionSymbolContext::append_entity_domain(
  self : DescriptionSymbolContext,
) -> Unit {
  let (figure_x, figure_y) = self.entity.description_figure_origin(
    self.text_metrics,
    self.width,
  )
  self.output <+
    $|<ellipse cx="\{self.x.to_double() + figure_x + 16}" cy="\{self.y.to_double() + figure_y + 16}" rx="12" ry="12" fill="\{self.fill}" \{self.stroke_attributes}/><line x1="\{self.x.to_double() + figure_x + 4}" y1="\{self.y.to_double() + figure_y + 30}" x2="\{self.x.to_double() + figure_x + 28}" y2="\{self.y.to_double() + figure_y + 30}" stroke="\{self.stroke}" style="\{self.line_attributes}"/>
}

///|
fn DescriptionSymbolContext::append_collections(
  self : DescriptionSymbolContext,
) -> Unit {
  self.output <+
    $|<rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="\{self.fill}" \{self.stroke_attributes}/><rect x="\{self.x - 4}" y="\{self.y - 4}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_person(
  self : DescriptionSymbolContext,
) -> Unit {
  let text = self.entity.description_text_layout(self.text_metrics)
  let body_width = 10 + text.block_width + 10
  let body_height = 10 + text.block_height + 10
  let head_size = (body_width.to_double() * body_height.to_double()).sqrt() *
    0.42
  let head_x = self.x.to_double() + (body_width.to_double() - head_size) / 2.0
  let body_x = self.x.to_double() +
    self.width.to_double() / 2.0 -
    body_width.to_double() / 2.0
  self.output <+
    $|<ellipse cx="\{head_x + head_size / 2.0}" cy="\{self.y.to_double() + head_size / 2.0}" rx="\{head_size / 2.0}" ry="\{head_size / 2.0}" fill="\{self.fill}" \{self.stroke_attributes}/><rect x="\{body_x}" y="\{self.y.to_double() + head_size}" width="\{body_width.to_double()}" height="\{body_height.to_double()}" rx="\{head_size / 2.0}" ry="\{head_size / 2.0}" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn DescriptionSymbolContext::append_circle(
  self : DescriptionSymbolContext,
) -> Unit {
  let (figure_x, figure_y) = self.entity.description_figure_origin(
    self.text_metrics,
    self.width,
  )
  self.output <+
    $|<ellipse cx="\{self.x.to_double() + figure_x + 9}" cy="\{self.y.to_double() + figure_y + 9}" rx="8" ry="8" fill="\{self.fill}" \{self.stroke_attributes}/>
}

///|
fn append_description_text(
  output : StringBuilder,
  entity : @entity.Entity,
  text_metrics : ClassTextMetrics,
  text_color : String,
  x : Int,
  y : Int,
  label_position : (Int, Int),
  stereotype_position : (Int, Int)?,
  text : DescriptionTextLayout,
) -> Unit {
  if stereotype_position is Some((stereotype_x, stereotype_baseline)) {
    append_paint_text(
      output,
      x + stereotype_x,
      y + stereotype_baseline,
      text.stereotype.unwrap(),
      "description-stereotype",
      text_metrics.regular,
      fill=text_color,
      font_size=text_metrics.regular.font_size,
    )
  }
  append_paint_text(
    output,
    x + label_position.0,
    y + label_position.1,
    entity.display,
    "description-title",
    text_metrics.regular,
    fill=text_color,
  )
}

///|
/// Node-local origin of a simple-symbol figure: centered horizontally, below
/// the stereotype strip like `USymbolSimpleAbstract.asSmall`.
fn @entity.Entity::description_figure_origin(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  width : Int,
) -> (Double, Double) {
  let (figure_width, _) = self.description_symbol().figure_dimension().unwrap()
  let figure_x = (width.to_double() - figure_width.to_double()) / 2.0
  let figure_y = self.description_text_layout(text_metrics).stereotype_height.to_double()
  (figure_x, figure_y)
}

///|
/// `java.util.Random` LCG replica: `USymbolCloud` seeds one instance with
/// `(long) width + 7919L * (long) height` and consumes it in a fixed order,
/// so the outline is deterministic for a given node size.
priv struct JavaRandom {
  mut seed : Int64
}

///|
fn JavaRandom::new(seed : Int64) -> JavaRandom {
  { seed: (seed ^ 0x5DEECE66DL) & 0xFFFFFFFFFFFFL }
}

///|
fn JavaRandom::next(self : JavaRandom, bits : Int) -> Int {
  self.seed = (self.seed * 0x5DEECE66DL + 0xBL) & 0xFFFFFFFFFFFFL
  (self.seed >> (48 - bits)).to_int()
}

///|
fn JavaRandom::next_double(self : JavaRandom) -> Double {
  let high = self.next(26)
  let low = self.next(27)
  (Int64::from_int(high << 27) + Int64::from_int(low)).to_double() /
  9007199254740992.0
}

///|
fn JavaRandom::ranged(self : JavaRandom, low : Double, high : Double) -> Double {
  self.next_double() * (high - low) + low
}

///|
/// `CoordinateChange`: a length-preserving local frame along a segment.
priv struct CoordinateChange {
  x1 : Double
  y1 : Double
  vect_u_x : Double
  vect_u_y : Double
  vect_v_x : Double
  vect_v_y : Double
  len : Double
}

///|
fn CoordinateChange::create(
  p1 : (Double, Double),
  p2 : (Double, Double),
) -> CoordinateChange {
  let dx = p2.0 - p1.0
  let dy = p2.1 - p1.1
  let len = (dx * dx + dy * dy).sqrt()
  let vect_u_x = (p2.0 - p1.0) / len
  let vect_u_y = (p2.1 - p1.1) / len
  {
    x1: p1.0,
    y1: p1.1,
    vect_u_x,
    vect_u_y,
    vect_v_x: -vect_u_y,
    vect_v_y: vect_u_x,
    len,
  }
}

///|
fn CoordinateChange::true_coordinate(
  self : CoordinateChange,
  a : Double,
  b : Double,
) -> (Double, Double) {
  (
    self.x1 + a * self.vect_u_x + b * self.vect_v_x,
    self.y1 + a * self.vect_u_y + b * self.vect_v_y,
  )
}

///|
fn description_cloud_points_on_segment(
  random : JavaRandom,
  points : Array[(Double, Double)],
  p1 : (Double, Double),
  p2 : (Double, Double),
  bubble_size : Double,
) -> Unit {
  let change = CoordinateChange::create(p1, p2)
  let length = change.len
  let mut bubble_size = bubble_size
  let mut nb = (length / bubble_size).to_int()
  if nb == 0 {
    bubble_size = length / 2.0
    nb = (length / bubble_size).to_int()
  }
  for i in 0..<nb {
    let (x, y) = change.true_coordinate(
      i.to_double() * length / nb.to_double(),
      0.0,
    )
    let dx = bubble_size * 0.2 * random.next_double()
    let dy = bubble_size * 0.2 * random.next_double()
    points.push((x + dx, y + dy))
  }
}

///|
fn description_cloud_special_line(
  random : JavaRandom,
  points : Array[(Double, Double)],
  p1 : (Double, Double),
  p2 : (Double, Double),
  bubble_size : Double,
) -> Unit {
  let change = CoordinateChange::create(p1, p2)
  let length = change.len
  let offset = -random.ranged(1.0, 1.0 + 12.0.min(bubble_size * 0.8))
  let middle = change.true_coordinate(length / 2.0, offset)
  description_cloud_points_on_segment(random, points, p1, middle, bubble_size)
  description_cloud_points_on_segment(random, points, middle, p2, bubble_size)
}

///|
fn description_cloud_curve(
  random : JavaRandom,
  output : StringBuilder,
  p1 : (Double, Double),
  p2 : (Double, Double),
) -> Unit {
  let change = CoordinateChange::create(p1, p2)
  let length = change.len
  let coef = random.ranged(0.25, 0.35)
  let (m1x, m1y) = change.true_coordinate(
    length * coef,
    -length * random.ranged(0.4, 0.55),
  )
  let (m2x, m2y) = change.true_coordinate(
    length * (1.0 - coef),
    -length * random.ranged(0.4, 0.55),
  )
  output <+
    $| C \{m1x},\{m1y} \{m2x},\{m2y} \{p2.0},\{p2.1}
}

///|
/// `USymbolCloud.getSpecificFrontierForCloudNew`: a wavy frontier whose
/// random offsets are seeded by the node size.
fn description_cloud_path(
  width : Double,
  height : Double,
  origin_x : Double,
  origin_y : Double,
) -> String {
  let random = JavaRandom::new(width.to_int64() + 7919L * height.to_int64())
  let mut bubble_size = 11.0
  let max_dim = width.max(height)
  if max_dim / bubble_size > 16.0 {
    bubble_size = max_dim / 16.0
  }
  let margin1 = 8.0
  let point_a = (margin1, margin1)
  let point_b = (width - margin1, margin1)
  let point_c = (width - margin1, height - margin1)
  let point_d = (margin1, height - margin1)
  let points : Array[(Double, Double)] = []
  if width > 100.0 && height > 100.0 {
    let margin2 = 7.0
    description_cloud_special_line(
      random,
      points,
      (point_a.0 + margin2, point_a.1),
      (point_b.0 - margin2, point_b.1),
      bubble_size,
    )
    points.push((point_b.0, point_b.1 + margin2))
    description_cloud_special_line(
      random,
      points,
      (point_b.0, point_b.1 + margin2),
      (point_c.0, point_c.1 - margin2),
      bubble_size,
    )
    points.push((point_c.0 - margin2, point_c.1))
    description_cloud_special_line(
      random,
      points,
      (point_c.0 - margin2, point_c.1),
      (point_d.0 + margin2, point_d.1),
      bubble_size,
    )
    points.push((point_d.0, point_d.1 - margin2))
    description_cloud_special_line(
      random,
      points,
      (point_d.0, point_d.1 - margin2),
      (point_a.0, point_a.1 + margin2),
      bubble_size,
    )
    points.push((point_a.0 + margin2, point_a.1))
  } else {
    description_cloud_special_line(
      random, points, point_a, point_b, bubble_size,
    )
    description_cloud_special_line(
      random, points, point_b, point_c, bubble_size,
    )
    description_cloud_special_line(
      random, points, point_c, point_d, bubble_size,
    )
    description_cloud_special_line(
      random, points, point_d, point_a, bubble_size,
    )
  }
  points.push(points[0])
  let output = StringBuilder()
  output <+ "M \{origin_x + points[0].0},\{origin_y + points[0].1}"
  for i in 0..<(points.length() - 1) {
    description_cloud_curve(
      random,
      output,
      (origin_x + points[i].0, origin_y + points[i].1),
      (origin_x + points[i + 1].0, origin_y + points[i + 1].1),
    )
  }
  output.to_string()
}

///|
/// `EntityImagePort`: a fixed 12x12 square whose label sits above or below
/// depending on the port position inside its parent cluster.
fn EntityPaintContext::append_port(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let diagram = self.diagram
  let text_metrics = self.text_metrics
  let output = self.output
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let up = match layout.graphviz {
    Some(graphviz) => {
      let mut result = false
      for package_layout in graphviz.packages {
        guard package_layout.package_index < diagram.packages.length() else {
          continue
        }
        if diagram.packages[package_layout.package_index].qualified_name ==
          entity.scope {
          result = y.to_double() <
            package_layout.y + package_layout.height / 2.0
        }
      }
      result
    }
    None => false
  }
  let fill = @svg.svg_color(
    entity.color,
    diagram.style.defaults().entity_colors().node,
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    diagram.style.diagram_line_color(),
  )
  let metrics = text_metrics.regular.measure(entity.display)
  let label_x = x - (metrics.width - width) / 2
  let label_y = if up {
    // `EntityImagePort`: the label block sits above the rect with an 8px
    // overlap gap; the block height cancels out of the baseline.
    y - width - 3
  } else {
    y + height + metrics.height - 3
  }
  output <+
    $|<g class="port-node" data-code="\{@svg.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}" stroke="\{stroke}" stroke-width="\{@svg.emphasized_stroke_width()}"/>
  append_paint_text(
    output,
    label_x,
    label_y,
    entity.display,
    "port-title",
    text_metrics.regular,
    fill=diagram.style.diagram_text_color(),
  )
  output.write_string("</g>")
}

///|
/// `EntityImageGroup`/`USymbol.asBig`: a declaration keyword opened with `{`
/// draws the symbol over its whole cluster rectangle, with the bold title
/// (and stereotype) placed by the symbol.
fn append_symbol_packages(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  if layout.graphviz is Some(graphviz) {
    for package_layout in graphviz.packages {
      guard package_layout.package_index < diagram.packages.length() else {
        continue
      }
      let group = diagram.packages[package_layout.package_index]
      if group.symbol is Some(symbol) {
        // PlantUML `Cluster.manageEntryExitPoint` runs the port centers
        // through the `FrontierCalculator` so the cluster border passes
        // through the ports of a node symbol.
        let (adjusted_y, adjusted_height) = port_frontier(
          diagram,
          group.qualified_name,
          package_layout.y,
          package_layout.y + package_layout.height,
          text_metrics,
          layout,
        )
        append_symbol_package(
          output,
          diagram,
          group,
          symbol,
          package_layout.x,
          adjusted_y,
          package_layout.width,
          adjusted_height,
          text_metrics,
        )
      }
    }
  }
}

///|
/// `FrontierCalculator` for ports: the top border moves to the source port
/// centers and the bottom border to the sink port centers; sides without
/// ports keep the Graphviz box.
fn port_frontier(
  diagram : @entity.EntityDiagram,
  scope : String,
  box_top : Double,
  box_bottom : Double,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> (Double, Double) {
  let mut top = box_top
  let mut bottom = box_bottom
  for index, entity in diagram.entities {
    guard entity.scope == scope && !entity.is_hidden && !entity.is_removed else {
      continue
    }
    let (_, y, _, height) = layout.entity_rect(diagram, index, text_metrics)
    match entity.kind {
      // Source ports sit at the top rank, so their centers are the topmost
      // frontier; sink ports at the bottom rank anchor the bottom border.
      Port | PortIn => top = top.max(y.to_double() + height.to_double() / 2.0)
      PortOut => bottom = bottom.min(y.to_double() + height.to_double() / 2.0)
      _ => ()
    }
  }
  (top, bottom - top)
}

///|
fn append_symbol_package(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  group : @entity.Package,
  symbol : String,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  text_metrics : ClassTextMetrics,
) -> Unit {
  let stroke = @entity.package_border_color(diagram.style)
  let title = text_metrics.regular.measure(group.display)
  let stereo = group.stereotype.map(value => {
    let display = @tokenizer.display_stereotype(value)
    let metrics = text_metrics.italic.measure(display)
    (display, metrics.width.to_double() + 2, metrics.height.to_double())
  })
  let symbol_ctx : SymbolPackageContext = {
    output,
    group,
    text_metrics,
    x,
    y,
    width,
    height,
    title_width: title.width.to_double(),
    title_height: title.height.to_double(),
    stereo,
    stroke_attributes: (
      $| stroke="\{stroke}" style="stroke-width:\{@svg.standard_border_stroke_width()}"
    ),
  }
  match symbol {
    "node" => symbol_ctx.append_node()
    "frame" => symbol_ctx.append_frame()
    "cloud" => symbol_ctx.append_cloud()
    "database" => symbol_ctx.append_database()
    "queue" => symbol_ctx.append_queue()
    "stack" => symbol_ctx.append_stack()
    "storage" => symbol_ctx.append_storage()
    "artifact" => symbol_ctx.append_artifact()
    "card" => symbol_ctx.append_card()
    "file" => symbol_ctx.append_file()
    "hexagon" => symbol_ctx.append_hexagon()
    "rectangle" => symbol_ctx.append_rectangle()
    "action" => symbol_ctx.append_action()
    "process" => symbol_ctx.append_process()
    "component" => symbol_ctx.append_component()
    "folder" => symbol_ctx.append_folder()
    _ => ()
  }
}

///|
/// Everything a symbol package branch needs, bundled to keep the per-shape
/// painters single-purpose.
priv struct SymbolPackageContext {
  output : StringBuilder
  group : @entity.Package
  text_metrics : ClassTextMetrics
  x : Double
  y : Double
  width : Double
  height : Double
  title_width : Double
  title_height : Double
  stereo : (String, Double, Double)?
  stroke_attributes : String
}

///|
fn SymbolPackageContext::append_label(
  self : SymbolPackageContext,
  title_x : Double,
  title_y : Double,
  stereo_position : (Double, Double)?,
) -> Unit {
  append_symbol_package_text(
    self.output,
    self.group,
    self.text_metrics,
    title_x,
    title_y,
    self.stereo.bind(triple => {
      stereo_position.map(pos => (triple.0, pos.0, pos.1))
    }),
  )
  self.output.write_string("</g>\n")
}

///|
/// The most common symbol layout: title and stereotype centered, with the
/// given baseline offsets.
fn SymbolPackageContext::append_centered_label(
  self : SymbolPackageContext,
  title_y : Double,
  stereo_y : Double,
) -> Unit {
  self.append_label(
    self.x + (self.width - self.title_width) / 2.0,
    self.y + title_y,
    self.stereo.map(triple => {
      (self.x + (self.width - triple.1) / 2.0, self.y + stereo_y)
    }),
  )
}

///|
fn SymbolPackageContext::append_node(self : SymbolPackageContext) -> Unit {
  self.output <+
    $|<g class="symbol-package"><polygon points="\{self.x},\{self.y + 10} \{self.x + 10},\{self.y} \{self.x + self.width},\{self.y} \{self.x + self.width},\{self.y + self.height - 10} \{self.x + self.width - 10},\{self.y + self.height} \{self.x},\{self.y + self.height} \{self.x},\{self.y + 10}" fill="none" \{self.stroke_attributes}/><line x1="\{self.x + self.width - 10}" y1="\{self.y + 10}" x2="\{self.x + self.width}" y2="\{self.y}" \{self.stroke_attributes}/><line x1="\{self.x}" y1="\{self.y + 10}" x2="\{self.x + self.width - 10}" y2="\{self.y + 10}" \{self.stroke_attributes}/><line x1="\{self.x + self.width - 10}" y1="\{self.y + 10}" x2="\{self.x + self.width - 10}" y2="\{self.y + self.height}" \{self.stroke_attributes}/>
  self.append_label(
    self.x + (self.width - self.title_width) / 2.0 - 4.0,
    self.y + 13.0,
    self.stereo.map(triple => {
      (self.x + (self.width - triple.1) / 2.0 - 4.0, self.y + 13.0)
    }),
  )
}

///|
fn SymbolPackageContext::append_frame(self : SymbolPackageContext) -> Unit {
  let text_width = self.title_width + 10.0
  let text_height = self.title_height + 3.0
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="none" \{self.stroke_attributes}/><path d="M \{self.x + text_width} \{self.y} L \{self.x + text_width} \{self.y + text_height - 10} L \{self.x + text_width - 10} \{self.y + text_height} L \{self.x} \{self.y + text_height}" fill="none" \{self.stroke_attributes}/>
  self.append_label(
    self.x + 3.0,
    self.y + 1.0,
    self.stereo.map(triple => {
      (self.x + 4.0 + (self.width - triple.1) / 2.0, self.y + 2.0 + text_height)
    }),
  )
}

///|
fn SymbolPackageContext::append_cloud(self : SymbolPackageContext) -> Unit {
  let path = description_cloud_path(self.width, self.height, self.x, self.y)
  self.output <+
    $|<g class="symbol-package"><path d="\{path}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(13.0, 13.0)
}

///|
fn SymbolPackageContext::append_database(self : SymbolPackageContext) -> Unit {
  let half = self.width / 2.0
  self.output <+
    $|<g class="symbol-package"><path d="M \{self.x} \{self.y + 10} C \{self.x} \{self.y} \{self.x + half} \{self.y} \{self.x + half} \{self.y} C \{self.x + half} \{self.y} \{self.x + self.width} \{self.y} \{self.x + self.width} \{self.y + 10} L \{self.x + self.width} \{self.y + self.height - 10} C \{self.x + self.width} \{self.y + self.height} \{self.x + half} \{self.y + self.height} \{self.x + half} \{self.y + self.height} C \{self.x + half} \{self.y + self.height} \{self.x} \{self.y + self.height} \{self.x} \{self.y + self.height - 10} L \{self.x} \{self.y + 10}" fill="none" \{self.stroke_attributes}/><path d="M \{self.x} \{self.y + 10} C \{self.x} \{self.y + 20} \{self.x + half} \{self.y + 20} \{self.x + half} \{self.y + 20} C \{self.x + half} \{self.y + 20} \{self.x + self.width} \{self.y + 20} \{self.x + self.width} \{self.y + 10}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(22.0, 22.0)
}

///|
fn SymbolPackageContext::append_queue(self : SymbolPackageContext) -> Unit {
  let half = self.y + self.height / 2.0
  self.output <+
    $|<g class="symbol-package"><path d="M \{self.x + 5} \{self.y} L \{self.x + self.width - 5} \{self.y} C \{self.x + self.width} \{self.y} \{self.x + self.width} \{half} \{self.x + self.width} \{half} C \{self.x + self.width} \{half} \{self.x + self.width} \{self.y + self.height} \{self.x + self.width - 5} \{self.y + self.height} L \{self.x + 5} \{self.y + self.height} C \{self.x} \{self.y + self.height} \{self.x} \{half} \{self.x} \{half} C \{self.x} \{half} \{self.x} \{self.y} \{self.x + 5} \{self.y}" fill="none" \{self.stroke_attributes}/><path d="M \{self.x + self.width - 5} \{self.y} C \{self.x + self.width - 10} \{self.y} \{self.x + self.width - 10} \{half} \{self.x + self.width - 10} \{half} C \{self.x + self.width - 10} \{self.y + self.height} \{self.x + self.width - 5} \{self.y + self.height} \{self.x + self.width - 5} \{self.y + self.height}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_stack(self : SymbolPackageContext) -> Unit {
  let border = 15.0
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x + border}" y="\{self.y}" width="\{self.width - 2 * border}" height="\{self.height}" rx="2.5" ry="2.5" fill="none" stroke="none"/><path d="M \{self.x} \{self.y} L \{self.x + border - 2.5} \{self.y} A2.5,2.5 0 0 1 \{self.x + border} \{self.y + 2.5} L \{self.x + border} \{self.y + self.height - 2.5} A2.5,2.5 0 0 0 \{self.x + border + 2.5} \{self.y + self.height} L \{self.x + self.width - border - 2.5} \{self.y + self.height} A2.5,2.5 0 0 0 \{self.x + self.width - border} \{self.y + self.height - 2.5} L \{self.x + self.width - border} \{self.y + 2.5} A2.5,2.5 0 0 1 \{self.x + self.width - border + 2.5} \{self.y} L \{self.x + self.width} \{self.y}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_storage(self : SymbolPackageContext) -> Unit {
  let radius = (35).min((self.width / 2.0).to_int())
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="\{radius}" ry="\{radius}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(7.0, 5.0)
}

///|
fn SymbolPackageContext::append_artifact(self : SymbolPackageContext) -> Unit {
  let x_symbol = self.x + self.width - 17.0
  let y_symbol = self.y + 5.0
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="none" \{self.stroke_attributes}/><polygon points="\{x_symbol},\{y_symbol} \{x_symbol},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 6} \{x_symbol + 6},\{y_symbol} \{x_symbol},\{y_symbol}" fill="none" \{self.stroke_attributes}/><line x1="\{x_symbol + 6}" y1="\{y_symbol}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" \{self.stroke_attributes}/><line x1="\{x_symbol + 12}" y1="\{y_symbol + 6}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_card(self : SymbolPackageContext) -> Unit {
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_file(self : SymbolPackageContext) -> Unit {
  self.output <+
    $|<g class="symbol-package"><path d="M \{self.x} \{self.y + 2.5} L \{self.x} \{self.y + self.height - 2.5} A2.5,2.5 0 0 0 \{self.x + 2.5} \{self.y + self.height} L \{self.x + self.width - 2.5} \{self.y + self.height} A2.5,2.5 0 0 0 \{self.x + self.width} \{self.y + self.height - 2.5} L \{self.x + self.width} \{self.y + 10} L \{self.x + self.width - 10} \{self.y} L \{self.x + 2.5} \{self.y} A2.5,2.5 0 0 0 \{self.x} \{self.y + 2.5}" fill="none" \{self.stroke_attributes}/><path d="M \{self.x + self.width - 10} \{self.y} L \{self.x + self.width - 10} \{self.y + 7.5} A2.5,2.5 0 0 0 \{self.x + self.width - 7.5} \{self.y + 10} L \{self.x + self.width} \{self.y + 10}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_hexagon(self : SymbolPackageContext) -> Unit {
  let quarter_width = self.width / 4.0
  let half_height = self.height / 2.0
  self.output <+
    $|<g class="symbol-package"><polygon points="\{self.x + self.width},\{self.y + half_height} \{self.x + self.width - quarter_width},\{self.y} \{self.x + quarter_width},\{self.y} \{self.x},\{self.y + half_height} \{self.x + quarter_width},\{self.y + self.height} \{self.x + self.width - quarter_width},\{self.y + self.height}" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_rectangle(self : SymbolPackageContext) -> Unit {
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_action(self : SymbolPackageContext) -> Unit {
  let half = self.y + self.height / 2.0
  self.output <+
    $|<g class="symbol-package"><polygon points="\{self.x},\{self.y} \{self.x + self.width - 10},\{self.y} \{self.x + self.width},\{half} \{self.x + self.width - 10},\{self.y + self.height} \{self.x},\{self.y + self.height}" fill="none" \{self.stroke_attributes}/>
  self.append_label(
    self.x + (self.width - self.title_width) / 2.0,
    self.y + 2.0,
    self.stereo.map(triple => {
      (
        self.x + 4.0 + (self.width - triple.1) / 2.0,
        self.y + 2.0 + self.title_height,
      )
    }),
  )
}

///|
fn SymbolPackageContext::append_process(self : SymbolPackageContext) -> Unit {
  let half = self.y + self.height / 2.0
  self.output <+
    $|<g class="symbol-package"><polygon points="\{self.x},\{self.y} \{self.x + self.width - 10},\{self.y} \{self.x + self.width},\{half} \{self.x + self.width - 10},\{self.y + self.height} \{self.x},\{self.y + self.height} \{self.x + 10},\{half}" fill="none" \{self.stroke_attributes}/>
  self.append_label(
    self.x + (self.width - self.title_width) / 2.0,
    self.y + 2.0,
    self.stereo.map(triple => {
      (
        self.x + 4.0 + (self.width - triple.1) / 2.0,
        self.y + 2.0 + self.title_height,
      )
    }),
  )
}

///|
fn SymbolPackageContext::append_component(self : SymbolPackageContext) -> Unit {
  self.output <+
    $|<g class="symbol-package"><rect x="\{self.x}" y="\{self.y}" width="\{self.width}" height="\{self.height}" rx="2.5" ry="2.5" fill="none" \{self.stroke_attributes}/><rect x="\{self.x + self.width - 20}" y="\{self.y + 5}" width="15" height="10" fill="none" \{self.stroke_attributes}/><rect x="\{self.x + self.width - 22}" y="\{self.y + 7}" width="4" height="2" fill="none" \{self.stroke_attributes}/><rect x="\{self.x + self.width - 22}" y="\{self.y + 11}" width="4" height="2" fill="none" \{self.stroke_attributes}/>
  self.append_centered_label(13.0, 13.0)
}

///|
fn SymbolPackageContext::append_folder(self : SymbolPackageContext) -> Unit {
  let wtitle = self.title_width + 6.0
  let htitle = self.title_height + 6.0
  self.output <+
    $|<g class="symbol-package"><path d="M \{self.x + 2.5} \{self.y} L \{self.x + wtitle - 2.5} \{self.y} A3.75,3.75 0 0 1 \{self.x + wtitle} \{self.y + 2.5} L \{self.x + wtitle + 7} \{self.y + htitle} L \{self.x + self.width - 2.5} \{self.y + htitle} A2.5,2.5 0 0 1 \{self.x + self.width} \{self.y + htitle + 2.5} L \{self.x + self.width} \{self.y + self.height - 2.5} A2.5,2.5 0 0 1 \{self.x + self.width - 2.5} \{self.y + self.height} L \{self.x + 2.5} \{self.y + self.height} A2.5,2.5 0 0 1 \{self.x} \{self.y + self.height - 2.5} L \{self.x} \{self.y + 2.5} A2.5,2.5 0 0 1 \{self.x + 2.5} \{self.y}" fill="none" \{self.stroke_attributes}/><line x1="\{self.x}" y1="\{self.y + htitle}" x2="\{self.x + wtitle + 7}" y2="\{self.y + htitle}" \{self.stroke_attributes}/>
  self.append_label(
    self.x + 4.0,
    self.y + 2.0,
    self.stereo.map(triple => {
      (self.x + 4.0 + (self.width - triple.1) / 2.0, self.y + 2.0 + htitle)
    }),
  )
}

///|
fn append_symbol_package_text(
  output : StringBuilder,
  group : @entity.Package,
  text_metrics : ClassTextMetrics,
  title_x : Double,
  title_top : Double,
  stereo : (String, Double, Double)?,
) -> Unit {
  match stereo {
    Some((display, x, top)) => {
      let stereo_height = text_metrics.italic.measure(display).height.to_double()
      output.write_string(
        @svg.text_markup(
          x,
          top + stereo_height - 3.0,
          display,
          [("class", "package-stereotype")],
          text_metrics.italic,
        ),
      )
      output.write_char('\n')
    }
    None => ()
  }
  let title_height = text_metrics.regular.measure(group.display).height.to_double()
  output.write_string(
    @svg.text_markup(
      title_x,
      title_top + title_height - 3.0,
      group.display,
      [("class", "package-title")],
      text_metrics.regular,
    ),
  )
  output.write_char('\n')
}
