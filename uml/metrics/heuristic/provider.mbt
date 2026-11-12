///|
#derive(Eq)
priv enum FontProfile {
  Sans
  Serif
  Monospace
}

///|
priv struct Font {
  spec : @metrics.FontSpec
  profile : FontProfile
}

///|
const REFERENCE_FONT_SIZE : Int32 = 13

///|
fn profile_for(family : String) -> FontProfile {
  let family = family.to_lower()
  match () {
    _ if family.contains("mono") ||
      family.contains("courier") ||
      family.contains("consolas") ||
      family.contains("menlo") => Monospace
    _ if !family.contains("sans") &&
      (
        family.contains("serif") ||
        family.contains("times") ||
        family.contains("georgia")
      ) => Serif
    _ => Sans
  }
}

///|
pub fn measurer() -> @metrics.Measurer {
  @metrics.Measurer::new((spec, text) => {
    let font = { spec, profile: profile_for(spec.font_family), }
    font.measure(text)
  })
}
