///|
/// Portable text measurement used by the built-in SVG renderers.
pub struct TextMetrics {
  width : Int
  height : Int
} derive(Eq, Debug)

///|
/// Configurable, deterministic font metrics for SVG layout.
///
/// These values are not a substitute for a platform text-shaping engine. They
/// make layout stable across targets while allowing callers to tune a font's
/// apparent size without changing the renderer.
pub struct FontMetrics {
  font_size : Int
  line_height : Int
  letter_spacing : Int
  space_width : Int
  narrow_width : Int
  normal_width : Int
  wide_width : Int
  uppercase_width : Int
  digit_width : Int
  cjk_width : Int
  emoji_width : Int
} derive(Eq, Debug)

///|
pub fn FontMetrics::default() -> FontMetrics {
  {
    font_size: 13,
    line_height: 15,
    letter_spacing: 0,
    space_width: 4,
    narrow_width: 3,
    normal_width: 7,
    wide_width: 11,
    uppercase_width: 8,
    digit_width: 7,
    cjk_width: 14,
    emoji_width: 14,
  }
}

///|
/// Creates metrics from the built-in table with lightweight tuning knobs.
/// `font_size` scales all hardcoded glyph advances relative to the 13px
/// defaults; `width_scale` applies an additional percentage adjustment.
pub fn FontMetrics::from_defaults(
  font_size? : Int = 13,
  line_height? : Int = 15,
  width_scale? : Int = 100,
  letter_spacing? : Int = 0,
) -> FontMetrics {
  let scale = font_size * width_scale
  let scaled = (width : Int) => (width * scale + 650) / 1300
  {
    font_size,
    line_height,
    letter_spacing,
    space_width: scaled(4),
    narrow_width: scaled(3),
    normal_width: scaled(7),
    wide_width: scaled(11),
    uppercase_width: scaled(8),
    digit_width: scaled(7),
    cjk_width: scaled(14),
    emoji_width: scaled(14),
  }
}

///|
pub fn FontMetrics::char_width(self : FontMetrics, char : Char) -> Int {
  match char {
    '\u{0300}'..='\u{036f}' | '\u{200b}' | '\u{200c}' | '\u{200d}' => 0
    ' ' | '\t' => self.space_width
    'i' | 'l' | 'I' | '!' | '|' | '.' | ',' | ':' | ';' | '\'' =>
      self.narrow_width
    'f' | 'j' | 'r' | 't' | '(' | ')' | '[' | ']' =>
      (self.normal_width + self.narrow_width) / 2
    'm' | 'w' | 'M' | 'W' | '@' | '%' => self.wide_width
    'A'..='Z' => self.uppercase_width
    '0'..='9' => self.digit_width
    '\u{1f000}'..='\u{1faff}' => self.emoji_width
    _ if char.is_ascii() => self.normal_width
    _ => self.cjk_width
  }
}

///|
pub fn text_char_width(char : Char) -> Int {
  FontMetrics::default().char_width(char)
}

///|
pub fn measure_text_with(text : String, metrics : FontMetrics) -> TextMetrics {
  let lines = text.split("\n").to_array()
  let measure_line = (line : StringView) => {
    let (advance, glyph_count) = line.fold(init=(0, 0), (state, char) => {
      let (advance, glyph_count) = state
      let char_width = metrics.char_width(char)
      (advance + char_width, glyph_count + (if char_width > 0 { 1 } else { 0 }))
    })
    advance + (glyph_count - 1).max(0) * metrics.letter_spacing
  }
  let width = lines.fold(init=0, (w, v) => w.max(measure_line(v)))
  { width, height: lines.length().max(1) * metrics.line_height }
}

///|
pub fn measure_text(text : String, line_height? : Int = 15) -> TextMetrics {
  measure_text_with(text, FontMetrics::from_defaults(line_height~))
}
