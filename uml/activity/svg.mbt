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
  output : @svg.XmlWriter,
  x : Int,
  y : Int,
  label : String,
  font_metrics : @metrics.FontMetrics,
  anchor? : String = "middle",
  multiline_center? : Bool = true,
) -> Unit {
  output.raw(
    @svg.multiline_text_markup(
      x.to_double(),
      y.to_double(),
      label,
      [
        ("text-anchor", anchor),
        ("class", "activity-label"),
        ("font-size", font_metrics.font_size.to_string()),
      ],
      line_height=font_metrics.line_height.to_double(),
      anchor=if multiline_center { Center } else { Baseline },
      text_metrics=Some(font_metrics),
    ),
  )
}

///|
fn append_edge(
  output : @svg.XmlWriter,
  layout : ActivityLayout,
  edge : ActivityEdgeLayout,
  small_metrics : @metrics.FontMetrics,
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
  let path = if from_is_fork || to_is_fork {
    let drop_x = if from_is_fork { target_x } else { x }
    "M \{drop_x} \{y1} V \{y2}"
  } else {
    match edge.route {
      Forward =>
        if from_is_decision && target_x != x {
          let start_x = if target_x < x { from.x } else { from.x + from.width }
          "M \{start_x} \{from_center_y} H \{target_x} V \{y2}"
        } else if from_is_decision {
          "M \{x} \{y1} V \{y1 + 12} H \{target_x} V \{y2}"
        } else {
          let middle_y = (y1 + y2) / 2
          "M \{x} \{y1} V \{middle_y} H \{target_x} V \{y2}"
        }
      Horizontal =>
        "M \{from.x + from.width} \{from.y + from.height / 2} H \{to.x}"
      Goto => "M \{from.x} \{from.y} H \{to.x} V \{to.y}"
      BackwardLeft => {
        let route_x = from.x.min(to.x) - WHILE_BACK_MARGIN
        "M \{x} \{y1} H \{route_x} V \{y2 - 8} H \{target_x} V \{y2}"
      }
      BackwardRight => {
        let route_x = (from.x + from.width).max(to.x + to.width) +
          WHILE_BACK_MARGIN
        if from_is_decision {
          "M \{from.x + from.width} \{from_center_y} H \{route_x} V \{to.y + to.height / 2}"
        } else {
          "M \{x} \{y1} V \{y1 + 10} H \{route_x} V \{from_center_y} H \{from.x + from.width}"
        }
      }
      IfDownLeft => "M \{from.x} \{from_center_y} H \{target_x} V \{y2}"
      IfDownRight =>
        "M \{from.x + from.width} \{from_center_y} H \{target_x} V \{y2}"
      SwitchLeft => "M \{from.x} \{from_center_y} H \{target_x} V \{y2}"
      SwitchRight =>
        "M \{from.x + from.width} \{from_center_y} H \{target_x} V \{y2}"
      SwitchMiddle => "M \{x} \{y1} V \{y1 + 12} H \{target_x} V \{y2}"
      WhileExitLeft => {
        let route_x = from.x.min(to.x) - WHILE_BACK_MARGIN
        "M \{from.x} \{from_center_y} H \{route_x} V \{to.y - VERTICAL_GAP} H \{target_x} V \{to.y}"
      }
    }
  }
  output.empty("path", attributes=[
    ("d", path),
    ("class", "activity-edge"),
    (
      "data-route",
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
    ("marker-end", "url(#activity-arrow)"),
  ])
  match edge.label {
    Some(label) => {
      let (label_x, label_y, anchor) = match edge.route {
        Forward =>
          if from_is_decision && target_x != x {
            (target_x + 4, y1 + 11, "start")
          } else if from_is_decision {
            (target_x + 4, y1 + 11, "start")
          } else {
            (x + 4, y1 + 21, "start")
          }
        Horizontal =>
          (
            (from.x + from.width + to.x) / 2,
            from.y + from.height / 2 - 4,
            "middle",
          )
        Goto => ((from.x + to.x) / 2, (from.y + to.y) / 2, "middle")
        BackwardLeft =>
          (from.x.min(to.x) - WHILE_BACK_MARGIN, (y1 + y2) / 2, "middle")
        BackwardRight => {
          let route_x = (from.x + from.width).max(to.x + to.width) +
            WHILE_BACK_MARGIN
          (route_x, (y1 + y2) / 2, "middle")
        }
        IfDownLeft => {
          let width = small_metrics.measure(label).width
          (from.x - width, from_center_y - 2, "end")
        }
        IfDownRight => (from.x + from.width, from_center_y - 2, "start")
        SwitchLeft | SwitchRight | SwitchMiddle => (target_x, y2 - 20, "start")
        WhileExitLeft => {
          let width = small_metrics.measure(label).width
          (from.x - width, from_center_y - 2, "end")
        }
      }
      append_label(
        output,
        label_x,
        label_y,
        label,
        small_metrics,
        anchor=match anchor {
          "start" => "start"
          "end" => "end"
          _ => "middle"
        },
        multiline_center=false,
      )
    }
    None => ()
  }
}

///|
fn append_region(
  output : @svg.XmlWriter,
  region : ActivityRegionLayout,
  font_metrics : @metrics.FontMetrics,
) -> Unit {
  let class = match region.kind {
    ActivityRegionKind::Partition => "activity-partition"
    ActivityRegionKind::Swimlane => "activity-swimlane"
  }
  output.empty("rect", attributes=[
    ("x", region.x.to_string()),
    ("y", region.y.to_string()),
    ("width", region.width.to_string()),
    ("height", region.height.to_string()),
    ("class", class),
  ])
  append_label(
    output,
    region.x + region.width / 2,
    region.y + REGION_HEADER_HEIGHT / 2 + 4,
    region.label,
    font_metrics,
  )
}

///|
fn append_node(
  output : @svg.XmlWriter,
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
  output.open("g", attributes=[
    ("class", "activity-node"),
    ("data-node-index", node_layout.node_index.to_string()),
  ])
  match node {
    Start =>
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (height / 2).to_string()),
        ("class", "activity-start"),
      ])
    Stop | End | Kill => {
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (height / 2).to_string()),
        ("class", "activity-stop-outer"),
      ])
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", STOP_INNER.to_string()),
        ("class", "activity-stop-inner"),
      ])
    }
    _ if node.is_fork() =>
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("rx", "2"),
        ("class", "activity-fork"),
      ])
    _ if node.is_exit() =>
      output.empty("path", attributes=[
        (
          "d",
          "M \{center_x} \{y} L \{x + width} \{center_y} L \{center_x} \{y + height} L \{x} \{center_y} Z",
        ),
        ("class", "activity-exit"),
      ])
    _ if node.is_decision() => {
      output.empty("path", attributes=[
        (
          "d",
          "M \{center_x} \{y} L \{x + width} \{center_y} L \{center_x} \{y + height} L \{x} \{center_y} Z",
        ),
        ("class", "activity-decision"),
      ])
      if node.label() is Some(label) {
        append_label(output, center_x, center_y + 4, label, small_metrics)
      }
    }
    Note(label) => {
      output.empty("path", attributes=[
        (
          "d",
          "M \{x} \{y} H \{x + width - 12} L \{x + width} \{y + 12} V \{y + height} H \{x} Z",
        ),
        ("class", "activity-note"),
      ])
      append_label(output, center_x, center_y + 4, label, font_metrics)
    }
    Action(label) => {
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("rx", BOX_ROUND.to_string()),
        ("class", "activity-action"),
      ])
      append_label(output, center_x, center_y + 4, label, font_metrics)
    }
    Arrow(_) | Label(_) | Goto(_) | Swimlane(_) | Partition(_) | EndPartition =>
      ()
    _ =>
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", "4"),
        ("class", "activity-merge"),
      ])
  }
  output.close()
}

///|
/// Render a parsed activity diagram with the built-in, non-Graphviz layout.
pub fn ActivityDiagram::render_svg(
  self : ActivityDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme), }
  let layout = self.layout()
  let output = @svg.XmlWriter::new()
  let family = self.style.font_family()
  let font_metrics = self.style.font_metrics_for(family, font_size=ACTION_FONT)
  let small_metrics = self.style.font_metrics_for(family, font_size=SMALL_FONT)
  let defaults = self.style.defaults()
  let line = self.style.diagram_line_color()
  let text = self.style.diagram_text_color()
  output.open("svg", attributes=[
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", layout.width.to_string()),
    ("height", layout.height.to_string()),
    ("viewBox", "0 0 \{layout.width} \{layout.height}"),
    ("role", "img"),
    ("aria-label", "Activity diagram"),
  ])
  output.open("style")
  output.raw(
    "svg{font-family:" +
    self.style.font_family() +
    ";font-size:" +
    self.style.font_size() +
    ";background:" +
    self.style.canvas_color() +
    "}.activity-edge{fill:none;stroke:" +
    line +
    ";stroke-width:" +
    @svg.emphasized_stroke_width() +
    "}.activity-label{fill:" +
    text +
    "}.activity-partition,.activity-swimlane{fill:" +
    defaults.partition +
    ";stroke:" +
    line +
    ";stroke-width:" +
    @svg.emphasized_stroke_width() +
    "}.activity-swimlane{stroke-dasharray:" +
    @svg.separator_dash_pattern() +
    "}.activity-start,.activity-stop-inner,.activity-fork,.activity-merge{fill:" +
    line +
    "}.activity-stop-outer,.activity-action,.activity-decision,.activity-exit{fill:" +
    defaults.node +
    ";stroke:" +
    line +
    ";stroke-width:" +
    @svg.emphasized_stroke_width() +
    "}.activity-note{fill:" +
    defaults.note +
    ";stroke:" +
    line +
    ";stroke-width:" +
    @svg.emphasized_stroke_width() +
    "}",
  )
  output.close()
  output.open("defs")
  output.open("marker", attributes=[
    ("id", "activity-arrow"),
    ("markerWidth", "8"),
    ("markerHeight", "8"),
    ("refX", "6"),
    ("refY", "3"),
    ("orient", "auto"),
    ("markerUnits", "strokeWidth"),
  ])
  output.empty("path", attributes=[("d", "M 0 0 L 6 3 L 0 6 Z"), ("fill", line)])
  output.close()
  output.close()
  output.empty("rect", attributes=[
    ("x", "0"),
    ("y", "0"),
    ("width", layout.width.to_string()),
    ("height", layout.height.to_string()),
    ("fill", self.style.canvas_color()),
  ])
  layout.regions.each(region => append_region(output, region, font_metrics))
  layout.edges.each(edge => append_edge(output, layout, edge, small_metrics))
  layout.nodes.each(node => {
    append_node(output, layout, node, font_metrics, small_metrics)
  })
  output.close()
  output.to_string()
}
