///|
fn initial_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityStartColor", style.defaults().line)
}

///|
fn terminal_border_color(style : @style.DocumentStyle) -> String {
  style.defaults().line
}

///|
fn final_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityEndColor", style.defaults().line)
}

///|
fn diamond_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityDiamondBackgroundColor", style.defaults().node)
}

///|
fn diamond_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityDiamondBorderColor", style.defaults().line)
}

///|
fn synchronization_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityBarColor", style.defaults().line)
}

///|
fn state_style_property(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  key : String,
) -> String? {
  guard state.stereotype is Some(stereotype) else { return style.property(key) }
  style
  .property(key + stereotype)
  .map_or(style.property(key), value => Some(value))
}

///|
fn state_style_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  key : String,
  fallback : String,
) -> String {
  @svg.svg_color(state_style_property(state, style, key), fallback)
}

///|
/// Resolve normal-state paint with PlantUML's inline-color precedence.
fn state_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  let fallback = state_style_color(
    state,
    style,
    "StateBackgroundColor",
    style.defaults().node,
  )
  @svg.svg_color(state.color, fallback)
}

///|
fn state_border_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_style_color(
    state,
    style,
    "StateBorderColor",
    style.diagram_line_color(),
  )
}

///|
fn composite_state_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_background_color(state, style)
}

///|
fn composite_state_border_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_border_color(state, style)
}

///|
fn note_background_color(
  note : @flow.StateNote,
  style : @style.DocumentStyle,
) -> String {
  let fallback = style.property_color(
    "NoteBackgroundColor",
    style.defaults().note,
  )
  @svg.svg_color(note.color, fallback)
}

///|
fn note_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("NoteBorderColor", style.diagram_line_color())
}

///|
priv enum StateFontRole {
  StateLabel
  StateDescription
  DiamondLabel
  NoteLabel
}

///|
/// Resolved together so CSS and measured text use the same font definition.
priv struct ResolvedStateFont {
  family : String
  size : Int
  color : String
  metrics : @metrics.FontMetrics
}

///|
fn resolve_state_font(
  style : @style.DocumentStyle,
  role : StateFontRole,
) -> ResolvedStateFont {
  let (prefix, fallback) = match role {
    StateLabel => ("State", STATE_LABEL_FONT_SIZE)
    StateDescription => ("StateAttribute", STATE_LABEL_FONT_SIZE)
    DiamondLabel => ("ActivityDiamond", STATE_LABEL_FONT_SIZE)
    NoteLabel => ("Note", style.font_size_value())
  }
  let family = style.property_font_family(prefix + "FontName")
  let size = style.property_font_size(prefix + "FontSize", fallback~)
  {
    family,
    size,
    color: style.property_font_color(prefix + "FontColor"),
    metrics: style.font_metrics_for(family, font_size=size),
  }
}

///|
const STATE_LABEL_FONT_SIZE : Int = 14
