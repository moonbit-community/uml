///|
fn state_fill(state : StateNode) -> String {
  match state.kind {
    Initial | Final | History | DeepHistory | Synchronization => "#181818"
    _ => @core.svg_color(state.color, "#FEFECE")
  }
}

///|
fn state_path_data(points : Array[(Double, Double)]) -> String {
  guard points.length() > 0 else { return "" }
  let output = StringBuilder()
  output.write_string("M ")
  output.write_string(points[0].0.to_string())
  output.write_string(" ")
  output.write_string(points[0].1.to_string())
  if (points.length() - 1) % 3 == 0 {
    let mut index = 1
    while index < points.length() {
      output.write_string(" C ")
      for offset in 0..<3 {
        let point = points[index + offset]
        output.write_string(point.0.to_string())
        output.write_string(" ")
        output.write_string(point.1.to_string())
        if offset < 2 {
          output.write_string(" ")
        }
      }
      index += 3
    }
  } else {
    for index in 1..<points.length() {
      let point = points[index]
      output.write_string(" L ")
      output.write_string(point.0.to_string())
      output.write_string(" ")
      output.write_string(point.1.to_string())
    }
  }
  output.to_string()
}

///|
fn append_state_label(
  output : @core.XmlWriter,
  text : String,
  x : Double,
  y : Double,
  class_name : String,
) -> Unit {
  let lines = text.split("\n").to_array()
  output.open("text", attributes=[
    ("x", x.to_string()),
    ("y", (y - (lines.length() - 1).to_double() * 8.0).to_string()),
    ("text-anchor", "middle"),
    ("class", class_name),
  ])
  for index, line in lines {
    output.text("tspan", line.to_owned(), attributes=[
      ("x", x.to_string()),
      ("dy", if index == 0 { "0" } else { "16" }),
    ])
  }
  output.close()
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
    output.empty("rect", attributes=[
      ("x", x.to_string()),
      ("y", y.to_string()),
      ("width", width.to_string()),
      ("height", height.to_string()),
      ("rx", "8"),
      ("fill", state_fill(state)),
      ("stroke", "#181818"),
    ])
    append_state_label(
      output,
      state.display,
      center_x,
      y + STATE_HEADER_HEIGHT / 2.0 + 5.0,
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
        ("rx", "8"),
        ("fill", state_fill(state)),
        ("stroke", "#181818"),
      ])
      append_state_label(output, text, center_x, center_y + 5.0, "state-label")
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
        ("d", state_path_data(path)),
        ("class", "state-transition"),
        ("fill", "none"),
        ("marker-end", "url(#state-arrow)"),
        ..match transition.line_style {
          Some("dashed") | Some("dotted") => [("stroke-dasharray", "6 4")]
          Some("bold") => [("stroke-width", "3")]
          _ => []
        },
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
    ("fill", "#FEFFDD"),
    ("stroke", "#181818"),
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
  output.open("marker", attributes=[
    ("id", "state-arrow"),
    ("viewBox", "0 0 10 10"),
    ("refX", "9"),
    ("refY", "5"),
    ("markerWidth", "6"),
    ("markerHeight", "6"),
    ("orient", "auto-start-reverse"),
  ])
  output.empty("path", attributes=[("d", "M 0 0 L 10 5 L 0 10 z")])
  output.close()
  output.close()
  output.open("style")
  output.raw(
    ".state-transition{stroke:" + self.style.diagram_line_color() +
    ";stroke-width:1.5}.state-region-separator{stroke:" +
    self.style.diagram_line_color() +
    ";stroke-width:1.2}.state-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:" +
    @core.font_size(self.style) +
    ";fill:#181818}.state-pseudostate-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:12px;fill:#181818}.state-transition-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:12px;fill:#181818}.state-note-label{font-family:" +
    @core.font_family(self.style) +
    ";font-size:12px;fill:#181818}",
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
