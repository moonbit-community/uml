///|
priv enum StateWrapKind {
  Word
  Space
  Cjk
  Break
} derive(Eq)

///|
priv struct StateWrapToken {
  text : String
  kind : StateWrapKind
  width : Double
  source : Int
}

///|
/// LineBreakStrategy accepts only signed integers; Fission uses their absolute
/// width. A transition uses the message setting unless WrapWidth is positive.
/// Verified 2026-09-16: signed widths, rejected units/decimals, and message
/// fallback precedence passed temporary tests, removed after verification.
fn state_wrap_value(value : String) -> Double {
  let digits = if value.has_prefix("-") { value[1:] } else { value[:] }
  guard !digits.is_empty() && digits.iter().all(char => char.is_ascii_digit()) else {
    return 0.0
  }
  @string.parse_double(value) catch {
    _ => 0.0
  }
}

///|
fn state_wrap_width(
  style : @style.DocumentStyle,
  state? : @flow.StateNode? = None,
) -> Double {
  let value = state.map_or_else(() => style.property("WrapWidth"), state => {
    state_style_property(state, style, "WrapWidth")
  })
  value.map_or(0.0, state_wrap_value)
}

///|
fn state_transition_wrap_width(style : @style.DocumentStyle) -> Double {
  let width = state_wrap_width(style)
  guard width <= 0.0 else { return width }
  let value = style
    .property("WrapMessageWidth")
    .unwrap_or_else(() => style.property("MaxMessageSize").unwrap_or(""))
  state_wrap_value(value)
}

///|
/// Character.isWhitespace excludes nonbreaking spaces. Neutron treats the
/// listed CJK/Japanese ranges as individual breakable characters.
fn state_wrap_kind(char : Char) -> StateWrapKind {
  if char is ('\u0009'..='\u000d') ||
    char is ('\u001c'..='\u0020') ||
    char == '\u1680' ||
    char is ('\u2000'..='\u2006') ||
    char is ('\u2008'..='\u200a') ||
    char is ('\u2028'..='\u2029') ||
    char == '\u205f' ||
    char == '\u3000' {
    Space
  } else if char is ('\u4e00'..='\u9fff') ||
    char is ('\u3040'..='\u30ff') ||
    char is ('\u3000'..='\u303f') ||
    char is ('\uff65'..='\uff9f') {
    Cjk
  } else {
    Word
  }
}

///|
/// AtomText surrounds whitespace and each CJK atom with zero-width breaks.
fn state_wrap_tokens(
  text : String,
  metrics : @metrics.FontMetrics,
) -> Array[StateWrapToken] {
  let tokens = []
  let separator : StateWrapToken = {
    text: "",
    kind: Break,
    width: 0.0,
    source: 0,
  }
  let emit = (text : String, kind : StateWrapKind) => {
    if kind != Word {
      tokens.push(separator)
    }
    tokens.push({
      text,
      kind,
      width: metrics.measure(text).width.to_double(),
      source: 0,
    })
    if kind != Word {
      tokens.push(separator)
    }
  }
  let mut pending = ""
  let mut kind = Word
  for char in text.iter() {
    let current = state_wrap_kind(char)
    if !pending.is_empty() && (current != kind || kind == Cjk) {
      emit(pending, kind)
      pending = ""
    }
    pending += char.to_string()
    kind = current
  }
  if !pending.is_empty() {
    emit(pending, kind)
  }
  tokens
}

///|
/// Fission shortens an overflowing line at its last separator, replaying that
/// suffix on the next line. An unbreakable word is allowed to exceed the limit.
/// Verified 2026-09-16: whole words, oversized words, whitespace trimming,
/// nonbreaking spaces, Chinese/Japanese boundaries, and signed width behavior.
fn state_wrap_line(
  text : String,
  metrics : @metrics.FontMetrics,
  limit : Double,
) -> String {
  let tokens = state_wrap_tokens(text, metrics)
  tokens.push({ text: "", kind: Break, width: 0.0, source: 0, })
  state_wrap_split(tokens, limit)
  .map(line => line.map(token => token.text).join(""))
  .join("\n")
}

///|
/// Keep atom identity while performing Fission so wrapped rich text retains
/// the font used to measure each atom.
/// Verified 2026-09-16: styled atoms survive wrapping, adjacent face changes
/// do not split an unbreakable word, and plain word/CJK/space behavior is retained.
fn state_wrap_split(
  tokens : Array[StateWrapToken],
  limit : Double,
) -> Array[Array[StateWrapToken]] {
  let lines : Array[(Array[StateWrapToken], Bool)] = []
  let finish = (line : Array[Int]) => {
    let mut start = 0
    let mut end = line.length()
    while start < end && tokens[line[start]].kind == Break {
      start += 1
    }
    while end > start + 1 && tokens[line[end - 1]].kind is (Space | Break) {
      end -= 1
    }
    let content = []
    let mut white = true
    for i = start; i < end; i = i + 1 {
      let token = tokens[line[i]]
      if token.kind != Break {
        content.push(token)
      }
      if token.kind is (Word | Cjk) {
        white = false
      }
    }
    lines.push((content, white))
  }
  let mut line : Array[Int] = []
  let mut width = 0.0
  let mut cursor = 0
  while cursor < tokens.length() {
    let token = tokens[cursor]
    if token.kind == Break && width > limit {
      let mut boundary = line.length() - 1
      while boundary >= 0 && tokens[line[boundary]].kind != Break {
        boundary -= 1
      }
      if boundary >= 0 {
        cursor = line[boundary]
        while line.length() > boundary {
          ignore(line.pop())
        }
      }
      finish(line)
      line = []
      width = 0.0
      continue
    }
    let skip = (
        token.kind == Break &&
        (
          line.is_empty() ||
          line.last().map_or(false, index => tokens[index].kind == Break)
        )
      ) ||
      (token.kind == Space && line.is_empty() && !lines.is_empty())
    if !skip {
      line.push(cursor)
      width += token.width
    }
    cursor += 1
  }
  finish(line)
  while lines.length() > 1 && lines.last().map_or(false, line => line.1) {
    ignore(lines.pop())
  }
  lines.map(line => line.0)
}

///|
/// Decode before wrapping so literal backslashes are not interpreted twice;
/// retain the display's natural alignment across all generated lines.
/// Verified 2026-09-16: automatic/explicit breaks produce identical layout and
/// draw commands for expanded/compact states, descriptions, entity/link notes,
/// and transition labels in TB/LR graphs, retaining routed contacts. Composite
/// titles/descriptions remain unwrapped; leaf stereotype widths are independent.
fn StateDisplay::wrap(
  self : StateDisplay,
  metrics : @metrics.FontMetrics,
  width : Double,
) -> StateDisplay {
  guard width != 0.0 else { return self }
  {
    ..self,
    text: self.text
    .split("\n")
    .map(line => state_wrap_line(line.to_owned(), metrics, width.abs()))
    .join("\n"),
  }
}
