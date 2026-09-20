///|
/// document styles in plantuml.skin; TextBlockBordered adds one point to
/// its measured size after padding, independently of border visibility.
const DOCUMENT_TEXT_SMALL_FONT_SIZE : Int = 10

///|
const DOCUMENT_TEXT_BORDER_EXTENT : Double = 1.0

///|
const DOCUMENT_TEXT_TITLE_INSET : Double = 5.0

///|
const DOCUMENT_TEXT_CAPTION_MARGIN : Double = 1.0

///|
const DOCUMENT_TEXT_LEGEND_MARGIN : Double = 12.0

///|
const DOCUMENT_TEXT_LEGEND_PADDING : Double = 5.0

///|
const DOCUMENT_TEXT_LEGEND_CORNER : Double = 15.0

///|
priv struct DocumentTextBlock {
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
fn document_text_alignment(
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
fn document_text_block(
  style : @style.DocumentStyle,
  kind : String,
  text : String?,
) -> DocumentTextBlock? {
  guard text is Some(text) else { return None }
  let (role, margin, padding) = match kind {
    "title" =>
      (TitleLabel, DOCUMENT_TEXT_TITLE_INSET, DOCUMENT_TEXT_TITLE_INSET)
    "caption" => (CaptionLabel, DOCUMENT_TEXT_CAPTION_MARGIN, 0.0)
    "header" => (HeaderLabel, 0.0, 0.0)
    "footer" => (FooterLabel, 0.0, 0.0)
    "legend" =>
      (LegendLabel, DOCUMENT_TEXT_LEGEND_MARGIN, DOCUMENT_TEXT_LEGEND_PADDING)
    _ => return None
  }
  let (width, height) = state_text_size(
    text,
    resolve_state_font(style, role).metrics,
    monospaced_family=state_monospaced_family(style),
  )
  let extra = (margin + padding) * 2.0 + DOCUMENT_TEXT_BORDER_EXTENT
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
    alignment: document_text_alignment(style, kind),
  })
}

///|
fn DocumentTextBlock::at(
  self : DocumentTextBlock,
  width : Double,
  y : Double,
) -> DocumentTextBlock {
  let x = match self.alignment {
    Start => 0.0
    Middle => (width - self.width) / 2.0
    End => width - self.width
  }
  { ..self, x, y, }
}

///|
fn document_text_number(
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
fn draw_document_text(
  output : @graphics.Graphic,
  style : @style.DocumentStyle,
  class_prefix : String,
  blocks : Array[DocumentTextBlock],
) -> Unit {
  for block in blocks {
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
    let border = document_text_number(
      style,
      block.kind + "BorderThickness",
      DOCUMENT_TEXT_BORDER_EXTENT,
    )
    let corner = document_text_number(
      style,
      block.kind + "BorderRoundCorner",
      if legend {
        DOCUMENT_TEXT_LEGEND_CORNER
      } else {
        0.0
      },
    )
    let x = block.x + block.margin
    let y = block.y + block.margin
    let width = block.width - block.margin * 2.0 - DOCUMENT_TEXT_BORDER_EXTENT
    let height = block.height - block.margin * 2.0 - DOCUMENT_TEXT_BORDER_EXTENT
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
        metadata=state_class(class_prefix + "-" + block.kind + "-border"),
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
      class_prefix + "-" + block.kind + "-label",
      resolve_state_font(style, block.role).metrics,
      anchor~,
      monospaced_family=state_monospaced_family(style),
    )
  }
}
