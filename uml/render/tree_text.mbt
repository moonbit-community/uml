///|
pub(all) struct TreeTextSpan {
  text : String
  strike : Bool
}

///|
/// Split one label line into creole `<s>` strike spans, mirroring PlantUML's
/// text run serialization.
pub fn parse_creole_text_line(line : String) -> Array[TreeTextSpan] {
  let lower = line.to_lower()
  let spans = []
  let mut cursor = 0
  let mut strike = false
  while cursor < line.length() {
    let marker = if strike { "</s>" } else { "<s>" }
    let rest = lower[cursor:].to_owned()
    match rest.find(marker) {
      Some(relative_index) => {
        let index = cursor + relative_index
        if index > cursor {
          spans.push({ text: line[cursor:index].to_owned(), strike, })
        }
        cursor = index + marker.length()
        strike = !strike
      }
      None => {
        spans.push({ text: line[cursor:].to_owned(), strike, })
        cursor = line.length()
      }
    }
  }
  if spans.is_empty() {
    spans.push({ text: "", strike: false, })
  }
  spans
}

///|
/// The visible label with creole markers stripped, keeping the line structure.
pub fn tree_visible_text(label : String) -> String {
  label
  .split("\n")
  .map(line => {
    parse_creole_text_line(line.to_owned()).map(span => span.text).join("")
  })
  .join("\n")
}

///|
/// PlantUML's real-font string bounder counts the space glyph, but the
/// vendored width table stores zero for it (faithful to PlantUML's own
/// table). Tree diagrams add the reference space advance back: 4.43px at
/// font size 14, derived from the reference SVGs.
pub const PLANTUML_SPACE_ADVANCE_PER_14 : Int = 443

///|
/// The width table measures a few percent narrower than PlantUML's real
/// font. Tree diagrams scale the measured advance only, leaving the line
/// heights untouched.
pub const PLANTUML_WIDTH_SCALE : Int = 110

///|
pub fn plantuml_space_advance(font_size : Int) -> Int {
  font_size * PLANTUML_SPACE_ADVANCE_PER_14 / 14 / 100
}

///|
pub fn plantuml_measure(
  metrics : @metrics.FontMetrics,
  text : String,
) -> @metrics.TextMetrics {
  let measured = metrics.measure(text)
  let spaces = text.split(" ").to_array().length() - 1
  let extra = measured.advance_width * (PLANTUML_WIDTH_SCALE - 100) / 100 +
    spaces * plantuml_space_advance(metrics.font_size)
  if extra > 0 {
    measured.with_extra_advance(extra)
  } else {
    measured
  }
}

///|
/// Measure a tree label with the PlantUML width compensation, after stripping
/// creole markers.
pub fn tree_label_metrics(
  metrics : @metrics.FontMetrics,
  label : String,
) -> @metrics.TextMetrics {
  plantuml_measure(metrics, tree_visible_text(label))
}

///|
/// Width of a tree label. PlantUML's multi-line labels carry a leading space
/// on their first line (visible in the reference SVGs); it widens the box
/// and offsets the first line of text.
pub fn tree_label_width(
  metrics : @metrics.FontMetrics,
  font_size : Int,
  label : String,
) -> Int {
  let visible = tree_visible_text(label)
  let lines = visible.split("\n").to_array()
  if lines.length() > 1 {
    let space = plantuml_space_advance(font_size)
    let first = plantuml_measure(metrics, lines[0].to_owned()).width + space
    let rest = plantuml_measure(metrics, lines[1:].join("\n")).width
    first.max(rest)
  } else {
    plantuml_measure(metrics, visible).width
  }
}

///|
fn split_whitespace(value : String) -> (String, String, String) {
  let length = value.length()
  let mut start = 0
  while start < length && value[start] == ' ' {
    start = start + 1
  }
  let mut end = length
  while end > start && value[end - 1] == ' ' {
    end = end - 1
  }
  (
    value[start:end].to_owned(),
    value[:start].to_owned(),
    value[end:].to_owned(),
  )
}

///|
/// Render one label as a run of `<text>` elements, each pinned to its
/// measured advance. PlantUML emits one `<text>` per markup span; the
/// whitespace between spans is measured but not drawn. The first line of a
/// multi-line label carries an extra leading space (visible in the reference
/// SVGs).
pub fn append_tree_text(
  output : @svg.XmlWriter,
  x : Int,
  y : Int,
  label : String,
  line_height : Int,
  anchor : String,
  fill : String,
  font_size : Int,
  text_metrics : @metrics.FontMetrics,
  class_name : String,
) -> Unit {
  let lines = label.split("\n").to_array()
  let space = plantuml_space_advance(font_size)
  let first_line_extra = if lines.length() > 1 { space } else { 0 }
  lines.eachi((line_index, line) => {
    let spans = parse_creole_text_line(line.to_owned())
    let mut cursor_x = x + (if line_index == 0 { first_line_extra } else { 0 })
    let mut pending_ws = 0
    for span_index, span in spans {
      let (text, leading, trailing) = split_whitespace(span.text)
      if span_index > 0 {
        cursor_x += pending_ws +
          plantuml_measure(text_metrics, leading).advance_width
      }
      if !text.is_empty() {
        let measured = plantuml_measure(text_metrics, text)
        let attributes = [
          ("x", cursor_x.to_string()),
          ("y", (y + line_index * line_height).to_string()),
          ("text-anchor", anchor),
          ("fill", fill),
          ("font-size", font_size.to_string() + "px"),
          ("class", class_name),
          ..if measured.advance_width > 0 {
            [
              ("textLength", measured.advance_width.to_string()),
              ("lengthAdjust", "spacing"),
            ]
          },
          ..if span.strike {
            [("text-decoration", "line-through")]
          },
        ]
        output.text("text", text, attributes~)
        cursor_x += measured.advance_width
      }
      pending_ws = plantuml_measure(text_metrics, trailing).advance_width
    }
  })
}
