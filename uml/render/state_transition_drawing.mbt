///|
/// ExtremityArrow.buildPolygon and getDecorationLength.
const STATE_ARROW_WING : Double = 9.0

///|
const STATE_ARROW_APERTURE : Double = 4.0

///|
const STATE_ARROW_CONTACT : Double = 5.0

///|
/// Extremity.getDecorationLength, inherited by circle and circle-cross ends.
const STATE_CIRCLE_CONTACT : Double = 8.0

///|
const STATE_CROSS_RADIUS : Double = 7.0

///|
const STATE_CIRCLE_RADIUS : Double = 5.0

///|
const STATE_DECORATION_STROKE_WIDTH : Double = 1.5

///|
/// Extremity.manageround compares angles in degrees without normalizing
/// negative angles. ArrowAndCircle receives an angle offset by its factory.
const STATE_EXTREMITY_ANGLE_TOLERANCE : Double = 0.05

///|
fn state_arrow_direction(
  direction : (Double, Double),
  circle_end~ : Bool,
) -> (Double, Double) {
  let offset = if circle_end { @math.PI / 2.0 } else { 0.0 }
  let angle = @math.atan2(direction.1, direction.0) - offset
  let degrees = angle * 180.0 / @math.PI
  for orthogonal in [0.0, 90.0, 180.0, 270.0, 360.0] {
    if (degrees - orthogonal).abs() < STATE_EXTREMITY_ANGLE_TOLERANCE {
      let rounded = (if orthogonal == 360.0 { 0.0 } else { orthogonal }) *
        @math.PI /
        180.0 +
        offset
      return (@math.cos(rounded), @math.sin(rounded))
    }
  }
  direction
}

///|
fn append_state_arrow(
  output : @graphics.Graphic,
  tip : (Double, Double),
  direction : (Double, Double),
  paint : @graphics.DrawingStyle,
) -> Unit {
  let point = (x : Double, y : Double) => @graphics.Point::{
    x: tip.0 + x * direction.0 - y * direction.1,
    y: tip.1 + x * direction.1 + y * direction.0,
  }
  output
  .with_style({ ..paint, fill: paint.stroke, dash: Some([]), })
  .draw(
    Polygon([
      point(0.0, 0.0),
      point(-STATE_ARROW_WING, -STATE_ARROW_APERTURE),
      point(-STATE_ARROW_CONTACT, 0.0),
      point(-STATE_ARROW_WING, STATE_ARROW_APERTURE),
    ]),
    metadata=state_class("state-arrowhead"),
  )
}

///|
fn append_state_cross(
  output : @graphics.Graphic,
  style : @style.DocumentStyle,
  contact : (Double, Double),
  paint : @graphics.DrawingStyle,
) -> Unit {
  let center : @graphics.Point = { x: contact.0, y: contact.1, }
  output
  .with_style({
    ..state_paint(
      Color(state_decoration_background_color(style)),
      paint.stroke,
      STATE_DECORATION_STROKE_WIDTH,
    ),
    dash: Some([]),
  })
  .draw(
    Circle(center~, radius=STATE_CROSS_RADIUS),
    metadata=state_class("state-cross-start"),
  )
  let diagonal = STATE_CROSS_RADIUS / 2.0.sqrt()
  output
  // SvekEdge passes stroke.onlyThickness() to extremities. The cross keeps
  // that thickness; only its enclosing circle replaces it with a fixed one.
  .with_style({ ..paint, fill: None, dash: Some([]), })
  .draw(
    Path([
      MoveTo({ x: center.x - diagonal, y: center.y - diagonal, }),
      LineTo({ x: center.x + diagonal, y: center.y + diagonal, }),
      MoveTo({ x: center.x - diagonal, y: center.y + diagonal, }),
      LineTo({ x: center.x + diagonal, y: center.y - diagonal, }),
    ]),
    metadata=state_class("state-cross-lines"),
  )
}

///|
/// Previously verified: arrows and circle/cross decorations use semantic
/// contacts, retain routed curves, respect signed angle rounding and inherit
/// link paint without changing route geometry.
fn append_state_edge(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  edge : StateEdgeLayout,
  include_hidden? : Bool = false,
) -> Unit {
  guard edge.transition_index < diagram.transitions.length() else { return }
  let transition = diagram.transitions[edge.transition_index]
  guard include_hidden || !transition.has_line_style("hidden") else { return }
  let paint = state_transition_paint(transition, diagram.style)
  for path in edge.paths {
    guard relation_spline_end_direction(path) is Some(direction) else {
      continue
    }
    let source = path[0]
    let target = path[path.length() - 1]
    // SvekEdge.getExtremitySimplier moves endpoints and adjacent controls,
    // preserving the Bezier tangents while making room for the decoration.
    let shortened = shorten_relation_spline(
      path,
      if transition.has_cross_start {
        STATE_CIRCLE_CONTACT
      } else {
        0.0
      },
      if transition.has_circle_end {
        STATE_CIRCLE_CONTACT
      } else {
        STATE_ARROW_CONTACT
      },
    )
    output
    .with_style(paint)
    .draw(
      Path(@graphics.spline_segments(shortened)),
      metadata=state_class("state-transition"),
    )
    if transition.has_cross_start {
      append_state_cross(output, diagram.style, source, paint)
    }
    let arrow_direction = state_arrow_direction(
      direction,
      circle_end=transition.has_circle_end,
    )
    let tip = if transition.has_circle_end {
      (
        target.0 - arrow_direction.0 * STATE_CIRCLE_RADIUS,
        target.1 - arrow_direction.1 * STATE_CIRCLE_RADIUS,
      )
    } else {
      target
    }
    append_state_arrow(output, tip, arrow_direction, paint)
    if transition.has_circle_end {
      output
      .with_style({
        ..state_paint(
          Color(state_decoration_background_color(diagram.style)),
          paint.stroke,
          STATE_DECORATION_STROKE_WIDTH,
        ),
        dash: Some([]),
      })
      .draw(
        Circle(center={ x: target.0, y: target.1, }, radius=STATE_CIRCLE_RADIUS),
        metadata=state_class("state-circle-end"),
      )
    }
  }
  guard transition.label is Some(label) && edge.label is Some(position) else {
    return
  }
  let metrics = resolve_state_font(diagram.style, TransitionLabel).metrics
  append_state_label(
    output,
    label,
    position.0,
    position.1 +
    metrics.ascent.to_double() -
    metrics.line_height.to_double() / 2.0,
    "state-transition-label",
    metrics,
    line_alignment=Some(
      state_skinparam_alignment(diagram.style, "StateMessageAlignment", Middle),
    ),
    wrap_width=state_transition_wrap_width(diagram.style),
    monospaced_family=state_monospaced_family(diagram.style),
  )
}
