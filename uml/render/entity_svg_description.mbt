///|
/// Paint one description-symbol node. The border geometry per symbol mirrors
/// the matching `USymbol.drawX` in node-local coordinates.
fn EntityPaintContext::append_description(
  self : EntityPaintContext,
  entity : @entity.Entity,
  index : Int,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let diagram = self.diagram
  let text_metrics = self.text_metrics
  let output = self.output
  let capability = entity.render_capability(diagram.family)
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let fill = @svg.svg_color(
    entity.color,
    capability.style_role.background_color(diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    capability.style_role.border_color(diagram.style),
  )
  let text_color = capability.style_role.font_color(diagram.style)
  let line_attributes = entity_line_style(entity.line_style)
  let stroke_attributes = { ..line_attributes, stroke: Color(stroke), }
  let description = entity.description_layout(text_metrics)
  let (label_position, stereotype_position) = description.text_placement(width)
  output.group(
    {
      ..Default::default(),
      class_name: Some("description-node"),
      data: [("code", entity.qualified_code)],
    },
    output => {
      with_entity_link(output, entity.url, graphic => {
        let output = graphic
        let symbol_ctx : DescriptionSymbolContext = {
          output,
          description,
          x,
          y,
          width,
          height,
          fill,
          stroke,
          stroke_attributes,
          line_attributes,
        }
        symbol_ctx.append_symbol()
        append_description_text(
          output,
          entity,
          text_metrics,
          text_color,
          x,
          y,
          label_position,
          stereotype_position,
          description.text,
        )
      })
    },
  )
}

///|
fn append_description_text(
  output : @graphics.Graphic,
  entity : @entity.Entity,
  text_metrics : ClassTextMetrics,
  text_color : String,
  x : Int,
  y : Int,
  label_position : (Int, Int),
  stereotype_position : (Int, Int)?,
  text : DescriptionTextLayout,
) -> Unit {
  if stereotype_position is Some((stereotype_x, stereotype_baseline)) {
    append_paint_text(
      output,
      x + stereotype_x,
      y + stereotype_baseline,
      text.stereotype.unwrap(),
      "description-stereotype",
      text_metrics.regular,
      fill=text_color,
      font_size=text_metrics.regular.font_size,
    )
  }
  append_paint_text(
    output,
    x + label_position.0,
    y + label_position.1,
    entity.display,
    "description-title",
    text_metrics.regular,
    fill=text_color,
  )
}
