///|
/// DecorateEntityImage centers the previous image within each wrapper, then
/// independently aligns its top and bottom text. Header/footer share a wrapper.
fn wrap_state_document(
  drawing : StateDrawingLayout,
  top : DocumentTextBlock?,
  bottom : DocumentTextBlock?,
) -> StateDrawingLayout {
  guard top is Some(_) || bottom is Some(_) else { return drawing }
  let original = drawing.layout
  let width = original.width
    .max(top.map_or(0.0, block => block.width))
    .max(bottom.map_or(0.0, block => block.width))
  let dx = (width - original.width) / 2.0
  let dy = top.map_or(0.0, block => block.height)
  let bottom_y = dy + original.height
  let document = []
  if top is Some(block) {
    document.push(block.at(width, 0.0))
  }
  for block in drawing.document {
    document.push({ ..block, x: block.x + dx, y: block.y + dy, })
  }
  if bottom is Some(block) {
    document.push(block.at(width, bottom_y))
  }
  {
    layout: {
      width,
      height: bottom_y + bottom.map_or(0.0, block => block.height),
      nodes: original.nodes.map(node => shift_state_node(node, dx, dy)),
      edges: original.edges.map(edge => shift_state_edge(edge, dx, dy)),
      regions: original.regions.map(region => shift_state_region(region, dx, dy)),
      notes: original.notes.map(note => shift_state_note(note, dx, dy)),
    },
    note_connections: drawing.note_connections.map(connection => {
      connection.shift(dx, dy)
    }),
    cluster_titles: Map::from_iter(
      drawing.cluster_titles.iter().map(entry => (entry.0, entry.1 + dy)),
    ),
    document,
  }
}

///|
/// DiagramChromeFactory applies legend, title, caption, then header/footer.
/// Verified before Graphviz 0.1.10: document composition order, independent
/// font roles, ribbon alignment and joint translation of nodes, edges, regions
/// and note contacts when surrounding text widens the image.
fn decorate_state_document(
  diagram : @flow.StateDiagram,
  drawing : StateDrawingLayout,
) -> StateDrawingLayout {
  let style = diagram.style
  let legend = document_text_block(style, "legend", style.legend)
  let legend_top = style.property("documentlegendposition") == Some("top")
  let drawing = wrap_state_document(
    drawing,
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
  let drawing = wrap_state_document(
    drawing,
    document_text_block(style, "title", style.title),
    None,
  )
  let drawing = wrap_state_document(
    drawing,
    None,
    document_text_block(style, "caption", style.caption),
  )
  wrap_state_document(
    drawing,
    document_text_block(style, "header", style.header),
    document_text_block(style, "footer", style.footer),
  )
}
