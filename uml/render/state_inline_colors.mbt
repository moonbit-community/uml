///|
/// Colors stores the last assignment for each color type. Bare colors set
/// BACK; dotted line flags alone do not set a color, and line.*:color sets LINE.
fn state_inline_color(source : String?, key : String) -> String? {
  guard source is Some(source) else { return None }
  let mut color = None
  for token in source.replace_all(old="#", new="").split(";") {
    match token.split(":").to_array() {
      [name, value] => {
        let name = name.to_lower()
        if name == key || name.has_prefix(key + ".") {
          color = Some(value.to_owned())
        }
      }
      [value] if key == "back" && !value.is_empty() && !value.contains(".") =>
        color = Some(value.to_owned())
      _ => ()
    }
  }
  color
}

///|
/// Colors.getSpecificLineStroke uses fixed LinkStyle widths and gives dashed
/// precedence over dotted and bold, independently of their order in the input.
fn state_inline_stroke(
  source : String?,
  paint : @graphics.DrawingStyle,
) -> @graphics.DrawingStyle {
  guard source is Some(source) else { return paint }
  let source = source.to_lower()
  if source.contains("line.dashed") {
    {
      ..paint,
      stroke_width: Some(STATE_LINK_STROKE_WIDTH),
      dash: Some([STATE_LINK_DASH, STATE_LINK_DASH]),
    }
  } else if source.contains("line.dotted") {
    {
      ..paint,
      stroke_width: Some(STATE_LINK_STROKE_WIDTH),
      dash: Some([STATE_LINK_DOT, STATE_LINK_DOT_GAP]),
    }
  } else if source.contains("line.bold") {
    { ..paint, stroke_width: Some(STATE_LINK_BOLD_WIDTH), dash: Some([]), }
  } else {
    paint
  }
}

///|
/// Previously verified: inline color/line flags preserve geometry, use Java
/// precedence and override styled thickness without changing unrelated text.
fn state_border_paint(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  fill : @graphics.Paint,
) -> @graphics.DrawingStyle {
  state_inline_stroke(
    state.color,
    state_paint(
      fill,
      Color(state_border_color(state, style)),
      state_border_thickness(state, style),
    ),
  )
}

///|
/// EntityImageStateCommon passes inline colors into the name's font; its
/// fields and InnerStateAutonom's name use their style font configuration.
/// ClusterHeader also applies inline colors to a non-autonomous group title.
fn resolve_state_node_font(
  diagram : @flow.StateDiagram,
  state : @flow.StateNode,
  role : StateFontRole,
) -> ResolvedStateFont {
  let effective_role = if state.kind == @flow.Frame {
    let composite = diagram.has_children(state.code)
    match role {
      StateLabel => if composite { FrameLabel } else { PackageLabel }
      StateStereotype =>
        if composite {
          StateStereotype
        } else {
          PackageStereotype
        }
      _ => role
    }
  } else {
    role
  }
  let font = resolve_state_font(
    diagram.style,
    effective_role,
    state=Some(state),
  )
  guard role is StateLabel &&
    (!diagram.has_children(state.code) || diagram.is_state_cluster(state.code)) else {
    return font
  }
  {
    ..font,
    color: @svg.svg_color(state_inline_color(state.color, "text"), font.color),
  }
}
