///|
fn state_fill(state : StateNode) -> String {
  match state.kind {
    Initial | Final | History | DeepHistory | Synchronization =>
      @core.render_defaults().diagram_line
    _ => @core.svg_color(state.color, @core.render_defaults().node_background)
  }
}

///|
fn append_state_label(
  output : @core.XmlWriter,
  text : String,
  x : Double,
  y : Double,
  class_name : String,
) -> Unit {
  output.raw(
    @core.multiline_text_markup(
      x,
      y,
      text,
      [("text-anchor", "middle"), ("class", class_name)],
      line_height=16.0,
    ),
  )
}

///|
fn append_state_node(
  output : @core.XmlWriter,
  diagram : StateDiagram,
  layout : StateNodeLayout,
) -> Unit {
  guard diagram.state(layout.code) is Some(state) else { return }
  let x = layout.x
  let y = layout.y
  let width = layout.width
  let height = layout.height
  let center_x = x + width / 2.0
  let center_y = y + height / 2.0
  let composite = diagram.has_children(state.code)
  output.open("g", attributes=[
    (
      "class",
      if composite {
        "state-node state-composite"
      } else {
        "state-node"
      },
    ),
    ("data-code", state.code),
  ])
  if composite {
    let corner = 12.5
    let header_bottom = y + STATE_HEADER_HEIGHT
    output.empty("path", attributes=[
      (
        "d",
        "M " +
        (x + corner).to_string() +
        " " +
        y.to_string() +
        " L " +
        (x + width - corner).to_string() +
        " " +
        y.to_string() +
        " A " +
        corner.to_string() +
        " " +
        corner.to_string() +
        " 0 0 1 " +
        (x + width).to_string() +
        " " +
        (y + corner).to_string() +
        " L " +
        (x + width).to_string() +
        " " +
        header_bottom.to_string() +
        " L " +
        x.to_string() +
        " " +
        header_bottom.to_string() +
        " L " +
        x.to_string() +
        " " +
        (y + corner).to_string() +
        " A " +
        corner.to_string() +
        " " +
        corner.to_string() +
        " 0 0 1 " +
        (x + corner).to_string() +
        " " +
        y.to_string() +
        " Z",
      ),
      ("fill", state_fill(state)),
    ])
    output.empty("rect", attributes=[
      ("x", x.to_string()),
      ("y", y.to_string()),
      ("width", width.to_string()),
      ("height", height.to_string()),
      ("rx", corner.to_string()),
      ("fill", "none"),
      ("stroke", diagram.style.diagram_line_color()),
      ("stroke-width", "0.5"),
    ])
    output.empty("line", attributes=[
      ("x1", x.to_string()),
      ("y1", header_bottom.to_string()),
      ("x2", (x + width).to_string()),
      ("y2", header_bottom.to_string()),
      ("stroke", "#181818"),
      ("stroke-width", "0.5"),
    ])
    append_state_label(
      output,
      state.display,
      center_x,
      y + STATE_HEADER_HEIGHT / 2.0 + 4.0,
      "state-label",
    )
    output.close()
    return
  }
  match state.kind {
    Initial =>
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (width.min(height) / 2.0).to_string()),
        ("fill", state_fill(state)),
      ])
    Final => {
      let radius = width.min(height) / 2.0
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", radius.to_string()),
        ("fill", "none"),
        ("stroke", "#181818"),
        ("stroke-width", "2"),
      ])
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (radius - 5.0).max(1.0).to_string()),
        ("fill", state_fill(state)),
      ])
    }
    History | DeepHistory => {
      output.empty("circle", attributes=[
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (width.min(height) / 2.0).to_string()),
        ("fill", "#FFFFFF"),
        ("stroke", "#181818"),
      ])
      append_state_label(
        output,
        if state.kind == DeepHistory {
          "H*"
        } else {
          "H"
        },
        center_x,
        center_y + 5.0,
        "state-pseudostate-label",
      )
    }
    Synchronization =>
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", (center_y - height / 2.0).to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("fill", state_fill(state)),
      ])
    Choice => {
      output.empty("path", attributes=[
        (
          "d",
          "M " +
          center_x.to_string() +
          " " +
          y.to_string() +
          " L " +
          (x + width).to_string() +
          " " +
          center_y.to_string() +
          " L " +
          center_x.to_string() +
          " " +
          (y + height).to_string() +
          " L " +
          x.to_string() +
          " " +
          center_y.to_string() +
          " Z",
        ),
        ("fill", state_fill(state)),
        ("stroke", "#181818"),
      ])
      append_state_label(
        output,
        state.display,
        center_x,
        center_y + 5.0,
        "state-label",
      )
    }
    Normal => {
      let description = state.description.unwrap_or("")
      let text = if description.length() == 0 {
        state.display
      } else {
        state.display + "\n" + description
      }
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("rx", "12.5"),
        ("fill", state_fill(state)),
        ("stroke", "#181818"),
        ("stroke-width", "0.5"),
      ])
      output.empty("line", attributes=[
        ("x1", x.to_string()),
        ("y1", (y + STATE_HEADER_HEIGHT).to_string()),
        ("x2", (x + width).to_string()),
        ("y2", (y + STATE_HEADER_HEIGHT).to_string()),
        ("stroke", "#181818"),
        ("stroke-width", "0.5"),
      ])
      append_state_label(
        output,
        text,
        center_x,
        y + STATE_HEADER_HEIGHT / 2.0 + 4.0,
        "state-label",
      )
    }
  }
  output.close()
}

///|
fn append_state_edge(
  output : @core.XmlWriter,
  diagram : StateDiagram,
  edge : StateEdgeLayout,
) -> Unit {
  guard edge.transition_index < diagram.transitions.length() else { return }
  let transition = diagram.transitions[edge.transition_index]
  for path in edge.paths {
    guard path.length() > 0 else { continue }
    output.empty(
      "path",
      attributes=[
        ("d", @core.spline_path_data(path)),
        ("class", "state-transition"),
        ("fill", "none"),
        ("marker-end", "url(#state-arrow)"),
        ..@core.line_style_attributes(transition.line_style),
      ],
    )
  }
  match (transition.label, edge.label) {
    (Some(label), Some(position)) =>
      append_state_label(
        output,
        label,
        position.0,
        position.1 - 5.0,
        "state-transition-label",
      )
    _ => ()
  }
}

///|
fn append_state_region_separator(
  output : @core.XmlWriter,
  region : StateRegionLayout,
) -> Unit {
  match region.separator {
    Some(Horizontal) =>
      output.empty("line", attributes=[
        ("x1", region.x.to_string()),
        ("y1", (region.y - STATE_REGION_GAP / 2.0).to_string()),
        ("x2", (region.x + region.width).to_string()),
        ("y2", (region.y - STATE_REGION_GAP / 2.0).to_string()),
        ("class", "state-region-separator"),
      ])
    Some(Vertical) =>
      output.empty("line", attributes=[
        ("x1", (region.x - STATE_REGION_GAP / 2.0).to_string()),
        ("y1", region.y.to_string()),
        ("x2", (region.x - STATE_REGION_GAP / 2.0).to_string()),
        ("y2", (region.y + region.height).to_string()),
        ("class", "state-region-separator"),
      ])
    None => ()
  }
}

///|
fn append_state_note(
  output : @core.XmlWriter,
  diagram : StateDiagram,
  layout : StateNoteLayout,
) -> Unit {
  guard layout.note_index < diagram.notes.length() else { return }
  let note = diagram.notes[layout.note_index]
  output.open("g", attributes=[
    ("class", "state-note"),
    ("data-note-index", layout.note_index.to_string()),
  ])
  output.empty("rect", attributes=[
    ("x", layout.x.to_string()),
    ("y", layout.y.to_string()),
    ("width", layout.width.to_string()),
    ("height", layout.height.to_string()),
    ("fill", @core.render_defaults().note_background),
    ("stroke", @core.render_defaults().diagram_line),
  ])
  append_state_label(
    output,
    note.text,
    layout.x + layout.width / 2.0,
    layout.y + layout.height / 2.0 + 5.0,
    "state-note-label",
  )
  output.close()
}

///|
pub fn StateDiagram::render_svg(self : StateDiagram) -> String {
  let layout = Some(self.layout()) catch { _ => None }
  let width = layout.map_or(1.0, value => value.width).ceil().to_int().max(1)
  let height = layout.map_or(1.0, value => value.height).ceil().to_int().max(1)
  let output = @core.XmlWriter::new()
  output.open("svg", attributes=[
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", width.to_string()),
    ("height", height.to_string()),
    ("viewBox", "0 0 " + width.to_string() + " " + height.to_string()),
    ("role", "img"),
    ("aria-label", "State diagram"),
  ])
  output.open("defs")
  output.raw(
    @core.arrow_marker_markup("state-arrow", marker_width=6.0, marker_height=6.0),
  )
  output.close()
  output.open("style")
  output.raw(
    ".state-transition{stroke:" +
    self.style.diagram_line_color() +
    ";stroke-width:1.5}.state-region-separator{stroke:" +
    self.style.diagram_line_color() +
    ";stroke-width:1.2}.state-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:" +
    @core.font_size(self.style) +
    ";fill:" +
    self.style.diagram_text_color() +
    "}.state-pseudostate-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:12px;fill:" +
    self.style.diagram_text_color() +
    "}.state-transition-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:12px;fill:" +
    self.style.diagram_text_color() +
    "}.state-note-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:12px;fill:" +
    self.style.diagram_text_color() +
    "}",
  )
  output.close()
  match layout {
    Some(layout) => {
      for edge in layout.edges {
        append_state_edge(output, self, edge)
      }
      for region in layout.regions {
        append_state_region_separator(output, region)
      }
      for node in layout.nodes {
        append_state_node(output, self, node)
      }
      for note in layout.notes {
        append_state_note(output, self, note)
      }
    }
    None => ()
  }
  output.close()
  output.to_string()
}

///|
pub fn render_state_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}
