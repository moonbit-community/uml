///|

///|
const STATE_CORNER_RADIUS : Double = 12.5

///|
const STATE_THIN_STROKE_WIDTH : String = "0.5"

///|
const STATE_TERMINAL_STROKE_WIDTH : String = "1"

///|
const STATE_CROSS_MARKER_DIAMETER : Double = 14.0

///|
const STATE_CROSS_MARKER_CENTER : Double = STATE_CROSS_MARKER_DIAMETER / 2.0

///|
const STATE_CROSS_MARKER_PADDING : Double = 1.0

///|
const STATE_CROSS_MARKER_DIAGONAL : Double = 4.949747468305833

///|
/// Radius of the circle decoration drawn at the target end of a transition
/// (`A -->o B`), matching PlantUML's `LinkDecor.ARROW_AND_CIRCLE`.
const STATE_CIRCLE_DECORATION_RADIUS : Double = 5.0

///|
/// Distance from the path end to the circle decoration center, matching the
/// PlantUML baseline placement of the circle beyond the clipped path end.
const STATE_CIRCLE_DECORATION_OFFSET : Double = 8.0

///|
fn initial_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityStartColor", style.defaults().line)
}

///|
fn terminal_border_color(style : @style.DocumentStyle) -> String {
  style.defaults().line
}

///|
fn final_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityEndColor", style.defaults().line)
}

///|
fn diamond_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityDiamondBackgroundColor", style.defaults().node)
}

///|
fn diamond_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityDiamondBorderColor", style.defaults().line)
}

///|
fn diamond_font_color(style : @style.DocumentStyle) -> String {
  style.property_font_color("ActivityDiamondFontColor")
}

///|
fn diamond_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ActivityDiamondFontName")
}

///|
fn diamond_font_size(style : @style.DocumentStyle) -> Int {
  style.property_font_size("ActivityDiamondFontSize", fallback=14)
}

///|
fn diamond_font_metrics(style : @style.DocumentStyle) -> @metrics.FontMetrics {
  style.font_metrics_for(
    diamond_font_family(style),
    font_size=diamond_font_size(style),
  )
}

///|
fn synchronization_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActivityBarColor", style.defaults().line)
}

///|
fn state_style_property(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  key : String,
) -> String? {
  match state.stereotype {
    Some(stereotype) =>
      style
      .property(key + stereotype)
      .map_or(style.property(key), value => Some(value))
    None => style.property(key)
  }
}

///|
fn state_style_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
  key : String,
  fallback : String,
) -> String {
  @svg.svg_color(state_style_property(state, style, key), fallback)
}

///|
/// Resolve normal-state paint with PlantUML's inline-color precedence.
fn state_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  let fallback = state_style_color(
    state,
    style,
    "StateBackgroundColor",
    style.defaults().node,
  )
  @svg.svg_color(state.color, fallback)
}

///|
fn state_border_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_style_color(
    state,
    style,
    "StateBorderColor",
    style.diagram_line_color(),
  )
}

///|
fn composite_state_background_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_background_color(state, style)
}

///|
fn composite_state_border_color(
  state : @flow.StateNode,
  style : @style.DocumentStyle,
) -> String {
  state_border_color(state, style)
}

///|
fn state_font_color(style : @style.DocumentStyle) -> String {
  style.property_font_color("StateFontColor")
}

///|
fn state_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("StateFontName")
}

///|
fn state_font_size(style : @style.DocumentStyle) -> Int {
  style.property_font_size("StateFontSize", fallback=14)
}

///|
fn state_font_metrics(style : @style.DocumentStyle) -> @metrics.FontMetrics {
  let family = state_font_family(style)
  style.font_metrics_for(family, font_size=state_font_size(style))
}

///|
fn state_description_font_color(style : @style.DocumentStyle) -> String {
  style.property_font_color("StateAttributeFontColor")
}

///|
fn state_description_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("StateAttributeFontName")
}

///|
fn state_description_font_size(style : @style.DocumentStyle) -> Int {
  style.property_font_size("StateAttributeFontSize", fallback=14)
}

///|
fn state_description_font_metrics(
  style : @style.DocumentStyle,
) -> @metrics.FontMetrics {
  let family = state_description_font_family(style)
  style.font_metrics_for(family, font_size=state_description_font_size(style))
}

///|
fn note_background_color(
  note : @flow.StateNote,
  style : @style.DocumentStyle,
) -> String {
  let fallback = style.property_color(
    "NoteBackgroundColor",
    style.defaults().note,
  )
  @svg.svg_color(note.color, fallback)
}

///|
fn note_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("NoteBorderColor", style.diagram_line_color())
}

///|
fn note_font_color(style : @style.DocumentStyle) -> String {
  style.property_font_color("NoteFontColor")
}

///|
fn note_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("NoteFontName")
}

///|
fn note_font_size(style : @style.DocumentStyle) -> Int {
  style.property_font_size("NoteFontSize", fallback=style.font_size_value())
}

///|
fn note_font_metrics(style : @style.DocumentStyle) -> @metrics.FontMetrics {
  style.font_metrics_for(
    note_font_family(style),
    font_size=note_font_size(style),
  )
}

///|
fn append_state_cross_marker(
  output : @svg.XmlWriter,
  style : @style.DocumentStyle,
) -> Unit {
  let center = STATE_CROSS_MARKER_CENTER
  let diagonal = STATE_CROSS_MARKER_DIAGONAL
  let marker_size = STATE_CROSS_MARKER_DIAMETER +
    STATE_CROSS_MARKER_PADDING * 2.0
  output.open("marker", attributes=[
    ("id", "state-cross-start"),
    (
      "viewBox",
      (-STATE_CROSS_MARKER_PADDING).to_string() +
      " " +
      (-STATE_CROSS_MARKER_PADDING).to_string() +
      " " +
      marker_size.to_string() +
      " " +
      marker_size.to_string(),
    ),
    ("refX", center.to_string()),
    ("refY", center.to_string()),
    ("markerWidth", marker_size.to_string()),
    ("markerHeight", marker_size.to_string()),
    ("markerUnits", "userSpaceOnUse"),
    ("orient", "auto"),
  ])
  output.empty("circle", attributes=[
    ("cx", center.to_string()),
    ("cy", center.to_string()),
    ("r", center.to_string()),
    ("fill", style.canvas_color()),
    ("stroke", style.diagram_line_color()),
    ("stroke-width", @svg.emphasized_stroke_width()),
  ])
  output.empty("path", attributes=[
    (
      "d",
      "M " +
      (center - diagonal).to_string() +
      " " +
      (center - diagonal).to_string() +
      " L " +
      (center + diagonal).to_string() +
      " " +
      (center + diagonal).to_string() +
      " M " +
      (center + diagonal).to_string() +
      " " +
      (center - diagonal).to_string() +
      " L " +
      (center - diagonal).to_string() +
      " " +
      (center + diagonal).to_string(),
    ),
    ("fill", "none"),
    ("stroke", style.diagram_line_color()),
    ("stroke-width", STATE_TERMINAL_STROKE_WIDTH),
  ])
  output.close()
}

///|
fn append_state_label(
  output : @svg.XmlWriter,
  text : String,
  x : Double,
  y : Double,
  class_name : String,
  text_metrics : @metrics.FontMetrics,
) -> Unit {
  output.append_text_markup(
    x,
    y,
    text,
    [("text-anchor", "middle"), ("class", class_name)],
    line_height=text_metrics.line_height.to_double(),
    anchor=Center,
    text_metrics=Some(text_metrics),
  )
}

///|
fn append_state_node(
  output : @svg.XmlWriter,
  diagram : @flow.StateDiagram,
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
  let empty_description = state.kind == @flow.StateKind::Normal &&
    !state.has_description() &&
    diagram.hide_empty_description()
  let group_attributes = [
    (
      "class",
      if composite {
        "state-node state-composite"
      } else {
        "state-node"
      },
    ),
    ("data-code", state.code),
    (
      "data-shape",
      if composite {
        "composite"
      } else if empty_description {
        "empty"
      } else if state.kind == @flow.StateKind::Normal {
        "compartment"
      } else {
        "pseudo"
      },
    ),
  ]
  if state.stereotype is Some(stereotype) {
    group_attributes.push(("data-stereotype", stereotype))
  }
  output.open("g", attributes=group_attributes)
  if state.url is Some(url) {
    output.open("a", attributes=[("href", url)])
  }
  if composite {
    let corner = STATE_CORNER_RADIUS
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
      ("fill", composite_state_background_color(state, diagram.style)),
    ])
    output.empty("rect", attributes=[
      ("x", x.to_string()),
      ("y", y.to_string()),
      ("width", width.to_string()),
      ("height", height.to_string()),
      ("rx", corner.to_string()),
      ("fill", "none"),
      ("stroke", composite_state_border_color(state, diagram.style)),
      ("stroke-width", STATE_THIN_STROKE_WIDTH),
    ])
    output.empty("line", attributes=[
      ("x1", x.to_string()),
      ("y1", header_bottom.to_string()),
      ("x2", (x + width).to_string()),
      ("y2", header_bottom.to_string()),
      ("stroke", composite_state_border_color(state, diagram.style)),
      ("stroke-width", STATE_THIN_STROKE_WIDTH),
    ])
    append_state_label(
      output,
      state.display,
      center_x,
      y + STATE_HEADER_HEIGHT / 2.0 + 4.0,
      "state-label",
      state_font_metrics(diagram.style),
    )
    if state.url is Some(_) {
      output.close()
    }
    output.close()
    return
  }
  match state.kind {
    @flow.StateKind::Initial =>
      output.empty("circle", attributes=[
        ("class", "state-initial"),
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (width.min(height) / 2.0).to_string()),
        ("fill", initial_background_color(diagram.style)),
        ("stroke", terminal_border_color(diagram.style)),
        ("stroke-width", STATE_TERMINAL_STROKE_WIDTH),
      ])
    @flow.StateKind::Final => {
      let radius = width.min(height) / 2.0
      output.empty("circle", attributes=[
        ("class", "state-final-outer"),
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", radius.to_string()),
        ("fill", "none"),
        ("stroke", final_border_color(diagram.style)),
        ("stroke-width", STATE_TERMINAL_STROKE_WIDTH),
      ])
      output.empty("circle", attributes=[
        ("class", "state-final-inner"),
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (radius - 5.0).max(1.0).to_string()),
        ("fill", terminal_border_color(diagram.style)),
        ("stroke", final_border_color(diagram.style)),
        ("stroke-width", STATE_TERMINAL_STROKE_WIDTH),
      ])
    }
    @flow.StateKind::History | @flow.StateKind::DeepHistory => {
      output.empty("circle", attributes=[
        (
          "class",
          if state.kind == @flow.StateKind::DeepHistory {
            "state-deep-history"
          } else {
            "state-history"
          },
        ),
        ("cx", center_x.to_string()),
        ("cy", center_y.to_string()),
        ("r", (width.min(height) / 2.0).to_string()),
        ("fill", diamond_background_color(diagram.style)),
        ("stroke", diamond_border_color(diagram.style)),
        ("stroke-width", STATE_THIN_STROKE_WIDTH),
      ])
      append_state_label(
        output,
        if state.kind == @flow.StateKind::DeepHistory {
          "H*"
        } else {
          "H"
        },
        center_x,
        center_y + 5.0,
        "state-pseudostate-label",
        diamond_font_metrics(diagram.style),
      )
    }
    @flow.StateKind::Synchronization =>
      output.empty("rect", attributes=[
        ("class", "state-synchronization"),
        ("x", x.to_string()),
        ("y", (center_y - height / 2.0).to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("fill", synchronization_background_color(diagram.style)),
        ("stroke", "none"),
      ])
    @flow.StateKind::Choice =>
      output.empty("path", attributes=[
        ("class", "state-choice"),
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
        ("fill", diamond_background_color(diagram.style)),
        ("stroke", diamond_border_color(diagram.style)),
        ("stroke-width", STATE_THIN_STROKE_WIDTH),
      ])
    @flow.StateKind::Normal => {
      output.empty("rect", attributes=[
        ("x", x.to_string()),
        ("y", y.to_string()),
        ("width", width.to_string()),
        ("height", height.to_string()),
        ("rx", STATE_CORNER_RADIUS.to_string()),
        ("fill", state_background_color(state, diagram.style)),
        ("stroke", state_border_color(state, diagram.style)),
        ("stroke-width", STATE_THIN_STROKE_WIDTH),
      ])
      if empty_description {
        append_state_label(
          output,
          state.display,
          center_x,
          center_y + 4.0,
          "state-label",
          state_font_metrics(diagram.style),
        )
      } else {
        output.empty("line", attributes=[
          ("x1", x.to_string()),
          ("y1", (y + STATE_HEADER_HEIGHT).to_string()),
          ("x2", (x + width).to_string()),
          ("y2", (y + STATE_HEADER_HEIGHT).to_string()),
          ("class", "state-compartment-separator"),
          ("stroke", state_border_color(state, diagram.style)),
          ("stroke-width", STATE_THIN_STROKE_WIDTH),
        ])
        append_state_label(
          output,
          state.display,
          center_x,
          y + STATE_HEADER_HEIGHT / 2.0 + 4.0,
          "state-label",
          state_font_metrics(diagram.style),
        )
        match state.description {
          Some(description) if description.length() > 0 =>
            append_state_label(
              output,
              description,
              center_x,
              y +
              STATE_HEADER_HEIGHT +
              (height - STATE_HEADER_HEIGHT) / 2.0 +
              4.0,
              "state-description-label",
              state_description_font_metrics(diagram.style),
            )
          _ => ()
        }
      }
    }
  }
  if state.url is Some(_) {
    output.close()
  }
  output.close()
}

///|
fn append_state_edge(
  output : @svg.XmlWriter,
  diagram : @flow.StateDiagram,
  edge : StateEdgeLayout,
) -> Unit {
  guard edge.transition_index < diagram.transitions.length() else { return }
  let transition = diagram.transitions[edge.transition_index]
  for path in edge.paths {
    guard path.length() > 0 else { continue }
    output.empty(
      "path",
      attributes=[
        ("d", @svg.spline_path_data(path)),
        ("class", "state-transition"),
        ("fill", "none"),
        ..if transition.has_cross_start {
          [("marker-start", "url(#state-cross-start)")]
        },
        ("marker-end", "url(#state-arrow)"),
        ..@svg.line_style_attributes(transition.line_style),
      ],
    )
    if transition.has_circle_end {
      append_state_circle_decoration(output, diagram.style, path)
    }
  }
  match (transition.label, edge.label) {
    (Some(label), Some(position)) =>
      append_state_label(
        output,
        label,
        position.0,
        position.1 - 5.0,
        "state-transition-label",
        diagram.style.font_metrics(font_size=14),
      )
    _ => ()
  }
}

///|
/// Draws the circle decoration at the target end of a transition path. The
/// circle sits on the node border, offset past the clipped path end along the
/// end tangent, mirroring PlantUML's `ARROW_AND_CIRCLE` placement.
fn append_state_circle_decoration(
  output : @svg.XmlWriter,
  style : @style.DocumentStyle,
  path : Array[(Double, Double)],
) -> Unit {
  guard path.length() >= 2 else { return }
  let end = path[path.length() - 1]
  let previous = path[path.length() - 2]
  let dx = end.0 - previous.0
  let dy = end.1 - previous.1
  let length = (dx * dx + dy * dy).sqrt()
  guard length > 0.0 else { return }
  let center_x = end.0 + dx / length * STATE_CIRCLE_DECORATION_OFFSET
  let center_y = end.1 + dy / length * STATE_CIRCLE_DECORATION_OFFSET
  output.empty("ellipse", attributes=[
    ("cx", center_x.to_string()),
    ("cy", center_y.to_string()),
    ("rx", STATE_CIRCLE_DECORATION_RADIUS.to_string()),
    ("ry", STATE_CIRCLE_DECORATION_RADIUS.to_string()),
    ("fill", style.canvas_color()),
    ("stroke", style.diagram_line_color()),
    ("stroke-width", "1.5"),
  ])
}

///|
fn append_state_region_separator(
  output : @svg.XmlWriter,
  region : StateRegionLayout,
) -> Unit {
  match region.separator {
    Some(@flow.StateRegionSeparator::Horizontal) =>
      output.empty("line", attributes=[
        ("x1", region.x.to_string()),
        ("y1", (region.y - STATE_REGION_GAP / 2.0).to_string()),
        ("x2", (region.x + region.width).to_string()),
        ("y2", (region.y - STATE_REGION_GAP / 2.0).to_string()),
        ("class", "state-region-separator"),
      ])
    Some(@flow.StateRegionSeparator::Vertical) =>
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
  output : @svg.XmlWriter,
  diagram : @flow.StateDiagram,
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
    ("fill", note_background_color(note, diagram.style)),
    ("stroke", note_border_color(diagram.style)),
    ("stroke-width", STATE_THIN_STROKE_WIDTH),
  ])
  append_state_label(
    output,
    note.text,
    layout.x + layout.width / 2.0,
    layout.y + layout.height / 2.0 + 5.0,
    "state-note-label",
    note_font_metrics(diagram.style),
  )
  output.close()
}

///|
fn @flow.StateDiagram::render_svg(
  self : @flow.StateDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @dot_layout.DotLayoutError {
  let self = { ..self, style: self.style.with_color_scheme(color_scheme), }
  let layout = @graphviz.layout_or_fallback(() => self.layout(), None)
  let width = layout.width.ceil().to_int().max(1)
  let height = layout.height.ceil().to_int().max(1)
  let output = @svg.XmlWriter::new()
  output.open(
    "svg",
    attributes=@svg.svg_root_attributes(
      width,
      height,
      "0 0 \{width} \{height}",
      "State diagram",
    ),
  )
  output.open("defs")
  output.raw(
    @svg.arrow_marker_markup(
      "state-arrow",
      marker_width=6.0,
      marker_height=6.0,
      path_fill=self.style.diagram_line_color(),
    ),
  )
  append_state_cross_marker(output, self.style)
  output.close()
  output.open("style")
  output.raw(
    (
      $|.state-transition{stroke:\{self.style.diagram_line_color()};stroke-width:\{@svg.emphasized_stroke_width()}}
      $|.state-region-separator{stroke:\{self.style.diagram_line_color()};stroke-width:\{@svg.standard_border_stroke_width()}}
      $|.state-label{font-family:\{state_font_family(self.style)};font-size:\{state_font_size(self.style)}px;fill:\{state_font_color(self.style)}}
      $|.state-description-label{font-family:\{state_description_font_family(self.style)};font-size:\{state_description_font_size(self.style)}px;fill:\{state_description_font_color(self.style)}}
      $|.state-pseudostate-label{font-family:\{diamond_font_family(self.style)};font-size:\{diamond_font_size(self.style)}px;fill:\{diamond_font_color(self.style)}}
      $|.state-transition-label{font-family:\{self.style.font_family()};font-size:\{@svg.auxiliary_label_font_size()};fill:\{self.style.diagram_text_color()}}
      $|.state-note-label{font-family:\{note_font_family(self.style)};font-size:\{note_font_size(self.style)}px;fill:\{note_font_color(self.style)}},
    ),
  )
  output.close()
  output.empty(
    "rect",
    attributes=@svg.background_rect_attributes(
      width,
      height,
      self.style.canvas_color(),
      class_name="state-canvas",
    ),
  )
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
  output.close()
  output.to_string()
}

///|
/// Render a parsed state diagram to SVG.
pub fn render_state_svg(
  diagram : @flow.StateDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @dot_layout.DotLayoutError {
  diagram.render_svg(color_scheme~)
}
