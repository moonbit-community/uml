///|
let state_node_width = 152

///|
let state_node_height = 54

///|
let state_node_gap = 54

///|
let state_canvas_padding = 28

///|
fn state_position(index : Int, columns : Int) -> (Int, Int) {
  let column = index % columns
  let row = index / columns
  (
    state_canvas_padding + column * (state_node_width + state_node_gap),
    state_canvas_padding + row * (state_node_height + state_node_gap),
  )
}

///|
fn state_index(diagram : StateDiagram, code : String) -> Int? {
  for index, state in diagram.states {
    if state.code == code {
      return Some(index)
    }
  }
  None
}

///|
fn state_fill(state : StateNode) -> String {
  match state.kind {
    Initial | Final | History | DeepHistory | Synchronization => "#181818"
    _ => @core.svg_color(state.color, "#FEFECE")
  }
}

///|
fn append_state_node(
  output : @core.XmlWriter,
  state : StateNode,
  index : Int,
  columns : Int,
) -> Unit {
  let (x, y) = state_position(index, columns)
  output.open("g", attributes=[
    ("class", "state-node"),
    ("data-code", state.code),
  ])
  match state.kind {
    Initial =>
      output.empty("circle", attributes=[
        ("cx", (x + state_node_width / 2).to_string()),
        ("cy", (y + state_node_height / 2).to_string()),
        ("r", "9"),
        ("fill", state_fill(state)),
      ])
    Final => {
      output.empty("circle", attributes=[
        ("cx", (x + state_node_width / 2).to_string()),
        ("cy", (y + state_node_height / 2).to_string()),
        ("r", "12"),
        ("fill", "none"),
        ("stroke", "#181818"),
        ("stroke-width", "2"),
      ])
      output.empty("circle", attributes=[
        ("cx", (x + state_node_width / 2).to_string()),
        ("cy", (y + state_node_height / 2).to_string()),
        ("r", "7"),
        ("fill", state_fill(state)),
      ])
    }
    Synchronization =>
      output.empty("rect", attributes=[
        ("x", (x + 18).to_string()),
        ("y", (y + state_node_height / 2 - 3).to_string()),
        ("width", (state_node_width - 36).to_string()),
        ("height", "6"),
        ("fill", state_fill(state)),
      ])
    _ => {
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", state_node_width.to_string()),
        ("height", state_node_height.to_string()),
        ("rx", "8"),
        ("fill", state_fill(state)),
        ("stroke", "#181818"),
      ])
      output.text("text", state.display, attributes=[
        ("x", (x + state_node_width / 2).to_string()),
        ("y", (y + state_node_height / 2 + 5).to_string()),
        ("text-anchor", "middle"),
        ("class", "state-label"),
      ])
    }
  }
  output.close()
}

///|
fn append_transition(
  output : @core.XmlWriter,
  diagram : StateDiagram,
  transition : StateTransition,
  columns : Int,
) -> Unit {
  guard state_index(diagram, transition.source) is Some(source_index) else {
    return
  }
  guard state_index(diagram, transition.target) is Some(target_index) else {
    return
  }
  let (source_x, source_y) = state_position(source_index, columns)
  let (target_x, target_y) = state_position(target_index, columns)
  let x1 = source_x + state_node_width / 2
  let y1 = source_y + state_node_height / 2
  let x2 = target_x + state_node_width / 2
  let y2 = target_y + state_node_height / 2
  let attributes = [
    ("x1", x1.to_string()),
    ("y1", y1.to_string()),
    ("x2", x2.to_string()),
    ("y2", y2.to_string()),
    ("class", "state-transition"),
    ("marker-end", "url(#state-arrow)"),
    ..match transition.line_style {
      Some("dashed") | Some("dotted") => [("stroke-dasharray", "6 4")]
      Some("bold") => [("stroke-width", "3")]
      _ => []
    },
  ]
  output.empty("line", attributes~)
  match transition.label {
    Some(label) =>
      output.text("text", label, attributes=[
        ("x", ((x1 + x2) / 2).to_string()),
        ("y", ((y1 + y2) / 2 - 7).to_string()),
        ("text-anchor", "middle"),
        ("class", "state-transition-label"),
      ])
    None => ()
  }
}

///|
pub fn StateDiagram::render_svg(self : StateDiagram) -> String {
  let columns = self.states.length().min(3).max(1)
  let rows = (self.states.length() + columns - 1) / columns
  let width = state_canvas_padding * 2 +
    columns * state_node_width +
    (columns - 1) * state_node_gap
  let height = state_canvas_padding * 2 +
    rows * state_node_height +
    (rows - 1) * state_node_gap
  let output = @core.XmlWriter::new()
  output.open("svg", attributes=[
    ("xmlns", "http://www.w3.org/2000/svg"),
    ("width", width.to_string()),
    ("height", height.to_string()),
    ("viewBox", "0 0 \{width} \{height}"),
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
    ".state-transition{stroke:#181818;stroke-width:1.5}.state-label{font-family:sans-serif;font-size:14px}.state-transition-label{font-family:sans-serif;font-size:12px;fill:#181818}",
  )
  output.close()
  self.transitions.each(transition => {
    append_transition(output, self, transition, columns)
  })
  self.states.eachi((index, state) => {
    append_state_node(output, state, index, columns)
  })
  output.close()
  output.to_string()
}

///|
pub fn render_state_svg(input : String) -> String raise @core.ParseError {
  parse(input).render_svg()
}
