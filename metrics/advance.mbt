///|
fn Float::ceil_pixels(self : Float) -> Int {
  (self / 1000.0).ceil().to_int()
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
fn FontMetrics::scaled_advance(
  self : FontMetrics,
  base_width : Float,
  char : Char,
) -> Float {
  let base_width = match self.profile {
    Monospace => if char.is_zero_width() { 0.0F } else { 8.0F }
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
  let advance = base_width * Float::from_int(self.font_size) * 1000.0F / 13.0F
  let advance = advance * Float::from_int(self.width_scale) / 100.0F
  let advance = advance * Float::from_int(self.glyph_width_scale(char)) / 100.0F
  let advance = advance * Float::from_int(self.font_stretch) / 100.0F
  let advance = advance * Float::from_int(self.profile_scale()) / 1000.0F
  let advance = advance * Float::from_int(weight_scale) / 100.0F
  advance * Float::from_int(style_scale) / 100.0
}

///|
/// Return the deterministic PlantUML table advance in fixed-point units.
/// The Java width table is generated at size 16 and stores tenths of a point.
fn FontMetrics::table_advance(self : FontMetrics, char : Char) -> Float? {
  guard self.profile == Sans else { None }
  let code_point = char.to_int()
  guard code_point < 0xFFFF else { Some(160.0F) }
  let block = code_point >> 8
  guard block < plantuml_sans_serif_widths.length() else { Some(130.0F) }
  let widths = plantuml_sans_serif_widths[block]
  let value = unicode_block_width(widths, code_point & 0xFF)
  Some(
    Float::from_int(value) * 100.0F * Float::from_int(self.font_size) / 16.0F,
  )
}

///|
/// Match PlantUML's UnicodeBlock representation: one-value blocks are
/// constant, full blocks are direct lookup tables, and shorter blocks store
/// `(count, value)` RLE pairs.
fn unicode_block_width(widths : Array[Int], low_byte : Int) -> Int {
  if widths.length() == 1 {
    widths[0]
  } else if widths.length() == 256 {
    widths[low_byte]
  } else {
    for cursor = 0, decoded_index = 0 {
      guard cursor < widths.length() else { break 0 }
      let count = widths[cursor]
      let next_value = widths[cursor + 1]
      guard low_byte < decoded_index + count else {
        continue cursor + 2, decoded_index + count
      }
      break next_value
    }
  }
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
    _ if char.is_emoji() => self.emoji_width_scale
    _ if char.is_wide() => self.wide_width_scale
    _ => 100
  }
}

///|
pub const MONO_DIGIT_BASE_WIDTH : Float = 8.5

///|
fn FontMetrics::digit_base_width(self : FontMetrics, char : Char) -> Float {
  match (self.profile, char) {
    (Sans, '1') => MONO_DIGIT_BASE_WIDTH * 0.6
    (Serif, '1') => MONO_DIGIT_BASE_WIDTH * 0.8
    _ => MONO_DIGIT_BASE_WIDTH
  }
}

///|
fn FontMetrics::base_char_width(self : FontMetrics, char : Char) -> Float {
  guard !char.is_zero_width() else { 0.0 }
  match char {
    ' ' | '\t' => 4.0
    'i' | 'l' | 'I' | '!' | '|' | '.' | ',' | ':' | ';' | '\'' => 3.0
    'f' | 'j' | 'r' | 't' | '(' | ')' | '[' | ']' => 5.0
    'm' | 'w' | 'M' | 'W' | '@' | '%' => 11.0
    'A'..='Z' => 8.0
    '0'..='9' => self.digit_base_width(char)
    _ if char.is_emoji() || char.is_wide() => 14.0
    _ => 7.0
  }
}

///|
fn FontMetrics::char_advance(self : FontMetrics, char : Char) -> Float {
  self
  .table_advance(char)
  .map_or_else(() => self.scaled_advance(self.base_char_width(char), char), advance => {
    let advance = advance * Float::from_int(self.width_scale) / 100.0F
    let advance = advance *
      Float::from_int(self.glyph_width_scale(char)) /
      100.0F
    let advance = advance * Float::from_int(self.font_stretch) / 100.0F
    let weight_progress = (self.font_weight - 400).clamp(min=0, max=500)
    let weight_scale = 100 +
      (self.bold_width_scale - 100) * weight_progress / 300
    let advance = advance * Float::from_int(weight_scale) / 100.0F
    match self.style {
      Normal => advance
      Italic => advance * Float::from_int(self.italic_width_scale) / 100.0F
    }
  })
}

///|
pub fn FontMetrics::char_width(self : FontMetrics, char : Char) -> Int {
  self.char_advance(char).ceil_pixels()
}

///|
fn FontMetrics::kerning(self : FontMetrics, left : Char, right : Char) -> Float {
  guard self.profile != Monospace else { 0.0 }
  let base = match (left, right) {
    ('A', 'V' | 'W' | 'Y') | ('T', 'a' | 'e' | 'o') | ('Y', 'a' | 'o') => -1000
    ('F' | 'P', 'a' | 'e' | 'o') => -500
    _ => 0
  }
  Float::from_int(base * self.font_size * self.kerning_scale) / 1300.0F
}
