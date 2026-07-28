///|
/// Geometry for one visible activity instruction.
pub struct ActivityNodeLayout {
  node_index : Int
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Debug)

///|
/// A directed connector between two visible activity instructions.
pub struct ActivityEdgeLayout {
  from_node_index : Int
  to_node_index : Int
} derive(Eq, Debug)

///|
/// Complete geometry emitted by the built-in activity layout stage.
pub struct ActivityLayout {
  nodes : Array[ActivityNodeLayout]
  edges : Array[ActivityEdgeLayout]
  width : Int
  height : Int
} derive(Eq, Debug)

///|
let canvas_padding = 20

///|
let vertical_gap = 24

///|
let text_padding_x = 16

///|
let text_padding_y = 10

///|
let minimum_action_width = 80

///|
let minimum_decision_width = 76

///|
let decision_height = 46

///|
let terminal_size = 20

///|
let fork_width = 104

///|
let fork_height = 6

///|
fn node_label(node : ActivityNode) -> String? {
  match node {
    Action(label)
    | If(label)
    | ElseIf(label)
    | Else(label)
    | While(label)
    | EndWhile(label)
    | RepeatWhile(label)
    | Switch(label)
    | Case(label)
    | Note(label) => Some(label)
    _ => None
  }
}

///|
fn is_visible(node : ActivityNode) -> Bool {
  match node {
    Label(_) | Goto(_) | Swimlane(_) | Partition(_) | EndPartition | Arrow(_) =>
      false
    _ => true
  }
}

///|
fn is_decision(node : ActivityNode) -> Bool {
  match node {
    If(_)
    | ElseIf(_)
    | Else(_)
    | While(_)
    | EndWhile(_)
    | RepeatWhile(_)
    | Switch(_)
    | Case(_) => true
    _ => false
  }
}

///|
fn is_fork(node : ActivityNode) -> Bool {
  match node {
    Fork | ForkAgain | EndFork => true
    _ => false
  }
}

///|
fn node_size(node : ActivityNode, metrics : @metrics.FontMetrics) -> (Int, Int) {
  match node {
    Start | Stop | End | Kill => (terminal_size, terminal_size)
    _ if is_fork(node) => (fork_width, fork_height)
    _ if is_decision(node) => {
      let label_width = node_label(node)
        .map(label => @metrics.measure_text_with(label, metrics).width)
        .unwrap_or(0)
      (
        (label_width + text_padding_x * 2).max(minimum_decision_width),
        decision_height,
      )
    }
    Note(label) => {
      let text = @metrics.measure_text_with(label, metrics)
      (text.width + text_padding_x * 2, text.height + text_padding_y * 2)
    }
    Action(label) => {
      let text = @metrics.measure_text_with(label, metrics)
      (
        (text.width + text_padding_x * 2).max(minimum_action_width),
        text.height + text_padding_y * 2,
      )
    }
    EndIf | Repeat | EndSwitch => (terminal_size, terminal_size)
    _ => (terminal_size, terminal_size)
  }
}

///|
/// Lay out visible instructions on PlantUML's default top-to-bottom axis.
///
/// The layout stage deliberately owns coordinates and edges rather than using
/// Graphviz. Structured branch packing is layered on top of this geometry in
/// the same way PlantUML's `Ftile` decorators refine instruction tiles.
pub fn ActivityDiagram::layout(self : ActivityDiagram) -> ActivityLayout {
  let font_metrics = @metrics.FontMetrics::from_defaults()
  let sizes = []
  let mut content_width = minimum_action_width
  let mut content_height = 0
  for node in self.nodes {
    guard is_visible(node) else { continue }
    let (width, height) = node_size(node, font_metrics)
    sizes.push((width, height))
    content_width = content_width.max(width)
    content_height += height
  }
  if !sizes.is_empty() {
    content_height += vertical_gap * (sizes.length() - 1)
  }
  let nodes = []
  let edges = []
  let mut y = canvas_padding
  let mut visible_index = 0
  let mut previous : Int? = None
  for node_index, node in self.nodes {
    guard is_visible(node) else { continue }
    let (width, height) = sizes[visible_index]
    let x = canvas_padding + (content_width - width) / 2
    nodes.push({ node_index, x, y, width, height })
    match previous {
      Some(from_node_index) =>
        edges.push({ from_node_index, to_node_index: node_index })
      None => ()
    }
    previous = Some(node_index)
    visible_index += 1
    y += height + vertical_gap
  }
  {
    nodes,
    edges,
    width: content_width + canvas_padding * 2,
    height: content_height + canvas_padding * 2,
  }
}
