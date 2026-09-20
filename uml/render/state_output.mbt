///|
priv struct StateOutputSize {
  width : Int
  height : Int
  scale : Double
}

///|
/// Resolve export scaling against the full unrounded image, including all
/// document blocks. Round only the resulting viewport to integer pixels.
fn state_output_size(
  diagram : @flow.StateDiagram,
  layout : StateLayout,
) -> StateOutputSize {
  let scale = diagram.style.output_scale(layout.width, layout.height)
  {
    width: (layout.width * scale).ceil().to_int().max(1),
    height: (layout.height * scale).ceil().to_int().max(1),
    scale,
  }
}

///|
/// Export transforms the complete drawing rather than rerunning DOT with
/// resized nodes. Text, border strokes, decorations, and notes scale together.
/// Previously verified: output scaling transforms the complete drawing
/// without rerunning layout; size constraints include document blocks.
fn append_state_output(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  drawing : StateDrawingLayout,
  size : StateOutputSize,
) -> Unit {
  output
  .with_style({
    ..@graphics.DrawingStyle::default(),
    fill: Color(diagram.style.canvas_color()),
  })
  .draw(
    Rectangle(
      origin={ x: 0.0, y: 0.0, },
      width=size.width.to_double(),
      height=size.height.to_double(),
      rx=None,
      ry=None,
    ),
    metadata=state_class("state-canvas"),
  )
  let paint = (output : @graphics.Graphic) => {
    append_state_layout(
      output,
      diagram,
      drawing.layout,
      note_connections=drawing.note_connections,
      cluster_titles=drawing.cluster_titles,
    )
    draw_document_text(output, diagram.style, "state", drawing.document)
  }
  if size.scale == 1.0 {
    paint(output)
  } else {
    output.scale_group(size.scale, paint)
  }
}

///|
fn write_state_shadow_command(
  writer : @svg.XmlWriter,
  command : @graphics.DrawCommand,
  text_backgrounds : Array[String],
  shadows : Array[Bool],
) -> Unit {
  guard command is Draw(_, _, _, metadata) &&
    state_metadata_shadow(metadata) > 0.0 else {
    write_state_rich_command(writer, command, text_backgrounds)
    return
  }
  if shadows.is_empty() {
    shadows.push(true)
  }
  writer.open("g", attributes=[("filter", "url(#state-shadow)")])
  write_state_rich_command(writer, command, text_backgrounds)
  writer.close()
}

///|
/// SvgGraphics.manageShadow uses this same filter for any positive shadow
/// value; the configured value separately controls bounds and note spacing.
fn write_state_shadow_filter(writer : @svg.XmlWriter) -> Unit {
  writer.open("defs")
  writer.open("filter", attributes=[
    ("id", "state-shadow"),
    ("x", "-1"),
    ("y", "-1"),
    ("width", "300%"),
    ("height", "300%"),
  ])
  writer.empty("feGaussianBlur", attributes=[
    ("result", "blurOut"),
    ("stdDeviation", "2"),
  ])
  writer.empty("feColorMatrix", attributes=[
    ("type", "matrix"),
    ("in", "blurOut"),
    ("result", "blurOut2"),
    ("values", "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 .4 0"),
  ])
  writer.empty("feOffset", attributes=[
    ("result", "blurOut3"),
    ("in", "blurOut2"),
    ("dx", "4"),
    ("dy", "4"),
  ])
  writer.empty("feBlend", attributes=[
    ("in", "SourceGraphic"),
    ("in2", "blurOut3"),
    ("mode", "normal"),
  ])
  writer.close()
  writer.close()
}
