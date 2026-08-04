///|
fn EntityDiagram::render_svg_with_mode(self : EntityDiagram) -> String {
  let usecase = self.family.is_usecase()
  let background = self.style.canvas_color()
  let font_family = @style.font_family(self.style)
  let font_size = @style.font_size(self.style)
  let line_color = self.style.diagram_line_color()
  let text_color = self.style.diagram_text_color()
  let text_metrics = ClassTextMetrics::new(self.style)
  let fallback_layout = self.layout(text_metrics)
  let graphviz = Some(self.graphviz_layout(text_metrics)) catch { _ => None }
  let layout = match graphviz {
    Some(graphviz) =>
      {
        columns: fallback_layout.columns,
        cell_width: fallback_layout.cell_width,
        cell_height: fallback_layout.cell_height,
        width: fallback_layout.width,
        graphviz: Some(graphviz),
      }
    None => fallback_layout
  }
  let bounds = layout.content_bounds(self, text_metrics)
  let content_width = (bounds.max_x - bounds.min_x).ceil().to_int()
  let content_height = (bounds.max_y - bounds.min_y).ceil().to_int()
  let output_width = content_width + SVG_MARGIN_LEFT + SVG_MARGIN_RIGHT
  let output_height = content_height + SVG_MARGIN_TOP + SVG_MARGIN_BOTTOM
  let view_box_x = bounds.min_x - SVG_MARGIN_LEFT.to_double()
  let view_box_y = bounds.min_y - SVG_MARGIN_TOP.to_double()
  let output = StringBuilder()
  let diagram_label = if usecase { "Use case diagram" } else { "Class diagram" }
  let marker_context_stroke = "context-stroke"
  output <+
    $|<svg xmlns="http://www.w3.org/2000/svg" width="\{output_width}" height="\{output_height}" viewBox="\{view_box_x} \{view_box_y} \{output_width} \{output_height}" role="img" aria-label="\{diagram_label}">
  let defs_relations =
    $|<defs>
    $|\{@svg.arrow_marker_markup("arrow", marker_width=7.0, marker_height=7.0, path_fill=marker_context_stroke)}
    $|<marker id="triangle" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="none"/></marker>
    $|<marker id="diamond" viewBox="0 0 12 10" refX="1" refY="5" markerWidth="10" markerHeight="8" orient="auto-start-reverse"><path d="M 0 5 L 6 0 L 12 5 L 6 10 z" fill="\{marker_context_stroke}"/></marker>
    $|<marker id="diamond-open" viewBox="0 0 12 10" refX="1" refY="5" markerWidth="10" markerHeight="8" orient="auto-start-reverse"><path d="M 0 5 L 6 0 L 12 5 L 6 10 z" fill="none"/></marker>
    $|</defs>
  output.write_string(defs_relations)
  let relations_style =
    $|<style>
    $|svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}
    $|.class-node > rect,.class-node > line{stroke:\{line_color};stroke-width:1.2}
    $|.relation{stroke:\{line_color};stroke-width:1.2}
    $|.class-node > line,.relation{fill:none}
    $|.class-title{fill:\{text_color}}
    $|.class-spot{text-anchor:middle;font-size:12px;font-weight:bold;fill:\{text_color}}
    $|.usecase-title{fill:\{text_color};text-anchor:middle}
    $|.usecase-stereotype{fill:\{text_color};text-anchor:middle;font-style:italic}
    $|.member,.relation-label{fill:\{text_color}}
    $|.relation-label{text-anchor:middle;font-size:\{if usecase { USECASE_RELATION_LABEL_FONT_SIZE } else { RELATION_LABEL_FONT_SIZE }}px}
    $|</style>
  output.write_string(relations_style)

  let style_markers =
    $|<style>marker path,marker circle,marker rect{stroke:\{marker_context_stroke};stroke-width:1}</style>

  output.write_string(style_markers)
  let style_note =
    $|<style>.package path,.package line{stroke:\{line_color};stroke-width:1.2}.package-title{fill:\{text_color};font-weight:bold}.class-note rect,.class-note path{stroke:\{line_color};stroke-width:1.2}.note-text{fill:\{text_color};font-size:\{NOTE_FONT_SIZE}px}</style>
  output.write_string(style_note)
  let defs_marks =
    $|<defs>
    $|<marker id="bar" viewBox="0 0 8 10" refX="4" refY="5" markerWidth="6" markerHeight="8" orient="auto-start-reverse"><path d="M 4 0 L 4 10" fill="none"/></marker>
    $|<marker id="circle" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><circle cx="5" cy="5" r="4" fill="none"/></marker>
    $|<marker id="circle-filled" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><circle cx="5" cy="5" r="4" fill="\{marker_context_stroke}"/></marker>
    $|<marker id="square" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><rect x="1" y="1" width="8" height="8" fill="none"/></marker>
    $|<marker id="plus" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 5 1 L 5 9 M 1 5 L 9 5" fill="none"/></marker>
    $|<marker id="crowfoot" viewBox="0 0 12 12" refX="2" refY="6" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 2 6 L 11 1 M 2 6 L 11 6 M 2 6 L 11 11" fill="none"/></marker>
    $|</defs>
  output.write_string(defs_marks)
  append_packages(output, self, text_metrics, layout)
  if usecase {
    for index, entity in self.entities {
      append_usecase_entity(output, self, entity, index, text_metrics, layout)
    }
    for relation_index, relation in self.relations {
      append_relation(
        output, self, relation_index, relation, text_metrics, layout,
      )
    }
  } else {
    for relation_index, relation in self.relations {
      append_relation(
        output, self, relation_index, relation, text_metrics, layout,
      )
    }
    for index, entity in self.entities {
      append_entity(output, self, entity, index, text_metrics, layout)
    }
  }
  append_notes(output, self, text_metrics, layout)
  output.write_string("</svg>\n")
  output.to_string()
}

///|
/// Render the parsed entity graph to a standalone SVG.
///
/// Node placement is deterministic so parsing and rendering can be used without
/// an external process. The graph-layout adapter will replace these coordinates
/// with Graphviz positions while retaining this entity and relation painter.
/// The diagram family selects the symbol set: class/object/component diagrams
/// draw class nodes, while use-case diagrams draw actors and ellipses.
pub fn EntityDiagram::render_svg(self : EntityDiagram) -> String {
  self.render_svg_with_mode()
}
