///|

///|
const STATE_CORNER_RADIUS : Double = 12.5

///|
const STATE_THIN_STROKE_WIDTH : Double = 0.5

///|
const STATE_TERMINAL_STROKE_WIDTH : Double = 1.0

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
fn append_state_label(
  output : @graphics.Graphic,
  text : String,
  x : Double,
  y : Double,
  class_name : String,
  text_metrics : @metrics.FontMetrics,
  line_alignment? : @graphics.TextAnchor? = None,
  wrap_width? : Double = 0.0,
  monospaced_family? : String = STATE_MONOSPACED_FAMILY,
) -> Unit {
  if state_rich_text(text, text_metrics, wrap_width, monospaced_family~)
    is Some(rich) {
    let top = y -
      text_metrics.ascent.to_double() +
      text_metrics.line_height.to_double() / 2.0 -
      rich.height / 2.0
    rich.draw(
      output,
      x,
      top,
      text_metrics,
      state_class(class_name),
      Middle,
      line_alignment,
    )
    return
  }
  let display = state_display(text).wrap(text_metrics, wrap_width)
  let (x, anchor) = display.anchor_position(
    x,
    Middle,
    text_metrics,
    line_alignment~,
  )
  output.draw(
    TextBlock(
      @svg.layout_multiline_text(
        x,
        y,
        display.text,
        line_height=text_metrics.line_height.to_double(),
        anchor=Center,
        text_anchor=anchor,
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
  cluster_title_top? : Double? = None,
) -> Unit {
  guard diagram.state(layout.code) is Some(state) else { return }
  let composite = diagram.has_children(state.code)
  let empty_description = diagram.state_uses_empty_image(state)
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
        "state-index",
        diagram.states
        .search_by(node => node.code == state.code)
        .unwrap()
        .to_string(),
      ),
      (
        "shape",
        if composite {
          "composite"
        } else if state.kind == @flow.Frame {
          "package"
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
        cluster_title_top~,
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
  cluster_title_top? : Double? = None,
) -> Unit {
  let x = layout.x
  let y = layout.y
  let width = layout.width
  let height = layout.height
  let center_x = x + width / 2.0
  let center_y = y + height / 2.0
  let center : @graphics.Point = { x: center_x, y: center_y, }
  let name_metrics = resolve_state_node_font(diagram, state, StateLabel).metrics
  let description_metrics = resolve_state_font(
      diagram.style,
      StateDescription,
      state=Some(state),
    ).metrics
  let wrap_width = if composite {
    0.0
  } else {
    state_wrap_width(diagram.style, state=Some(state))
  }
  let monospaced_family = state_monospaced_family(diagram.style)
  let cluster = composite && diagram.is_state_cluster(state.code)
  let header_height = state.header_height(
    name_metrics,
    wrap_width~,
    monospaced_family~,
  )
  let header_height = if cluster {
    header_height - STATE_SEPARATOR_MARGIN
  } else {
    header_height
  }
  let corner = state_corner_radius(state, diagram.style)
  let shadow = state_node_shadow(state, diagram.style)
  if state.kind == @flow.Frame {
    append_state_frame(output, diagram, state, layout)
    return
  }
  if composite {
    let header_bottom = y + header_height
    let description_height = state.description_compartment_height(
      description_metrics,
      monospaced_family~,
    )
    // RoundedContainer paints a shadowed transparent outline before its fills.
    if shadow > 0.0 {
      output
      .with_style(state_border_paint(state, diagram.style, None))
      .draw(
        Rectangle(origin={ x, y, }, width~, height~, rx=Some(corner), ry=None),
        metadata=state_shadow_metadata(
          state_class("state-composite-shadow"),
          shadow,
        ),
      )
    }
    append_state_composite_background(
      output,
      state,
      layout,
      diagram.style,
      header_height,
      description_height,
      corner,
    )
    let border = output.with_style(
      state_border_paint(state, diagram.style, None),
    )
    border.draw(
      Rectangle(origin={ x, y, }, width~, height~, rx=Some(corner), ry=None),
    )
    border.draw(
      Line({ x, y: header_bottom, }, { x: x + width, y: header_bottom, }),
    )
    if description_height > 0.0 {
      border.draw(
        Line({ x, y: header_bottom + description_height, }, {
          x: x + width,
          y: header_bottom + description_height,
        }),
      )
      append_state_description(
        output,
        state,
        layout,
        header_bottom + (if cluster { STATE_TEXT_MARGIN / 2.0 } else { 0.0 }),
        diagram.style,
        description_metrics,
        align_within_state=!cluster,
      )
    }
    let alignment = state_text_alignment(state, diagram.style, fallback=Middle)
    let anchor = if cluster { alignment } else { @graphics.TextAnchor::Middle }
    let title_x = x +
      STATE_TEXT_MARGIN +
      state_text_anchor_offset(anchor, width - 2.0 * STATE_TEXT_MARGIN)
    append_state_text_at_top(
      output,
      state.display,
      title_x,
      cluster_title_top.unwrap_or(y + STATE_TEXT_MARGIN),
      "state-label",
      name_metrics,
      anchor~,
      line_alignment=Some(alignment),
      state=Some(state),
      monospaced_family~,
    )
    append_state_submachine_symbol(
      output,
      state,
      layout,
      state_paint(
        None,
        Color(composite_state_border_color(state, diagram.style)),
        STATE_BACKGROUND_STROKE_WIDTH,
      ),
    )
    return
  }
  match state.kind {
    @flow.StateKind::Initial =>
      output
      .with_style(
        state_paint(
          Color(state_terminal_background_color(state, diagram.style)),
          Color(state_terminal_border_color(state, diagram.style)),
          STATE_TERMINAL_STROKE_WIDTH,
        ),
      )
      .draw(
        Circle(center~, radius=width.min(height) / 2.0),
        metadata=state_shadow_metadata(state_class("state-initial"), shadow),
      )
    @flow.StateKind::Final => {
      let radius = width.min(height) / 2.0
      let background = state_terminal_background_color(state, diagram.style)
      let border = state_terminal_border_color(state, diagram.style)
      output
      .with_style(state_paint(None, Color(border), STATE_TERMINAL_STROKE_WIDTH))
      .draw(
        Circle(center~, radius~),
        metadata=state_shadow_metadata(state_class("state-final-outer"), shadow),
      )
      output
      .with_style(
        state_paint(
          Color(background),
          Color(state_final_inner_border_color(background, border)),
          STATE_TERMINAL_STROKE_WIDTH,
        ),
      )
      .draw(
        Circle(center~, radius=(radius - 5.0).max(1.0)),
        metadata=state_class("state-final-inner"),
      )
    }
    @flow.StateKind::History | @flow.StateKind::DeepHistory =>
      append_state_history(output, diagram, state, layout)
    @flow.StateKind::Synchronization =>
      output
      .with_style({
        ..@graphics.DrawingStyle::default(),
        fill: Color(synchronization_background_color(state, diagram.style)),
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
        Polygon([
          { x: center_x, y, },
          { x: x + width, y: center_y, },
          { x: center_x, y: y + height, },
          { x, y: center_y, },
        ]),
        metadata=state_shadow_metadata(state_class("state-choice"), shadow),
      )
    @flow.StateKind::Frame => () // Drawn above with its group/package style.
    @flow.StateKind::Normal => {
      output
      .with_style(
        state_border_paint(
          state,
          diagram.style,
          Color(state_background_color(state, diagram.style)),
        ),
      )
      .draw(
        Rectangle(origin={ x, y, }, width~, height~, rx=Some(corner), ry=None),
        metadata=state_shadow_metadata(state_class("state-outline"), shadow),
      )
      if empty_description {
        append_state_text_at_top(
          output,
          state.display,
          center_x,
          center_y -
          state_text_size(
            state.display,
            name_metrics,
            wrap_width~,
            monospaced_family~,
          ).1 /
          2.0,
          "state-label",
          name_metrics,
          line_alignment=Some(state_text_alignment(state, diagram.style)),
          state=Some(state),
          wrap_width~,
          monospaced_family~,
        )
      } else {
        append_state_submachine_symbol(
          output,
          state,
          layout,
          state_border_paint(
            state,
            diagram.style,
            Color(state_background_color(state, diagram.style)),
          ),
        )
        output
        .with_style(state_border_paint(state, diagram.style, None))
        .draw(
          Line({ x, y: y + header_height, }, {
            x: x + width,
            y: y + header_height,
          }),
          metadata=state_class("state-compartment-separator"),
        )
        append_state_text_at_top(
          output,
          state.display,
          center_x,
          y + STATE_TEXT_MARGIN,
          "state-label",
          name_metrics,
          line_alignment=Some(state_text_alignment(state, diagram.style)),
          state=Some(state),
          wrap_width~,
          monospaced_family~,
        )
        append_state_description(
          output,
          state,
          layout,
          y + header_height + STATE_SEPARATOR_MARGIN,
          diagram.style,
          description_metrics,
          wrap_width~,
        )
      }
    }
  }
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
        { x: region.x, y: region.y, },
        { x: region.x + region.width + STATE_REGION_DASH, y: region.y, },
      )
    @flow.StateRegionSeparator::Vertical =>
      (
        { x: region.x, y: region.y, },
        { x: region.x, y: region.y + region.height + STATE_REGION_DASH, },
      )
  }
  output
  .with_style({
    ..@graphics.DrawingStyle::default(),
    stroke_width: Some(STATE_REGION_STROKE_WIDTH),
    dash: Some([STATE_REGION_DASH, STATE_REGION_DASH_GAP]),
  })
  .draw(Line(start, end), metadata=state_class("state-region-separator"))
}

///|
/// ConcurrentStates.Separator.drawSeparator.
const STATE_REGION_DASH : Double = 8.0

///|
const STATE_REGION_DASH_GAP : Double = 10.0

///|
const STATE_REGION_STROKE_WIDTH : Double = 1.5

///|
fn append_state_note(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  layout : StateNoteLayout,
  connection? : StateNoteConnection? = None,
) -> Unit {
  guard layout.note_index < diagram.notes.length() else { return }
  let note = diagram.notes[layout.note_index]
  let round_corner = state_note_round_corner(note, diagram.style)
  let paint = state_paint(
    Color(note_background_color(note, diagram.style)),
    Color(note_border_color(note, diagram.style)),
    state_note_border_thickness(diagram.style),
  )
  output.group(
    {
      ..state_class("state-note"),
      data: [("note-index", layout.note_index.to_string())],
    },
    output => {
      output
      .with_style(paint)
      .draw(
        Path(state_note_outline(layout, connection, round_corner~)),
        metadata=state_shadow_metadata(
          state_class("state-note-outline"),
          state_note_shadow(diagram.style),
        ),
      )
      output.with_style(paint).draw(Path(state_note_fold(layout, round_corner)))
      guard !note.text.is_empty() else { return }
      append_state_text_at_top(
        output,
        note.text,
        literal_newlines=note.text_mode == @flow.BlockText,
        state_note_text_x(note, layout, diagram.style),
        layout.y + STATE_NOTE_VERTICAL_MARGIN,
        "state-note-label",
        resolve_state_font(diagram.style, NoteLabel).metrics,
        anchor=Start,
        line_alignment=Some(state_note_text_alignment(diagram.style)),
        wrap_width=state_wrap_width(diagram.style),
        data=[("note-index", layout.note_index.to_string())],
        monospaced_family=state_monospaced_family(diagram.style),
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
  let drawing = @graphviz.layout_or_fallback(() => self.drawing_layout(), None)
  let layout = drawing.layout
  let size = state_output_size(self, layout)
  let document = @svg.SvgDocument::empty(
    size.width,
    size.height,
    "State diagram",
  )
  document.stylesheet(
    ".state-region-separator{stroke:\{state_first_gradient_color(self.style.diagram_line_color())}}",
  )
  // Notes retain relative indentation after their shared source indent is
  // removed. Keep SVG whitespace handling consistent with measured text.
  document.stylesheet(".state-note-label{white-space:pre}")
  for
    (key, line, pattern) in [
      ("u", "underline", "solid"),
      ("s", "line-through", "solid"),
      ("us", "underline line-through", "solid"),
      ("w", "underline", "wavy"),
      ("uw", "underline", "wavy"),
      ("sw", "underline line-through", "wavy"),
      ("usw", "underline line-through", "wavy"),
    ] {
    document.stylesheet(
      ".state-richtext-run[data-rich-decoration=\"\{key}\"]{text-decoration-line:\{line};text-decoration-style:\{pattern}}",
    )
  }
  let roles = [
    ("state-label", StateLabel),
    ("state-stereotype-label", StateStereotype),
    ("state-description-label", StateDescription),
    ("state-pseudostate-label", DiamondLabel),
    ("state-transition-label", TransitionLabel),
    ("state-note-label", NoteLabel),
    ("state-title-label", TitleLabel),
    ("state-caption-label", CaptionLabel),
    ("state-header-label", HeaderLabel),
    ("state-footer-label", FooterLabel),
    ("state-legend-label", LegendLabel),
  ]
  for (class_name, role) in roles {
    document.stylesheet(
      resolve_state_font(self.style, role).css_rule("." + class_name),
    )
  }
  for index, state in self.states {
    guard state.kind == @flow.Frame ||
      state.stereotype is Some(_) ||
      state.color is Some(_) else {
      continue
    }
    let selector = ".state-node[data-state-index=\"" + index.to_string() + "\"]"
    for (class_name, role) in roles {
      // History labels use their own stereotype font, matching the font used
      // by append_state_history and the drawing-bounds metadata lookup.
      guard role
        is (StateLabel | StateDescription | DiamondLabel | StateStereotype) else {
        continue
      }
      let font = resolve_state_node_font(self, state, role)
      document.stylesheet(font.css_rule("\{selector} .\{class_name}"))
    }
  }
  let gradients : StateGradients = { definitions: [], }
  let writer = document.writer()
  let text_backgrounds : Array[String] = []
  let shadow_filters : Array[Bool] = []
  append_state_output(
    @graphics.Graphic::new(command => {
      write_state_shadow_command(
        writer,
        gradients.command(resolve_state_rich_paint(self, command)),
        text_backgrounds,
        shadow_filters,
      )
    }),
    self,
    drawing,
    size,
  )
  gradients.write_definitions(writer)
  write_state_text_backgrounds(writer, text_backgrounds)
  if !shadow_filters.is_empty() {
    write_state_shadow_filter(writer)
  }
  document.to_string()
}

///|
/// SvekResult draws nodes before edges so state borders cannot cover the
/// circle/cross or arrowhead at a transition contact.
fn append_state_layout(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  layout : StateLayout,
  note_connections? : Array[StateNoteConnection] = [],
  cluster_titles? : Map[String, Double] = Map([]),
  include_hidden? : Bool = false,
) -> Unit {
  for region in layout.regions {
    if !diagram.is_state_cluster(region.parent) {
      append_state_region_separator(output, region)
    }
  }
  for node in layout.nodes {
    append_state_node(
      output,
      diagram,
      node,
      cluster_title_top=cluster_titles.get(node.code),
    )
  }
  for region in layout.regions {
    append_empty_concurrent_region(output, diagram, region)
  }
  for note in layout.notes {
    guard !(diagram.notes[note.note_index].target is @flow.TransitionNote(_)) else {
      continue
    }
    let connection = note_connections
      .search_by(connection => connection.note_index == note.note_index)
      .map(index => note_connections[index])
    append_state_note(output, diagram, note, connection~)
  }
  for edge in layout.edges {
    guard include_hidden ||
      !diagram.transitions[edge.transition_index].has_line_style("hidden") else {
      continue
    }
    append_state_edge(output, diagram, edge, include_hidden~)
    for note in layout.notes {
      guard diagram.notes[note.note_index].target ==
        @flow.StateNoteTarget::TransitionNote(edge.transition_index) else {
        continue
      }
      append_state_note(output, diagram, note)
    }
  }
}

///|
/// Render a parsed state diagram to SVG.
pub fn render_state_svg(
  diagram : @flow.StateDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> String raise @dot_layout.DotLayoutError {
  diagram.render_svg(color_scheme~)
}

///|
/// USymbolFrame.asBig and EntityImageEmptyPackage use different symbols and
/// styles. A populated frame keeps the state group paint, but its title uses
/// frame.composite.title. Empty frames use package.title and packageStyle.
fn append_state_frame(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  state : @flow.StateNode,
  layout : StateNodeLayout,
) -> Unit {
  let composite = diagram.has_children(state.code)
  let style = diagram.style
  let prefix = if composite { "State" } else { "Package" }
  let property = suffix => state_style_property(state, style, prefix + suffix)
  let background = @svg.svg_color(
    state_inline_color(state.color, "back"),
    @svg.svg_color(property("BackgroundColor"), style.defaults().node),
  )
  let border = @svg.svg_color(
    state_inline_color(state.color, "line"),
    @svg.svg_color(property("BorderColor"), style.diagram_line_color()),
  )
  let thickness = property("BorderThickness").map_or(STATE_THIN_STROKE_WIDTH, value => {
    state_style_dimension(value, STATE_THIN_STROKE_WIDTH)
  })
  let paint = state_inline_stroke(
    state.color,
    state_paint(Color(background), Color(border), thickness),
  )
  let corner = if composite {
    state_corner_radius(state, style)
  } else {
    let value = property("RoundCorner")
    let value = if value is Some(_) {
      value
    } else {
      state_style_property(state, style, "RoundCorner")
    }
    value.map_or(0.0, value => state_style_dimension(value, 0.0) / 2.0)
  }
  let shadow = if composite {
    state_node_shadow(state, style)
  } else {
    let value = property("Shadowing")
    state_shadow_value(
      if value is Some(_) {
        value
      } else {
        state_style_property(state, style, "Shadowing")
      },
    )
  }
  let metadata = state_shadow_metadata(
    state_class("state-frame-outline"),
    shadow,
  )
  let name_metrics = resolve_state_node_font(diagram, state, StateLabel).metrics
  let stereo_metrics = resolve_state_node_font(diagram, state, StateStereotype).metrics
  let monospaced_family = state_monospaced_family(style)
  let title = state_text_size(state.display, name_metrics, monospaced_family~)
  let stereo_text = state_frame_stereotype(state, style)
  let stereo = if stereo_text.is_empty() {
    (0.0, 0.0)
  } else {
    state_text_size(stereo_text, stereo_metrics, monospaced_family~)
  }
  let symbol = if composite {
    "frame"
  } else {
    style.property("PackageStyle").unwrap_or("folder").to_lower()
  }
  let x = layout.x
  let y = layout.y
  let width = layout.width
  let height = layout.height
  let point = (dx, dy) => @graphics.Point::{ x: x + dx, y: y + dy, }
  let shape = output.with_style(paint)
  let line = output.with_style({ ..paint, fill: None, })
  let mut title_x = (width - title.0) / 2.0
  let mut title_y = 2.0 + stereo.1
  let mut stereo_x = (width - stereo.0) / 2.0
  let mut stereo_y = 2.0
  match symbol {
    // PackageStyle.toUSymbol returns no symbol for these legacy values.
    "agent" | "storage" | "component1" | "component2" | "artifact" => return
    "frame" => {
      shape.draw(
        Rectangle(
          origin=point(0.0, 0.0),
          width~,
          height~,
          rx=Some(corner),
          ry=None,
        ),
        metadata~,
      )
      let tab_width = if title.0 == 0.0 { width / 3.0 } else { title.0 + 10.0 }
      let tab_height = if title.0 == 0.0 { 12.0 } else { title.1 + 3.0 }
      let cut = if title.0 == 0.0 { 7.0 } else { 10.0 }
      line.draw(
        Path([
          MoveTo(point(tab_width, 0.0)),
          LineTo(point(tab_width, tab_height - cut)),
          LineTo(point(tab_width - cut, tab_height)),
          LineTo(point(0.0, tab_height)),
        ]),
      )
      title_x = 3.0
      title_y = 1.0
      stereo_x += 4.0
      stereo_y = 2.0 + tab_height
    }
    "rect" | "rectangle" | "card" => {
      let diagonal = state_style_property(state, style, "DiagonalCorner").map_or(
        0.0,
        value => state_style_dimension(value, 0.0),
      )
      if diagonal > 0.0 && symbol != "card" {
        shape.draw(
          Polygon([
            point(diagonal, 0.0),
            point(width - diagonal, 0.0),
            point(width, diagonal),
            point(width, height - diagonal),
            point(width - diagonal, height),
            point(diagonal, height),
            point(0.0, height - diagonal),
            point(0.0, diagonal),
          ]),
          metadata~,
        )
      } else {
        shape.draw(
          Rectangle(
            origin=point(0.0, 0.0),
            width~,
            height~,
            rx=Some(corner),
            ry=None,
          ),
          metadata~,
        )
      }
      if symbol == "card" {
        line.draw(
          Line(
            point(0.0, title.1 + stereo.1 + 4.0),
            point(width, title.1 + stereo.1 + 4.0),
          ),
        )
      } else {
        let alignment = state_skinparam_alignment(
          style,
          "PackageTitleAlignment",
          Middle,
        )
        title_x = match alignment {
          Start => 3.0
          Middle => title_x
          End => width - title.0 - 3.0
        }
        if state_skinparam_alignment(style, "StereotypeAlignment", Middle)
          is End {
          stereo_x = width - stereo.0 - 5.0
          stereo_y = 5.0
        }
      }
    }
    "node" => {
      shape.draw(
        Polygon([
          point(0.0, 10.0),
          point(10.0, 0.0),
          point(width, 0.0),
          point(width, height - 10.0),
          point(width - 10.0, height),
          point(0.0, height),
          point(0.0, 10.0),
        ]),
        metadata~,
      )
      line.draw(Line(point(width - 10.0, 10.0), point(width, 0.0)))
      line.draw(Line(point(0.0, 10.0), point(width - 10.0, 10.0)))
      line.draw(Line(point(width - 10.0, 10.0), point(width - 10.0, height)))
      title_x -= 4.0
      title_y += 11.0
      stereo_x = if state_skinparam_alignment(
          style,
          "StereotypeAlignment",
          Middle,
        )
        is End {
        width - stereo.0 - 14.0
      } else {
        stereo_x - 4.0
      }
      stereo_y += 11.0
      output
      .with_style(state_paint(None, None, 0.0))
      .draw(
        Rectangle(
          origin=point(0.0, height),
          width=10.0,
          height=10.0,
          rx=None,
          ry=None,
        ),
        metadata=state_class("state-package-empty-extent"),
      )
    }
    "database" => {
      let half = width / 2.0
      shape.draw(
        Path([
          MoveTo(point(0.0, 10.0)),
          CubicTo(point(0.0, 0.0), point(half, 0.0), point(half, 0.0)),
          CubicTo(point(half, 0.0), point(width, 0.0), point(width, 10.0)),
          LineTo(point(width, height - 10.0)),
          CubicTo(
            point(width, height),
            point(half, height),
            point(half, height),
          ),
          CubicTo(
            point(half, height),
            point(0.0, height),
            point(0.0, height - 10.0),
          ),
          LineTo(point(0.0, 10.0)),
        ]),
        metadata~,
      )
      line.draw(
        Path([
          MoveTo(point(0.0, 10.0)),
          CubicTo(point(0.0, 20.0), point(half, 20.0), point(half, 20.0)),
          CubicTo(point(half, 20.0), point(width, 20.0), point(width, 10.0)),
        ]),
      )
      title_y += 20.0
      stereo_y += 20.0
      output
      .with_style(state_paint(None, None, 0.0))
      .draw(
        Rectangle(
          origin=point(width, height),
          width=10.0,
          height=10.0,
          rx=None,
          ry=None,
        ),
        metadata=state_class("state-package-empty-extent"),
      )
    }
    "cloud" => {
      shape.draw(Path(description_cloud_path(width, height, x, y)), metadata~)
      title_y += 11.0
      stereo_y += 11.0
    }
    _ => {
      let tab_width = if title.0 == 0.0 {
        30.0.max(width / 4.0)
      } else {
        title.0 + 6.0
      }
      let tab_height = if title.0 == 0.0 { 10.0 } else { title.1 + 6.0 }
      if corner == 0.0 {
        shape.draw(
          Polygon([
            point(0.0, 0.0),
            point(tab_width, 0.0),
            point(tab_width + 7.0, tab_height),
            point(width, tab_height),
            point(width, height),
            point(0.0, height),
            point(0.0, 0.0),
          ]),
          metadata~,
        )
      } else {
        let arc = (radius, end) => {
          @graphics.PathSegment::ArcTo(
            rx=radius,
            ry=radius,
            rotation=0.0,
            large_arc=false,
            sweep=true,
            end~,
          )
        }
        shape.draw(
          Path([
            MoveTo(point(corner, 0.0)),
            LineTo(point(tab_width - corner, 0.0)),
            arc(corner * 1.5, point(tab_width, corner)),
            LineTo(point(tab_width + 7.0, tab_height)),
            LineTo(point(width - corner, tab_height)),
            arc(corner, point(width, tab_height + corner)),
            LineTo(point(width, height - corner)),
            arc(corner, point(width - corner, height)),
            LineTo(point(corner, height)),
            arc(corner, point(0.0, height - corner)),
            LineTo(point(0.0, corner)),
            arc(corner, point(corner, 0.0)),
            Close,
          ]),
          metadata~,
        )
      }
      line.draw(
        Line(point(0.0, tab_height), point(tab_width + 7.0, tab_height)),
      )
      title_x = 4.0
      title_y = 2.0
      stereo_x += 4.0
      stereo_y = 2.0 + tab_height
    }
  }
  append_state_text_at_top(
    output,
    state.display,
    x + title_x,
    y + title_y,
    "state-label",
    name_metrics,
    anchor=Start,
    state=Some(state),
    monospaced_family~,
  )
  if !stereo_text.is_empty() {
    append_state_text_at_top(
      output,
      stereo_text,
      x + stereo_x,
      y + stereo_y,
      "state-stereotype-label",
      stereo_metrics,
      anchor=Start,
      state=Some(state),
      monospaced_family~,
    )
  }
}
