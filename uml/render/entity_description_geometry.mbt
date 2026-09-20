// Description symbol selection and measured geometry, following
// EntityImageDescription and USymbol.asSmall. Drawing consumes these results.

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
/// Measured description image shared by layout and painting. Symbol painters
/// consume this value without measuring the source entity again.
priv struct DescriptionImageLayout {
  symbol : DescriptionSymbol
  text : DescriptionTextLayout
}

///|
fn @entity.Entity::description_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> DescriptionImageLayout {
  {
    symbol: self.description_symbol(),
    text: self.description_text_layout(text_metrics),
  }
}

///|
priv struct DescriptionPersonGeometry {
  body_width : Int
  body_height : Int
  head_size : Double
}

///|
fn DescriptionTextLayout::person_geometry(
  self : DescriptionTextLayout,
) -> DescriptionPersonGeometry {
  let (left, right, top, bottom) = PersonSymbol.margin()
  let body_width = left + self.block_width + right
  let body_height = top + self.block_height + bottom
  {
    body_width,
    body_height,
    head_size: (body_width.to_double() * body_height.to_double()).sqrt() * 0.42,
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
fn DescriptionImageLayout::dimension(
  self : DescriptionImageLayout,
) -> (Int, Int) {
  let text = self.text
  match self.symbol {
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
      let person = text.person_geometry()
      (
        person.body_width,
        (person.body_height.to_double() + person.head_size).ceil().to_int(),
      )
    }
    BoundarySymbol | ControlSymbol | EntityDomainSymbol | CircleSymbol => {
      let (figure_width, figure_height) = self.symbol
        .figure_dimension()
        .unwrap()
      (
        text.label_width.max(text.stereotype_width).max(figure_width),
        text.stereotype_height + figure_height + text.label_height,
      )
    }
    _ => {
      let (left, right, top, bottom) = self.symbol.margin()
      (left + text.block_width + right, top + text.block_height + bottom)
    }
  }
}

///|
/// Top offset of the label block inside the symbol, in node-local
/// coordinates. Margin symbols start their merged block at their vertical
/// margin; the folder reserves its fixed title strip, the hexagon its 5px
/// inset, and the person its head.
fn DescriptionImageLayout::label_top(self : DescriptionImageLayout) -> Double {
  let (_, _, top, _) = self.symbol.margin()
  match self.symbol {
    FolderSymbol => (top + 15).to_double()
    HexagonSymbol => 5.0
    PersonSymbol => top.to_double() + self.text.person_geometry().head_size
    _ => top.to_double()
  }
}

///|
/// Where the label block and its stereotype baseline sit inside the symbol,
/// in node-local coordinates.
fn DescriptionImageLayout::text_placement(
  self : DescriptionImageLayout,
  width : Int,
) -> ((Int, Int), (Int, Int)?) {
  let text = self.text
  match self.symbol {
    BoundarySymbol | ControlSymbol | EntityDomainSymbol => {
      // `mergeLayoutT12B3`: stereotype above the figure, label below it,
      // each centered on the widest column.
      let (_, figure_height) = self.symbol.figure_dimension().unwrap()
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
      let (left, _right, _, _) = self.symbol.margin()
      let label_top = self.label_top()
      let block_x = match self.symbol {
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
/// Node-local origin of a simple-symbol figure: centered horizontally, below
/// the stereotype strip like `USymbolSimpleAbstract.asSmall`.
fn DescriptionImageLayout::figure_origin(
  self : DescriptionImageLayout,
  width : Int,
) -> (Double, Double) {
  let (figure_width, _) = self.symbol.figure_dimension().unwrap()
  let figure_x = (width.to_double() - figure_width.to_double()) / 2.0
  let figure_y = self.text.stereotype_height.to_double()
  (figure_x, figure_y)
}
