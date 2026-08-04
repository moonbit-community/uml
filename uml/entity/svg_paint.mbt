///|
fn append_packages(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for package_layout in graphviz.packages {
        guard package_layout.package_index < diagram.packages.length() else {
          continue
        }
        let group = diagram.packages[package_layout.package_index]
        let fill = @style.svg_color(
          group.color,
          diagram.style.package_background_color(),
        )
        let tab_width = @metrics.measure_text_with(
            group.display,
            text_metrics.regular,
          ).width.to_double() +
          18.0
        let x = package_layout.x
        let y = package_layout.y
        let right = x + package_layout.width
        let bottom = y + package_layout.height
        let border_color = diagram.style.package_border_color()
        output <+
          $|<g class="package">
          $|<path d="M \{x + 2.5} \{y} L \{x + tab_width - 9.0} \{y} Q \{x + tab_width - 6.5} \{y} \{x + tab_width - 5.5} \{y + 2.5} L \{x + tab_width + 1.5} \{y + 22.0} L \{right - 2.5} \{y + 22.0} Q \{right} \{y + 22.0} \{right} \{y + 24.5} L \{right} \{bottom - 2.5} Q \{right} \{bottom} \{right - 2.5} \{bottom} L \{x + 2.5} \{bottom} Q \{x} \{bottom} \{x} \{bottom - 2.5} L \{x} \{y + 2.5} Q \{x} \{y} \{x + 2.5} \{y}" fill="\{fill}" style="stroke:\{border_color}"/>
          $|<line x1="\{x}" y1="\{y + 22.0}" x2="\{x + tab_width + 1.5}" y2="\{y + 22.0}" style="stroke:\{border_color}"/>
          $|<text x="\{x + 4.0}" y="\{y + 16.0}" class="package-title">\{@style.xml_escape(group.display)}</text></g>
      }
    None => ()
  }
}

///|
fn append_notes(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for note_layout in graphviz.notes {
        guard note_layout.note_index < diagram.notes.length() else { continue }
        let note = diagram.notes[note_layout.note_index]
        let x = note_layout.x - note_layout.width / 2.0
        let y = note_layout.y - note_layout.height / 2.0
        let fill = @style.svg_color(
          note.color,
          diagram.style.note_background_color(),
        )
        let mut linked_to_target = false
        if note.target_kind is EntityNote || note.target_kind is MemberTip {
          for node in graphviz.nodes {
            guard node.code == note.target else { continue }
            let target_left = node.x - node.width / 2.0
            let target_right = node.x + node.width / 2.0
            let target_top = node.y - node.height / 2.0
            let target_bottom = node.y + node.height / 2.0
            let corner = 12.0
            let path = match note.position {
              Right =>
                (
                  $|M \{x} \{y} L \{x} \{node.y - 4.0} L \{target_right} \{node.y} L \{x} \{node.y + 4.0} L \{x} \{y + note_layout.height} L \{x + note_layout.width} \{y + note_layout.height} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width - corner} \{y} Z
                )
              Left =>
                (
                  $|M \{x} \{y} L \{x + note_layout.width - corner} \{y} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width} \{node.y - 4.0} L \{target_left} \{node.y} L \{x + note_layout.width} \{node.y + 4.0} L \{x + note_layout.width} \{y + note_layout.height} L \{x} \{y + note_layout.height} Z
                )
              Top =>
                (
                  $|M \{x} \{y} L \{x + note_layout.width - corner} \{y} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width} \{y + note_layout.height} L \{node.x + 4.0} \{y + note_layout.height} L \{node.x} \{target_top} L \{node.x - 4.0} \{y + note_layout.height} L \{x} \{y + note_layout.height} Z
                )
              Bottom =>
                (
                  $|M \{x} \{y} L \{node.x - 4.0} \{y} L \{node.x} \{target_bottom} L \{node.x + 4.0} \{y} L \{x + note_layout.width - corner} \{y} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width} \{y + note_layout.height} L \{x} \{y + note_layout.height} Z
                )
            }
            output <+
              $|<g class="class-note" style="stroke:\{diagram.style.note_border_color()}"><path d="\{path}" class="note-opale-link" fill="\{fill}"/><path d="M \{x + note_layout.width - 12.0} \{y} L \{x + note_layout.width} \{y + 12.0} L \{x + note_layout.width - 12.0} \{y + 12.0} Z" fill="\{fill}"/></g>
            linked_to_target = true
          }
        }
        if !linked_to_target {
          output <+
            $|<g class="class-note" style="stroke:\{diagram.style.note_border_color()}"><rect x="\{x}" y="\{y}" width="\{note_layout.width}" height="\{note_layout.height}" fill="\{fill}"/><path d="M \{x + note_layout.width - 12.0} \{y} L \{x + note_layout.width} \{y + 12.0} L \{x + note_layout.width - 12.0} \{y + 12.0} Z"/></g>
        }
        for line_index, line in note.text.split("\n") {
          output <+
            $|<text x="\{x + NOTE_LEFT_PADDING.to_double()}" y="\{y + NOTE_VERTICAL_PADDING.to_double() + text_metrics.note.ascent.to_double() + line_index.to_double() * text_metrics.note.line_height.to_double()}" class="note-text">\{@style.xml_escape(line.to_owned())}</text>
        }
      }
    None => ()
  }
}

///|
fn ClassLayout::node_y(self : ClassLayout, index : Int) -> Int {
  24 + index / self.columns * self.cell_height
}

///|
fn append_relation(
  output : StringBuilder,
  diagram : EntityDiagram,
  relation_index : Int,
  relation : Relation,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  let usecase = diagram.family.is_usecase()
  guard entity_index(diagram, relation.left) is Some(left_index) else { return }
  guard entity_index(diagram, relation.right) is Some(right_index) else {
    return
  }
  let left = diagram.entities[left_index]
  let right = diagram.entities[right_index]
  guard !left.is_removed && !right.is_removed else { return }
  let ((x1, y1), (x2, y2)) = relation_endpoints(
    layout, diagram, left_index, right_index, text_metrics,
  )
  let (left_x, left_y, left_width, left_height) = layout.entity_rect(
    diagram, left_index, text_metrics,
  )
  let (right_x, right_y, right_width, right_height) = layout.entity_rect(
    diagram, right_index, text_metrics,
  )
  // Dotted arrows render with the dash pattern shared by the dashed line
  // style, matching PlantUML where a dotted arrow draws dash-like segments.
  let dash = if relation.dotted {
    @svg.line_style_attributes_markup(Some("dashed"))
  } else {
    ""
  }
  let relation_style = @svg.stroke_style(relation.line_style, default_width="")
  let relation_color = @style.svg_color(
    relation.color,
    diagram.style.diagram_line_color(),
  )
  let label_font_size = if usecase {
    diagram.style.arrow_font_size(fallback=USECASE_RELATION_LABEL_FONT_SIZE)
  } else {
    text_metrics.relation_label_regular.font_size
  }
  let label_font_family = if usecase {
    diagram.style.arrow_font_family()
  } else {
    @style.font_family(diagram.style)
  }
  let label_color = if usecase {
    diagram.style.arrow_font_color()
  } else {
    diagram.style.diagram_text_color()
  }
  let relation_label_layout = layout.relation_label_layout(
    diagram, relation_index, relation, text_metrics,
  )
  let style =
    $| style="stroke:\{relation_color};\{relation_style}"
  let marker_start = match relation_marker(relation.left_end) {
    Some(marker) => " marker-start=\"url(#\{marker})\""
    None => ""
  }
  let marker_end = match relation_marker(relation.right_end) {
    Some(marker) => " marker-end=\"url(#\{marker})\""
    None => ""
  }
  let mut drew_spline = false
  match layout.graphviz {
    Some(graphviz) if !(usecase &&
      relation.dotted &&
      relation.direction is Automatic) =>
      for edge in graphviz.edges {
        if edge.index == relation_index {
          for path in edge.paths {
            guard path.length() > 1 else { continue }
            drew_spline = true
            let clipped = if usecase {
              clip_usecase_spline(
                path,
                left,
                (left_x, left_y, left_width, left_height),
                right,
                (right_x, right_y, right_width, right_height),
              )
            } else {
              path
            }
            output <+
              $|<path d="
            output.write_string(@svg.spline_path_data(clipped))
            output <+
              $|" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
          }
        }
      }
    _ => ()
  }
  if !drew_spline {
    output <+
      $|<line x1="\{x1}" y1="\{y1}" x2="\{x2}" y2="\{y2}" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
  }
  match relation_label_layout.label {
    Some(text_box) => {
      let x = if usecase {
        text_box.x + text_box.width / 2.0
      } else {
        text_box.x
      }
      let anchor_style = if usecase {
        ""
      } else {
        " style=\"text-anchor:start\""
      }
      output <+
        $|<text x="\{x}" y="\{text_box.baseline}" class="relation-label" fill="\{label_color}" font-family="\{@style.xml_escape(label_font_family)}" font-size="\{label_font_size}"\{anchor_style}>\{@style.xml_escape(text_box.text)}</text>
    }
    None => ()
  }
  let end_label_font_size = text_metrics.relation_end_regular.font_size
  let end_label_font_family = text_metrics.relation_end_font_family
  match relation_label_layout.left_cardinality {
    Some(text_box) =>
      output <+
        $|<text x="\{text_box.x}" y="\{text_box.baseline}" class="relation-end-label" font-family="\{@style.xml_escape(end_label_font_family)}" font-size="\{end_label_font_size}">\{@style.xml_escape(text_box.text)}</text>
    None => ()
  }
  match relation_label_layout.right_cardinality {
    Some(text_box) =>
      output <+
        $|<text x="\{text_box.x}" y="\{text_box.baseline}" class="relation-end-label" font-family="\{@style.xml_escape(end_label_font_family)}" font-size="\{end_label_font_size}">\{@style.xml_escape(text_box.text)}</text>
    None => ()
  }
  match relation_label_layout.left_role {
    Some(text_box) =>
      output <+
        $|<text x="\{text_box.x}" y="\{text_box.baseline}" class="relation-end-label" font-family="\{@style.xml_escape(end_label_font_family)}" font-size="\{end_label_font_size}">\{@style.xml_escape(text_box.text)}</text>
    None => ()
  }
  match relation_label_layout.right_role {
    Some(text_box) =>
      output <+
        $|<text x="\{text_box.x}" y="\{text_box.baseline}" class="relation-end-label" font-family="\{@style.xml_escape(end_label_font_family)}" font-size="\{end_label_font_size}">\{@style.xml_escape(text_box.text)}</text>
    None => ()
  }
}

///|
fn append_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let header = entity.header_layout(text_metrics)
  let body = entity.body_layout(text_metrics)
  let row_height = text_metrics.row_height()
  let fill = @style.svg_color(
    entity.color,
    diagram.style.class_background_color(),
  )
  let stroke = @style.svg_color(
    entity.line_color,
    diagram.style.class_border_color(),
  )
  let stroke_style = @svg.stroke_style(entity.line_style)
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let title_style = match entity.kind {
    AbstractClass | Interface => " font-style=\"italic\""
    _ => ""
  }
  let (spot_text, spot_fill) = entity.spot()
  let (circle_cx, title_x) = class_title_offsets(
    entity.display,
    entity.title_metrics(text_metrics),
    width,
  )
  output <+
    $|<g class="class-node" data-code="\{@style.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}"\{line_attributes}/><circle cx="\{x + circle_cx}" cy="\{y + 16}" r="11" fill="\{spot_fill}" stroke="\{diagram.style.diagram_line_color()}" stroke-width="1"/><text x="\{x + circle_cx}" y="\{y + 20}" class="class-spot">\{spot_text}</text><text x="\{x + title_x}" y="\{y + header.height - 11}" class="class-title"\{title_style}>\{@style.xml_escape(entity.display)}</text>
  let mut section_y = y + header.height
  for section_index, section in [body.fields, body.methods] {
    let section_height = if section_index == 0 {
      body.fields_height
    } else {
      body.methods_height
    }
    output <+
      $|<line x1="\{x}" y1="\{section_y}" x2="\{x + width}" y2="\{section_y}"\{line_attributes}/>
    for member_index, entry in section {
      let member_y = section_y + (member_index + 1) * row_height + 1
      output <+
        $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y)}</g><text x="\{x + entry.member_text_x()}" y="\{member_y}" class="member">\{@style.xml_escape(entry.display_without_visibility())}</text>
    }
    section_y += section_height
  }
  output.write_string("</g>\n")
}

///|
fn append_usecase_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let (background, border) = match entity.kind {
    Usecase | BusinessUsecase =>
      (
        diagram.style.usecase_background_color(),
        diagram.style.usecase_border_color(),
      )
    Actor | BusinessActor =>
      (
        diagram.style.actor_background_color(),
        diagram.style.actor_border_color(),
      )
    _ =>
      (
        diagram.style.class_background_color(),
        diagram.style.class_border_color(),
      )
  }
  let fill = @style.svg_color(entity.color, background)
  let stroke = @style.svg_color(entity.line_color, border)
  let text_color = match entity.kind {
    Usecase | BusinessUsecase => diagram.style.usecase_font_color()
    Actor | BusinessActor => diagram.style.actor_font_color()
    _ => diagram.style.diagram_text_color()
  }
  let line_attributes = @svg.stroke_style(entity.line_style)
  match entity.kind {
    Usecase | BusinessUsecase | Actor | BusinessActor | Component => ()
    _ => {
      append_entity(output, diagram, entity, index, text_metrics, layout)
      return
    }
  }
  let node_class = match entity.kind {
    Usecase | BusinessUsecase => "usecase-node"
    Actor | BusinessActor => "actor-node"
    Component => "component-node"
    _ => ""
  }
  output <+
    $|<g class="\{node_class}" data-code="\{@style.xml_escape(entity.qualified_code)}">
  match entity.url {
    Some(url) =>
      output <+
        $|<a href="\{@style.xml_escape(url)}">
    None => ()
  }
  match entity.kind {
    Usecase | BusinessUsecase => {
      let (_, content_height, stereotype) = entity.usecase_content_layout(
        text_metrics,
      )
      // TextBlockInEllipse centers the text block, then applies dy - 2.
      // The ellipse itself has grown by 6px, so SVG text needs a +2px
      // top offset before converting its font ascent to a baseline.
      let content_top = y + height / 2 - content_height / 2 + 2
      let title_metrics = @metrics.measure_text_with(
        entity.display,
        text_metrics.usecase_regular,
      )
      output <+
        $|<ellipse cx="\{x + width / 2}" cy="\{y + height / 2}" rx="\{width / 2}" ry="\{height / 2}" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
      match stereotype {
        Some(value) => {
          let metrics = @metrics.measure_text_with(
            value,
            text_metrics.usecase_italic,
          )
          output <+
            $|<text x="\{x + width / 2}" y="\{content_top + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@style.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_italic.font_size}">\{@style.xml_escape(value)}</text>
        }
        None => ()
      }
      let title_y = match stereotype {
        Some(value) =>
          content_top +
          @metrics.measure_text_with(value, text_metrics.usecase_italic).height +
          title_metrics.baseline
        None => content_top + title_metrics.baseline
      }
      output <+
        $|<text x="\{x + width / 2}" y="\{title_y}" class="usecase-title" fill="\{text_color}" font-family="\{@style.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_regular.font_size}">\{@style.xml_escape(entity.display)}</text>
      if entity.kind is BusinessUsecase {
        let (mark_start, mark_end) = usecase_business_mark(x, y, width, height)
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="usecase-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Actor | BusinessActor => {
      let center_x = x + width / 2
      let title = @metrics.measure_text_with(
        entity.display,
        text_metrics.actor_regular,
      )
      let (_, _, stereotype) = entity.actor_content_layout(text_metrics)
      let appearance = actor_appearance(text_metrics.actor_style)
      let (figure_width, figure_height) = actor_figure_geometry(
        appearance,
        business=entity.kind is BusinessActor,
      )
      let stereotype_height = match stereotype {
        Some(value) =>
          @metrics.measure_text_with(value, text_metrics.actor_italic).height
        None => 0
      }
      let figure_top = y + stereotype_height
      let label_y = figure_top + figure_height + title.baseline
      match stereotype {
        Some(value) => {
          let metrics = @metrics.measure_text_with(
            value,
            text_metrics.actor_italic,
          )
          output <+
            $|<text x="\{center_x}" y="\{y + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@style.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_italic.font_size}">\{@style.xml_escape(value)}</text>
        }
        None => ()
      }
      if entity.kind is Actor {
        match appearance {
          Awesome =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 17}" r="16" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 27} \{figure_top + 50} Q \{center_x} \{figure_top + 38} \{center_x + 27} \{figure_top + 50} V \{figure_top + 62} Q \{center_x + 27} \{figure_top + 62} \{center_x + 19} \{figure_top + 62} H \{center_x - 19} Q \{center_x - 27} \{figure_top + 62} \{center_x - 27} \{figure_top + 54} Z" class="actor-awesome-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Hollow =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 5}" r="4" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 13} \{figure_top + 12} H \{center_x + 13} V \{figure_top + 17} H \{center_x + 3} V \{figure_top + 27} L \{center_x + 9} \{figure_top + 35} H \{center_x + 3} L \{center_x} \{figure_top + 30} L \{center_x - 3} \{figure_top + 35} H \{center_x - 9} L \{center_x - 3} \{figure_top + 27} V \{figure_top + 17} H \{center_x - 13} Z" class="actor-hollow-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Stickman => ()
        }
      }
      if entity.kind is BusinessActor || appearance is Stickman {
        output <+
          $|<circle cx="\{center_x}" cy="\{figure_top + 9}" r="8" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x} \{figure_top + 17} L \{center_x} \{figure_top + 43} M \{center_x - 13} \{figure_top + 27} L \{center_x + 13} \{figure_top + 27} M \{center_x} \{figure_top + 43} L \{center_x - 13} \{figure_top + figure_height} M \{center_x} \{figure_top + 43} L \{center_x + 13} \{figure_top + figure_height}" fill="none" stroke="\{stroke}" style="\{line_attributes}"/>
      }
      output <+
        $|<text x="\{center_x}" y="\{label_y}" class="usecase-title" fill="\{text_color}" font-family="\{@style.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_regular.font_size}">\{@style.xml_escape(entity.display)}</text>
      if entity.kind is BusinessActor && figure_width == ACTOR_FIGURE_WIDTH {
        let (mark_start, mark_end) = actor_business_mark(
          center_x,
          figure_top + 9,
          8,
        )
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="actor-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Component => {
      let title = @metrics.measure_text_with(
        entity.display,
        text_metrics.regular,
      )
      let tab_x = x + width - COMPONENT_TAB_WIDTH - COMPONENT_TAB_INSET
      let tab_y = y + COMPONENT_TAB_INSET
      let mark_x = tab_x - COMPONENT_TAB_MARK_LEFT_OFFSET
      let first_mark_y = tab_y + COMPONENT_TAB_MARK_TOP_OFFSET
      let second_mark_y = first_mark_y + COMPONENT_TAB_MARK_GAP
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2" ry="2" class="component-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{tab_x}" y="\{tab_y}" width="\{COMPONENT_TAB_WIDTH}" height="\{COMPONENT_TAB_HEIGHT}" class="component-tab" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{first_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{second_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><text x="\{x + width / 2}" y="\{y + (height + title.height) / 2 - 2}" class="usecase-title" fill="\{text_color}">\{@style.xml_escape(entity.display)}</text>
    }
    _ => ()
  }
  match entity.url {
    Some(_) => output.write_string("</a>")
    None => ()
  }
  output.write_string("</g>\n")
}

///|
