///|
fn state_embedded_size(
  entity : @entity.Entity,
  style : @style.DocumentStyle,
) -> (Double, Double) {
  let metrics = ClassTextMetrics::new(style)
  let (width, height) = if entity.kind is @entity.Map {
    entity.map_node_size(metrics)
  } else {
    entity.json_node_size(metrics)
  }
  (width.to_double(), height.to_double())
}

///|
/// Share the entity image painter without running a second layout. The state
/// DOT graph supplies placement; the image's local origin remains exact.
fn append_state_embedded(
  output : @graphics.Graphic,
  style : @style.DocumentStyle,
  entity : @entity.Entity,
  node : StateNodeLayout,
) -> Unit {
  let diagram : @entity.EntityDiagram = {
    family: @entity.ClassDiagram,
    entities: [entity],
    relations: [],
    packages: [],
    notes: [],
    constraints: [],
    together_groups: [],
    style,
  }
  let graphviz : GraphvizLayout = {
    width: node.width,
    height: node.height,
    nodes: [
      {
        code: entity.qualified_code,
        x: node.width / 2.0,
        y: node.height / 2.0,
        width: node.width,
        height: node.height,
      },
    ],
    edges: [],
    note_edges: [],
    relation_labels: [],
    constraints: [],
    packages: [],
    notes: [],
  }
  let context : EntityPaintContext = {
    output: output.translated(node.x, node.y),
    diagram,
    text_metrics: ClassTextMetrics::new(style),
  }
  context.append_object_like(entity, 0, {
    graphviz: Some(graphviz),
    mindmap: None,
  })
}
