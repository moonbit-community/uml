///|
priv struct ClassDrawing {
  graphic : @graphics.Graphic
  diagram : @entity.EntityDiagram
  text_metrics : ClassTextMetrics
}

///|
fn draw_class_text(
  output : @graphics.Graphic,
  x : Int,
  y : Int,
  text : String,
  class_name : String,
  metrics : @metrics.FontMetrics,
  fill? : String = "",
  font_family? : String = "",
  font_size? : Int = 0,
  italic? : Bool? = None,
  anchor? : @graphics.TextAnchor = Start,
) -> Unit {
  let run = entity_text_run(
    text,
    class_point(x, y),
    metrics,
    anchor~,
    font_family~,
    font_size~,
  )
  output
  .with_style({
    ..Default::default(),
    fill: if fill.is_empty() {
      Inherit
    } else {
      Color(fill)
    },
  })
  .draw(StyledText(run, { ..Default::default(), italic, }), metadata={
    ..Default::default(),
    class_name: Some(class_name),
  })
}

///|
fn ClassDrawing::draw_class(
  self : ClassDrawing,
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
      self.append_class_header(entity, x, y, placement, header)
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
  x : Int,
  y : Int,
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
  x : Int,
  y : Int,
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
    entity.display,
    "class-title",
    text_metrics.regular,
    italic=if italic { Some(true) } else { None },
  )
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
  x : Int,
  y : Int,
  width : Int,
  header : ClassHeaderLayout,
  body : ClassBodyLayout,
  line_style : @graphics.DrawingStyle,
  entity_colors : @style.EntityColors,
) -> Unit {
  let interactive = self.text_metrics.member_interaction &&
    self.diagram.family.capability().class_members_collapsible
  let independent = self.diagram.family is Mbti
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
  x : Int,
  y : Int,
  width : Int,
  height : Int,
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
  x : Int,
  y : Int,
  width : Int,
  entries : Array[@entity.Member],
  section_height : Int,
  row_height : Int,
  entity_colors : @style.EntityColors,
  line_style : @graphics.DrawingStyle,
  text_metrics : ClassTextMetrics,
) -> Unit {
  guard section_height > 0 else { return }
  output
  .with_style(line_style)
  .draw(Line(class_point(x, y), class_point(x + width, y)))
  for member_index, entry in entries {
    let member_y = y + (member_index + 1) * row_height + 1
    output.group({ ..Default::default(), class_name: Some("member-icon"), }, graphic => {
      entry.draw_visibility_icon(graphic, x + 5, member_y, entity_colors)
    })
    draw_class_text(
      output,
      x + entry.member_text_x(),
      member_y,
      entry.display_without_visibility(),
      "member",
      text_metrics.regular,
    )
  }
}

///|
fn class_point(x : Int, y : Int) -> @graphics.Point {
  { x: x.to_double(), y: y.to_double(), }
}

///|
fn entity_text_run(
  text : String,
  position : @graphics.Point,
  metrics : @metrics.FontMetrics,
  anchor? : @graphics.TextAnchor = Start,
  font_family? : String = "",
  font_size? : Int = 0,
) -> @graphics.TextRun {
  let measured = metrics.measure(text)
  {
    text,
    position,
    advance: if text.length() > 1 && measured.advance_width > 0 {
      Some(measured.advance_width.to_double())
    } else {
      None
    },
    anchor,
    font_size: (if font_size > 0 { font_size } else { metrics.font_size }).to_double(),
    font_family: if font_family.is_empty() {
      None
    } else {
      Some(font_family)
    },
    strike: false,
  }
}
