///|
/// SvekResult moves the measured drawing origin before returning its size.
const STATE_IMAGE_ORIGIN : Double = 6.0

///|
const STATE_IMAGE_MARGIN : Double = 15.0

///|
/// LimitFinder uses this coordinate adjustment for rectangles and ellipses;
/// it is independent of their paint and stroke width.
const STATE_LIMIT_SHAPE_ADJUSTMENT : Double = 1.0

///|
const STATE_LIMIT_TEXT_BASELINE : Double = 1.5

///|
/// LimitFinder.HACK_X_FOR_POLYGON also applies to extremity arrows.
const STATE_LIMIT_POLYGON_MARGIN : Double = 10.0

///|
priv struct StateDrawingBounds {
  mut empty : Bool
  mut min_x : Double
  mut min_y : Double
  mut max_x : Double
  mut max_y : Double
}

///|
fn StateDrawingBounds::new() -> StateDrawingBounds {
  { empty: true, min_x: 0.0, min_y: 0.0, max_x: 0.0, max_y: 0.0, }
}

///|
fn StateDrawingBounds::add_point(
  self : StateDrawingBounds,
  x : Double,
  y : Double,
) -> Unit {
  if self.empty {
    self.min_x = x
    self.min_y = y
    self.max_x = x
    self.max_y = y
    self.empty = false
  } else {
    self.min_x = self.min_x.min(x)
    self.min_y = self.min_y.min(y)
    self.max_x = self.max_x.max(x)
    self.max_y = self.max_y.max(y)
  }
}

///|
/// UPath and DotPath include control points, not just sampled curve points.
/// UPath arcs contribute their end point, as in the Java path accumulator.
fn StateDrawingBounds::include_path(
  self : StateDrawingBounds,
  segments : Array[@graphics.PathSegment],
  translation : @graphics.Point,
) -> Unit {
  let point = (p : @graphics.Point) => {
    self.add_point(p.x + translation.x, p.y + translation.y)
  }
  for segment in segments {
    match segment {
      MoveTo(p) | LineTo(p) | ArcTo(end=p, ..) => point(p)
      CubicTo(first, second, end) => {
        point(first)
        point(second)
        point(end)
      }
      QuadraticTo(control, end) => {
        point(control)
        point(end)
      }
      Close => ()
    }
  }
}

///|
fn state_drawing_font(
  diagram : @flow.StateDiagram,
  metadata : @graphics.Metadata,
) -> @metrics.FontMetrics {
  let metadata = metadata.data
    .search_by(entry => entry.0 == "rich-role")
    .map_or(metadata, index => {
      ..metadata,
      class_name: Some(metadata.data[index].1),
    })
  let role = if metadata.class_name == Some("state-stereotype-label") {
    StateStereotype
  } else if metadata.class_name == Some("state-description-label") {
    StateDescription
  } else if metadata.class_name == Some("state-transition-label") {
    TransitionLabel
  } else if metadata.class_name == Some("state-pseudostate-label") {
    DiamondLabel
  } else if metadata.class_name == Some("state-note-label") {
    NoteLabel
  } else if metadata.class_name == Some("state-title-label") {
    TitleLabel
  } else if metadata.class_name == Some("state-caption-label") {
    CaptionLabel
  } else if metadata.class_name == Some("state-header-label") {
    HeaderLabel
  } else if metadata.class_name == Some("state-footer-label") {
    FooterLabel
  } else if metadata.class_name == Some("state-legend-label") {
    LegendLabel
  } else {
    StateLabel
  }
  let state = metadata.data
    .search_by(entry => entry.0 == "state-code")
    .bind(index => diagram.state(metadata.data[index].1))
  state.map_or_else(() => resolve_state_font(diagram.style, role).metrics, state => {
    resolve_state_node_font(diagram, state, role).metrics
  })
}

///|
/// Measure the same drawing commands used by the renderer, without exporting
/// SVG or using Graphviz's box as a substitute for the painted diagram.
fn StateDrawingBounds::draw(
  self : StateDrawingBounds,
  diagram : @flow.StateDiagram,
  command : @graphics.DrawCommand,
) -> Unit {
  guard command is Draw(shape, _, translation, metadata) else {
    guard command is BeginScale(_) else { return }
    abort("state drawing bounds do not support scaled drawing scopes")
  }
  let point = (p : @graphics.Point) => {
    self.add_point(p.x + translation.x, p.y + translation.y)
  }
  // DriverTextSvg adds these after LimitFinder has measured the UText atom.
  // Keep their SVG geometry out of the layout measurement, as Java does.
  guard metadata.class_name != Some("state-richtext-decoration") &&
    metadata.class_name != Some("state-richtext-background") else {
    return
  }
  let adjustment = STATE_LIMIT_SHAPE_ADJUSTMENT
  let shadow_extent = 2.0 * state_metadata_shadow(metadata)
  match shape {
    Rectangle(origin~, width~, height~, ..) => {
      if metadata.class_name == Some("state-package-empty-extent") {
        point(origin)
        point({ x: origin.x + width, y: origin.y + height, })
        return
      }
      point({ x: origin.x - adjustment, y: origin.y - adjustment, })
      point({
        x: origin.x + width - adjustment + shadow_extent,
        y: origin.y + height - adjustment + shadow_extent,
      })
    }
    Circle(center~, radius~) => {
      point({ x: center.x - radius, y: center.y - radius, })
      point({
        x: center.x + radius - adjustment + shadow_extent,
        y: center.y + radius - adjustment + shadow_extent,
      })
    }
    Ellipse(center~, rx~, ry~) => {
      point({ x: center.x - rx, y: center.y - ry, })
      point({
        x: center.x + rx - adjustment + shadow_extent,
        y: center.y + ry - adjustment + shadow_extent,
      })
    }
    Line(start, end) => {
      point(start)
      point(end)
    }
    Polygon(points) =>
      for p in points {
        point({ x: p.x - STATE_LIMIT_POLYGON_MARGIN, y: p.y, })
        point({ x: p.x + STATE_LIMIT_POLYGON_MARGIN, y: p.y, })
      }
    Path(segments) => self.include_path(segments, translation)
    TextBlock(block) => {
      let metrics = state_drawing_font(diagram, metadata)
      let mut baseline = block.position.y
      for line in block.lines {
        baseline += line.dy
        // TextBlock lines have already passed through StateDisplay. Measuring
        // their literal contents avoids decoding escaped backslashes twice.
        let size = metrics.measure(line.text)
        let width = size.width.to_double()
        let height = size.height.to_double()
        let left = block.position.x -
          state_text_anchor_offset(block.anchor, width)
        let bottom = baseline + STATE_LIMIT_TEXT_BASELINE
        point({ x: left, y: bottom - height, })
        point({ x: left + width, y: bottom, })
      }
    }
    StyledText(run, font) => {
      let base = state_drawing_font(diagram, metadata)
      let base = run.font_family.map_or(base, family => {
        base.with_profile(@style.font_profile_for(family))
      })
      let metrics = base
        .with_size(run.font_size.to_int())
        .with_face(
          font.weight.unwrap_or(base.font_weight),
          font.italic.map_or(base.style, italic => {
            if italic {
              @metrics.FontStyle::Italic
            } else {
              @metrics.FontStyle::Normal
            }
          }),
        )
      let size = metrics.measure(run.text)
      let width = size.width.to_double()
      let left = run.position.x - state_text_anchor_offset(run.anchor, width)
      let bottom = run.position.y + STATE_LIMIT_TEXT_BASELINE
      point({ x: left, y: bottom - size.height.to_double(), })
      point({ x: left + width, y: bottom, })
    }
    _ => abort("unsupported primitive in state drawing bounds")
  }
}

///|
fn StateFragment::as_layout(self : StateFragment) -> StateLayout {
  {
    width: self.width,
    height: self.height,
    nodes: self.nodes,
    edges: self.edges,
    regions: self.regions,
    notes: self.notes,
  }
}

///|
fn state_fragment_bounds(
  diagram : @flow.StateDiagram,
  fragment : StateFragment,
) -> StateDrawingBounds {
  let bounds = StateDrawingBounds::new()
  append_state_layout(
    @graphics.Graphic::new(command => bounds.draw(diagram, command)),
    diagram,
    fragment.as_layout(),
    note_connections=fragment.note_connections,
    cluster_titles=fragment.cluster_titles,
    // LimitFinder ignores UHidden. Invisible output must retain the same
    // reserved diagram bounds as the corresponding visible drawing.
    include_hidden=true,
  )
  bounds
}

///|
/// Previously verified: canvas normalization is translation independent,
/// includes multiline text, outlying Bezier controls and note pointer contacts,
/// and uses drawing bounds instead of DOT bounds.
fn normalize_state_fragment(
  diagram : @flow.StateDiagram,
  fragment : StateFragment,
  dimension_padding : Double,
) -> StateFragment {
  let bounds = state_fragment_bounds(diagram, fragment)
  let output : StateFragment = {
    width: bounds.max_x - bounds.min_x + dimension_padding,
    height: bounds.max_y - bounds.min_y + dimension_padding,
    nodes: [],
    edges: [],
    regions: [],
    notes: [],
    note_connections: [],
    cluster_titles: Map([]),
  }
  append_shifted_fragment(
    output,
    fragment,
    STATE_IMAGE_ORIGIN - bounds.min_x,
    STATE_IMAGE_ORIGIN - bounds.min_y,
  )
  output
}
