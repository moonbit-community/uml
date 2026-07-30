///|
fn Char::is_emoji(char : Char) -> Bool {
  match char {
    '\u{2600}'..='\u{27bf}' => true
    '\u{1f000}'..='\u{1faff}' => true
    _ => false
  }
}

///|
fn Char::is_zero_width(char : Char) -> Bool {
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
fn Char::is_wide(char : Char) -> Bool {
  match char {
    '\u{1100}'..='\u{11ff}'
    | '\u{2e80}'..='\u{9fff}'
    | '\u{a000}'..='\u{a4cf}'
    | '\u{ac00}'..='\u{d7af}'
    | '\u{f900}'..='\u{faff}'
    | '\u{fe10}'..='\u{fe6f}'
    | '\u{ff01}'..='\u{ff60}'
    | '\u{ffe0}'..='\u{ffe6}'
    | '\u{1b000}'..='\u{1b12f}'
    | '\u{20000}'..='\u{2fa1f}'
    | '\u{30000}'..='\u{3134f}' => true
    _ => false
  }
}
