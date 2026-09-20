///|
fn draw_timing_grid(drawing : TimingDrawing, layout : TimingLayout) -> Unit {
  let ruler = layout.ruler
  let bottom = TIMING_MARGIN + layout.inner_height
  let grid = {
    ..timing_appearance(drawing.style, "timegrid").paint(),
    dash: Some([3.0, 5.0]),
    stroke_width: Some(0.5),
  }
  for index in 0..<=ruler.tick_count() {
    let x = layout.wave_x + ruler.interval * index.to_double()
    drawing.line(x, TIMING_MARGIN, x, bottom, grid, class_name="timing-grid")
  }
}

///|
fn draw_timing_axis(
  drawing : TimingDrawing,
  diagram : @flow.TimingDiagram,
  layout : TimingLayout,
) -> Unit {
  guard !(diagram.time_axis is @flow.TimeAxisStrategy::Hidden) else { return }
  let ruler = layout.ruler
  let bottom = TIMING_MARGIN + layout.inner_height
  let paint = timing_appearance(drawing.style, "timeline").paint()
  let first = ruler.marks
    .filter(mark => mark >= 0.0)
    .get(0)
    .unwrap_or(ruler.minimum)
  let first_x = ruler.position(first)
  let axis_ticks = ((ruler.width - first_x) / ruler.interval)
    .floor()
    .to_int()
    .max(0)
  drawing.line(
    layout.wave_x + first_x,
    bottom,
    layout.wave_x + first_x + axis_ticks.to_double() * ruler.interval,
    bottom,
    paint,
    class_name="timing-axis",
  )
  let labels = []
  if diagram.time_axis is @flow.TimeAxisStrategy::Manual {
    for value in ruler.marks {
      let x = layout.wave_x + ruler.position(value)
      drawing.line(
        x,
        bottom,
        x,
        bottom + TIMING_TICK_HEIGHT,
        paint,
        class_name="timing-tick",
      )
      let coded = diagram.codes
        .filter(entry => timing_tick(entry.1) == value)
        .get(0)
      labels.push(
        (
          value,
          coded.map_or_else(() => timing_time_label(diagram, value), entry => {
            entry.0
          }),
        ),
      )
    }
  } else {
    for index in 0..<=axis_ticks {
      let x = layout.wave_x + first_x + index.to_double() * ruler.interval
      drawing.line(
        x,
        bottom,
        x,
        bottom + TIMING_TICK_HEIGHT,
        paint,
        class_name="timing-tick",
      )
    }
    if diagram.scale is Some(_) {
      for index in 0..<=ruler.tick_count() {
        let value = ruler.minimum.trunc() + index.to_double() * ruler.unit
        labels.push((value, timing_time_label(diagram, value)))
      }
    } else {
      let rounded : Array[Double] = []
      for mark in ruler.marks {
        let value = mark.trunc()
        if !rounded.contains(value) {
          rounded.push(value)
          labels.push((value, timing_time_label(diagram, value)))
        }
      }
    }
  }
  for (value, label) in labels {
    drawing.text(
      label,
      layout.wave_x + ruler.position(value),
      bottom + TIMING_TICK_HEIGHT + 1.0,
      "timeline",
      anchor=Middle,
    )
  }
}

///|
fn draw_timing_highlights(
  drawing : TimingDrawing,
  diagram : @flow.TimingDiagram,
  layout : TimingLayout,
  background : Bool,
) -> Unit {
  let appearance = timing_appearance(drawing.style, "highlight")
  for highlight in diagram.highlights {
    guard highlight.from is Some(from) && highlight.to is Some(to) else {
      continue
    }
    let x1 = layout.wave_x + layout.ruler.position(timing_tick(from))
    let x2 = layout.wave_x + layout.ruler.position(timing_tick(to))
    let paint = timing_wave_paint(appearance, highlight.color)
    if background {
      drawing.rect(
        x1,
        TIMING_MARGIN,
        x2 - x1,
        layout.inner_height,
        { ..paint, stroke: None, },
        class_name="timing-highlight",
      )
    } else {
      let paint = { ..paint, dash: Some([4.0, 4.0]), }
      drawing.line(
        x1,
        TIMING_MARGIN,
        x1,
        TIMING_MARGIN + layout.inner_height,
        paint,
        class_name="timing-highlight-boundary",
      )
      drawing.line(
        x2,
        TIMING_MARGIN,
        x2,
        TIMING_MARGIN + layout.inner_height,
        paint,
        class_name="timing-highlight-boundary",
      )
      if highlight.caption is Some(caption) {
        drawing.text(caption, x1 + 3.0, TIMING_MARGIN + 2.0, "highlight")
      }
    }
  }
}

///|
fn build_timing_drawing(
  diagram : @flow.TimingDiagram,
  layout : TimingLayout,
) -> TimingDrawing {
  let drawing : TimingDrawing = {
    style: diagram.style,
    commands: [],
    min_x: 0.0,
    min_y: 0.0,
    max_x: layout.width,
    max_y: layout.height,
  }
  let full_width = layout.width - TIMING_MARGIN * 2.0
  for panel in layout.players {
    let player = diagram.players[panel.index]
    if player.background_color is Some(color) {
      drawing.rect(
        TIMING_MARGIN,
        panel.frame_y,
        full_width,
        panel.height,
        {
          ..Default::default(),
          fill: Color(@svg.svg_color(Some(color), "none")),
        },
        class_name="timing-player-background",
      )
    }
  }
  let border = timing_appearance(diagram.style, "title").paint()
  if !diagram.compact_by_default {
    drawing.line(
      TIMING_MARGIN,
      TIMING_MARGIN,
      TIMING_MARGIN,
      TIMING_MARGIN + layout.inner_height,
      border,
      class_name="timing-border",
    )
    drawing.line(
      TIMING_MARGIN + full_width,
      TIMING_MARGIN,
      TIMING_MARGIN + full_width,
      TIMING_MARGIN + layout.inner_height,
      border,
      class_name="timing-border",
    )
  }
  draw_timing_highlights(drawing, diagram, layout, true)
  draw_timing_grid(drawing, layout)
  for panel in layout.players {
    let player = diagram.players[panel.index]
    if !player.compact {
      drawing.line(
        TIMING_MARGIN,
        panel.frame_y,
        TIMING_MARGIN + full_width,
        panel.frame_y,
        border,
        class_name="timing-separator",
      )
    }
    drawing.text(
      player.title,
      TIMING_MARGIN + TIMING_SIDE,
      panel.frame_y,
      "title",
    )
    if !player.title.is_empty() && !player.compact {
      let title = timing_text_size(
        player.title,
        timing_appearance(diagram.style, "title"),
      )
      let corner_x = TIMING_MARGIN + TIMING_SIDE + title.0 + 1.0
      drawing.polygon(
        [
          { x: TIMING_MARGIN, y: panel.panel_y, },
          { x: corner_x, y: panel.panel_y, },
          { x: corner_x + TIMING_FRAME_CORNER, y: panel.frame_y, },
        ],
        border,
        closed=false,
        class_name="timing-title-frame",
      )
    }
    match player.kind {
      Robust => draw_timing_robust(drawing, layout, panel, player)
      Concise | Rectangle => draw_timing_concise(drawing, layout, panel, player)
      Binary => draw_timing_binary(drawing, layout, panel, player)
      Clock => draw_timing_clock(drawing, layout, panel, player)
      Analog => draw_timing_analog(drawing, layout, panel, player)
    }
    draw_timing_constraints(drawing, layout, panel, player)
    draw_timing_notes(drawing, layout, panel, player)
  }
  draw_timing_axis(drawing, diagram, layout)
  draw_timing_messages(drawing, diagram, layout)
  draw_timing_highlights(drawing, diagram, layout, false)
  drawing
}

///|
/// Render the six TimingDiagram player families through their native panels.
pub fn render_timing_svg(
  diagram : @flow.TimingDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let diagram = {
    ..diagram,
    style: diagram.style.with_color_scheme(color_scheme),
  }
  let layout = layout_timing(diagram)
  let drawing = build_timing_drawing(diagram, layout)
  let width = drawing.max_x - drawing.min_x
  let height = drawing.max_y - drawing.min_y
  let decoration = decorate_document_text(diagram.style, width, height)
  let scale = diagram.style.output_scale(decoration.width, decoration.height)
  let document = @svg.SvgDocument::new(
    (decoration.width * scale).ceil().to_int(),
    (decoration.height * scale).ceil().to_int(),
    "Timing diagram",
    diagram.style.canvas_color(),
    diagram.style.font_family(),
    diagram.style.font_size(),
  )
  for
    role in [
      "title", "robust", "concise", "rectangle", "binary", "analog", "clock", "timeline",
      "arrow", "constraintArrow", "note", "highlight",
    ] {
    let appearance = timing_appearance(diagram.style, role)
    document.stylesheet(
      ".timing-" +
      role +
      "-label{font-family:" +
      appearance.family +
      ";font-size:" +
      appearance.metrics.font_size.to_string() +
      "px;font-weight:" +
      appearance.metrics.font_weight.to_string() +
      ";fill:" +
      appearance.color +
      "}",
    )
  }
  for block in decoration.text {
    document.stylesheet(
      resolve_state_font(diagram.style, block.role).css_rule(
        ".timing-document-" + block.kind + "-label",
      ),
    )
  }
  document
  .graphic()
  .scale_group(scale, output => {
    for command in drawing.commands {
      let command = match command {
        Draw(shape, paint, translation, metadata) =>
          @graphics.DrawCommand::Draw(
            shape,
            paint,
            {
              x: translation.x - drawing.min_x + decoration.dx,
              y: translation.y - drawing.min_y + decoration.dy,
            },
            metadata,
          )
        _ => command
      }
      (output.emit)(command)
    }
    draw_document_text(
      output,
      diagram.style,
      "timing-document",
      decoration.text,
    )
  })
  document.to_string()
}
