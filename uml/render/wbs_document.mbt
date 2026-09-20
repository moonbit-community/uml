///|
priv struct WbsDocumentLayout {
  tree : WbsLayout
  text : Array[DocumentTextBlock]
}

///|
fn WbsDocumentLayout::wrap(
  self : WbsDocumentLayout,
  top : DocumentTextBlock?,
  bottom : DocumentTextBlock?,
) -> WbsDocumentLayout {
  guard top is Some(_) || bottom is Some(_) else { return self }
  let original = self.tree
  let width = original.width
    .max(top.map_or(0.0, block => block.width))
    .max(bottom.map_or(0.0, block => block.width))
  let dx = (width - original.width) / 2.0
  let dy = top.map_or(0.0, block => block.height)
  let bottom_y = dy + original.height
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
    tree: {
      nodes: original.nodes.map(node => {
        ..node,
        x: node.x + dx,
        y: node.y + dy,
      }),
      lines: original.lines.map(line => {
        ..line,
        start: { x: line.start.x + dx, y: line.start.y + dy, },
        end: { x: line.end.x + dx, y: line.end.y + dy, },
      }),
      width,
      height: bottom_y + bottom.map_or(0.0, block => block.height),
    },
    text,
  }
}

///|
/// The same DiagramChromeFactory wrapper order used by the other UML families.
fn wbs_document(
  style : @style.DocumentStyle,
  tree : WbsLayout,
) -> WbsDocumentLayout {
  let drawing = { tree, text: [], }
  let legend = document_text_block(style, "legend", style.legend)
  let legend_top = style.property("documentlegendposition") == Some("top")
  drawing
  .wrap(
    if legend_top {
      legend
    } else {
      None
    },
    if legend_top {
      None
    } else {
      legend
    },
  )
  .wrap(document_text_block(style, "title", style.title), None)
  .wrap(None, document_text_block(style, "caption", style.caption))
  .wrap(
    document_text_block(style, "header", style.header),
    document_text_block(style, "footer", style.footer),
  )
}
