///|
/// Portable text measurement used by the built-in SVG renderers.
pub struct TextMetrics {
  width : Int
  height : Int
} derive(Eq, Debug)

///|
pub fn text_char_width(char : Char) -> Int {
  match char {
    ' ' | '\t' => 4
    'i' | 'l' | 'I' | '!' | '|' | '.' | ',' | ':' | ';' | '\'' => 3
    'f' | 'j' | 'r' | 't' | '(' | ')' | '[' | ']' => 5
    'm' | 'w' | 'M' | 'W' | '@' | '%' => 11
    'A'..='Z' => 8
    '0'..='9' => 7
    _ if char.is_ascii() => 7
    _ => 14
  }
}

///|
pub fn measure_text(text : String, line_height? : Int = 15) -> TextMetrics {
  let lines = text.split("\n").to_array()
  let mut width = 0
  for line in lines {
    let mut line_width = 0
    for char in line {
      line_width = line_width + text_char_width(char)
    }
    width = width.max(line_width)
  }
  { width, height: lines.length().max(1) * line_height }
}
