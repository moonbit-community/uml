///|
/// EntityImagePseudoState uses the state's diamond stereotype style for both
/// its circle and label. The circle keeps its fixed size even when the font
/// grows; the text's measured bounds still contribute to the exported canvas.
/// Verified 2026-09-16: H/H* stereotype styles match equivalent global drawing
/// commands, layout, and font CSS; enlarged labels expand drawing bounds without
/// resizing circles or changing unrelated history/choice nodes. Property merging
/// and ignored inline state colors passed. Temporary property tests removed.
fn append_state_history(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  state : @flow.StateNode,
  layout : StateNodeLayout,
) -> Unit {
  let deep = state.kind == @flow.StateKind::DeepHistory
  let label = if deep { "H*" } else { "H" }
  let metrics = resolve_state_node_font(diagram, state, DiamondLabel).metrics
  let center : @graphics.Point = {
    x: layout.x + layout.width / 2.0,
    y: layout.y + layout.height / 2.0,
  }
  output
  .with_style(
    state_paint(
      Color(
        state_style_color(
          state,
          diagram.style,
          "ActivityDiamondBackgroundColor",
          diagram.style.defaults().node,
        ),
      ),
      Color(
        state_style_color(
          state,
          diagram.style,
          "ActivityDiamondBorderColor",
          diagram.style.defaults().line,
        ),
      ),
      STATE_THIN_STROKE_WIDTH,
    ),
  )
  .draw(
    Circle(center~, radius=layout.width.min(layout.height) / 2.0),
    metadata=state_shadow_metadata(
      state_class(if deep { "state-deep-history" } else { "state-history" }),
      state_node_shadow(state, diagram.style),
    ),
  )
  append_state_text_at_top(
    output,
    label,
    center.x,
    center.y - state_text_size(label, metrics).1 / 2.0,
    "state-pseudostate-label",
    metrics,
    state=Some(state),
  )
}
