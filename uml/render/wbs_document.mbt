///|
priv struct WbsDocumentLayout {
  tree : WbsLayout
  text : Array[DocumentTextBlock]
}

///|
/// Apply the shared DiagramChromeFactory wrappers to WBS geometry.
fn wbs_document(
  style : @style.DocumentStyle,
  tree : WbsLayout,
) -> WbsDocumentLayout {
  let decoration = decorate_document_text(style, tree.width, tree.height)
  let dx = decoration.dx
  let dy = decoration.dy
  {
    tree: {
      nodes: tree.nodes.map(node => { ..node, x: node.x + dx, y: node.y + dy, }),
      lines: tree.lines.map(line => {
        ..line,
        start: { x: line.start.x + dx, y: line.start.y + dy, },
        end: { x: line.end.x + dx, y: line.end.y + dy, },
      }),
      width: decoration.width,
      height: decoration.height,
    },
    text: decoration.text,
  }
}
