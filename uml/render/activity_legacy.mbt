///|
/// EntityImageActivity and DotStringFactory's ACTIVITY-specific geometry.
const LEGACY_ACTIVITY_MARGIN : Double = 10.0

///|
const LEGACY_ACTIVITY_CORNER : Double = 25.0

///|
const LEGACY_ACTIVITY_NODESEP : Double = 20.0

///|
const LEGACY_ACTIVITY_RANKSEP : Double = 40.0

///|
const LEGACY_ACTIVITY_FONT : Int = 12

///|
const LEGACY_ACTIVITY_ARROW_FONT : Int = 11

///|
fn legacy_activity_font(
  style : @style.DocumentStyle,
  prefix : String,
  fallback : Int,
) -> @metrics.FontMetrics {
  let size = style.property_font_size(prefix + "FontSize", fallback~)
  let face = style.property(prefix + "FontStyle").unwrap_or("").to_lower()
  style.font_metrics_for(
    style.property(prefix + "FontName").unwrap_or(style.font_family()),
    font_size=size,
    font_weight=if face.contains("bold") { 700 } else { 400 },
    font_style=if face.contains("italic") { Italic } else { Normal },
  )
}

///|
fn legacy_activity_metrics(
  style : @style.DocumentStyle,
) -> @metrics.FontMetrics {
  legacy_activity_font(style, "Activity", LEGACY_ACTIVITY_FONT)
}

///|
fn legacy_activity_arrow_metrics(
  style : @style.DocumentStyle,
) -> @metrics.FontMetrics {
  legacy_activity_font(style, "Arrow", LEGACY_ACTIVITY_ARROW_FONT)
}

///|
fn append_legacy_activity_node(
  output : @graphics.Graphic,
  style : @style.DocumentStyle,
  state : @flow.StateNode,
  layout : StateNodeLayout,
) -> Unit {
  let metrics = legacy_activity_metrics(style)
  let background = @svg.svg_color(
    state.color,
    state_style_color(
      state,
      style,
      "ActivityBackgroundColor",
      style.defaults().node,
    ),
  )
  let border = state_style_color(
    state,
    style,
    "ActivityBorderColor",
    style.defaults().line,
  )
  let width = state_style_property(state, style, "ActivityBorderThickness").map_or(
    1.5,
    value => @string.parse_double(value) catch { _ => 1.5 },
  )
  // EntityImageActivity.drawOctagon uses Graphviz's polygon, translated to
  // the activity's local origin, and its fixed outline stroke.
  let shape : @graphics.Shape = match layout.outline {
    Some(points) => Polygon(points)
    None =>
      Rectangle(
        origin={ x: 0, y: 0, },
        width=layout.width,
        height=layout.height,
        rx=Some(LEGACY_ACTIVITY_CORNER / 2.0),
        ry=None,
      )
  }
  output
  .translated(layout.x, layout.y)
  .with_style(
    state_paint(
      Color(background),
      Color(border),
      if layout.outline is Some(_) {
        LEGACY_ACTIVITY_OCTAGON_STROKE
      } else {
        width
      },
    ),
  )
  .draw(shape, metadata=state_class("legacy-activity-node"))
  append_state_text_at_top(
    output.with_style({
      ..Default::default(),
      fill: Color(
        state_style_color(
          state,
          style,
          "ActivityFontColor",
          style.diagram_text_color(),
        ),
      ),
    }),
    state.display,
    layout.x + LEGACY_ACTIVITY_MARGIN,
    layout.y + LEGACY_ACTIVITY_MARGIN,
    "legacy-activity-label",
    metrics,
    anchor=Start,
  )
}

///|
/// Legacy activities share Svek's graph/cluster layout with state diagrams,
/// but use their own node geometry, spacing and activity/arrow styles.
pub fn render_legacy_activity_svg(
  diagram : @flow.StateDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @dot_layout.DotLayoutError {
  diagram.render_svg(color_scheme~)
}

///|
/// EntityImageActivity.drawOctagon uses UStroke.withThickness(1.5).
const LEGACY_ACTIVITY_OCTAGON_STROKE : Double = 1.5
