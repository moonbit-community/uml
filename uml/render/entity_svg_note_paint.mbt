///|
const NOTE_CORNER_SIZE : Double = 10.0

///|
const NOTE_POINTER_DELTA : Double = 4.0

///|
priv enum NoteOpaleStrategy {
  OpaleLeft
  OpaleRight
  OpaleUp
  OpaleDown
}

///|
priv struct NoteOpaleAttachment {
  strategy : NoteOpaleStrategy
  note_point : (Double, Double)
  target_point : (Double, Double)
}

///|
fn GraphvizLayout::note_edge(
  self : GraphvizLayout,
  note_index : Int,
) -> @graphviz.GraphvizEdge? {
  for edge in self.note_edges {
    if edge.index == note_index {
      return Some(edge)
    }
  }
  None
}

///|
/// Mirrors `EntityImageNote`: orient the routed edge so its first endpoint is
/// the one attached to the note, then select the nearest note boundary.
fn note_opale_attachment(
  note : @graphviz.GraphvizNote,
  edge : @graphviz.GraphvizEdge,
  target : GraphvizNodeLayout,
  target_shape : @entity.NodeShape,
) -> NoteOpaleAttachment? {
  let center = point(note.x, note.y)
  for spline in edge.splines {
    let path = spline.points
    guard path.length() > 0 else { continue }
    let first = spline.arrow_start.unwrap_or(path[0])
    let last = spline.arrow_end.unwrap_or(path[path.length() - 1])
    let first_adjacent = match spline.arrow_start {
      Some(_) => path[0]
      None => if path.length() > 1 { path[1] } else { last }
    }
    let last_adjacent = match spline.arrow_end {
      Some(_) => path[path.length() - 1]
      None => if path.length() > 1 { path[path.length() - 2] } else { first }
    }
    let (raw_note_point, note_adjacent, raw_target_point, target_adjacent) = if point_distance_squared(
        point(first.x, first.y),
        center,
      ) <=
      point_distance_squared(point(last.x, last.y), center) {
      (first, first_adjacent, last, last_adjacent)
    } else {
      (last, last_adjacent, first, first_adjacent)
    }
    let note_point = clip_ray_to_rect(
      point(raw_note_point.x, raw_note_point.y),
      point(note_adjacent.x, note_adjacent.y),
      rect(center, note.width, note.height),
    ).pair()
    let target_point = clip_ray_to_node(
      point(raw_target_point.x, raw_target_point.y),
      point(target_adjacent.x, target_adjacent.y),
      target,
      target_shape,
    ).pair()
    let left = note.x - note.width / 2.0
    let right = note.x + note.width / 2.0
    let top = note.y - note.height / 2.0
    let bottom = note.y + note.height / 2.0
    let distance_left = (note_point.0 - left).abs()
    let distance_right = (note_point.0 - right).abs()
    let distance_top = (note_point.1 - top).abs()
    let distance_bottom = (note_point.1 - bottom).abs()
    let strategy = if distance_left <= distance_right &&
      distance_left <= distance_top &&
      distance_left <= distance_bottom {
      OpaleLeft
    } else if distance_right <= distance_top &&
      distance_right <= distance_bottom {
      OpaleRight
    } else if distance_top <= distance_bottom {
      OpaleUp
    } else {
      OpaleDown
    }
    return Some({ strategy, note_point, target_point, })
  }
  None
}

///|
fn clamp_double(value : Double, lower : Double, upper : Double) -> Double {
  value.max(lower).min(upper)
}

///|
fn normal_note_path(note : @graphviz.GraphvizNote) -> String {
  let x = note.x - note.width / 2.0
  let y = note.y - note.height / 2.0
  let right = x + note.width
  let bottom = y + note.height
  (
    $|M \{x} \{y} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
  )
}

///|
/// Mirrors `Opale.getCorner` for PlantUML's default zero-rounding geometry.
fn note_corner_path(note : @graphviz.GraphvizNote) -> String {
  let x = note.x - note.width / 2.0
  let y = note.y - note.height / 2.0
  let right = x + note.width
  (
    $|M \{right - NOTE_CORNER_SIZE} \{y} L \{right - NOTE_CORNER_SIZE} \{y + NOTE_CORNER_SIZE} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
  )
}

///|
/// Mirrors the four `Opale.getPolygon*` paths with PlantUML's zero-rounding
/// geometry. The pointer tip is the routed edge endpoint on the target.
fn opale_note_path(
  note : @graphviz.GraphvizNote,
  attachment : NoteOpaleAttachment,
) -> String {
  let x = note.x - note.width / 2.0
  let y = note.y - note.height / 2.0
  let right = x + note.width
  let bottom = y + note.height
  let tip = attachment.target_point
  match attachment.strategy {
    OpaleLeft => {
      let base = clamp_double(
        attachment.note_point.1 - NOTE_POINTER_DELTA,
        y,
        bottom - 2.0 * NOTE_POINTER_DELTA,
      )
      (
        $|M \{x} \{y} L \{x} \{base} L \{tip.0} \{tip.1} L \{x} \{base + 2.0 * NOTE_POINTER_DELTA} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
      )
    }
    OpaleRight => {
      let base = clamp_double(
        attachment.note_point.1 - NOTE_POINTER_DELTA,
        y + NOTE_CORNER_SIZE,
        bottom - 2.0 * NOTE_POINTER_DELTA,
      )
      (
        $|M \{x} \{y} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{base + 2.0 * NOTE_POINTER_DELTA} L \{tip.0} \{tip.1} L \{right} \{base} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
      )
    }
    OpaleUp => {
      let base = clamp_double(
        attachment.note_point.0 - NOTE_POINTER_DELTA,
        x,
        right - NOTE_CORNER_SIZE,
      )
      (
        $|M \{x} \{y} L \{x} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} L \{base + 2.0 * NOTE_POINTER_DELTA} \{y} L \{tip.0} \{tip.1} L \{base} \{y} Z
      )
    }
    OpaleDown => {
      let base = clamp_double(
        attachment.note_point.0 - NOTE_POINTER_DELTA,
        x,
        right,
      )
      (
        $|M \{x} \{y} L \{x} \{bottom} L \{base} \{bottom} L \{tip.0} \{tip.1} L \{base + 2.0 * NOTE_POINTER_DELTA} \{bottom} L \{right} \{bottom} L \{right} \{y + NOTE_CORNER_SIZE} L \{right - NOTE_CORNER_SIZE} \{y} Z
      )
    }
  }
}

///|

///|
const FALLBACK_NOTE_GAP : Int = 12

///|
/// Place notes next to their target entity when Graphviz is unavailable.
/// Link notes need the routed label anchor and are skipped in this mode.
fn fallback_note_layouts(
  diagram : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Array[@graphviz.GraphvizNote] {
  let notes : Array[@graphviz.GraphvizNote] = []
  for note_index, note in diagram.notes {
    if note.target_kind is @entity.NoteTargetKind::LinkNote {
      continue
    }
    let (width, height) = note_size(note, text_metrics)
    match note.target_kind {
      @entity.NoteTargetKind::EntityNote | MemberTip =>
        if entity_index(diagram, note.target) is Some(target_index) {
          let (x, y, w, h) = layout.entity_rect(
            diagram, target_index, text_metrics,
          )
          let position = note.position.with_rankdir(diagram.style)
          let (nx, ny) = match position {
            Right => (x + w + FALLBACK_NOTE_GAP + width / 2, y + h / 2)
            Left => (x - FALLBACK_NOTE_GAP - width / 2, y + h / 2)
            Top => (x + w / 2, y - FALLBACK_NOTE_GAP - height / 2)
            Bottom => (x + w / 2, y + h + FALLBACK_NOTE_GAP + height / 2)
          }
          notes.push({
            note_index,
            x: nx.to_double(),
            y: ny.to_double(),
            width: width.to_double(),
            height: height.to_double(),
          })
        }
      FloatingNote =>
        notes.push({
          note_index,
          x: (SVG_MARGIN_LEFT + width / 2).to_double(),
          y: (SVG_MARGIN_TOP + height / 2).to_double(),
          width: width.to_double(),
          height: height.to_double(),
        })
      @entity.NoteTargetKind::LinkNote => ()
    }
  }
  notes
}

///|
fn append_notes(
  output : StringBuilder,
  diagram : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  collapsible : Bool,
) -> Unit {
  let note_layouts = layout.graphviz.map_or(
    fallback_note_layouts(diagram, text_metrics, layout),
    graphviz => graphviz.notes,
  )
  for note_layout in note_layouts {
    guard note_layout.note_index < diagram.notes.length() else { continue }
    let note = diagram.notes[note_layout.note_index]
    let x = note_layout.x - note_layout.width / 2.0
    let y = note_layout.y - note_layout.height / 2.0
    let fill = @svg.svg_color(
      note.color,
      @entity.note_background_color(diagram.style),
    )
    let mut path = normal_note_path(note_layout)
    let corner_path = note_corner_path(note_layout)
    let mut path_class = ""
    let mut closed_path : String? = None
    if note.target_kind is @entity.NoteTargetKind::EntityNote ||
      note.target_kind is MemberTip {
      match layout.graphviz {
        Some(graphviz) =>
          match graphviz.note_edge(note_layout.note_index) {
            Some(edge) =>
              match (graphviz.node(note.target), diagram.entity(note.target)) {
                (Some(target), Some(entity)) => {
                  let target_shape = entity.node_geometry(
                      text_metrics,
                      diagram.family,
                    ).shape
                  match
                    note_opale_attachment(
                      note_layout, edge, target, target_shape,
                    ) {
                    Some(attachment) => {
                      path = opale_note_path(note_layout, attachment)
                      path_class = " class=\"note-opale-link\""
                      match entity_index(diagram, note.target) {
                        Some(target_index) =>
                          match
                            relation_endpoint_header(
                              layout, diagram, target_index, text_metrics, collapsible,
                            ) {
                            Some(header) =>
                              match
                                note_opale_attachment(
                                  note_layout,
                                  edge,
                                  {
                                    code: target.code,
                                    x: header.center.x,
                                    y: header.center.y,
                                    width: header.width,
                                    height: header.height,
                                  },
                                  Box,
                                ) {
                                Some(closed_attachment) =>
                                  closed_path = Some(
                                    opale_note_path(
                                      note_layout, closed_attachment,
                                    ),
                                  )
                                None => ()
                              }
                            None => ()
                          }
                        None => ()
                      }
                    }
                    None => ()
                  }
                }
                _ => ()
              }
            None => ()
          }
        None => ()
      }
    }
    match closed_path {
      Some(closed) =>
        output <+
          $|<g class="class-note" data-note-index="\{note_layout.note_index}" style="stroke:\{@entity.note_border_color(diagram.style)}"><g class="note-state note-state-0"><path d="\{path}"\{path_class} fill="\{fill}"/><path d="\{corner_path}" fill="\{fill}"/></g><g class="note-state note-state-1"><path d="\{closed}"\{path_class} fill="\{fill}"/><path d="\{corner_path}" fill="\{fill}"/></g></g>
      None =>
        output <+
          $|<g class="class-note" style="stroke:\{@entity.note_border_color(diagram.style)}"><path d="\{path}"\{path_class} fill="\{fill}"/><path d="\{corner_path}" fill="\{fill}"/></g>
    }
    for line_index, line in note.text.split("\n") {
      let line_text = line.to_owned()
      output.write_string(
        @svg.text_markup(
          x + NOTE_LEFT_PADDING.to_double(),
          y +
          NOTE_VERTICAL_PADDING.to_double() +
          text_metrics.note.ascent.to_double() +
          line_index.to_double() * text_metrics.note.line_height.to_double(),
          line_text,
          [("class", "note-text")],
          text_metrics.note,
        ),
      )
      output.write_char('\n')
    }
  }
}

///|
/// CSS that switches each note to its closed variant when its attached class
/// node collapses its members, mirroring `collapsible_relation_style`. The
/// open state targets the full node boundary while the closed state
/// re-anchors the pointer onto the header strip.
fn collapsible_note_style(
  diagram : @entity.EntityDiagram,
  layout : ClassLayout,
  text_metrics : ClassTextMetrics,
  collapsible : Bool,
) -> String {
  guard collapsible else { return "" }
  let output = StringBuilder()
  output.write_string("g[data-note-index] > .note-state{display:none}\n")
  for note_index, note in diagram.notes {
    guard note.target_kind is @entity.NoteTargetKind::EntityNote ||
      note.target_kind is MemberTip else {
      continue
    }
    if entity_index(diagram, note.target) is Some(target_index) {
      if relation_endpoint_header(
          layout, diagram, target_index, text_metrics, collapsible,
        )
        is Some(_) {
        for bit in 0..<2 {
          let condition = if bit == 1 {
            ":has(.class-node[data-node-index=\"\{target_index}\"] details:not([open]))"
          } else {
            ":has(.class-node[data-node-index=\"\{target_index}\"] details[open])"
          }
          output.write_string(
            "svg\{condition} > g[data-note-index=\"\{note_index}\"] > .note-state-\{bit}{display:block}\n",
          )
        }
      }
    }
  }
  output.to_string()
}
