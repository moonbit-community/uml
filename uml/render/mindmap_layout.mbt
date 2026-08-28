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
  self.mindmap_style.node_style(
    idea.parent is None,
    self.has_children(index),
    idea.stereotype,
  )
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
) -> @metrics.TextMetrics {
  let idea = self.ideas[index]
  let font_size = self.node_font_size(index)
  let metrics = self.style.font_metrics(font_size~)
  tree_label_metrics(metrics, idea.label)
}

///|
fn @tree.MindmapDiagram::node_text_width(
  self : @tree.MindmapDiagram,
  index : Int,
) -> Int {
  let idea = self.ideas[index]
  let font_size = self.node_font_size(index)
  let metrics = self.style.font_metrics(font_size~)
  tree_label_width(metrics, font_size, idea.label)
}

///|
fn @tree.MindmapDiagram::node_base_size(
  self : @tree.MindmapDiagram,
  index : Int,
) -> (Int, Int) {
  let idea = self.ideas[index]
  let metrics = self.node_text_metrics(index)
  let node_style = self.node_style(index)
  match idea.shape {
    @tree.IdeaShape::Box => {
      let padding_x = node_style.padding_x.unwrap_or(
        @tree.MINDMAP_DEFAULT_PADDING_X,
      )
      let padding_y = node_style.padding_y.unwrap_or(
        @tree.MINDMAP_DEFAULT_PADDING_Y,
      )
      let width = (self.node_text_width(index) + padding_x * 2).max(
        node_style.minimum_width.unwrap_or(0),
      )
      let height = metrics.height + padding_y * 2
      (width, height)
    }
    @tree.IdeaShape::Boxless =>
      (
        (self.node_text_width(index) + boxless_horizontal_margin).max(
          node_style.minimum_width.unwrap_or(0),
        ),
        metrics.height + boxless_vertical_margin * 2,
      )
  }
}

///|
fn @tree.MindmapDiagram::node_size(
  self : @tree.MindmapDiagram,
  index : Int,
) -> (Int, Int) {
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
  let items = []
  let roots = []
  for index, idea in self.ideas {
    let (width, height) = self.node_size(index)
    let style = self.node_style(index)
    items.push({
      width,
      height,
      margin_left: style.margin_left.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      margin_right: style.margin_right.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      margin_top: style.margin_top.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      margin_bottom: style.margin_bottom.unwrap_or(@tree.MINDMAP_DEFAULT_MARGIN),
      left_children: self.children_of(index, @tree.TreeDirection::Left),
      right_children: self.children_of(index, @tree.TreeDirection::Right),
    })
    if idea.parent is None {
      roots.push(index)
    }
  }
  layout_tree(items, roots)
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
