///|
/// Portable text measurement used by the built-in SVG renderers.
pub struct TextMetrics {
  width : Int
  advance_width : Int
  height : Int
  ascent : Int
  descent : Int
  baseline : Int
  ink_left : Int
  ink_right : Int
} derive(Eq, Debug)

///|
/// Coarse built-in width profiles for deterministic cross-platform layout.
pub(all) enum FontProfile {
  Sans
  Serif
  Monospace
} derive(Eq, Debug)

///|
pub(all) enum FontStyle {
  Normal
  Italic
} derive(Eq, Debug)

///|
/// Configurable, deterministic font metrics for SVG layout.
///
/// Glyph advances are accumulated internally at 1/1000px precision. The
/// public width fields are rounded pixel summaries retained for callers that
/// inspect individual character classes.
pub struct FontMetrics {
  profile : FontProfile
  style : FontStyle
  font_size : Int
  font_weight : Int
  line_height : Int
  ascent : Int
  descent : Int
  line_gap : Int
  letter_spacing : Int
  word_spacing : Int
  tab_size : Int
  kerning_scale : Int
  font_stretch : Int
  italic_width_scale : Int
  italic_overhang : Int
  width_scale : Int
  uppercase_width_scale : Int
  lowercase_width_scale : Int
  digit_width_scale : Int
  punctuation_width_scale : Int
  cjk_width_scale : Int
  bold_width_scale : Int
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
pub impl Default for FontMetrics with fn default() -> FontMetrics {
  FontMetrics::from_defaults()
}

///|
/// Creates deterministic metrics from one of the built-in profiles.
/// Percentage parameters use 100 as their neutral value.
pub fn FontMetrics::from_defaults(
  profile? : FontProfile = Sans,
  style? : FontStyle = Normal,
  font_size? : Int = 13,
  font_weight? : Int = 400,
  line_height? : Int = 0,
  ascent? : Int = 0,
  descent? : Int = 0,
  line_gap? : Int = 0,
  width_scale? : Int = 100,
  uppercase_width_scale? : Int = 108,
  lowercase_width_scale? : Int = 100,
  digit_width_scale? : Int = 93,
  punctuation_width_scale? : Int = 102,
  cjk_width_scale? : Int = 93,
  font_stretch? : Int = 100,
  bold_width_scale? : Int = 110,
  italic_width_scale? : Int = 103,
  italic_overhang? : Int = 1,
  kerning_scale? : Int = 100,
  letter_spacing? : Int = 0,
  word_spacing? : Int = 0,
  tab_size? : Int = 4,
) -> FontMetrics {
  let font_size = font_size.max(1)
  let ascent = if ascent > 0 { ascent } else { font_size * 10 / 13 }
  let descent = if descent > 0 { descent } else { font_size * 3 / 13 }
  let line_gap = if line_gap > 0 { line_gap } else { font_size * 2 / 13 }
  let line_height = if line_height > 0 {
    line_height
  } else {
    ascent + descent + line_gap
  }
  let metrics = {
    profile,
    style,
    font_size,
    font_weight,
    line_height,
    ascent,
    descent,
    line_gap,
    letter_spacing,
    word_spacing,
    tab_size: tab_size.max(1),
    kerning_scale,
    font_stretch,
    italic_width_scale,
    italic_overhang,
    width_scale,
    uppercase_width_scale,
    lowercase_width_scale,
    digit_width_scale,
    punctuation_width_scale,
    cjk_width_scale,
    bold_width_scale,
    space_width: 0,
    narrow_width: 0,
    normal_width: 0,
    wide_width: 0,
    uppercase_width: 0,
    digit_width: 0,
    cjk_width: 0,
    emoji_width: 0,
  }
  {
    ..metrics,
    space_width: metrics.scaled_advance(4, ' ').ceil_pixels(),
    narrow_width: metrics.scaled_advance(3, 'i').ceil_pixels(),
    normal_width: metrics.scaled_advance(7, 'a').ceil_pixels(),
    wide_width: metrics.scaled_advance(11, 'm').ceil_pixels(),
    uppercase_width: metrics.scaled_advance(8, 'A').ceil_pixels(),
    digit_width: metrics.scaled_advance(8, '0').ceil_pixels(),
    cjk_width: metrics.scaled_advance(14, '\u{4e00}').ceil_pixels(),
    emoji_width: metrics.scaled_advance(14, '\u{1f600}').ceil_pixels(),
  }
}

///|
fn Int::ceil_pixels(self : Int) -> Int {
  (self + 999) / 1000
}

///|
fn FontMetrics::profile_scale(self : FontMetrics) -> Int {
  match self.profile {
    Sans => 1000
    Serif => 1020
    Monospace => 1000
  }
}

///|
fn is_zero_width(char : Char) -> Bool {
  match char {
    '\u{0300}'..='\u{036f}'
    | '\u{1ab0}'..='\u{1aff}'
    | '\u{1dc0}'..='\u{1dff}'
    | '\u{200b}'..='\u{200d}'
    | '\u{2060}'
    | '\u{20d0}'..='\u{20ff}'
    | '\u{fe00}'..='\u{fe0f}'
    | '\u{fe20}'..='\u{fe2f}'
    | '\u{e0100}'..='\u{e01ef}' => true
    _ => false
  }
}

///|
fn FontMetrics::scaled_advance(
  self : FontMetrics,
  base_width : Int,
  char : Char,
) -> Int {
  let base_width = match self.profile {
    Monospace => if is_zero_width(char) { 0 } else { 8 }
    _ => base_width
  }
  let weight_progress = (self.font_weight - 400).clamp(min=0, max=500)
  let weight_scale = match self.profile {
    Monospace => 100
    _ => 100 + (self.bold_width_scale - 100) * weight_progress / 300
  }
  let style_scale = match (self.profile, self.style) {
    (Monospace, _) | (_, Normal) => 100
    (_, Italic) => self.italic_width_scale
  }
  let advance = base_width * self.font_size * 1000 / 13
  let advance = advance * self.width_scale / 100
  let advance = advance * self.glyph_width_scale(char) / 100
  let advance = advance * self.font_stretch / 100
  let advance = advance * self.profile_scale() / 1000
  let advance = advance * weight_scale / 100
  advance * style_scale / 100
}

///|
fn FontMetrics::glyph_width_scale(self : FontMetrics, char : Char) -> Int {
  guard self.profile != Monospace else { 100 }
  match char {
    'A'..='Z' => self.uppercase_width_scale
    'a'..='z' => self.lowercase_width_scale
    '0'..='9' => self.digit_width_scale
    ' ' | '\t' => 100
    _ if char.is_ascii() => self.punctuation_width_scale
    '\u{2e80}'..='\u{9fff}'
    | '\u{ac00}'..='\u{d7af}'
    | '\u{f900}'..='\u{faff}' => self.cjk_width_scale
    _ => 100
  }
}

///|
fn base_char_width(char : Char) -> Int {
  guard !is_zero_width(char) else { 0 }
  match char {
    ' ' | '\t' => 4
    'i' | 'l' | 'I' | '!' | '|' | '.' | ',' | ':' | ';' | '\'' => 3
    'f' | 'j' | 'r' | 't' | '(' | ')' | '[' | ']' => 5
    'm' | 'w' | 'M' | 'W' | '@' | '%' => 11
    'A'..='Z' => 8
    '0'..='9' => 8
    '\u{1f000}'..='\u{1faff}' => 14
    _ if char.is_ascii() => 7
    _ => 14
  }
}

///|
fn FontMetrics::char_advance(self : FontMetrics, char : Char) -> Int {
  self.scaled_advance(base_char_width(char), char)
}

///|
pub fn FontMetrics::char_width(self : FontMetrics, char : Char) -> Int {
  self.char_advance(char).ceil_pixels()
}

///|
fn FontMetrics::kerning(self : FontMetrics, left : Char, right : Char) -> Int {
  guard self.profile != Monospace else { 0 }
  let base = match (left, right) {
    ('A', 'V' | 'W' | 'Y') | ('T', 'a' | 'e' | 'o') | ('Y', 'a' | 'o') => -1000
    ('F' | 'P', 'a' | 'e' | 'o') => -500
    _ => 0
  }
  base * self.font_size * self.kerning_scale / (13 * 100)
}

///|
pub fn measure_text_with(text : String, metrics : FontMetrics) -> TextMetrics {
  let lines = text.split("\n").to_array()
  let measure_line = (line : StringView) => {
    let (_, advance, glyph_count) = line.fold(init=(None, 0, 0), (state, char) => {
      let (previous, advance, glyph_count) = state
      let char_advance = if char == '\t' {
        let tab_width = (metrics.char_advance(' ') * metrics.tab_size).max(1)
        tab_width - advance % tab_width
      } else {
        metrics.char_advance(char) +
        (if char == ' ' { metrics.word_spacing * 1000 } else { 0 })
      }
      let pair_adjustment = previous.map_or(0, left => {
        metrics.kerning(left, char)
      })
      let next_previous = if char_advance > 0 { Some(char) } else { previous }
      (
        next_previous,
        advance + char_advance + pair_adjustment,
        glyph_count + (if char_advance > 0 { 1 } else { 0 }),
      )
    })
    advance + (glyph_count - 1).max(0) * metrics.letter_spacing * 1000
  }
  let width_units = lines.fold(init=0, (widest, line) => {
    widest.max(measure_line(line))
  })
  let advance_width = width_units.ceil_pixels()
  let (ink_left, ink_right) = match (metrics.style, advance_width) {
    (Italic, width) if width > 0 =>
      (metrics.italic_overhang, metrics.italic_overhang)
    _ => (0, 0)
  }
  {
    width: advance_width + ink_left + ink_right,
    advance_width,
    height: lines.length().max(1) * metrics.line_height,
    ascent: metrics.ascent,
    descent: metrics.descent,
    baseline: metrics.ascent,
    ink_left,
    ink_right,
  }
}

///|
pub fn measure_text(text : String, line_height? : Int = 15) -> TextMetrics {
  measure_text_with(text, FontMetrics::from_defaults(line_height~))
}
