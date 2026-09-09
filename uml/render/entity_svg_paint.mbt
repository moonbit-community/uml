///|
/// The always-repeated painter dependencies, bundled so per-entity paint
/// helpers can take a single context instead of a long parameter list.
priv struct EntityPaintContext {
  output : @graphics.Graphic
  diagram : @entity.EntityDiagram
  text_metrics : ClassTextMetrics
}

///|
const PACKAGE_TAB_HEIGHT : Double = 22.0

///|
/// Emit a single-line `<text>` pinned to its measured advance via
/// `textLength`, matching how PlantUML serializes every text run.
fn append_paint_text(
  output : @graphics.Graphic,
  x : Int,
  y : Int,
  text : String,
  class_name : String,
  metrics : @metrics.FontMetrics,
  fill? : String = "",
  font_family? : String = "",
  font_size? : Int = 0,
) -> Unit {
  draw_class_text(
    output,
    x,
    y,
    text,
    class_name,
    metrics,
    fill~,
    font_family~,
    font_size~,
  )
}

///|
fn append_packages(
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
      // Symbol packages are painted by `append_symbol_packages` instead.
      guard group.symbol is None else { continue }
      let fill = @svg.svg_color(
        group.color,
        @entity.package_background_color(diagram.style),
      )
      let tab_width = text_metrics.regular.measure(group.display).width.to_double() +
        18.0
      let x = package_layout.x
      let y = package_layout.y
      let right = x + package_layout.width
      let bottom = y + package_layout.height
      let border_color = @entity.package_border_color(diagram.style)
      output.group({ ..Default::default(), class_name: Some("package"), }, output => {
        output
        .with_style({
          ..Default::default(),
          stroke: Color(border_color),
          inline: true,
          fill: Color(fill),
        })
        .draw(
          Path([
            MoveTo({ x: x + 2.5, y, }),
            LineTo({ x: x + tab_width - 9.0, y, }),
            QuadraticTo({ x: x + tab_width - 6.5, y, }, {
              x: x + tab_width - 5.5,
              y: y + 2.5,
            }),
            LineTo({ x: x + tab_width + 1.5, y: y + PACKAGE_TAB_HEIGHT, }),
            LineTo({ x: right - 2.5, y: y + PACKAGE_TAB_HEIGHT, }),
            QuadraticTo({ x: right, y: y + PACKAGE_TAB_HEIGHT, }, {
              x: right,
              y: y + PACKAGE_TAB_HEIGHT + 2.5,
            }),
            LineTo({ x: right, y: bottom - 2.5, }),
            QuadraticTo({ x: right, y: bottom, }, { x: right - 2.5, y: bottom, }),
            LineTo({ x: x + 2.5, y: bottom, }),
            QuadraticTo({ x, y: bottom, }, { x, y: bottom - 2.5, }),
            LineTo({ x, y: y + 2.5, }),
            QuadraticTo({ x, y, }, { x: x + 2.5, y, }),
          ]),
        )
        output
        .with_style({
          ..Default::default(),
          stroke: Color(border_color),
          inline: true,
        })
        .draw(
          Line({ x, y: y + PACKAGE_TAB_HEIGHT, }, {
            x: x + tab_width + 1.5,
            y: y + PACKAGE_TAB_HEIGHT,
          }),
        )
        draw_entity_text(
          output,
          x + 4.0,
          y + 16.0,
          group.display,
          text_metrics.regular,
          class_name="package-title",
        )
        if group.stereotype is Some(stereotype) {
          let display = @tokenizer.display_stereotype(stereotype)
          let metrics = text_metrics.italic.measure(display)
          let stereotype_x = x +
            (package_layout.width - metrics.width.to_double()) / 2.0
          draw_entity_text(
            output,
            stereotype_x,
            y + PACKAGE_TAB_HEIGHT + 2.0 + metrics.ascent.to_double(),
            display,
            text_metrics.italic,
            class_name="package-stereotype",
          )
        }
      })
    }
  }
}

///|
fn ClassLayout::node_y(self : ClassLayout, index : Int) -> Int {
  24 + index / self.columns * self.cell_height
}

///|
fn EntityPaintContext::append_entity_image(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  match entity.render_capability(self.diagram.family).renderer {
    ClassRenderer => self.append_entity(entity, index, layout)
    ObjectRenderer | MapRenderer | JsonRenderer =>
      self.append_object_like(entity, index, layout)
    LollipopRenderer => self.append_lollipop(entity, index, layout)
    PointRenderer => self.append_point(entity, index, layout)
    UsecaseRenderer | ActorRenderer | ComponentRenderer =>
      self.append_usecase(entity, index, layout)
    DescriptionRenderer => self.append_description(entity, index, layout)
    PortRenderer => self.append_port(entity, index, layout)
  }
}

///|
/// Dominant direction from the lollipop node toward its attached entity,
/// mirroring `EntityImageLollipopInterface.addImpact` input.
fn lollipop_attachment_direction(
  diagram : @entity.EntityDiagram,
  code : String,
  center : (Int, Int),
  layout : ClassLayout,
  text_metrics : ClassTextMetrics,
) -> (Double, Double) {
  for relation in diagram.relations {
    let other = if relation.left == code {
      Some(relation.right)
    } else if relation.right == code {
      Some(relation.left)
    } else {
      None
    }
    if other is Some(other) {
      if entity_index(diagram, other) is Some(other_index) {
        let (ox, oy, ow, oh) = layout.entity_rect(
          diagram, other_index, text_metrics,
        )
        return (
          (ox + ow / 2 - center.0).to_double(),
          (oy + oh / 2 - center.1).to_double(),
        )
      }
    }
  }
  (0.0, -1.0)
}

///|
/// Half-lollipop arc bulging toward the attached entity: the curved side
/// faces the entity while the flat side opens away from it.
fn lollipop_half_arc(
  center_x : Int,
  center_y : Int,
  direction : (Double, Double),
) -> Array[@graphics.PathSegment] {
  let radius = (LOLLIPOP_SIZE / 2).to_double()
  let x = center_x.to_double()
  let y = center_y.to_double()
  let horizontal = direction.0.abs() > direction.1.abs()
  let (start, end) : (@graphics.Point, @graphics.Point) = if horizontal {
    if direction.0 > 0 {
      ({ x, y: y - radius, }, { x, y: y + radius, })
    } else {
      ({ x, y: y + radius, }, { x, y: y - radius, })
    }
  } else if direction.1 > 0 {
    ({ x: x - radius, y, }, { x: x + radius, y, })
  } else {
    ({ x: x + radius, y, }, { x: x - radius, y, })
  }
  [
    MoveTo(start),
    ArcTo(
      rx=radius,
      ry=radius,
      rotation=0,
      large_arc=false,
      sweep=horizontal,
      end~,
    ),
  ]
}

///|
/// `EntityImageLollipopInterface`: a fixed-size circle (or half circle for
/// required interfaces) with the interface name centered below it. The name
/// overflows the small node, matching the Java image contract.
fn EntityPaintContext::append_lollipop(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(
    self.diagram,
    index,
    self.text_metrics,
  )
  let center_x = x + width / 2
  let center_y = y + height / 2
  let fill = @svg.svg_color(
    entity.color,
    self.diagram.style.defaults().entity_colors().node,
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    self.diagram.style.diagram_line_color(),
  )
  let title = self.text_metrics.regular.measure(entity.display)
  let title_x = x + LOLLIPOP_SIZE / 2 - title.width / 2
  let title_y = y + LOLLIPOP_SIZE + title.ascent
  self.output.group(
    {
      ..Default::default(),
      class_name: Some("lollipop-node"),
      data: [("code", entity.qualified_code)],
    },
    graphic => {
      let self = { ..self, output: graphic, }
      match entity.kind {
        LollipopHalf => {
          let direction = lollipop_attachment_direction(
            self.diagram,
            entity.qualified_code,
            (center_x, center_y),
            layout,
            self.text_metrics,
          )
          self.output
          .with_style({
            ..Default::default(),
            fill: Color(fill),
            stroke: Color(stroke),
            stroke_width: Some(@svg.EMPHASIZED_STROKE_WIDTH),
          })
          .draw(Path(lollipop_half_arc(center_x, center_y, direction)), metadata={
            ..Default::default(),
          })
        }
        _ =>
          self.output
          .with_style({
            ..Default::default(),
            fill: Color(fill),
            stroke: Color(stroke),
            stroke_width: Some(@svg.EMPHASIZED_STROKE_WIDTH),
          })
          .draw(
            Ellipse(
              center={ x: center_x.to_double(), y: center_y.to_double(), },
              rx=(width / 2).to_double(),
              ry=(height / 2).to_double(),
            ),
          )
      }
      append_paint_text(
        self.output,
        title_x,
        title_y,
        entity.display,
        "lollipop-title",
        self.text_metrics.regular,
        fill=self.diagram.style.diagram_text_color(),
      )
    },
  )
}

///|
/// `EntityImageAssociationPoint`: a fixed 4x4 circle filled with the line
/// color, drawn without an entity group like the Java image.
fn EntityPaintContext::append_point(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(
    self.diagram,
    index,
    self.text_metrics,
  )
  let color = self.diagram.style.diagram_line_color()
  self.output
  .with_style({
    ..Default::default(),
    fill: Color(color),
    stroke: Color(color),
    stroke_width: Some(1),
  })
  .draw(
    Ellipse(
      center={
        x: (x + width / 2).to_double(),
        y: (y + height / 2).to_double(),
      },
      rx=(width / 2).to_double(),
      ry=(height / 2).to_double(),
    ),
  )
}

///|
/// Paint an object-family rectangular image without class-only spot or
/// compartment semantics. Map rows and JSON trees replace the provisional
/// empty object-like body in O3 and O4, while keeping this image contract.
fn EntityPaintContext::append_object_like(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let capability = entity.render_capability(self.diagram.family)
  let (x, y, width, height) = layout.entity_rect(
    self.diagram,
    index,
    self.text_metrics,
  )
  let is_json = capability.renderer is JsonRenderer
  let header = if is_json {
    entity.json_header_layout(self.text_metrics)
  } else {
    entity.object_header_layout(self.text_metrics)
  }
  let fill = @svg.svg_color(
    entity.color,
    capability.style_role.background_color(self.diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    capability.style_role.border_color(self.diagram.style),
  )
  let line_attributes = {
    ..entity_line_style(entity.line_style),
    stroke: Color(stroke),
  }
  let separator_attributes = {
    ..entity_line_style(None),
    stroke: Color(stroke),
  }
  let placement = if is_json {
    header.json_placement(width)
  } else {
    header.placement(width)
  }
  let text_color = capability.style_role.font_color(self.diagram.style)
  self.output.group(
    {
      ..Default::default(),
      class_name: Some(capability.node_class()),
      data: [("code", entity.qualified_code)],
    },
    graphic => {
      let self = { ..self, output: graphic, }
      with_entity_link(self.output, entity.url, graphic => {
        let self = { ..self, output: graphic, }
        self.output
        .with_style({ ..line_attributes, fill: Color(fill), })
        .draw(
          Rectangle(
            origin={ x: x.to_double(), y: y.to_double(), },
            width=width.to_double(),
            height=height.to_double(),
            rx=Some(OBJECT_ROUND_CORNER),
            ry=Some(OBJECT_ROUND_CORNER),
          ),
        )
        self.append_object_header(
          capability, entity, x, y, width, header, placement, text_color, line_attributes,
        )
        match capability.body {
          MapEntries =>
            self.append_map_body(
              entity, x, y, width, header, separator_attributes, text_color,
            )
          OrderedMembers =>
            self.append_object_body(
              entity, x, y, width, header, separator_attributes,
            )
          JsonData =>
            self.append_json_body(entity, x, y, header, stroke, text_color)
          ClassCompartments | NoBody => panic()
        }
      })
    },
  )
}

///|
fn EntityPaintContext::append_object_header(
  self : EntityPaintContext,
  capability : @entity.EntityRenderCapability,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  width : Int,
  header : ObjectHeaderLayout,
  placement : (Int, Int, (Int, Int)?),
  text_color : String,
  line_attributes : @graphics.DrawingStyle,
) -> Unit {
  match (capability.renders_stereotype, header.stereotype, placement.2) {
    (true, Some(stereotype), Some((stereotype_x, stereotype_baseline))) =>
      append_paint_text(
        self.output,
        x + stereotype_x,
        y + stereotype_baseline,
        stereotype,
        capability.stereotype_class(),
        self.text_metrics.class_stereotype,
        fill=text_color,
        font_family=self.text_metrics.class_stereotype_font_family,
        font_size=self.text_metrics.class_stereotype.font_size,
      )
    _ => ()
  }
  append_paint_text(
    self.output,
    x + placement.0,
    y + placement.1,
    entity.display,
    capability.title_class(),
    self.text_metrics.regular,
    fill=text_color,
  )
  self.output
  .with_style({ ..line_attributes, })
  .draw(
    Line({ x: x.to_double(), y: (y + header.height).to_double(), }, {
      x: (x + width).to_double(),
      y: (y + header.height).to_double(),
    }),
  )
}

///|
fn EntityPaintContext::append_map_body(
  self : EntityPaintContext,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  width : Int,
  header : ObjectHeaderLayout,
  separator_attributes : @graphics.DrawingStyle,
  text_color : String,
) -> Unit {
  let body = entity.map_body_layout(self.text_metrics)
  let output = self.output
  for row_index, row in body.rows {
    let row_y = y + header.height + row.top
    if row_index > 0 {
      output
      .with_style({ ..separator_attributes, })
      .draw(
        Line({ x: x.to_double(), y: row_y.to_double(), }, {
          x: (x + width).to_double(),
          y: row_y.to_double(),
        }),
        metadata={
          ..Default::default(),
          class_name: Some("map-row-separator"),
        },
      )
    }
    let svg_port_id = "map-port-" +
      stable_port_identifier(entity.qualified_code) +
      "-" +
      row.port_id
    output.group(
      {
        id: Some(svg_port_id),
        class_name: Some(
          "map-row\{if row.entry.link_target is Some(_) { " map-link-row" } else { " map-value-row" }}",
        ),
        data: [("port", row.entry.key), ("port-id", row.port_id)],
      },
      output => {
        let key_metrics = self.text_metrics.regular.measure(row.key)
        let key_x = if row.entry.link_target is Some(_) {
          x + (width - key_metrics.width) / 2
        } else {
          x + (body.key_column_width - key_metrics.width) / 2
        }
        let key_y = row_y +
          (row.height - key_metrics.height) / 2 +
          key_metrics.baseline
        append_paint_text(
          output,
          key_x,
          key_y,
          row.key,
          "map-key member",
          self.text_metrics.regular,
          fill=text_color,
        )
        match row.entry.value {
          Some(value) => {
            let value_metrics = self.text_metrics.regular.measure(value)
            let divider_x = x + body.key_column_width
            let value_x = divider_x +
              (body.value_column_width - value_metrics.width) / 2
            let value_y = row_y +
              (row.height - value_metrics.height) / 2 +
              value_metrics.baseline
            output
            .with_style({ ..separator_attributes, })
            .draw(
              Line({ x: divider_x.to_double(), y: row_y.to_double(), }, {
                x: divider_x.to_double(),
                y: (row_y + row.height).to_double(),
              }),
              metadata={
                ..Default::default(),
                class_name: Some("map-column-separator"),
              },
            )
            append_paint_text(
              output,
              value_x,
              value_y,
              value,
              "map-value member",
              self.text_metrics.regular,
              fill=text_color,
            )
          }
          None => ()
        }
      },
    )
  }
}

///|
fn EntityPaintContext::append_object_body(
  self : EntityPaintContext,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  width : Int,
  header : ObjectHeaderLayout,
  separator_attributes : @graphics.DrawingStyle,
) -> Unit {
  let body = entity.object_body_layout(self.text_metrics)
  let row_height = self.text_metrics.row_height()
  let text_x = if body.has_visibility { 20 } else { 5 }
  let entity_colors = self.diagram.style.defaults().entity_colors()
  let mut body_y = y + header.height
  let output = self.output
  for entry in body.entries {
    if entry.is_separator {
      body_y += OBJECT_SEPARATOR_HEIGHT
      output
      .with_style({ ..separator_attributes, })
      .draw(
        Line({ x: x.to_double(), y: body_y.to_double(), }, {
          x: (x + width).to_double(),
          y: body_y.to_double(),
        }),
        metadata={ ..Default::default(), class_name: Some("object-separator"), },
      )
    } else {
      let member_y = body_y + row_height + 1
      output.group({ ..Default::default(), class_name: Some("member-icon"), }, graphic => {
        entry.draw_visibility_icon(graphic, x + 5, member_y, entity_colors)
      })
      append_paint_text(
        output,
        x + text_x,
        member_y,
        entry.display_without_visibility(),
        "object-member member",
        self.text_metrics.regular,
      )
      body_y += row_height
    }
  }
}

///|
fn EntityPaintContext::append_json_body(
  self : EntityPaintContext,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  header : ObjectHeaderLayout,
  stroke : String,
  text_color : String,
) -> Unit {
  let body = entity.json_body_layout(self.text_metrics)
  let body_top = y + header.height
  let json_separator_attributes = {
    ..entity_line_style(None),
    stroke: Color(stroke),
    stroke_width: Some(1),
  }
  let output = self.output
  for divider in body.dividers {
    output
    .with_style({ ..json_separator_attributes, })
    .draw(
      Line(
        {
          x: (x + divider.x).to_double(),
          y: (body_top + divider.top).to_double(),
        },
        {
          x: (x + divider.x).to_double(),
          y: (body_top + divider.top + divider.height).to_double(),
        },
      ),
      metadata={
        ..Default::default(),
        class_name: Some("json-column-separator"),
      },
    )
  }
  for row in body.rows {
    if row.hline {
      output
      .with_style({ ..json_separator_attributes, })
      .draw(
        Line(
          {
            x: (x + row.hline_from).to_double(),
            y: (body_top + row.top).to_double(),
          },
          {
            x: (x + row.hline_from + row.hline_width).to_double(),
            y: (body_top + row.top).to_double(),
          },
        ),
        metadata={
          ..Default::default(),
          class_name: Some("json-row-separator"),
        },
      )
    }
    match row.key {
      Some(key) => {
        let key_metrics = self.text_metrics.regular.measure(key)
        append_paint_text(
          output,
          x + row.hline_from + MAP_CELL_HORIZONTAL_PADDING,
          body_top + row.top + MAP_CELL_VERTICAL_PADDING + key_metrics.ascent,
          key,
          "json-key member",
          self.text_metrics.regular,
          fill=text_color,
        )
      }
      None => ()
    }
    match row.value {
      Some(value) => {
        let value_metrics = self.text_metrics.regular.measure(value)
        append_paint_text(
          output,
          x + row.value_x + MAP_CELL_HORIZONTAL_PADDING,
          body_top + row.top + MAP_CELL_VERTICAL_PADDING + value_metrics.ascent,
          value,
          "json-value member",
          self.text_metrics.regular,
          fill=text_color,
        )
      }
      None => ()
    }
  }
}

///|
fn EntityPaintContext::append_entity(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  let drawing = {
    graphic: self.output,
    diagram: self.diagram,
    text_metrics: self.text_metrics,
  }
  drawing.draw_class(entity, index, layout)
}

///|
fn EntityPaintContext::append_usecase(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let capability = entity.render_capability(self.diagram.family)
  let (x, y, width, height) = layout.entity_rect(
    self.diagram,
    index,
    self.text_metrics,
  )
  let fill = @svg.svg_color(
    entity.color,
    capability.style_role.background_color(self.diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    capability.style_role.border_color(self.diagram.style),
  )
  let text_color = capability.style_role.font_color(self.diagram.style)
  let line_attributes = entity_line_style(entity.line_style)
  match capability.renderer {
    UsecaseRenderer | ActorRenderer | ComponentRenderer => ()
    _ => {
      self.append_entity(entity, index, layout)
      return
    }
  }
  self.output.group(
    {
      ..Default::default(),
      class_name: Some(capability.node_class()),
      data: [("code", entity.qualified_code)],
    },
    graphic => {
      let self = { ..self, output: graphic, }
      with_entity_link(self.output, entity.url, graphic => {
        let self = { ..self, output: graphic, }
        match entity.kind {
          @entity.EntityKind::Usecase | @entity.EntityKind::BusinessUsecase =>
            self.append_usecase_body(
              entity, x, y, width, height, capability, fill, stroke, line_attributes,
              text_color,
            )
          @entity.EntityKind::Actor | @entity.EntityKind::BusinessActor =>
            self.append_actor_body(
              entity, x, y, width, capability, fill, stroke, line_attributes, text_color,
            )
          @entity.EntityKind::Component =>
            self.append_component_body(
              entity, x, y, width, height, capability, fill, stroke, line_attributes,
              text_color,
            )
          _ => ()
        }
      })
    },
  )
}

///|
fn EntityPaintContext::append_usecase_body(
  self : EntityPaintContext,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  capability : @entity.EntityRenderCapability,
  fill : String,
  stroke : String,
  line_attributes : @graphics.DrawingStyle,
  text_color : String,
) -> Unit {
  let (_, content_height, stereotype) = entity.usecase_content_layout(
    self.text_metrics,
  )
  // TextBlockInEllipse centers the text block, then applies dy - 2.
  // The ellipse itself has grown by 6px, so SVG text needs a +2px
  // top offset before converting its font ascent to a baseline.
  let content_top = y + height / 2 - content_height / 2 + 2
  let title_metrics = self.text_metrics.usecase_regular.measure(entity.display)
  let output = self.output
  output
  .with_style({ ..line_attributes, fill: Color(fill), stroke: Color(stroke), })
  .draw(
    Ellipse(
      center={
        x: (x + width / 2).to_double(),
        y: (y + height / 2).to_double(),
      },
      rx=(width / 2).to_double(),
      ry=(height / 2).to_double(),
    ),
  )
  match stereotype {
    Some(value) => {
      let metrics = self.text_metrics.usecase_italic.measure(value)
      append_paint_text(
        output,
        x + width / 2,
        content_top + metrics.baseline,
        value,
        capability.stereotype_class(),
        self.text_metrics.usecase_italic,
        fill=text_color,
        font_family=self.text_metrics.usecase_font_family,
        font_size=self.text_metrics.usecase_italic.font_size,
      )
    }
    None => ()
  }
  let title_y = match stereotype {
    Some(value) =>
      content_top +
      self.text_metrics.usecase_italic.measure(value).height +
      title_metrics.baseline
    None => content_top + title_metrics.baseline
  }
  append_paint_text(
    output,
    x + width / 2,
    title_y,
    entity.display,
    capability.title_class(),
    self.text_metrics.usecase_regular,
    fill=text_color,
    font_family=self.text_metrics.usecase_font_family,
    font_size=self.text_metrics.usecase_regular.font_size,
  )
  if entity.kind is @entity.EntityKind::BusinessUsecase {
    let (mark_start, mark_end) = usecase_business_mark(x, y, width, height)
    output
    .with_style({ ..line_attributes, stroke: Color(stroke), })
    .draw(
      Path([
        MoveTo({ x: mark_start.0, y: mark_start.1, }),
        LineTo({ x: mark_end.0, y: mark_end.1, }),
      ]),
      metadata={
        ..Default::default(),
        class_name: Some("usecase-business-mark"),
      },
    )
  }
}

///|
fn EntityPaintContext::append_actor_body(
  self : EntityPaintContext,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  width : Int,
  capability : @entity.EntityRenderCapability,
  fill : String,
  stroke : String,
  line_attributes : @graphics.DrawingStyle,
  text_color : String,
) -> Unit {
  let output = self.output
  let text_metrics = self.text_metrics
  let center_x = x + width / 2
  let title = text_metrics.actor_regular.measure(entity.display)
  let (_, _, stereotype) = entity.actor_content_layout(text_metrics)
  let appearance = actor_appearance(text_metrics.actor_style)
  let (figure_width, figure_height) = actor_figure_geometry(
    appearance,
    business=entity.kind is @entity.EntityKind::BusinessActor,
  )
  let stereotype_height = stereotype.map_or(0, value => {
    text_metrics.actor_italic.measure(value).height
  })
  let figure_top = y + stereotype_height
  let label_y = figure_top + figure_height + title.baseline
  match stereotype {
    Some(value) => {
      let metrics = text_metrics.actor_italic.measure(value)
      append_paint_text(
        output,
        center_x,
        y + metrics.baseline,
        value,
        capability.stereotype_class(),
        text_metrics.actor_italic,
        fill=text_color,
        font_family=text_metrics.actor_font_family,
        font_size=text_metrics.actor_italic.font_size,
      )
    }
    None => ()
  }
  if entity.kind is @entity.EntityKind::Actor {
    match appearance {
      Awesome => {
        output
        .with_style({
          ..line_attributes,
          fill: Color(fill),
          stroke: Color(stroke),
        })
        .draw(
          Circle(
            center={
              x: center_x.to_double(),
              y: (figure_top + 17).to_double(),
            },
            radius=16,
          ),
        )
        output
        .with_style({
          ..line_attributes,
          fill: Color(fill),
          stroke: Color(stroke),
        })
        .draw(
          Path([
            MoveTo({
              x: (center_x - 27).to_double(),
              y: (figure_top + 50).to_double(),
            }),
            QuadraticTo(
              { x: center_x.to_double(), y: (figure_top + 38).to_double(), },
              {
                x: (center_x + 27).to_double(),
                y: (figure_top + 50).to_double(),
              },
            ),
            LineTo({
              x: (center_x + 27).to_double(),
              y: (figure_top + 62).to_double(),
            }),
            QuadraticTo(
              {
                x: (center_x + 27).to_double(),
                y: (figure_top + 62).to_double(),
              },
              {
                x: (center_x + 19).to_double(),
                y: (figure_top + 62).to_double(),
              },
            ),
            LineTo({
              x: (center_x - 19).to_double(),
              y: (figure_top + 62).to_double(),
            }),
            QuadraticTo(
              {
                x: (center_x - 27).to_double(),
                y: (figure_top + 62).to_double(),
              },
              {
                x: (center_x - 27).to_double(),
                y: (figure_top + 54).to_double(),
              },
            ),
            Close,
          ]),
          metadata={
            ..Default::default(),
            class_name: Some("actor-awesome-body"),
          },
        )
      }
      Hollow => {
        output
        .with_style({
          ..line_attributes,
          fill: Color(fill),
          stroke: Color(stroke),
        })
        .draw(
          Circle(
            center={ x: center_x.to_double(), y: (figure_top + 5).to_double(), },
            radius=4,
          ),
        )
        output
        .with_style({
          ..line_attributes,
          fill: Color(fill),
          stroke: Color(stroke),
        })
        .draw(
          Path([
            MoveTo({
              x: (center_x - 13).to_double(),
              y: (figure_top + 12).to_double(),
            }),
            LineTo({
              x: (center_x + 13).to_double(),
              y: (figure_top + 12).to_double(),
            }),
            LineTo({
              x: (center_x + 13).to_double(),
              y: (figure_top + 17).to_double(),
            }),
            LineTo({
              x: (center_x + 3).to_double(),
              y: (figure_top + 17).to_double(),
            }),
            LineTo({
              x: (center_x + 3).to_double(),
              y: (figure_top + 27).to_double(),
            }),
            LineTo({
              x: (center_x + 9).to_double(),
              y: (figure_top + 35).to_double(),
            }),
            LineTo({
              x: (center_x + 3).to_double(),
              y: (figure_top + 35).to_double(),
            }),
            LineTo({
              x: center_x.to_double(),
              y: (figure_top + 30).to_double(),
            }),
            LineTo({
              x: (center_x - 3).to_double(),
              y: (figure_top + 35).to_double(),
            }),
            LineTo({
              x: (center_x - 9).to_double(),
              y: (figure_top + 35).to_double(),
            }),
            LineTo({
              x: (center_x - 3).to_double(),
              y: (figure_top + 27).to_double(),
            }),
            LineTo({
              x: (center_x - 3).to_double(),
              y: (figure_top + 17).to_double(),
            }),
            LineTo({
              x: (center_x - 13).to_double(),
              y: (figure_top + 17).to_double(),
            }),
            Close,
          ]),
          metadata={
            ..Default::default(),
            class_name: Some("actor-hollow-body"),
          },
        )
      }
      Stickman => ()
    }
  }
  if entity.kind is @entity.EntityKind::BusinessActor || appearance is Stickman {
    output
    .with_style({ ..line_attributes, fill: Color(fill), stroke: Color(stroke), })
    .draw(
      Circle(
        center={ x: center_x.to_double(), y: (figure_top + 9).to_double(), },
        radius=8,
      ),
    )
    output
    .with_style({ ..line_attributes, fill: None, stroke: Color(stroke), })
    .draw(
      Path([
        MoveTo({ x: center_x.to_double(), y: (figure_top + 17).to_double(), }),
        LineTo({ x: center_x.to_double(), y: (figure_top + 43).to_double(), }),
        MoveTo({
          x: (center_x - 13).to_double(),
          y: (figure_top + 27).to_double(),
        }),
        LineTo({
          x: (center_x + 13).to_double(),
          y: (figure_top + 27).to_double(),
        }),
        MoveTo({ x: center_x.to_double(), y: (figure_top + 43).to_double(), }),
        LineTo({
          x: (center_x - 13).to_double(),
          y: (figure_top + figure_height).to_double(),
        }),
        MoveTo({ x: center_x.to_double(), y: (figure_top + 43).to_double(), }),
        LineTo({
          x: (center_x + 13).to_double(),
          y: (figure_top + figure_height).to_double(),
        }),
      ]),
    )
  }
  append_paint_text(
    output,
    center_x,
    label_y,
    entity.display,
    capability.title_class(),
    text_metrics.actor_regular,
    fill=text_color,
    font_family=text_metrics.actor_font_family,
    font_size=text_metrics.actor_regular.font_size,
  )
  if entity.kind is @entity.EntityKind::BusinessActor &&
    figure_width == ACTOR_FIGURE_WIDTH {
    let (mark_start, mark_end) = actor_business_mark(
      center_x,
      figure_top + 9,
      8,
    )
    output
    .with_style({ ..line_attributes, stroke: Color(stroke), })
    .draw(
      Path([
        MoveTo({ x: mark_start.0, y: mark_start.1, }),
        LineTo({ x: mark_end.0, y: mark_end.1, }),
      ]),
      metadata={
        ..Default::default(),
        class_name: Some("actor-business-mark"),
      },
    )
  }
}

///|
fn EntityPaintContext::append_component_body(
  self : EntityPaintContext,
  entity : @entity.Entity,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  capability : @entity.EntityRenderCapability,
  fill : String,
  stroke : String,
  line_attributes : @graphics.DrawingStyle,
  text_color : String,
) -> Unit {
  let title = self.text_metrics.regular.measure(entity.display)
  let tab_x = x + width - COMPONENT_TAB_WIDTH - COMPONENT_TAB_INSET
  let tab_y = y + COMPONENT_TAB_INSET
  let mark_x = tab_x - COMPONENT_TAB_MARK_LEFT_OFFSET
  let first_mark_y = tab_y + COMPONENT_TAB_MARK_TOP_OFFSET
  let second_mark_y = first_mark_y + COMPONENT_TAB_MARK_GAP
  self.output
  .with_style({ ..line_attributes, fill: Color(fill), stroke: Color(stroke), })
  .draw(
    Rectangle(
      origin={ x: x.to_double(), y: y.to_double(), },
      width=width.to_double(),
      height=height.to_double(),
      rx=Some(2),
      ry=Some(2),
    ),
    metadata={ ..Default::default(), class_name: Some("component-body"), },
  )
  self.output
  .with_style({ ..line_attributes, fill: Color(fill), stroke: Color(stroke), })
  .draw(
    Rectangle(
      origin={ x: tab_x.to_double(), y: tab_y.to_double(), },
      width=COMPONENT_TAB_WIDTH.to_double(),
      height=COMPONENT_TAB_HEIGHT.to_double(),
      rx=None,
      ry=None,
    ),
    metadata={ ..Default::default(), class_name: Some("component-tab"), },
  )
  self.output
  .with_style({ ..line_attributes, fill: Color(fill), stroke: Color(stroke), })
  .draw(
    Rectangle(
      origin={ x: mark_x.to_double(), y: first_mark_y.to_double(), },
      width=COMPONENT_TAB_MARK_WIDTH.to_double(),
      height=COMPONENT_TAB_MARK_HEIGHT.to_double(),
      rx=None,
      ry=None,
    ),
    metadata={ ..Default::default(), class_name: Some("component-tab-mark"), },
  )
  self.output
  .with_style({ ..line_attributes, fill: Color(fill), stroke: Color(stroke), })
  .draw(
    Rectangle(
      origin={ x: mark_x.to_double(), y: second_mark_y.to_double(), },
      width=COMPONENT_TAB_MARK_WIDTH.to_double(),
      height=COMPONENT_TAB_MARK_HEIGHT.to_double(),
      rx=None,
      ry=None,
    ),
    metadata={ ..Default::default(), class_name: Some("component-tab-mark"), },
  )
  append_paint_text(
    self.output,
    x + width / 2,
    y + (height + title.height) / 2 - 2,
    entity.display,
    capability.title_class(),
    self.text_metrics.regular,
    fill=text_color,
  )
}

///|
