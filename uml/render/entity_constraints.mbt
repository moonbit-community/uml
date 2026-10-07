///|
/// SvekEdge reserves a square label for an otherwise unlabelled constrained
/// link, then elects its perimeter point nearest to the routed path.
const ENTITY_CONSTRAINT_SPOT : Int = 10

///|
pub struct RelationConstraintLayout {
  start : (Double, Double)
  end : (Double, Double)
  label : RelationTextBox
} derive(Eq, Debug)

///|
pub extend RelationConstraintLayout with Eq::{not_equal, equal}

///|
pub extend RelationConstraintLayout with Debug::{to_repr}

///|
fn constraint_spot_label() -> String {
  "<<TABLE FIXEDSIZE=\"TRUE\" WIDTH=\"\{ENTITY_CONSTRAINT_SPOT}\" HEIGHT=\"\{ENTITY_CONSTRAINT_SPOT}\"><TR><TD></TD></TR></TABLE>>"
}

///|
fn @entity.EntityDiagram::relation_visible(
  self : @entity.EntityDiagram,
  relation : @entity.Relation,
) -> Bool {
  !relation.has_style("hidden") &&
  self
  .entity(relation.left)
  .map_or(true, entity => !entity.is_hidden && !entity.is_removed) &&
  self
  .entity(relation.right)
  .map_or(true, entity => !entity.is_hidden && !entity.is_removed)
}

///|
fn constraint_anchor(
  edge : @graphviz.GraphvizEdge,
  relation : @entity.Relation,
  metrics : ClassTextMetrics,
) -> (Double, Double)? {
  guard edge.label is Some(center) else { return None }
  let size = relation.label.map_or(
    (ENTITY_CONSTRAINT_SPOT, ENTITY_CONSTRAINT_SPOT),
    text => {
      let measured = metrics.relation_label_regular.entity_measure(text)
      (measured.width, measured.height)
    },
  )
  let x = center.x - size.0.to_double() / 2.0
  let y = center.y - size.1.to_double() / 2.0
  let side = ENTITY_CONSTRAINT_SPOT.to_double()
  let half = side / 2.0
  let candidates = [
    (x, y),
    (x + half, y),
    (x + side, y),
    (x, y + half),
    (x + side, y + half),
    (x, y + side),
    (x + half, y + side),
    (x + side, y + side),
  ]
  let paths = sample_spline_segments(relation_edge_paths(edge))
  let mut nearest : (Double, (Double, Double))? = None
  for candidate in candidates {
    for segment in paths {
      for point in [segment.0, segment.1] {
        let distance = relation_point_distance_squared(candidate, point)
        if nearest.map_or(true, previous => distance < previous.0) {
          nearest = Some((distance, candidate))
        }
      }
    }
  }
  nearest.map(pair => pair.1)
}

///|
fn @entity.EntityDiagram::relation_constraint_layouts(
  self : @entity.EntityDiagram,
  metrics : ClassTextMetrics,
  edges : Array[@graphviz.GraphvizEdge],
) -> Array[RelationConstraintLayout] {
  let output : Array[RelationConstraintLayout] = []
  let anchors : Map[Int, (Double, Double)] = Map([])
  for edge in edges {
    let relation = self.relations[edge.index]
    guard self.relation_visible(relation) else { continue }
    if constraint_anchor(edge, relation, metrics) is Some(anchor) {
      anchors[edge.index] = anchor
    }
  }
  for constraint in self.constraints {
    guard anchors.get(constraint.first_relation) is Some(start) &&
      anchors.get(constraint.second_relation) is Some(end) else {
      continue
    }
    output.push({
      start,
      end,
      label: relation_text_box_from_center(
        constraint.text,
        ((start.0 + end.0) / 2.0, (start.1 + end.1) / 2.0),
        metrics.relation_label_regular,
      ),
    })
  }
  output
}

///|
fn draw_relation_constraints(
  output : @graphics.Graphic,
  constraints : Array[RelationConstraintLayout],
  metrics : ClassTextMetrics,
) -> Unit {
  for constraint in constraints {
    output
    .with_style({
      ..Default::default(),
      stroke: Color("black"),
      stroke_width: Some(1),
      dash: Some([3, 3]),
      inline: true,
    })
    .draw(
      Line({ x: constraint.start.0, y: constraint.start.1, }, {
        x: constraint.end.0,
        y: constraint.end.1,
      }),
      metadata={
        ..Default::default(),
        class_name: Some("relation-constraint"),
      },
    )
    draw_entity_text(
      output,
      constraint.label.x,
      constraint.label.baseline,
      constraint.label.text,
      metrics.relation_label_regular,
      class_name="relation-constraint-label",
      fill="black",
    )
  }
}
