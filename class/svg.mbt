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
  self.members.length() * text_metrics.row_height()
}

///|
priv struct ClassTextMetrics {
  regular : @core.FontMetrics
  bold : @core.FontMetrics
}

///|
fn ClassTextMetrics::new(style : @core.DocumentStyle) -> ClassTextMetrics {
  { regular: style.font_metrics(), bold: style.font_metrics(font_weight=700) }
}

///|
fn Entity::width(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let mut width = @core.measure_text_with(self.display, text_metrics.bold).width +
    28
  for entry in self.members {
    width = width.max(
      @core.measure_text_with(entry.raw, text_metrics.regular).width + 28,
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
  }
}

///|
fn entity_index(diagram : ClassDiagram, code : String) -> Int? {
  for index, entity in diagram.entities {
    if entity.code == code {
      return Some(index)
    }
  }
  None
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
  let x1 = layout.node_x(left_index) + left.width(text_metrics) / 2
  let y1 = layout.node_y(left_index) + left.height(text_metrics) / 2
  let x2 = layout.node_x(right_index) + right.width(text_metrics) / 2
  let y2 = layout.node_y(right_index) + right.height(text_metrics) / 2
  let dash = if relation.dotted { " stroke-dasharray=\"6 4\"" } else { "" }
  let marker = match relation.kind {
    Extension | Realization => " marker-end=\"url(#triangle)\""
    Aggregation => " marker-start=\"url(#diamond-open)\""
    Composition => " marker-start=\"url(#diamond)\""
    Dependency => " marker-end=\"url(#arrow)\""
    Association => ""
  }
  output <+
    "<line x1=\"\{x1}\" y1=\"\{y1}\" x2=\"\{x2}\" y2=\"\{y2}\" class=\"relation\"\{dash}\{marker}/>\n"
  match relation.label {
    Some(label) =>
      output <+
        "<text x=\{(x1 + x2) / 2} y=\{(y1 + y2) / 2 - 5} class=\"relation-label\">\{xml_escape(label)}</text>\n"
    None => ()
  }
}

///|
fn append_entity(
  output : StringBuilder,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  let x = layout.node_x(index)
  let y = layout.node_y(index)
  let width = entity.width(text_metrics)
  let height = entity.height(text_metrics)
  let header_height = text_metrics.header_height()
  let row_height = text_metrics.row_height()
  let fill = @core.svg_color(entity.color, "#FEFECE")
  output <+
    "<g class=\"class-node\" data-code=\"\{xml_escape(entity.code)}\"><rect x=\"\{x}\" y=\"\{y}\" width=\"\{width}\" height=\"\{height}\" fill=\"\{fill}\"/><line x1=\"\{x}\" y1=\"\{y + header_height}\" x2=\"\{x + width}\" y2=\"\{y + header_height}\"/><text x=\"\{x + width / 2}\" y=\"\{y + header_height - 14}\" class=\"class-title\">\{xml_escape(entity.display)}</text>\n"
  for member_index, entry in entity.members {
    let member_y = y + header_height + (member_index + 1) * row_height
    if entry.is_separator {
      output <+
        "<line x1=\"\{x}\" y1=\"\{member_y - row_height / 2}\" x2=\"\{x + width}\" y2=\"\{member_y - row_height / 2}\"/>\n"
    } else {
      output <+
        "<text x=\"\{x + 12}\" y=\"\{member_y}\" class=\"member\">\{xml_escape(entry.raw)}</text>\n"
    }
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
  let layout = self.layout(text_metrics)
  let output = StringBuilder()
  output <+
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{layout.width}\" height=\"\{layout.height}\" viewBox=\"0 0 \{layout.width} \{layout.height}\" role=\"img\" aria-label=\"Class diagram\">\n"
  output.write_string(
    "<defs><marker id=\"arrow\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto\"><path d=\"M 0 0 L 10 5 L 0 10 z\"/></marker><marker id=\"triangle\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"9\" markerHeight=\"9\" orient=\"auto\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"white\"/></marker><marker id=\"diamond\" viewBox=\"0 0 12 10\" refX=\"1\" refY=\"5\" markerWidth=\"10\" markerHeight=\"8\" orient=\"auto\"><path d=\"M 0 5 L 6 0 L 12 5 L 6 10 z\"/></marker><marker id=\"diamond-open\" viewBox=\"0 0 12 10\" refX=\"1\" refY=\"5\" markerWidth=\"10\" markerHeight=\"8\" orient=\"auto\"><path d=\"M 0 5 L 6 0 L 12 5 L 6 10 z\" fill=\"white\"/></marker></defs>\n<style>svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}.class-node rect,.class-node line{stroke:#181818;stroke-width:1.2}.relation{stroke:\{line_color};stroke-width:1.2}.class-node line,.relation{fill:none}.class-title{text-anchor:middle;font-weight:bold;fill:#181818}.member,.relation-label{fill:#181818}.relation-label{text-anchor:middle;font-size:12px}</style>\n",
  )
  for relation in self.relations {
    append_relation(output, self, relation, text_metrics, layout)
  }
  for index, entity in self.entities {
    append_entity(output, entity, index, text_metrics, layout)
  }
  output.write_string("</svg>\n")
  output.to_string()
}

///|
pub fn render_svg(diagram : ClassDiagram) -> String {
  diagram.render_svg()
}
