///|
fn entity_line_style(line_style : String?) -> @graphics.DrawingStyle {
  let style = @svg.line_drawing_style(line_style)
  {
    ..style,
    stroke_width: if style.dash is Some(_) {
      style.stroke_width
    } else {
      Some(style.stroke_width.unwrap_or(@svg.STANDARD_BORDER_WIDTH))
    },
    inline: true,
  }
}

///|
fn with_entity_link(
  graphic : @graphics.Graphic,
  url : String?,
  draw : (@graphics.Graphic) -> Unit,
) -> Unit {
  guard url is Some(url) else { return draw(graphic) }
  graphic.link(url, draw)
}

///|
fn draw_entity_text(
  graphic : @graphics.Graphic,
  x : Double,
  y : Double,
  text : String,
  metrics : @metrics.FontMetrics,
  class_name? : String,
  fill? : String = "",
  font_family? : String = "",
  font_size? : Int = 0,
  anchor? : @graphics.TextAnchor = Start,
  text_style? : @graphics.TextStyle? = None,
) -> Unit {
  if state_rich_text(text, metrics, 0.0, literal_newlines=true) is Some(rich) {
    let styled = graphic.with_style({
      ..Default::default(),
      fill: if fill.is_empty() {
        Inherit
      } else {
        Color(fill)
      },
    })
    rich.draw(
      styled,
      x,
      y - metrics.ascent.to_double(),
      metrics,
      { ..Default::default(), class_name, },
      anchor,
      None,
    )
    return
  }
  if text.contains("\n") {
    for index, line in text.split("\n") {
      draw_entity_text(
        graphic,
        x,
        y + index.to_double() * metrics.line_height.to_double(),
        line.to_owned(),
        metrics,
        class_name?,
        fill~,
        font_family~,
        font_size~,
        anchor~,
        text_style~,
      )
    }
    return
  }
  let run = entity_text_run(
    text,
    { x, y, },
    metrics,
    font_family~,
    font_size~,
    anchor~,
  )
  graphic
  .with_style({
    ..Default::default(),
    fill: if fill.is_empty() {
      Inherit
    } else {
      Color(fill)
    },
  })
  .draw(text_style.map_or(Text(run), style => StyledText(run, style)), metadata={
    ..Default::default(),
    class_name,
  })
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
  let measured = metrics.entity_measure(text)
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

///|
priv struct EntityTextSize {
  width : Int
  height : Int
  baseline : Int
  ascent : Int
  advance_width : Int
}

///|
fn @metrics.FontMetrics::entity_measure(
  self : @metrics.FontMetrics,
  text : String,
) -> EntityTextSize {
  if state_rich_text(text, self, 0.0, literal_newlines=true) is Some(rich) {
    {
      width: rich.width.ceil().to_int(),
      height: rich.height.ceil().to_int(),
      baseline: self.ascent,
      ascent: self.ascent,
      advance_width: rich.width.ceil().to_int(),
    }
  } else {
    let measured = self.measure(text)
    {
      width: measured.width,
      height: measured.height,
      baseline: measured.baseline,
      ascent: measured.ascent,
      advance_width: measured.advance_width,
    }
  }
}
