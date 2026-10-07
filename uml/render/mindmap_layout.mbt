///|
let boxless_horizontal_margin = 3

///|
let boxless_vertical_margin = 1

///|
fn @tree.MindmapDiagram::has_children(
  self : @tree.MindmapDiagram,
  index : Int,
) -> Bool {
  self.ideas.any(idea => idea.parent == Some(index))
}

///|
fn @tree.MindmapDiagram::children_of(
  self : @tree.MindmapDiagram,
  parent : Int,
  direction : @tree.TreeDirection,
) -> Array[Int] {
  let children = []
  for index, idea in self.ideas {
    if idea.parent == Some(parent) && idea.direction == direction {
      children.push(index)
    }
  }
  children
}

///|
fn @tree.MindmapDiagram::node_style(
  self : @tree.MindmapDiagram,
  index : Int,
) -> @tree.MindmapNodeStyle {
  let idea = self.ideas[index]
  mindmap_properties(self, index, false).fold(
    init=self.mindmap_style.node_style(
      idea.parent is None,
      self.has_children(index),
      idea.stereotype,
    ),
    (style, property) => style.with_property(property.name, property.value),
  )
}

///|
fn mindmap_properties(
  diagram : @tree.MindmapDiagram,
  index : Int,
  arrow : Bool,
) -> Array[@tree.WbsStyleProperty] {
  let idea = diagram.ideas[index]
  let selected : Array[(Int, Int, @tree.WbsStyleProperty)] = []
  for order, property in diagram.style_properties {
    let mut score = 0
    let matches = property.selector
      .to_lower()
      .split(" ")
      .all(word => {
        if word.is_empty() {
          return true
        }
        score += 1
        match word {
          "root" | "element" | "mindmapdiagram" => true
          "node" => !arrow
          "arrow" => arrow
          "rootnode" => {
            score += 100
            !arrow && idea.parent is None
          }
          "leafnode" => {
            score += 100
            !arrow && idea.parent is Some(_) && !diagram.has_children(index)
          }
          "boxless" => {
            score += 100
            !arrow && idea.shape is @tree.IdeaShape::Boxless
          }
          _ if word.has_prefix(".") => {
            score += 1000
            idea.stereotype.map_or(false, value => {
              value.trim().trim_start(chars="<").trim_end(chars=">").to_lower() ==
              word[1:]
            })
          }
          _ if word.has_prefix("depth(") && word.has_suffix(")") => {
            score += 100
            let depth = @string.parse_int(word[6:word.length() - 1]) catch {
              _ => -1
            }
            depth == idea.level
          }
          _ => false
        }
      })
    if matches {
      selected.push((score, order, property))
    }
  }
  selected.sort_by((a, b) => if a.0 == b.0 { a.1 - b.1 } else { a.0 - b.0 })
  selected.map(item => item.2)
}

///|
fn @tree.MindmapDiagram::node_font_size(
  self : @tree.MindmapDiagram,
  index : Int,
) -> Int {
  self.node_style(index).font_size.unwrap_or(
    self.style.font_size_value(fallback=14),
  )
}

///|
fn @tree.MindmapDiagram::node_text_metrics(
  self : @tree.MindmapDiagram,
  index : Int,
) -> TreeLabelMetrics {
  let idea = self.ideas[index]
  let metrics = self.node_font_metrics(index)
  tree_label_metrics(
    metrics,
    idea.label,
    wrap_width=self.node_style(index).wrap_width.unwrap_or(0.0),
  )
}

///|
fn @tree.MindmapDiagram::node_text_width(
  self : @tree.MindmapDiagram,
  index : Int,
) -> Double {
  let idea = self.ideas[index]
  let font_size = self.node_font_size(index)
  let metrics = self.node_font_metrics(index)
  tree_label_width(
    metrics,
    font_size,
    idea.label,
    wrap_width=self.node_style(index).wrap_width.unwrap_or(0.0),
  )
}

///|
fn @tree.MindmapDiagram::node_font_metrics(
  self : @tree.MindmapDiagram,
  index : Int,
) -> @metrics.FontMetrics {
  let style = self.node_style(index)
  self.style.font_metrics_for(
    style.font_name.unwrap_or(self.style.font_family()),
    font_size=self.node_font_size(index),
    font_weight=style.font_weight.unwrap_or(400),
    font_style=if style.italic.unwrap_or(false) { Italic } else { Normal },
  )
}

///|
fn @tree.MindmapDiagram::node_base_size(
  self : @tree.MindmapDiagram,
  index : Int,
) -> (Double, Double) {
  let idea = self.ideas[index]
  let metrics = self.node_text_metrics(index)
  let node_style = self.node_style(index)
  match idea.shape {
    @tree.IdeaShape::Box => {
      let padding_x = node_style.padding_left.unwrap_or(
        @tree.MINDMAP_DEFAULT_PADDING_X,
      )
      let padding_y = node_style.padding_top.unwrap_or(
        @tree.MINDMAP_DEFAULT_PADDING_Y,
      )
      let width = (self.node_text_width(index) +
      padding_x +
      node_style.padding_right.unwrap_or(@tree.MINDMAP_DEFAULT_PADDING_X)).max(
        node_style.minimum_width.unwrap_or(0),
      )
      let height = metrics.height +
        padding_y +
        node_style.padding_bottom.unwrap_or(@tree.MINDMAP_DEFAULT_PADDING_Y)
      (width, height)
    }
    @tree.IdeaShape::Boxless =>
      (
        (self.node_text_width(index) + boxless_horizontal_margin.to_double()).max(
          node_style.minimum_width.unwrap_or(0),
        ),
        metrics.height + (boxless_vertical_margin * 2).to_double(),
      )
  }
}

///|
fn @tree.MindmapDiagram::node_size(
  self : @tree.MindmapDiagram,
  index : Int,
) -> (Double, Double) {
  let (width, height) = self.node_base_size(index)
  guard self.node_style(index).same_class_width.unwrap_or(false) else {
    (width, height)
  }
  let mut shared_width = width
  for candidate in 0..<self.ideas.length() {
    guard self.node_style(candidate).same_class_width.unwrap_or(false) else {
      continue
    }
    let (candidate_width, _) = self.node_base_size(candidate)
    shared_width = shared_width.max(candidate_width)
  }
  (shared_width, height)
}

///|
/// Calculate PlantUML-style, symmetric mindmap geometry without rendering it.
fn @tree.MindmapDiagram::layout(self : @tree.MindmapDiagram) -> MindmapLayout {
  let vertical = self.style.layout_direction is Some(TopToBottom)
  let items = []
  let roots = []
  for index, idea in self.ideas {
    let (width, height) = self.node_size(index)
    let style = self.node_style(index)
    let item : LayoutItem = {
      width,
      height,
      margin_left: style.margin_left.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      margin_right: style.margin_right.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      margin_top: style.margin_top.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      margin_bottom: style.margin_bottom.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      left_children: self.children_of(index, @tree.TreeDirection::Left),
      right_children: self.children_of(index, @tree.TreeDirection::Right),
    }
    items.push(
      if vertical {
        {
          ..item,
          width: item.height,
          height: item.width,
          margin_left: item.margin_top,
          margin_right: item.margin_bottom,
          margin_top: item.margin_left,
          margin_bottom: item.margin_right,
        }
      } else {
        item
      },
    )
    if idea.parent is None {
      roots.push(index)
    }
  }
  if !vertical {
    return layout_tree(items, roots)
  }
  let nodes = []
  let edges = []
  let mut width = 0.0
  let mut height = 0.0
  for root in roots {
    let layout = layout_tree(items, [root], branch_gap=5.0, curve_control=10.0)
    let rotated : MindmapLayout = {
      nodes: layout.nodes.map(node => {
        ..node,
        x: node.y,
        y: node.x,
        width: node.height,
        height: node.width,
      }),
      edges: layout.edges.map(edge => {
        ..edge,
        x1: edge.y1,
        y1: edge.x1,
        x2: edge.y2,
        y2: edge.x2,
        control1_x: edge.control1_y,
        control1_y: edge.control1_x,
        control2_x: edge.control2_y,
        control2_y: edge.control2_x,
      }),
      width: layout.height,
      height: layout.width,
    }
    let placed = rotated.translated(0.0, height)
    nodes.append(placed.nodes)
    edges.append(placed.edges)
    width = width.max(rotated.width)
    height += rotated.height
  }
  { nodes, edges, width, height, }
}

///|
/// Calculate PlantUML-style, symmetric mindmap geometry without rendering it.
pub fn layout_mindmap(diagram : @tree.MindmapDiagram) -> MindmapLayout {
  diagram.layout()
}

///|
/// The effective node style for a mindmap idea, combining diagram defaults
/// with `<style>` and skinparam overrides.
pub fn mindmap_node_style(
  diagram : @tree.MindmapDiagram,
  index : Int,
) -> @tree.MindmapNodeStyle {
  diagram.node_style(index)
}
