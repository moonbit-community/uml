///|
/// DiagramChromeFactory wrappers independent of the diagram's inner geometry.
priv struct DocumentDecoration {
  width : Double
  height : Double
  dx : Double
  dy : Double
  text : Array[DocumentTextBlock]
}

///|
fn DocumentDecoration::wrap(
  self : DocumentDecoration,
  top : DocumentTextBlock?,
  bottom : DocumentTextBlock?,
) -> DocumentDecoration {
  guard top is Some(_) || bottom is Some(_) else { return self }
  let width = self.width
    .max(top.map_or(0.0, block => block.width))
    .max(bottom.map_or(0.0, block => block.width))
  let dx = (width - self.width) / 2.0
  let dy = top.map_or(0.0, block => block.height)
  let bottom_y = dy + self.height
  let text = self.text.map(block => {
    ..block,
    x: block.x + dx,
    y: block.y + dy,
  })
  if top is Some(block) {
    text.push(block.at(width, 0.0))
  }
  if bottom is Some(block) {
    text.push(block.at(width, bottom_y))
  }
  {
    width,
    height: bottom_y + bottom.map_or(0.0, block => block.height),
    dx: self.dx + dx,
    dy: self.dy + dy,
    text,
  }
}

///|
fn decorate_document_text(
  style : @style.DocumentStyle,
  width : Double,
  height : Double,
) -> DocumentDecoration {
  let drawing : DocumentDecoration = {
    width,
    height,
    dx: 0.0,
    dy: 0.0,
    text: [],
  }
  let legend = document_text_block(style, "legend", style.legend)
  let top = style.property("documentlegendposition") == Some("top")
  drawing
  .wrap(if top { legend } else { None }, if top { None } else { legend })
  .wrap(document_text_block(style, "title", style.title), None)
  .wrap(None, document_text_block(style, "caption", style.caption))
  .wrap(
    document_text_block(style, "header", style.header),
    document_text_block(style, "footer", style.footer),
  )
}
