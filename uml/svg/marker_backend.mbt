///|
/// Define marker geometry in a fresh local drawing context. Names are
/// renderer constants; duplicate names receive unique document-owned IDs.
pub fn SvgDocument::define_marker(
  self : SvgDocument,
  name : String,
  spec : @graphics.MarkerSpec,
  draw : (@graphics.Graphic) -> Unit,
) -> @graphics.MarkerRef {
  let id = for index = 0 {
    let candidate = if index == 0 { name } else { "\{name}-\{index}" }
    guard self.marker_ids.contains(candidate) else { break candidate }
    continue index + 1
  }
  self.marker_ids.push(id)
  let writer = self.writer
  writer.open("defs")
  writer.open("marker", attributes=[
    ("id", id),
    (
      "viewBox",
      "\{spec.origin.x} \{spec.origin.y} \{spec.viewport.width} \{spec.viewport.height}",
    ),
    ("refX", spec.reference.x.to_string()),
    ("refY", spec.reference.y.to_string()),
    ("markerWidth", spec.size.width.to_string()),
    ("markerHeight", spec.size.height.to_string()),
    (
      "markerUnits",
      match spec.units {
        StrokeWidth => "strokeWidth"
        UserSpace => "userSpaceOnUse"
      },
    ),
    (
      "orient",
      match spec.orientation {
        Auto => "auto"
        AutoStartReverse => "auto-start-reverse"
      },
    ),
  ])
  draw(writer.graphic())
  writer.close()
  writer.close()
  @graphics.MarkerRef::new(id)
}

///|
fn marker_attributes(
  markers : @graphics.PathMarkers,
) -> Array[(String, String)] {
  [
    ..markers.start.map_or([], marker => {
      [("marker-start", "url(#\{marker.id})")]
    }),
    ..markers.end.map_or([], marker => [("marker-end", "url(#\{marker.id})")]),
  ]
}

///|
const ARROW_MARKER_EXTENT : Double = 10.0

///|
const ARROW_MARKER_MIDDLE : Double = ARROW_MARKER_EXTENT / 2.0

///|
const ARROW_MARKER_REFERENCE_X : Double = 9.0

///|
/// Define the shared PlantUML triangle marker and return its resource handle.
pub fn SvgDocument::arrow_marker(
  self : SvgDocument,
  name : String,
  marker_width~ : Double,
  marker_height~ : Double,
  fill~ : String,
) -> @graphics.MarkerRef {
  self.define_marker(
    name,
    {
      origin: { x: 0.0, y: 0.0, },
      viewport: { width: ARROW_MARKER_EXTENT, height: ARROW_MARKER_EXTENT, },
      reference: { x: ARROW_MARKER_REFERENCE_X, y: ARROW_MARKER_MIDDLE, },
      size: { width: marker_width, height: marker_height, },
      orientation: AutoStartReverse,
      units: StrokeWidth,
    },
    output => {
      output
      .with_style({ ..@graphics.DrawingStyle::default(), fill: Color(fill), })
      .draw(
        Path([
          MoveTo({ x: 0.0, y: 0.0, }),
          LineTo({ x: ARROW_MARKER_EXTENT, y: ARROW_MARKER_MIDDLE, }),
          LineTo({ x: 0.0, y: ARROW_MARKER_EXTENT, }),
          Close,
        ]),
      )
    },
  )
}
