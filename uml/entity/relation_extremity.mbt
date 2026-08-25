///|
const ARROW_DECORATION_LENGTH : Double = 5.0

///|
const ARROW_WING_LENGTH : Double = 9.0

///|
const ARROW_APERTURE : Double = 4.0

///|
const TRIANGLE_DECORATION_LENGTH : Double = 18.0

///|
const TRIANGLE_APERTURE : Double = 6.0

///|
const TRIANGLE_ARROW_DECORATION_LENGTH : Double = 8.0

///|
const TRIANGLE_ARROW_APERTURE : Double = 3.0

///|
const DIAMOND_DECORATION_LENGTH : Double = 12.0

///|
const DIAMOND_APERTURE : Double = 4.0

///|
const CROWFOOT_DECORATION_LENGTH : Double = 8.0

///|
const CROWFOOT_APERTURE : Double = 8.0

///|
const CROWFOOT_COMPOSITE_APERTURE : Double = 6.0

///|
const CIRCLE_DECORATION_LENGTH : Double = 12.0

///|
const CIRCLE_RADIUS : Double = 6.0

///|
const CIRCLE_CROWFOOT_DECORATION_LENGTH : Double = 18.0

///|
const CIRCLE_CROWFOOT_RADIUS : Double = 4.0

///|
const CIRCLE_CROWFOOT_CENTER_LENGTH : Double = 14.0

///|
const CIRCLE_LINE_DECORATION_LENGTH : Double = 15.0

///|
const CIRCLE_LINE_RADIUS : Double = 4.0

///|
const CIRCLE_LINE_CENTER_LENGTH : Double = 11.0

///|
const END_LINE_HALF_HEIGHT : Double = 4.0

///|
const END_LINE_FIRST_LENGTH : Double = 4.0

///|
const END_LINE_SECOND_LENGTH : Double = 7.0

///|
const LINE_CROWFOOT_BAR_LENGTH : Double = 10.0

///|
const NOT_NAVIGABLE_DECORATION_LENGTH : Double = 8.0

///|
const NOT_NAVIGABLE_NEAR_LENGTH : Double = 5.0

///|
const NOT_NAVIGABLE_FAR_LENGTH : Double = 13.0

///|
const NOT_NAVIGABLE_HALF_SIZE : Double = 4.0

///|
const PARENTHESIS_DECORATION_LENGTH : Double = 10.0

///|
const PARENTHESIS_RADIUS : Double = 9.0

///|
const PARENTHESIS_HALF_ANGLE : Double = 70.0 * @math.PI / 180.0

///|
const CIRCLE_CONNECT_DECORATION_LENGTH : Double = 10.0

///|
const CIRCLE_CONNECT_ARC_RADIUS : Double = 10.0

///|
const CIRCLE_CONNECT_HALF_ANGLE : Double = @math.PI / 4.0

///|
const SQUARE_DECORATION_LENGTH : Double = 5.0

///|
const SQUARE_RADIUS : Double = 5.0

///|
const PLUS_DECORATION_LENGTH : Double = 16.0

///|
const PLUS_RADIUS : Double = 8.0

///|
const HALF_ARROW_DECORATION_LENGTH : Double = 8.0

///|
const EXTENDS_LIKE_TRIANGLE_LENGTH : Double = 19.0

///|
const EXTENDS_LIKE_HALF_WIDTH : Double = 7.0

///|
const REDEFINES_BAR_LENGTH : Double = EXTENDS_LIKE_TRIANGLE_LENGTH * 1.2

///|
const DEFINED_BY_DOT_LENGTH : Double = EXTENDS_LIKE_TRIANGLE_LENGTH * 1.3

///|
const DEFINED_BY_DOT_RADIUS : Double = 2.0

///|
const DEFINED_BY_DOT_NORMAL : Double = EXTENDS_LIKE_HALF_WIDTH -
  DEFINED_BY_DOT_RADIUS

///|
const DEFAULT_EXTREMITY_STROKE_WIDTH : Double = 1.0

///|
const EMPHASIZED_EXTREMITY_STROKE_WIDTH : Double = 1.5

///|
const REDEFINES_BAR_STROKE_WIDTH : Double = 2.0

///|
priv enum RelationContactSide {
  ContactWest
  ContactEast
  ContactNorth
  ContactSouth
}

///|
priv enum RelationDecorationFill {
  NoDecorationFill
  LineDecorationFill
  BackgroundDecorationFill
}

///|
priv struct RelationDecorationArc {
  start : (Double, Double)
  end : (Double, Double)
  radius : Double
  large_arc : Bool
  sweep : Bool
}

///|
priv enum RelationDecorationShape {
  DecorationPolygon(Array[(Double, Double)])
  DecorationSegment((Double, Double), (Double, Double))
  DecorationCircle((Double, Double), Double)
  DecorationSquare((Double, Double), Double)
  DecorationArc(RelationDecorationArc)
}

///|
priv struct RelationDecorationPrimitive {
  shape : RelationDecorationShape
  fill : RelationDecorationFill
  stroke_width : Double
}

///|
priv struct RelationDecorationGeometry {
  primitives : Array[RelationDecorationPrimitive]
}

///|
priv struct RelationDecorationFrame {
  endpoint : (Double, Double)
  tangent : (Double, Double)
  normal : (Double, Double)
}

///|
fn RelationDecorationFrame::new(
  endpoint : (Double, Double),
  adjacent : (Double, Double),
) -> RelationDecorationFrame? {
  let dx = endpoint.0 - adjacent.0
  let dy = endpoint.1 - adjacent.1
  let tangent_length = (dx * dx + dy * dy).sqrt()
  guard tangent_length > 0.0 else { return None }
  let tangent = (dx / tangent_length, dy / tangent_length)
  Some({ endpoint, tangent, normal: (-tangent.1, tangent.0), })
}

///|
fn RelationDecorationFrame::point(
  self : RelationDecorationFrame,
  along : Double,
  normal : Double,
) -> (Double, Double) {
  (
    self.endpoint.0 - self.tangent.0 * along + self.normal.0 * normal,
    self.endpoint.1 - self.tangent.1 * along + self.normal.1 * normal,
  )
}

///|
fn RelationDecorationFrame::arc(
  self : RelationDecorationFrame,
  radius : Double,
  half_angle : Double,
) -> RelationDecorationArc {
  let along = radius * @math.cos(half_angle)
  let normal = radius * @math.sin(half_angle)
  {
    start: self.point(along, -normal),
    end: self.point(along, normal),
    radius,
    large_arc: false,
    sweep: false,
  }
}

///|
fn relation_decoration_primitive(
  shape : RelationDecorationShape,
  fill : RelationDecorationFill,
  stroke_width? : Double = DEFAULT_EXTREMITY_STROKE_WIDTH,
) -> RelationDecorationPrimitive {
  { shape, fill, stroke_width, }
}

///|
fn relation_decoration_polygon(
  points : Array[(Double, Double)],
  fill : RelationDecorationFill,
) -> RelationDecorationPrimitive {
  relation_decoration_primitive(DecorationPolygon(points), fill)
}

///|
fn relation_decoration_segment(
  start : (Double, Double),
  end : (Double, Double),
  stroke_width? : Double = DEFAULT_EXTREMITY_STROKE_WIDTH,
) -> RelationDecorationPrimitive {
  relation_decoration_primitive(
    DecorationSegment(start, end),
    NoDecorationFill,
    stroke_width~,
  )
}

///|
fn relation_decoration_circle(
  center : (Double, Double),
  radius : Double,
  fill : RelationDecorationFill,
  stroke_width? : Double = DEFAULT_EXTREMITY_STROKE_WIDTH,
) -> RelationDecorationPrimitive {
  relation_decoration_primitive(
    DecorationCircle(center, radius),
    fill,
    stroke_width~,
  )
}

///|
fn relation_decoration_geometry(
  primitives : Array[RelationDecorationPrimitive],
) -> RelationDecorationGeometry {
  { primitives, }
}

///|
fn relation_crowfoot_wing(
  point : (Double, Double),
  endpoint : (Double, Double),
  side : RelationContactSide?,
) -> (Double, Double) {
  match side {
    Some(ContactWest | ContactEast) => (endpoint.0, point.1)
    Some(ContactNorth | ContactSouth) => (point.0, endpoint.1)
    None => point
  }
}

///|
fn RelationEnd::decoration_length(self : RelationEnd) -> Double {
  match self {
    Plain => 0.0
    Arrow => ARROW_DECORATION_LENGTH
    Extension | Redefines | DefinedBy => TRIANGLE_DECORATION_LENGTH
    CompositionEnd | AggregationEnd => DIAMOND_DECORATION_LENGTH
    NotNavigable => NOT_NAVIGABLE_DECORATION_LENGTH
    Crowfoot | LineCrowfoot => CROWFOOT_DECORATION_LENGTH
    CircleCrowfoot => CIRCLE_CROWFOOT_DECORATION_LENGTH
    CircleLine => CIRCLE_LINE_DECORATION_LENGTH
    DoubleLine => CROWFOOT_DECORATION_LENGTH
    TriangleArrow => TRIANGLE_ARROW_DECORATION_LENGTH
    CircleEnd | FilledCircle => CIRCLE_DECORATION_LENGTH
    CircleConnect => CIRCLE_CONNECT_DECORATION_LENGTH
    Parenthesis => PARENTHESIS_DECORATION_LENGTH
    Square => SQUARE_DECORATION_LENGTH
    Plus => PLUS_DECORATION_LENGTH
    HalfArrowUp | HalfArrowDown => HALF_ARROW_DECORATION_LENGTH
  }
}

///|
fn RelationEnd::decoration_geometry(
  self : RelationEnd,
  endpoint : (Double, Double),
  adjacent : (Double, Double),
  side? : RelationContactSide? = None,
) -> RelationDecorationGeometry? {
  guard RelationDecorationFrame::new(endpoint, adjacent) is Some(frame) else {
    return None
  }
  let segment = (
    start_along : Double,
    start_normal : Double,
    end_along : Double,
    end_normal : Double,
  ) => {
    relation_decoration_segment(
      frame.point(start_along, start_normal),
      frame.point(end_along, end_normal),
    )
  }
  match self {
    Plain => None
    Arrow =>
      Some(
        relation_decoration_geometry([
          relation_decoration_polygon(
            [
              endpoint,
              frame.point(ARROW_WING_LENGTH, -ARROW_APERTURE),
              frame.point(ARROW_DECORATION_LENGTH, 0.0),
              frame.point(ARROW_WING_LENGTH, ARROW_APERTURE),
            ],
            LineDecorationFill,
          ),
        ]),
      )
    Extension =>
      Some(
        relation_decoration_geometry([
          relation_decoration_polygon(
            [
              endpoint,
              frame.point(TRIANGLE_DECORATION_LENGTH, -TRIANGLE_APERTURE),
              frame.point(TRIANGLE_DECORATION_LENGTH, TRIANGLE_APERTURE),
            ],
            BackgroundDecorationFill,
          ),
        ]),
      )
    Redefines | DefinedBy => {
      let primitives = [
        relation_decoration_polygon(
          [
            endpoint,
            frame.point(EXTENDS_LIKE_TRIANGLE_LENGTH, -EXTENDS_LIKE_HALF_WIDTH),
            frame.point(EXTENDS_LIKE_TRIANGLE_LENGTH, EXTENDS_LIKE_HALF_WIDTH),
          ],
          BackgroundDecorationFill,
        ),
      ]
      match self {
        Redefines =>
          primitives.push(
            relation_decoration_segment(
              frame.point(REDEFINES_BAR_LENGTH, -EXTENDS_LIKE_HALF_WIDTH),
              frame.point(REDEFINES_BAR_LENGTH, EXTENDS_LIKE_HALF_WIDTH),
              stroke_width=REDEFINES_BAR_STROKE_WIDTH,
            ),
          )
        DefinedBy => {
          primitives.push(
            relation_decoration_circle(
              frame.point(DEFINED_BY_DOT_LENGTH, -DEFINED_BY_DOT_NORMAL),
              DEFINED_BY_DOT_RADIUS,
              LineDecorationFill,
            ),
          )
          primitives.push(
            relation_decoration_circle(
              frame.point(DEFINED_BY_DOT_LENGTH, DEFINED_BY_DOT_NORMAL),
              DEFINED_BY_DOT_RADIUS,
              LineDecorationFill,
            ),
          )
        }
        _ => ()
      }
      Some(relation_decoration_geometry(primitives))
    }
    CompositionEnd | AggregationEnd =>
      Some(
        relation_decoration_geometry([
          relation_decoration_polygon(
            [
              endpoint,
              frame.point(DIAMOND_DECORATION_LENGTH / 2.0, -DIAMOND_APERTURE),
              frame.point(DIAMOND_DECORATION_LENGTH, 0.0),
              frame.point(DIAMOND_DECORATION_LENGTH / 2.0, DIAMOND_APERTURE),
            ],
            if self is CompositionEnd {
              LineDecorationFill
            } else {
              NoDecorationFill
            },
          ),
        ]),
      )
    Crowfoot => {
      let base = frame.point(CROWFOOT_DECORATION_LENGTH, 0.0)
      let left = relation_crowfoot_wing(
        frame.point(0.0, -CROWFOOT_APERTURE),
        endpoint,
        side,
      )
      let right = relation_crowfoot_wing(
        frame.point(0.0, CROWFOOT_APERTURE),
        endpoint,
        side,
      )
      Some(
        relation_decoration_geometry([
          relation_decoration_segment(base, left),
          relation_decoration_segment(base, right),
          relation_decoration_segment(base, endpoint),
        ]),
      )
    }
    CircleCrowfoot => {
      let base = frame.point(CROWFOOT_DECORATION_LENGTH, 0.0)
      Some(
        relation_decoration_geometry([
          relation_decoration_segment(
            base,
            frame.point(0.0, -CROWFOOT_COMPOSITE_APERTURE),
          ),
          relation_decoration_segment(
            base,
            frame.point(0.0, CROWFOOT_COMPOSITE_APERTURE),
          ),
          relation_decoration_segment(base, endpoint),
          relation_decoration_circle(
            frame.point(CIRCLE_CROWFOOT_CENTER_LENGTH, 0.0),
            CIRCLE_CROWFOOT_RADIUS,
            NoDecorationFill,
          ),
        ]),
      )
    }
    LineCrowfoot => {
      let base = frame.point(CROWFOOT_DECORATION_LENGTH, 0.0)
      Some(
        relation_decoration_geometry([
          relation_decoration_segment(
            base,
            frame.point(0.0, -CROWFOOT_COMPOSITE_APERTURE),
          ),
          relation_decoration_segment(
            base,
            frame.point(0.0, CROWFOOT_COMPOSITE_APERTURE),
          ),
          relation_decoration_segment(base, endpoint),
          segment(
            LINE_CROWFOOT_BAR_LENGTH,
            -END_LINE_HALF_HEIGHT,
            LINE_CROWFOOT_BAR_LENGTH,
            END_LINE_HALF_HEIGHT,
          ),
        ]),
      )
    }
    CircleLine =>
      Some(
        relation_decoration_geometry([
          segment(CIRCLE_LINE_CENTER_LENGTH, 0.0, 0.0, 0.0),
          relation_decoration_circle(
            frame.point(CIRCLE_LINE_CENTER_LENGTH, 0.0),
            CIRCLE_LINE_RADIUS,
            NoDecorationFill,
          ),
          segment(
            END_LINE_FIRST_LENGTH,
            -END_LINE_HALF_HEIGHT,
            END_LINE_FIRST_LENGTH,
            END_LINE_HALF_HEIGHT,
          ),
        ]),
      )
    DoubleLine =>
      Some(
        relation_decoration_geometry([
          segment(
            END_LINE_FIRST_LENGTH,
            -END_LINE_HALF_HEIGHT,
            END_LINE_FIRST_LENGTH,
            END_LINE_HALF_HEIGHT,
          ),
          segment(
            END_LINE_SECOND_LENGTH,
            -END_LINE_HALF_HEIGHT,
            END_LINE_SECOND_LENGTH,
            END_LINE_HALF_HEIGHT,
          ),
          segment(CROWFOOT_DECORATION_LENGTH, 0.0, 0.0, 0.0),
        ]),
      )
    NotNavigable =>
      Some(
        relation_decoration_geometry([
          segment(
            NOT_NAVIGABLE_NEAR_LENGTH,
            -NOT_NAVIGABLE_HALF_SIZE,
            NOT_NAVIGABLE_FAR_LENGTH,
            NOT_NAVIGABLE_HALF_SIZE,
          ),
          segment(
            NOT_NAVIGABLE_NEAR_LENGTH,
            NOT_NAVIGABLE_HALF_SIZE,
            NOT_NAVIGABLE_FAR_LENGTH,
            -NOT_NAVIGABLE_HALF_SIZE,
          ),
        ]),
      )
    TriangleArrow =>
      Some(
        relation_decoration_geometry([
          relation_decoration_polygon(
            [
              endpoint,
              frame.point(
                TRIANGLE_ARROW_DECORATION_LENGTH,
                -TRIANGLE_ARROW_APERTURE,
              ),
              frame.point(
                TRIANGLE_ARROW_DECORATION_LENGTH,
                TRIANGLE_ARROW_APERTURE,
              ),
            ],
            LineDecorationFill,
          ),
        ]),
      )
    CircleEnd | FilledCircle =>
      Some(
        relation_decoration_geometry([
          relation_decoration_circle(
            frame.point(CIRCLE_RADIUS, 0.0),
            CIRCLE_RADIUS,
            if self is FilledCircle {
              LineDecorationFill
            } else {
              BackgroundDecorationFill
            },
            stroke_width=EMPHASIZED_EXTREMITY_STROKE_WIDTH,
          ),
        ]),
      )
    CircleConnect =>
      Some(
        relation_decoration_geometry([
          relation_decoration_circle(
            endpoint,
            CIRCLE_RADIUS,
            BackgroundDecorationFill,
            stroke_width=EMPHASIZED_EXTREMITY_STROKE_WIDTH,
          ),
          relation_decoration_primitive(
            DecorationArc(
              frame.arc(CIRCLE_CONNECT_ARC_RADIUS, CIRCLE_CONNECT_HALF_ANGLE),
            ),
            BackgroundDecorationFill,
            stroke_width=EMPHASIZED_EXTREMITY_STROKE_WIDTH,
          ),
        ]),
      )
    Parenthesis =>
      Some(
        relation_decoration_geometry([
          relation_decoration_primitive(
            DecorationArc(frame.arc(PARENTHESIS_RADIUS, PARENTHESIS_HALF_ANGLE)),
            NoDecorationFill,
            stroke_width=EMPHASIZED_EXTREMITY_STROKE_WIDTH,
          ),
        ]),
      )
    Square =>
      Some(
        relation_decoration_geometry([
          relation_decoration_primitive(
            DecorationSquare(endpoint, SQUARE_RADIUS),
            BackgroundDecorationFill,
            stroke_width=EMPHASIZED_EXTREMITY_STROKE_WIDTH,
          ),
        ]),
      )
    Plus => {
      let center = frame.point(PLUS_RADIUS, 0.0)
      Some(
        relation_decoration_geometry([
          relation_decoration_circle(
            center,
            PLUS_RADIUS,
            BackgroundDecorationFill,
          ),
          relation_decoration_segment(
            frame.point(0.0, 0.0),
            frame.point(PLUS_DECORATION_LENGTH, 0.0),
          ),
          relation_decoration_segment(
            frame.point(PLUS_RADIUS, -PLUS_RADIUS),
            frame.point(PLUS_RADIUS, PLUS_RADIUS),
          ),
        ]),
      )
    }
    HalfArrowUp | HalfArrowDown => {
      let normal = if self is HalfArrowUp {
        -ARROW_APERTURE
      } else {
        ARROW_APERTURE
      }
      Some(
        relation_decoration_geometry([
          relation_decoration_segment(
            endpoint,
            frame.point(ARROW_WING_LENGTH, normal),
          ),
          relation_decoration_segment(
            endpoint,
            frame.point(HALF_ARROW_DECORATION_LENGTH, 0.0),
          ),
        ]),
      )
    }
  }
}
