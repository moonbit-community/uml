///|
fn Font::measure(self : Font, text : String) -> @metrics.TextMetrics {
  let lines = text.split("\n").to_array()
  let advance = lines.fold(init=0.0, (widest, line) => {
    let (_, width) = line.fold(init=(None, 0.0), (state, char) => {
      let (previous, width) = state
      let glyph = self.advance(char)
      let adjustment = previous.map_or(0.0, left => self.kerning(left, char))
      let next_width = if char == '\t' {
        let tab_width = (self.advance(' ') * self.spec.tab_size.to_double()).max(
          1.0,
        )
        ((width / tab_width).floor() + 1.0) * tab_width
      } else {
        width + glyph + adjustment
      }
      (if glyph > 0.0 { Some(char) } else { previous }, next_width)
    })
    widest.max(width)
  })
  let overhang = if self.spec.style is Italic && advance > 0.0 {
    1.0
  } else {
    0.0
  }
  let ascent = self.spec.font_size * 10 / REFERENCE_FONT_SIZE
  {
    width: advance.ceil().to_int() + (overhang * 2.0).to_int(),
    advance_width: advance,
    height: lines.length() * self.spec.line_height,
    ascent,
    descent: self.spec.font_size * 3 / REFERENCE_FONT_SIZE,
    baseline: ascent,
    ink_left: overhang,
    ink_right: overhang,
  }
}
