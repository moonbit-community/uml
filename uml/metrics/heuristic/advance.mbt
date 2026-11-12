///|
/// The vendored table uses tenths of a pixel at its reference font size.
const TABLE_FONT_SIZE : Double = 16.0

///|
fn table_width(char : Char) -> Double {
  // U+0020 is zero in the table; NBSP provides its actual space advance.
  let code_point = if char == ' ' { '\u{00a0}'.to_int() } else { char.to_int() }
  guard code_point < 0xFFFF else { return 16.0 }
  let block = code_point >> 8
  guard block < plantuml_sans_serif_widths.length() else { return 13.0 }
  unicode_block_width(plantuml_sans_serif_widths[block], code_point & 0xFF).to_double() /
  10.0
}

///|
/// Blocks are constant, direct lookup, or `(count, value)` RLE pairs.
fn unicode_block_width(widths : Array[Int32], low_byte : Int32) -> Int32 {
  if widths.length() == 1 {
    widths[0]
  } else if widths.length() == 256 {
    widths[low_byte]
  } else {
    for cursor = 0, decoded_index = 0 {
      guard cursor < widths.length() else { break 0 }
      let count = widths[cursor]
      guard low_byte >= decoded_index + count else { break widths[cursor + 1] }
      continue cursor + 2, decoded_index + count
    }
  }
}

///|
fn Font::base_width(self : Font, char : Char) -> Double {
  guard !char.is_zero_width() else { return 0.0 }
  guard self.profile != Monospace else { return 8.0 }
  match char {
    ' ' | '\t' => 4.0
    'i' | 'l' | 'I' | '!' | '|' | '.' | ',' | ':' | ';' | '\'' => 3.0
    'f' | 'j' | 'r' | 't' | '(' | ')' | '[' | ']' => 5.0
    'm' | 'w' | 'M' | 'W' | '@' | '%' => 11.0
    'A'..<='Z' => 8.0
    '1' => 8.5 * 0.8
    '0'..<='9' => 8.5
    _ if char.is_emoji() || char.is_wide() => 14.0
    _ => 7.0
  }
}

///|
fn Font::advance(self : Font, char : Char) -> Double {
  let size = self.spec.font_size.to_double()
  let advance = if self.profile == Sans {
    table_width(char) * size / TABLE_FONT_SIZE
  } else {
    let advance = self.base_width(char) * size / REFERENCE_FONT_SIZE.to_double()
    if self.profile == Serif {
      advance * 1.02
    } else {
      advance
    }
  }
  guard self.profile != Monospace else { return advance }
  let weight_progress = (self.spec.font_weight - 400).clamp(min=0, max=500)
  let weight_scale = 100 + 10 * weight_progress / 300
  let advance = advance * weight_scale.to_double() / 100.0
  match self.spec.style {
    Normal => advance
    Italic => advance * 1.03
  }
}

///|
fn Font::kerning(self : Font, left : Char, right : Char) -> Double {
  guard self.profile == Serif else { return 0.0 }
  let adjustment = match (left, right) {
    ('A', 'V' | 'W' | 'Y') | ('T', 'a' | 'e' | 'o') | ('Y', 'a' | 'o') => -1.0
    ('F' | 'P', 'a' | 'e' | 'o') => -0.5
    _ => 0.0
  }
  adjustment * self.spec.font_size.to_double() / REFERENCE_FONT_SIZE.to_double()
}
