///|
/// document styles in plantuml.skin; TextBlockBordered adds one point to
/// its measured size after padding, independently of border visibility.
const STATE_DOCUMENT_SMALL_FONT_SIZE : Int = 10

///|
const STATE_DOCUMENT_BORDER_EXTENT : Double = 1.0

///|
const STATE_DOCUMENT_TITLE_INSET : Double = 5.0

///|
const STATE_DOCUMENT_CAPTION_MARGIN : Double = 1.0

///|
const STATE_DOCUMENT_LEGEND_MARGIN : Double = 12.0

///|
const STATE_DOCUMENT_LEGEND_PADDING : Double = 5.0

///|
const STATE_DOCUMENT_LEGEND_CORNER : Double = 15.0

///|
priv struct StateDocumentBlock {
  kind : String
  text : String
  role : StateFontRole
  x : Double
  y : Double
  width : Double
  height : Double
  margin : Double
  padding : Double
  alignment : @graphics.TextAnchor
}

///|
fn state_document_alignment(
  style : @style.DocumentStyle,
  kind : String,
) -> @graphics.TextAnchor {
  let fallback = if kind == "header" { "right" } else { "center" }
  match style.property("document" + kind + "alignment").unwrap_or(fallback) {
    "left" => Start
    "right" => End
    _ => Middle
  }
}

///|
fn state_document_block(
  style : @style.DocumentStyle,
  kind : String,
  text : String?,
) -> StateDocumentBlock? {
  guard text is Some(text) else { return None }
  let (role, margin, padding) = match kind {
    "title" =>
      (TitleLabel, STATE_DOCUMENT_TITLE_INSET, STATE_DOCUMENT_TITLE_INSET)
    "caption" => (CaptionLabel, STATE_DOCUMENT_CAPTION_MARGIN, 0.0)
    "header" => (HeaderLabel, 0.0, 0.0)
    "footer" => (FooterLabel, 0.0, 0.0)
    "legend" =>
      (LegendLabel, STATE_DOCUMENT_LEGEND_MARGIN, STATE_DOCUMENT_LEGEND_PADDING)
    _ => return None
  }
  let (width, height) = state_text_size(
    text,
    resolve_state_font(style, role).metrics,
    monospaced_family=state_monospaced_family(style),
  )
  let extra = (margin + padding) * 2.0 + STATE_DOCUMENT_BORDER_EXTENT
  Some({
    kind,
    text,
    role,
    x: 0.0,
    y: 0.0,
    width: width + extra,
    height: height + extra,
    margin,
    padding,
    alignment: state_document_alignment(style, kind),
  })
}

///|
fn StateDocumentBlock::at(
  self : StateDocumentBlock,
  width : Double,
  y : Double,
) -> StateDocumentBlock {
  let x = match self.alignment {
    Start => 0.0
    Middle => (width - self.width) / 2.0
    End => width - self.width
  }
  { ..self, x, y, }
}

///|
/// DecorateEntityImage centers the previous image within each wrapper, then
/// independently aligns its top and bottom text. Header/footer share a wrapper.
fn wrap_state_document(
  drawing : StateDrawingLayout,
  top : StateDocumentBlock?,
  bottom : StateDocumentBlock?,
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
  let legend = state_document_block(style, "legend", style.legend)
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
    state_document_block(style, "title", style.title),
    None,
  )
  let drawing = wrap_state_document(
    drawing,
    None,
    state_document_block(style, "caption", style.caption),
  )
  wrap_state_document(
    drawing,
    state_document_block(style, "header", style.header),
    state_document_block(style, "footer", style.footer),
  )
}

///|
fn state_document_number(
  style : @style.DocumentStyle,
  key : String,
  fallback : Double,
) -> Double {
  guard style.property(key) is Some(value) else { return fallback }
  @string.parse_double(value) catch {
    _ => fallback
  }
}

///|
fn append_state_document(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  blocks : Array[StateDocumentBlock],
) -> Unit {
  for block in blocks {
    let style = diagram.style
    let legend = block.kind == "legend"
    let fill = style.property_color(
      block.kind + "BackgroundColor",
      if legend {
        "#DDDDDD"
      } else {
        "none"
      },
    )
    let stroke = style.property_color(
      block.kind + "BorderColor",
      if legend {
        "#000000"
      } else {
        "none"
      },
    )
    let border = state_document_number(
      style,
      block.kind + "BorderThickness",
      STATE_DOCUMENT_BORDER_EXTENT,
    )
    let corner = state_document_number(
      style,
      block.kind + "BorderRoundCorner",
      if legend {
        STATE_DOCUMENT_LEGEND_CORNER
      } else {
        0.0
      },
    )
    let x = block.x + block.margin
    let y = block.y + block.margin
    let width = block.width - block.margin * 2.0 - STATE_DOCUMENT_BORDER_EXTENT
    let height = block.height -
      block.margin * 2.0 -
      STATE_DOCUMENT_BORDER_EXTENT
    if fill != "none" || stroke != "none" {
      output
      .with_style(state_paint(Color(fill), Color(stroke), border))
      .draw(
        Rectangle(
          origin={ x, y, },
          width~,
          height~,
          rx=Some(corner / 2.0),
          ry=Some(corner / 2.0),
        ),
        metadata=state_class("state-" + block.kind + "-border"),
      )
    }
    // Positioning the whole ribbon does not change its internal text style:
    // header text is right-aligned, legend left-aligned, other text centered.
    let default_alignment = match block.kind {
      "header" => "right"
      "legend" => "left"
      _ => "center"
    }
    let alignment = style
      .property("DefaultTextAlignment")
      .map(value => value.to_lower())
      .unwrap_or(default_alignment)
    let (text_x, anchor) = match alignment {
      "right" => (x + width - block.padding, @graphics.TextAnchor::End)
      "left" => (x + block.padding, @graphics.TextAnchor::Start)
      _ => (x + width / 2.0, @graphics.TextAnchor::Middle)
    }
    append_state_text_at_top(
      output,
      block.text,
      text_x,
      y + block.padding,
      "state-" + block.kind + "-label",
      resolve_state_font(style, block.role).metrics,
      anchor~,
      monospaced_family=state_monospaced_family(style),
    )
  }
}
