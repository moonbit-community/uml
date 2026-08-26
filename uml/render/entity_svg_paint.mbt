///|

///|
const PACKAGE_TAB_HEIGHT : Double = 22.0

///|
/// Emit a single-line `<text>` pinned to its measured advance via
/// `textLength`, matching how PlantUML serializes every text run.
fn append_paint_text(
  output : StringBuilder,
  x : Double,
  y : Double,
  text : String,
  class_name : String,
  metrics : @metrics.FontMetrics,
  attributes? : Array[(String, String)] = [],
) -> Unit {
  output.write_string(
    @svg.text_markup(x, y, text, [("class", class_name), ..attributes], metrics),
  )
}

///|
fn append_packages(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  if layout.graphviz is Some(graphviz) {
    for package_layout in graphviz.packages {
      guard package_layout.package_index < diagram.packages.length() else {
        continue
      }
      let group = diagram.packages[package_layout.package_index]
      // Symbol packages are painted by `append_symbol_packages` instead.
      guard group.symbol is None else { continue }
      let fill = @svg.svg_color(
        group.color,
        @entity.package_background_color(diagram.style),
      )
      let tab_width = text_metrics.regular.measure(group.display).width.to_double() +
        18.0
      let x = package_layout.x
      let y = package_layout.y
      let right = x + package_layout.width
      let bottom = y + package_layout.height
      let border_color = @entity.package_border_color(diagram.style)
      output <+
        $|<g class="package">
        $|<path d="M \{x + 2.5} \{y} L \{x + tab_width - 9.0} \{y} Q \{x + tab_width - 6.5} \{y} \{x + tab_width - 5.5} \{y + 2.5} L \{x + tab_width + 1.5} \{y + PACKAGE_TAB_HEIGHT} L \{right - 2.5} \{y + PACKAGE_TAB_HEIGHT} Q \{right} \{y + PACKAGE_TAB_HEIGHT} \{right} \{y + PACKAGE_TAB_HEIGHT + 2.5} L \{right} \{bottom - 2.5} Q \{right} \{bottom} \{right - 2.5} \{bottom} L \{x + 2.5} \{bottom} Q \{x} \{bottom} \{x} \{bottom - 2.5} L \{x} \{y + 2.5} Q \{x} \{y} \{x + 2.5} \{y}" fill="\{fill}" style="stroke:\{border_color}"/>
        $|<line x1="\{x}" y1="\{y + PACKAGE_TAB_HEIGHT}" x2="\{x + tab_width + 1.5}" y2="\{y + PACKAGE_TAB_HEIGHT}" style="stroke:\{border_color}"/>
      append_paint_text(
        output,
        x + 4.0,
        y + 16.0,
        group.display,
        "package-title",
        text_metrics.regular,
      )
      output.write_char('\n')
      if group.stereotype is Some(stereotype) {
        let display = @tokenizer.display_stereotype(stereotype)
        let metrics = text_metrics.italic.measure(display)
        let stereotype_x = x +
          (package_layout.width - metrics.width.to_double()) / 2.0
        append_paint_text(
          output,
          stereotype_x,
          y + PACKAGE_TAB_HEIGHT + 2.0 + metrics.ascent.to_double(),
          display,
          "package-stereotype",
          text_metrics.italic,
        )
        output.write_char('\n')
      }
      output.write_string("</g>\n")
    }
  }
}

///|
fn ClassLayout::node_y(self : ClassLayout, index : Int) -> Int {
  24 + index / self.columns * self.cell_height
}

///|
fn append_entity_image(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  entity : @entity.Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  class_member_collapsible : Bool,
) -> Unit {
  match entity.render_capability(diagram.family).renderer {
    ClassRenderer =>
      append_entity(
        output, diagram, entity, index, text_metrics, layout, class_member_collapsible,
      )
    ObjectRenderer | MapRenderer | JsonRenderer =>
      append_object_like_entity(
        output, diagram, entity, index, text_metrics, layout,
      )
    LollipopRenderer =>
      append_lollipop_entity(
        output, diagram, entity, index, text_metrics, layout,
      )
    PointRenderer =>
      append_point_entity(output, diagram, entity, index, text_metrics, layout)
    UsecaseRenderer | ActorRenderer | ComponentRenderer =>
      append_usecase_entity(
        output, diagram, entity, index, text_metrics, layout, class_member_collapsible,
      )
    DescriptionRenderer =>
      append_description_entity(
        output, diagram, entity, index, text_metrics, layout,
      )
    PortRenderer =>
      append_port_entity(output, diagram, entity, index, text_metrics, layout)
  }
}

///|
/// Dominant direction from the lollipop node toward its attached entity,
/// mirroring `EntityImageLollipopInterface.addImpact` input.
fn lollipop_attachment_direction(
  diagram : @entity.EntityDiagram,
  code : String,
  center : (Int, Int),
  layout : ClassLayout,
  text_metrics : ClassTextMetrics,
) -> (Double, Double) {
  for relation in diagram.relations {
    let other = if relation.left == code {
      Some(relation.right)
    } else if relation.right == code {
      Some(relation.left)
    } else {
      None
    }
    if other is Some(other) {
      if entity_index(diagram, other) is Some(other_index) {
        let (ox, oy, ow, oh) = layout.entity_rect(
          diagram, other_index, text_metrics,
        )
        return (
          (ox + ow / 2 - center.0).to_double(),
          (oy + oh / 2 - center.1).to_double(),
        )
      }
    }
  }
  (0.0, -1.0)
}

///|
/// Half-lollipop arc bulging toward the attached entity: the curved side
/// faces the entity while the flat side opens away from it.
fn lollipop_half_arc(
  center_x : Int,
  center_y : Int,
  direction : (Double, Double),
) -> String {
  let radius = (LOLLIPOP_SIZE / 2).to_double()
  let x = center_x.to_double()
  let y = center_y.to_double()
  if direction.0.abs() > direction.1.abs() {
    if direction.0 > 0.0 {
      // @entity.Entity on the right: bulge right.
      (
        $|M \{x},\{y - radius} A \{radius},\{radius} 0 0 1 \{x},\{y + radius}
      )
    } else {
      (
        // @entity.Entity on the left: bulge left.
        $|M \{x},\{y + radius} A \{radius},\{radius} 0 0 1 \{x},\{y - radius}
      )
    }
  } else if direction.1 > 0.0 {
    // @entity.Entity below: bulge down.
    (
      $|M \{x - radius},\{y} A \{radius},\{radius} 0 0 0 \{x + radius},\{y}
    )
  } else {
    (
      // @entity.Entity above: bulge up.
      $|M \{x + radius},\{y} A \{radius},\{radius} 0 0 0 \{x - radius},\{y}
    )
  }
}

///|
/// `EntityImageLollipopInterface`: a fixed-size circle (or half circle for
/// required interfaces) with the interface name centered below it. The name
/// overflows the small node, matching the Java image contract.
fn append_lollipop_entity(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  entity : @entity.Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let center_x = x + width / 2
  let center_y = y + height / 2
  let fill = @svg.svg_color(
    entity.color,
    diagram.style.defaults().entity_colors().node,
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    diagram.style.diagram_line_color(),
  )
  let title = text_metrics.regular.measure(entity.display)
  let title_x = x + LOLLIPOP_SIZE / 2 - title.width / 2
  let title_y = y + LOLLIPOP_SIZE + title.ascent
  output <+
    $|<g class="lollipop-node" data-code="\{@svg.xml_escape(entity.qualified_code)}">
  match entity.kind {
    LollipopHalf => {
      let direction = lollipop_attachment_direction(
        diagram,
        entity.qualified_code,
        (center_x, center_y),
        layout,
        text_metrics,
      )
      output <+
        $|<path d="\{lollipop_half_arc(center_x, center_y, direction)}" fill="\{fill}" stroke="\{stroke}" stroke-width="\{@svg.emphasized_stroke_width()}"/>
    }
    _ =>
      output <+
        $|<ellipse cx="\{center_x}" cy="\{center_y}" rx="\{width / 2}" ry="\{height / 2}" fill="\{fill}" stroke="\{stroke}" stroke-width="\{@svg.emphasized_stroke_width()}"/>
  }
  append_paint_text(
    output,
    title_x.to_double(),
    title_y.to_double(),
    entity.display,
    "lollipop-title",
    text_metrics.regular,
    attributes=[("fill", diagram.style.diagram_text_color())],
  )
  output.write_string("</g>\n")
}

///|
/// `EntityImageAssociationPoint`: a fixed 4x4 circle filled with the line
/// color, drawn without an entity group like the Java image.
fn append_point_entity(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  entity : @entity.Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let color = diagram.style.diagram_line_color()
  output <+
    $|<ellipse cx="\{x + width / 2}" cy="\{y + height / 2}" rx="\{width / 2}" ry="\{height / 2}" fill="\{color}" stroke="\{color}" stroke-width="1"/>
}

///|
/// Paint an object-family rectangular image without class-only spot or
/// compartment semantics. Map rows and JSON trees replace the provisional
/// empty object-like body in O3 and O4, while keeping this image contract.
fn append_object_like_entity(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  entity : @entity.Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let capability = entity.render_capability(diagram.family)
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let is_json = capability.renderer is JsonRenderer
  let header = if is_json {
    entity.json_header_layout(text_metrics)
  } else {
    entity.object_header_layout(text_metrics)
  }
  let fill = @svg.svg_color(
    entity.color,
    capability.style_role.background_color(diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    capability.style_role.border_color(diagram.style),
  )
  let stroke_style = @svg.stroke_style(entity.line_style)
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let separator_attributes =
    $| style="stroke:\{stroke};stroke-width:\{@svg.standard_border_stroke_width()}"
  let placement = if is_json {
    header.json_placement(width)
  } else {
    header.placement(width)
  }
  output <+
    $|<g class="\{capability.node_class()}" data-code="\{@svg.xml_escape(entity.qualified_code)}">
  if entity.url is Some(url) {
    output <+
      $|<a href="\{@svg.xml_escape(url)}">
  }
  output <+
    $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="\{OBJECT_ROUND_CORNER}" ry="\{OBJECT_ROUND_CORNER}" fill="\{fill}" \{line_attributes}/>
  match (capability.renders_stereotype, header.stereotype, placement.2) {
    (true, Some(stereotype), Some((stereotype_x, stereotype_baseline))) =>
      append_paint_text(
        output,
        (x + stereotype_x).to_double(),
        (y + stereotype_baseline).to_double(),
        stereotype,
        capability.stereotype_class(),
        text_metrics.class_stereotype,
        attributes=[
          ("fill", capability.style_role.font_color(diagram.style)),
          ("font-family", text_metrics.class_stereotype_font_family),
          ("font-size", text_metrics.class_stereotype.font_size.to_string()),
        ],
      )
    _ => ()
  }
  append_paint_text(
    output,
    (x + placement.0).to_double(),
    (y + placement.1).to_double(),
    entity.display,
    capability.title_class(),
    text_metrics.regular,
    attributes=[("fill", capability.style_role.font_color(diagram.style))],
  )
  output <+
    $|<line x1="\{x}" y1="\{y + header.height}" x2="\{x + width}" y2="\{y + header.height}"\{line_attributes}/>
  match capability.body {
    MapEntries => {
      let body = entity.map_body_layout(text_metrics)
      let text_color = capability.style_role.font_color(diagram.style)
      for row_index, row in body.rows {
        let row_y = y + header.height + row.top
        if row_index > 0 {
          output <+
            $|<line class="map-row-separator" x1="\{x}" y1="\{row_y}" x2="\{x + width}" y2="\{row_y}"\{separator_attributes}/>
        }
        let svg_port_id = "map-port-" +
          stable_port_identifier(entity.qualified_code) +
          "-" +
          row.port_id
        output <+
          $|<g id="\{svg_port_id}" class="map-row\{if row.entry.link_target is Some(_) { " map-link-row" } else { " map-value-row" }}" data-port="\{@svg.xml_escape(row.entry.key)}" data-port-id="\{row.port_id}">
        let key_metrics = text_metrics.regular.measure(row.key)
        let key_x = if row.entry.link_target is Some(_) {
          x + (width - key_metrics.width) / 2
        } else {
          x + (body.key_column_width - key_metrics.width) / 2
        }
        let key_y = row_y +
          (row.height - key_metrics.height) / 2 +
          key_metrics.baseline
        append_paint_text(
          output,
          key_x.to_double(),
          key_y.to_double(),
          row.key,
          "map-key member",
          text_metrics.regular,
          attributes=[("fill", text_color)],
        )
        output.write_char('\n')
        match row.entry.value {
          Some(value) => {
            let value_metrics = text_metrics.regular.measure(value)
            let divider_x = x + body.key_column_width
            let value_x = divider_x +
              (body.value_column_width - value_metrics.width) / 2
            let value_y = row_y +
              (row.height - value_metrics.height) / 2 +
              value_metrics.baseline
            output <+
              $|<line class="map-column-separator" x1="\{divider_x}" y1="\{row_y}" x2="\{divider_x}" y2="\{row_y + row.height}"\{separator_attributes}/>
            append_paint_text(
              output,
              value_x.to_double(),
              value_y.to_double(),
              value,
              "map-value member",
              text_metrics.regular,
              attributes=[("fill", text_color)],
            )
          }
          None => ()
        }
        output.write_string("</g>")
      }
    }
    OrderedMembers => {
      let body = entity.object_body_layout(text_metrics)
      let row_height = text_metrics.row_height()
      let text_x = if body.has_visibility { 20 } else { 5 }
      let entity_colors = diagram.style.defaults().entity_colors()
      let mut body_y = y + header.height
      for entry in body.entries {
        if entry.is_separator {
          body_y += OBJECT_SEPARATOR_HEIGHT
          output <+
            $|<line class="object-separator" x1="\{x}" y1="\{body_y}" x2="\{x + width}" y2="\{body_y}"\{separator_attributes}/>
        } else {
          let member_y = body_y + row_height + 1
          output <+
            $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y, entity_colors)}</g>
          append_paint_text(
            output,
            (x + text_x).to_double(),
            member_y.to_double(),
            entry.display_without_visibility(),
            "object-member member",
            text_metrics.regular,
          )
          output.write_char('\n')
          body_y += row_height
        }
      }
    }
    JsonData => {
      let body = entity.json_body_layout(text_metrics)
      let body_top = y + header.height
      let text_color = capability.style_role.font_color(diagram.style)
      let json_separator_attributes =
        $| style="stroke:\{stroke};stroke-width:1"
      for divider in body.dividers {
        output <+
          $|<line class="json-column-separator" x1="\{x + divider.x}" y1="\{body_top + divider.top}" x2="\{x + divider.x}" y2="\{body_top + divider.top + divider.height}"\{json_separator_attributes}/>
      }
      for row in body.rows {
        if row.hline {
          output <+
            $|<line class="json-row-separator" x1="\{x + row.hline_from}" y1="\{body_top + row.top}" x2="\{x + row.hline_from + row.hline_width}" y2="\{body_top + row.top}"\{json_separator_attributes}/>
        }
        match row.key {
          Some(key) => {
            let key_metrics = text_metrics.regular.measure(key)
            append_paint_text(
              output,
              (x + row.hline_from + MAP_CELL_HORIZONTAL_PADDING).to_double(),
              (body_top +
              row.top +
              MAP_CELL_VERTICAL_PADDING +
              key_metrics.ascent).to_double(),
              key,
              "json-key member",
              text_metrics.regular,
              attributes=[("fill", text_color)],
            )
            output.write_char('\n')
          }
          None => ()
        }
        match row.value {
          Some(value) => {
            let value_metrics = text_metrics.regular.measure(value)
            append_paint_text(
              output,
              (x + row.value_x + MAP_CELL_HORIZONTAL_PADDING).to_double(),
              (body_top +
              row.top +
              MAP_CELL_VERTICAL_PADDING +
              value_metrics.ascent).to_double(),
              value,
              "json-value member",
              text_metrics.regular,
              attributes=[("fill", text_color)],
            )
            output.write_char('\n')
          }
          None => ()
        }
      }
    }
    ClassCompartments | NoBody => panic()
  }
  if entity.url is Some(_) {
    output.write_string("</a>")
  }
  output.write_string("</g>\n")
}

///|
fn append_entity(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  entity : @entity.Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  class_member_collapsible : Bool,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let header = entity.header_layout(text_metrics, diagram.family)
  let body = entity.body_layout(text_metrics, diagram.family)
  let row_height = text_metrics.row_height()
  let fill = @svg.svg_color(
    entity.color,
    @entity.class_background_color(diagram.style),
  )
  let stroke = @svg.svg_color(
    entity.line_color,
    @entity.class_border_color(diagram.style),
  )
  let stroke_style = @svg.stroke_style(entity.line_style)
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let title_attributes = match entity.kind {
    @entity.EntityKind::AbstractClass | @entity.EntityKind::Interface =>
      [("font-style", "italic")]
    _ => []
  }
  let entity_colors = diagram.style.defaults().entity_colors()
  let (spot_text, spot_fill) = entity.spot(diagram.family, entity_colors)
  let placement = header.placement(width)
  let rect_height = if class_member_collapsible {
    header.height
  } else {
    height
  }
  let node_index_attribute = if class_member_collapsible {
    " data-node-index=\"\{index}\" style=\"--uml-header-height:\{header.height}px\""
  } else {
    ""
  }
  output <+
    $|<g class="class-node" data-code="\{@svg.xml_escape(entity.qualified_code)}"\{node_index_attribute}><rect x="\{x}" y="\{y}" width="\{width}" height="\{rect_height}" fill="\{fill}"\{line_attributes}/>
  match
    (entity.render_capability(diagram.family).spot, placement.circle_center) {
    (ClassSpot, Some((circle_cx, circle_cy))) if diagram.family is Mbti => {
      // The mbti family labels the node with the bold kind word instead of a
      // circled letter; the shared `.class-spot` style already bolds it.
      append_paint_text(
        output,
        (x + circle_cx).to_double(),
        (y + circle_cy + 4).to_double(),
        spot_text,
        "class-spot",
        text_metrics.regular,
      )
      output.write_char('\n')
    }
    (ClassSpot, Some((circle_cx, circle_cy))) => {
      output <+
        $|<circle cx="\{x + circle_cx}" cy="\{y + circle_cy}" r="\{CLASS_SPOT_RADIUS}" fill="\{spot_fill}" stroke="\{diagram.style.diagram_line_color()}" stroke-width="1"/>
      append_paint_text(
        output,
        (x + circle_cx).to_double(),
        (y + circle_cy + 4).to_double(),
        spot_text,
        "class-spot",
        text_metrics.regular,
      )
      output.write_char('\n')
    }
    _ => ()
  }
  match (header.stereotype, placement.stereotype_position) {
    (Some(stereotype), Some((stereotype_x, stereotype_baseline))) => {
      append_paint_text(
        output,
        (x + stereotype_x).to_double(),
        (y + stereotype_baseline).to_double(),
        stereotype,
        "class-stereotype",
        text_metrics.class_stereotype,
        attributes=[
          ("fill", @entity.class_stereotype_font_color(diagram.style)),
          ("font-family", text_metrics.class_stereotype_font_family),
          ("font-size", text_metrics.class_stereotype.font_size.to_string()),
        ],
      )
      output.write_char('\n')
    }
    _ => ()
  }
  append_paint_text(
    output,
    (x + placement.title_x).to_double(),
    (y + placement.title_baseline).to_double(),
    entity.display,
    "class-title",
    text_metrics.regular,
    attributes=title_attributes,
  )
  output.write_char('\n')
  match (header.annotation, placement.annotation_position) {
    (Some(annotation), Some((annotation_x, annotation_baseline))) => {
      append_paint_text(
        output,
        (x + annotation_x).to_double(),
        (y + annotation_baseline).to_double(),
        annotation,
        "class-annotation",
        text_metrics.class_stereotype,
        attributes=[
          ("fill", @entity.class_stereotype_font_color(diagram.style)),
          ("font-family", text_metrics.class_stereotype_font_family),
          ("font-size", text_metrics.class_stereotype.font_size.to_string()),
        ],
      )
      output.write_char('\n')
    }
    _ => ()
  }
  let member_top = y + header.height
  let body_height = body.fields_height + body.methods_height
  // The mbti family opens its member disclosure by default; class diagrams
  // stay collapsed until the user expands them.
  let details_open = if diagram.family is Mbti { " open" } else { "" }
  if class_member_collapsible {
    output <+
      $|<foreignObject x="\{x}" y="\{y}" width="\{width}" height="\{height}" pointer-events="all"><details xmlns="http://www.w3.org/1999/xhtml"\{details_open} style="position:relative"><summary style="position:absolute;top:0;left:0;right:0;height:\{header.height}px;list-style:none"></summary><svg xmlns="http://www.w3.org/2000/svg" viewBox="\{x} \{y} \{width} \{height}" width="\{width}" height="\{height}"><rect x="\{x}" y="\{member_top}" width="\{width}" height="\{body_height}" fill="\{fill}"\{line_attributes}/>
  }
  let mut section_y = y + header.height
  for section_index, section in [body.fields, body.methods] {
    let section_height = if section_index == 0 {
      body.fields_height
    } else {
      body.methods_height
    }
    // The mbti family collapses empty portions: no separator, no strip.
    guard section_height > 0 else { continue }
    output <+
      $|<line x1="\{x}" y1="\{section_y}" x2="\{x + width}" y2="\{section_y}"\{line_attributes}/>
    for member_index, entry in section {
      let member_y = section_y + (member_index + 1) * row_height + 1
      output <+
        $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y, entity_colors)}</g>
      append_paint_text(
        output,
        (x + entry.member_text_x()).to_double(),
        member_y.to_double(),
        entry.display_without_visibility(),
        "member",
        text_metrics.regular,
      )
      output.write_char('\n')
    }
    section_y += section_height
  }
  if class_member_collapsible {
    output.write_string("</svg></details></foreignObject>\n")
  }
  output.write_string("</g>\n")
}

///|
fn append_usecase_entity(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  entity : @entity.Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  class_member_collapsible : Bool,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
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
  let line_attributes = @svg.stroke_style(entity.line_style)
  match capability.renderer {
    UsecaseRenderer | ActorRenderer | ComponentRenderer => ()
    _ => {
      append_entity(
        output, diagram, entity, index, text_metrics, layout, class_member_collapsible,
      )
      return
    }
  }
  output <+
    $|<g class="\{capability.node_class()}" data-code="\{@svg.xml_escape(entity.qualified_code)}">
  if entity.url is Some(url) {
    output <+
      $|<a href="\{@svg.xml_escape(url)}">
  }
  match entity.kind {
    @entity.EntityKind::Usecase | @entity.EntityKind::BusinessUsecase => {
      let (_, content_height, stereotype) = entity.usecase_content_layout(
        text_metrics,
      )
      // TextBlockInEllipse centers the text block, then applies dy - 2.
      // The ellipse itself has grown by 6px, so SVG text needs a +2px
      // top offset before converting its font ascent to a baseline.
      let content_top = y + height / 2 - content_height / 2 + 2
      let title_metrics = text_metrics.usecase_regular.measure(entity.display)
      output <+
        $|<ellipse cx="\{x + width / 2}" cy="\{y + height / 2}" rx="\{width / 2}" ry="\{height / 2}" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
      match stereotype {
        Some(value) => {
          let metrics = text_metrics.usecase_italic.measure(value)
          append_paint_text(
            output,
            (x + width / 2).to_double(),
            (content_top + metrics.baseline).to_double(),
            value,
            capability.stereotype_class(),
            text_metrics.usecase_italic,
            attributes=[
              ("fill", text_color),
              ("font-family", text_metrics.usecase_font_family),
              ("font-size", text_metrics.usecase_italic.font_size.to_string()),
            ],
          )
          output.write_char('\n')
        }
        None => ()
      }
      let title_y = match stereotype {
        Some(value) =>
          content_top +
          text_metrics.usecase_italic.measure(value).height +
          title_metrics.baseline
        None => content_top + title_metrics.baseline
      }
      append_paint_text(
        output,
        (x + width / 2).to_double(),
        title_y.to_double(),
        entity.display,
        capability.title_class(),
        text_metrics.usecase_regular,
        attributes=[
          ("fill", text_color),
          ("font-family", text_metrics.usecase_font_family),
          ("font-size", text_metrics.usecase_regular.font_size.to_string()),
        ],
      )
      output.write_char('\n')
      if entity.kind is @entity.EntityKind::BusinessUsecase {
        let (mark_start, mark_end) = usecase_business_mark(x, y, width, height)
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="usecase-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    @entity.EntityKind::Actor | @entity.EntityKind::BusinessActor => {
      let center_x = x + width / 2
      let title = text_metrics.actor_regular.measure(entity.display)
      let (_, _, stereotype) = entity.actor_content_layout(text_metrics)
      let appearance = actor_appearance(text_metrics.actor_style)
      let (figure_width, figure_height) = actor_figure_geometry(
        appearance,
        business=entity.kind is @entity.EntityKind::BusinessActor,
      )
      let stereotype_height = stereotype.map_or(0, value => {
        text_metrics.actor_italic.measure(value).height
      })
      let figure_top = y + stereotype_height
      let label_y = figure_top + figure_height + title.baseline
      match stereotype {
        Some(value) => {
          let metrics = text_metrics.actor_italic.measure(value)
          append_paint_text(
            output,
            center_x.to_double(),
            (y + metrics.baseline).to_double(),
            value,
            capability.stereotype_class(),
            text_metrics.actor_italic,
            attributes=[
              ("fill", text_color),
              ("font-family", text_metrics.actor_font_family),
              ("font-size", text_metrics.actor_italic.font_size.to_string()),
            ],
          )
          output.write_char('\n')
        }
        None => ()
      }
      if entity.kind is @entity.EntityKind::Actor {
        match appearance {
          Awesome =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 17}" r="16" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 27} \{figure_top + 50} Q \{center_x} \{figure_top + 38} \{center_x + 27} \{figure_top + 50} V \{figure_top + 62} Q \{center_x + 27} \{figure_top + 62} \{center_x + 19} \{figure_top + 62} H \{center_x - 19} Q \{center_x - 27} \{figure_top + 62} \{center_x - 27} \{figure_top + 54} Z" class="actor-awesome-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Hollow =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 5}" r="4" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 13} \{figure_top + 12} H \{center_x + 13} V \{figure_top + 17} H \{center_x + 3} V \{figure_top + 27} L \{center_x + 9} \{figure_top + 35} H \{center_x + 3} L \{center_x} \{figure_top + 30} L \{center_x - 3} \{figure_top + 35} H \{center_x - 9} L \{center_x - 3} \{figure_top + 27} V \{figure_top + 17} H \{center_x - 13} Z" class="actor-hollow-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Stickman => ()
        }
      }
      if entity.kind is @entity.EntityKind::BusinessActor ||
        appearance is Stickman {
        output <+
          $|<circle cx="\{center_x}" cy="\{figure_top + 9}" r="8" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x} \{figure_top + 17} L \{center_x} \{figure_top + 43} M \{center_x - 13} \{figure_top + 27} L \{center_x + 13} \{figure_top + 27} M \{center_x} \{figure_top + 43} L \{center_x - 13} \{figure_top + figure_height} M \{center_x} \{figure_top + 43} L \{center_x + 13} \{figure_top + figure_height}" fill="none" stroke="\{stroke}" style="\{line_attributes}"/>
      }
      append_paint_text(
        output,
        center_x.to_double(),
        label_y.to_double(),
        entity.display,
        capability.title_class(),
        text_metrics.actor_regular,
        attributes=[
          ("fill", text_color),
          ("font-family", text_metrics.actor_font_family),
          ("font-size", text_metrics.actor_regular.font_size.to_string()),
        ],
      )
      output.write_char('\n')
      if entity.kind is @entity.EntityKind::BusinessActor &&
        figure_width == ACTOR_FIGURE_WIDTH {
        let (mark_start, mark_end) = actor_business_mark(
          center_x,
          figure_top + 9,
          8,
        )
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="actor-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    @entity.EntityKind::Component => {
      let title = text_metrics.regular.measure(entity.display)
      let tab_x = x + width - COMPONENT_TAB_WIDTH - COMPONENT_TAB_INSET
      let tab_y = y + COMPONENT_TAB_INSET
      let mark_x = tab_x - COMPONENT_TAB_MARK_LEFT_OFFSET
      let first_mark_y = tab_y + COMPONENT_TAB_MARK_TOP_OFFSET
      let second_mark_y = first_mark_y + COMPONENT_TAB_MARK_GAP
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2" ry="2" class="component-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{tab_x}" y="\{tab_y}" width="\{COMPONENT_TAB_WIDTH}" height="\{COMPONENT_TAB_HEIGHT}" class="component-tab" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{first_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{second_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
      append_paint_text(
        output,
        (x + width / 2).to_double(),
        (y + (height + title.height) / 2 - 2).to_double(),
        entity.display,
        capability.title_class(),
        text_metrics.regular,
        attributes=[("fill", text_color)],
      )
      output.write_char('\n')
    }
    _ => ()
  }
  if entity.url is Some(_) {
    output.write_string("</a>")
  }
  output.write_string("</g>\n")
}

///|
