///|
/// Portable text measurement used by the built-in SVG renderers.
pub struct TextMetrics {
  width : Int
  advance_width : Int
  height : Int
  ascent : Int
  descent : Int
  baseline : Int
  ink_left : Int
  ink_right : Int
} derive(Eq, Debug)

///|
pub extend TextMetrics with Eq::{not_equal, equal}

///|
pub extend TextMetrics with Debug::{to_repr}

///|
/// A copy whose advance is widened by `extra` pixels, for renderers that
/// compensate the built-in width table (e.g. the mindmap's space advance).
pub fn TextMetrics::with_extra_advance(
  self : TextMetrics,
  extra : Int,
) -> TextMetrics {
  {
    ..self,
    width: self.width + extra,
    advance_width: self.advance_width + extra,
  }
}

///|
/// Coarse built-in width profiles for deterministic cross-platform layout.
pub(all) enum FontProfile {
  Sans
  Serif
  Monospace
} derive(Eq, Debug)

///|
pub extend FontProfile with Eq::{not_equal, equal}

///|
pub extend FontProfile with Debug::{to_repr}

///|
pub(all) enum FontStyle {
  Normal
  Italic
} derive(Eq, Debug)

///|
pub extend FontStyle with Eq::{not_equal, equal}

///|
pub extend FontStyle with Debug::{to_repr}

///|
/// Configurable, deterministic font metrics for SVG layout.
///
/// Glyph advances are accumulated internally at 1/1000px precision. The
/// public width fields are rounded pixel summaries retained for callers that
/// inspect individual character classes.
pub struct FontMetrics {
  profile : FontProfile
  style : FontStyle
  font_size : Int
  font_weight : Int
  line_height : Int
  ascent : Int
  descent : Int
  line_gap : Int
  letter_spacing : Int
  word_spacing : Int
  tab_size : Int
  kerning_scale : Int
  font_stretch : Int
  italic_width_scale : Int
  italic_overhang : Int
  width_scale : Int
  uppercase_width_scale : Int
  lowercase_width_scale : Int
  digit_width_scale : Int
  punctuation_width_scale : Int
  wide_width_scale : Int
  emoji_width_scale : Int
  bold_width_scale : Int
  space_width : Int
  narrow_width : Int
  normal_width : Int
  wide_width : Int
  uppercase_width : Int
  digit_width : Int
  cjk_width : Int
  emoji_width : Int
} derive(Eq, Debug)

///|
pub extend FontMetrics with Eq::{not_equal, equal}

///|
pub extend FontMetrics with Debug::{to_repr}

///|
pub impl Default for FontMetrics with fn default() -> FontMetrics {
  FontMetrics::from_defaults()
}

///|
pub extend FontMetrics with Default::{default}

///|
/// Creates deterministic metrics from one of the built-in profiles.
/// Percentage parameters use 100 as their neutral value.
pub fn FontMetrics::from_defaults(
  profile? : FontProfile = Sans,
  style? : FontStyle = Normal,
  font_size? : Int = 13,
  font_weight? : Int = 400,
  line_height? : Int = 0,
  ascent? : Int = 0,
  descent? : Int = 0,
  line_gap? : Int = 0,
  width_scale? : Int = 100,
  uppercase_width_scale? : Int = 100,
  lowercase_width_scale? : Int = 100,
  digit_width_scale? : Int = 100,
  punctuation_width_scale? : Int = 100,
  wide_width_scale? : Int = 100,
  emoji_width_scale? : Int = 100,
  font_stretch? : Int = 100,
  bold_width_scale? : Int = 110,
  italic_width_scale? : Int = 103,
  italic_overhang? : Int = 1,
  kerning_scale? : Int = 100,
  letter_spacing? : Int = 0,
  word_spacing? : Int = 0,
  tab_size? : Int = 4,
) -> FontMetrics {
  let font_size = font_size.max(1)
  let ascent = if ascent > 0 { ascent } else { font_size * 10 / 13 }
  let descent = if descent > 0 { descent } else { font_size * 3 / 13 }
  let line_gap = if line_gap > 0 { line_gap } else { font_size * 2 / 13 }
  let line_height = {
    guard line_height > 0 else { ascent + descent + line_gap }
    line_height
  }
  let metrics = {
    profile,
    style,
    font_size,
    font_weight,
    line_height,
    ascent,
    descent,
    line_gap,
    letter_spacing,
    word_spacing,
    tab_size: tab_size.max(1),
    kerning_scale,
    font_stretch,
    italic_width_scale,
    italic_overhang,
    width_scale,
    uppercase_width_scale,
    lowercase_width_scale,
    digit_width_scale,
    punctuation_width_scale,
    wide_width_scale,
    emoji_width_scale,
    bold_width_scale,
    space_width: 0,
    narrow_width: 0,
    normal_width: 0,
    wide_width: 0,
    uppercase_width: 0,
    digit_width: 0,
    cjk_width: 0,
    emoji_width: 0,
  }
  {
    ..metrics,
    space_width: metrics.char_advance(' ').ceil_pixels(),
    narrow_width: metrics.char_advance('i').ceil_pixels(),
    normal_width: metrics.char_advance('a').ceil_pixels(),
    wide_width: metrics.char_advance('m').ceil_pixels(),
    uppercase_width: metrics.char_advance('A').ceil_pixels(),
    digit_width: metrics.char_advance('0').ceil_pixels(),
    cjk_width: metrics.char_advance('\u{4e00}').ceil_pixels(),
    emoji_width: metrics.char_advance('\u{1f600}').ceil_pixels(),
  }
}
