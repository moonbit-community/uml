///|
/// The common SVG document scaffold shared by diagram renderers: the root
/// `<svg>` element, the `svg{font-...;background:...}` style rule, and the
/// background rectangle. Renderers paint their content through `writer` and
/// finish with `to_string`, which closes the root element.
pub struct SvgDocument {
  writer : XmlWriter
  width : Int
  height : Int
}

///|
/// The root `<svg>` element attributes shared by every diagram renderer.
///
/// Use `svg_root_attributes` with `XmlWriter::open` (or `SvgDocument::new`);
/// `svg_root_markup` is the string form for renderers that hand-build markup.
/// Do not re-list the xmlns/width/height/viewBox/role attributes locally.
pub fn svg_root_attributes(
  width : Int,
  height : Int,
  view_box : String,
  aria_label : String,
) -> Array[(String, String)] {
  [
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", width.to_string()),
    ("height", height.to_string()),
    ("viewBox", view_box),
    ("role", "img"),
    ("aria-label", aria_label),
  ]
}

///|
/// The opening `<svg>` tag for renderers that hand-build markup.
pub fn svg_root_markup(
  width : Int,
  height : Int,
  view_box : String,
  aria_label : String,
) -> String {
  "<svg" +
  svg_root_attributes(width, height, view_box, aria_label)
  .map(attribute => " \{attribute.0}=\"\{attribute.1}\"")
  .join("") +
  ">"
}

///|
/// The `svg{font-family;font-size;background}` rule shared by the renderers'
/// style blocks. Do not re-interpolate the rule locally.
pub fn svg_style_rule(
  font_family : String,
  font_size : String,
  background : String,
) -> String {
  "svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}"
}

///|
/// The background `<rect>` attributes shared by the renderers that paint a
/// canvas rectangle under their content.
pub fn background_rect_attributes(
  width : Int,
  height : Int,
  fill : String,
  class_name? : String = "",
) -> Array[(String, String)] {
  let class = if class_name.length() > 0 { [("class", class_name)] } else { [] }
  class +
  [
    ("x", "0"),
    ("y", "0"),
    ("width", width.to_string()),
    ("height", height.to_string()),
    ("fill", fill),
  ]
}

///|
/// The background `<rect>` markup for renderers that hand-build markup.
pub fn background_rect_markup(
  width : Int,
  height : Int,
  fill : String,
  class_name? : String = "",
) -> String {
  "<rect" +
  background_rect_attributes(width, height, fill, class_name~)
  .map(attribute => " \{attribute.0}=\"\{attribute.1}\"")
  .join("") +
  "/>"
}

///|
/// The closing `</svg>` tag with a trailing newline, for renderers that
/// hand-build markup.
pub fn svg_close_markup() -> String {
  "</svg>\n"
}

///|
pub fn SvgDocument::new(
  width : Int,
  height : Int,
  aria_label : String,
  background : String,
  font_family : String,
  font_size : String,
  css? : String = "",
) -> SvgDocument {
  let writer = XmlWriter::new()
  writer.open(
    "svg",
    attributes=svg_root_attributes(
      width,
      height,
      "0 0 \{width} \{height}",
      aria_label,
    ),
  )
  writer.open("style")
  writer.raw(svg_style_rule(font_family, font_size, background) + css)
  writer.close()
  writer.empty(
    "rect",
    attributes=background_rect_attributes(width, height, background),
  )
  { writer, width, height, }
}

///|
/// The underlying writer for painting diagram content between construction
/// and `to_string`.
pub fn SvgDocument::writer(self : SvgDocument) -> XmlWriter {
  self.writer
}

///|
/// Close the root element and return the serialized SVG document.
pub fn SvgDocument::to_string(self : SvgDocument) -> String {
  self.writer.close()
  self.writer.to_string()
}
