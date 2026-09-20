// Container symbol painting follows USymbol.asBig, including per-symbol title placement.
// Small-node text placement remains in entity_description_geometry.mbt.

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
