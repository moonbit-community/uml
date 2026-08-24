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
/// `Interface`/`Entity` kinds whose description renderer the capability
/// already restricted to the description families.
fn Entity::description_symbol(self : Entity) -> DescriptionSymbol {
  match self.kind {
    Node => NodeSymbol
    Frame => FrameSymbol
    Cloud => CloudSymbol
    Storage => StorageSymbol
    Database => DatabaseSymbol
    Queue => QueueSymbol
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
    Boundary => BoundarySymbol
    Control => ControlSymbol
    Collections => CollectionsSymbol
    Person => PersonSymbol
    Entity => EntityDomainSymbol
    Circle | Interface => CircleSymbol
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
fn Entity::description_text_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> DescriptionTextLayout {
  let label = text_metrics.regular.measure(self.display)
  match self.stereotype {
    Some(value) if !self.stereotype_hidden => {
      let display = @parse.display_stereotype(value)
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
/// Fixed figure sizes of the "simple" symbols: `Boundary`, `Control`,
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
fn Entity::description_geometry(
  self : Entity,
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
fn Entity::description_label_top(
  self : Entity,
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
fn Entity::description_text_placement(
  self : Entity,
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
        match text.stereotype {
          Some(_) => Some((stereo_x, text.stereotype_height - 3))
          None => None
        },
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
        match text.stereotype {
          Some(_) => Some((stereo_x, -8 - 3))
          None => None
        },
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
        match text.stereotype {
          Some(_) => Some((stereo_x, stereo_baseline))
          None => None
        },
      )
    }
  }
}

///|
/// Paint one description-symbol node. The border geometry per symbol mirrors
/// the matching `USymbol.drawX` in node-local coordinates.
fn append_description_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
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
  match entity.description_symbol() {
    NodeSymbol =>
      output <+
        $|<polygon points="\{x},\{y + 10} \{x + 10},\{y} \{x + width},\{y} \{x + width},\{y + height - 10} \{x + width - 10},\{y + height} \{x},\{y + height} \{x},\{y + 10}" fill="\{fill}" \{stroke_attributes}/><line x1="\{x + width - 10}" y1="\{y + 10}" x2="\{x + width}" y2="\{y}" stroke="\{stroke}" style="\{line_attributes}"/><line x1="\{x}" y1="\{y + 10}" x2="\{x + width - 10}" y2="\{y + 10}" stroke="\{stroke}" style="\{line_attributes}"/><line x1="\{x + width - 10}" y1="\{y + 10}" x2="\{x + width - 10}" y2="\{y + height}" stroke="\{stroke}" style="\{line_attributes}"/>
    FrameSymbol => {
      let text_width = (width.to_double() / 3.0).round().to_int()
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="\{fill}" \{stroke_attributes}/><path d="M \{x + text_width} \{y} L \{x + text_width} \{y + 5} L \{x + text_width - 7} \{y + 12} L \{x} \{y + 12}" fill="none" \{stroke_attributes}/>
    }
    CloudSymbol => {
      let path = description_cloud_path(
        width.to_double(),
        height.to_double(),
        x.to_double(),
        y.to_double(),
      )
      output <+
        $|<path d="\{path}" fill="\{fill}" \{stroke_attributes}/>
    }
    StorageSymbol => {
      let radius = (35).min(width / 2)
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="\{radius}" ry="\{radius}" fill="\{fill}" \{stroke_attributes}/>
    }
    DatabaseSymbol => {
      let half = width / 2
      output <+
        $|<path d="M \{x} \{y + 10} C \{x} \{y} \{x + half} \{y} \{x + half} \{y} C \{x + half} \{y} \{x + width} \{y} \{x + width} \{y + 10} L \{x + width} \{y + height - 10} C \{x + width} \{y + height} \{x + half} \{y + height} \{x + half} \{y + height} C \{x + half} \{y + height} \{x} \{y + height} \{x} \{y + height - 10} L \{x} \{y + 10}" fill="\{fill}" \{stroke_attributes}/><path d="M \{x} \{y + 10} C \{x} \{y + 20} \{x + half} \{y + 20} \{x + half} \{y + 20} C \{x + half} \{y + 20} \{x + width} \{y + 20} \{x + width} \{y + 10}" fill="none" \{stroke_attributes}/>
    }
    QueueSymbol => {
      let half = y + height / 2
      output <+
        $|<path d="M \{x + 5} \{y} L \{x + width - 5} \{y} C \{x + width} \{y} \{x + width} \{half} \{x + width} \{half} C \{x + width} \{half} \{x + width} \{y + height} \{x + width - 5} \{y + height} L \{x + 5} \{y + height} C \{x} \{y + height} \{x} \{half} \{x} \{half} C \{x} \{half} \{x} \{y} \{x + 5} \{y}" fill="\{fill}" \{stroke_attributes}/><path d="M \{x + width - 5} \{y} C \{x + width - 10} \{y} \{x + width - 10} \{half} \{x + width - 10} \{half} C \{x + width - 10} \{y + height} \{x + width - 5} \{y + height} \{x + width - 5} \{y + height}" fill="none" \{stroke_attributes}/>
    }
    StackSymbol => {
      let border = 15.0
      let x = x.to_double()
      let y = y.to_double()
      let width = width.to_double()
      let height = height.to_double()
      output <+
        $|<rect x="\{x + border}" y="\{y}" width="\{width - 2 * border}" height="\{height}" rx="2.5" ry="2.5" fill="\{fill}" stroke="none"/><path d="M \{x} \{y} L \{x + border - 2.5} \{y} A2.5,2.5 0 0 1 \{x + border} \{y + 2.5} L \{x + border} \{y + height - 2.5} A2.5,2.5 0 0 0 \{x + border + 2.5} \{y + height} L \{x + width - border - 2.5} \{y + height} A2.5,2.5 0 0 0 \{x + width - border} \{y + height - 2.5} L \{x + width - border} \{y + 2.5} A2.5,2.5 0 0 1 \{x + width - border + 2.5} \{y} L \{x + width} \{y}" fill="none" \{stroke_attributes}/>
    }
    RectangleSymbol | CardSymbol =>
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="\{fill}" \{stroke_attributes}/>
    ArtifactSymbol => {
      let x_symbol = x + width - 12 - 5
      let y_symbol = y + 5
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="\{fill}" \{stroke_attributes}/><polygon points="\{x_symbol},\{y_symbol} \{x_symbol},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 6} \{x_symbol + 6},\{y_symbol} \{x_symbol},\{y_symbol}" fill="\{fill}" \{stroke_attributes}/><line x1="\{x_symbol + 6}" y1="\{y_symbol}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" stroke="\{stroke}" style="\{line_attributes}"/><line x1="\{x_symbol + 12}" y1="\{y_symbol + 6}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" stroke="\{stroke}" style="\{line_attributes}"/>
    }
    FolderSymbol => {
      let x = x.to_double()
      let y = y.to_double()
      let width = width.to_double()
      let height = height.to_double()
      let wtitle = 46.0
      let htitle = 21.0
      output <+
        $|<path d="M \{x + 2.5} \{y} L \{x + wtitle - 2.5} \{y} A3.75,3.75 0 0 1 \{x + wtitle} \{y + 2.5} L \{x + wtitle + 7} \{y + htitle} L \{x + width - 2.5} \{y + htitle} A2.5,2.5 0 0 1 \{x + width} \{y + htitle + 2.5} L \{x + width} \{y + height - 2.5} A2.5,2.5 0 0 1 \{x + width - 2.5} \{y + height} L \{x + 2.5} \{y + height} A2.5,2.5 0 0 1 \{x} \{y + height - 2.5} L \{x} \{y + 2.5} A2.5,2.5 0 0 1 \{x + 2.5} \{y}" fill="\{fill}" \{stroke_attributes}/><line x1="\{x}" y1="\{y + htitle}" x2="\{x + wtitle + 7}" y2="\{y + htitle}" stroke="\{stroke}" style="\{line_attributes}"/>
    }
    FileSymbol => {
      let x = x.to_double()
      let y = y.to_double()
      let width = width.to_double()
      let height = height.to_double()
      output <+
        $|<path d="M \{x} \{y + 2.5} L \{x} \{y + height - 2.5} A2.5,2.5 0 0 0 \{x + 2.5} \{y + height} L \{x + width - 2.5} \{y + height} A2.5,2.5 0 0 0 \{x + width} \{y + height - 2.5} L \{x + width} \{y + 10} L \{x + width - 10} \{y} L \{x + 2.5} \{y} A2.5,2.5 0 0 0 \{x} \{y + 2.5}" fill="\{fill}" \{stroke_attributes}/><path d="M \{x + width - 10} \{y} L \{x + width - 10} \{y + 7.5} A2.5,2.5 0 0 0 \{x + width - 7.5} \{y + 10} L \{x + width} \{y + 10}" fill="\{fill}" \{stroke_attributes}/>
    }
    HexagonSymbol => {
      let quarter_width = width / 4
      let half_height = height / 2
      output <+
        $|<polygon points="\{x + width},\{y + half_height} \{x + width - quarter_width},\{y} \{x + quarter_width},\{y} \{x},\{y + half_height} \{x + quarter_width},\{y + height} \{x + width - quarter_width},\{y + height}" fill="\{fill}" \{stroke_attributes}/>
    }
    LabelSymbol => ()
    ActionSymbol => {
      let half = y + height / 2
      output <+
        $|<polygon points="\{x},\{y} \{x + width - 10},\{y} \{x + width},\{half} \{x + width - 10},\{y + height} \{x},\{y + height}" fill="\{fill}" \{stroke_attributes}/>
    }
    ProcessSymbol => {
      let half = y + height / 2
      output <+
        $|<polygon points="\{x},\{y} \{x + width - 10},\{y} \{x + width},\{half} \{x + width - 10},\{y + height} \{x},\{y + height} \{x + 10},\{half}" fill="\{fill}" \{stroke_attributes}/>
    }
    BoundarySymbol => {
      let (figure_x, figure_y) = entity.description_figure_origin(
        text_metrics, width,
      )
      let left = x.to_double() + figure_x + 4.0
      let top = y.to_double() + figure_y + 4.0
      output <+
        $|<path d="M \{left} \{top} L \{left} \{top + 24} M \{left} \{top + 12} L \{left + 17} \{top + 12}" fill="none" \{stroke_attributes}/><ellipse cx="\{x.to_double() + figure_x + 33}" cy="\{y.to_double() + figure_y + 16}" rx="12" ry="12" fill="\{fill}" \{stroke_attributes}/>
    }
    ControlSymbol => {
      let (figure_x, figure_y) = entity.description_figure_origin(
        text_metrics, width,
      )
      let wing_x = x.to_double() + figure_x + 12.0
      let wing_y = y.to_double() + figure_y + 4.0
      output <+
        $|<ellipse cx="\{x.to_double() + figure_x + 16}" cy="\{y.to_double() + figure_y + 16}" rx="12" ry="12" fill="\{fill}" \{stroke_attributes}/><polygon points="\{wing_x},\{wing_y} \{wing_x + 6},\{wing_y - 5} \{wing_x + 4},\{wing_y} \{wing_x + 6},\{wing_y + 5} \{wing_x},\{wing_y}" fill="\{stroke}" stroke="\{stroke}" stroke-width="1"/>
    }
    EntityDomainSymbol => {
      let (figure_x, figure_y) = entity.description_figure_origin(
        text_metrics, width,
      )
      output <+
        $|<ellipse cx="\{x.to_double() + figure_x + 16}" cy="\{y.to_double() + figure_y + 16}" rx="12" ry="12" fill="\{fill}" \{stroke_attributes}/><line x1="\{x.to_double() + figure_x + 4}" y1="\{y.to_double() + figure_y + 30}" x2="\{x.to_double() + figure_x + 28}" y2="\{y.to_double() + figure_y + 30}" stroke="\{stroke}" style="\{line_attributes}"/>
    }
    CollectionsSymbol =>
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="\{fill}" \{stroke_attributes}/><rect x="\{x - 4}" y="\{y - 4}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="\{fill}" \{stroke_attributes}/>
    PersonSymbol => {
      let text = entity.description_text_layout(text_metrics)
      let body_width = 10 + text.block_width + 10
      let body_height = 10 + text.block_height + 10
      let head_size = (body_width.to_double() * body_height.to_double()).sqrt() *
        0.42
      let head_x = x.to_double() + (body_width.to_double() - head_size) / 2.0
      let body_x = x.to_double() +
        width.to_double() / 2.0 -
        body_width.to_double() / 2.0
      output <+
        $|<ellipse cx="\{head_x + head_size / 2.0}" cy="\{y.to_double() + head_size / 2.0}" rx="\{head_size / 2.0}" ry="\{head_size / 2.0}" fill="\{fill}" \{stroke_attributes}/><rect x="\{body_x}" y="\{y.to_double() + head_size}" width="\{body_width.to_double()}" height="\{body_height.to_double()}" rx="\{head_size / 2.0}" ry="\{head_size / 2.0}" fill="\{fill}" \{stroke_attributes}/>
    }
    CircleSymbol => {
      let (figure_x, figure_y) = entity.description_figure_origin(
        text_metrics, width,
      )
      output <+
        $|<ellipse cx="\{x.to_double() + figure_x + 9}" cy="\{y.to_double() + figure_y + 9}" rx="8" ry="8" fill="\{fill}" \{stroke_attributes}/>
    }
  }
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
fn append_description_text(
  output : StringBuilder,
  entity : Entity,
  text_metrics : ClassTextMetrics,
  text_color : String,
  x : Int,
  y : Int,
  label_position : (Int, Int),
  stereotype_position : (Int, Int)?,
  text : DescriptionTextLayout,
) -> Unit {
  if stereotype_position is Some((stereotype_x, stereotype_baseline)) {
    output <+
      $|<text x="\{x + stereotype_x}" y="\{y + stereotype_baseline}" class="description-stereotype" fill="\{text_color}" font-size="\{text_metrics.regular.font_size}">\{@svg.xml_escape(text.stereotype.unwrap())}</text>
  }
  output <+
    $|<text x="\{x + label_position.0}" y="\{y + label_position.1}" class="description-title" fill="\{text_color}">\{@svg.xml_escape(entity.display)}</text>
}

///|
/// Node-local origin of a simple-symbol figure: centered horizontally, below
/// the stereotype strip like `USymbolSimpleAbstract.asSmall`.
fn Entity::description_figure_origin(
  self : Entity,
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
fn append_port_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
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
    $|<g class="port-node" data-code="\{@svg.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}" stroke="\{stroke}" stroke-width="1.5"/><text x="\{label_x}" y="\{label_y}" class="port-title" fill="\{diagram.style.diagram_text_color()}">\{@svg.xml_escape(entity.display)}</text></g>
}

///|
/// `EntityImageGroup`/`USymbol.asBig`: a declaration keyword opened with `{`
/// draws the symbol over its whole cluster rectangle, with the bold title
/// (and stereotype) placed by the symbol.
fn append_symbol_packages(
  output : StringBuilder,
  diagram : EntityDiagram,
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
  diagram : EntityDiagram,
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
  diagram : EntityDiagram,
  group : Package,
  symbol : String,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  text_metrics : ClassTextMetrics,
) -> Unit {
  let stroke = package_border_color(diagram.style)
  let title = text_metrics.regular.measure(group.display)
  let title_height = title.height.to_double()
  let title_width = title.width.to_double()
  let stereo = match group.stereotype {
    Some(value) => {
      let display = @parse.display_stereotype(value)
      let metrics = text_metrics.italic.measure(display)
      Some((display, metrics.width.to_double() + 2, metrics.height.to_double()))
    }
    None => None
  }
  let stroke_attributes =
    $| stroke="\{stroke}" style="stroke-width:\{@svg.standard_border_stroke_width()}"
  match symbol {
    "node" => {
      output <+
        $|<g class="symbol-package"><polygon points="\{x},\{y + 10} \{x + 10},\{y} \{x + width},\{y} \{x + width},\{y + height - 10} \{x + width - 10},\{y + height} \{x},\{y + height} \{x},\{y + 10}" fill="none" \{stroke_attributes}/><line x1="\{x + width - 10}" y1="\{y + 10}" x2="\{x + width}" y2="\{y}" \{stroke_attributes}/><line x1="\{x}" y1="\{y + 10}" x2="\{x + width - 10}" y2="\{y + 10}" \{stroke_attributes}/><line x1="\{x + width - 10}" y1="\{y + 10}" x2="\{x + width - 10}" y2="\{y + height}" \{stroke_attributes}/>
      let pos_title = (width - title_width) / 2.0 - 4.0
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + pos_title,
        y + 13.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, (width - stereo_width) / 2.0 - 4.0, y + 13.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "frame" => {
      let text_width = title_width + 10.0
      let text_height = title_height + 3.0
      output <+
        $|<g class="symbol-package"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="none" \{stroke_attributes}/><path d="M \{x + text_width} \{y} L \{x + text_width} \{y + text_height - 10} L \{x + text_width - 10} \{y + text_height} L \{x} \{y + text_height}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + 3.0,
        y + 1.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some(
              (
                display,
                x + 4.0 + (width - stereo_width) / 2.0,
                y + 2.0 + text_height,
              ),
            )
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "cloud" => {
      let path = description_cloud_path(width, height, x, y)
      output <+
        $|<g class="symbol-package"><path d="\{path}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 13.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 13.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "database" => {
      let half = width / 2.0
      output <+
        $|<g class="symbol-package"><path d="M \{x} \{y + 10} C \{x} \{y} \{x + half} \{y} \{x + half} \{y} C \{x + half} \{y} \{x + width} \{y} \{x + width} \{y + 10} L \{x + width} \{y + height - 10} C \{x + width} \{y + height} \{x + half} \{y + height} \{x + half} \{y + height} C \{x + half} \{y + height} \{x} \{y + height} \{x} \{y + height - 10} L \{x} \{y + 10}" fill="none" \{stroke_attributes}/><path d="M \{x} \{y + 10} C \{x} \{y + 20} \{x + half} \{y + 20} \{x + half} \{y + 20} C \{x + half} \{y + 20} \{x + width} \{y + 20} \{x + width} \{y + 10}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 22.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 22.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "queue" => {
      let half = y + height / 2.0
      output <+
        $|<g class="symbol-package"><path d="M \{x + 5} \{y} L \{x + width - 5} \{y} C \{x + width} \{y} \{x + width} \{half} \{x + width} \{half} C \{x + width} \{half} \{x + width} \{y + height} \{x + width - 5} \{y + height} L \{x + 5} \{y + height} C \{x} \{y + height} \{x} \{half} \{x} \{half} C \{x} \{half} \{x} \{y} \{x + 5} \{y}" fill="none" \{stroke_attributes}/><path d="M \{x + width - 5} \{y} C \{x + width - 10} \{y} \{x + width - 10} \{half} \{x + width - 10} \{half} C \{x + width - 10} \{y + height} \{x + width - 5} \{y + height} \{x + width - 5} \{y + height}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "stack" => {
      let border = 15.0
      output <+
        $|<g class="symbol-package"><rect x="\{x + border}" y="\{y}" width="\{width - 2 * border}" height="\{height}" rx="2.5" ry="2.5" fill="none" stroke="none"/><path d="M \{x} \{y} L \{x + border - 2.5} \{y} A2.5,2.5 0 0 1 \{x + border} \{y + 2.5} L \{x + border} \{y + height - 2.5} A2.5,2.5 0 0 0 \{x + border + 2.5} \{y + height} L \{x + width - border - 2.5} \{y + height} A2.5,2.5 0 0 0 \{x + width - border} \{y + height - 2.5} L \{x + width - border} \{y + 2.5} A2.5,2.5 0 0 1 \{x + width - border + 2.5} \{y} L \{x + width} \{y}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "storage" => {
      let radius = (35).min((width / 2.0).to_int())
      output <+
        $|<g class="symbol-package"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="\{radius}" ry="\{radius}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 7.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 5.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "artifact" => {
      let x_symbol = x + width - 17.0
      let y_symbol = y + 5.0
      output <+
        $|<g class="symbol-package"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="none" \{stroke_attributes}/><polygon points="\{x_symbol},\{y_symbol} \{x_symbol},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 14} \{x_symbol + 12},\{y_symbol + 6} \{x_symbol + 6},\{y_symbol} \{x_symbol},\{y_symbol}" fill="none" \{stroke_attributes}/><line x1="\{x_symbol + 6}" y1="\{y_symbol}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" \{stroke_attributes}/><line x1="\{x_symbol + 12}" y1="\{y_symbol + 6}" x2="\{x_symbol + 6}" y2="\{y_symbol + 6}" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "card" => {
      output <+
        $|<g class="symbol-package"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "file" => {
      output <+
        $|<g class="symbol-package"><path d="M \{x} \{y + 2.5} L \{x} \{y + height - 2.5} A2.5,2.5 0 0 0 \{x + 2.5} \{y + height} L \{x + width - 2.5} \{y + height} A2.5,2.5 0 0 0 \{x + width} \{y + height - 2.5} L \{x + width} \{y + 10} L \{x + width - 10} \{y} L \{x + 2.5} \{y} A2.5,2.5 0 0 0 \{x} \{y + 2.5}" fill="none" \{stroke_attributes}/><path d="M \{x + width - 10} \{y} L \{x + width - 10} \{y + 7.5} A2.5,2.5 0 0 0 \{x + width - 7.5} \{y + 10} L \{x + width} \{y + 10}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "hexagon" => {
      let quarter_width = width / 4.0
      let half_height = height / 2.0
      output <+
        $|<g class="symbol-package"><polygon points="\{x + width},\{y + half_height} \{x + width - quarter_width},\{y} \{x + quarter_width},\{y} \{x},\{y + half_height} \{x + quarter_width},\{y + height} \{x + width - quarter_width},\{y + height}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "rectangle" => {
      output <+
        $|<g class="symbol-package"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 2.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "action" => {
      let half = y + height / 2.0
      output <+
        $|<g class="symbol-package"><polygon points="\{x},\{y} \{x + width - 10},\{y} \{x + width},\{half} \{x + width - 10},\{y + height} \{x},\{y + height}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some(
              (
                display,
                x + 4.0 + (width - stereo_width) / 2.0,
                y + 2.0 + title_height,
              ),
            )
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "process" => {
      let half = y + height / 2.0
      output <+
        $|<g class="symbol-package"><polygon points="\{x},\{y} \{x + width - 10},\{y} \{x + width},\{half} \{x + width - 10},\{y + height} \{x},\{y + height} \{x + 10},\{half}" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some(
              (
                display,
                x + 4.0 + (width - stereo_width) / 2.0,
                y + 2.0 + title_height,
              ),
            )
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "component" => {
      output <+
        $|<g class="symbol-package"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2.5" ry="2.5" fill="none" \{stroke_attributes}/><rect x="\{x + width - 20}" y="\{y + 5}" width="15" height="10" fill="none" \{stroke_attributes}/><rect x="\{x + width - 22}" y="\{y + 7}" width="4" height="2" fill="none" \{stroke_attributes}/><rect x="\{x + width - 22}" y="\{y + 11}" width="4" height="2" fill="none" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + (width - title_width) / 2.0,
        y + 13.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some((display, x + (width - stereo_width) / 2.0, y + 13.0))
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    "folder" => {
      let wtitle = title_width + 6.0
      let htitle = title_height + 6.0
      output <+
        $|<g class="symbol-package"><path d="M \{x + 2.5} \{y} L \{x + wtitle - 2.5} \{y} A3.75,3.75 0 0 1 \{x + wtitle} \{y + 2.5} L \{x + wtitle + 7} \{y + htitle} L \{x + width - 2.5} \{y + htitle} A2.5,2.5 0 0 1 \{x + width} \{y + htitle + 2.5} L \{x + width} \{y + height - 2.5} A2.5,2.5 0 0 1 \{x + width - 2.5} \{y + height} L \{x + 2.5} \{y + height} A2.5,2.5 0 0 1 \{x} \{y + height - 2.5} L \{x} \{y + 2.5} A2.5,2.5 0 0 1 \{x + 2.5} \{y}" fill="none" \{stroke_attributes}/><line x1="\{x}" y1="\{y + htitle}" x2="\{x + wtitle + 7}" y2="\{y + htitle}" \{stroke_attributes}/>
      append_symbol_package_text(
        output,
        group,
        text_metrics,
        x + 4.0,
        y + 2.0,
        match stereo {
          Some((display, stereo_width, _)) =>
            Some(
              (
                display,
                x + 4.0 + (width - stereo_width) / 2.0,
                y + 2.0 + htitle,
              ),
            )
          None => None
        },
      )
      output.write_string("</g>\n")
    }
    _ => ()
  }
}

///|
fn append_symbol_package_text(
  output : StringBuilder,
  group : Package,
  text_metrics : ClassTextMetrics,
  title_x : Double,
  title_top : Double,
  stereo : (String, Double, Double)?,
) -> Unit {
  match stereo {
    Some((display, x, top)) => {
      let stereo_height = text_metrics.italic.measure(display).height.to_double()
      output <+
        $|<text x="\{x}" y="\{top + stereo_height - 3.0}" class="package-stereotype">\{@svg.xml_escape(display)}</text>
    }
    None => ()
  }
  let title_height = text_metrics.regular.measure(group.display).height.to_double()
  output <+
    $|<text x="\{title_x}" y="\{title_top + title_height - 3.0}" class="package-title">\{@svg.xml_escape(group.display)}</text>
}
