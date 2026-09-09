///|
/// Inherit omits a paint declaration; None explicitly disables painting.
/// Color holds an unescaped, resolved color value.
pub(all) enum Paint {
  Inherit
  None
  Color(String)
} derive(Eq, Debug)

///|
pub impl Default for Paint with fn default() -> Paint {
  Inherit
}

///|
/// Explicit drawing state, independent of SVG attribute names or CSS syntax.
/// Absent width/dash values inherit document presentation; an empty dash
/// array explicitly selects a solid stroke.
pub(all) struct DrawingStyle {
  fill : Paint
  stroke : Paint
  stroke_width : Double?
  dash : Array[Double]?
} derive(Eq, Debug, Default)

///|
/// Semantic element identity. Data names are trusted renderer constants,
/// without the `data-` prefix; values are unescaped application text.
pub(all) struct Metadata {
  id : String?
  class_name : String?
  data : Array[(String, String)]
} derive(Eq, Debug, Default)

///|
/// Ordered drawing events consumed immediately by a backend. Translation
/// and style are snapshots of the context at the draw call.
pub(all) enum DrawCommand {
  Draw(Shape, DrawingStyle, Point, Metadata)
  BeginGroup(Metadata)
  EndGroup
  BeginLink(String)
  EndLink
} derive(Eq, Debug)

///|
/// A small UGraphic-like drawing context. Derived contexts share the output
/// sink, but never mutate the parent's translation or style. Commands are
/// emitted synchronously with owned array snapshots, so recording backends
/// can retain them independently of the renderer's working buffers.
pub struct Graphic {
  emit : (DrawCommand) -> Unit
  translation : Point
  style : DrawingStyle
}

///|
/// Connect a drawing context to a backend or a command recorder.
pub fn Graphic::new(emit : (DrawCommand) -> Unit) -> Graphic {
  { emit, translation: Default::default(), style: Default::default(), }
}

///|
/// Compose a local translation without changing the original context.
pub fn Graphic::translated(self : Graphic, x : Double, y : Double) -> Graphic {
  {
    ..self,
    translation: { x: self.translation.x + x, y: self.translation.y + y, },
  }
}

///|
/// Replace the complete local style. Use a struct spread to change selected
/// fields of an existing style; there is no hidden merge or CSS precedence.
pub fn Graphic::with_style(self : Graphic, style : DrawingStyle) -> Graphic {
  { ..self, style: style.snapshot(), }
}

///|
fn DrawingStyle::snapshot(self : DrawingStyle) -> DrawingStyle {
  { ..self, dash: self.dash.map(values => values.copy()), }
}

///|
fn Metadata::snapshot(self : Metadata) -> Metadata {
  { ..self, data: self.data.copy(), }
}

///|
/// Draw a primitive at the current translation, preserving call order.
pub fn Graphic::draw(
  self : Graphic,
  shape : Shape,
  metadata? : Metadata = Default::default(),
) -> Unit {
  let shape = match shape {
    Path(segments) => Shape::Path(segments.copy())
    MarkedPath(segments, markers) => Shape::MarkedPath(segments.copy(), markers)
    Polygon(points) => Shape::Polygon(points.copy())
    TextBlock(block) =>
      Shape::TextBlock({ ..block, lines: block.lines.copy(), })
    StyledTextBlock(block, style) =>
      Shape::StyledTextBlock({ ..block, lines: block.lines.copy(), }, style)
    _ => shape
  }
  (self.emit)(
    Draw(shape, self.style.snapshot(), self.translation, metadata.snapshot()),
  )
}

///|
/// Synchronously draw a balanced semantic group. Contexts used inside the
/// callback retain their own state; the group does not introduce layout.
pub fn Graphic::group(
  self : Graphic,
  metadata : Metadata,
  draw : (Graphic) -> Unit,
) -> Unit {
  (self.emit)(BeginGroup(metadata.snapshot()))
  draw(self)
  (self.emit)(EndGroup)
}

///|
/// Synchronously draw linked content without exposing tag balancing.
pub fn Graphic::link(
  self : Graphic,
  url : String,
  draw : (Graphic) -> Unit,
) -> Unit {
  (self.emit)(BeginLink(url))
  draw(self)
  (self.emit)(EndLink)
}
