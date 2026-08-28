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
  writer.open("svg", attributes=[
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", width.to_string()),
    ("height", height.to_string()),
    ("viewBox", "0 0 \{width} \{height}"),
    ("role", "img"),
    ("aria-label", aria_label),
  ])
  writer.open("style")
  writer.raw(
    "svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}\{css}",
  )
  writer.close()
  writer.empty("rect", attributes=[
    ("x", "0"),
    ("y", "0"),
    ("width", width.to_string()),
    ("height", height.to_string()),
    ("fill", background),
  ])
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
