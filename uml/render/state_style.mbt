///|
/// CircleStart/CircleEnd resolve BACK and LINE independently from inline
/// colors, then their global circle style; they do not merge stereotypes.
/// Verified 2026-09-16: independent BACK/LINE overrides preserve node layout
/// and routed contacts. Terminal stereotypes and line flags are ignored;
/// the final outer circle remains unfilled. Temporary property tests removed.
fn state_terminal_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  let fallback = if state.kind == @flow.StateKind::Initial {
    style.property_color("ActivityStartColor", style.defaults().line)
  } else {
    style.defaults().line
  }
  @svg.svg_color(state_inline_color(state.color, "back"), fallback)
}

///|
/// Verified with state_terminal_background_color on 2026-09-16: a LINE
/// override changes the circle outlines without changing their fill or width.
fn state_terminal_border_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  let fallback = if state.kind == @flow.StateKind::Final {
    style.property_color("ActivityEndColor", style.defaults().line)
  } else {
    style.defaults().line
  }
  @svg.svg_color(state_inline_color(state.color, "line"), fallback)
}

///|
/// CircleEnd uses HColorMiddle for equal solid colors. Its RGB constructor
/// makes the inner outline opaque even when both supplied colors have alpha.
/// Verified 2026-09-16: equal RGBA colors produce an opaque inner outline,
/// preserving fill/outer alpha; unequal colors and gradients pass through.
fn state_final_inner_border_color(
  background : String,
  border : String,
) -> String {
  guard state_gradient_color(background) is Some(back) &&
    state_gradient_color(border) is Some(line) &&
    back == line else {
    return border
  }
  guard line.length() > 7 else { return border }
  line[:7].to_owned()
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
/// EntityImageSynchroBar merges the stereotype's activityBar style and
/// ignores inline state colors.
/// Verified 2026-09-16: fork/join stereotype paint matches equivalent global
/// paint in both rank directions, including geometry and absent outlines.
fn synchronization_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_style_color(state, style, "ActivityBarColor", style.defaults().line)
}

///|
/// SvekEdge's extremities use the skin background (white by default), even
/// when the exported canvas itself is transparent. Otherwise a state border
/// shows through the circle-cross drawn on top of it.
fn state_decoration_background_color(style : @style.DocumentStyle) -> String {
  let canvas = style.canvas_color()
  guard style.background_color is None &&
    (canvas == "none" || canvas == "transparent") else {
    return canvas
  }
  "#FFFFFF"
}

///|
/// Previously verified: each property uses its first matching stereotype;
/// a lone submachine stereotype does not become a style label.
fn state_style_property(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  key : String,
) -> String? {
  style.property(state_style_property_key(state, style, key))
}

///|
/// StyleSignatures merges in label order with KEEP_EXISTING_VALUE_OF_STEREOTYPE:
/// the first stereotype defining a property wins; other properties can come
/// from later labels. A lone O-O marker exposes no style labels in Java.
fn state_style_property_key(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  key : String,
) -> String {
  guard state.stereotype is Some(group) && !state.has_submachine_symbol() else {
    return key
  }
  let cursor = @tokenizer.Cursor::new(group)
  while !cursor.is_eof() {
    cursor.skip_inline_spaces()
    guard cursor.take_stereotype_value() is Some(label) else { break }
    let candidate = key + label
    if style.property(candidate) is Some(_) {
      return candidate
    }
  }
  key
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
  @svg.svg_color(state_inline_color(state.color, "back"), fallback)
}

///|
fn state_border_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  let fallback = state_style_color(
    state,
    style,
    "StateBorderColor",
    style.diagram_line_color(),
  )
  @svg.svg_color(state_inline_color(state.color, "line"), fallback)
}

///|
/// ValueImpl.asDouble extracts decimal digits and dots before parsing skin
/// geometry values, including values annotated with units.
fn state_style_dimension(value : String, fallback : Double) -> Double {
  let digits = StringBuilder()
  for char in value.iter() {
    if char.is_ascii_digit() || char == '.' {
      digits.write_char(char)
    }
  }
  @string.parse_double(digits.to_string()) catch {
    _ => fallback
  }
}

///|
fn state_border_thickness(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> Double {
  state_style_property(state, style, "StateBorderThickness").map_or(
    STATE_THIN_STROKE_WIDTH,
    value => state_style_dimension(value, STATE_THIN_STROKE_WIDTH),
  )
}

///|
/// State shapes use the root RoundCorner style. URectangle stores the full
/// corner diameter; SVG and RoundedNorth's arcs use half that value.
/// Previously verified: border widths and rounding reach outlines/dividers,
/// remain local to matching stereotypes and use Java numeric extraction.
fn state_corner_radius(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> Double {
  state_style_property(state, style, "RoundCorner").map_or(
    STATE_CORNER_RADIUS,
    value => state_style_dimension(value, STATE_CORNER_RADIUS * 2.0) / 2.0,
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
/// The body style defaults to transparent, but an explicit state background
/// style or inline BACK color also colors the compartment containing children.
fn composite_state_body_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  let fallback = state_style_color(state, style, "StateBackgroundColor", "none")
  @svg.svg_color(state_inline_color(state.color, "back"), fallback)
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
  @svg.svg_color(state_inline_color(note.color, "back"), fallback)
}

///|
fn note_border_color(
  note : @flow.StateNote,
  style : @style.DocumentStyle,
) -> String {
  let fallback = style.property_color(
    "NoteBorderColor",
    style.diagram_line_color(),
  )
  guard note.target is TransitionNote(_) else { return fallback }
  @svg.svg_color(state_inline_color(note.color, "line"), fallback)
}

///|
priv enum StateFontRole {
  StateLabel
  StateDescription
  StateStereotype
  FrameLabel
  PackageLabel
  PackageStereotype
  TransitionLabel
  DiamondLabel
  NoteLabel
  TitleLabel
  CaptionLabel
  HeaderLabel
  FooterLabel
  LegendLabel
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
/// Previously verified: stereotype/global font equivalence, partial property
/// inheritance, local overrides, face normalization and Java size extraction.
fn resolve_state_font(
  style : @style.DocumentStyle,
  role : StateFontRole,
  state? : @flow.StateNode? = None,
) -> ResolvedStateFont {
  let (prefix, fallback) = match role {
    StateLabel | StateDescription => ("State", STATE_LABEL_FONT_SIZE)
    StateStereotype => ("StateStereotype", STATE_LABEL_FONT_SIZE)
    FrameLabel => ("Frame", STATE_LABEL_FONT_SIZE)
    PackageLabel => ("Package", STATE_LABEL_FONT_SIZE)
    PackageStereotype => ("PackageStereotype", STATE_LABEL_FONT_SIZE)
    TransitionLabel => ("Arrow", STATE_TRANSITION_FONT_SIZE)
    DiamondLabel => ("ActivityDiamond", STATE_LABEL_FONT_SIZE)
    NoteLabel => ("Note", STATE_NOTE_FONT_SIZE)
    TitleLabel => ("Title", STATE_LABEL_FONT_SIZE)
    CaptionLabel => ("Caption", STATE_LABEL_FONT_SIZE)
    HeaderLabel => ("Header", STATE_DOCUMENT_SMALL_FONT_SIZE)
    FooterLabel => ("Footer", STATE_DOCUMENT_SMALL_FONT_SIZE)
    LegendLabel => ("Legend", STATE_LABEL_FONT_SIZE)
  }
  // EntityImageStateCommon resolves each state's name/body style with its
  // stereotype. Resolve each property separately so partial overrides inherit.
  let key = (suffix : String) => {
    let base = prefix + suffix
    state.map_or(base, state => state_style_property_key(state, style, base))
  }
  let family = style.property_font_family(key("FontName"))
  let size = style
    .property(key("FontSize"))
    .map_or_else(
      () => {
        if role
          is (TitleLabel
          | CaptionLabel
          | HeaderLabel
          | FooterLabel
          | LegendLabel) {
          fallback
        } else {
          style.font_size.map_or(fallback, state_font_size)
        }
      },
      state_font_size,
    )
  let face = state_font_face(
    style
    .property(key("FontStyle"))
    .unwrap_or(
      if role is (TitleLabel | FrameLabel | PackageLabel) {
        "bold"
      } else if role is (StateStereotype | PackageStereotype) {
        "italic"
      } else {
        "normal"
      },
    ),
  )
  {
    family,
    size,
    color: style.property_color(
      key("FontColor"),
      style.property_color(
        "DefaultFontColor",
        if role is (HeaderLabel | FooterLabel) {
          "#888888"
        } else {
          style.diagram_text_color()
        },
      ),
    ),
    metrics: style.font_metrics_for(
      family,
      font_size=size,
      font_weight=face.weight,
      font_style=face.style,
    ),
  }
}

///|
/// ValueImpl.asInt collects ASCII digits; Style.getUFont uses the standard
/// state text size for an explicit value with no digits. It does not convert
/// a pt/px suffix into another unit before reserving the text box.
fn state_font_size(value : String) -> Int {
  let digits = StringBuilder()
  for char in value.iter() {
    if char is ('0'..='9') {
      digits.write_char(char)
    }
  }
  @string.parse_int(digits.to_string()) catch {
    _ => STATE_LABEL_FONT_SIZE
  }
}

///|
priv struct StateFontFace {
  weight : Int
  style : @metrics.FontStyle
}

///|
const STATE_FONT_NORMAL_WEIGHT : Int = 400

///|
const STATE_FONT_BOLD_WEIGHT : Int = 700

///|
const STATE_FONT_LIGHT_WEIGHT : Int = 300

///|
const STATE_FONT_HEAVY_WEIGHT : Int = 800

///|
const STATE_FONT_WEIGHT_STEP : Int = 100

///|
const STATE_FONT_MAX_WEIGHT : Int = 900

///|
/// ValueImpl.asFontFace and UFontWeight.fromCssValue. Unrecognized values
/// reset to normal; numeric weights clamp and round to the nearest hundred.
fn state_font_face(value : String) -> StateFontFace {
  let value = value.trim().to_owned().to_lower()
  let normal : StateFontFace = {
    weight: STATE_FONT_NORMAL_WEIGHT,
    style: Normal,
  }
  match value {
    "normal" | "plain" => normal
    "bold" => { ..normal, weight: STATE_FONT_BOLD_WEIGHT, }
    "italic" => { ..normal, style: Italic, }
    "lighter" => { ..normal, weight: STATE_FONT_LIGHT_WEIGHT, }
    "bolder" => { ..normal, weight: STATE_FONT_HEAVY_WEIGHT, }
    _ => {
      let weight = @string.parse_int(value) catch { _ => return normal }
      let weight = weight.clamp(
        min=STATE_FONT_WEIGHT_STEP,
        max=STATE_FONT_MAX_WEIGHT,
      )
      {
        ..normal,
        weight: (weight + STATE_FONT_WEIGHT_STEP / 2) /
        STATE_FONT_WEIGHT_STEP *
        STATE_FONT_WEIGHT_STEP,
      }
    }
  }
}

///|
/// The SVG font face comes from the metrics used to reserve its text box.
fn ResolvedStateFont::css_rule(
  self : ResolvedStateFont,
  selector : String,
) -> String {
  let style = match self.metrics.style {
    Normal => "normal"
    Italic => "italic"
  }
  let color = state_first_gradient_color(self.color)
  "\{selector}{font-family:\{self.family};font-size:\{self.size}px;font-weight:\{self.metrics.font_weight};font-style:\{style};fill:\{color}}"
}

///|
const STATE_LABEL_FONT_SIZE : Int = 14

///|
/// plantuml.skin: arrow.FontSize (also used by state-diagram transitions).
const STATE_TRANSITION_FONT_SIZE : Int = 13

///|
/// plantuml.skin note.FontSize.
const STATE_NOTE_FONT_SIZE : Int = 13

///|
/// FromSkinparamToStyle converts booleans to 0/3; Style.getShadowing uses
/// ValueImpl's digit-and-dot extraction, with 1.5 for an invalid explicit value.
fn state_shadow_value(value : String?) -> Double {
  guard value is Some(value) else { return 0.0 }
  match value.to_lower() {
    "true" | "yes" => 3.0
    "false" | "no" => 0.0
    _ => state_style_dimension(value, 1.5)
  }
}

///|
fn state_node_shadow(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> Double {
  let value = if state.kind
    is (@flow.StateKind::Initial
    | @flow.StateKind::Final
    | @flow.StateKind::Choice) {
    style.property("Shadowing")
  } else {
    state_style_property(state, style, "Shadowing")
  }
  state_shadow_value(value)
}

///|
fn state_note_shadow(style : @style.DocumentStyle) -> Double {
  let value = if style.property("NoteShadowing") is Some(value) {
    Some(value)
  } else {
    style.property("Shadowing")
  }
  state_shadow_value(value)
}

///|
fn state_shadow_metadata(
  metadata : @graphics.Metadata,
  shadow : Double,
) -> @graphics.Metadata {
  guard shadow > 0.0 else { return metadata }
  { ..metadata, data: [..metadata.data, ("state-shadow", shadow.to_string())], }
}

///|
fn state_metadata_shadow(metadata : @graphics.Metadata) -> Double {
  state_rich_context(metadata, "state-shadow").map_or(0.0, value => {
    @string.parse_double(value) catch {
      _ => 0.0
    }
  })
}
