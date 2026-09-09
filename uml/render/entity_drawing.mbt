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
) -> Unit {
  graphic
  .with_style({
    ..Default::default(),
    fill: if fill.is_empty() {
      Inherit
    } else {
      Color(fill)
    },
  })
  .draw(
    Text(
      entity_text_run(
        text,
        { x, y, },
        metrics,
        font_family~,
        font_size~,
        anchor~,
      ),
    ),
    metadata={ ..Default::default(), class_name, },
  )
}
