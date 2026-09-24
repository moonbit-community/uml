///|
/// A resource handle issued by the document backend.
pub struct MarkerRef {
  id : String
} derive(Eq, Debug)

///|
pub extend MarkerRef with Eq::{not_equal, equal}

///|
pub extend MarkerRef with Debug::{to_repr}

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
pub extend PathMarkers with Eq::{not_equal, equal}

///|
pub extend PathMarkers with Debug::{to_repr}

///|
pub extend PathMarkers with Default::{default}

///|
/// Marker orientation relative to the path tangent.
pub(all) enum MarkerOrientation {
  Auto
  AutoStartReverse
} derive(Eq, Debug)

///|
pub extend MarkerOrientation with Eq::{not_equal, equal}

///|
pub extend MarkerOrientation with Debug::{to_repr}

///|
/// Whether marker dimensions scale with the referencing stroke width.
pub(all) enum MarkerUnits {
  StrokeWidth
  UserSpace
} derive(Eq, Debug)

///|
pub extend MarkerUnits with Eq::{not_equal, equal}

///|
pub extend MarkerUnits with Debug::{to_repr}

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

///|
pub extend MarkerSpec with Eq::{not_equal, equal}

///|
pub extend MarkerSpec with Debug::{to_repr}
