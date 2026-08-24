///|
/// Graphviz uses points as its normalized output unit.
pub const GRAPHVIZ_DPI : Double = 72.0

///|
/// Convert SVG pixels/Graphviz points to inches for fixed-size attributes.
pub fn points_to_inches(points : Double) -> Double {
  points / GRAPHVIZ_DPI
}

///|
/// Convert Graphviz inches to SVG pixels/points.
pub fn inches_to_points(inches : Double) -> Double {
  inches * GRAPHVIZ_DPI
}

///|
/// Create the common directed spline graph used by PlantUML diagram layouts.
pub fn new_directed_graph(
  name : String,
  style : @style.DocumentStyle,
) -> @cgraph.Graph {
  let graph = @cgraph.Graph::new(@cgraph.Directed, name~, strict=false)
  graph.set_attr("rankdir", graphviz_rankdir_attr(graphviz_rankdir(style)))
  graph.set_attr("splines", "spline")
  graph
}

///|
/// Configure a Graphviz node with an exact SVG-space size.
pub fn set_fixed_node_size(
  node : @cgraph.Node,
  width : Double,
  height : Double,
  shape? : String = "box",
) -> Unit {
  node.set_attr("label", "")
  node.set_attr("shape", shape)
  node.set_attr("width", points_to_inches(width).to_string())
  node.set_attr("height", points_to_inches(height).to_string())
  node.set_attr("fixedsize", "true")
}

///|
/// Execute dot with the shared rank direction and spline mode.
pub fn layout_dot(
  graph : @cgraph.Graph,
  style : @style.DocumentStyle,
  nodesep : Double,
  ranksep : Double,
) -> @dot_layout.DotLayoutGraph raise @dot_layout.DotLayoutError {
  @dot_layout.layout_dot(graph, options={
    rankdir: Some(graphviz_rankdir(style)),
    nodesep: Some(nodesep),
    ranksep: Some(ranksep),
    splines: Some(@dot_layout.SplinesMode::Spline),
  })
}

///|
/// Run a Graphviz layout with the shared recovery policy used by UML diagram
/// families. Unsupported Graphviz features may use a domain-provided fallback;
/// invalid graphs and unsupported layouts without a fallback remain visible to
/// the caller.
pub fn[T] layout_or_fallback(
  layout : () -> T raise @dot_layout.DotLayoutError,
  fallback : (() -> T)?,
) -> T raise @dot_layout.DotLayoutError {
  try layout() catch {
    @dot_layout.DotLayoutError::UnsupportedFeature(message~) => {
      guard fallback is Some(fallback) else {
        raise @dot_layout.DotLayoutError::UnsupportedFeature(message~)
      }
      fallback()
    }
    other => raise other
  } noraise {
    value => value
  }
}

///|
/// Normalize a graphviz point (inches, y-up) into SVG coordinates (y-down).
pub fn graphviz_point_to_svg(
  point : @geom.Point,
  bbox : @geom.Rect,
) -> GraphvizPoint {
  { x: point.x - bbox.llx, y: bbox.ury - point.y }
}

///|
/// A normalized Graphviz point in SVG coordinates.
pub(all) struct GraphvizPoint {
  x : Double
  y : Double
} derive(Eq, Debug)

///|
pub extend GraphvizPoint with Eq::{not_equal, equal}

///|
pub extend GraphvizPoint with Debug::{to_repr}

///|
/// Convert a normalized point at the SVG/tuple serialization boundary.
pub fn GraphvizPoint::pair(self : GraphvizPoint) -> (Double, Double) {
  (self.x, self.y)
}

///|
fn graphviz_path_to_svg(
  spline : @geom.Spline,
  bbox : @geom.Rect,
) -> GraphvizSpline {
  {
    arrow_start: spline.start.map(point => graphviz_point_to_svg(point, bbox)),
    arrow_end: spline.end.map(point => graphviz_point_to_svg(point, bbox)),
    points: spline.points.map(point => graphviz_point_to_svg(point, bbox)),
  }
}

///|
pub fn graphviz_rankdir(style : @style.DocumentStyle) -> @rankdir.RankDir {
  match style.layout_direction {
    Some(LeftToRight) => @rankdir.LR
    _ => @rankdir.TB
  }
}

///|
pub fn graphviz_rankdir_attr(rankdir : @rankdir.RankDir) -> String {
  match rankdir {
    @rankdir.LR => "LR"
    @rankdir.TB => "TB"
    @rankdir.BT => "BT"
    @rankdir.RL => "RL"
  }
}

///|
pub fn graphviz_note_name(index : Int) -> String {
  "note" + index.to_string()
}

///|
/// One Graphviz cubic spline normalized into SVG coordinates. `arrow_start`
/// and `arrow_end` are optional arrow clipping tips; node contact points live
/// in `points` when Graphviz routing has arrows disabled.
pub(all) struct GraphvizSpline {
  arrow_start : GraphvizPoint?
  arrow_end : GraphvizPoint?
  points : Array[GraphvizPoint]
} derive(Eq, Debug)

///|
pub extend GraphvizSpline with Eq::{not_equal, equal}

///|
pub extend GraphvizSpline with Debug::{to_repr}

///|
/// One graphviz edge normalized into SVG coordinates.
pub(all) struct GraphvizEdge {
  index : Int
  splines : Array[GraphvizSpline]
  label : GraphvizPoint?
  head_label : GraphvizPoint?
  tail_label : GraphvizPoint?
} derive(Eq, Debug)

///|
pub extend GraphvizEdge with Eq::{not_equal, equal}

///|
pub extend GraphvizEdge with Debug::{to_repr}

///|
/// Extract edges whose graphviz ids appear in `names`, mapping each id to
/// its semantic index.
pub fn graphviz_edges(
  laid_out : @dot_layout.DotLayoutGraph,
  names : Map[Int, String],
  bbox : @geom.Rect,
) -> Array[GraphvizEdge] {
  laid_out.edges.filter_map(edge_layout => {
    guard names.get(edge_layout.edge.id()) is Some(index_text) else {
      return None
    }
    let index = @string.parse_int(index_text) catch { _ => return None }
    let splines = edge_layout.splines.map(spline => {
      graphviz_path_to_svg(spline, bbox)
    })
    let label = edge_layout.label_pos.map(point => {
      graphviz_point_to_svg(point, bbox)
    })
    let head_label = edge_layout.head_label_pos.map(point => {
      graphviz_point_to_svg(point, bbox)
    })
    let tail_label = edge_layout.tail_label_pos.map(point => {
      graphviz_point_to_svg(point, bbox)
    })
    Some({ index, splines, label, head_label, tail_label })
  })
}

///|
/// One graphviz note node normalized into SVG coordinates.
pub(all) struct GraphvizNote {
  note_index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend GraphvizNote with Eq::{not_equal, equal}

///|
pub extend GraphvizNote with Debug::{to_repr}

///|
/// Select whether normalized node coordinates identify the center or the
/// top-left corner of the node rectangle.
pub(all) enum NodeAnchor {
  Center
  TopLeft
} derive(Eq, Debug)

///|
pub extend NodeAnchor with Eq::{not_equal, equal}

///|
pub extend NodeAnchor with Debug::{to_repr}

///|
/// Extract note nodes whose graphviz names appear in `note_names`. With
/// `offset` the result is the top-left corner, otherwise the center.
pub fn graphviz_notes(
  laid_out : @dot_layout.DotLayoutGraph,
  note_names : Map[String, Int],
  bbox : @geom.Rect,
  anchor? : NodeAnchor = TopLeft,
) -> Array[GraphvizNote] {
  let notes = []
  for node_layout in laid_out.nodes {
    guard note_names.get(node_layout.node.name()) is Some(note_index) else {
      continue
    }
    let point = graphviz_point_to_svg(node_layout.pos, bbox)
    let x = point.x
    let y = point.y
    notes.push({
      note_index,
      x: match anchor {
        TopLeft => x - inches_to_points(node_layout.width_in) / 2.0
        Center => x
      },
      y: match anchor {
        TopLeft => y - inches_to_points(node_layout.height_in) / 2.0
        Center => y
      },
      width: inches_to_points(node_layout.width_in),
      height: inches_to_points(node_layout.height_in),
    })
  }
  notes
}
