// Node symbol painters consume measured description geometry and emit Graphic commands.
// Container symbols use the distinct USymbol.asBig rules in entity_symbol_package_drawing.mbt.

///|
/// Everything a description symbol shape needs, bundled so each per-symbol
/// painter stays single-purpose.
priv struct DescriptionSymbolContext {
  output : @graphics.Graphic
  description : DescriptionImageLayout
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
) -> Unit {
  match self.description.symbol {
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
  self.append_rectangle()
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
  self.append_rectangle()
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
  let (figure_x, figure_y) = self.description.figure_origin(self.width)
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
  let (figure_x, figure_y) = self.description.figure_origin(self.width)
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
  let (figure_x, figure_y) = self.description.figure_origin(self.width)
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
  self.append_rectangle()
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
  let person = self.description.text.person_geometry()
  let body_width = person.body_width
  let body_height = person.body_height
  let head_size = person.head_size
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
  let (figure_x, figure_y) = self.description.figure_origin(self.width)
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
