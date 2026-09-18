///|
/// EntityImageState.drawSymbol uses these fixed sizes for the O-O marker.
const STATE_SUBMACHINE_RADIUS : Double = 3.0

///|
const STATE_SUBMACHINE_LINK_LENGTH : Double = 3.0

///|
const STATE_SUBMACHINE_RIGHT_MARGIN : Double = 7.0

///|
const STATE_SUBMACHINE_BOTTOM_MARGIN : Double = 4.0

///|
/// Stereotype.isWithOOSymbol compares the complete stereotype, ignoring case.
fn @flow.StateNode::has_submachine_symbol(self : @flow.StateNode) -> Bool {
  self.stereotype.map_or(false, value => {
    value.equal_ignore_ascii_case("<<O-O>>")
  })
}

///|
/// EntityImageState adds this extent to both dimensions before applying its
/// minimum size. InnerStateAutonom draws the marker without this extra extent.
fn @flow.StateNode::submachine_extent(self : @flow.StateNode) -> Double {
  if self.has_submachine_symbol() {
    STATE_SUBMACHINE_RADIUS * 2.0 + STATE_SUBMACHINE_BOTTOM_MARGIN
  } else {
    0.0
  }
}

///|
/// Previously verified: leaf/composite marker sizing, joined circles in the
/// lower-right corner, and ordinary/compound stereotype exclusion.
fn append_state_submachine_symbol(
  output : @graphics.Graphic,
  state : @flow.StateNode,
  layout : StateNodeLayout,
  paint : @graphics.DrawingStyle,
) -> Unit {
  guard state.has_submachine_symbol() else { return }
  let radius = STATE_SUBMACHINE_RADIUS
  let x = layout.x +
    layout.width -
    (
      radius * 4.0 +
      STATE_SUBMACHINE_LINK_LENGTH +
      STATE_SUBMACHINE_RIGHT_MARGIN
    )
  let y = layout.y +
    layout.height -
    (radius * 2.0 + STATE_SUBMACHINE_BOTTOM_MARGIN)
  let output = output.with_style(paint)
  for center_x in [x + radius, x + radius * 3.0 + STATE_SUBMACHINE_LINK_LENGTH] {
    output.draw(
      Circle(center={ x: center_x, y: y + radius, }, radius~),
      metadata=state_class("state-submachine-symbol"),
    )
  }
  output.draw(
    Line({ x: x + radius * 2.0, y: y + STATE_SUBMACHINE_LINK_LENGTH, }, {
      x: x + radius * 2.0 + STATE_SUBMACHINE_LINK_LENGTH,
      y: y + STATE_SUBMACHINE_LINK_LENGTH,
    }),
    metadata=state_class("state-submachine-symbol"),
  )
}
