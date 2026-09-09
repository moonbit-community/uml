///|
fn layout_for(layout : ActivityLayout, node_index : Int) -> ActivityNodeLayout? {
  for node in layout.nodes {
    guard node.node_index == node_index else { continue }
    return Some(node)
  }
  None
}

///|
fn append_label(
  output : @graphics.Graphic,
  x : Int,
  y : Int,
  label : String,
  font_metrics : @metrics.FontMetrics,
  anchor? : @graphics.TextAnchor = Middle,
  multiline_anchor? : @svg.MultilineTextAnchor = Center,
) -> Unit {
  output.draw(
    StyledTextBlock(
      @svg.layout_multiline_text(
        x.to_double(),
        y.to_double(),
        label,
        line_height=font_metrics.line_height.to_double(),
        anchor=multiline_anchor,
        text_anchor=anchor,
        text_metrics=Some(font_metrics),
      ),
      {
        ..@graphics.TextStyle::default(),
        font_size: Some(font_metrics.font_size.to_double()),
      },
    ),
    metadata=activity_class("activity-label"),
  )
}

///|
fn append_edge(
  output : @graphics.Graphic,
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
  small_metrics : @metrics.FontMetrics,
  arrow : @graphics.MarkerRef,
) -> Unit {
  guard layout_for(layout, edge.from_node_index) is Some(from) else { return }
  guard layout_for(layout, edge.to_node_index) is Some(to) else { return }
  let x = from.x + from.width / 2
  let y1 = from.y + from.height
  let target_x = to.x + to.width / 2
  let y2 = to.y
  let from_center_y = from.y + from.height / 2
  let from_is_decision = layout.source_nodes[edge.from_node_index].is_decision()
  let from_is_fork = layout.source_nodes[edge.from_node_index].is_fork()
  let to_is_fork = layout.source_nodes[edge.to_node_index].is_fork()
  let path : Array[@graphics.PathSegment] = if from_is_fork || to_is_fork {
    let drop_x = if from_is_fork { target_x } else { x }
    [MoveTo(activity_point(drop_x, y1)), LineTo(activity_point(drop_x, y2))]
  } else {
    match edge.route {
      Forward =>
        if from_is_decision && target_x != x {
          let start_x = if target_x < x { from.x } else { from.x + from.width }
          [
            MoveTo(activity_point(start_x, from_center_y)),
            LineTo(activity_point(target_x, from_center_y)),
            LineTo(activity_point(target_x, y2)),
          ]
        } else if from_is_decision {
          [
            MoveTo(activity_point(x, y1)),
            LineTo(activity_point(x, y1 + 12)),
            LineTo(activity_point(target_x, y1 + 12)),
            LineTo(activity_point(target_x, y2)),
          ]
        } else {
          let middle_y = (y1 + y2) / 2
          [
            MoveTo(activity_point(x, y1)),
            LineTo(activity_point(x, middle_y)),
            LineTo(activity_point(target_x, middle_y)),
            LineTo(activity_point(target_x, y2)),
          ]
        }
      Horizontal =>
        [
          MoveTo(activity_point(from.x + from.width, from.y + from.height / 2)),
          LineTo(activity_point(to.x, from.y + from.height / 2)),
        ]
      Goto =>
        [
          MoveTo(activity_point(from.x, from.y)),
          LineTo(activity_point(to.x, from.y)),
          LineTo(activity_point(to.x, to.y)),
        ]
      BackwardLeft => {
        let route_x = backward_left_route_x(from, to)
        [
          MoveTo(activity_point(x, y1)),
          LineTo(activity_point(route_x, y1)),
          LineTo(activity_point(route_x, y2 - 8)),
          LineTo(activity_point(target_x, y2 - 8)),
          LineTo(activity_point(target_x, y2)),
        ]
      }
      BackwardRight => {
        let route_x = backward_right_route_x(from, to)
        if from_is_decision {
          [
            MoveTo(activity_point(from.x + from.width, from_center_y)),
            LineTo(activity_point(route_x, from_center_y)),
            LineTo(activity_point(route_x, to.y + to.height / 2)),
          ]
        } else {
          [
            MoveTo(activity_point(x, y1)),
            LineTo(activity_point(x, y1 + 10)),
            LineTo(activity_point(route_x, y1 + 10)),
            LineTo(activity_point(route_x, from_center_y)),
            LineTo(activity_point(from.x + from.width, from_center_y)),
          ]
        }
      }
      IfDownLeft =>
        [
          MoveTo(activity_point(from.x, from_center_y)),
          LineTo(activity_point(target_x, from_center_y)),
          LineTo(activity_point(target_x, y2)),
        ]
      IfDownRight =>
        [
          MoveTo(activity_point(from.x + from.width, from_center_y)),
          LineTo(activity_point(target_x, from_center_y)),
          LineTo(activity_point(target_x, y2)),
        ]
      SwitchLeft =>
        [
          MoveTo(activity_point(from.x, from_center_y)),
          LineTo(activity_point(target_x, from_center_y)),
          LineTo(activity_point(target_x, y2)),
        ]
      SwitchRight =>
        [
          MoveTo(activity_point(from.x + from.width, from_center_y)),
          LineTo(activity_point(target_x, from_center_y)),
          LineTo(activity_point(target_x, y2)),
        ]
      SwitchMiddle =>
        [
          MoveTo(activity_point(x, y1)),
          LineTo(activity_point(x, y1 + 12)),
          LineTo(activity_point(target_x, y1 + 12)),
          LineTo(activity_point(target_x, y2)),
        ]
      WhileExitLeft => {
        let route_x = backward_left_route_x(from, to)
        [
          MoveTo(activity_point(from.x, from_center_y)),
          LineTo(activity_point(route_x, from_center_y)),
          LineTo(activity_point(route_x, to.y - VERTICAL_GAP)),
          LineTo(activity_point(target_x, to.y - VERTICAL_GAP)),
          LineTo(activity_point(target_x, to.y)),
        ]
      }
    }
  }
  output.draw(MarkedPath(path, { start: None, end: Some(arrow), }), metadata={
    ..activity_class("activity-edge"),
    data: [
      (
        "route",
        match edge.route {
          Forward => "forward"
          Horizontal => "horizontal"
          Goto => "goto"
          BackwardLeft => "backward-left"
          BackwardRight => "backward-right"
          IfDownLeft => "if-down-left"
          IfDownRight => "if-down-right"
          SwitchLeft => "switch-left"
          SwitchRight => "switch-right"
          SwitchMiddle => "switch-middle"
          WhileExitLeft => "while-exit-left"
        },
      ),
    ],
  })
  if edge.label is Some(label) {
    let (label_x, label_y, anchor) = match edge.route {
      Forward =>
        if from_is_decision && target_x != x {
          (target_x + 4, y1 + 11, @graphics.TextAnchor::Start)
        } else if from_is_decision {
          (target_x + 4, y1 + 11, @graphics.TextAnchor::Start)
        } else {
          (x + 4, y1 + 21, @graphics.TextAnchor::Start)
        }
      Horizontal =>
        (
          (from.x + from.width + to.x) / 2,
          from.y + from.height / 2 - 4,
          @graphics.TextAnchor::Middle,
        )
      Goto =>
        ((from.x + to.x) / 2, (from.y + to.y) / 2, @graphics.TextAnchor::Middle)
      BackwardLeft =>
        (
          from.x.min(to.x) - WHILE_BACK_MARGIN,
          (y1 + y2) / 2,
          @graphics.TextAnchor::Middle,
        )
      BackwardRight => {
        let route_x = (from.x + from.width).max(to.x + to.width) +
          WHILE_BACK_MARGIN
        (route_x, (y1 + y2) / 2, @graphics.TextAnchor::Middle)
      }
      IfDownLeft => {
        let width = small_metrics.measure(label).width
        (from.x - width, from_center_y - 2, @graphics.TextAnchor::End)
      }
      IfDownRight =>
        (from.x + from.width, from_center_y - 2, @graphics.TextAnchor::Start)
      SwitchLeft | SwitchRight | SwitchMiddle =>
        (target_x, y2 - 20, @graphics.TextAnchor::Start)
      WhileExitLeft => {
        let width = small_metrics.measure(label).width
        (from.x - width, from_center_y - 2, @graphics.TextAnchor::End)
      }
    }
    append_label(
      output,
      label_x,
      label_y,
      label,
      small_metrics,
      anchor~,
      multiline_anchor=Baseline,
    )
  }
}

///|
fn append_region(
  output : @graphics.Graphic,
  region : ActivityRegionLayout,
  font_metrics : @metrics.FontMetrics,
) -> Unit {
  let class = match region.kind {
    ActivityRegionKind::Partition => "activity-partition"
    ActivityRegionKind::Swimlane => "activity-swimlane"
  }
  output.draw(
    Rectangle(
      origin=activity_point(region.x, region.y),
      width=region.width.to_double(),
      height=region.height.to_double(),
      rx=None,
      ry=None,
    ),
    metadata=activity_class(class),
  )
  append_label(
    output,
    region.x + region.width / 2,
    region.y + REGION_HEADER_HEIGHT / 2 + 4,
    region.label,
    font_metrics,
  )
}

///|
fn activity_point(x : Int, y : Int) -> @graphics.Point {
  { x: x.to_double(), y: y.to_double(), }
}

///|
fn activity_class(name : String) -> @graphics.Metadata {
  { ..@graphics.Metadata::default(), class_name: Some(name), }
}

///|
fn activity_append_node(
  output : @graphics.Graphic,
  layout : ActivityLayout,
  node_layout : ActivityNodeLayout,
  font_metrics : @metrics.FontMetrics,
  small_metrics : @metrics.FontMetrics,
) -> Unit {
  let node = layout.source_nodes[node_layout.node_index]
  let x = node_layout.x
  let y = node_layout.y
  let width = node_layout.width
  let height = node_layout.height
  let center_x = x + width / 2
  let center_y = y + height / 2
  let center = activity_point(center_x, center_y)
  output.group(
    {
      ..activity_class("activity-node"),
      data: [("node-index", node_layout.node_index.to_string())],
    },
    output => {
      match node {
        Start =>
          output.draw(
            Circle(center~, radius=(height / 2).to_double()),
            metadata=activity_class("activity-start"),
          )
        Stop | End | Kill => {
          output.draw(
            Circle(center~, radius=(height / 2).to_double()),
            metadata=activity_class("activity-stop-outer"),
          )
          output.draw(
            Circle(center~, radius=STOP_INNER.to_double()),
            metadata=activity_class("activity-stop-inner"),
          )
        }
        _ if node.is_fork() =>
          output.draw(
            Rectangle(
              origin=activity_point(x, y),
              width=width.to_double(),
              height=height.to_double(),
              rx=Some(2.0),
              ry=None,
            ),
            metadata=activity_class("activity-fork"),
          )
        _ if node.is_exit() || node.is_decision() => {
          output.draw(
            Path([
              MoveTo(activity_point(center_x, y)),
              LineTo(activity_point(x + width, center_y)),
              LineTo(activity_point(center_x, y + height)),
              LineTo(activity_point(x, center_y)),
              Close,
            ]),
            metadata=activity_class(
              if node.is_exit() {
                "activity-exit"
              } else {
                "activity-decision"
              },
            ),
          )
          if !node.is_exit() && node.label() is Some(label) {
            append_label(output, center_x, center_y + 4, label, small_metrics)
          }
        }
        Note(label) => {
          output.draw(
            Path([
              MoveTo(activity_point(x, y)),
              LineTo(activity_point(x + width - 12, y)),
              LineTo(activity_point(x + width, y + 12)),
              LineTo(activity_point(x + width, y + height)),
              LineTo(activity_point(x, y + height)),
              Close,
            ]),
            metadata=activity_class("activity-note"),
          )
          append_label(output, center_x, center_y + 4, label, font_metrics)
        }
        Action(label) => {
          output.draw(
            Rectangle(
              origin=activity_point(x, y),
              width=width.to_double(),
              height=height.to_double(),
              rx=Some(BOX_ROUND.to_double()),
              ry=None,
            ),
            metadata=activity_class("activity-action"),
          )
          append_label(output, center_x, center_y + 4, label, font_metrics)
        }
        Arrow(_)
        | Label(_)
        | Goto(_)
        | Swimlane(_)
        | Partition(_)
        | EndPartition => ()
        _ =>
          output.draw(
            Circle(center~, radius=4.0),
            metadata=activity_class("activity-merge"),
          )
      }
    },
  )
}

///|
const ACTIVITY_ARROW_SIZE : Double = 8.0

///|
const ACTIVITY_ARROW_EXTENT : Double = 6.0

///|
const ACTIVITY_ARROW_MIDDLE : Double = ACTIVITY_ARROW_EXTENT / 2.0

///|
/// Preserve the activity marker's original viewport and reference point.
/// A viewBox equal to its viewport is the original identity mapping.
fn define_activity_arrow(
  document : @svg.SvgDocument,
  fill : String,
) -> @graphics.MarkerRef {
  document.define_marker(
    "activity-arrow",
    {
      origin: { x: 0.0, y: 0.0, },
      viewport: { width: ACTIVITY_ARROW_SIZE, height: ACTIVITY_ARROW_SIZE, },
      reference: { x: ACTIVITY_ARROW_EXTENT, y: ACTIVITY_ARROW_MIDDLE, },
      size: { width: ACTIVITY_ARROW_SIZE, height: ACTIVITY_ARROW_SIZE, },
      orientation: Auto,
      units: StrokeWidth,
    },
    output => {
      output
      .with_style({ ..@graphics.DrawingStyle::default(), fill: Color(fill), })
      .draw(
        Path([
          MoveTo({ x: 0.0, y: 0.0, }),
          LineTo({ x: ACTIVITY_ARROW_EXTENT, y: ACTIVITY_ARROW_MIDDLE, }),
          LineTo({ x: 0.0, y: ACTIVITY_ARROW_EXTENT, }),
          Close,
        ]),
      )
    },
  )
}

///|
/// Render a parsed activity diagram with the built-in, non-Graphviz layout.
fn @flow.ActivityDiagram::render_svg(
  self : @flow.ActivityDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme), }
  let layout = self.layout()
  let document = @svg.SvgDocument::empty(
    layout.width,
    layout.height,
    "Activity diagram",
  )
  let family = self.style.font_family()
  let font_metrics = self.style.font_metrics_for(family, font_size=ACTION_FONT)
  let small_metrics = self.style.font_metrics_for(family, font_size=SMALL_FONT)
  let defaults = self.style.defaults()
  let line = self.style.diagram_line_color()
  let text = self.style.diagram_text_color()
  let emphasized_width = @svg.emphasized_stroke_width()
  document.stylesheet(
    (
      $|\{@svg.svg_style_rule(self.style.font_family(), self.style.font_size(), self.style.canvas_color())}
      $|.activity-edge{fill:none;stroke:\{line};stroke-width:\{emphasized_width}}
      $|.activity-label{fill:\{text}}
      $|.activity-partition,.activity-swimlane{fill:\{defaults.partition};stroke:\{line};stroke-width:\{emphasized_width}}
      $|.activity-swimlane{stroke-dasharray:\{@svg.separator_dash_pattern()}}
      $|.activity-start,.activity-stop-inner,.activity-fork,.activity-merge{fill:\{line}}
      $|.activity-stop-outer,.activity-action,.activity-decision,.activity-exit{fill:\{defaults.node};stroke:\{line};stroke-width:\{emphasized_width}}
      $|.activity-note{fill:\{defaults.note};stroke:\{line};stroke-width:\{emphasized_width}},
    ),
  )
  let arrow = define_activity_arrow(document, line)
  let output = document.graphic()
  output
  .with_style({
    ..@graphics.DrawingStyle::default(),
    fill: Color(self.style.canvas_color()),
  })
  .draw(
    Rectangle(
      origin=activity_point(0, 0),
      width=layout.width.to_double(),
      height=layout.height.to_double(),
      rx=None,
      ry=None,
    ),
  )
  layout.regions.each(region => append_region(output, region, font_metrics))
  layout.edges.each(edge => {
    append_edge(output, layout, edge, small_metrics, arrow)
  })
  layout.nodes.each(node => {
    activity_append_node(output, layout, node, font_metrics, small_metrics)
  })
  document.to_string()
}

///|
/// Render a parsed activity diagram to SVG.
pub fn render_activity_svg(
  diagram : @flow.ActivityDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  diagram.render_svg(color_scheme~)
}
