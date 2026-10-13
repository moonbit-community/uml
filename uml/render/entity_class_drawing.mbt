///|
priv struct ClassDrawing {
  graphic : @graphics.Graphic
  diagram : @entity.EntityDiagram
  text_metrics : ClassTextMetrics
}

///|
fn draw_class_text(
  output : @graphics.Graphic,
  x : Int32,
  y : Int32,
  text : String,
  class_name : String,
  metrics : @metrics.FontMetrics,
  fill~ : String = "",
  font_family~ : String = "",
  font_size~ : Int32 = 0,
  italic~ : Bool? = None,
  anchor~ : @graphics.TextAnchor = Start,
) -> Unit {
  draw_entity_text(
    output,
    x.to_double(),
    y.to_double(),
    text,
    metrics,
    class_name~,
    fill~,
    font_family~,
    font_size~,
    anchor~,
    text_style=Some({
      ..Default::default(),
      italic: Some(
        italic.unwrap_or(metrics.style == @metrics.FontStyle::Italic),
      ),
      weight: Some(metrics.font_weight),
    }),
  )
}

///|
fn ClassDrawing::draw_class(
  self : ClassDrawing,
  entity : @entity.Entity,
  index : Int32,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(
    self.diagram,
    index,
    self.text_metrics,
  )
  let header = entity.header_layout(self.text_metrics, self.diagram.family)
  let body = entity.body_layout(self.text_metrics, self.diagram.family)
  let fill = @svg.svg_color(
    entity.color,
    @entity.class_background_color(self.diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    @entity.class_border_color(self.diagram.style),
  )
  let line_style = @svg.line_drawing_style(entity.line_style)
  let line_style = {
    ..line_style,
    stroke: Color(stroke),
    inline: true,
    stroke_width: Some(
      line_style.stroke_width.unwrap_or(@svg.STANDARD_BORDER_WIDTH),
    ),
  }
  let entity_colors = self.diagram.style.defaults().entity_colors()
  let (spot_text, spot_fill) = entity.spot(self.diagram.family, entity_colors)
  let placement = header.placement(width)
  self.graphic.group(
    {
      ..Default::default(),
      class_name: Some("class-node"),
      data: [("code", entity.qualified_code)],
    },
    graphic => {
      graphic
      .with_style({ ..line_style, fill: Color(fill), })
      .draw(
        Rectangle(
          origin=class_point(x, y),
          width=width.to_double(),
          height=height.to_double(),
          rx=None,
          ry=None,
        ),
      )
      let self = { ..self, graphic, }
      self.append_class_spot(entity, x, y, placement, spot_text, spot_fill)
      self.append_class_header(entity, x, y, width, placement, header)
      self.append_class_members(
        entity, x, y, width, header, body, line_style, entity_colors,
      )
    },
  )
}

///|
fn ClassDrawing::append_class_spot(
  self : ClassDrawing,
  entity : @entity.Entity,
  x : Int32,
  y : Int32,
  placement : ClassHeaderPlacement,
  spot_text : String,
  spot_fill : String,
) -> Unit {
  match
    (
      entity.render_capability(self.diagram.family).spot,
      placement.circle_center,
    ) {
    (ClassSpot, Some((circle_cx, circle_cy))) if self.diagram.family is Mbti =>
      // The mbti family labels the node with the bold kind word instead of a
      // circled letter; the shared `.class-spot` style already bolds it.
      draw_class_text(
        self.graphic,
        x + circle_cx,
        y + circle_cy + 4,
        spot_text,
        "class-spot",
        self.text_metrics.regular,
      )
    (ClassSpot, Some((circle_cx, circle_cy))) => {
      self.graphic
      .with_style({
        ..Default::default(),
        fill: Color(spot_fill),
        stroke: Color(self.diagram.style.diagram_line_color()),
        stroke_width: Some(1),
      })
      .draw(
        Circle(
          center=class_point(x + circle_cx, y + circle_cy),
          radius=CLASS_SPOT_RADIUS.to_double(),
        ),
      )
      draw_class_text(
        self.graphic,
        x + circle_cx,
        y + circle_cy + 4,
        spot_text,
        "class-spot",
        self.text_metrics.regular,
      )
    }
    _ => ()
  }
}

///|
fn ClassDrawing::append_class_header(
  self : ClassDrawing,
  entity : @entity.Entity,
  x : Int32,
  y : Int32,
  width : Int32,
  placement : ClassHeaderPlacement,
  header : ClassHeaderLayout,
) -> Unit {
  let italic = entity.kind is @entity.EntityKind::AbstractClass ||
    entity.kind is @entity.EntityKind::Interface
  let text_metrics = self.text_metrics
  let stereotype_font_color = @entity.class_stereotype_font_color(
    self.diagram.style,
  )
  match (header.stereotype, placement.stereotype_position) {
    (Some(stereotype), Some((stereotype_x, stereotype_baseline))) =>
      draw_class_text(
        self.graphic,
        x + stereotype_x,
        y + stereotype_baseline,
        stereotype,
        "class-stereotype",
        text_metrics.class_stereotype,
        fill=stereotype_font_color,
        font_family=text_metrics.class_stereotype_font_family,
        font_size=text_metrics.class_stereotype.font_size,
      )
    _ => ()
  }
  draw_class_text(
    self.graphic,
    x + placement.title_x,
    y + placement.title_baseline,
    header.title_text,
    "class-title",
    entity.title_metrics(text_metrics),
    font_family=self.diagram.style.font_family(),
    fill=self.diagram.style.property_font_color("ClassFontColor"),
    italic=if italic { Some(true) } else { None },
  )
  if header.generic is Some(generic) {
    // HeaderLayout places the generic box above and beyond the top-right
    // corner. Both TextBlockGeneric margins participate in measurement.
    let (gx, gy, gw, gh) = header.generic_rect(width)
    self.graphic
    .with_style({
      fill: Color(@entity.class_background_color(self.diagram.style)),
      stroke: Color(@entity.class_border_color(self.diagram.style)),
      stroke_width: Some(1),
      dash: Some([2, 2]),
      inline: true,
    })
    .draw(
      Rectangle(
        origin=class_point(x + gx, y + gy),
        width=gw.to_double(),
        height=gh.to_double(),
        rx=None,
        ry=None,
      ),
      metadata={ ..Default::default(), class_name: Some("class-generic-box"), },
    )
    draw_class_text(
      self.graphic,
      x + gx + CLASS_GENERIC_MARGIN,
      y +
      gy +
      CLASS_GENERIC_MARGIN +
      text_metrics.class_stereotype.entity_measure(generic).baseline,
      generic,
      "class-generic",
      text_metrics.class_stereotype,
      fill=stereotype_font_color,
      font_family=text_metrics.class_stereotype_font_family,
    )
  }
  match (header.annotation, placement.annotation_position) {
    (Some(annotation), Some((annotation_x, annotation_baseline))) =>
      draw_class_text(
        self.graphic,
        x + annotation_x,
        y + annotation_baseline,
        annotation,
        "class-annotation",
        text_metrics.class_stereotype,
        fill=stereotype_font_color,
        font_family=text_metrics.class_stereotype_font_family,
        font_size=text_metrics.class_stereotype.font_size,
      )
    _ => ()
  }
}

///|
fn ClassDrawing::append_class_members(
  self : ClassDrawing,
  entity : @entity.Entity,
  x : Int32,
  y : Int32,
  width : Int32,
  header : ClassHeaderLayout,
  body : ClassBodyLayout,
  line_style : @graphics.DrawingStyle,
  entity_colors : @style.EntityColors,
) -> Unit {
  let interactive = self.text_metrics.member_interaction &&
    self.diagram.family.capability().class_members_collapsible
  let independent = self.diagram.family is Mbti
  if body.compartments is Some(sections) {
    draw_class_compartments(
      self.graphic,
      sections,
      x,
      y + header.height,
      width,
      self.text_metrics,
      entity_colors,
      self.diagram.style.property_font_color("ClassAttributeFontColor"),
      line_style,
    )
    if interactive {
      append_member_toggle(
        self.graphic,
        entity.qualified_code,
        "all",
        true,
        x,
        y,
        width,
        header.height,
      )
    }
    return
  }
  let sections = [
    (
      "fields",
      body.fields,
      body.fields_height,
      body.fields_collapsed,
      y + header.height,
    ),
    (
      "methods",
      body.methods,
      body.methods_height,
      body.methods_collapsed,
      y + header.height + body.fields_height,
    ),
  ]
  for (section, entries, height, collapsed, top) in sections {
    if collapsed {
      if height > 0 {
        self.graphic
        .with_style(line_style)
        .draw(Line(class_point(x, top), class_point(x + width, top)))
        draw_class_text(
          self.graphic,
          x + width / 2,
          top + self.text_metrics.row_height() + 1,
          "...",
          "member",
          self.text_metrics.regular,
          anchor=Middle,
        )
      }
    } else {
      append_member_section(
        self.graphic,
        x,
        top,
        width,
        entries,
        height,
        self.text_metrics.row_height(),
        entity_colors,
        self.diagram.style.property_font_color("ClassAttributeFontColor"),
        line_style,
        self.text_metrics,
      )
    }
    if interactive && independent && height > 0 {
      append_member_toggle(
        self.graphic,
        entity.qualified_code,
        section,
        !collapsed,
        x,
        top,
        width,
        height,
      )
    }
  }
  if interactive && !independent {
    append_member_toggle(
      self.graphic,
      entity.qualified_code,
      "all",
      !body.fields_collapsed,
      x,
      y,
      width,
      header.height,
    )
  }
}

///|
/// The host handles activation and rerenders with updated member states.
fn append_member_toggle(
  output : @graphics.Graphic,
  code : String,
  section : String,
  expanded : Bool,
  x : Int32,
  y : Int32,
  width : Int32,
  height : Int32,
) -> Unit {
  output.draw(
    ToggleArea(
      origin=class_point(x, y),
      width=width.to_double(),
      height=height.to_double(),
      label="Toggle \{section}",
      expanded~,
    ),
    metadata={
      ..Default::default(),
      data: [("member-node", code), ("member-section", section)],
    },
  )
}

///|
fn append_member_section(
  output : @graphics.Graphic,
  x : Int32,
  y : Int32,
  width : Int32,
  entries : Array[@entity.Member],
  section_height : Int32,
  row_height : Int32,
  entity_colors : @style.EntityColors,
  text_color : String,
  line_style : @graphics.DrawingStyle,
  text_metrics : ClassTextMetrics,
) -> Unit {
  guard section_height > 0 else { return }
  output
  .with_style(line_style)
  .draw(Line(class_point(x, y), class_point(x + width, y)))
  let mut top = y
  for entry in entries {
    let member_y = top + row_height + 1
    output.group({ ..Default::default(), class_name: Some("member-icon"), }, graphic => {
      entry.draw_visibility_icon(graphic, x + 5, member_y, entity_colors)
    })
    draw_member_text(
      output,
      entry,
      x + entry.member_text_x(),
      member_y,
      "member",
      text_metrics,
      text_color,
    )
    top += entry.rendered_height(text_metrics)
  }
}

///|
fn class_point(x : Int32, y : Int32) -> @graphics.Point {
  { x: x.to_double(), y: y.to_double(), }
}

///|
fn draw_member_text(
  output : @graphics.Graphic,
  entry : @entity.Member,
  x : Int32,
  y : Int32,
  class_name : String,
  metrics : ClassTextMetrics,
  color : String,
) -> Unit {
  let font = if entry.is_abstract { metrics.italic } else { metrics.regular }
  let text = entry.display_without_visibility()
  draw_class_text(
    output,
    x,
    y,
    text,
    class_name,
    font,
    italic=if entry.is_abstract { Some(true) } else { None },
    font_family=metrics.style.font_family(),
    fill=color,
  )
  if entry.is_static {
    let measured = font.entity_measure(text)
    output
    .with_style({
      ..Default::default(),
      stroke: Color(color),
      stroke_width: Some(1),
      inline: true,
    })
    .draw(Line(class_point(x, y + 1), class_point(x + measured.width, y + 1)), metadata={
      ..Default::default(),
      class_name: Some("member-static-underline"),
    })
  }
}
