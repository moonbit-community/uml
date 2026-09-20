// Port images and the cluster frontier adjustment that attaches their centers.

///|
/// `EntityImagePort`: a fixed 12x12 square whose label sits above or below
/// depending on the port position inside its parent cluster.
fn EntityPaintContext::append_port(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let diagram = self.diagram
  let text_metrics = self.text_metrics
  let output = self.output
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let up = match layout.graphviz {
    Some(graphviz) => {
      let mut result = false
      for package_layout in graphviz.packages {
        guard package_layout.package_index < diagram.packages.length() else {
          continue
        }
        if diagram.packages[package_layout.package_index].qualified_name ==
          entity.scope {
          result = y.to_double() <
            package_layout.y + package_layout.height / 2.0
        }
      }
      result
    }
    None => false
  }
  let fill = @svg.svg_color(
    entity.color,
    diagram.style.defaults().entity_colors().node,
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    diagram.style.diagram_line_color(),
  )
  let metrics = text_metrics.regular.measure(entity.display)
  let label_x = x - (metrics.width - width) / 2
  let label_y = if up {
    // `EntityImagePort`: the label block sits above the rect with an 8px
    // overlap gap; the block height cancels out of the baseline.
    y - width - 3
  } else {
    y + height + metrics.height - 3
  }
  output.group(
    {
      ..Default::default(),
      class_name: Some("port-node"),
      data: [("code", entity.qualified_code)],
    },
    output => {
      output
      .with_style({
        ..Default::default(),
        fill: Color(fill),
        stroke: Color(stroke),
        stroke_width: Some(@svg.EMPHASIZED_STROKE_WIDTH),
      })
      .draw(
        Rectangle(
          origin={ x: x.to_double(), y: y.to_double(), },
          width=width.to_double(),
          height=height.to_double(),
          rx=None,
          ry=None,
        ),
      )
      append_paint_text(
        output,
        label_x,
        label_y,
        entity.display,
        "port-title",
        text_metrics.regular,
        fill=diagram.style.diagram_text_color(),
      )
    },
  )
}

///|
/// `FrontierCalculator` for ports: the top border moves to the source port
/// centers and the bottom border to the sink port centers; sides without
/// ports keep the Graphviz box.
fn port_frontier(
  diagram : @entity.EntityDiagram,
  scope : String,
  box_top : Double,
  box_bottom : Double,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> (Double, Double) {
  let mut top = box_top
  let mut bottom = box_bottom
  for index, entity in diagram.entities {
    guard entity.scope == scope && !entity.is_hidden && !entity.is_removed else {
      continue
    }
    let (_, y, _, height) = layout.entity_rect(diagram, index, text_metrics)
    match entity.kind {
      // Source ports sit at the top rank, so their centers are the topmost
      // frontier; sink ports at the bottom rank anchor the bottom border.
      Port | PortIn => top = top.max(y.to_double() + height.to_double() / 2.0)
      PortOut => bottom = bottom.min(y.to_double() + height.to_double() / 2.0)
      _ => ()
    }
  }
  (top, bottom - top)
}
