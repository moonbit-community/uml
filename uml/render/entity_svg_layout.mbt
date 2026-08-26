///|
priv struct ClassLayout {
  columns : Int
  cell_width : Int
  cell_height : Int
  width : Int
  graphviz : GraphvizLayout?
  mindmap : MindmapClassLayout?
}

///|
fn @entity.EntityDiagram::layout(
  self : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> ClassLayout {
  let columns = self.entities.length().min(3).max(1)
  let mut cell_width = 220
  let mut cell_height = 180
  for entity in self.entities {
    let geometry = entity.node_geometry(text_metrics, self.family)
    cell_width = cell_width.max(geometry.width + 24)
    cell_height = cell_height.max(geometry.height + 24)
  }
  {
    columns,
    cell_width,
    cell_height,
    width: 24 + columns * cell_width,
    graphviz: None,
    mindmap: None,
  }
}

///|
fn ClassLayout::entity_rect(
  self : ClassLayout,
  diagram : @entity.EntityDiagram,
  index : Int,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, Int, Int) {
  if self.mindmap is Some(mindmap) {
    return mindmap.rects[index]
  }
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
  let geometry = diagram.entities[index].node_geometry(
    text_metrics,
    diagram.family,
  )
  (self.node_x(index), self.node_y(index), geometry.width, geometry.height)
}

///|
/// Extent of everything the renderer draws, used to size the SVG canvas like
/// PlantUML's SvekResult minMax: content is placed at (6, 6) and the canvas
/// extends 15px beyond the content's bottom-right corner.
priv struct ContentBounds {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
}

///|
fn ContentBounds::point(
  self : ContentBounds,
  x : Double,
  y : Double,
) -> ContentBounds {
  {
    min_x: self.min_x.min(x),
    min_y: self.min_y.min(y),
    max_x: self.max_x.max(x),
    max_y: self.max_y.max(y),
  }
}

///|
fn ClassLayout::content_bounds(
  self : ClassLayout,
  diagram : @entity.EntityDiagram,
  text_metrics : ClassTextMetrics,
) -> ContentBounds {
  let mut bounds : ContentBounds? = None
  let include_point = (bounds : ContentBounds?, x : Double, y : Double) => {
    bounds.map_or(Some({ min_x: x, min_y: y, max_x: x, max_y: y }), current => {
      Some(current.point(x, y))
    })
  }
  for index, entity in diagram.entities {
    guard !entity.is_hidden && !entity.is_removed else { continue }
    let (x, y, w, h) = self.entity_rect(diagram, index, text_metrics)
    let (x, y, w, h) = (
      x.to_double(),
      y.to_double(),
      w.to_double(),
      h.to_double(),
    )
    bounds = include_point(bounds, x, y)
    bounds = include_point(bounds, x + w, y + h)
  }
  match self.mindmap {
    Some(mindmap) =>
      for edge in mindmap.structure_edges {
        bounds = include_point(bounds, edge.x1.to_double(), edge.y1.to_double())
        bounds = include_point(
          bounds,
          edge.control1_x.to_double(),
          edge.control1_y.to_double(),
        )
        bounds = include_point(
          bounds,
          edge.control2_x.to_double(),
          edge.control2_y.to_double(),
        )
        bounds = include_point(bounds, edge.x2.to_double(), edge.y2.to_double())
      }
    None =>
      match self.graphviz {
        Some(graphviz) => {
          for edge in graphviz.edges {
            for spline in edge.splines {
              for point in spline.points {
                let x = point.x
                let y = point.y
                bounds = include_point(bounds, x, y)
              }
            }
          }
          for edge in graphviz.note_edges {
            for spline in edge.splines {
              for point in spline.points {
                let x = point.x
                let y = point.y
                bounds = include_point(bounds, x, y)
              }
            }
          }
          for p in graphviz.packages {
            guard p.package_index < diagram.packages.length() else { continue }
            bounds = include_point(bounds, p.x, p.y)
            bounds = include_point(bounds, p.x + p.width, p.y + p.height)
          }
          for note in graphviz.notes {
            guard note.note_index < diagram.notes.length() else { continue }
            bounds = include_point(
              bounds,
              note.x - note.width / 2.0,
              note.y - note.height / 2.0,
            )
            bounds = include_point(
              bounds,
              note.x + note.width / 2.0,
              note.y + note.height / 2.0,
            )
          }
          for label_layout in graphviz.relation_labels {
            for text_box in label_layout.boxes() {
              bounds = include_point(bounds, text_box.x, text_box.y)
              bounds = include_point(
                bounds,
                text_box.x + text_box.width,
                text_box.y + text_box.height,
              )
            }
          }
        }
        None =>
          for relation_index, relation in diagram.relations {
            let label_layout = self.relation_label_layout(
              diagram, relation_index, relation, text_metrics,
            )
            for text_box in label_layout.boxes() {
              bounds = include_point(bounds, text_box.x, text_box.y)
              bounds = include_point(
                bounds,
                text_box.x + text_box.width,
                text_box.y + text_box.height,
              )
            }
          }
      }
  }
  bounds.unwrap_or({ min_x: 0.0, min_y: 0.0, max_x: 0.0, max_y: 0.0 })
}

///|
/// The laid-out rectangle of a package (group) referenced by a relation.
fn ClassLayout::group_rect(
  self : ClassLayout,
  diagram : @entity.EntityDiagram,
  code : String,
) -> (Double, Double, Double, Double)? {
  if self.graphviz is Some(graphviz) {
    for package_index, group in diagram.packages {
      if group.qualified_name == code {
        for group in graphviz.packages {
          if group.package_index == package_index {
            return Some((group.x, group.y, group.width, group.height))
          }
        }
      }
    }
  }
  None
}

///|
fn relation_endpoints(
  layout : ClassLayout,
  diagram : @entity.EntityDiagram,
  relation : @entity.Relation,
  left_index : Int?,
  right_index : Int?,
  text_metrics : ClassTextMetrics,
) -> ((Double, Double), (Double, Double)) {
  let endpoint_center = (index : Int?, code : String) => {
    match index {
      Some(index) => {
        let (x, y, width, height) = layout.entity_rect(
          diagram, index, text_metrics,
        )
        (
          x.to_double() + width.to_double() / 2.0,
          y.to_double() + height.to_double() / 2.0,
        )
      }
      None =>
        match layout.group_rect(diagram, code) {
          Some((x, y, width, height)) => (x + width / 2.0, y + height / 2.0)
          None => (0.0, 0.0)
        }
    }
  }
  let endpoint_style = (index : Int?) => {
    index.map_or(@entity.EntityRelationEndpointCapability::CenterEndpoint, index => {
      diagram.entities[index].render_capability(diagram.family).relation_endpoint
    })
  }
  let left_center = endpoint_center(left_index, relation.left)
  let right_center = endpoint_center(right_index, relation.right)
  let boundary_endpoint = (
    index : Int?,
    port : String?,
    other_center : (Double, Double),
  ) => {
    match index {
      Some(index) => {
        let (x, y, width, height) = layout.entity_rect(
          diagram, index, text_metrics,
        )
        let target_x = other_center.0.floor().to_int()
        let target_y = other_center.1.floor().to_int()
        let endpoint = match
          diagram.entities[index].map_port_endpoint(
            port, text_metrics, x, y, width, target_x,
          ) {
          Some(endpoint) => endpoint
          None =>
            usecase_relation_endpoint(x, y, width, height, target_x, target_y)
        }
        (endpoint.0.to_double(), endpoint.1.to_double())
      }
      None => other_center
    }
  }
  let (x1, y1) = match endpoint_style(left_index) {
    @entity.EntityRelationEndpointCapability::PortOrShapeBoundaryEndpoint =>
      boundary_endpoint(left_index, relation.left_port, right_center)
    @entity.EntityRelationEndpointCapability::ShapeBoundaryEndpoint =>
      match left_index {
        Some(index) => {
          let (left_x, left_y, left_width, left_height) = layout.entity_rect(
            diagram, index, text_metrics,
          )
          let endpoint = usecase_relation_endpoint(
            left_x,
            left_y,
            left_width,
            left_height,
            right_center.0.floor().to_int(),
            right_center.1.floor().to_int(),
          )
          (endpoint.0.to_double(), endpoint.1.to_double())
        }
        None => left_center
      }
    @entity.EntityRelationEndpointCapability::CenterEndpoint => left_center
  }
  let (x2, y2) = match endpoint_style(right_index) {
    @entity.EntityRelationEndpointCapability::PortOrShapeBoundaryEndpoint =>
      boundary_endpoint(right_index, relation.right_port, left_center)
    @entity.EntityRelationEndpointCapability::ShapeBoundaryEndpoint =>
      match right_index {
        Some(index) => {
          let (right_x, right_y, right_width, right_height) = layout.entity_rect(
            diagram, index, text_metrics,
          )
          let endpoint = usecase_relation_endpoint(
            right_x,
            right_y,
            right_width,
            right_height,
            left_center.0.floor().to_int(),
            left_center.1.floor().to_int(),
          )
          (endpoint.0.to_double(), endpoint.1.to_double())
        }
        None => right_center
      }
    @entity.EntityRelationEndpointCapability::CenterEndpoint => right_center
  }
  ((x1, y1), (x2, y2))
}

///|
fn entity_index(diagram : @entity.EntityDiagram, code : String) -> Int? {
  for index, entity in diagram.entities {
    if entity.qualified_code == code {
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
fn usecase_relation_endpoint(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  target_x : Int,
  target_y : Int,
) -> (Int, Int) {
  let center_x = x + width / 2
  let center_y = y + height / 2
  let horizontal = (target_x - center_x).abs() > (target_y - center_y).abs()
  if horizontal {
    if target_x < center_x {
      (x, center_y)
    } else {
      (x + width, center_y)
    }
  } else if target_y < center_y {
    (center_x, y)
  } else {
    (center_x, y + height)
  }
}

///|
