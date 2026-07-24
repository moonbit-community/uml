///|
fn xml_escape(value : String) -> String {
  @core.xml_escape(value)
}

///|
fn ClassTextMetrics::header_height(self : ClassTextMetrics) -> Int {
  (self.bold.line_height + 23).max(38)
}

///|
fn ClassTextMetrics::row_height(self : ClassTextMetrics) -> Int {
  (self.regular.line_height + 3).max(18)
}

///|
fn Entity::height(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  text_metrics.header_height() +
  self.visible_member_count() * text_metrics.row_height()
}

///|
fn Entity::entry_visible(self : Entity, entry : Member) -> Bool {
  !entry.is_hidden &&
  !(entry.is_method && self.methods_hidden) &&
  !(!entry.is_method && !entry.is_separator && self.fields_hidden)
}

///|
fn Entity::visible_member_count(self : Entity) -> Int {
  let mut count = 0
  for entry in self.members {
    if self.entry_visible(entry) {
      count += 1
    }
  }
  count
}

///|
priv struct ClassTextMetrics {
  regular : @metrics.FontMetrics
  bold : @metrics.FontMetrics
}

///|
fn ClassTextMetrics::new(style : @core.DocumentStyle) -> ClassTextMetrics {
  { regular: style.font_metrics(), bold: style.font_metrics(font_weight=700) }
}

///|
fn Entity::width(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let mut width = @metrics.measure_text_with(self.display, text_metrics.bold).width +
    28
  for entry in self.members {
    guard self.entry_visible(entry) else { continue }
    width = width.max(
      @metrics.measure_text_with(entry.raw, text_metrics.regular).width + 28,
    )
  }
  width.max(140)
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
fn ClassDiagram::layout(
  self : ClassDiagram,
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
  diagram : ClassDiagram,
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
fn entity_index(diagram : ClassDiagram, code : String) -> Int? {
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
  output <+ "M \{points[0].0} \{points[0].1}"
  if (points.length() - 1) % 3 == 0 {
    let mut index = 1
    while index < points.length() {
      output <+
        " C \{points[index].0} \{points[index].1} \{points[index + 1].0} \{points[index + 1].1} \{points[index + 2].0} \{points[index + 2].1}"
      index += 3
    }
  } else {
    for index in 1..<points.length() {
      output <+ " L \{points[index].0} \{points[index].1}"
    }
  }
}

///|
fn append_packages(
  output : StringBuilder,
  diagram : ClassDiagram,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for package_layout in graphviz.packages {
        guard package_layout.package_index < diagram.packages.length() else {
          continue
        }
        let group = diagram.packages[package_layout.package_index]
        let fill = @core.svg_color(group.color, "#F8F8F8")
        output <+
          "<g class=\"package\"><rect x=\"\{package_layout.x}\" y=\"\{package_layout.y}\" width=\"\{package_layout.width}\" height=\"\{package_layout.height}\" fill=\"\{fill}\"/><text x=\"\{package_layout.x + 10.0}\" y=\"\{package_layout.y + 18.0}\" class=\"package-title\">\{xml_escape(group.display)}</text></g>\n"
      }
    None => ()
  }
}

///|
fn append_notes(
  output : StringBuilder,
  diagram : ClassDiagram,
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
        let fill = @core.svg_color(note.color, "#FEFFDD")
        output <+
          "<g class=\"class-note\"><rect x=\"\{x}\" y=\"\{y}\" width=\"\{note_layout.width}\" height=\"\{note_layout.height}\" fill=\"\{fill}\"/><path d=\"M \{x + note_layout.width - 12.0} \{y} L \{x + note_layout.width} \{y + 12.0} L \{x + note_layout.width - 12.0} \{y + 12.0} Z\"/></g>\n"
        for line_index, line in note.text.split("\n") {
          output <+
            "<text x=\"\{x + 10.0}\" y=\"\{y + 17.0 + line_index.to_double() * text_metrics.row_height().to_double()}\" class=\"note-text\">\{xml_escape(line.to_owned())}</text>\n"
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
  diagram : ClassDiagram,
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
    @core.svg_color(diagram.style.line_color, "#181818"),
  )
  let style = " style=\"stroke:\{relation_color};\{relation_style}\""
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
            output <+ "<path d=\""
            append_spline_path(output, path)
            output <+
              "\" class=\"relation\"\{style}\{dash}\{marker_start}\{marker_end}/>\n"
          }
        }
      }
    None => ()
  }
  if drew_spline {
    match relation.label {
      Some(label) =>
        output <+
          "<text x=\"\{relation_label_position(layout, relation_index, ((x1 + x2) / 2, (y1 + y2) / 2)).0}\" y=\"\{relation_label_position(layout, relation_index, ((x1 + x2) / 2, (y1 + y2) / 2)).1 - 5.0}\" class=\"relation-label\">\{xml_escape(label)}</text>\n"
      None => ()
    }
  } else {
    output <+
      "<line x1=\"\{x1}\" y1=\"\{y1}\" x2=\"\{x2}\" y2=\"\{y2}\" class=\"relation\"\{style}\{dash}\{marker_start}\{marker_end}/>\n"
    match relation.label {
      Some(label) =>
        output <+
          "<text x=\{(x1 + x2) / 2} y=\{(y1 + y2) / 2 - 5} class=\"relation-label\">\{xml_escape(label)}</text>\n"
      None => ()
    }
  }
  match relation.left_cardinality {
    Some(text) =>
      output <+
        "<text x=\"\{x1 - 8}\" y=\"\{y1 - 6}\" class=\"relation-end-label\">\{xml_escape(text)}</text>\n"
    None => ()
  }
  match relation.right_cardinality {
    Some(text) =>
      output <+
        "<text x=\"\{x2 + 8}\" y=\"\{y2 - 6}\" class=\"relation-end-label\">\{xml_escape(text)}</text>\n"
    None => ()
  }
  match relation.left_role {
    Some(text) =>
      output <+
        "<text x=\"\{x1 - 8}\" y=\"\{y1 + 13}\" class=\"relation-end-label\">\{xml_escape(text)}</text>\n"
    None => ()
  }
  match relation.right_role {
    Some(text) =>
      output <+
        "<text x=\"\{x2 + 8}\" y=\"\{y2 + 13}\" class=\"relation-end-label\">\{xml_escape(text)}</text>\n"
    None => ()
  }
}

///|
fn append_entity(
  output : StringBuilder,
  diagram : ClassDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(diagram, index, text_metrics)
  let header_height = text_metrics.header_height()
  let row_height = text_metrics.row_height()
  let fill = @core.svg_color(entity.color, "#FEFECE")
  let stroke = @core.svg_color(entity.line_color, "#181818")
  let stroke_style = match entity.line_style {
    Some("dashed") => "stroke-dasharray:6 4"
    Some("dotted") => "stroke-dasharray:2 3"
    Some("bold") => "stroke-width:2.5"
    _ => "stroke-width:1.2"
  }
  let line_attributes = " style=\"stroke:\{stroke};\{stroke_style}\""
  output <+
    "<g class=\"class-node\" data-code=\"\{xml_escape(entity.qualified_code)}\"><rect x=\"\{x}\" y=\"\{y}\" width=\"\{width}\" height=\"\{height}\" fill=\"\{fill}\"\{line_attributes}/><line x1=\"\{x}\" y1=\"\{y + header_height}\" x2=\"\{x + width}\" y2=\"\{y + header_height}\"\{line_attributes}/><text x=\"\{x + width / 2}\" y=\"\{y + header_height - 14}\" class=\"class-title\">\{xml_escape(entity.display)}</text>\n"
  let mut visible_index = 0
  for entry in entity.members {
    guard entity.entry_visible(entry) else { continue }
    let member_y = y + header_height + (visible_index + 1) * row_height
    if entry.is_separator {
      output <+
        "<line x1=\"\{x}\" y1=\"\{member_y - row_height / 2}\" x2=\"\{x + width}\" y2=\"\{member_y - row_height / 2}\"\{line_attributes}/>\n"
    } else {
      output <+
        "<text x=\"\{x + 12}\" y=\"\{member_y}\" class=\"member\">\{xml_escape(entry.raw)}</text>\n"
    }
    visible_index += 1
  }
  output.write_string("</g>\n")
}

///|
/// Render the parsed class graph to a standalone SVG.
///
/// Node placement is deterministic so parsing and rendering can be used without
/// an external process. The graph-layout adapter will replace these coordinates
/// with Graphviz positions while retaining this entity and relation painter.
pub fn ClassDiagram::render_svg(self : ClassDiagram) -> String {
  let background = @core.svg_color(self.style.background_color, "#fff")
  let font_family = @core.font_family(self.style)
  let font_size = @core.font_size(self.style)
  let line_color = @core.svg_color(self.style.line_color, "#181818")
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
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{output_width}\" height=\"\{output_height}\" viewBox=\"0 0 \{output_width} \{output_height}\" role=\"img\" aria-label=\"Class diagram\">\n"
  output.write_string(
    "<defs><marker id=\"arrow\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\"/></marker><marker id=\"triangle\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"9\" markerHeight=\"9\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"white\"/></marker><marker id=\"diamond\" viewBox=\"0 0 12 10\" refX=\"1\" refY=\"5\" markerWidth=\"10\" markerHeight=\"8\" orient=\"auto-start-reverse\"><path d=\"M 0 5 L 6 0 L 12 5 L 6 10 z\"/></marker><marker id=\"diamond-open\" viewBox=\"0 0 12 10\" refX=\"1\" refY=\"5\" markerWidth=\"10\" markerHeight=\"8\" orient=\"auto-start-reverse\"><path d=\"M 0 5 L 6 0 L 12 5 L 6 10 z\" fill=\"white\"/></marker></defs>\n<style>svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}.class-node rect,.class-node line{stroke:#181818;stroke-width:1.2}.relation{stroke:\{line_color};stroke-width:1.2}.class-node line,.relation{fill:none}.class-title{text-anchor:middle;font-weight:bold;fill:#181818}.member,.relation-label{fill:#181818}.relation-label{text-anchor:middle;font-size:12px}</style>\n",
  )
  output.write_string(
    "<style>.package rect{stroke:#181818;stroke-width:1.2}.package-title{font-weight:bold;fill:#181818}.class-note rect,.class-note path{stroke:#181818;stroke-width:1.2}.note-text{fill:#181818}</style>\n",
  )
  output.write_string(
    "<defs><marker id=\"bar\" viewBox=\"0 0 8 10\" refX=\"4\" refY=\"5\" markerWidth=\"6\" markerHeight=\"8\" orient=\"auto-start-reverse\"><path d=\"M 4 0 L 4 10\"/></marker><marker id=\"circle\" viewBox=\"0 0 10 10\" refX=\"5\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><circle cx=\"5\" cy=\"5\" r=\"4\" fill=\"white\"/></marker><marker id=\"circle-filled\" viewBox=\"0 0 10 10\" refX=\"5\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><circle cx=\"5\" cy=\"5\" r=\"4\"/></marker><marker id=\"square\" viewBox=\"0 0 10 10\" refX=\"5\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><rect x=\"1\" y=\"1\" width=\"8\" height=\"8\" fill=\"white\"/></marker><marker id=\"plus\" viewBox=\"0 0 10 10\" refX=\"5\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 5 1 L 5 9 M 1 5 L 9 5\"/></marker><marker id=\"crowfoot\" viewBox=\"0 0 12 12\" refX=\"2\" refY=\"6\" markerWidth=\"9\" markerHeight=\"9\" orient=\"auto-start-reverse\"><path d=\"M 2 6 L 11 1 M 2 6 L 11 6 M 2 6 L 11 11\"/></marker></defs>\n",
  )
  append_packages(output, self, layout)
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
pub fn render_svg(diagram : ClassDiagram) -> String {
  diagram.render_svg()
}
