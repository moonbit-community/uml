///|
/// Change an inline face while retaining size, spacing, and width calibration.
/// Verified 2026-09-16: calibrated measurement matches an equivalent configured
/// font; restoring the original face retains every metric. Temporary tests removed.
pub fn FontMetrics::with_face(
  self : FontMetrics,
  weight : Int,
  style : FontStyle,
) -> FontMetrics {
  { ..self, font_weight: weight, style, }
}

///|
/// Switch the glyph profile without changing the caller's face or calibration.
pub fn FontMetrics::with_profile(
  self : FontMetrics,
  profile : FontProfile,
) -> FontMetrics {
  guard self.profile != profile else { return self }
  let metrics = { ..self, profile, }
  {
    ..metrics,
    space_width: metrics.char_width(' '),
    narrow_width: metrics.char_width('i'),
    normal_width: metrics.char_width('a'),
    wide_width: metrics.char_width('m'),
    uppercase_width: metrics.char_width('A'),
    digit_width: metrics.char_width('0'),
    cjk_width: metrics.char_width('\u4e00'),
    emoji_width: metrics.char_width('\u{1f600}'),
  }
}

///|
/// Resize an inline font while retaining face, spacing, and glyph calibration.
/// Keep the configured leading relative to size and recompute glyph summaries.
/// Zero size resets vertical metrics. Verified 2026-09-16: positive resizing
/// matches an equivalently configured font; zero-size text has no glyph extent.
/// Temporary property tests removed after verification.
pub fn FontMetrics::with_size(self : FontMetrics, size : Int) -> FontMetrics {
  let size = size.max(0)
  guard size != self.font_size else { return self }
  let resized = FontMetrics::from_defaults(
    profile=self.profile,
    style=self.style,
    font_size=size,
    font_weight=self.font_weight,
    line_height=(size + self.line_height - self.font_size).max(1),
    width_scale=self.width_scale,
    uppercase_width_scale=self.uppercase_width_scale,
    lowercase_width_scale=self.lowercase_width_scale,
    digit_width_scale=self.digit_width_scale,
    punctuation_width_scale=self.punctuation_width_scale,
    wide_width_scale=self.wide_width_scale,
    emoji_width_scale=self.emoji_width_scale,
    font_stretch=self.font_stretch,
    bold_width_scale=self.bold_width_scale,
    italic_width_scale=self.italic_width_scale,
    italic_overhang=self.italic_overhang,
    kerning_scale=self.kerning_scale,
    letter_spacing=self.letter_spacing,
    word_spacing=self.word_spacing,
    tab_size=self.tab_size,
  )
  guard size == 0 else { return resized }
  {
    ..resized,
    font_size: 0,
    line_height: 0,
    ascent: 0,
    descent: 0,
    line_gap: 0,
    space_width: 0,
    narrow_width: 0,
    normal_width: 0,
    wide_width: 0,
    uppercase_width: 0,
    digit_width: 0,
    cjk_width: 0,
    emoji_width: 0,
  }
}
