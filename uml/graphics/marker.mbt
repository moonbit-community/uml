///|
/// A resource handle issued by the document backend.
pub struct MarkerRef {
  id : String
} derive(Eq, Debug)

///|
/// Backend constructor; callers obtain handles by defining document markers.
pub fn MarkerRef::new(id : String) -> MarkerRef {
  { id, }
}

///|
/// Marker placement for a path. Absent handles leave that endpoint unmarked.
pub(all) struct PathMarkers {
  start : MarkerRef?
  end : MarkerRef?
} derive(Eq, Debug, Default)

///|
/// Marker orientation relative to the path tangent.
pub(all) enum MarkerOrientation {
  Auto
  AutoStartReverse
} derive(Eq, Debug)

///|
/// Whether marker dimensions scale with the referencing stroke width.
pub(all) enum MarkerUnits {
  StrokeWidth
  UserSpace
} derive(Eq, Debug)

///|
/// Marker viewport and reference point, independent of SVG syntax.
pub(all) struct MarkerSpec {
  origin : Point
  viewport : Size
  reference : Point
  size : Size
  orientation : MarkerOrientation
  units : MarkerUnits
} derive(Eq, Debug)
