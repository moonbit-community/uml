///|
fn xml_escape(value : String) -> String {
  @core.xml_escape(value)
}

///|
fn Entity::height(self : Entity) -> Int {
  38 + self.members.length() * 18
}

///|
fn Entity::width(self : Entity) -> Int {
  let mut width = @core.measure_text(self.display).width + 28
  for entry in self.members {
    width = width.max(@core.measure_text(entry.raw).width + 28)
  }
  width.max(140)
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
fn node_x(index : Int) -> Int {
  24 + index % 3 * 220
}

///|
fn node_y(index : Int) -> Int {
  24 + index / 3 * 180
}

///|
fn append_relation(
  output : StringBuilder,
  diagram : ClassDiagram,
  relation : Relation,
) -> Unit {
  guard entity_index(diagram, relation.left) is Some(left_index) else { return }
  guard entity_index(diagram, relation.right) is Some(right_index) else {
    return
  }
  let left = diagram.entities[left_index]
  let right = diagram.entities[right_index]
  let x1 = node_x(left_index) + left.width() / 2
  let y1 = node_y(left_index) + left.height() / 2
  let x2 = node_x(right_index) + right.width() / 2
  let y2 = node_y(right_index) + right.height() / 2
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
fn append_entity(output : StringBuilder, entity : Entity, index : Int) -> Unit {
  let x = node_x(index)
  let y = node_y(index)
  let width = entity.width()
  let height = entity.height()
  let fill = @core.svg_color(entity.color, "#FEFECE")
  output <+
    "<g class=\"class-node\" data-code=\"\{xml_escape(entity.code)}\"><rect x=\"\{x}\" y=\"\{y}\" width=\"\{width}\" height=\"\{height}\" fill=\"\{fill}\"/><line x1=\"\{x}\" y1=\"\{y + 38}\" x2=\"\{x + width}\" y2=\"\{y + 38}\"/><text x=\"\{x + width / 2}\" y=\"\{y + 24}\" class=\"class-title\">\{xml_escape(entity.display)}</text>\n"
  for member_index, entry in entity.members {
    let member_y = y + 56 + member_index * 18
    if entry.is_separator {
      output <+
        "<line x1=\"\{x}\" y1=\"\{member_y - 7}\" x2=\"\{x + width}\" y2=\"\{member_y - 7}\"/>\n"
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
  let columns = self.entities.length().min(3).max(1)
  let rows = (self.entities.length() + columns - 1) / columns
  let width = columns * 220 + 24
  let height = rows * 180 + 24
  let background = @core.svg_color(self.style.background_color, "#fff")
  let font_family = @core.font_family(self.style)
  let font_size = @core.font_size(self.style)
  let line_color = @core.svg_color(self.style.line_color, "#181818")
  let output = StringBuilder()
  output <+
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}\" height=\"\{height}\" viewBox=\"0 0 \{width} \{height}\" role=\"img\" aria-label=\"Class diagram\">\n"
  output.write_string(
    "<defs><marker id=\"arrow\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto\"><path d=\"M 0 0 L 10 5 L 0 10 z\"/></marker><marker id=\"triangle\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"9\" markerHeight=\"9\" orient=\"auto\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"white\"/></marker><marker id=\"diamond\" viewBox=\"0 0 12 10\" refX=\"1\" refY=\"5\" markerWidth=\"10\" markerHeight=\"8\" orient=\"auto\"><path d=\"M 0 5 L 6 0 L 12 5 L 6 10 z\"/></marker><marker id=\"diamond-open\" viewBox=\"0 0 12 10\" refX=\"1\" refY=\"5\" markerWidth=\"10\" markerHeight=\"8\" orient=\"auto\"><path d=\"M 0 5 L 6 0 L 12 5 L 6 10 z\" fill=\"white\"/></marker></defs>\n<style>svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}.class-node rect,.class-node line{stroke:#181818;stroke-width:1.2}.relation{stroke:\{line_color};stroke-width:1.2}.class-node line,.relation{fill:none}.class-title{text-anchor:middle;font-weight:bold;fill:#181818}.member,.relation-label{fill:#181818}.relation-label{text-anchor:middle;font-size:12px}</style>\n",
  )
  for relation in self.relations {
    append_relation(output, self, relation)
  }
  for index, entity in self.entities {
    append_entity(output, entity, index)
  }
  output.write_string("</svg>\n")
  output.to_string()
}

///|
pub fn render_svg(diagram : ClassDiagram) -> String {
  diagram.render_svg()
}
