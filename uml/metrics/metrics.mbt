///|
pub const DEFAULT_FONT_FAMILY : String = "Arial, sans-serif"

///|
#derive(Eq, Debug)
pub(all) enum FontStyle {
  Normal
  Italic
}

///|
pub extend FontStyle with Eq::{not_equal, equal}

///|
pub extend FontStyle with Debug::{to_repr}

///|
/// Font families use CSS family-list syntax; all dimensions use CSS pixels.
/// Leading and tab stops are supplied by layout, not inferred from glyph ink.
#derive(Eq, Debug)
pub(all) struct FontSpec {
  font_family : String
  style : FontStyle
  font_size : Int32
  font_weight : Int32
  line_height : Int32
  tab_size : Int32
}

///|
pub extend FontSpec with Eq::{not_equal, equal}

///|
pub extend FontSpec with Debug::{to_repr}

///|
/// Advances retain subpixel precision. Integer extents are rounded out only
/// at the boundary to the renderers' pixel-based box layout.
#derive(Eq, Debug)
pub(all) struct TextMetrics {
  width : Int32
  advance_width : Double
  height : Int32
  ascent : Int32
  descent : Int32
  baseline : Int32
  ink_left : Double
  ink_right : Double
}

///|
pub extend TextMetrics with Eq::{not_equal, equal}

///|
pub extend TextMetrics with Debug::{to_repr}

///|
/// An instance-owned measurement service. Neither the common package nor the
/// renderer selects a platform backend or substitutes one after a failure.
pub struct Measurer {
  priv measure_text : (FontSpec, String) -> TextMetrics
}

///|
/// The callback measures nonzero-size text, including newlines and tab stops.
/// Empty text supplies font-level bounds for resolving a stable baseline.
pub fn Measurer::new(measure : (FontSpec, String) -> TextMetrics) -> Measurer {
  { measure_text: measure, }
}

///|
pub fn Measurer::measure(
  self : Measurer,
  font : FontSpec,
  text : String,
) -> TextMetrics {
  guard font.font_size > 0 else {
    return {
      width: 0,
      advance_width: 0.0,
      height: 0,
      ascent: 0,
      descent: 0,
      baseline: 0,
      ink_left: 0.0,
      ink_right: 0.0,
    }
  }
  (self.measure_text)(font, text)
}

///|
pub impl Debug for Measurer with fn to_repr(_self : Measurer) -> @debug.Repr {
  Debug::to_repr("Measurer")
}

///|
pub extend Measurer with Debug::{to_repr}

///|
/// A resolved font bound to the measurement service of one rendering task.
/// Face, family and size changes retain that service and recompute font bounds.
#derive(Debug)
pub struct FontMetrics {
  font_family : String
  style : FontStyle
  font_size : Int32
  font_weight : Int32
  line_height : Int32
  ascent : Int32
  descent : Int32
  tab_size : Int32
  priv measurer : Measurer
}

///|
pub extend FontMetrics with Debug::{to_repr}

///|
pub fn FontMetrics::from_defaults(
  measurer : Measurer,
  font_family~ : String = DEFAULT_FONT_FAMILY,
  style~ : FontStyle = Normal,
  font_size~ : Int32 = 13,
  font_weight~ : Int32 = 400,
  line_height~ : Int32 = 0,
  tab_size~ : Int32 = 4,
) -> FontMetrics {
  let font_size = font_size.max(0)
  let spec : FontSpec = {
    font_family,
    style,
    font_size,
    font_weight,
    line_height: if font_size == 0 {
      0
    } else if line_height > 0 {
      line_height
    } else {
      font_size + 2
    },
    tab_size: tab_size.max(1),
  }
  let bounds = measurer.measure(spec, "")
  {
    font_family,
    style,
    font_size,
    font_weight,
    line_height: spec.line_height,
    ascent: bounds.ascent,
    descent: bounds.descent,
    tab_size: spec.tab_size,
    measurer,
  }
}

///|
pub fn FontMetrics::measure(self : FontMetrics, text : String) -> TextMetrics {
  self.measurer.measure(
    {
      font_family: self.font_family,
      style: self.style,
      font_size: self.font_size,
      font_weight: self.font_weight,
      line_height: self.line_height,
      tab_size: self.tab_size,
    },
    text,
  )
}

///|
pub fn FontMetrics::with_face(
  self : FontMetrics,
  weight : Int32,
  style : FontStyle,
) -> FontMetrics {
  FontMetrics::from_defaults(
    self.measurer,
    font_family=self.font_family,
    font_size=self.font_size,
    font_weight=weight,
    style~,
    line_height=self.line_height,
    tab_size=self.tab_size,
  )
}

///|
pub fn FontMetrics::with_family(
  self : FontMetrics,
  family : String,
) -> FontMetrics {
  FontMetrics::from_defaults(
    self.measurer,
    font_family=family,
    font_size=self.font_size,
    font_weight=self.font_weight,
    style=self.style,
    line_height=self.line_height,
    tab_size=self.tab_size,
  )
}

///|
pub fn FontMetrics::with_size(self : FontMetrics, size : Int32) -> FontMetrics {
  FontMetrics::from_defaults(
    self.measurer,
    font_family=self.font_family,
    font_size=size,
    font_weight=self.font_weight,
    style=self.style,
    line_height=(size + self.line_height - self.font_size).max(1),
    tab_size=self.tab_size,
  )
}
