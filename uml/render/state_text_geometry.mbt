///|
/// IEntityImage.MARGIN and MARGIN_LINE, shared by leaf and composite states.
const STATE_TEXT_MARGIN : Double = 5.0

///|
const STATE_SEPARATOR_MARGIN : Double = 5.0

///|
fn @flow.StateNode::header_height(
  self : @flow.StateNode,
  metrics : @metrics.FontMetrics,
  wrap_width? : Double = 0.0,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> Double {
  STATE_TEXT_MARGIN +
  state_text_size(self.display, metrics, wrap_width~, monospaced_family~).1 +
  STATE_SEPARATOR_MARGIN
}

///|
fn @flow.StateNode::description_size(
  self : @flow.StateNode,
  metrics : @metrics.FontMetrics,
  wrap_width? : Double = 0.0,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> (Double, Double) {
  guard self.description is Some(description) && !description.is_empty() else {
    return (0.0, 0.0)
  }
  state_text_size(description, metrics, wrap_width~, monospaced_family~)
}

///|
/// InnerStateAutonom adds a field margin only for nonempty descriptions.
fn @flow.StateNode::description_compartment_height(
  self : @flow.StateNode,
  metrics : @metrics.FontMetrics,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> Double {
  let height = self.description_size(metrics, monospaced_family~).1
  if height > 0.0 {
    height + STATE_TEXT_MARGIN
  } else {
    0.0
  }
}

///|
fn @flow.StateNode::composite_content_y(
  self : @flow.StateNode,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> Double {
  self.header_height(name_metrics, monospaced_family~) +
  self.description_compartment_height(description_metrics, monospaced_family~) +
  STATE_SEPARATOR_MARGIN
}

///|
/// InnerStateAutonom.calculateDimension merges name, attributes, and inner
/// image vertically, then adds the same margins to both dimensions.
fn @flow.StateNode::composite_size(
  self : @flow.StateNode,
  child : StateFragment,
  name_metrics : @metrics.FontMetrics,
  description_metrics : @metrics.FontMetrics,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> (Double, Double) {
  let name = state_text_size(self.display, name_metrics, monospaced_family~)
  let description = self.description_size(
    description_metrics,
    monospaced_family~,
  )
  let field_margin = if description.1 > 0.0 { STATE_TEXT_MARGIN } else { 0.0 }
  let padding = 2.0 * (STATE_TEXT_MARGIN + STATE_SEPARATOR_MARGIN) +
    field_margin
  (
    name.0.max(description.0).max(child.width) + padding,
    name.1 + description.1 + child.height + padding,
  )
}

///|
/// Place text from its measured top rather than a fixed baseline correction.
/// Previously verified for plain text: title/description alignment, natural
/// alignment overrides, multiline header spacing and local stereotype styles.
/// This record does not cover the later inline font-family extension.
fn append_state_text_at_top(
  output : @graphics.Graphic,
  text : String,
  x : Double,
  top : Double,
  class_name : String,
  metrics : @metrics.FontMetrics,
  anchor? : @graphics.TextAnchor = Middle,
  line_alignment? : @graphics.TextAnchor? = None,
  state? : @flow.StateNode? = None,
  wrap_width? : Double = 0.0,
  data? : Array[(String, String)] = [],
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
  literal_newlines? : Bool = false,
) -> Unit {
  let metadata = {
    ..state_class(class_name),
    data: [..state.map_or([], state => [("state-code", state.code)]), ..data],
  }
  if state_rich_text(
      text,
      metrics,
      wrap_width,
      monospaced_family~,
      literal_newlines~,
    )
    is Some(rich) {
    rich.draw(output, x, top, metrics, metadata, anchor, line_alignment)
    return
  }
  let display = state_display(text, literal_newlines~).wrap(metrics, wrap_width)
  let (x, anchor) = display.anchor_position(x, anchor, metrics, line_alignment~)
  output.draw(
    TextBlock(
      @svg.layout_multiline_text(
        x,
        top + metrics.ascent.to_double(),
        display.text,
        line_height=metrics.line_height.to_double(),
        anchor=Baseline,
        text_anchor=anchor,
        text_metrics=Some(metrics),
      ),
    ),
    metadata~,
  )
}

///|
/// Leaf names inherit the state alignment; InnerStateAutonom names inherit
/// the centered name style. Explicit default alignment overrides either.
fn state_text_alignment(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  fallback? : @graphics.TextAnchor = Start,
) -> @graphics.TextAnchor {
  state_style_property(state, style, "DefaultTextAlignment")
  .bind(parse_state_text_alignment)
  .unwrap_or(fallback)
}

///|
fn parse_state_text_alignment(value : String) -> @graphics.TextAnchor? {
  match value.to_lower() {
    "left" => Some(Start)
    "center" => Some(Middle)
    "right" => Some(End)
    _ => None
  }
}

///|
/// SkinParam.getHorizontalAlignment receives no arrow direction for state
/// messages or notes. "first" resolves left; unrecognized direction values
/// fall back to defaultTextAlignment and then the role's default.
fn state_skinparam_alignment(
  style : @style.DocumentStyle,
  key : String,
  fallback : @graphics.TextAnchor,
) -> @graphics.TextAnchor {
  let value = style.property(key).unwrap_or("").to_lower()
  if value == "first" {
    Start
  } else {
    parse_state_text_alignment(value).unwrap_or_else(() => {
      style
      .property("DefaultTextAlignment")
      .bind(parse_state_text_alignment)
      .unwrap_or(fallback)
    })
  }
}

///|
/// HorizontalAlignment.draw positions the description within the state.
/// Display's natural alignment can then align its lines inside that block.
fn append_state_description(
  output : @graphics.Graphic,
  state : @flow.StateNode,
  layout : StateNodeLayout,
  top : Double,
  style : @style.DocumentStyle,
  metrics : @metrics.FontMetrics,
  wrap_width? : Double = 0.0,
  align_within_state? : Bool = true,
) -> Unit {
  guard state.description is Some(text) && !text.is_empty() else { return }
  let alignment = state_text_alignment(state, style)
  let anchor = if align_within_state {
    alignment
  } else {
    @graphics.TextAnchor::Start
  }
  let x = layout.x +
    STATE_TEXT_MARGIN +
    state_text_anchor_offset(anchor, layout.width - 2.0 * STATE_TEXT_MARGIN)
  append_state_text_at_top(
    output,
    text,
    x,
    top,
    "state-description-label",
    metrics,
    anchor~,
    line_alignment=Some(alignment),
    state=Some(state),
    wrap_width~,
    monospaced_family=state_monospaced_family(style),
  )
}

///|
/// EntityImageEmptyPackage adds this margin to its merged title/stereotype.
const STATE_PACKAGE_MARGIN : Double = 10.0

///|
fn state_frame_stereotype(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  guard state.stereotype is Some(group) else { return "" }
  let delimiters = style.property("Guillemet").unwrap_or("")
  let (left, right) = match delimiters.to_lower() {
    "false" | "<< >>" => ("<<", ">>")
    "none" => ("", "")
    _ => {
      let cursor = @tokenizer.Cursor::new(delimiters)
      let first = cursor.take_while(char => char != ' ')
      cursor.skip_inline_spaces()
      let second = cursor.take_while(char => char != ' ')
      if first.is_empty() || second.is_empty() {
        ("«", "»")
      } else {
        (first, second)
      }
    }
  }
  let cursor = @tokenizer.Cursor::new(group)
  let labels : Array[String] = []
  while !cursor.is_eof() {
    cursor.skip_inline_spaces()
    guard cursor.take_stereotype_value() is Some(label) else { break }
    let text = label[2:label.length() - 2].to_owned()
    labels.push(left + text.trim().to_owned() + right)
  }
  labels.join("\n")
}

///|
fn state_frame_stereotype_size(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  role : StateFontRole,
) -> (Double, Double) {
  let text = state_frame_stereotype(state, style)
  guard !text.is_empty() else { return (0.0, 0.0) }
  let size = state_text_size(
    text,
    resolve_state_font(style, role, state=Some(state)).metrics,
    monospaced_family=state_monospaced_family(style),
  )
  // EntityImageEmptyPackage wraps its stereotype in a one-point side margin.
  (size.0 + (if role is PackageStereotype { 2.0 } else { 0.0 }), size.1)
}
