///|
fn Entity::spot(self : Entity) -> (String, String) {
  match self.kind {
    AbstractClass => ("A", "#A9DCDF")
    Interface => ("I", "#B4A7E5")
    Enum => ("E", "#EB937F")
    Annotation => ("@", "#B4A7E5")
    _ => ("C", "#ADD1B2")
  }
}

///|
fn Member::display_without_visibility(self : Member) -> String {
  match self.visibility {
    Unknown => self.raw
    _ => self.raw[1:].trim_start().to_owned()
  }
}

///|
fn Member::visibility_icon(self : Member, x : Int, baseline_y : Int) -> String {
  if self.visibility is Unknown {
    return ""
  }
  let fill = if self.is_method { "#84BE84" } else { "none" }
  let color = match self.visibility {
    Public => "#038048"
    Private => "#B20000"
    Protected => "#A9A900"
    Package => "#A06000"
    Unknown => "#181818"
  }
  let center_y = baseline_y - 4
  match self.visibility {
    Public =>
      "<circle cx=\"\{x + 5}\" cy=\"\{center_y}\" r=\"3\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Private =>
      "<rect x=\"\{x + 2}\" y=\"\{center_y - 3}\" width=\"6\" height=\"6\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Protected =>
      "<path d=\"M \{x + 5} \{center_y - 4} L \{x + 9} \{center_y} L \{x + 5} \{center_y + 4} L \{x + 1} \{center_y} Z\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Package =>
      "<path d=\"M \{x + 5} \{center_y - 3} L \{x + 9} \{center_y + 3} L \{x + 1} \{center_y + 3} Z\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Unknown => ""
  }
}

///|
fn ClassTextMetrics::header_height(self : ClassTextMetrics) -> Int {
  (self.regular.line_height + 16).max(32)
}

///|
fn ClassTextMetrics::row_height(self : ClassTextMetrics) -> Int {
  self.regular.line_height.max(17)
}

///|
priv struct ClassHeaderLayout {
  width : Int
  height : Int
}

///|
priv struct ClassBodyLayout {
  fields : Array[Member]
  methods : Array[Member]
  fields_height : Int
  methods_height : Int
}

///|
fn body_section_height(
  entries : Array[Member],
  text_metrics : ClassTextMetrics,
) -> Int {
  if entries.is_empty() {
    8
  } else {
    7 + entries.length() * text_metrics.row_height()
  }
}

///|
fn Entity::header_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> ClassHeaderLayout {
  // PlantUML places a 22px circled type icon beside every class title.
  let title_metrics = match self.kind {
    AbstractClass | Interface => text_metrics.italic
    _ => text_metrics.regular
  }
  let width = @metrics.measure_text_with(self.display, title_metrics).width + 32
  { width, height: text_metrics.header_height() }
}

///|
fn Entity::body_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> ClassBodyLayout {
  let fields : Array[Member] = []
  let methods : Array[Member] = []
  for entry in self.members {
    guard self.entry_visible(entry) && !entry.is_separator else { continue }
    if entry.is_method {
      methods.push(entry)
    } else {
      fields.push(entry)
    }
  }
  // MethodsOrFieldsArea always contributes its separator and vertical margins,
  // even when that portion has no visible members.
  {
    fields,
    methods,
    fields_height: body_section_height(fields, text_metrics),
    methods_height: body_section_height(methods, text_metrics),
  }
}

///|
fn Entity::height(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let header = self.header_layout(text_metrics)
  let body = self.body_layout(text_metrics)
  header.height + body.fields_height + body.methods_height
}

///|
fn Entity::entry_visible(self : Entity, entry : Member) -> Bool {
  !entry.is_hidden &&
  !(entry.is_method && self.methods_hidden) &&
  !(!entry.is_method && !entry.is_separator && self.fields_hidden)
}

///|
priv struct ClassTextMetrics {
  regular : @metrics.FontMetrics
  italic : @metrics.FontMetrics
}

///|
fn ClassTextMetrics::new(style : @core.DocumentStyle) -> ClassTextMetrics {
  let font_size = if style.font_size is None {
    14
  } else {
    @core.font_size_value(style)
  }
  {
    regular: style.font_metrics(font_size~),
    italic: style.font_metrics(font_size~, font_style=Italic),
  }
}

///|
fn Entity::width(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let mut width = self.header_layout(text_metrics).width
  let body = self.body_layout(text_metrics)
  for entry in body.fields {
    width = width.max(
      @metrics.measure_text_with(entry.raw, text_metrics.regular).width + 28,
    )
  }
  for entry in body.methods {
    width = width.max(
      @metrics.measure_text_with(entry.raw, text_metrics.regular).width + 28,
    )
  }
  width
}

///|
priv struct ClassLayout {
  columns : Int
  cell_width : Int
  cell_height : Int
  width : Int
  height : Int
  graphviz : GraphvizLayout?
}

///|
fn EntityDiagram::layout(
  self : EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> ClassLayout {
  let columns = self.entities.length().min(3).max(1)
  let rows = (self.entities.length() + columns - 1) / columns
  let mut cell_width = 220
  let mut cell_height = 180
  for entity in self.entities {
    cell_width = cell_width.max(entity.width(text_metrics) + 24)
    cell_height = cell_height.max(entity.height(text_metrics) + 24)
  }
  {
    columns,
    cell_width,
    cell_height,
    width: columns * cell_width + 24,
    height: rows * cell_height + 24,
    graphviz: None,
  }
}

///|
fn ClassLayout::entity_rect(
  self : ClassLayout,
  diagram : EntityDiagram,
  index : Int,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, Int, Int) {
  match self.graphviz {
    Some(layout) => {
      let code = diagram.entities[index].qualified_code
      for node in layout.nodes {
        if node.code == code {
          return (
            (node.x - node.width / 2.0).floor().to_int(),
            (node.y - node.height / 2.0).floor().to_int(),
            node.width.ceil().to_int().max(1),
            node.height.ceil().to_int().max(1),
          )
        }
      }
    }
    None => ()
  }
  (
    self.node_x(index),
    self.node_y(index),
    diagram.entities[index].width(text_metrics),
    diagram.entities[index].height(text_metrics),
  )
}

///|
fn ClassLayout::output_width(self : ClassLayout) -> Int {
  match self.graphviz {
    Some(layout) => layout.width.ceil().to_int().max(1)
    None => self.width
  }
}

///|
fn ClassLayout::output_height(self : ClassLayout) -> Int {
  match self.graphviz {
    Some(layout) => layout.height.ceil().to_int().max(1)
    None => self.height
  }
}

///|
fn entity_index(diagram : EntityDiagram, code : String) -> Int? {
  for index, entity in diagram.entities {
    if entity.qualified_code == code {
      return Some(index)
    }
  }
  None
}

///|
fn relation_marker(end : RelationEnd) -> String? {
  match end {
    Extension | Redefines | DefinedBy => Some("triangle")
    CompositionEnd => Some("diamond")
    AggregationEnd => Some("diamond-open")
    Arrow | TriangleArrow | HalfArrowUp | HalfArrowDown => Some("arrow")
    NotNavigable | DoubleLine => Some("bar")
    CircleEnd | CircleConnect | CircleLine | CircleCrowfoot => Some("circle")
    FilledCircle => Some("circle-filled")
    Square => Some("square")
    Plus => Some("plus")
    Crowfoot | LineCrowfoot => Some("crowfoot")
    _ => None
  }
}

///|
fn relation_label_position(
  layout : ClassLayout,
  relation_index : Int,
  fallback : (Int, Int),
) -> (Double, Double) {
  match layout.graphviz {
    Some(graphviz) =>
      for edge in graphviz.edges {
        if edge.relation_index == relation_index {
          return edge.label.unwrap_or(
            (fallback.0.to_double(), fallback.1.to_double()),
          )
        }
      }
    None => ()
  }
  (fallback.0.to_double(), fallback.1.to_double())
}

///|
/// Graphviz spline points use the SVG-compatible 3n+1 cubic Bezier form.
fn append_spline_path(
  output : StringBuilder,
  points : Array[(Double, Double)],
) -> Unit {
  output <+
    $|M \{points[0].0} \{points[0].1}
  if (points.length() - 1) % 3 == 0 {
    let mut index = 1
    while index < points.length() {
      output <+
        $| C \{points[index].0} \{points[index].1} \{points[index + 1].0} \{points[index + 1].1} \{points[index + 2].0} \{points[index + 2].1}
      index += 3
    }
  } else {
    for index in 1..<points.length() {
      output <+
        $| L \{points[index].0} \{points[index].1}
    }
  }
}

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
        let fill = @core.svg_color(
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
          $|<text x="\{x + 4.0}" y="\{y + 16.0}" class="package-title">\{@core.xml_escape(group.display)}</text></g>
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
        let fill = @core.svg_color(
          note.color,
          diagram.style.note_background_color(),
        )
        output <+
          $|<g class="class-note" style="stroke:\{diagram.style.note_border_color()}"><rect x="\{x}" y="\{y}" width="\{note_layout.width}" height="\{note_layout.height}" fill="\{fill}"/><path d="M \{x + note_layout.width - 12.0} \{y} L \{x + note_layout.width} \{y + 12.0} L \{x + note_layout.width - 12.0} \{y + 12.0} Z"/></g>
        for line_index, line in note.text.split("\n") {
          output <+
            $|<text x="\{x + 10.0}" y="\{y + 17.0 + line_index.to_double() * text_metrics.row_height().to_double()}" class="note-text">\{@core.xml_escape(line.to_owned())}</text>
        }
      }
    None => ()
  }
}

///|
fn ClassLayout::node_x(self : ClassLayout, index : Int) -> Int {
  24 + index % self.columns * self.cell_width
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
  guard entity_index(diagram, relation.left) is Some(left_index) else { return }
  guard entity_index(diagram, relation.right) is Some(right_index) else {
    return
  }
  let left = diagram.entities[left_index]
  let right = diagram.entities[right_index]
  guard !left.is_removed && !right.is_removed else { return }
  let (left_x, left_y, left_width, left_height) = layout.entity_rect(
    diagram, left_index, text_metrics,
  )
  let (right_x, right_y, right_width, right_height) = layout.entity_rect(
    diagram, right_index, text_metrics,
  )
  let x1 = left_x + left_width / 2
  let y1 = left_y + left_height / 2
  let x2 = right_x + right_width / 2
  let y2 = right_y + right_height / 2
  let dash = if relation.dotted { " stroke-dasharray=\"6 4\"" } else { "" }
  let relation_style = match relation.line_style {
    Some("dashed") => "stroke-dasharray:6 4"
    Some("dotted") => "stroke-dasharray:2 3"
    Some("bold") => "stroke-width:2.5"
    _ => ""
  }
  let relation_color = @core.svg_color(
    relation.color,
    diagram.style.diagram_line_color(),
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
    Some(graphviz) =>
      for edge in graphviz.edges {
        if edge.relation_index == relation_index {
          for path in edge.paths {
            guard path.length() > 1 else { continue }
            drew_spline = true
            output <+
              $|<path d="
            append_spline_path(output, path)
            output <+
              $|" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
          }
        }
      }
    None => ()
  }
  if drew_spline {
    match relation.label {
      Some(label) =>
        output <+
          $|<text x="\{relation_label_position(layout, relation_index, ((x1 + x2) / 2, (y1 + y2) / 2)).0}" y="\{relation_label_position(layout, relation_index, ((x1 + x2) / 2, (y1 + y2) / 2)).1 - 5.0}" class="relation-label">\{@core.xml_escape(label)}</text>
      None => ()
    }
  } else {
    output <+
      $|<line x1="\{x1}" y1="\{y1}" x2="\{x2}" y2="\{y2}" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
    match relation.label {
      Some(label) =>
        output <+
          $|<text x="\{(x1 + x2) / 2}" y="\{(y1 + y2) / 2 - 5}" class="relation-label">\{@core.xml_escape(label)}</text>
      None => ()
    }
  }
  match relation.left_cardinality {
    Some(text) =>
      output <+
        $|<text x="\{x1 - 8}" y="\{y1 - 6}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
  match relation.right_cardinality {
    Some(text) =>
      output <+
        $|<text x="\{x2 + 8}" y="\{y2 - 6}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
  match relation.left_role {
    Some(text) =>
      output <+
        $|<text x="\{x1 - 8}" y="\{y1 + 13}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
  match relation.right_role {
    Some(text) =>
      output <+
        $|<text x="\{x2 + 8}" y="\{y2 + 13}" class="relation-end-label">\{@core.xml_escape(text)}</text>
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
  let fill = @core.svg_color(
    entity.color,
    diagram.style.class_background_color(),
  )
  let stroke = @core.svg_color(
    entity.line_color,
    diagram.style.class_border_color(),
  )
  let stroke_style = match entity.line_style {
    Some("dashed") => "stroke-dasharray:6 4"
    Some("dotted") => "stroke-dasharray:2 3"
    Some("bold") => "stroke-width:2.5"
    _ => "stroke-width:1.2"
  }
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let title_style = match entity.kind {
    AbstractClass | Interface => " font-style=\"italic\""
    _ => ""
  }
  let (spot_text, spot_fill) = entity.spot()
  output <+
    $|<g class="class-node" data-code="\{@core.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}"\{line_attributes}/><circle cx="\{x + 15}" cy="\{y + 16}" r="11" fill="\{spot_fill}" stroke="#181818" stroke-width="1"/><text x="\{x + 15}" y="\{y + 20}" class="class-spot">\{spot_text}</text><text x="\{x + 29}" y="\{y + header.height - 11}" class="class-title"\{title_style}>\{@core.xml_escape(entity.display)}</text>
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
        $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y)}</g><text x="\{x + 20}" y="\{member_y}" class="member">\{@core.xml_escape(entry.display_without_visibility())}</text>
    }
    section_y += section_height
  }
  output.write_string("</g>\n")
}

///|
/// Render the parsed class graph to a standalone SVG.
///
/// Node placement is deterministic so parsing and rendering can be used without
/// an external process. The graph-layout adapter will replace these coordinates
/// with Graphviz positions while retaining this entity and relation painter.
pub fn EntityDiagram::render_svg(self : EntityDiagram) -> String {
  let background = self.style.canvas_color()
  let font_family = @core.font_family(self.style)
  let font_size = if self.style.font_size is None {
    "14px"
  } else {
    @core.font_size(self.style)
  }
  let line_color = self.style.diagram_line_color()
  let text_metrics = ClassTextMetrics::new(self.style)
  let fallback_layout = self.layout(text_metrics)
  let graphviz = Some(self.graphviz_layout(text_metrics)) catch { _ => None }
  let layout = match graphviz {
    Some(graphviz) =>
      {
        columns: fallback_layout.columns,
        cell_width: fallback_layout.cell_width,
        cell_height: fallback_layout.cell_height,
        width: graphviz.width.ceil().to_int().max(1),
        height: graphviz.height.ceil().to_int().max(1),
        graphviz: Some(graphviz),
      }
    None => fallback_layout
  }
  let output_width = layout.output_width()
  let output_height = layout.output_height()
  let output = StringBuilder()
  output <+
    $|<svg xmlns="http://www.w3.org/2000/svg" width="\{output_width}" height="\{output_height}" viewBox="0 0 \{output_width} \{output_height}" role="img" aria-label="Class diagram">
  let defs_relations =
    #|<defs>
    #|<marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z"/></marker>
    #|<marker id="triangle" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="white"/></marker>
    #|<marker id="diamond" viewBox="0 0 12 10" refX="1" refY="5" markerWidth="10" markerHeight="8" orient="auto-start-reverse"><path d="M 0 5 L 6 0 L 12 5 L 6 10 z"/></marker>
    #|<marker id="diamond-open" viewBox="0 0 12 10" refX="1" refY="5" markerWidth="10" markerHeight="8" orient="auto-start-reverse"><path d="M 0 5 L 6 0 L 12 5 L 6 10 z" fill="white"/></marker>
    #|</defs>
  output.write_string(defs_relations)
  let relations_style =
    $|<style>
    $|svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}
    $|.class-node rect,.class-node line{stroke:#181818;stroke-width:1.2}
    $|.relation{stroke:\{line_color};stroke-width:1.2}
    $|.class-node line,.relation{fill:none}
    $|.class-title{fill:#181818}
    $|.class-spot{text-anchor:middle;font-size:12px;font-weight:bold;fill:#181818}
    $|.member,.relation-label{fill:#181818}
    $|.relation-label{text-anchor:middle;font-size:12px}
    $|</style>
  output.write_string(relations_style)
  let style_markers =
    #|<style>marker path,marker circle,marker rect{stroke:#181818;stroke-width:1}</style>
  output.write_string(style_markers)
  let style_note =
    #|<style>.package path,.package line{stroke:#181818;stroke-width:1.2}.package-title{fill:#181818}.class-note rect,.class-note path{stroke:#181818;stroke-width:1.2}.note-text{fill:#181818}</style>
  output.write_string(style_note)
  let defs_marks =
    #|<defs>
    #|<marker id="bar" viewBox="0 0 8 10" refX="4" refY="5" markerWidth="6" markerHeight="8" orient="auto-start-reverse"><path d="M 4 0 L 4 10"/></marker>
    #|<marker id="circle" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><circle cx="5" cy="5" r="4" fill="white"/></marker>
    #|<marker id="circle-filled" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><circle cx="5" cy="5" r="4"/></marker>
    #|<marker id="square" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><rect x="1" y="1" width="8" height="8" fill="white"/></marker>
    #|<marker id="plus" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 5 1 L 5 9 M 1 5 L 9 5"/></marker>
    #|<marker id="crowfoot" viewBox="0 0 12 12" refX="2" refY="6" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 2 6 L 11 1 M 2 6 L 11 6 M 2 6 L 11 11"/></marker>
    #|</defs>
  output.write_string(defs_marks)
  append_packages(output, self, text_metrics, layout)
  for relation_index, relation in self.relations {
    append_relation(
      output, self, relation_index, relation, text_metrics, layout,
    )
  }
  for index, entity in self.entities {
    append_entity(output, self, entity, index, text_metrics, layout)
  }
  append_notes(output, self, text_metrics, layout)
  output.write_string("</svg>\n")
  output.to_string()
}

///|
test "class layout receives document font profile size and title style" {
  let source = "@startuml\nclass VeryLongClassDisplayName\n@enduml"
  let regular = parse(source)
  let styled = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nclass VeryLongClassDisplayName\n@enduml",
  )
  let regular_metrics = ClassTextMetrics::new(regular.style)
  let styled_metrics = ClassTextMetrics::new(styled.style)
  @test.assert_eq(styled_metrics.regular.profile, Monospace)
  @test.assert_eq(styled_metrics.regular.font_size, 16)
  @test.assert_eq(styled_metrics.italic.style, Italic)
  @test.assert_eq(
    styled.entities[0].width(styled_metrics) >
    regular.entities[0].width(regular_metrics),
    true,
  )
  let layout = styled.layout(styled_metrics)
  @test.assert_eq(
    layout.width >=
    layout.node_x(0) + styled.entities[0].width(styled_metrics) + 24,
    true,
  )
}

///|
test "class body keeps empty field and method sections" {
  let empty = parse("@startuml\ninterface Empty\n@enduml")
  let with_field = parse("@startuml\ninterface Empty {\n+ id : Int\n}\n@enduml")
  let with_method = parse("@startuml\ninterface Empty {\n+ run()\n}\n@enduml")
  let metrics = ClassTextMetrics::new(empty.style)
  let empty_entity = empty.entities[0]
  let empty_body = empty_entity.body_layout(metrics)
  @test.assert_eq(empty_body.fields.length(), 0)
  @test.assert_eq(empty_body.methods.length(), 0)
  @test.assert_eq(empty_body.fields_height > 0, true)
  @test.assert_eq(empty_body.methods_height > 0, true)
  @test.assert_eq(
    with_field.entities[0].height(metrics) > empty_entity.height(metrics),
    true,
  )
  @test.assert_eq(
    with_method.entities[0].height(metrics) > empty_entity.height(metrics),
    true,
  )
}

///|
test "class SVG draws field and method partitions from the layout model" {
  let diagram = parse(
    "@startuml\nclass User {\n+ id : Int\n+ login()\n}\n@enduml",
  )
  let entity = diagram.entities[0]
  let metrics = ClassTextMetrics::new(diagram.style)
  let body = entity.body_layout(metrics)
  let svg = diagram.render_svg()
  @test.assert_eq(body.fields.length(), 1)
  @test.assert_eq(body.methods.length(), 1)
  @test.assert_eq(svg.split("<line ").count() >= 2, true)
  @test.assert_eq(svg.contains("class=\"member-icon\""), true)
  @test.assert_eq(svg.contains(">id : Int</text>"), true)
  @test.assert_eq(svg.contains(">login()</text>"), true)
  @test.assert_eq(svg.contains(">+ id : Int</text>"), false)
}

///|
test "class SVG uses PlantUML spots, visibility icons, and package tabs" {
  let diagram = parse(
    "@startuml\npackage domain {\nabstract class Abstract\nclass Concrete {\n+ visible\n- hidden\n+ run()\n}\ninterface Contract\n}\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"class-spot\">A</text>"), true)
  @test.assert_eq(svg.contains("class=\"class-spot\">C</text>"), true)
  @test.assert_eq(svg.contains("class=\"class-spot\">I</text>"), true)
  @test.assert_eq(svg.contains("class=\"member-icon\""), true)
  @test.assert_eq(svg.contains("fill=\"#84BE84\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\" style="), false)
  @test.assert_eq(svg.contains("class=\"package-title\">domain</text>"), true)
  @test.assert_eq(svg.contains("<path d=\"M "), true)
  @test.assert_eq(svg.contains("style=\"stroke:#181818\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\"><rect"), false)
}

///|
test "class SVG consumes colors resolved by document style" {
  let default_svg = parse("@startuml\nclass User\n@enduml").render_svg()
  let styled_svg = parse(
    "@startuml\nskinparam ClassBackgroundColor #123456\nskinparam ClassBorderColor #654321\nclass User\n@enduml",
  ).render_svg()
  @test.assert_eq(default_svg.contains("fill=\"#F1F1F1\""), true)
  @test.assert_eq(styled_svg.contains("fill=\"#123456\""), true)
  @test.assert_eq(styled_svg.contains("stroke:#654321"), true)
}

///|
test "graphviz receives dimensions from each class header and body" {
  let diagram = parse(
    "@startuml\nclass Short\nclass VeryLongClassDisplayName {\n+ attribute : Int\n+ operation()\n}\nShort --> VeryLongClassDisplayName\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let nodes : Map[String, GraphvizNodeLayout] = Map([])
  for node in layout.nodes {
    nodes[node.code] = node
  }
  let short = nodes.get("Short").unwrap()
  let long = nodes.get("VeryLongClassDisplayName").unwrap()
  @test.assert_eq(long.width > short.width, true)
  @test.assert_eq(long.height > short.height, true)
}

///|
test "graphviz layout emits semantic node and spline geometry" {
  let diagram = parse(
    "@startuml\nclass Parent\nclass Child\nParent <|-- Child : inherits\n@enduml",
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let layout = diagram.graphviz_layout(metrics)
  @test.assert_eq(layout.nodes.length(), 2)
  @test.assert_eq(layout.edges.length(), 1)
  @test.assert_eq(layout.edges[0].paths.length() > 0, true)
  @test.assert_eq(layout.edges[0].label is Some(_), true)
  @test.assert_eq(layout.width > 0.0 && layout.height > 0.0, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("<path d=\"M "), true)
  @test.assert_eq(svg.contains(" C "), true)
}

///|
test "graphviz layout includes package clusters and notes" {
  let diagram = parse(
    "@startuml\npackage Domain {\nclass User\nclass Account\nUser --> Account\nnote right of User : owner\nnote on link : association\n}\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  @test.assert_eq(layout.packages.length(), 1)
  @test.assert_eq(layout.notes.length(), 2)
  @test.assert_eq(layout.packages[0].width > 0.0, true)
  @test.assert_eq(layout.notes[0].width > 0.0, true)
  @test.assert_eq(layout.notes[1].y > layout.edges[0].label.unwrap().1, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"package\""), true)
  @test.assert_eq(svg.contains("class=\"class-note\""), true)
  @test.assert_eq(svg.contains(">owner</text>"), true)
}

///|
test "graphviz layout anchors an entity note beside its target" {
  let diagram = parse(
    "@startuml\nclass Identity\nclass Store\nIdentity --> Store\nnote right of Identity : validates\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let mut identity_x = None
  for node in layout.nodes {
    if node.code == "Identity" {
      identity_x = Some(node.x)
    }
  }
  @test.assert_eq(layout.notes[0].x > identity_x.unwrap(), true)
}

///|
test "graphviz layout follows PlantUML inheritance ordering without fake labels" {
  let diagram = parse(
    (
      #|@startuml
      #|package domain {
      #|  abstract class "Account Holder" as Account
      #|  interface Auditable
      #|  class Customer extends Account
      #|  Customer ..|> Auditable
      #|}
      #|@enduml
    ),
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let nodes : Map[String, GraphvizNodeLayout] = Map([])
  for node in layout.nodes {
    nodes[node.code] = node
  }
  let account = nodes.get("domain.Account").unwrap()
  let customer = nodes.get("domain.Customer").unwrap()
  let auditable = nodes.get("domain.Auditable").unwrap()
  @test.assert_eq(
    account.y + account.height / 2.0 < customer.y - customer.height / 2.0 &&
    customer.y + customer.height / 2.0 < auditable.y - auditable.height / 2.0,
    true,
  )
  @test.assert_eq(layout.edges.length(), diagram.relations.length())
  for edge in layout.edges {
    @test.assert_eq(edge.label, None)
  }
}

///|
test "routed relations preserve endpoint decorations and cardinalities" {
  let diagram = parse(
    "@startuml\nOrder \"1\" *-- \"many\" Item : contains\nClient --[dashed]--> Service\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("url(#diamond)"), true)
  @test.assert_eq(svg.contains("marker path,marker circle,marker rect"), true)
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), false)
  @test.assert_eq(svg.contains(">1</text>"), true)
  @test.assert_eq(svg.contains(">many</text>"), true)
  @test.assert_eq(svg.contains("stroke-dasharray:6 4"), true)
}

///|
test "hollow inheritance arrows retain a visible outline" {
  let svg = parse("@startuml\nParent <|-- Child\n@enduml").render_svg()
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), true)
  @test.assert_eq(svg.contains("fill=\"white\""), true)
  @test.assert_eq(svg.contains("marker path,marker circle,marker rect"), true)
}
