///|
/// Normalize a graphviz point (inches, y-up) into SVG coordinates (y-down).
pub fn graphviz_point_to_svg(
  point : @geom.Point,
  bbox : @geom.Rect,
) -> (Double, Double) {
  (point.x - bbox.llx, bbox.ury - point.y)
}

///|
pub fn graphviz_path_to_svg(
  spline : @geom.Spline,
  bbox : @geom.Rect,
) -> Array[(Double, Double)] {
  spline.points.map(point => graphviz_point_to_svg(point, bbox))
}

///|
pub fn graphviz_rankdir(style : DocumentStyle) -> @rankdir.RankDir {
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
/// One graphviz edge normalized into SVG coordinates.
pub struct GraphvizEdge {
  index : Int
  paths : Array[Array[(Double, Double)]]
  label : (Double, Double)?
} derive(Eq, Debug)

///|
/// Extract edges whose graphviz ids appear in `names`, mapping each id to
/// its semantic index.
pub fn graphviz_edges(
  laid_out : @dot_layout.DotLayoutGraph,
  names : Map[Int, String],
  bbox : @geom.Rect,
) -> Array[GraphvizEdge] {
  let edges = []
  for edge_layout in laid_out.edges {
    guard names.get(edge_layout.edge.id()) is Some(index_text) else {
      continue
    }
    let index = @string.parse_int(index_text) catch { _ => continue }
    let paths = edge_layout.splines.map(spline => {
      graphviz_path_to_svg(spline, bbox)
    })
    let label = edge_layout.label_pos.map(point => {
      graphviz_point_to_svg(point, bbox)
    })
    edges.push({ index, paths, label })
  }
  edges
}

///|
/// One graphviz note node normalized into SVG coordinates.
pub struct GraphvizNote {
  note_index : Int
  x : Double
  y : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
/// Extract note nodes whose graphviz names appear in `note_names`. With
/// `offset` the result is the top-left corner, otherwise the center.
pub fn graphviz_notes(
  laid_out : @dot_layout.DotLayoutGraph,
  note_names : Map[String, Int],
  bbox : @geom.Rect,
  offset~ : Bool = true,
) -> Array[GraphvizNote] {
  let notes = []
  for node_layout in laid_out.nodes {
    guard note_names.get(node_layout.node.name()) is Some(note_index) else {
      continue
    }
    let (x, y) = graphviz_point_to_svg(node_layout.pos, bbox)
    notes.push({
      note_index,
      x: if offset { x - node_layout.width_in * 72.0 / 2.0 } else { x },
      y: if offset { y - node_layout.height_in * 72.0 / 2.0 } else { y },
      width: node_layout.width_in * 72.0,
      height: node_layout.height_in * 72.0,
    })
  }
  notes
}
