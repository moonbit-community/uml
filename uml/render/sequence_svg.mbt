///|
fn sequence_stylesheet(
  document : @svg.SvgDocument,
  style : @style.DocumentStyle,
) -> Unit {
  let background = style.canvas_color()
  let font_family = style.font_family()
  let font_size = style.font_size()
  let base_font_size = style.font_size_value(fallback=14)
  let body_font_size = (base_font_size - 1).max(1)
  let small_font_size = (base_font_size - 3).max(1)
  let line_color = sequence_colors(style).line
  let text_color = style.diagram_text_color()
  let defaults = sequence_colors(style)
  let border_width = @svg.standard_border_stroke_width()
  let emphasized_width = @svg.emphasized_stroke_width()
  let svg_style =
    $|\{@svg.svg_style_rule(font_family, font_size, background)}
    $|.participant rect{stroke:\{line_color};stroke-width:0.5}
    $|.activation{stroke:\{line_color};stroke-width:1}
    $|.note,.divider-title{stroke:\{line_color};stroke-width:\{border_width}}
    $|.participant-label{font-size:\{base_font_size}px;font-weight:normal;fill:\{text_color}}
    $|.participant-icon{stroke:\{line_color};stroke-width:0.5}
    $|.participant-box-group{stroke:\{line_color};stroke-width:0.5}
    $|.participant-box-label{font-size:\{small_font_size}px;font-weight:bold;fill:\{text_color}}
    $|.lifeline{stroke:\{defaults.lifeline};stroke-width:0.5;stroke-dasharray:\{@svg.lifeline_dash_pattern()}}
    $|.message,.cross{fill:none;stroke:\{line_color};stroke-width:1.3}
    $|.message.dotted{stroke-dasharray:\{@svg.dotted_message_dash_pattern()}}
    $|.arrow-fill{fill:context-stroke}
    $|.arrow-open{fill:none;stroke:context-stroke;stroke-width:\{emphasized_width}}
    $|.endpoint{fill:\{background};stroke:\{line_color};stroke-width:\{border_width}}
    $|.message-label,.reference-label,.delay-label{fill:\{text_color};font-size:\{body_font_size}px}
    $|.note-label{fill:\{text_color};font-size:\{base_font_size}px}
    $|.note,.note-fold{stroke:\{line_color};stroke-width:.5}
    $|.partial-arrow{fill:\{line_color}}
    $|.group-body{stroke:\{defaults.text};stroke-width:1.5}
    $|.group-branch{stroke:none}
    $|.group-header{stroke:\{line_color};stroke-width:\{@svg.secondary_structure_stroke_width()}}
    $|.group-label{font-size:\{body_font_size}px;font-weight:bold;fill:\{text_color}}
    $|.hex-note{stroke-dasharray:\{@svg.hex_note_dash_pattern()}}
    $|.box-note{rx:0}
    $|.divider{stroke:\{defaults.divider};stroke-width:1}
    $|.divider-title{fill:\{defaults.divider_title}}
    $|.divider-label{font-size:\{body_font_size}px;font-weight:bold}
    $|.delay{stroke:\{defaults.delay};stroke-dasharray:\{@svg.delay_dash_pattern()}}
    $|.reference{fill:none;stroke:\{defaults.text};stroke-width:1.5}
    $|.reference-tab{fill:\{defaults.reference_tab};stroke:\{defaults.text};stroke-width:2}
    $|.reference-tab-label{fill:\{text_color};font-size:\{body_font_size}px;font-weight:bold}
    $|.group-separator{stroke:\{line_color};stroke-dasharray:\{@svg.separator_dash_pattern()}}
    $|.page-break{stroke:\{defaults.page_break};stroke-width:\{border_width};stroke-dasharray:\{@svg.page_break_dash_pattern()}}
    $|.page-label{font-size:\{body_font_size}px;font-style:italic}
    $|.destroy{fill:none;stroke:#A80036;stroke-width:2}
  document.stylesheet(svg_style)
  let metrics = SequenceTextMetrics::new(style)
  for
    (selector, role, font) in [
      (".participant-label", "Participant", metrics.participant),
      (".note-label", "Note", metrics.note),
      (".message-label,.reference-label,.delay-label", "Arrow", metrics.body),
      (".group-label,.divider-label", "Group", metrics.body_bold),
      (".participant-box-label", "Box", metrics.small_bold),
    ] {
    let family = sequence_style_property(style, role, "FontName").unwrap_or(
      font_family,
    )
    let color = sequence_style_color(style, role, "FontColor", text_color)
    document.stylesheet(
      "\{selector}{font-family:\{family};font-size:\{font.font_size}px;font-weight:\{font.font_weight};fill:\{color}}",
    )
  }
}

///|
/// Render a parsed sequence diagram as a standalone SVG document.
///
/// The renderer follows PlantUML's sequence-diagram ordering: participant
/// headers determine horizontal constraints, events reserve vertical space,
/// and group, lifeline, activation, and message layers are then painted in
/// that order.
fn @seq.SequenceDiagram::paint_sequence_svg(
  self : @seq.SequenceDiagram,
  layout : DiagramLayout,
) -> String {
  let decoration = decorate_document_text(
    self.style,
    layout.width,
    layout.height,
  )
  let scale = self.style.output_scale(decoration.width, decoration.height)
  let document = @svg.SvgDocument::empty(
    (decoration.width * scale).ceil().to_int().max(1),
    (decoration.height * scale).ceil().to_int().max(1),
    "Sequence diagram",
    view_box=(
      { x: 0.0, y: 0.0, },
      { width: decoration.width, height: decoration.height, },
    ),
  )
  let output = sequence_drawing(document)
  sequence_stylesheet(document, self.style)
  output.draw(
    Rectangle(
      origin=sequence_point(0, 0),
      width=decoration.width,
      height=decoration.height,
      rx=None,
      ry=None,
    ),
    fill=Color(self.style.canvas_color()),
  )
  let output = {
    ..output,
    graphic: output.graphic.translated(decoration.dx, decoration.dy),
  }
  append_groups(output, layout)
  append_participant_boxes(output, layout)
  for participant in layout.participants {
    guard participant.birth_y.map_or(true, y => y < layout.body_bottom) else {
      continue
    }
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
  let mut arrow_anchor : @seq.Message? = None
  // An on-arrow note attaches to the latest event able to carry one (Java's
  // `getLastEventWithNote`). A message/exo carrier wraps its arrow in the
  // note's URL too (`AbstractMessage.getUrl`), first note wins; a reference
  // or group-leaf carrier applies no URL at all, so a note attached there
  // is drawn without its own link.
  let note_urls : Map[Int32, String] = Map([])
  let note_suppress : Map[Int32, Bool] = Map([])
  let mut last_carrier_index = -1
  let mut last_carrier_is_message = false
  for index, event in self.events {
    match event {
      @seq.Message(_) | @seq.MessageExo(_) => {
        last_carrier_index = index
        last_carrier_is_message = true
      }
      @seq.Reference(_) | @seq.GroupingLeaf(_) => {
        last_carrier_index = index
        last_carrier_is_message = false
      }
      @seq.Note(note) if note.on_arrow => {
        if !last_carrier_is_message {
          note_suppress[index] = true
        }
        if last_carrier_is_message && !note_urls.contains(last_carrier_index) {
          if note.url is Some(url) {
            note_urls[last_carrier_index] = url
          }
        }
      }
      @seq.Notes(notes) if notes[0].on_arrow => {
        if !last_carrier_is_message {
          note_suppress[index] = true
        }
        if last_carrier_is_message && !note_urls.contains(last_carrier_index) {
          if notes[0].url is Some(url) {
            note_urls[last_carrier_index] = url
          }
        }
      }
      _ => ()
    }
  }
  for index, event in self.events {
    append_event(
      output,
      layout,
      event,
      layout.placements[index],
      arrow_anchor,
      note_urls.get(index),
      note_suppress.get(index).unwrap_or(false),
    )
    match event {
      @seq.Message(message) => arrow_anchor = Some(message)
      _ => ()
    }
  }
  append_destroy_marks(output, layout)
  append_sequence_anchors(output, self, layout)
  if self.show_footbox {
    append_footboxes(output, layout)
  }
  draw_document_text(
    document.graphic(),
    self.style,
    "sequence",
    decoration.text,
  )
  document.to_string()
}

///|
/// Render a parsed sequence diagram to SVG.
pub fn render_sequence_svg(
  diagram : @seq.SequenceDiagram,
  color_scheme~ : @style.ColorScheme = @style.ColorScheme::default(),
) -> String {
  let diagram = {
    ..diagram,
    style: diagram.style.with_color_scheme(color_scheme),
  }
  diagram.paint_sequence_svg(diagram.layout())
}
