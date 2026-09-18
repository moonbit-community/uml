///|
priv struct StateRichSpan {
  text : String
  face : StateFontFace
  size : Int?
  color : String?
  family : String?
  decoration : StateRichDecoration
}

///|
priv struct StateRichLine {
  spans : Array[StateRichSpan]
  width : Double
  height : Double
}

///|
priv struct StateRichText {
  lines : Array[StateRichLine]
  width : Double
  height : Double
  alignment : @graphics.TextAnchor?
}

///|
fn state_rich_escapable(char : Char) -> Bool {
  char is ('_' | '-' | '"' | '#' | ']' | '[' | '*' | '.' | '/' | '<')
}

///|
fn state_rich_end(text : String, closing : String, nonempty~ : Bool) -> Int? {
  let cursor = @tokenizer.Cursor::new(text)
  while !cursor.is_eof() {
    if (!nonempty || cursor.offset() > 0) &&
      cursor.remaining().to_lower().has_prefix(closing) {
      return Some(cursor.offset())
    }
    if cursor.consume_literal("\\~") {
      continue
    }
    guard cursor.advance() is Some(char) else { break }
    if char == '~' && cursor.peek().map_or(false, state_rich_escapable) {
      ignore(cursor.advance())
    }
  }
  None
}

///|
/// CommandCreoleStyle recursively applies a face to its matched body, then
/// restores the outer face. Legacy tags can run to EOL; ** and // need a pair.
/// Faces, decorations, size, color and family preserve the enclosing font
/// configuration across recursive Creole spans.
/// Verified 2026-09-16: nested face restoration, equivalent legacy/Creole
/// syntax, unmatched delimiters, escaped delimiters, and raw spans passed.
fn state_rich_spans(
  text : String,
  face : StateFontFace,
  size? : Int? = None,
  color? : String? = None,
  family? : String? = None,
  decoration? : StateRichDecoration = Default::default(),
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> (Array[StateRichSpan], Bool) {
  let spans = []
  let cursor = @tokenizer.Cursor::new(text)
  let mut pending = ""
  let mut changed = false
  while !cursor.is_eof() {
    if cursor.consume_literal("\\~") {
      pending += "~"
      changed = true
      continue
    }
    if cursor.remaining().has_prefix("~") {
      let start = cursor.offset()
      ignore(cursor.advance())
      if cursor.peek().map_or(false, state_rich_escapable) {
        pending += cursor.advance().unwrap().to_string()
        changed = true
        continue
      }
      ignore(cursor.restore(start))
    }
    let mut raw_end = None
    for
      (open, close) in [
        ("[[", "]]"),
        ("<math>", "</math>"),
        ("<latex>", "</latex>"),
      ] {
      if cursor.remaining().has_prefix(open) {
        raw_end = cursor
          .remaining()
          .find(close)
          .map(index => index + close.length())
      }
    }
    if raw_end is Some(length) {
      pending += cursor.slice(cursor.offset(), cursor.offset() + length)
      ignore(cursor.restore(cursor.offset() + length))
      continue
    }
    if state_rich_decoration_open(cursor.remaining()) is Some(tag) {
      let start = cursor.offset() + tag.length
      let body = cursor.slice(start, text.length())
      let mut ending : (Int, Int)? = None
      for close in tag.closing {
        if state_rich_end(body, close, nonempty=tag.paired) is Some(index) &&
          ending.map_or(true, previous => index < previous.0) {
          ending = Some((index, close.length()))
        }
      }
      let length = ending.map_or(body.length(), end => end.0)
      if length > 0 && (!tag.paired || ending is Some(_)) {
        if !pending.is_empty() {
          spans.push({ text: pending, face, size, color, family, decoration, })
          pending = ""
        }
        let nested_decoration = decoration.add(tag)
        let (nested, _) = state_rich_spans(
          body[:length].to_owned(),
          face,
          size~,
          color~,
          family~,
          decoration=nested_decoration,
          monospaced_family~,
        )
        spans.append(nested)
        ignore(cursor.restore(start + length + ending.map_or(0, end => end.1)))
        changed = true
        continue
      }
    }
    let mut matched = false
    let mono = cursor.remaining().has_prefix("\"\"")
    let font_tag = if mono {
      Some({
        length: 2,
        family: Some(monospaced_family),
        size: None,
        color: None,
      })
    } else {
      state_rich_font_open(cursor.remaining())
    }
    if font_tag is Some(tag) {
      let close = if mono { "\"\"" } else { "</font>" }
      let start = cursor.offset() + tag.length
      let body = cursor.slice(start, text.length())
      let end = state_rich_end(body, close, nonempty=false)
      if !mono || end is Some(_) {
        if !pending.is_empty() {
          spans.push({ text: pending, face, size, color, family, decoration, })
          pending = ""
        }
        let length = end.unwrap_or(body.length())
        let color = tag.color.map_or(color, value => {
          guard state_rich_color(value) is Some(color) else {
            abort("unknown color in rich text font tag: " + value)
          }
          Some(color)
        })
        let (nested, _) = state_rich_spans(
          body[:length].to_owned(),
          face,
          size=tag.size.map_or(size, value => Some(value)),
          color~,
          family=tag.family.map_or(family, value => Some(value)),
          decoration~,
          monospaced_family~,
        )
        spans.append(nested)
        ignore(
          cursor.restore(start + length + end.map_or(0, _ => close.length())),
        )
        changed = true
        continue
      }
    }
    if state_rich_color_open(cursor.remaining()) is Some((length, value)) {
      if !pending.is_empty() {
        spans.push({ text: pending, face, size, color, family, decoration, })
        pending = ""
      }
      let start = cursor.offset() + length
      let body = cursor.slice(start, text.length())
      let end = state_rich_end(body, "</color>", nonempty=false)
      let length = end.unwrap_or(body.length())
      let inherited = if state_rich_color(value) is Some(resolved) {
        Some(resolved)
      } else {
        color
      }
      let (nested, _) = state_rich_spans(
        body[:length].to_owned(),
        face,
        size~,
        color=inherited,
        family~,
        decoration~,
        monospaced_family~,
      )
      spans.append(nested)
      ignore(
        cursor.restore(start + length + end.map_or(0, _ => "</color>".length())),
      )
      changed = true
      continue
    }
    if state_rich_size_open(cursor.remaining()) is Some((length, new_size)) {
      if !pending.is_empty() {
        spans.push({ text: pending, face, size, color, family, decoration, })
        pending = ""
      }
      let start = cursor.offset() + length
      let body = cursor.slice(start, text.length())
      let end = state_rich_end(body, "</size>", nonempty=false)
      let length = end.unwrap_or(body.length())
      let (nested, _) = state_rich_spans(
        body[:length].to_owned(),
        face,
        size=Some(new_size),
        color~,
        family~,
        decoration~,
        monospaced_family~,
      )
      spans.append(nested)
      ignore(
        cursor.restore(start + length + end.map_or(0, _ => "</size>".length())),
      )
      changed = true
      continue
    }
    for
      (open, close, mode, paired) in [
        ("**", "**", "bold", true),
        ("//", "//", "italic", true),
        ("<b>", "</b>", "bold", false),
        ("<i>", "</i>", "italic", false),
        ("<plain>", "</plain>", "plain", false),
      ] {
      guard cursor.remaining().to_lower().has_prefix(open) else { continue }
      let start = cursor.offset() + open.length()
      let body = cursor.slice(start, text.length())
      let end = state_rich_end(body, close, nonempty=paired)
      guard end is Some(_) || !paired else { continue }
      let length = end.unwrap_or(body.length())
      guard length > 0 else { continue }
      if !pending.is_empty() {
        spans.push({ text: pending, face, size, color, family, decoration, })
        pending = ""
      }
      let inner = match mode {
        "bold" => { ..face, weight: STATE_FONT_BOLD_WEIGHT, }
        "italic" => { ..face, style: @metrics.FontStyle::Italic, }
        _ =>
          {
            weight: STATE_FONT_NORMAL_WEIGHT,
            style: @metrics.FontStyle::Normal,
          }
      }
      let (nested, _) = state_rich_spans(
        body[:length].to_owned(),
        inner,
        size~,
        color~,
        family~,
        decoration=if mode == "plain" {
          { ..Default::default(), color: decoration.color, }
        } else {
          decoration
        },
        monospaced_family~,
      )
      spans.append(nested)
      ignore(
        cursor.restore(start + length + end.map_or(0, _ => close.length())),
      )
      changed = true
      matched = true
      break
    }
    if !matched && cursor.advance() is Some(char) {
      pending += char.to_string()
    }
  }
  if !pending.is_empty() {
    spans.push({ text: pending, face, size, color, family, decoration, })
  }
  (spans, changed)
}

///|
/// Splitter.fontSizePattern permits ASCII whitespace or colon before digits
/// and trailing whitespace including NBSP, with case-insensitive tag names.
/// Verified 2026-09-16: case/separators, rejected signed/unit/decimal values,
/// EOL scope, outer-size restoration, nested faces, and escaped opening tags.
fn state_rich_size_open(text : String) -> (Int, Int)? {
  let cursor = @tokenizer.Cursor::new(text.to_lower())
  guard cursor.consume_literal("<size") else { return None }
  let separator = cursor.take_while(char => {
    char == ':' || char == ' ' || char is ('\u0009'..='\u000d')
  })
  guard !separator.is_empty() else { return None }
  let digits = cursor.take_while(char => char.is_ascii_digit())
  guard !digits.is_empty() else { return None }
  let size = @string.parse_int(digits) catch { _ => return None }
  ignore(
    cursor.take_while(char => {
      char == ' ' || char == '\u00a0' || char is ('\u0009'..='\u000d')
    }),
  )
  guard cursor.consume_literal(">") else { return None }
  Some((cursor.offset(), size))
}

///|
/// AtomText reserves a minimum height even for very small or zero-size fonts.
const STATE_RICH_MIN_ATOM_HEIGHT : Double = 10.0

///|
fn StateRichSpan::metrics(
  self : StateRichSpan,
  base : @metrics.FontMetrics,
) -> @metrics.FontMetrics {
  let font = base.with_face(self.face.weight, self.face.style)
  let font = self.family.map_or(font, family => {
    font.with_profile(@style.font_profile_for(family))
  })
  self.size.map_or(font, size => font.with_size(size))
}

///|
/// Sea.doAlign places ordinary text atoms against a common bottom edge.
/// Verified 2026-09-16: mixed sizes align atom bottoms, following lines advance
/// by measured line height, and small/zero fonts retain AtomText's minimum height.
fn state_rich_line(
  spans : Array[StateRichSpan],
  base : @metrics.FontMetrics,
) -> StateRichLine {
  let mut width = 0.0
  let mut height = STATE_RICH_MIN_ATOM_HEIGHT
  for span in spans {
    let metrics = span.metrics(base)
    width += metrics.measure(span.text).width.to_double()
    height = height.max(metrics.line_height.to_double())
  }
  { spans, width, height, }
}

///|
/// Measure the same face-specific atoms that are drawn, preserving their
/// identity through Fission. Line breaks reset the original parsing face.
/// Verified 2026-09-16: uniform inline faces match equivalent role fonts for
/// leaf/compact/composite states, descriptions, notes, and transitions in TB/LR
/// layouts; automatic and explicit styled breaks have identical drawing commands.
/// Size extension verified 2026-09-16: uniform inline sizes match role font
/// settings for states, notes, and transitions, including small fonts; automatic
/// and explicit sized breaks retain identical layout and text drawing commands.
/// Color extension verified 2026-09-16: colors preserve layout across leaf and
/// composite states, notes, and transitions in TB/LR; automatic and explicit
/// colored breaks have identical drawing commands and restore inherited paint.
fn state_rich_text(
  text : String,
  metrics : @metrics.FontMetrics,
  wrap_width : Double,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
  literal_newlines? : Bool = false,
) -> StateRichText? {
  let display = state_display(text, literal_newlines~)
  let face : StateFontFace = {
    weight: metrics.font_weight,
    style: metrics.style,
  }
  let mut changed = metrics.line_height.to_double() < STATE_RICH_MIN_ATOM_HEIGHT
  let lines = []
  for line in display.text.split("\n") {
    let (spans, styled) = state_rich_spans(
      line.to_owned(),
      face,
      monospaced_family~,
    )
    changed = changed || styled
    if spans.is_empty() {
      spans.push({
        text: " ",
        face,
        size: None,
        color: None,
        family: None,
        decoration: Default::default(),
      })
    }
    if wrap_width == 0.0 {
      lines.push(state_rich_line(spans, metrics))
    } else {
      let tokens = []
      for index, span in spans {
        let metrics = span.metrics(metrics)
        tokens.append(
          state_wrap_tokens(span.text, metrics).map(token => {
            ..token,
            source: index,
          }),
        )
      }
      tokens.push({ text: "", kind: Break, width: 0.0, source: 0, })
      for line in state_wrap_split(tokens, wrap_width.abs()) {
        lines.push(
          state_rich_line(
            line.map(token => { ..spans[token.source], text: token.text, }),
            metrics,
          ),
        )
      }
    }
  }
  guard changed else { return None }
  Some({
    lines,
    width: lines.fold(init=0.0, (width, line) => width.max(line.width)),
    height: lines.fold(init=0.0, (height, line) => height + line.height),
    alignment: display.alignment,
  })
}

///|
/// The role class belongs to the group: explicit run face attributes then
/// override inherited font properties without competing with role CSS rules.
/// Verified 2026-09-16: runs keep state/role metadata, calibrated advances, and
/// matching face-specific drawing bounds. Temporary property tests removed.
fn StateRichText::draw(
  self : StateRichText,
  output : @graphics.Graphic,
  x : Double,
  top : Double,
  metrics : @metrics.FontMetrics,
  metadata : @graphics.Metadata,
  anchor : @graphics.TextAnchor,
  line_alignment : @graphics.TextAnchor?,
) -> Unit {
  let left = x - state_text_anchor_offset(anchor, self.width)
  let alignment = self.alignment.unwrap_or(line_alignment.unwrap_or(anchor))
  output.group(metadata, output => {
    let mut line_top = top
    for line in self.lines {
      let mut x = left +
        state_text_anchor_offset(alignment, self.width - line.width)
      for span in line.spans {
        let font = span.metrics(metrics)
        let baseline = line_top +
          line.height -
          font.line_height.to_double().max(STATE_RICH_MIN_ATOM_HEIGHT) +
          font.ascent.to_double()
        let size = font.measure(span.text)
        let decoration = span.decoration
        if decoration.background &&
          decoration.color is Some(color) &&
          parse_state_gradient(color) is Some(_) {
          output
          .with_style({
            ..@graphics.DrawingStyle::default(),
            fill: Color(color),
            stroke: None,
          })
          .draw(
            Rectangle(
              origin={
                x,
                y: baseline -
                size.height.to_double() +
                STATE_RICH_BACKGROUND_OFFSET,
              },
              width=size.width.to_double(),
              height=size.height.to_double(),
              rx=None,
              ry=None,
            ),
            metadata={
              ..metadata,
              class_name: Some("state-richtext-background"),
            },
          )
        }
        output
        .with_style({
          ..@graphics.DrawingStyle::default(),
          fill: span.color.map_or(@graphics.Paint::Inherit, value => {
            Color(value)
          }),
        })
        .draw(
          StyledText(
            {
              text: span.text,
              position: { x, y: baseline, },
              advance: Some(size.advance_width.to_double()),
              anchor: Start,
              font_size: font.font_size.to_double(),
              font_family: span.family,
              strike: false,
            },
            {
              ..@graphics.TextStyle::default(),
              weight: Some(span.face.weight),
              italic: Some(span.face.style == @metrics.FontStyle::Italic),
            },
          ),
          metadata={
            ..metadata,
            class_name: Some("state-richtext-run"),
            data: [
              ..metadata.data,
              ("rich-role", metadata.class_name.unwrap_or("state-label")),
              ("rich-decoration", decoration.css_key()),
              ..if decoration.background {
                decoration.color
                .filter(color => parse_state_gradient(color) is None)
                .map_or([], color => [("rich-background", color)])
              } else {
                []
              },
            ],
          },
        )
        if decoration.color is Some(color) {
          let offsets = []
          if decoration.underline {
            offsets.push(
              font.font_size.to_double() / STATE_RICH_UNDERLINE_DIVISOR,
            )
          }
          if decoration.strike {
            offsets.push(
              -font.font_size.to_double() / STATE_RICH_STRIKE_DIVISOR,
            )
          }
          for offset in offsets {
            output
            .with_style({
              ..@graphics.DrawingStyle::default(),
              fill: None,
              stroke: Color(color),
              stroke_width: Some(
                font.font_size.to_double() /
                STATE_RICH_DECORATION_STROKE_DIVISOR,
              ),
              dash: Some([]),
            })
            .draw(
              Line({ x, y: baseline + offset, }, {
                x: x + size.width.to_double(),
                y: baseline + offset,
              }),
              metadata={
                ..metadata,
                class_name: Some("state-richtext-decoration"),
              },
            )
          }
        }
        x += size.width.to_double()
      }
      line_top += line.height
    }
  })
}

///|
/// CommandCreoleStyle shares one extended color between decorations. A nested
/// colored style therefore also changes existing underline/strike/background.
priv struct StateRichDecoration {
  underline : Bool
  strike : Bool
  wave : Bool
  background : Bool
  color : String?
} derive(Default)

///|
priv enum StateRichDecorationKind {
  Underline
  Strike
  Wave
  Background
}

///|
priv struct StateRichDecorationTag {
  length : Int
  kind : StateRichDecorationKind
  closing : Array[String]
  paired : Bool
  color : String?
}

///|
fn StateRichDecoration::add(
  self : StateRichDecoration,
  tag : StateRichDecorationTag,
) -> StateRichDecoration {
  let color = tag.color.map_or(self.color, color => Some(color))
  match tag.kind {
    Underline => { ..self, underline: true, color, }
    Strike => { ..self, strike: true, color, }
    Wave => { ..self, wave: true, color, }
    Background => { ..self, background: true, color, }
  }
}

///|
/// FontStyle activation patterns permit word colors or full six-digit hex;
/// background alone also permits a two-color gradient. Invalid color names
/// use HColorSet.getColorOrWhite, unlike the <color> command's fallback.
fn state_rich_decoration_open(text : String) -> StateRichDecorationTag? {
  for (marker, kind) in [("__", Underline), ("--", Strike), ("~~", Wave)] {
    if text.has_prefix(marker) {
      return Some({
        length: marker.length(),
        kind,
        closing: [marker],
        paired: true,
        color: None,
      })
    }
  }
  let cursor = @tokenizer.Cursor::new(text)
  guard cursor.consume('<') else { return None }
  let name = cursor.take_while(char => char.is_ascii_alphabetic())
  let kind = match name.to_lower() {
    "u" => Underline
    "w" => Wave
    "back" => Background
    "s" => Strike
    "strike" | "del" if name == name.to_lower() || name == name.to_upper() =>
      Strike
    _ => return None
  }
  let color = if cursor.consume(':') {
    let start = cursor.offset()
    let component = () => {
      if cursor.consume('#') {
        cursor
        .take_while(char => {
          char.is_ascii_digit() || char is ('a'..='f' | 'A'..='F')
        })
        .length() ==
        6
      } else {
        !cursor
        .take_while(char => {
          char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
        })
        .is_empty()
      }
    }
    guard component() else { return None }
    if kind is Background && cursor.peek() is Some('-' | '/' | '\\' | '|') {
      ignore(cursor.advance())
      guard component() else { return None }
    }
    let value = cursor.slice(start, cursor.offset())
    Some(
      if parse_state_gradient(value) is Some(_) {
        value
      } else {
        state_rich_color(value).unwrap_or("#ffffff")
      },
    )
  } else {
    None
  }
  guard cursor.consume('>') else { return None }
  Some({
    length: cursor.offset(),
    kind,
    closing: if kind is Strike {
      ["</s>", "</strike>", "</del>"]
    } else {
      ["</" + name.to_lower() + ">"]
    },
    paired: false,
    color,
  })
}

///|
/// DriverTextSvg emits native SVG decorations without an extended color;
/// colored underline/strike instead become explicit strokes after the text.
fn StateRichDecoration::css_key(self : StateRichDecoration) -> String {
  let underline = if self.underline && self.color is None { "u" } else { "" }
  let strike = if self.strike && self.color is None { "s" } else { "" }
  underline + strike + (if self.wave { "w" } else { "" })
}

///|
/// DriverTextSvg.ExtraLines offsets and stroke width, relative to font size.
const STATE_RICH_UNDERLINE_DIVISOR : Double = 14.0

///|
const STATE_RICH_STRIKE_DIVISOR : Double = 4.0

///|
const STATE_RICH_DECORATION_STROKE_DIVISOR : Double = 28.0

///|
/// DriverTextSvg's gradient background deltaPatch.
const STATE_RICH_BACKGROUND_OFFSET : Double = 2.0
