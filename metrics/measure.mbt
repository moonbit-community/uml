///|
/// Measure text with this font profile.
pub fn FontMetrics::measure(self : FontMetrics, text : String) -> TextMetrics {
  let lines = text.split("\n").to_array()
  let measure_line = (line : StringView) => {
    let (_, advance, glyph_count) = line.fold(init=(None, 0.0F, 0), (
      state,
      char,
    ) => {
      let (previous, advance, glyph_count) = state
      let char_advance = if char == '\t' {
        let tab_width = (self.char_advance(' ') * Float::from_int(self.tab_size)).max(
          1.0F,
        )
        tab_width - Float::mod(advance, tab_width)
      } else {
        self.char_advance(char) +
        ({
          guard char != ' ' else {
            Float::from_int(self.word_spacing) * 1000.0F
          }
          0.0
        })
      }
      let pair_adjustment = {
        guard self.profile != Sans else { 0.0F }
        previous.map_or(0.0F, left => self.kerning(left, char))
      }
      let next_previous = {
        guard char_advance > 0.0F else { previous }
        Some(char)
      }
      (
        next_previous,
        advance + char_advance + pair_adjustment,
        glyph_count + (if char_advance > 0.0F { 1 } else { 0 }),
      )
    })
    advance +
    Float::from_int((glyph_count - 1).max(0) * self.letter_spacing) * 1000.0F
  }
  let width_units = lines.fold(init=0.0F, (widest, line) => {
    widest.max(measure_line(line))
  })
  let advance_width = width_units.ceil_pixels()
  let (ink_left, ink_right) = {
    guard self.style is Italic && advance_width > 0 else { (0, 0) }
    (self.italic_overhang, self.italic_overhang)
  }
  {
    width: advance_width + ink_left + ink_right,
    advance_width,
    height: lines.length().max(1) * self.line_height,
    ascent: self.ascent,
    descent: self.descent,
    baseline: self.ascent,
    ink_left,
    ink_right,
  }
}
