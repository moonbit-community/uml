///|
fn sequence_arrow_hidden(config : @seq.ArrowConfig) -> Bool {
  config.line_style.map_or(false, style => {
    style.contains(Hidden)
  })
}

///|
fn sequence_arrow_drawing(
  output : SequenceDrawing,
  config : @seq.ArrowConfig,
  defaults : @style.SequenceColors,
) -> SequenceDrawing {
  let mut style = @svg.parsed_line_drawing_style(config.line_style)
  for token in config.line_style.unwrap_or([]) {
    if token is Color(color) && color.has_prefix("#") {
      style = {
        ..style,
        stroke: Color(@svg.svg_color(Some(color), defaults.line)),
      }
    }
  }
  { ..output, line_style: { ..style, inline: true, }, }
}
