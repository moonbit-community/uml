///|
/// ScaleProtected bounds the user scale before TextBlockExporter applies DPI.
const MAX_DIAGRAM_SCALE : Double = 4.0

///|
const DIAGRAM_DEFAULT_DPI : Int = 96

///|
enum ScaleDimension {
  Factor(Double)
  Width(Double)
  Height(Double)
  Fit(Double, Double)
}

///|
/// A validated PlantUML scale command, resolved against the final image size.
pub struct DiagramScale {
  dimension : ScaleDimension
  shrink_only : Bool
}

///|
fn scale_number(cursor : @tokenizer.Cursor) -> Double? {
  let token = cursor.take_while(char => char is ('0'..='9' | '.'))
  Some(@string.parse_double(token)) catch {
    _ => None
  }
}

///|
/// Parse the body of CommandScale, CommandScaleWidthOrHeight, and their
/// bounded variants. A zero factor/divisor is invalid; zero size constraints
/// remain valid and are handled by ScaleProtected when resolving the factor.
pub fn parse_diagram_scale(value : String) -> DiagramScale? {
  let cursor = @tokenizer.Cursor::new(value.trim().to_owned().to_lower())
  let shrink_only = cursor.consume_literal("max")
  guard !shrink_only || cursor.skip_inline_space1() else { return None }
  guard scale_number(cursor) is Some(first) else { return None }
  let space = cursor.skip_inline_whitespace()
  let dimension = if cursor.is_eof() {
    guard !shrink_only && first > 0.0 else { return None }
    Factor(first)
  } else if cursor.consume('/') {
    guard !shrink_only && first > 0.0 else { return None }
    cursor.skip_inline_spaces()
    guard scale_number(cursor) is Some(divisor) && divisor > 0.0 else {
      return None
    }
    Factor(first / divisor)
  } else if cursor.consume('*') || cursor.consume('x') {
    cursor.skip_inline_spaces()
    guard scale_number(cursor) is Some(height) else { return None }
    Fit(first, height)
  } else {
    guard space > 0 else { return None }
    if cursor.consume_literal("width") {
      Width(first)
    } else if cursor.consume_literal("height") {
      Height(first)
    } else {
      return None
    }
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else { return None }
  Some({ dimension, shrink_only, })
}

///|
/// Preserve aspect ratio, optionally avoid enlargement, then apply the
/// common nonpositive fallback and enlargement limit from ScaleProtected.
/// Previously verified: equivalent ratios, aspect-preserving constraints,
/// max-only shrinking and scale protection before DPI multiplication.
pub fn DiagramScale::factor(
  self : DiagramScale,
  width : Double,
  height : Double,
) -> Double {
  let factor = match self.dimension {
    Factor(value) => value
    Width(value) => value / width
    Height(value) => value / height
    Fit(w, h) => (w / width).min(h / height)
  }
  guard factor > 0.0 else { return 1.0 }
  factor.min(if self.shrink_only { 1.0 } else { MAX_DIAGRAM_SCALE })
}

///|
/// SkinParam.getDpi accepts a positive decimal integer, falling back to its
/// default otherwise. DPI multiplies the protected scale without another cap.
pub fn DocumentStyle::output_scale(
  self : DocumentStyle,
  width : Double,
  height : Double,
) -> Double {
  let scale = self.scale
    .bind(parse_diagram_scale)
    .map_or(1.0, scale => scale.factor(width, height))
  let dpi = self
    .property("dpi")
    .map_or(DIAGRAM_DEFAULT_DPI, value => {
      guard !value.is_empty() && value.iter().all(char => char is ('0'..='9')) else {
        return DIAGRAM_DEFAULT_DPI
      }
      let dpi = @string.parse_int(value) catch {
        _ => return DIAGRAM_DEFAULT_DPI
      }
      if dpi > 0 {
        dpi
      } else {
        DIAGRAM_DEFAULT_DPI
      }
    })
  scale * dpi.to_double() / DIAGRAM_DEFAULT_DPI.to_double()
}
