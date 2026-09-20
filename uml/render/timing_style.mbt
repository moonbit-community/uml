///|
/// TimingDiagram, TimingRuler, Panels and PlayerFrame geometry constants.
const TIMING_MARGIN : Double = 10.0

///|
const TIMING_SIDE : Double = 5.0

///|
const TIMING_TICK_PIXELS : Double = 50.0

///|
const TIMING_MAX_AUTO_WIDTH : Double = 4000.0

///|
const TIMING_MAX_TICKS : Int = 1000

///|
const TIMING_TICK_HEIGHT : Double = 5.0

///|
const TIMING_MARGIN_Y : Double = 8.0

///|
const TIMING_MARGIN_X : Double = 12.0

///|
const TIMING_BOTTOM : Double = 10.0

///|
const TIMING_RIBBON_HEIGHT : Double = 24.0

///|
const TIMING_BINARY_HEIGHT : Double = 30.0

///|
const TIMING_ANALOG_HEIGHT : Double = 100.0

///|
const TIMING_ROBUST_STEP : Double = 20.0

///|
const TIMING_ROBUST_INITIAL : Double = 40.0

///|
const TIMING_ROBUST_BOTTOM : Double = 18.0

///|
const TIMING_CONSTRAINT_MARGIN : Double = 5.0

///|
const TIMING_CONSTRAINT_INSET : Double = 2.5

///|
const TIMING_HATCH_STEP : Double = 5.0

///|
const TIMING_FRAME_CORNER : Double = 10.0

///|
const TIMING_ARROW_LENGTH : Double = 8.0

///|
const TIMING_ARROW_HALF_HEIGHT : Double = 4.0

///|
const TIMING_ARROW_ANGLE : Double = 0.3490658503988659

///|
const TIMING_NOTE_MARGIN : Double = 10.0

///|
fn timing_kind(kind : @flow.PlayerKind) -> String {
  match kind {
    Robust => "robust"
    Concise => "concise"
    Rectangle => "rectangle"
    Binary => "binary"
    Clock => "clock"
    Analog => "analog"
  }
}

///|
priv struct TimingAppearance {
  metrics : @metrics.FontMetrics
  family : String
  color : String
  line : String
  fill : String
  thickness : Double
}

///|
fn timing_number(value : String, fallback : Double) -> Double {
  let number = @string.parse_double(value) catch { _ => return fallback }
  if number.is_nan() || number.is_inf() {
    fallback
  } else {
    number
  }
}

///|
fn timing_appearance(
  style : @style.DocumentStyle,
  role : String,
) -> TimingAppearance {
  let (size, weight, line, text, fill, thickness) = match role {
    "robust" | "binary" => (12, 400, "DarkGreen", "#333333", "#E2E2F0", 2.0)
    "concise" => (12, 700, "DarkGreen", "#333333", "#E2E2F0", 1.5)
    "clock" => (14, 700, "DarkGreen", "#333333", "#F1F1F1", 1.5)
    "timeline" => (11, 400, "#333333", "#333333", "none", 2.0)
    "arrow" => (14, 400, "DarkBlue", "DarkBlue", "none", 1.5)
    "constraintArrow" => (12, 400, "DarkRed", "DarkRed", "none", 1.5)
    "note" => (14, 700, "#333333", "#333333", "#FEFFDD", 0.5)
    "highlight" => (14, 700, "#333333", "#333333", "#EEEEEE", 2.0)
    _ => (14, 700, "#333333", "#333333", "#F1F1F1", 0.5)
  }
  let prefix = "timing" + role
  let custom_scheme = style.color_scheme != @style.ColorScheme::default()
  let scheme = style.defaults()
  let text = if custom_scheme { scheme.text } else { text }
  let line = if custom_scheme { scheme.line } else { line }
  let fill = if custom_scheme && fill != "none" {
    if role == "note" {
      scheme.note
    } else {
      scheme.node
    }
  } else {
    fill
  }
  let font_size = style.property_font_size(prefix + "FontSize", fallback=size)
  let family = style
    .property(prefix + "FontName")
    .unwrap_or(if role == "arrow" { "serif" } else { style.font_family() })
  let weight = style
    .property(prefix + "FontStyle")
    .map_or(weight, value => {
      if value.to_lower().contains("bold") {
        700
      } else {
        400
      }
    })
  {
    metrics: style.font_metrics_for(family, font_size~, font_weight=weight),
    family,
    color: style.property_color(prefix + "FontColor", text),
    line: style.property_color(prefix + "LineColor", line),
    fill: style.property_color(prefix + "BackgroundColor", fill),
    thickness: style
    .property(prefix + "LineThickness")
    .map_or(thickness, value => timing_number(value, thickness)),
  }
}

///|
fn TimingAppearance::paint(
  self : TimingAppearance,
  fill? : Bool = false,
) -> @graphics.DrawingStyle {
  {
    ..Default::default(),
    stroke: Color(self.line),
    fill: if fill {
      Color(self.fill)
    } else {
      None
    },
    stroke_width: Some(self.thickness),
  }
}

///|
fn timing_color_part(
  value : String?,
  part : String,
  fallback : String,
) -> String {
  guard value is Some(value) else { return fallback }
  let tokens = value.split(";").to_array()
  let base = if part == "back" { tokens[0].to_owned() } else { fallback }
  @svg.svg_color(
    Some(
      tokens.fold(init=base, (result, token) => {
        if token.has_prefix(part + ":") {
          token[part.length() + 1:].to_owned()
        } else {
          result
        }
      }),
    ),
    fallback,
  )
}
