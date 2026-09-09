///|
/// Sequence-specific resources travel with the drawing context; geometry is
/// emitted through Graphic and marker handles belong to the SVG document.
priv struct SequenceDrawing {
  graphic : @graphics.Graphic
  arrow : @graphics.MarkerRef
  arrow_start : @graphics.MarkerRef
  open_arrow : @graphics.MarkerRef
  open_arrow_start : @graphics.MarkerRef
}

///|
fn sequence_point(x : Int, y : Int) -> @graphics.Point {
  { x: x.to_double(), y: y.to_double(), }
}

///|
fn SequenceDrawing::draw(
  self : SequenceDrawing,
  shape : @graphics.Shape,
  class_name? : String,
  fill? : @graphics.Paint = Inherit,
) -> Unit {
  self.graphic
  .with_style({ ..Default::default(), fill, })
  .draw(shape, metadata={ ..Default::default(), class_name, })
}

///|
fn SequenceDrawing::group(
  self : SequenceDrawing,
  metadata : @graphics.Metadata,
  draw : (SequenceDrawing) -> Unit,
) -> Unit {
  self.graphic.group(metadata, graphic => draw({ ..self, graphic, }))
}

///|
fn SequenceDrawing::link(
  self : SequenceDrawing,
  url : String?,
  draw : (SequenceDrawing) -> Unit,
) -> Unit {
  guard url is Some(url) else { return draw(self) }
  self.graphic.link(url, graphic => draw({ ..self, graphic, }), target="_top")
}

///|
fn SequenceDrawing::marker(
  self : SequenceDrawing,
  head : @seq.ArrowHead,
  start : Bool,
) -> @graphics.MarkerRef? {
  match (head, start) {
    (@seq.Normal, true) => Some(self.arrow_start)
    (@seq.Normal, false) => Some(self.arrow)
    (@seq.Async, true) => Some(self.open_arrow_start)
    (@seq.Async, false) => Some(self.open_arrow)
    (@seq.CrossX | @seq.NoneHead, _) => None
  }
}

///|
fn sequence_drawing(document : @svg.SvgDocument) -> SequenceDrawing {
  let define_arrow = (name : String, start : Bool, open : Bool) => {
    let base = if start { 10 } else { 0 }
    let tip = if start { 0 } else { 10 }
    document.define_marker(
      name,
      {
        origin: sequence_point(0, 0),
        viewport: { width: 10, height: 10, },
        reference: sequence_point(if start { 1 } else { 9 }, 5),
        size: { width: 7, height: 7, },
        orientation: if !start && !open {
          AutoStartReverse
        } else {
          Auto
        },
        units: StrokeWidth,
      },
      graphic => {
        let segments : Array[@graphics.PathSegment] = [
          MoveTo(sequence_point(base, 0)),
          LineTo(sequence_point(tip, 5)),
          LineTo(sequence_point(base, 10)),
        ]
        if !open {
          segments.push(Close)
        }
        graphic.draw(Path(segments), metadata={
          ..Default::default(),
          class_name: Some(if open { "arrow-open" } else { "arrow-fill" }),
        })
      },
    )
  }
  let arrow = define_arrow("arrow", false, false)
  let arrow_start = define_arrow("arrow-start", true, false)
  let open_arrow = define_arrow("open-arrow", false, true)
  let open_arrow_start = define_arrow("open-arrow-start", true, true)
  {
    graphic: document.graphic(),
    arrow,
    arrow_start,
    open_arrow,
    open_arrow_start,
  }
}
