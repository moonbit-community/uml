///|
/// RoundedNorth, RoundedSouth, and RoundedContainer.drawCenter use UStroke.simple.
const STATE_BACKGROUND_STROKE_WIDTH : Double = 1.0

///|
fn state_composite_header_shape(
  layout : StateNodeLayout,
  header_height : Double,
  corner : Double,
) -> @graphics.Shape {
  let x = layout.x
  let y = layout.y
  let width = layout.width
  if corner == 0.0 {
    Rectangle(origin={ x, y, }, width~, height=header_height, rx=None, ry=None)
  } else {
    Path([
      MoveTo({ x: x + corner, y, }),
      LineTo({ x: x + width - corner, y, }),
      ArcTo(rx=corner, ry=corner, rotation=0.0, large_arc=false, sweep=true, end={
        x: x + width,
        y: y + corner,
      }),
      LineTo({ x: x + width, y: y + header_height, }),
      LineTo({ x, y: y + header_height, }),
      LineTo({ x, y: y + corner, }),
      ArcTo(rx=corner, ry=corner, rotation=0.0, large_arc=false, sweep=true, end={
        x: x + corner,
        y,
      }),
      Close,
    ])
  }
}

///|
/// RoundedSouth starts below the title and description, rounding only the
/// lower corners so its top meets the description divider without a gap.
fn state_composite_body_shape(
  layout : StateNodeLayout,
  top : Double,
  corner : Double,
) -> @graphics.Shape {
  let x = layout.x
  let right = x + layout.width
  let bottom = layout.y + layout.height
  if corner == 0.0 {
    Rectangle(
      origin={ x, y: top, },
      width=layout.width,
      height=bottom - top,
      rx=None,
      ry=None,
    )
  } else {
    Path([
      MoveTo({ x, y: top, }),
      LineTo({ x: right, y: top, }),
      LineTo({ x: right, y: bottom - corner, }),
      ArcTo(rx=corner, ry=corner, rotation=0.0, large_arc=false, sweep=true, end={
        x: right - corner,
        y: bottom,
      }),
      LineTo({ x: x + corner, y: bottom, }),
      ArcTo(rx=corner, ry=corner, rotation=0.0, large_arc=false, sweep=true, end={
        x,
        y: bottom - corner,
      }),
      LineTo({ x, y: top, }),
      Close,
    ])
  }
}

///|
/// Previously verified: rounded/square fills cover the child compartment;
/// transparent composite bodies omit their background.
fn append_state_composite_background(
  output : @graphics.Graphic,
  state : @flow.StateNode,
  layout : StateNodeLayout,
  style : @style.DocumentStyle,
  header_height : Double,
  description_height : Double,
  corner : Double,
) -> Unit {
  let upper = composite_state_background_color(state, style)
  let lower = composite_state_body_background_color(state, style)
  let header_bottom = layout.y + header_height
  if upper != "none" && upper != "transparent" {
    output
    .with_style(
      state_paint(Color(upper), Color(upper), STATE_BACKGROUND_STROKE_WIDTH),
    )
    .draw(
      state_composite_header_shape(layout, header_height, corner),
      metadata=state_class("state-composite-header-background"),
    )
  }
  if description_height > 0.0 {
    output
    .with_style(
      state_paint(Color(upper), Color(upper), STATE_BACKGROUND_STROKE_WIDTH),
    )
    .draw(
      Rectangle(
        origin={ x: layout.x, y: header_bottom, },
        width=layout.width,
        height=description_height,
        rx=None,
        ry=None,
      ),
      metadata=state_class("state-composite-description-background"),
    )
  }
  if lower != "none" && lower != "transparent" {
    output
    .with_style(
      state_paint(Color(lower), Color(lower), STATE_BACKGROUND_STROKE_WIDTH),
    )
    .draw(
      state_composite_body_shape(
        layout,
        header_bottom + description_height,
        corner,
      ),
      metadata=state_class("state-composite-body-background"),
    )
  }
}
