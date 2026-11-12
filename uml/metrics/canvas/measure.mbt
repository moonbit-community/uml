///|
/// Each service owns its context and cache. Call after the required web fonts
/// have loaded; after a font change, render again to rebuild resolved baselines.
pub fn measurer() -> @metrics.Measurer {
  let canvas = new_canvas_measurer()
  @metrics.Measurer::new((font, text) => {
    let style = match font.style {
      Normal => "normal"
      Italic => "italic"
    }
    let css = "\{style} \{font.font_weight} \{font.font_size}px \{font.font_family}"
    let measured = canvas.measure(css, text, font.tab_size)
    let advance = measured.advance()
    let left = measured.left()
    let right = measured.right()
    let bounds = canvas.measure(css, "", font.tab_size)
    {
      width: (advance + left + right).ceil().to_int(),
      advance_width: advance,
      height: text.split("\n").count() * font.line_height,
      ascent: measured.ascent().ceil().to_int(),
      descent: measured.descent().ceil().to_int(),
      baseline: bounds.ascent().ceil().to_int(),
      ink_left: left,
      ink_right: right,
    }
  })
}
