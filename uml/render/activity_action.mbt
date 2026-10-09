///|
/// BoxStyle.java dimensions; getShield belongs to FtileGeometry as well as paint.
const ACTIVITY_BOX_SHIELD : Double = 10.0

///|
const ACTIVITY_PROCEDURE_INSET : Double = 5.0

///|
const ACTIVITY_CONTINUOUS_INSET : Double = 5.0

///|
fn activity_box_style(action : @flow.ActivityAction) -> String {
  if action.box_style is Some(box) {
    return box
  }
  let cursor = @tokenizer.Cursor::new(action.stereotype.unwrap_or(""))
  while cursor.take_stereotype_value() is Some(label) {
    let label = label[2:label.length() - 2]
      .trim()
      .to_lower()
      .to_owned()
      .replace_all(old="-", new="")
    if [
        "input", "output", "procedure", "load", "save", "continuous", "task", "object",
        "objectsignal", "trigger", "sendsignal", "acceptevent", "timeevent",
      ].contains(label) {
      return label
    }
    cursor.skip_inline_spaces()
  }
  "plain"
}

///|
fn activity_box_shield(action : @flow.ActivityAction) -> Double {
  if [
      "input", "output", "objectsignal", "trigger", "sendsignal", "acceptevent",
      "timeevent",
    ].contains(activity_box_style(action)) {
    ACTIVITY_BOX_SHIELD
  } else {
    0.0
  }
}

///|
fn activity_action_style(action : @flow.ActivityAction) -> @style.DocumentStyle {
  let style = action.style
    .with_stereotypes(action.stereotype)
    .with_color_scheme(action.style.defaults())
  let cursor = @tokenizer.Cursor::new(action.stereotype.unwrap_or(""))
  while cursor.take_stereotype_value() is Some(label) {
    let label = label[2:label.length() - 2].trim().to_owned()
    if label.has_prefix("###") {
      style.apply(@style.Property("ActivityFontColor", label[3:].to_owned()))
    } else if label.has_prefix("##") {
      let line = @tokenizer.Cursor::new(label[2:].to_owned())
      if line.consume('[') {
        let stroke = line.take_while(char => char != ']')
        if line.consume(']') {
          style.apply(@style.Property("ActivityLineStyle", stroke))
        }
      }
      let color = line.take_rest_trimmed()
      if !color.is_empty() {
        style.apply(@style.Property("ActivityBorderColor", color))
      }
    } else if label.has_prefix("#") {
      for
        (kind, key) in [
          ("back", "ActivityBackgroundColor"),
          ("line", "ActivityBorderColor"),
          ("text", "ActivityFontColor"),
        ] {
        if state_inline_color(Some(label), kind) is Some(color) {
          style.apply(@style.Property(key, color))
        }
      }
    }
    cursor.skip_inline_spaces()
  }
  style
}

///|
fn activity_action_geometry(
  style : @style.DocumentStyle,
) -> @tree.TreeNodeStyle {
  let mut geometry = @tree.TreeNodeStyle::empty().with_property(
    "Padding",
    TEXT_PADDING.to_string(),
  )
  for name in ["Padding", "MinimumWidth", "RoundCorner", "MaximumWidth"] {
    if style.property("Activity" + name) is Some(value) {
      geometry = geometry.with_property(name, value)
    }
  }
  geometry
}

///|
fn activity_action_measure(action : @flow.ActivityAction) -> TileMeasure {
  let style = activity_action_style(action)
  let geometry = activity_action_geometry(style)
  let metrics = activity_font_metrics(style, false)
  let (width, height) = state_text_size(
    action.label,
    metrics,
    wrap_width=geometry.wrap_width.unwrap_or(0.0),
  )
  {
    width: (width +
    geometry.padding_left.unwrap_or(TEXT_PADDING) +
    geometry.padding_right.unwrap_or(TEXT_PADDING)).max(
      geometry.minimum_width.unwrap_or(0.0),
    ) +
    activity_box_shield(action),
    height: height +
    geometry.padding_top.unwrap_or(TEXT_PADDING) +
    geometry.padding_bottom.unwrap_or(TEXT_PADDING),
  }
}

///|
fn @flow.ActivityNode::flow_axis(
  self : @flow.ActivityNode,
  width : Double,
) -> Double {
  (
    width -
    (if self is (StyledAction(action) | RepeatAction(action)) {
      activity_box_shield(action)
    } else {
      0.0
    })
  ) /
  2.0
}

///|
fn draw_activity_action(
  output : @graphics.Graphic,
  action : @flow.ActivityAction,
  node : ActivityNodeLayout,
) -> Unit {
  let style = activity_action_style(action)
  let geometry = activity_action_geometry(style)
  let box = activity_box_style(action)
  let width = node.width - activity_box_shield(action)
  let height = node.height
  let delta = ACTIVITY_BOX_SHIELD
  let point = (x : Double, y : Double) => @graphics.Point::{ x, y, }
  let shape : @graphics.Shape = match box {
    "input" | "trigger" =>
      Polygon([
        point(0, 0),
        point(width + delta, 0),
        point(width, height / 2),
        point(width + delta, height),
        point(0, height),
      ])
    "output" | "sendsignal" =>
      Polygon([
        point(0, 0),
        point(width, 0),
        point(width + delta, height / 2),
        point(width, height),
        point(0, height),
      ])
    "load" =>
      Polygon([
        point(0, 0),
        point(width - delta, 0),
        point(width, height),
        point(delta, height),
      ])
    "save" =>
      Polygon([
        point(delta, 0),
        point(width, 0),
        point(width - delta, height),
        point(0, height),
      ])
    "objectsignal" =>
      Polygon([
        point(-delta, 0),
        point(width, 0),
        point(width + delta, height / 2),
        point(width, height),
        point(-delta, height),
        point(0, height / 2),
      ])
    "acceptevent" =>
      Polygon([
        point(-delta, 0),
        point(width, 0),
        point(width, height),
        point(-delta, height),
        point(0, height / 2),
      ])
    "timeevent" =>
      Polygon([
        point(width / 2 - height / 3, height / 3),
        point(width / 2 + height / 3, height / 3),
        point(width / 2 - height / 3, height),
        point(width / 2 + height / 3, height),
      ])
    "continuous" =>
      Path([
        MoveTo(point(ACTIVITY_CONTINUOUS_INSET, 0)),
        LineTo(point(0, height / 2)),
        LineTo(point(ACTIVITY_CONTINUOUS_INSET, height)),
        MoveTo(point(width - ACTIVITY_CONTINUOUS_INSET, 0)),
        LineTo(point(width, height / 2)),
        LineTo(point(width - ACTIVITY_CONTINUOUS_INSET, height)),
      ])
    _ =>
      Rectangle(
        origin=point(0, 0),
        width~,
        height~,
        rx=if box == "plain" {
          Some(geometry.round_corner.unwrap_or(LEGACY_ACTIVITY_CORNER) / 2.0)
        } else {
          None
        },
        ry=None,
      )
  }
  let stroke = @svg.line_drawing_style(style.property("ActivityLineStyle"))
  let paint : @graphics.DrawingStyle = {
    ..stroke,
    stroke: Color(
      style.property_color("ActivityBorderColor", style.diagram_line_color()),
    ),
    fill: if box == "continuous" {
      None
    } else {
      Color(
        style.property_color("ActivityBackgroundColor", style.defaults().node),
      )
    },
    stroke_width: Some(stroke.stroke_width.unwrap_or(1.5)),
    inline: true,
  }
  let output = output.translated(node.x, node.y)
  output
  .with_style(paint)
  .draw(shape, metadata=activity_class("activity-action"))
  if box == "procedure" {
    for x in [ACTIVITY_PROCEDURE_INSET, width - ACTIVITY_PROCEDURE_INSET] {
      output
      .with_style({ ..paint, fill: None, })
      .draw(Line(point(x, 0), point(x, height)))
    }
  }
  let font = activity_font_metrics(style, false)
  let color = style.property_color(
    "ActivityFontColor",
    style.diagram_text_color(),
  )
  let alignment = style
    .property("ActivityHorizontalAlignment")
    .unwrap_or("center")
    .to_lower()
  let (x, anchor) = match alignment {
    "left" =>
      (
        geometry.padding_left.unwrap_or(TEXT_PADDING),
        @graphics.TextAnchor::Start,
      )
    "right" =>
      (
        node.width - geometry.padding_right.unwrap_or(TEXT_PADDING),
        @graphics.TextAnchor::End,
      )
    _ => (node.width / 2.0, @graphics.TextAnchor::Middle)
  }
  append_state_text_at_top(
    output.with_style({
      ..Default::default(),
      fill: Color(color),
      inline: true,
    }),
    action.label,
    x,
    geometry.padding_top.unwrap_or(TEXT_PADDING),
    "activity-label",
    font,
    anchor~,
    wrap_width=geometry.wrap_width.unwrap_or(0.0),
    font_family=Some(style.property_font_family("ActivityFontName")),
  )
}
