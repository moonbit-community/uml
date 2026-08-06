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
        let fill = @svg.svg_color(
          group.color,
          package_background_color(diagram.style),
        )
        let tab_width = text_metrics.regular.measure(group.display).width.to_double() +
          18.0
        let x = package_layout.x
        let y = package_layout.y
        let right = x + package_layout.width
        let bottom = y + package_layout.height
        let border_color = package_border_color(diagram.style)
        output <+
          $|<g class="package">
          $|<path d="M \{x + 2.5} \{y} L \{x + tab_width - 9.0} \{y} Q \{x + tab_width - 6.5} \{y} \{x + tab_width - 5.5} \{y + 2.5} L \{x + tab_width + 1.5} \{y + 22.0} L \{right - 2.5} \{y + 22.0} Q \{right} \{y + 22.0} \{right} \{y + 24.5} L \{right} \{bottom - 2.5} Q \{right} \{bottom} \{right - 2.5} \{bottom} L \{x + 2.5} \{bottom} Q \{x} \{bottom} \{x} \{bottom - 2.5} L \{x} \{y + 2.5} Q \{x} \{y} \{x + 2.5} \{y}" fill="\{fill}" style="stroke:\{border_color}"/>
          $|<line x1="\{x}" y1="\{y + 22.0}" x2="\{x + tab_width + 1.5}" y2="\{y + 22.0}" style="stroke:\{border_color}"/>
          $|<text x="\{x + 4.0}" y="\{y + 16.0}" class="package-title">\{@svg.xml_escape(group.display)}</text></g>
      }
    None => ()
  }
}

///|
fn ClassLayout::node_y(self : ClassLayout, index : Int) -> Int {
  24 + index / self.columns * self.cell_height
}

///|
fn append_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  class_member_collapsible : Bool,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let header = entity.header_layout(text_metrics)
  let body = entity.body_layout(text_metrics)
  let row_height = text_metrics.row_height()
  let fill = @svg.svg_color(entity.color, class_background_color(diagram.style))
  let stroke = @svg.svg_color(
    entity.line_color,
    class_border_color(diagram.style),
  )
  let stroke_style = @svg.stroke_style(entity.line_style)
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let title_style = match entity.kind {
    AbstractClass | Interface => " font-style=\"italic\""
    _ => ""
  }
  let entity_colors = diagram.style.defaults().entity_colors()
  let (spot_text, spot_fill) = entity.spot(entity_colors)
  let placement = header.placement(width)
  let rect_height = if class_member_collapsible {
    header.height
  } else {
    height
  }
  output <+
    $|<g class="class-node" data-code="\{@svg.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{rect_height}" fill="\{fill}"\{line_attributes}/>
  match placement.circle_center {
    Some((circle_cx, circle_cy)) =>
      output <+
        $|<circle cx="\{x + circle_cx}" cy="\{y + circle_cy}" r="\{CLASS_SPOT_RADIUS}" fill="\{spot_fill}" stroke="\{diagram.style.diagram_line_color()}" stroke-width="1"/><text x="\{x + circle_cx}" y="\{y + circle_cy + 4}" class="class-spot">\{spot_text}</text>
    None => ()
  }
  match (header.stereotype, placement.stereotype_position) {
    (Some(stereotype), Some((stereotype_x, stereotype_baseline))) =>
      output <+
        $|<text x="\{x + stereotype_x}" y="\{y + stereotype_baseline}" class="class-stereotype" fill="\{class_stereotype_font_color(diagram.style)}" font-family="\{@svg.xml_escape(text_metrics.class_stereotype_font_family)}" font-size="\{text_metrics.class_stereotype.font_size}">\{@svg.xml_escape(stereotype)}</text>
    _ => ()
  }
  output <+
    $|<text x="\{x + placement.title_x}" y="\{y + placement.title_baseline}" class="class-title"\{title_style}>\{@svg.xml_escape(entity.display)}</text>
  let member_top = y + header.height
  let body_height = body.fields_height + body.methods_height
  if class_member_collapsible {
    output <+
      $|<foreignObject x="\{x}" y="\{y}" width="\{width}" height="\{height}" pointer-events="all"><details xmlns="http://www.w3.org/1999/xhtml" style="position:relative"><summary style="position:absolute;top:0;left:0;right:0;height:\{header.height}px;list-style:none"></summary><svg xmlns="http://www.w3.org/2000/svg" viewBox="\{x} \{y} \{width} \{height}" width="\{width}" height="\{height}"><rect x="\{x}" y="\{member_top}" width="\{width}" height="\{body_height}" fill="\{fill}"\{line_attributes}/>
  }
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
        $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y, entity_colors)}</g><text x="\{x + entry.member_text_x()}" y="\{member_y}" class="member">\{@svg.xml_escape(entry.display_without_visibility())}</text>
    }
    section_y += section_height
  }
  if class_member_collapsible {
    output.write_string("</svg></details></foreignObject>\n")
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
  class_member_collapsible : Bool,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let (background, border) = match entity.kind {
    Usecase | BusinessUsecase =>
      (
        usecase_background_color(diagram.style),
        usecase_border_color(diagram.style),
      )
    Actor | BusinessActor =>
      (actor_background_color(diagram.style), actor_border_color(diagram.style))
    _ =>
      (class_background_color(diagram.style), class_border_color(diagram.style))
  }
  let fill = @svg.svg_color(entity.color, background)
  let stroke = @svg.svg_color(entity.line_color, border)
  let text_color = match entity.kind {
    Usecase | BusinessUsecase => usecase_font_color(diagram.style)
    Actor | BusinessActor => actor_font_color(diagram.style)
    _ => diagram.style.diagram_text_color()
  }
  let line_attributes = @svg.stroke_style(entity.line_style)
  match entity.kind {
    Usecase | BusinessUsecase | Actor | BusinessActor | Component => ()
    _ => {
      append_entity(
        output, diagram, entity, index, text_metrics, layout, class_member_collapsible,
      )
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
    $|<g class="\{node_class}" data-code="\{@svg.xml_escape(entity.qualified_code)}">
  match entity.url {
    Some(url) =>
      output <+
        $|<a href="\{@svg.xml_escape(url)}">
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
      let title_metrics = text_metrics.usecase_regular.measure(entity.display)
      output <+
        $|<ellipse cx="\{x + width / 2}" cy="\{y + height / 2}" rx="\{width / 2}" ry="\{height / 2}" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
      match stereotype {
        Some(value) => {
          let metrics = text_metrics.usecase_italic.measure(value)
          output <+
            $|<text x="\{x + width / 2}" y="\{content_top + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_italic.font_size}">\{@svg.xml_escape(value)}</text>
        }
        None => ()
      }
      let title_y = match stereotype {
        Some(value) =>
          content_top +
          text_metrics.usecase_italic.measure(value).height +
          title_metrics.baseline
        None => content_top + title_metrics.baseline
      }
      output <+
        $|<text x="\{x + width / 2}" y="\{title_y}" class="usecase-title" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_regular.font_size}">\{@svg.xml_escape(entity.display)}</text>
      if entity.kind is BusinessUsecase {
        let (mark_start, mark_end) = usecase_business_mark(x, y, width, height)
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="usecase-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Actor | BusinessActor => {
      let center_x = x + width / 2
      let title = text_metrics.actor_regular.measure(entity.display)
      let (_, _, stereotype) = entity.actor_content_layout(text_metrics)
      let appearance = actor_appearance(text_metrics.actor_style)
      let (figure_width, figure_height) = actor_figure_geometry(
        appearance,
        business=entity.kind is BusinessActor,
      )
      let stereotype_height = match stereotype {
        Some(value) => text_metrics.actor_italic.measure(value).height
        None => 0
      }
      let figure_top = y + stereotype_height
      let label_y = figure_top + figure_height + title.baseline
      match stereotype {
        Some(value) => {
          let metrics = text_metrics.actor_italic.measure(value)
          output <+
            $|<text x="\{center_x}" y="\{y + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_italic.font_size}">\{@svg.xml_escape(value)}</text>
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
        $|<text x="\{center_x}" y="\{label_y}" class="usecase-title" fill="\{text_color}" font-family="\{@svg.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_regular.font_size}">\{@svg.xml_escape(entity.display)}</text>
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
      let title = text_metrics.regular.measure(entity.display)
      let tab_x = x + width - COMPONENT_TAB_WIDTH - COMPONENT_TAB_INSET
      let tab_y = y + COMPONENT_TAB_INSET
      let mark_x = tab_x - COMPONENT_TAB_MARK_LEFT_OFFSET
      let first_mark_y = tab_y + COMPONENT_TAB_MARK_TOP_OFFSET
      let second_mark_y = first_mark_y + COMPONENT_TAB_MARK_GAP
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2" ry="2" class="component-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{tab_x}" y="\{tab_y}" width="\{COMPONENT_TAB_WIDTH}" height="\{COMPONENT_TAB_HEIGHT}" class="component-tab" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{first_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{second_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><text x="\{x + width / 2}" y="\{y + (height + title.height) / 2 - 2}" class="usecase-title" fill="\{text_color}">\{@svg.xml_escape(entity.display)}</text>
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
