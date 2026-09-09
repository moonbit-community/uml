///|
/// Serialize graphviz spline points as an SVG path `d` string, using the
/// 3n+1 cubic Bezier form emitted by dot.
pub fn spline_path_data(points : Array[(Double, Double)]) -> String {
  path_data(@graphics.spline_segments(points))
}

///|
/// The shared PlantUML border width used by node, relation, endpoint, and
/// reference outlines across diagram families.
pub const STANDARD_BORDER_WIDTH : Double = 1.2

///|
pub fn standard_border_stroke_width() -> String {
  STANDARD_BORDER_WIDTH.to_string()
}

///|
/// The emphasized outline width shared by primary edges and arrows.
pub const EMPHASIZED_STROKE_WIDTH : Double = 1.5

///|
pub fn emphasized_stroke_width() -> String {
  EMPHASIZED_STROKE_WIDTH.to_string()
}

///|
/// The width for secondary diagram structures such as participant icons,
/// enclosing boxes, and group frames.
const SECONDARY_STRUCTURE_STROKE_WIDTH : String = "1.1"

///|
pub fn secondary_structure_stroke_width() -> String {
  SECONDARY_STRUCTURE_STROKE_WIDTH
}

///|
/// The size used for auxiliary labels that annotate a diagram rather than a
/// primary node.
const AUXILIARY_LABEL_FONT_SIZE : String = "12px"

///|
pub fn auxiliary_label_font_size() -> String {
  AUXILIARY_LABEL_FONT_SIZE
}

///|
/// The dash pattern used by structural separators.
const SEPARATOR_DASH_PATTERN : String = "4 3"

///|
pub fn separator_dash_pattern() -> String {
  SEPARATOR_DASH_PATTERN
}

///|
const DASHED_LINE_LENGTH : Double = 6.0

///|
const DASHED_LINE_GAP : Double = 4.0

///|
pub fn dashed_line_pattern() -> String {
  "\{DASHED_LINE_LENGTH} \{DASHED_LINE_GAP}"
}

///|
const DOTTED_LINE_LENGTH : Double = 2.0

///|
const DOTTED_LINE_GAP : Double = 3.0

///|
pub fn dotted_line_pattern() -> String {
  "\{DOTTED_LINE_LENGTH} \{DOTTED_LINE_GAP}"
}

///|
/// The dash pattern used by sequence participant lifelines.
const LIFELINE_DASH_PATTERN : String = "5 5"

///|
pub fn lifeline_dash_pattern() -> String {
  LIFELINE_DASH_PATTERN
}

///|
/// The dash pattern used by dotted sequence messages.
const DOTTED_MESSAGE_DASH_PATTERN : String = "5 4"

///|
pub fn dotted_message_dash_pattern() -> String {
  DOTTED_MESSAGE_DASH_PATTERN
}

///|
/// The dash pattern used by sequence hexagonal notes.
const HEX_NOTE_DASH_PATTERN : String = "2 1"

///|
pub fn hex_note_dash_pattern() -> String {
  HEX_NOTE_DASH_PATTERN
}

///|
/// The dash pattern used by sequence delay separators.
const DELAY_DASH_PATTERN : String = "3 3"

///|
pub fn delay_dash_pattern() -> String {
  DELAY_DASH_PATTERN
}

///|
/// The dash pattern used by sequence page breaks.
const PAGE_BREAK_DASH_PATTERN : String = "8 4"

///|
pub fn page_break_dash_pattern() -> String {
  PAGE_BREAK_DASH_PATTERN
}

///|
/// Map a PlantUML line style token to SVG presentation attributes.
pub fn line_style_attributes(line_style : String?) -> Array[(String, String)] {
  drawing_style_attributes(line_drawing_style(line_style))
}

///|
/// Serialize a line style as SVG presentation attributes (`name="value"`),
/// with a leading space so the result can be spliced into a tag.
pub fn line_style_attributes_markup(line_style : String?) -> String {
  line_style_attributes(line_style)
  .map(attr => " \{attr.0}=\"\{attr.1}\"")
  .join("")
}

///|
/// Serialize a line style as a CSS `style` value, falling back to a default
/// stroke width (empty means no stroke attribute).
pub fn stroke_style(
  line_style : String?,
  default_width? : String = STANDARD_BORDER_WIDTH.to_string(),
) -> String {
  match line_style_attributes(line_style) {
    [(name, value)] => "\{name}:\{value}"
    _ =>
      if default_width.length() == 0 {
        ""
      } else {
        "stroke-width:\{default_width}"
      }
  }
}

///|
/// Serialize the standard PlantUML triangle arrow marker with a 10x10
/// viewBox and auto-start-reverse orientation.
pub fn arrow_marker_markup(
  id : String,
  marker_width~ : Double,
  marker_height~ : Double,
  path_fill? : String,
  path_class? : String,
) -> String {
  let extra = [
    ..path_fill.map_or([], fill => [" fill=\"\{xml_escape(fill)}\""]),
    ..path_class.map_or([], class => [" class=\"\{xml_escape(class)}\""]),
  ].join("")
  "<marker id=\"\{id}\" viewBox=\"0 0 \{ARROW_MARKER_EXTENT} \{ARROW_MARKER_EXTENT}\" refX=\"\{ARROW_MARKER_REFERENCE_X}\" refY=\"\{ARROW_MARKER_MIDDLE}\" markerWidth=\"\{marker_width}\" markerHeight=\"\{marker_height}\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L \{ARROW_MARKER_EXTENT} \{ARROW_MARKER_MIDDLE} L 0 \{ARROW_MARKER_EXTENT} z\"\{extra}/></marker>"
}

///|
/// Vertical reference used to position a multiline SVG text block.
pub(all) enum MultilineTextAnchor {
  Center
  Baseline
}

///|
/// Serialize a multiline `<text>` block: one `<tspan>` per line sharing the
/// `x` attribute, with `dy` line spacing. Attribute values and text content
/// are XML-escaped. `offset` centers the first baseline on `y` when `true`.
pub fn multiline_text_markup(
  x : Double,
  y : Double,
  text : String,
  attributes : Array[(String, String)],
  line_height~ : Double,
  anchor? : MultilineTextAnchor = Center,
  text_metrics? : @metrics.FontMetrics? = None,
) -> String {
  let block = layout_multiline_text(
    x,
    y,
    text,
    line_height~,
    anchor~,
    text_metrics~,
  )
  let output = StringBuilder()
  output.write_string("<text x=\"\{x}\" y=\"\{block.position.y}\"")
  for attribute in attributes {
    output.write_string(" \{attribute.0}=\"\{xml_escape(attribute.1)}\"")
  }
  output.write_string(">")
  for line in block.lines {
    let width_attributes = line.advance.map_or("", advance => {
      " textLength=\"\{advance}\" lengthAdjust=\"spacing\""
    })
    output <+
      "<tspan x=\"\{x}\" dy=\"\{line.dy}\"\{width_attributes}>\{xml_escape(line.text)}</tspan>"
  }
  output.write_string("</text>")
  output.to_string()
}

///|
/// Emit a multiline `<text>` block, appending a trailing newline.
///
/// The renderers that hand-build markup (sequence, structured) share this
/// emit convention; XmlWriter-based renderers instead pass the string from
/// `multiline_text_markup` to `XmlWriter::raw`. Do not re-implement the
/// textLength pinning or the trailing `\n` locally.
pub fn append_text_markup(
  output : StringBuilder,
  x : Double,
  y : Double,
  text : String,
  attributes : Array[(String, String)],
  line_height~ : Double,
  anchor~ : MultilineTextAnchor,
  text_metrics~ : @metrics.FontMetrics?,
) -> Unit {
  output.write_string(
    multiline_text_markup(
      x,
      y,
      text,
      attributes,
      line_height~,
      anchor~,
      text_metrics~,
    ),
  )
  output.write_string("\n")
}

///|
/// Serialize one SVG text node using the same advance used by layout.
pub fn text_markup(
  x : Double,
  y : Double,
  text : String,
  attributes : Array[(String, String)],
  text_metrics : @metrics.FontMetrics,
) -> String {
  let measured = text_metrics.measure(text)
  let output = StringBuilder()
  output.write_string("<text x=\"\{x}\" y=\"\{y}\"")
  for attribute in attributes {
    output.write_string(" \{attribute.0}=\"\{xml_escape(attribute.1)}\"")
  }
  if text.length() > 1 && measured.advance_width > 0 {
    output.write_string(
      " textLength=\"\{measured.advance_width}\" lengthAdjust=\"spacing\"",
    )
  }
  output <+ ">\{xml_escape(text)}</text>"
  output.to_string()
}

///|
/// Resolve line-style tokens to numeric drawing state. Legacy SVG attribute
/// helpers delegate here so both backends use the same stroke constants.
pub fn line_drawing_style(line_style : String?) -> @graphics.DrawingStyle {
  let style = @graphics.DrawingStyle::default()
  match line_style {
    Some("dashed") =>
      { ..style, dash: Some([DASHED_LINE_LENGTH, DASHED_LINE_GAP]), }
    Some("dotted") =>
      { ..style, dash: Some([DOTTED_LINE_LENGTH, DOTTED_LINE_GAP]), }
    Some("bold") => { ..style, stroke_width: Some(2.5), }
    _ => style
  }
}

///|
/// Lay out multiline SVG text once for both typed drawing and legacy markup.
/// Keep the centered first baseline and per-line advance pinning consistent.
pub fn layout_multiline_text(
  x : Double,
  y : Double,
  text : String,
  line_height~ : Double,
  anchor? : MultilineTextAnchor = Center,
  text_anchor? : @graphics.TextAnchor = Start,
  text_metrics? : @metrics.FontMetrics? = None,
) -> @graphics.MultilineText {
  let lines = text.split("\n").map(StringView::to_owned).to_array()
  let baseline = match anchor {
    Center => y - (lines.length() - 1).to_double() * line_height / 2.0
    Baseline => y
  }
  {
    position: { x, y: baseline, },
    anchor: text_anchor,
    lines: lines.mapi((index, text) => {
      let advance = text_metrics.map_or(None, metrics => {
        let measured = metrics.measure(text)
        if text.length() > 1 && measured.advance_width > 0 {
          Some(measured.advance_width.to_double())
        } else {
          None
        }
      })
      { text, dy: if index == 0 { 0.0 } else { line_height }, advance, }
    }),
  }
}
