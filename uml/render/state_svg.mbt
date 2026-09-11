///|

///|
const STATE_CORNER_RADIUS : Double = 12.5

///|
const STATE_THIN_STROKE_WIDTH : Double = 0.5

///|
const STATE_TERMINAL_STROKE_WIDTH : Double = 1.0

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
fn state_class(name : String) -> @graphics.Metadata {
  { ..@graphics.Metadata::default(), class_name: Some(name), }
}

///|
fn state_paint(
  fill : @graphics.Paint,
  stroke : @graphics.Paint,
  width : Double,
) -> @graphics.DrawingStyle {
  {
    ..@graphics.DrawingStyle::default(),
    fill,
    stroke,
    stroke_width: Some(width),
  }
}

///|
fn define_state_cross_marker(
  document : @svg.SvgDocument,
  style : @style.DocumentStyle,
) -> @graphics.MarkerRef {
  let center = STATE_CROSS_MARKER_CENTER
  let diagonal = STATE_CROSS_MARKER_DIAGONAL
  let marker_size = STATE_CROSS_MARKER_DIAMETER +
    STATE_CROSS_MARKER_PADDING * 2.0
  document.define_marker(
    "state-cross-start",
    {
      origin: {
        x: -STATE_CROSS_MARKER_PADDING,
        y: -STATE_CROSS_MARKER_PADDING,
      },
      viewport: { width: marker_size, height: marker_size, },
      reference: { x: center, y: center, },
      size: { width: marker_size, height: marker_size, },
      units: UserSpace,
      orientation: Auto,
    },
    output => {
      output
      .with_style(
        state_paint(
          Color(style.canvas_color()),
          Color(style.diagram_line_color()),
          @svg.EMPHASIZED_STROKE_WIDTH,
        ),
      )
      .draw(Circle(center={ x: center, y: center, }, radius=center))
      output
      .with_style(
        state_paint(
          None,
          Color(style.diagram_line_color()),
          STATE_TERMINAL_STROKE_WIDTH,
        ),
      )
      .draw(
        Path([
          MoveTo({ x: center - diagonal, y: center - diagonal, }),
          LineTo({ x: center + diagonal, y: center + diagonal, }),
          MoveTo({ x: center + diagonal, y: center - diagonal, }),
          LineTo({ x: center - diagonal, y: center + diagonal, }),
        ]),
      )
    },
  )
}

///|
fn append_state_label(
  output : @graphics.Graphic,
  text : String,
  x : Double,
  y : Double,
  class_name : String,
  text_metrics : @metrics.FontMetrics,
) -> Unit {
  output.draw(
    TextBlock(
      @svg.layout_multiline_text(
        x,
        y,
        text,
        line_height=text_metrics.line_height.to_double(),
        anchor=Center,
        text_anchor=Middle,
        text_metrics=Some(text_metrics),
      ),
    ),
    metadata=state_class(class_name),
  )
}

///|
fn append_state_node(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  layout : StateNodeLayout,
) -> Unit {
  guard diagram.state(layout.code) is Some(state) else { return }
  let composite = diagram.has_children(state.code)
  let empty_description = state.kind == @flow.StateKind::Normal &&
    !state.has_description() &&
    diagram.hide_empty_description()
  let metadata = {
    ..state_class(
      if composite {
        "state-node state-composite"
      } else {
        "state-node"
      },
    ),
    data: [
      ("code", state.code),
      (
        "shape",
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
      ..state.stereotype.map_or([], stereotype => [("stereotype", stereotype)]),
    ],
  }
  output.group(metadata, output => {
    let paint = output => {
      append_state_node_body(
        output,
        diagram,
        state,
        layout,
        composite~,
        empty_description~,
      )
    }
    if state.url is Some(url) {
      output.link(url, paint)
    } else {
      paint(output)
    }
  })
}

///|
fn append_state_node_body(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  state : @flow.StateNode,
  layout : StateNodeLayout,
  composite~ : Bool,
  empty_description~ : Bool,
) -> Unit {
  let x = layout.x
  let y = layout.y
  let width = layout.width
  let height = layout.height
  let center_x = x + width / 2.0
  let center_y = y + height / 2.0
  let center : @graphics.Point = { x: center_x, y: center_y, }
  if composite {
    let corner = STATE_CORNER_RADIUS
    let header_bottom = y + STATE_HEADER_HEIGHT
    output
    .with_style({
      ..@graphics.DrawingStyle::default(),
      fill: Color(composite_state_background_color(state, diagram.style)),
    })
    .draw(
      Path([
        MoveTo({ x: x + corner, y, }),
        LineTo({ x: x + width - corner, y, }),
        ArcTo(rx=corner, ry=corner, rotation=0.0, large_arc=false, sweep=true, end={
          x: x + width,
          y: y + corner,
        }),
        LineTo({ x: x + width, y: header_bottom, }),
        LineTo({ x, y: header_bottom, }),
        LineTo({ x, y: y + corner, }),
        ArcTo(rx=corner, ry=corner, rotation=0.0, large_arc=false, sweep=true, end={
          x: x + corner,
          y,
        }),
        Close,
      ]),
    )
    let border = output.with_style(
      state_paint(
        None,
        Color(composite_state_border_color(state, diagram.style)),
        STATE_THIN_STROKE_WIDTH,
      ),
    )
    border.draw(
      Rectangle(origin={ x, y, }, width~, height~, rx=Some(corner), ry=None),
    )
    border.draw(
      Line({ x, y: header_bottom, }, { x: x + width, y: header_bottom, }),
    )
    append_state_label(
      output,
      state.display,
      center_x,
      y + STATE_HEADER_HEIGHT / 2.0 + 4.0,
      "state-label",
      resolve_state_font(diagram.style, StateLabel).metrics,
    )
    return
  }
  match state.kind {
    @flow.StateKind::Initial =>
      output
      .with_style(
        state_paint(
          Color(initial_background_color(diagram.style)),
          Color(terminal_border_color(diagram.style)),
          STATE_TERMINAL_STROKE_WIDTH,
        ),
      )
      .draw(
        Circle(center~, radius=width.min(height) / 2.0),
        metadata=state_class("state-initial"),
      )
    @flow.StateKind::Final => {
      let radius = width.min(height) / 2.0
      output
      .with_style(
        state_paint(
          None,
          Color(final_border_color(diagram.style)),
          STATE_TERMINAL_STROKE_WIDTH,
        ),
      )
      .draw(Circle(center~, radius~), metadata=state_class("state-final-outer"))
      output
      .with_style(
        state_paint(
          Color(terminal_border_color(diagram.style)),
          Color(final_border_color(diagram.style)),
          STATE_TERMINAL_STROKE_WIDTH,
        ),
      )
      .draw(
        Circle(center~, radius=(radius - 5.0).max(1.0)),
        metadata=state_class("state-final-inner"),
      )
    }
    @flow.StateKind::History | @flow.StateKind::DeepHistory => {
      output
      .with_style(
        state_paint(
          Color(diamond_background_color(diagram.style)),
          Color(diamond_border_color(diagram.style)),
          STATE_THIN_STROKE_WIDTH,
        ),
      )
      .draw(
        Circle(center~, radius=width.min(height) / 2.0),
        metadata=state_class(
          if state.kind == @flow.StateKind::DeepHistory {
            "state-deep-history"
          } else {
            "state-history"
          },
        ),
      )
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
        resolve_state_font(diagram.style, DiamondLabel).metrics,
      )
    }
    @flow.StateKind::Synchronization =>
      output
      .with_style({
        ..@graphics.DrawingStyle::default(),
        fill: Color(synchronization_background_color(diagram.style)),
        stroke: None,
      })
      .draw(
        Rectangle(
          origin={ x, y: center_y - height / 2.0, },
          width~,
          height~,
          rx=None,
          ry=None,
        ),
        metadata=state_class("state-synchronization"),
      )
    @flow.StateKind::Choice =>
      output
      .with_style(
        state_paint(
          Color(diamond_background_color(diagram.style)),
          Color(diamond_border_color(diagram.style)),
          STATE_THIN_STROKE_WIDTH,
        ),
      )
      .draw(
        Path([
          MoveTo({ x: center_x, y, }),
          LineTo({ x: x + width, y: center_y, }),
          LineTo({ x: center_x, y: y + height, }),
          LineTo({ x, y: center_y, }),
          Close,
        ]),
        metadata=state_class("state-choice"),
      )
    @flow.StateKind::Normal => {
      output
      .with_style(
        state_paint(
          Color(state_background_color(state, diagram.style)),
          Color(state_border_color(state, diagram.style)),
          STATE_THIN_STROKE_WIDTH,
        ),
      )
      .draw(
        Rectangle(
          origin={ x, y, },
          width~,
          height~,
          rx=Some(STATE_CORNER_RADIUS),
          ry=None,
        ),
      )
      if empty_description {
        append_state_label(
          output,
          state.display,
          center_x,
          center_y + 4.0,
          "state-label",
          resolve_state_font(diagram.style, StateLabel).metrics,
        )
      } else {
        output
        .with_style({
          ..@graphics.DrawingStyle::default(),
          stroke: Color(state_border_color(state, diagram.style)),
          stroke_width: Some(STATE_THIN_STROKE_WIDTH),
        })
        .draw(
          Line({ x, y: y + STATE_HEADER_HEIGHT, }, {
            x: x + width,
            y: y + STATE_HEADER_HEIGHT,
          }),
          metadata=state_class("state-compartment-separator"),
        )
        append_state_label(
          output,
          state.display,
          center_x,
          y + STATE_HEADER_HEIGHT / 2.0 + 4.0,
          "state-label",
          resolve_state_font(diagram.style, StateLabel).metrics,
        )
        if state.description is Some(description) && description.length() > 0 {
          append_state_label(
            output,
            description,
            center_x,
            y + STATE_HEADER_HEIGHT + (height - STATE_HEADER_HEIGHT) / 2.0 + 4.0,
            "state-description-label",
            resolve_state_font(diagram.style, StateDescription).metrics,
          )
        }
      }
    }
  }
}

///|
fn append_state_edge(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  edge : StateEdgeLayout,
  arrow : @graphics.MarkerRef,
  cross : @graphics.MarkerRef,
) -> Unit {
  guard edge.transition_index < diagram.transitions.length() else { return }
  let transition = diagram.transitions[edge.transition_index]
  for path in edge.paths {
    guard path.length() > 0 else { continue }
    output
    .with_style({
      ..@svg.line_drawing_style(transition.line_style),
      fill: None,
    })
    .draw(
      MarkedPath(@graphics.spline_segments(path), {
        start: if transition.has_cross_start {
          Some(cross)
        } else {
          None
        },
        end: Some(arrow),
      }),
      metadata=state_class("state-transition"),
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
/// Keep the circle offset on the terminal tangent of the clipped path.
fn append_state_circle_decoration(
  output : @graphics.Graphic,
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
  output
  .with_style(
    state_paint(
      Color(style.canvas_color()),
      Color(style.diagram_line_color()),
      @svg.EMPHASIZED_STROKE_WIDTH,
    ),
  )
  .draw(
    Ellipse(
      center={ x: center_x, y: center_y, },
      rx=STATE_CIRCLE_DECORATION_RADIUS,
      ry=STATE_CIRCLE_DECORATION_RADIUS,
    ),
  )
}

///|
fn append_state_region_separator(
  output : @graphics.Graphic,
  region : StateRegionLayout,
) -> Unit {
  guard region.separator is Some(separator) else { return }
  let (start, end) : (@graphics.Point, @graphics.Point) = match separator {
    @flow.StateRegionSeparator::Horizontal =>
      (
        { x: region.x, y: region.y - STATE_REGION_GAP / 2.0, },
        { x: region.x + region.width, y: region.y - STATE_REGION_GAP / 2.0, },
      )
    @flow.StateRegionSeparator::Vertical =>
      (
        { x: region.x - STATE_REGION_GAP / 2.0, y: region.y, },
        { x: region.x - STATE_REGION_GAP / 2.0, y: region.y + region.height, },
      )
  }
  output.draw(Line(start, end), metadata=state_class("state-region-separator"))
}

///|
fn append_state_note(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  layout : StateNoteLayout,
) -> Unit {
  guard layout.note_index < diagram.notes.length() else { return }
  let note = diagram.notes[layout.note_index]
  output.group(
    {
      ..state_class("state-note"),
      data: [("note-index", layout.note_index.to_string())],
    },
    output => {
      output
      .with_style(
        state_paint(
          Color(note_background_color(note, diagram.style)),
          Color(note_border_color(diagram.style)),
          STATE_THIN_STROKE_WIDTH,
        ),
      )
      .draw(
        Rectangle(
          origin={ x: layout.x, y: layout.y, },
          width=layout.width,
          height=layout.height,
          rx=None,
          ry=None,
        ),
      )
      append_state_label(
        output,
        note.text,
        layout.x + layout.width / 2.0,
        layout.y + layout.height / 2.0 + 5.0,
        "state-note-label",
        resolve_state_font(diagram.style, NoteLabel).metrics,
      )
    },
  )
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
  let document = @svg.SvgDocument::empty(width, height, "State diagram")
  let arrow = document.arrow_marker(
    "state-arrow",
    marker_width=6.0,
    marker_height=6.0,
    fill=self.style.diagram_line_color(),
  )
  let cross = define_state_cross_marker(document, self.style)
  let state_font = resolve_state_font(self.style, StateLabel)
  let state_description_font = resolve_state_font(self.style, StateDescription)
  let diamond_font = resolve_state_font(self.style, DiamondLabel)
  let note_font = resolve_state_font(self.style, NoteLabel)
  document.stylesheet(
    (
      $|.state-transition{stroke:\{self.style.diagram_line_color()};stroke-width:\{@svg.emphasized_stroke_width()}}
      $|.state-region-separator{stroke:\{self.style.diagram_line_color()};stroke-width:\{@svg.standard_border_stroke_width()}}
      $|.state-label{font-family:\{state_font.family};font-size:\{state_font.size}px;fill:\{state_font.color}}
      $|.state-description-label{font-family:\{state_description_font.family};font-size:\{state_description_font.size}px;fill:\{state_description_font.color}}
      $|.state-pseudostate-label{font-family:\{diamond_font.family};font-size:\{diamond_font.size}px;fill:\{diamond_font.color}}
      $|.state-transition-label{font-family:\{self.style.font_family()};font-size:\{@svg.auxiliary_label_font_size()};fill:\{self.style.diagram_text_color()}}
      $|.state-note-label{font-family:\{note_font.family};font-size:\{note_font.size}px;fill:\{note_font.color}},
    ),
  )
  let output = document.graphic()
  output
  .with_style({
    ..@graphics.DrawingStyle::default(),
    fill: Color(self.style.canvas_color()),
  })
  .draw(
    Rectangle(
      origin={ x: 0.0, y: 0.0, },
      width=width.to_double(),
      height=height.to_double(),
      rx=None,
      ry=None,
    ),
    metadata=state_class("state-canvas"),
  )
  for edge in layout.edges {
    append_state_edge(output, self, edge, arrow, cross)
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
  document.to_string()
}

///|
/// Render a parsed state diagram to SVG.
pub fn render_state_svg(
  diagram : @flow.StateDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @dot_layout.DotLayoutError {
  diagram.render_svg(color_scheme~)
}
