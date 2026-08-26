///|
/// A lightweight streaming XML writer for SVG renderers.
pub struct XmlWriter {
  output : StringBuilder
  open_tags : Array[String]
}

///|
pub fn XmlWriter::new() -> XmlWriter {
  { output: StringBuilder(), open_tags: [] }
}

///|
fn append_attribute(
  output : StringBuilder,
  name : String,
  value : String,
) -> Unit {
  output <+ " \{name}=\"\{xml_escape_attribute(value)}\""
}

///|
fn append_text(output : StringBuilder, value : String) -> Unit {
  output.write_string(xml_escape_text(value))
}

///|
pub fn XmlWriter::open(
  self : XmlWriter,
  name : String,
  attributes? : Array[(String, String)] = [],
) -> Unit {
  self.output <+ "<\{name}"
  for attribute in attributes {
    append_attribute(self.output, attribute.0, attribute.1)
  }
  self.output.write_char('>')
  self.open_tags.push(name)
}

///|
pub fn XmlWriter::empty(
  self : XmlWriter,
  name : String,
  attributes? : Array[(String, String)] = [],
) -> Unit {
  self.output <+ "<\{name}"
  for attribute in attributes {
    append_attribute(self.output, attribute.0, attribute.1)
  }
  self.output.write_string("/>")
}

///|
pub fn XmlWriter::text(
  self : XmlWriter,
  name : String,
  value : String,
  attributes? : Array[(String, String)] = [],
) -> Unit {
  self.open(name, attributes~)
  append_text(self.output, value)
  self.close()
}

///|
/// Append a pre-serialized XML fragment. Callers retain responsibility for
/// escaping and well-formedness of raw markup.
pub fn XmlWriter::raw(self : XmlWriter, markup : String) -> Unit {
  self.output.write_string(markup)
}

///|
pub fn XmlWriter::close(self : XmlWriter) -> Unit {
  guard self.open_tags.pop() is Some(name) else { return }
  self.output <+ "</\{name}>"
}

///|
/// Returns the completed XML document. Renderers must close every opened tag.
pub fn XmlWriter::to_string(self : XmlWriter) -> String {
  self.output.to_string() + "\n"
}

///|
test "XML writer escapes attribute and text contexts" {
  let writer = XmlWriter::new()
  writer.open("svg", attributes=[
    ("aria-label", "A \"quoted\" < diagram & more"),
  ])
  writer.text("text", "A < B & C")
  writer.close()
  let xml = writer.to_string()
  @test.assert_eq(
    xml.contains("aria-label=\"A &quot;quoted&quot; &lt; diagram &amp; more\""),
    true,
  )
  @test.assert_eq(xml.contains(">A &lt; B &amp; C</text>"), true)
}

///|
test "XML writer preserves nested and empty SVG elements" {
  let writer = XmlWriter::new()
  writer.open("svg")
  writer.open("g", attributes=[("class", "node")])
  writer.empty("path", attributes=[("d", "M 0 0")])
  writer.close()
  writer.close()
  let xml = writer.to_string()
  @test.assert_eq(
    xml.contains("<svg><g class=\"node\"><path d=\"M 0 0\"/></g></svg>"),
    true,
  )
}
