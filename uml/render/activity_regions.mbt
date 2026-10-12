///|
/// FtileCircleSpot.SIZE and FtileGroup's horizontal margin, bottom margin,
/// and minimum title band. Keep measuring and painting on the same constants.
const ACTIVITY_SPOT_SIZE : Double = 20.0

///|
const ACTIVITY_GROUP_MARGIN : Double = 10.0

///|
const ACTIVITY_GROUP_BOTTOM : Double = 20.0

///|
const ACTIVITY_GROUP_MIN_HEADER : Double = 25.0

///|
fn activity_lane(
  nodes : Array[@flow.ActivityNode],
  name : String,
) -> @flow.ActivitySwimlane {
  let mut result : @flow.ActivitySwimlane = { name, label: None, color: None, }
  for node in nodes {
    guard node is @flow.Swimlane(lane) && lane.name == name else { continue }
    result = {
      ..result,
      label: lane.label.map_or(result.label, value => Some(value)),
      color: lane.color.map_or(result.color, value => Some(value)),
    }
  }
  result
}

///|
fn activity_group_role(group : @flow.ActivityGroup) -> String {
  match group.symbol {
    "package" => "Package"
    "rectangle" => "Rectangle"
    "card" => "Card"
    "group" => "Group"
    _ => "Partition"
  }
}

///|
fn activity_role_metrics(
  style : @style.DocumentStyle,
  role : String,
  size : Int32,
) -> @metrics.FontMetrics {
  let face = style.property(role + "FontStyle").unwrap_or("").to_lower()
  style.font_metrics_for(
    style.property(role + "FontName").unwrap_or(style.font_family()),
    font_size=style.property_font_size(role + "FontSize", fallback=size),
    font_weight=if face.contains("bold") { 700 } else { 400 },
    font_style=if face.contains("italic") { Italic } else { Normal },
  )
}

///|
fn activity_partition_title(
  node : @flow.ActivityNode,
  _metrics : @metrics.FontMetrics,
) -> TileMeasure {
  guard node is @flow.Partition(group) else { return { width: 0, height: 0, } }
  let style = group.style.with_stereotypes(group.stereotype)
  activity_measure(
    activity_role_metrics(style, activity_group_role(group), 14),
    group.label,
  )
}

///|
/// FtileGroup delegates its outline to USymbolFrame, USymbolFolder,
/// USymbolRectangle or USymbolCard. This paints those vector primitives only.
fn draw_activity_group(
  output : @graphics.Graphic,
  region : ActivityRegionLayout,
  group : @flow.ActivityGroup,
) -> Unit {
  let style = group.style.with_stereotypes(group.stereotype)
  let role = activity_group_role(group)
  let font = activity_role_metrics(style, role, 14)
  let title = activity_measure(font, region.label)
  let graphic = output
    .translated(region.x, region.y)
    .with_style({
      ..Default::default(),
      fill: Color(
        @svg.svg_color(
          group.color,
          style.property_color(role + "BackgroundColor", "transparent"),
        ),
      ),
      stroke: Color(
        style.property_color(role + "BorderColor", style.diagram_line_color()),
      ),
      stroke_width: Some(
        activity_style_number(style, role + "BorderThickness", 1.5),
      ),
      inline: true,
    })
  let point = (x, y) => activity_point(x, y)
  let width = region.width
  let height = region.height
  let mut title_x = 3.0
  let mut title_y = 1.0
  if group.symbol == "package" {
    let tab_width = if title.width == 0 {
      (width / 4).max(30)
    } else {
      title.width + 6
    }
    let tab_height = if title.width == 0 { 10.0 } else { title.height + 6 }
    let radius = activity_style_number(style, role + "RoundCorner", 0.0) / 2
    let shape : @graphics.Shape = if radius == 0 {
      Polygon([
        point(0, 0),
        point(tab_width, 0),
        point(tab_width + 7, tab_height),
        point(width, tab_height),
        point(width, height),
        point(0, height),
      ])
    } else {
      Path([
        MoveTo(point(radius, 0)),
        LineTo(point(tab_width - radius, 0)),
        ArcTo(
          rx=radius * 1.5,
          ry=radius * 1.5,
          rotation=0,
          large_arc=false,
          sweep=true,
          end=point(tab_width, radius),
        ),
        LineTo(point(tab_width + 7, tab_height)),
        LineTo(point(width - radius, tab_height)),
        ArcTo(
          rx=radius,
          ry=radius,
          rotation=0,
          large_arc=false,
          sweep=true,
          end=point(width, tab_height + radius),
        ),
        LineTo(point(width, height - radius)),
        ArcTo(
          rx=radius,
          ry=radius,
          rotation=0,
          large_arc=false,
          sweep=true,
          end=point(width - radius, height),
        ),
        LineTo(point(radius, height)),
        ArcTo(
          rx=radius,
          ry=radius,
          rotation=0,
          large_arc=false,
          sweep=true,
          end=point(0, height - radius),
        ),
        LineTo(point(0, radius)),
        ArcTo(
          rx=radius,
          ry=radius,
          rotation=0,
          large_arc=false,
          sweep=true,
          end=point(radius, 0),
        ),
        Close,
      ])
    }
    graphic.draw(shape, metadata=activity_class("activity-partition-package"))
    graphic.draw(Line(point(0, tab_height), point(tab_width + 7, tab_height)))
    title_x = 4
    title_y = 2
  } else {
    let radius = activity_style_number(style, role + "RoundCorner", 0.0) / 2
    graphic.draw(
      Rectangle(origin=point(0, 0), width~, height~, rx=Some(radius), ry=None),
      metadata=activity_class("activity-partition-" + group.symbol),
    )
    if group.symbol == "partition" || group.symbol == "group" {
      let tab_width = if title.width == 0 {
        width / 3
      } else {
        title.width + 10
      }
      let corner = if title.width == 0 { 7.0 } else { 10.0 }
      let tab_height = if title.width == 0 { 12.0 } else { title.height + 3 }
      graphic
      .with_style({ ..graphic.drawing_style(), fill: None, })
      .draw(
        Path([
          MoveTo(point(tab_width, 0)),
          LineTo(point(tab_width, tab_height - corner)),
          LineTo(point(tab_width - corner, tab_height)),
          LineTo(point(0, tab_height)),
        ]),
      )
    } else {
      title_x = (width - title.width) / 2
      title_y = 2
      if group.symbol == "card" {
        graphic.draw(
          Line(point(0, title.height + 4), point(width, title.height + 4)),
        )
      }
    }
  }
  append_state_text_at_top(
    graphic.with_style({
      ..Default::default(),
      fill: Color(
        style.property_color(role + "FontColor", style.diagram_text_color()),
      ),
    }),
    region.label,
    title_x,
    title_y,
    "activity-partition-label",
    font,
    font_family=Some(
      style.property(role + "FontName").unwrap_or(style.font_family()),
    ),
    anchor=Start,
  )
}

///|
fn draw_activity_spot(
  output : @graphics.Graphic,
  node : ActivityNodeLayout,
  text : String,
  color : String?,
  style : @style.DocumentStyle,
) -> Unit {
  let center = activity_point(node.x + node.width / 2, node.y + node.height / 2)
  output
  .with_style({
    ..Default::default(),
    fill: Color(
      @svg.svg_color(
        color,
        style.property_color("CircleBackgroundColor", style.defaults().node),
      ),
    ),
    stroke: Color(
      style.property_color("CircleBorderColor", style.diagram_line_color()),
    ),
    stroke_width: Some(
      activity_style_number(style, "CircleBorderThickness", 1.5),
    ),
    inline: true,
  })
  .draw(
    Circle(center~, radius=ACTIVITY_SPOT_SIZE / 2),
    metadata=activity_class("activity-spot"),
  )
  let font = activity_role_metrics(style, "Circle", 14)
  append_state_text_at_top(
    output.with_style({
      ..Default::default(),
      fill: Color(
        style.property_color("CircleFontColor", style.diagram_text_color()),
      ),
    }),
    text,
    center.x,
    center.y - font.line_height.to_double() / 2,
    "activity-spot-label",
    font,
    font_family=Some(
      style.property("CircleFontName").unwrap_or(style.font_family()),
    ),
    anchor=Middle,
  )
}

///|
fn activity_style_number(
  style : @style.DocumentStyle,
  name : String,
  fallback : Double,
) -> Double {
  style
  .property(name)
  .map_or(fallback, value => @string.parse_double(value) catch { _ => fallback })
}

///|
/// FtileBlackBlock.labelMargin; labels extend the tile without moving its axis.
const ACTIVITY_FORK_LABEL_MARGIN : Double = 5.0

///|
fn activity_fork_label_width(
  node : @flow.ActivityNode,
  metrics : @metrics.FontMetrics,
) -> Double {
  match node {
    @flow.EndFork(Some(label), _) =>
      activity_measure(metrics, label).width + ACTIVITY_FORK_LABEL_MARGIN
    _ => 0.0
  }
}

///|
fn @flow.ActivityNode::activity_decision(
  self : @flow.ActivityNode,
) -> @flow.ActivityDecision? {
  match self {
    If(decision)
    | EndIf(decision)
    | EndSwitch(decision)
    | Repeat(decision)
    | ElseIf(decision)
    | While(decision)
    | RepeatWhile(decision)
    | Switch(decision) => Some(decision)
    _ => None
  }
}

///|
fn activity_decision_style(
  decision : @flow.ActivityDecision,
) -> @style.DocumentStyle {
  let style = decision.style
    .with_stereotypes(decision.stereotype)
    .with_color_scheme(decision.style.defaults())
  if decision.color is Some(color) {
    style.apply(@style.Property("ActivityDiamondBackgroundColor", color))
  }
  let cursor = @tokenizer.Cursor::new(decision.stereotype.unwrap_or(""))
  while cursor.take_stereotype_value() is Some(label) {
    let label = label[2:label.length() - 2].trim().to_owned()
    guard label.has_prefix("#") else {
      cursor.skip_inline_spaces()
      continue
    }
    for
      (kind, suffix) in [
        ("back", "BackgroundColor"),
        ("line", "BorderColor"),
        ("text", "FontColor"),
      ] {
      if state_inline_color(Some(label), kind) is Some(color) {
        style.apply(@style.Property("ActivityDiamond" + suffix, color))
      }
    }
    cursor.skip_inline_spaces()
  }
  style
}

///|
fn activity_decision_metrics(
  decision : @flow.ActivityDecision,
) -> @metrics.FontMetrics {
  activity_role_metrics(
    activity_decision_style(decision),
    "ActivityDiamond",
    SMALL_FONT,
  )
}
