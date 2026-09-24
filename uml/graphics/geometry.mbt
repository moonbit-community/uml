///|
/// A position in layout coordinates. No rounding occurs in the drawing layer.
pub(all) struct Point {
  x : Double
  y : Double
} derive(Eq, Debug, Default)

///|
pub extend Point with Eq::{not_equal, equal}

///|
pub extend Point with Debug::{to_repr}

///|
pub extend Point with Default::{default}

///|
/// Absolute path operations, including curves and arcs without flattening.
pub(all) enum PathSegment {
  MoveTo(Point)
  LineTo(Point)
  CubicTo(Point, Point, Point)
  QuadraticTo(Point, Point)
  ArcTo(
    rx~ : Double,
    ry~ : Double,
    rotation~ : Double,
    large_arc~ : Bool,
    sweep~ : Bool,
    end~ : Point
  )
  Close
} derive(Eq, Debug)

///|
pub extend PathSegment with Eq::{not_equal, equal}

///|
pub extend PathSegment with Debug::{to_repr}

///|
/// Graphviz's 3n+1 spline becomes cubic segments; other point lists are
/// polylines. The control points are preserved, not fitted or resampled.
pub fn spline_segments(points : Array[(Double, Double)]) -> Array[PathSegment] {
  guard points.length() > 0 else { return [] }
  let point = index => Point::{ x: points[index].0, y: points[index].1, }
  let segments = [MoveTo(point(0))]
  if (points.length() - 1) % 3 == 0 {
    for index = 1; index < points.length(); index = index + 3 {
      segments.push(CubicTo(point(index), point(index + 1), point(index + 2)))
    }
  } else {
    for index in 1..<points.length() {
      segments.push(LineTo(point(index)))
    }
  }
  segments
}

///|
/// Text alignment around its baseline position.
pub(all) enum TextAnchor {
  Start
  Middle
  End
} derive(Eq, Debug)

///|
pub extend TextAnchor with Eq::{not_equal, equal}

///|
pub extend TextAnchor with Debug::{to_repr}

///|
/// An already laid-out text run. `advance` comes from the same measurement
/// used by layout; the backend must not measure it again. None leaves the
/// browser's natural spacing intact.
pub(all) struct TextRun {
  text : String
  position : Point
  advance : Double?
  anchor : TextAnchor
  font_size : Double
  font_family : String?
  strike : Bool
} derive(Eq, Debug)

///|
pub extend TextRun with Eq::{not_equal, equal}

///|
pub extend TextRun with Debug::{to_repr}

///|
/// Drawing primitives in layout coordinates. Composite UML symbols remain
/// renderer operations which draw several primitives in their existing order.
pub(all) enum Shape {
  Rectangle(
    origin~ : Point,
    width~ : Double,
    height~ : Double,
    rx~ : Double?,
    ry~ : Double?
  )
  Ellipse(center~ : Point, rx~ : Double, ry~ : Double)
  Circle(center~ : Point, radius~ : Double)
  Line(Point, Point)
  Polygon(Array[Point])
  Path(Array[PathSegment])
  MarkedPath(Array[PathSegment], PathMarkers)
  Text(TextRun)
  StyledText(TextRun, TextStyle)
  ToggleArea(
    origin~ : Point,
    width~ : Double,
    height~ : Double,
    label~ : String,
    expanded~ : Bool
  )
  TextBlock(MultilineText)
  StyledTextBlock(MultilineText, TextStyle)
} derive(Eq, Debug)

///|
pub extend Shape with Eq::{not_equal, equal}

///|
pub extend Shape with Debug::{to_repr}

///|
/// Explicit font presentation for text runs and blocks. Missing values inherit
/// the document font; layout still owns line spacing and measured advances.
pub(all) struct TextStyle {
  font_size : Double?
  font_family : String?
  italic : Bool?
  weight : Int?
} derive(Eq, Debug, Default)

///|
pub extend TextStyle with Eq::{not_equal, equal}

///|
pub extend TextStyle with Debug::{to_repr}

///|
pub extend TextStyle with Default::{default}

///|
/// A measured line with a baseline offset from the previous line.
pub(all) struct TextLine {
  text : String
  dy : Double
  advance : Double?
} derive(Eq, Debug)

///|
pub extend TextLine with Eq::{not_equal, equal}

///|
pub extend TextLine with Debug::{to_repr}

///|
/// Lines sharing a horizontal anchor. Font presentation is inherited from
/// the enclosing document; the baseline and advances are layout-owned.
pub(all) struct MultilineText {
  position : Point
  anchor : TextAnchor
  lines : Array[TextLine]
} derive(Eq, Debug)

///|
pub extend MultilineText with Eq::{not_equal, equal}

///|
pub extend MultilineText with Debug::{to_repr}

///|
/// Untranslated dimensions of a viewport or drawing resource.
pub(all) struct Size {
  width : Double
  height : Double
} derive(Eq, Debug)

///|
pub extend Size with Eq::{not_equal, equal}

///|
pub extend Size with Debug::{to_repr}
