///|
fn activity_font_metrics(
  style : @style.DocumentStyle,
  arrow : Bool,
) -> @metrics.FontMetrics {
  let prefix = if arrow { "Arrow" } else { "Activity" }
  let font_size = style.property_font_size(
    prefix + "FontSize",
    fallback=if arrow { SMALL_FONT } else { ACTION_FONT },
  )
  let family = style
    .property(prefix + "FontName")
    .unwrap_or(style.font_family())
  let weight = if style
    .property(prefix + "FontStyle")
    .map_or(false, value => value.to_lower().contains("bold")) {
    700
  } else {
    400
  }
  style.font_metrics_for(family, font_size~, font_weight=weight)
}
