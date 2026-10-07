///|
fn sequence_arrow_hidden(config : @seq.ArrowConfig) -> Bool {
  config.line_style.map_or(false, style => {
    style
    .split(",")
    .any(token => token.trim().equal_ignore_ascii_case("hidden"))
  })
}

///|
fn sequence_arrow_drawing(
  output : SequenceDrawing,
  config : @seq.ArrowConfig,
  defaults : @style.SequenceColors,
) -> SequenceDrawing {
  let mut style = @svg.line_drawing_style(config.line_style)
  for token in config.line_style.unwrap_or("").split(",") {
    let token = token.trim().to_owned()
    if token.has_prefix("#") {
      style = {
        ..style,
        stroke: Color(@svg.svg_color(Some(token), defaults.line)),
      }
    }
  }
  { ..output, line_style: { ..style, inline: true, }, }
}
