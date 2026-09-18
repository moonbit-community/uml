///|
/// WithLinkType applies comma-separated flags independently of the stroke
/// pattern. Hidden links still participate in DOT and LimitFinder; norank
/// only disables the edge's ranking constraint.
fn @flow.StateTransition::has_line_style(
  self : @flow.StateTransition,
  keyword : String,
) -> Bool {
  self.line_style.map_or(false, value => {
    value
    .split(",")
    .any(part => part.to_owned().equal_ignore_ascii_case(keyword))
  })
}

///|
priv enum StateStrokePattern {
  Plain
  Bold
  Dashed
  Dotted
}

///|
priv struct StateStrokeSpec {
  pattern : StateStrokePattern
  thickness : Double?
  color : String?
}

///|
const STATE_LINK_STROKE_WIDTH : Double = 1.0

///|
const STATE_LINK_BOLD_WIDTH : Double = 2.0

///|
const STATE_LINK_DASH : Double = 7.0

///|
const STATE_LINK_DOT : Double = 1.0

///|
const STATE_LINK_DOT_GAP : Double = 3.0

///|
/// WithLinkType applies tokens in order. Changing the pattern resets an
/// earlier thickness; plain and layout flags leave the chosen pattern intact.
/// Verified before Graphviz 0.1.10: hidden/norank flags preserve their separate
/// layout effects; token order controls patterns, thickness resets and color.
fn @flow.StateTransition::stroke_spec(
  self : @flow.StateTransition,
) -> StateStrokeSpec {
  let initial : StateStrokeSpec = {
    pattern: Plain,
    thickness: None,
    color: None,
  }
  guard self.line_style is Some(style) else { return initial }
  style
  .split(",")
  .fold(init=initial, (current, token) => {
    match token.to_lower() {
      "bold" => { ..current, pattern: Bold, thickness: None, }
      "dashed" => { ..current, pattern: Dashed, thickness: None, }
      "dotted" => { ..current, pattern: Dotted, thickness: None, }
      _ => {
        if token.strip_prefix("thickness=") is Some(value) {
          let thickness = @string.parse_double(value) catch {
            _ => return current
          }
          return { ..current, thickness: Some(thickness), }
        }
        guard token.has_prefix("#") else { return current }
        { ..current, color: Some(token.to_owned()), }
      }
    }
  })
}

///|
/// LinkType.getStroke3 uses the default ArrowThickness unless an explicit
/// thickness remains. LinkStyle.BOLD always uses its own bold width.
fn state_transition_paint(
  transition : @flow.StateTransition,
  style : @style.DocumentStyle,
) -> @graphics.DrawingStyle {
  let stroke = transition.stroke_spec()
  let default_width = style
    .property("ArrowThickness")
    .map_or(STATE_LINK_STROKE_WIDTH, value => {
      @string.parse_double(value) catch {
        _ => STATE_LINK_STROKE_WIDTH
      }
    })
  let width = if stroke.pattern is Bold {
    STATE_LINK_BOLD_WIDTH
  } else {
    stroke.thickness.unwrap_or(default_width)
  }
  let dash = match stroke.pattern {
    Plain | Bold => None
    Dashed => Some([STATE_LINK_DASH, STATE_LINK_DASH])
    Dotted => Some([STATE_LINK_DOT, STATE_LINK_DOT_GAP])
  }
  let color = @svg.svg_color(stroke.color, style.diagram_line_color())
  { ..state_paint(None, Color(color), width), dash, }
}
