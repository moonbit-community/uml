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
  let line_attributes = entity_line_style(entity.line_style)
  let stroke_attributes = { ..line_attributes, stroke: Color(stroke), }
  let text = entity.description_text_layout(text_metrics)
  let (label_position, stereotype_position) = entity.description_text_placement(
    text_metrics, width, height,
  )
  output.group(
    {
      ..Default::default(),
      class_name: Some("description-node"),
      data: [("code", entity.qualified_code)],
    },
    output => {
      with_entity_link(output, entity.url, graphic => {
        let output = graphic
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
      })
    },
  )
}

///|
/// Everything a description symbol shape needs, bundled so each per-symbol
/// painter stays single-purpose.
priv struct DescriptionSymbolContext {
  output : @graphics.Graphic
  entity : @entity.Entity
  text_metrics : ClassTextMetrics
  x : Int
  y : Int
  width : Int
  height : Int
  fill : String
  stroke : String
  stroke_attributes : @graphics.DrawingStyle
  line_attributes : @graphics.DrawingStyle
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
  output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Polygon([
      { x: x.to_double(), y: (y + 10).to_double(), },
      { x: (x + 10).to_double(), y: y.to_double(), },
      { x: (x + width).to_double(), y: y.to_double(), },
      { x: (x + width).to_double(), y: (y + height - 10).to_double(), },
      { x: (x + width - 10).to_double(), y: (y + height).to_double(), },
      { x: x.to_double(), y: (y + height).to_double(), },
      { x: x.to_double(), y: (y + 10).to_double(), },
    ]),
  )
  output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(
    Line({ x: (x + width - 10).to_double(), y: (y + 10).to_double(), }, {
      x: (x + width).to_double(),
      y: y.to_double(),
    }),
  )
  output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(
    Line({ x: x.to_double(), y: (y + 10).to_double(), }, {
      x: (x + width - 10).to_double(),
      y: (y + 10).to_double(),
    }),
  )
  output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(
    Line({ x: (x + width - 10).to_double(), y: (y + 10).to_double(), }, {
      x: (x + width - 10).to_double(),
      y: (y + height).to_double(),
    }),
  )
}

///|
fn DescriptionSymbolContext::append_frame(
  self : DescriptionSymbolContext,
) -> Unit {
  let text_width = (self.width.to_double() / 3.0).round().to_int()
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: self.x.to_double(), y: self.y.to_double(), },
      width=self.width.to_double(),
      height=self.height.to_double(),
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: (self.x + text_width).to_double(), y: self.y.to_double(), }),
      LineTo({
        x: (self.x + text_width).to_double(),
        y: (self.y + 5).to_double(),
      }),
      LineTo({
        x: (self.x + text_width - 7).to_double(),
        y: (self.y + 12).to_double(),
      }),
      LineTo({ x: self.x.to_double(), y: (self.y + 12).to_double(), }),
    ]),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(Path(path))
}

///|
fn DescriptionSymbolContext::append_storage(
  self : DescriptionSymbolContext,
) -> Unit {
  let radius = (35).min(self.width / 2)
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: self.x.to_double(), y: self.y.to_double(), },
      width=self.width.to_double(),
      height=self.height.to_double(),
      rx=Some(radius.to_double()),
      ry=Some(radius.to_double()),
    ),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Path([
      MoveTo({ x: x.to_double(), y: (y + 10).to_double(), }),
      CubicTo(
        { x: x.to_double(), y: y.to_double(), },
        { x: (x + half).to_double(), y: y.to_double(), },
        { x: (x + half).to_double(), y: y.to_double(), },
      ),
      CubicTo(
        { x: (x + half).to_double(), y: y.to_double(), },
        { x: (x + width).to_double(), y: y.to_double(), },
        { x: (x + width).to_double(), y: (y + 10).to_double(), },
      ),
      LineTo({ x: (x + width).to_double(), y: (y + height - 10).to_double(), }),
      CubicTo(
        { x: (x + width).to_double(), y: (y + height).to_double(), },
        { x: (x + half).to_double(), y: (y + height).to_double(), },
        { x: (x + half).to_double(), y: (y + height).to_double(), },
      ),
      CubicTo(
        { x: (x + half).to_double(), y: (y + height).to_double(), },
        { x: x.to_double(), y: (y + height).to_double(), },
        { x: x.to_double(), y: (y + height - 10).to_double(), },
      ),
      LineTo({ x: x.to_double(), y: (y + 10).to_double(), }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: x.to_double(), y: (y + 10).to_double(), }),
      CubicTo(
        { x: x.to_double(), y: (y + 20).to_double(), },
        { x: (x + half).to_double(), y: (y + 20).to_double(), },
        { x: (x + half).to_double(), y: (y + 20).to_double(), },
      ),
      CubicTo(
        { x: (x + half).to_double(), y: (y + 20).to_double(), },
        { x: (x + width).to_double(), y: (y + 20).to_double(), },
        { x: (x + width).to_double(), y: (y + 10).to_double(), },
      ),
    ]),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Path([
      MoveTo({ x: (x + 5).to_double(), y: y.to_double(), }),
      LineTo({ x: (x + width - 5).to_double(), y: y.to_double(), }),
      CubicTo(
        { x: (x + width).to_double(), y: y.to_double(), },
        { x: (x + width).to_double(), y: half.to_double(), },
        { x: (x + width).to_double(), y: half.to_double(), },
      ),
      CubicTo(
        { x: (x + width).to_double(), y: half.to_double(), },
        { x: (x + width).to_double(), y: (y + height).to_double(), },
        { x: (x + width - 5).to_double(), y: (y + height).to_double(), },
      ),
      LineTo({ x: (x + 5).to_double(), y: (y + height).to_double(), }),
      CubicTo(
        { x: x.to_double(), y: (y + height).to_double(), },
        { x: x.to_double(), y: half.to_double(), },
        { x: x.to_double(), y: half.to_double(), },
      ),
      CubicTo(
        { x: x.to_double(), y: half.to_double(), },
        { x: x.to_double(), y: y.to_double(), },
        { x: (x + 5).to_double(), y: y.to_double(), },
      ),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: (x + width - 5).to_double(), y: y.to_double(), }),
      CubicTo(
        { x: (x + width - 10).to_double(), y: y.to_double(), },
        { x: (x + width - 10).to_double(), y: half.to_double(), },
        { x: (x + width - 10).to_double(), y: half.to_double(), },
      ),
      CubicTo(
        { x: (x + width - 10).to_double(), y: (y + height).to_double(), },
        { x: (x + width - 5).to_double(), y: (y + height).to_double(), },
        { x: (x + width - 5).to_double(), y: (y + height).to_double(), },
      ),
    ]),
  )
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
  self.output
  .with_style({ ..Default::default(), fill: Color(self.fill), stroke: None, })
  .draw(
    Rectangle(
      origin={ x: x + border, y, },
      width=width - 2 * border,
      height~,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x, y, }),
      LineTo({ x: x + border - 2.5, y, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: x + border,
        y: y + 2.5,
      }),
      LineTo({ x: x + border, y: y + height - 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: x + border + 2.5,
        y: y + height,
      }),
      LineTo({ x: x + width - border - 2.5, y: y + height, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: x + width - border,
        y: y + height - 2.5,
      }),
      LineTo({ x: x + width - border, y: y + 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: x + width - border + 2.5,
        y,
      }),
      LineTo({ x: x + width, y, }),
    ]),
  )
}

///|
fn DescriptionSymbolContext::append_rectangle(
  self : DescriptionSymbolContext,
) -> Unit {
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: self.x.to_double(), y: self.y.to_double(), },
      width=self.width.to_double(),
      height=self.height.to_double(),
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
}

///|
fn DescriptionSymbolContext::append_artifact(
  self : DescriptionSymbolContext,
) -> Unit {
  let x_symbol = self.x + self.width - 12 - 5
  let y_symbol = self.y + 5
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: self.x.to_double(), y: self.y.to_double(), },
      width=self.width.to_double(),
      height=self.height.to_double(),
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Polygon([
      { x: x_symbol.to_double(), y: y_symbol.to_double(), },
      { x: x_symbol.to_double(), y: (y_symbol + 14).to_double(), },
      { x: (x_symbol + 12).to_double(), y: (y_symbol + 14).to_double(), },
      { x: (x_symbol + 12).to_double(), y: (y_symbol + 6).to_double(), },
      { x: (x_symbol + 6).to_double(), y: y_symbol.to_double(), },
      { x: x_symbol.to_double(), y: y_symbol.to_double(), },
    ]),
  )
  self.output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(
    Line({ x: (x_symbol + 6).to_double(), y: y_symbol.to_double(), }, {
      x: (x_symbol + 6).to_double(),
      y: (y_symbol + 6).to_double(),
    }),
  )
  self.output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(
    Line({ x: (x_symbol + 12).to_double(), y: (y_symbol + 6).to_double(), }, {
      x: (x_symbol + 6).to_double(),
      y: (y_symbol + 6).to_double(),
    }),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Path([
      MoveTo({ x: x + 2.5, y, }),
      LineTo({ x: x + wtitle - 2.5, y, }),
      ArcTo(rx=3.75, ry=3.75, rotation=0, large_arc=false, sweep=true, end={
        x: x + wtitle,
        y: y + 2.5,
      }),
      LineTo({ x: x + wtitle + 7, y: y + htitle, }),
      LineTo({ x: x + width - 2.5, y: y + htitle, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: x + width,
        y: y + htitle + 2.5,
      }),
      LineTo({ x: x + width, y: y + height - 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: x + width - 2.5,
        y: y + height,
      }),
      LineTo({ x: x + 2.5, y: y + height, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x,
        y: y + height - 2.5,
      }),
      LineTo({ x, y: y + 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: x + 2.5,
        y,
      }),
    ]),
  )
  self.output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(Line({ x, y: y + htitle, }, { x: x + wtitle + 7, y: y + htitle, }), metadata={
    ..Default::default(),
  })
}

///|
fn DescriptionSymbolContext::append_file(
  self : DescriptionSymbolContext,
) -> Unit {
  let x = self.x.to_double()
  let y = self.y.to_double()
  let width = self.width.to_double()
  let height = self.height.to_double()
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Path([
      MoveTo({ x, y: y + 2.5, }),
      LineTo({ x, y: y + height - 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: x + 2.5,
        y: y + height,
      }),
      LineTo({ x: x + width - 2.5, y: y + height, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: x + width,
        y: y + height - 2.5,
      }),
      LineTo({ x: x + width, y: y + 10, }),
      LineTo({ x: x + width - 10, y, }),
      LineTo({ x: x + 2.5, y, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x,
        y: y + 2.5,
      }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Path([
      MoveTo({ x: x + width - 10, y, }),
      LineTo({ x: x + width - 10, y: y + 7.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: x + width - 7.5,
        y: y + 10,
      }),
      LineTo({ x: x + width, y: y + 10, }),
    ]),
  )
}

///|
fn DescriptionSymbolContext::append_hexagon(
  self : DescriptionSymbolContext,
) -> Unit {
  let quarter_width = self.width / 4
  let half_height = self.height / 2
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Polygon([
      {
        x: (self.x + self.width).to_double(),
        y: (self.y + half_height).to_double(),
      },
      {
        x: (self.x + self.width - quarter_width).to_double(),
        y: self.y.to_double(),
      },
      { x: (self.x + quarter_width).to_double(), y: self.y.to_double(), },
      { x: self.x.to_double(), y: (self.y + half_height).to_double(), },
      {
        x: (self.x + quarter_width).to_double(),
        y: (self.y + self.height).to_double(),
      },
      {
        x: (self.x + self.width - quarter_width).to_double(),
        y: (self.y + self.height).to_double(),
      },
    ]),
  )
}

///|
fn DescriptionSymbolContext::append_action(
  self : DescriptionSymbolContext,
) -> Unit {
  let half = self.y + self.height / 2
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Polygon([
      { x: self.x.to_double(), y: self.y.to_double(), },
      { x: (self.x + self.width - 10).to_double(), y: self.y.to_double(), },
      { x: (self.x + self.width).to_double(), y: half.to_double(), },
      {
        x: (self.x + self.width - 10).to_double(),
        y: (self.y + self.height).to_double(),
      },
      { x: self.x.to_double(), y: (self.y + self.height).to_double(), },
    ]),
  )
}

///|
fn DescriptionSymbolContext::append_process(
  self : DescriptionSymbolContext,
) -> Unit {
  let half = self.y + self.height / 2
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Polygon([
      { x: self.x.to_double(), y: self.y.to_double(), },
      { x: (self.x + self.width - 10).to_double(), y: self.y.to_double(), },
      { x: (self.x + self.width).to_double(), y: half.to_double(), },
      {
        x: (self.x + self.width - 10).to_double(),
        y: (self.y + self.height).to_double(),
      },
      { x: self.x.to_double(), y: (self.y + self.height).to_double(), },
      { x: (self.x + 10).to_double(), y: half.to_double(), },
    ]),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: left, y: top, }),
      LineTo({ x: left, y: top + 24, }),
      MoveTo({ x: left, y: top + 12, }),
      LineTo({ x: left + 17, y: top + 12, }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Ellipse(
      center={
        x: self.x.to_double() + figure_x + 33,
        y: self.y.to_double() + figure_y + 16,
      },
      rx=12,
      ry=12,
    ),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Ellipse(
      center={
        x: self.x.to_double() + figure_x + 16,
        y: self.y.to_double() + figure_y + 16,
      },
      rx=12,
      ry=12,
    ),
  )
  self.output
  .with_style({
    ..Default::default(),
    fill: Color(self.stroke),
    stroke: Color(self.stroke),
    stroke_width: Some(1),
  })
  .draw(
    Polygon([
      { x: wing_x, y: wing_y, },
      { x: wing_x + 6, y: wing_y - 5, },
      { x: wing_x + 4, y: wing_y, },
      { x: wing_x + 6, y: wing_y + 5, },
      { x: wing_x, y: wing_y, },
    ]),
  )
}

///|
fn DescriptionSymbolContext::append_entity_domain(
  self : DescriptionSymbolContext,
) -> Unit {
  let (figure_x, figure_y) = self.entity.description_figure_origin(
    self.text_metrics,
    self.width,
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Ellipse(
      center={
        x: self.x.to_double() + figure_x + 16,
        y: self.y.to_double() + figure_y + 16,
      },
      rx=12,
      ry=12,
    ),
  )
  self.output
  .with_style({ ..self.line_attributes, stroke: Color(self.stroke), })
  .draw(
    Line(
      {
        x: self.x.to_double() + figure_x + 4,
        y: self.y.to_double() + figure_y + 30,
      },
      {
        x: self.x.to_double() + figure_x + 28,
        y: self.y.to_double() + figure_y + 30,
      },
    ),
  )
}

///|
fn DescriptionSymbolContext::append_collections(
  self : DescriptionSymbolContext,
) -> Unit {
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: self.x.to_double(), y: self.y.to_double(), },
      width=self.width.to_double(),
      height=self.height.to_double(),
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: (self.x - 4).to_double(), y: (self.y - 4).to_double(), },
      width=self.width.to_double(),
      height=self.height.to_double(),
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Ellipse(
      center={
        x: head_x + head_size / 2.0,
        y: self.y.to_double() + head_size / 2.0,
      },
      rx=head_size / 2.0,
      ry=head_size / 2.0,
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Rectangle(
      origin={ x: body_x, y: self.y.to_double() + head_size, },
      width=body_width.to_double(),
      height=body_height.to_double(),
      rx=Some(head_size / 2.0),
      ry=Some(head_size / 2.0),
    ),
  )
}

///|
fn DescriptionSymbolContext::append_circle(
  self : DescriptionSymbolContext,
) -> Unit {
  let (figure_x, figure_y) = self.entity.description_figure_origin(
    self.text_metrics,
    self.width,
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: Color(self.fill), })
  .draw(
    Ellipse(
      center={
        x: self.x.to_double() + figure_x + 9,
        y: self.y.to_double() + figure_y + 9,
      },
      rx=8,
      ry=8,
    ),
  )
}

///|
fn append_description_text(
  output : @graphics.Graphic,
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
  { seed: (seed ^ 0x5DEECE66DL) & 0xFFFFFFFFFFFFL, }
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
  output : Array[@graphics.PathSegment],
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
  output.push(
    CubicTo({ x: m1x, y: m1y, }, { x: m2x, y: m2y, }, { x: p2.0, y: p2.1, }),
  )
}

///|
/// `USymbolCloud.getSpecificFrontierForCloudNew`: a wavy frontier whose
/// random offsets are seeded by the node size.
fn description_cloud_path(
  width : Double,
  height : Double,
  origin_x : Double,
  origin_y : Double,
) -> Array[@graphics.PathSegment] {
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
  let output : Array[@graphics.PathSegment] = [
    MoveTo({ x: origin_x + points[0].0, y: origin_y + points[0].1, }),
  ]
  for i in 0..<(points.length() - 1) {
    description_cloud_curve(
      random,
      output,
      (origin_x + points[i].0, origin_y + points[i].1),
      (origin_x + points[i + 1].0, origin_y + points[i + 1].1),
    )
  }
  output
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
  output.group(
    {
      ..Default::default(),
      class_name: Some("port-node"),
      data: [("code", entity.qualified_code)],
    },
    output => {
      output
      .with_style({
        ..Default::default(),
        fill: Color(fill),
        stroke: Color(stroke),
        stroke_width: Some(@svg.EMPHASIZED_STROKE_WIDTH),
      })
      .draw(
        Rectangle(
          origin={ x: x.to_double(), y: y.to_double(), },
          width=width.to_double(),
          height=height.to_double(),
          rx=None,
          ry=None,
        ),
      )
      append_paint_text(
        output,
        label_x,
        label_y,
        entity.display,
        "port-title",
        text_metrics.regular,
        fill=diagram.style.diagram_text_color(),
      )
    },
  )
}

///|
/// `EntityImageGroup`/`USymbol.asBig`: a declaration keyword opened with `{`
/// draws the symbol over its whole cluster rectangle, with the bold title
/// (and stereotype) placed by the symbol.
fn append_symbol_packages(
  output : @graphics.Graphic,
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
  output : @graphics.Graphic,
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
    stroke_attributes: { ..entity_line_style(None), stroke: Color(stroke), },
  }
  output.group({ ..Default::default(), class_name: Some("symbol-package"), }, graphic => {
    let symbol_ctx = { ..symbol_ctx, output: graphic, }
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
  })
}

///|
/// Everything a symbol package branch needs, bundled to keep the per-shape
/// painters single-purpose.
priv struct SymbolPackageContext {
  output : @graphics.Graphic
  group : @entity.Package
  text_metrics : ClassTextMetrics
  x : Double
  y : Double
  width : Double
  height : Double
  title_width : Double
  title_height : Double
  stereo : (String, Double, Double)?
  stroke_attributes : @graphics.DrawingStyle
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Polygon([
      { x: self.x, y: self.y + 10, },
      { x: self.x + 10, y: self.y, },
      { x: self.x + self.width, y: self.y, },
      { x: self.x + self.width, y: self.y + self.height - 10, },
      { x: self.x + self.width - 10, y: self.y + self.height, },
      { x: self.x, y: self.y + self.height, },
      { x: self.x, y: self.y + 10, },
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, })
  .draw(
    Line({ x: self.x + self.width - 10, y: self.y + 10, }, {
      x: self.x + self.width,
      y: self.y,
    }),
  )
  self.output
  .with_style({ ..self.stroke_attributes, })
  .draw(
    Line({ x: self.x, y: self.y + 10, }, {
      x: self.x + self.width - 10,
      y: self.y + 10,
    }),
  )
  self.output
  .with_style({ ..self.stroke_attributes, })
  .draw(
    Line({ x: self.x + self.width - 10, y: self.y + 10, }, {
      x: self.x + self.width - 10,
      y: self.y + self.height,
    }),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x, y: self.y, },
      width=self.width,
      height=self.height,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x + text_width, y: self.y, }),
      LineTo({ x: self.x + text_width, y: self.y + text_height - 10, }),
      LineTo({ x: self.x + text_width - 10, y: self.y + text_height, }),
      LineTo({ x: self.x, y: self.y + text_height, }),
    ]),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(Path(path))
  self.append_centered_label(13.0, 13.0)
}

///|
fn SymbolPackageContext::append_database(self : SymbolPackageContext) -> Unit {
  let half = self.width / 2.0
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x, y: self.y + 10, }),
      CubicTo({ x: self.x, y: self.y, }, { x: self.x + half, y: self.y, }, {
        x: self.x + half,
        y: self.y,
      }),
      CubicTo(
        { x: self.x + half, y: self.y, },
        { x: self.x + self.width, y: self.y, },
        { x: self.x + self.width, y: self.y + 10, },
      ),
      LineTo({ x: self.x + self.width, y: self.y + self.height - 10, }),
      CubicTo(
        { x: self.x + self.width, y: self.y + self.height, },
        { x: self.x + half, y: self.y + self.height, },
        { x: self.x + half, y: self.y + self.height, },
      ),
      CubicTo(
        { x: self.x + half, y: self.y + self.height, },
        { x: self.x, y: self.y + self.height, },
        { x: self.x, y: self.y + self.height - 10, },
      ),
      LineTo({ x: self.x, y: self.y + 10, }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x, y: self.y + 10, }),
      CubicTo(
        { x: self.x, y: self.y + 20, },
        { x: self.x + half, y: self.y + 20, },
        { x: self.x + half, y: self.y + 20, },
      ),
      CubicTo(
        { x: self.x + half, y: self.y + 20, },
        { x: self.x + self.width, y: self.y + 20, },
        { x: self.x + self.width, y: self.y + 10, },
      ),
    ]),
  )
  self.append_centered_label(22.0, 22.0)
}

///|
fn SymbolPackageContext::append_queue(self : SymbolPackageContext) -> Unit {
  let half = self.y + self.height / 2.0
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x + 5, y: self.y, }),
      LineTo({ x: self.x + self.width - 5, y: self.y, }),
      CubicTo(
        { x: self.x + self.width, y: self.y, },
        { x: self.x + self.width, y: half, },
        { x: self.x + self.width, y: half, },
      ),
      CubicTo(
        { x: self.x + self.width, y: half, },
        { x: self.x + self.width, y: self.y + self.height, },
        { x: self.x + self.width - 5, y: self.y + self.height, },
      ),
      LineTo({ x: self.x + 5, y: self.y + self.height, }),
      CubicTo(
        { x: self.x, y: self.y + self.height, },
        { x: self.x, y: half, },
        { x: self.x, y: half, },
      ),
      CubicTo({ x: self.x, y: half, }, { x: self.x, y: self.y, }, {
        x: self.x + 5,
        y: self.y,
      }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x + self.width - 5, y: self.y, }),
      CubicTo(
        { x: self.x + self.width - 10, y: self.y, },
        { x: self.x + self.width - 10, y: half, },
        { x: self.x + self.width - 10, y: half, },
      ),
      CubicTo(
        { x: self.x + self.width - 10, y: self.y + self.height, },
        { x: self.x + self.width - 5, y: self.y + self.height, },
        { x: self.x + self.width - 5, y: self.y + self.height, },
      ),
    ]),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_stack(self : SymbolPackageContext) -> Unit {
  let border = 15.0
  self.output
  .with_style({ ..Default::default(), fill: None, stroke: None, })
  .draw(
    Rectangle(
      origin={ x: self.x + border, y: self.y, },
      width=self.width - 2 * border,
      height=self.height,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x, y: self.y, }),
      LineTo({ x: self.x + border - 2.5, y: self.y, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: self.x + border,
        y: self.y + 2.5,
      }),
      LineTo({ x: self.x + border, y: self.y + self.height - 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: self.x + border + 2.5,
        y: self.y + self.height,
      }),
      LineTo({ x: self.x + self.width - border - 2.5, y: self.y + self.height, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: self.x + self.width - border,
        y: self.y + self.height - 2.5,
      }),
      LineTo({ x: self.x + self.width - border, y: self.y + 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: self.x + self.width - border + 2.5,
        y: self.y,
      }),
      LineTo({ x: self.x + self.width, y: self.y, }),
    ]),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_storage(self : SymbolPackageContext) -> Unit {
  let radius = (35).min((self.width / 2.0).to_int())
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x, y: self.y, },
      width=self.width,
      height=self.height,
      rx=Some(radius.to_double()),
      ry=Some(radius.to_double()),
    ),
  )
  self.append_centered_label(7.0, 5.0)
}

///|
fn SymbolPackageContext::append_artifact(self : SymbolPackageContext) -> Unit {
  let x_symbol = self.x + self.width - 17.0
  let y_symbol = self.y + 5.0
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x, y: self.y, },
      width=self.width,
      height=self.height,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Polygon([
      { x: x_symbol, y: y_symbol, },
      { x: x_symbol, y: y_symbol + 14, },
      { x: x_symbol + 12, y: y_symbol + 14, },
      { x: x_symbol + 12, y: y_symbol + 6, },
      { x: x_symbol + 6, y: y_symbol, },
      { x: x_symbol, y: y_symbol, },
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, })
  .draw(
    Line({ x: x_symbol + 6, y: y_symbol, }, {
      x: x_symbol + 6,
      y: y_symbol + 6,
    }),
  )
  self.output
  .with_style({ ..self.stroke_attributes, })
  .draw(
    Line({ x: x_symbol + 12, y: y_symbol + 6, }, {
      x: x_symbol + 6,
      y: y_symbol + 6,
    }),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_card(self : SymbolPackageContext) -> Unit {
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x, y: self.y, },
      width=self.width,
      height=self.height,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_file(self : SymbolPackageContext) -> Unit {
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x, y: self.y + 2.5, }),
      LineTo({ x: self.x, y: self.y + self.height - 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: self.x + 2.5,
        y: self.y + self.height,
      }),
      LineTo({ x: self.x + self.width - 2.5, y: self.y + self.height, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: self.x + self.width,
        y: self.y + self.height - 2.5,
      }),
      LineTo({ x: self.x + self.width, y: self.y + 10, }),
      LineTo({ x: self.x + self.width - 10, y: self.y, }),
      LineTo({ x: self.x + 2.5, y: self.y, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: self.x,
        y: self.y + 2.5,
      }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x + self.width - 10, y: self.y, }),
      LineTo({ x: self.x + self.width - 10, y: self.y + 7.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=false, end={
        x: self.x + self.width - 7.5,
        y: self.y + 10,
      }),
      LineTo({ x: self.x + self.width, y: self.y + 10, }),
    ]),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_hexagon(self : SymbolPackageContext) -> Unit {
  let quarter_width = self.width / 4.0
  let half_height = self.height / 2.0
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Polygon([
      { x: self.x + self.width, y: self.y + half_height, },
      { x: self.x + self.width - quarter_width, y: self.y, },
      { x: self.x + quarter_width, y: self.y, },
      { x: self.x, y: self.y + half_height, },
      { x: self.x + quarter_width, y: self.y + self.height, },
      { x: self.x + self.width - quarter_width, y: self.y + self.height, },
    ]),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_rectangle(self : SymbolPackageContext) -> Unit {
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x, y: self.y, },
      width=self.width,
      height=self.height,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.append_centered_label(2.0, 2.0)
}

///|
fn SymbolPackageContext::append_action(self : SymbolPackageContext) -> Unit {
  let half = self.y + self.height / 2.0
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Polygon([
      { x: self.x, y: self.y, },
      { x: self.x + self.width - 10, y: self.y, },
      { x: self.x + self.width, y: half, },
      { x: self.x + self.width - 10, y: self.y + self.height, },
      { x: self.x, y: self.y + self.height, },
    ]),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Polygon([
      { x: self.x, y: self.y, },
      { x: self.x + self.width - 10, y: self.y, },
      { x: self.x + self.width, y: half, },
      { x: self.x + self.width - 10, y: self.y + self.height, },
      { x: self.x, y: self.y + self.height, },
      { x: self.x + 10, y: half, },
    ]),
  )
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
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x, y: self.y, },
      width=self.width,
      height=self.height,
      rx=Some(2.5),
      ry=Some(2.5),
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x + self.width - 20, y: self.y + 5, },
      width=15,
      height=10,
      rx=None,
      ry=None,
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x + self.width - 22, y: self.y + 7, },
      width=4,
      height=2,
      rx=None,
      ry=None,
    ),
  )
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Rectangle(
      origin={ x: self.x + self.width - 22, y: self.y + 11, },
      width=4,
      height=2,
      rx=None,
      ry=None,
    ),
  )
  self.append_centered_label(13.0, 13.0)
}

///|
fn SymbolPackageContext::append_folder(self : SymbolPackageContext) -> Unit {
  let wtitle = self.title_width + 6.0
  let htitle = self.title_height + 6.0
  self.output
  .with_style({ ..self.stroke_attributes, fill: None, })
  .draw(
    Path([
      MoveTo({ x: self.x + 2.5, y: self.y, }),
      LineTo({ x: self.x + wtitle - 2.5, y: self.y, }),
      ArcTo(rx=3.75, ry=3.75, rotation=0, large_arc=false, sweep=true, end={
        x: self.x + wtitle,
        y: self.y + 2.5,
      }),
      LineTo({ x: self.x + wtitle + 7, y: self.y + htitle, }),
      LineTo({ x: self.x + self.width - 2.5, y: self.y + htitle, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: self.x + self.width,
        y: self.y + htitle + 2.5,
      }),
      LineTo({ x: self.x + self.width, y: self.y + self.height - 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: self.x + self.width - 2.5,
        y: self.y + self.height,
      }),
      LineTo({ x: self.x + 2.5, y: self.y + self.height, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: self.x,
        y: self.y + self.height - 2.5,
      }),
      LineTo({ x: self.x, y: self.y + 2.5, }),
      ArcTo(rx=2.5, ry=2.5, rotation=0, large_arc=false, sweep=true, end={
        x: self.x + 2.5,
        y: self.y,
      }),
    ]),
  )
  self.output
  .with_style({ ..self.stroke_attributes, })
  .draw(
    Line({ x: self.x, y: self.y + htitle, }, {
      x: self.x + wtitle + 7,
      y: self.y + htitle,
    }),
  )
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
  output : @graphics.Graphic,
  group : @entity.Package,
  text_metrics : ClassTextMetrics,
  title_x : Double,
  title_top : Double,
  stereo : (String, Double, Double)?,
) -> Unit {
  match stereo {
    Some((display, x, top)) => {
      let stereo_height = text_metrics.italic.measure(display).height.to_double()
      draw_entity_text(
        output,
        x,
        top + stereo_height - 3.0,
        display,
        text_metrics.italic,
        class_name="package-stereotype",
      )
    }
    None => ()
  }
  let title_height = text_metrics.regular.measure(group.display).height.to_double()
  draw_entity_text(
    output,
    title_x,
    title_top + title_height - 3.0,
    group.display,
    text_metrics.regular,
    class_name="package-title",
  )
}
