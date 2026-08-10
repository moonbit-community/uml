///|
fn EntityDiagram::render_svg_with_mode(
  self : EntityDiagram,
  class_member_collapsible : Bool,
) -> String raise @dot_layout.DotLayoutError {
  let family_capability = self.family.capability()
  let usecase = family_capability.usecase_relation_style
  let collapsible = family_capability.class_members_collapsible &&
    class_member_collapsible
  let background = self.style.canvas_color()
  let font_family = self.style.font_family()
  let font_size = self.style.font_size()
  let line_color = self.style.diagram_line_color()
  let text_color = self.style.diagram_text_color()
  let text_metrics = ClassTextMetrics::new(self.style)
  let fallback_layout = self.layout(text_metrics)
  let layout = @graphviz.layout_or_fallback(
    () => {
      let graphviz = self.graphviz_layout(text_metrics)
      {
        columns: fallback_layout.columns,
        cell_width: fallback_layout.cell_width,
        cell_height: fallback_layout.cell_height,
        width: fallback_layout.width,
        graphviz: Some(graphviz),
      }
    },
    Some(() => fallback_layout),
  )
  let bounds = layout.content_bounds(self, text_metrics)
  let content_width = (bounds.max_x - bounds.min_x).ceil().to_int()
  let content_height = (bounds.max_y - bounds.min_y).ceil().to_int()
  let output_width = content_width + SVG_MARGIN_LEFT + SVG_MARGIN_RIGHT
  let output_height = content_height + SVG_MARGIN_TOP + SVG_MARGIN_BOTTOM
  let view_box_x = bounds.min_x - SVG_MARGIN_LEFT.to_double()
  let view_box_y = bounds.min_y - SVG_MARGIN_TOP.to_double()
  let output = StringBuilder()
  output <+
    $|<svg xmlns="http://www.w3.org/2000/svg" width="\{output_width}" height="\{output_height}" viewBox="\{view_box_x} \{view_box_y} \{output_width} \{output_height}" role="img" aria-label="\{family_capability.aria_label}">
  let relations_style =
    $|<style>
    $|svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}
    $|.class-node > rect,.class-node > line{stroke:\{line_color};stroke-width:\{@svg.standard_border_stroke_width()}}
    $|.class-node foreignObject line{stroke-width:\{@svg.standard_border_stroke_width()};fill:none}
    $|.class-node foreignObject rect{stroke-width:\{@svg.standard_border_stroke_width()}}
    $|.class-node:has(details:not([open])) > rect{stroke:transparent !important}
    $|.relation{stroke:\{line_color};stroke-width:\{@svg.standard_border_stroke_width()}}
    $|.relation-decoration{stroke-width:1;stroke-linejoin:miter}
    $|.class-node > line,.relation{fill:none}
    $|.class-title{fill:\{text_color}}
    $|.class-stereotype{fill:\{text_color};font-style:italic}
    $|.class-spot{text-anchor:middle;font-size:12px;font-weight:bold;fill:\{text_color}}
    $|.usecase-title{fill:\{text_color};text-anchor:middle}
    $|.usecase-stereotype{fill:\{text_color};text-anchor:middle;font-style:italic}
    $|.member,.relation-label{fill:\{text_color}}
    $|.relation-label{text-anchor:middle;font-size:\{if usecase { USECASE_RELATION_LABEL_FONT_SIZE } else { RELATION_LABEL_FONT_SIZE }}px}
    $|</style>
  output.write_string(relations_style)
  let has_object_image = self.entities.any(entity => {
    match entity.render_capability().renderer {
      ObjectRenderer | MapRenderer | JsonRenderer => true
      _ => false
    }
  })
  if has_object_image {
    let object_style =
      $|<style>.object-node > rect,.object-node > line,.map-node > rect,.map-node > line,.json-node > rect,.json-node > line{stroke-width:\{@svg.standard_border_stroke_width()}}.object-node > line,.map-node > line,.json-node > line,.object-separator{fill:none}.object-title,.map-title,.json-title{fill:\{text_color};text-anchor:middle}.object-stereotype,.map-stereotype,.json-stereotype{fill:\{text_color};text-anchor:middle;font-style:italic}</style>
    output.write_string(object_style)
  }

  let style_note =
    $|<style>.package path,.package line{stroke:\{line_color};stroke-width:\{@svg.standard_border_stroke_width()}}.package-title{fill:\{text_color};font-weight:bold}.class-note rect,.class-note path{stroke:\{line_color};stroke-width:\{@svg.standard_border_stroke_width()}}.note-text{fill:\{text_color};font-size:\{NOTE_FONT_SIZE}px}</style>
  output.write_string(style_note)
  if family_capability.renders_packages {
    append_packages(output, self, text_metrics, layout)
  }
  match family_capability.paint_order {
    EntitiesBeforeRelations => {
      for index, entity in self.entities {
        append_entity_image(
          output, self, entity, index, text_metrics, layout, collapsible,
        )
      }
      for relation_index, relation in self.relations {
        append_relation(
          output, self, relation_index, relation, text_metrics, layout,
        )
      }
    }
    RelationsBeforeEntities => {
      for relation_index, relation in self.relations {
        append_relation(
          output, self, relation_index, relation, text_metrics, layout,
        )
      }
      for index, entity in self.entities {
        append_entity_image(
          output, self, entity, index, text_metrics, layout, collapsible,
        )
      }
    }
  }
  if family_capability.renders_notes {
    append_notes(output, self, text_metrics, layout)
  }
  output.write_string("</svg>\n")
  output.to_string()
}

///|
/// Render the parsed entity graph to a standalone SVG.
///
/// Node placement is deterministic so parsing and rendering can be used without
/// an external process. The graph-layout adapter will replace these coordinates
/// with Graphviz positions while retaining this entity and relation painter.
/// Diagram-family capabilities select parser and paint-order policy, while the
/// entity kind selects its PlantUML image, geometry and SVG style role.
///
/// When `class_member_collapsible` is set, class-diagram members (fields and
/// methods) are wrapped in a `<foreignObject>`/`<details>` disclosure so they
/// can be collapsed in the browser. Other diagram families ignore the flag.
pub fn EntityDiagram::render_svg(
  self : EntityDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
  class_member_collapsible? : Bool = false,
) -> String raise @dot_layout.DotLayoutError {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme) }
  self.render_svg_with_mode(class_member_collapsible)
}
