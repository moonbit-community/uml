///|
fn append_svg_preamble(
  output : StringBuilder,
  layout : DiagramLayout,
  style : @style.DocumentStyle,
) -> Unit {
  let background = style.canvas_color()
  let font_family = style.font_family()
  let font_size = style.font_size()
  let base_font_size = style.font_size_value()
  let body_font_size = (base_font_size - 1).max(1)
  let small_font_size = (base_font_size - 2).max(1)
  let line_color = style.diagram_line_color()
  let text_color = style.diagram_text_color()
  let defaults = style.defaults()
  output <+
    $|<svg xmlns="http://www.w3.org/2000/svg" width="\{layout.width}" height="\{layout.height}" viewBox="0 0 \{layout.width} \{layout.height}" role="img" aria-label="Sequence diagram">
  let defs =
    $|<defs>
    $|\{@svg.arrow_marker_markup("arrow", marker_width=7.0, marker_height=7.0, path_class="arrow-fill")}
    $|<marker id="arrow-start" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M 10 0 L 0 5 L 10 10 z" class="arrow-fill"/></marker>
    $|<marker id="open-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M 0 0 L 10 5 L 0 10" class="arrow-open"/></marker>
    $|<marker id="open-arrow-start" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M 10 0 L 0 5 L 10 10" class="arrow-open"/></marker>
    $|</defs>
  output.write_string(defs)

  let svg_style =
    $|<style>
    $|svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}
    $|.participant rect,.activation,.note,.divider-title{stroke:\{line_color};stroke-width:1.2}
    $|.participant-label{font-size:\{base_font_size}px;font-weight:bold;fill:\{text_color}}
    $|.participant-icon{fill:none;stroke:\{line_color};stroke-width:1.1}
    $|.participant-box-group{fill-opacity:.16;stroke:\{line_color};stroke-width:1.1}
    $|.participant-box-label{font-size:\{small_font_size}px;font-weight:bold;fill:\{text_color}}
    $|.lifeline{stroke:\{defaults.lifeline};stroke-width:1;stroke-dasharray:5 5}
    $|.activation{fill:\{defaults.activation}}
    $|.message,.cross,.destroy{fill:none;stroke:\{line_color};stroke-width:1.3}
    $|.message.dotted{stroke-dasharray:5 4}
    $|.arrow-fill{fill:\{line_color}}
    $|.arrow-open{fill:none;stroke:\{line_color};stroke-width:1.5}
    $|.endpoint{fill:\{background};stroke:\{line_color};stroke-width:1.2}
    $|.message-label,.reference-label,.delay-label{fill:\{text_color};font-size:\{body_font_size}px}
    $|.note-label{fill:\{text_color};font-size:\{base_font_size}px}
    $|.note,.note-fold{stroke:\{line_color};stroke-width:.5}
    $|.partial-arrow{fill:\{line_color}}
    $|.group-body{fill-opacity:.18;stroke:\{line_color};stroke-width:1.1}
    $|.group-body-colored,.group-branch{fill-opacity:1}
    $|.group-branch{stroke:none}
    $|.group-header{stroke:\{line_color};stroke-width:1.1}
    $|.group-label{font-size:\{body_font_size}px;font-weight:bold;fill:\{text_color}}
    $|.note{fill:\{defaults.note}}
    $|.hex-note{stroke-dasharray:2 1}
    $|.box-note{rx:0}
    $|.divider{stroke:\{defaults.divider};stroke-width:1}
    $|.divider-title{fill:\{defaults.divider_title}}
    $|.divider-label{font-size:\{body_font_size}px;font-weight:bold}
    $|.delay{stroke:\{defaults.delay};stroke-dasharray:3 3}
    $|.reference{fill:\{background};stroke:\{line_color};stroke-width:1.2}
    $|.reference-tab{fill:\{defaults.reference_tab};stroke:\{line_color};stroke-width:1.2}
    $|.reference-tab-label{fill:\{text_color};font-size:\{body_font_size}px;font-weight:bold}
    $|.group-separator{stroke:\{line_color};stroke-dasharray:4 3}
    $|.page-break{stroke:\{defaults.page_break};stroke-width:1.2;stroke-dasharray:8 4}
    $|.page-label{font-size:\{body_font_size}px;font-style:italic}
    $|.destroy{stroke-width:2}
    $|</style>
  output.write_string(svg_style)
}

///|
/// Render a parsed sequence diagram as a standalone SVG document.
///
/// The renderer follows PlantUML's sequence-diagram ordering: participant
/// headers determine horizontal constraints, events reserve vertical space,
/// and group, lifeline, activation, and message layers are then painted in
/// that order.
pub fn SequenceDiagram::render_svg(
  self : SequenceDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme) }
  let layout = self.layout()
  let output = StringBuilder()
  append_svg_preamble(output, layout, self.style)
  let background = self.style.canvas_color()
  output <+
    $|<rect x="0" y="0" width="\{layout.width}" height="\{layout.height}" fill="\{background}"/>
  append_groups(output, layout)
  append_participant_boxes(output, layout)
  for participant in layout.participants {
    append_participant(
      output,
      participant,
      layout.participant_head_y(participant),
      false,
    )
  }
  append_lifelines(output, layout, self.events)
  append_activations(output, layout)
  for y in layout.auto_page_breaks {
    append_line(output, 18, y, layout.width - 18, y, "page-break")
  }
  let mut arrow_anchor : Message? = None
  for index, event in self.events {
    append_event(output, layout, event, layout.placements[index], arrow_anchor)
    match event {
      Message(message) => arrow_anchor = Some(message)
      _ => ()
    }
  }
  append_destroy_marks(output, layout)
  if self.show_footbox {
    append_footboxes(output, layout)
  }
  output.write_string("</svg>\n")
  output.to_string()
}

///|
/// Parse PlantUML sequence-diagram text and render it as standalone SVG.
pub fn render_sequence_svg(
  input : String,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @parse.ParseError {
  parse(input).render_svg(color_scheme~)
}
