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
