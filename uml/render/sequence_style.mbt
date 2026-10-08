///|
fn sequence_style_property(
  style : @style.DocumentStyle,
  role : String,
  key : String,
  stereotype? : String? = None,
) -> String? {
  let style = style.with_stereotypes(stereotype)
  if stereotype is Some(stereotype) {
    if style.property("Sequence" + role + key + stereotype) is Some(value) {
      return Some(value)
    }
    if style.property(role + key + stereotype) is Some(value) {
      return Some(value)
    }
  }
  style
  .property("Sequence" + role + key)
  .map_or(style.property(role + key), value => Some(value))
}

///|
fn sequence_style_color(
  style : @style.DocumentStyle,
  role : String,
  key : String,
  fallback : String,
  stereotype? : String? = None,
) -> String {
  @svg.svg_color(
    sequence_style_property(style, role, key, stereotype~),
    fallback,
  )
}

///|
fn sequence_font(
  style : @style.DocumentStyle,
  role : String,
  size : Int,
  weight? : Int = 400,
  italic? : Bool = false,
  stereotype? : String? = None,
) -> @metrics.FontMetrics {
  let family = sequence_style_property(style, role, "FontName", stereotype~).unwrap_or(
    style.font_family(),
  )
  let size = sequence_style_property(style, role, "FontSize", stereotype~).map_or(
    size,
    value => (@string.parse_int(value) catch { _ => size }).max(1),
  )
  let font_style = sequence_style_property(
    style,
    role,
    "FontStyle",
    stereotype~,
  ).map(value => value.to_lower())
  style.font_metrics_for(
    family,
    font_size=size,
    font_weight=font_style.map_or(weight, value => {
      if value.contains("bold") {
        700
      } else {
        400
      }
    }),
    font_style=if font_style.map_or(italic, value => value.contains("italic")) {
      Italic
    } else {
      Normal
    },
    line_height=size + 2,
  )
}

///|
fn sequence_colors(style : @style.DocumentStyle) -> @style.SequenceColors {
  let base = style.defaults().sequence_colors()
  {
    ..base,
    line: sequence_style_color(
      style,
      "Arrow",
      "Color",
      style.diagram_line_color(),
    ),
    text: style.diagram_text_color(),
    canvas: style.canvas_color(),
    note: sequence_style_color(style, "Note", "BackgroundColor", base.note),
    participant: sequence_style_color(
      style,
      "Participant",
      "BackgroundColor",
      base.participant,
    ),
    activation: sequence_style_color(
      style,
      "LifeLine",
      "BackgroundColor",
      base.activation,
    ),
    lifeline: sequence_style_color(
      style,
      "LifeLine",
      "BorderColor",
      base.lifeline,
    ),
    divider_title: sequence_style_color(
      style,
      "Divider",
      "BackgroundColor",
      base.divider_title,
    ),
    reference_tab: sequence_style_color(
      style,
      "Reference",
      "BackgroundColor",
      base.reference_tab,
    ),
  }
}
