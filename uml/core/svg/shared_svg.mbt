///|
/// Serialize graphviz spline points as an SVG path `d` string, using the
/// 3n+1 cubic Bezier form emitted by dot.
pub fn spline_path_data(points : Array[(Double, Double)]) -> String {
  guard points.length() > 0 else { return "" }
  let output = StringBuilder()
  output.write_string("M ")
  output.write_string(points[0].0.to_string())
  output.write_string(" ")
  output.write_string(points[0].1.to_string())
  if (points.length() - 1) % 3 == 0 {
    let mut index = 1
    while index < points.length() {
      output.write_string(" C ")
      for offset in 0..<3 {
        let point = points[index + offset]
        output.write_string(point.0.to_string())
        output.write_string(" ")
        output.write_string(point.1.to_string())
        if offset < 2 {
          output.write_string(" ")
        }
      }
      index += 3
    }
  } else {
    for index in 1..<points.length() {
      let point = points[index]
      output.write_string(" L ")
      output.write_string(point.0.to_string())
      output.write_string(" ")
      output.write_string(point.1.to_string())
    }
  }
  output.to_string()
}

///|
/// The shared PlantUML border width used by node, relation, endpoint, and
/// reference outlines across diagram families.
const STANDARD_BORDER_STROKE_WIDTH : String = "1.2"

///|
pub fn standard_border_stroke_width() -> String {
  STANDARD_BORDER_STROKE_WIDTH
}

///|
/// The emphasized outline width shared by primary edges and arrows.
const EMPHASIZED_STROKE_WIDTH : String = "1.5"

///|
pub fn emphasized_stroke_width() -> String {
  EMPHASIZED_STROKE_WIDTH
}

///|
/// The dash pattern used by structural separators.
const SEPARATOR_DASH_PATTERN : String = "4 3"

///|
pub fn separator_dash_pattern() -> String {
  SEPARATOR_DASH_PATTERN
}

///|
const DASHED_LINE_PATTERN : String = "6 4"

///|
pub fn dashed_line_pattern() -> String {
  DASHED_LINE_PATTERN
}

///|
/// Map a PlantUML line style token to SVG presentation attributes.
pub fn line_style_attributes(line_style : String?) -> Array[(String, String)] {
  match line_style {
    Some("dashed") => [("stroke-dasharray", DASHED_LINE_PATTERN)]
    Some("dotted") => [("stroke-dasharray", "2 3")]
    Some("bold") => [("stroke-width", "2.5")]
    _ => []
  }
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
  default_width? : String = STANDARD_BORDER_STROKE_WIDTH,
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
    ..match path_fill {
      Some(fill) => [" fill=\"\{xml_escape(fill)}\""]
      None => []
    },
    ..match path_class {
      Some(class) => [" class=\"\{xml_escape(class)}\""]
      None => []
    },
  ].join("")
  "<marker id=\"\{id}\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"\{marker_width}\" markerHeight=\"\{marker_height}\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\"\{extra}/></marker>"
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
) -> String {
  let lines = text.split("\n").map(StringView::to_owned).to_array()
  let baseline = match anchor {
    Center => y - (lines.length() - 1).to_double() * line_height / 2.0
    Baseline => y
  }
  let output = StringBuilder()
  output.write_string("<text x=\"\{x}\" y=\"\{baseline}\"")
  for attribute in attributes {
    output.write_string(" \{attribute.0}=\"\{xml_escape(attribute.1)}\"")
  }
  output.write_string(">")
  for index, line in lines {
    let dy = if index == 0 { 0.0 } else { line_height }
    output <+ "<tspan x=\"\{x}\" dy=\"\{dy}\">\{xml_escape(line)}</tspan>"
  }
  output.write_string("</text>")
  output.to_string()
}
