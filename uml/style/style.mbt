///|
/// Common PlantUML document-level style state.
///
/// This type preserves document directives and offers generic property, color,
/// and font resolution. Diagram-family role mapping belongs to the relevant
/// painter; `ColorScheme` is stored here only as the selected cross-diagram
/// theme.
pub struct DocumentStyle {
  mut background_color : String?
  mut theme : String?
  mut font_family : String?
  mut font_size : String?
  mut line_color : String?
  mut layout_direction : Direction?
  mut scale : String?
  mut title : String?
  mut caption : String?
  mut legend : String?
  mut header : String?
  mut footer : String?
  color_scheme : ColorScheme
  properties : Map[String, String]
} derive(Eq, Debug)

///|
pub extend DocumentStyle with Eq::{not_equal, equal}

///|
pub extend DocumentStyle with Debug::{to_repr}

///|
pub(all) enum Direction {
  TopToBottom
  LeftToRight
} derive(Eq, Debug)

///|
pub extend Direction with Eq::{not_equal, equal}

///|
pub extend Direction with Debug::{to_repr}

///|
pub(all) enum StyleDirective {
  BackgroundColor(String)
  Theme(String)
  FontFamily(String)
  FontSize(String)
  LineColor(String)
  TextBlock(String, String)
  Direction(Direction)
  Scale(String)
  Title(String)
  Property(String, String)
} derive(Eq, Debug)

///|
pub extend StyleDirective with Eq::{not_equal, equal}

///|
pub extend StyleDirective with Debug::{to_repr}

///|
pub fn DocumentStyle::empty() -> DocumentStyle {
  {
    background_color: None,
    theme: None,
    font_family: None,
    font_size: None,
    line_color: None,
    layout_direction: None,
    scale: None,
    title: None,
    caption: None,
    legend: None,
    header: None,
    footer: None,
    color_scheme: ColorScheme::default(),
    properties: Map([]),
  }
}

///|
/// Returns a copy of the style using the selected cross-diagram theme.
pub fn DocumentStyle::with_color_scheme(
  self : DocumentStyle,
  scheme : ColorScheme,
) -> DocumentStyle {
  { ..self, color_scheme: scheme, }
}

///|
/// The effective cross-diagram theme selected for this document.
///
/// Renderers should project family-specific roles with `sequence_colors` or
/// `entity_colors` before painting.
pub fn DocumentStyle::defaults(self : DocumentStyle) -> ColorScheme {
  self.color_scheme
}

///|
pub fn DocumentStyle::apply(
  self : DocumentStyle,
  directive : StyleDirective,
) -> Unit {
  match directive {
    BackgroundColor(color) => self.background_color = Some(color)
    Theme(theme) => self.theme = Some(theme)
    FontFamily(family) => self.font_family = Some(family)
    FontSize(size) => self.font_size = Some(size)
    LineColor(color) => self.line_color = Some(color)
    TextBlock(kind, text) =>
      match kind {
        "title" => self.title = Some(text)
        "caption" => self.caption = Some(text)
        "legend" => self.legend = Some(text)
        "header" => self.header = Some(text)
        "footer" => self.footer = Some(text)
        _ => ()
      }
    Direction(dir) => self.layout_direction = Some(dir)
    Scale(s) => self.scale = Some(s)
    Title(t) => self.title = Some(t)
    Property(key, value) => self.properties[key] = value
  }
}

///|
/// Returns the value of a preserved skinparam-style property.
pub fn DocumentStyle::property(self : DocumentStyle, key : String) -> String? {
  match self.properties.get(key) {
    Some(value) => Some(value)
    None => {
      let entries = self.properties.iter()
      let mut matching = None
      while entries.next() is Some((stored_key, value)) {
        if stored_key.equal_ignore_ascii_case(key) {
          matching = Some(value)
        }
      }
      matching
    }
  }
}

///|
pub fn DocumentStyle::canvas_color(self : DocumentStyle) -> String {
  @svg.svg_color(self.background_color, self.defaults().canvas)
}

///|
pub fn DocumentStyle::diagram_line_color(self : DocumentStyle) -> String {
  @svg.svg_color(self.line_color, self.defaults().line)
}

///|
/// Resolves a skinparam color property with a shared fallback.
pub fn DocumentStyle::property_color(
  self : DocumentStyle,
  key : String,
  fallback : String,
) -> String {
  @svg.svg_color(self.property(key), fallback)
}

///|
pub fn DocumentStyle::diagram_text_color(self : DocumentStyle) -> String {
  @svg.svg_color(self.property("FontColor"), self.defaults().text)
}

///|
/// Resolves a skinparam font color property, falling back to diagram text.
pub fn DocumentStyle::property_font_color(
  self : DocumentStyle,
  key : String,
) -> String {
  self.property_color(key, self.diagram_text_color())
}

///|
/// Resolves a skinparam font size property with a fallback.
pub fn DocumentStyle::property_font_size(
  self : DocumentStyle,
  key : String,
  fallback~ : Int,
) -> Int {
  guard self.property(key) is Some(value) else { return fallback }
  parse_font_size(value, fallback~)
}

///|
/// Resolves a skinparam font family property, falling back to the document
/// font family.
pub fn DocumentStyle::property_font_family(
  self : DocumentStyle,
  key : String,
) -> String {
  self.property(key).unwrap_or(self.font_family())
}

///|
const SKINPARAM_PREFIX : String = "skinparam "

///|
const SCALE_PREFIX : String = "scale "

///|
pub fn parse_style_directive(line : String) -> StyleDirective? {
  let trimmed = line.trim()
  if trimmed.to_lower().has_prefix(SKINPARAM_PREFIX) {
    return parse_style_property(
      trimmed[SKINPARAM_PREFIX.length():].trim().to_owned(),
    )
  }
  let lower = trimmed.to_lower()
  if lower == "left to right direction" {
    return Some(Direction(LeftToRight))
  }
  if lower == "top to bottom direction" {
    return Some(Direction(TopToBottom))
  }
  if lower == "hide empty description" || lower == "show empty description" {
    return Some(
      Property(
        "hide empty description",
        {
          guard lower == "hide empty description" else { "false" }
          "true"
        },
      ),
    )
  }
  if lower.has_prefix("set namespace_separator ") ||
    lower.has_prefix("set namespaceseparator ") {
    return Some(
      Property(
        "namespace separator",
        @parse.syntax_words(trimmed.to_owned()).last().unwrap_or(""),
      ),
    )
  }
  if lower == "footbox" ||
    lower == "newpage" ||
    lower.has_prefix("newpage ") ||
    lower == "layout newline" {
    return Some(Property(lower.to_owned(), "true"))
  }
  if lower.has_prefix(SCALE_PREFIX) {
    return Some(Scale(trimmed[SCALE_PREFIX.length():].trim().to_owned()))
  }
  if lower == "rotate" ||
    lower.has_prefix("skin ") ||
    lower.has_prefix("minwidth ") ||
    lower.has_prefix("page ") ||
    lower.has_prefix("mainframe ") ||
    lower.has_prefix("mainframe:") ||
    (lower.has_prefix("sprite ") && !lower.has_suffix("{")) ||
    (lower.has_prefix("<style") && lower.has_suffix(">") && lower != "<style>") {
    return Some(Property(lower.to_owned(), "true"))
  }
  for kind in ["title", "caption", "legend", "header", "footer"] {
    if lower.has_prefix(kind + ":") || lower.has_prefix(kind + " ") {
      let value = trimmed[kind.length():].trim_start(chars=": ").to_owned()
      if kind == "legend" &&
        !lower.has_prefix("legend:") &&
        value
        .split(" ")
        .all(word => {
          let word = word.trim().to_lower()
          word == "top" ||
          word == "bottom" ||
          word == "left" ||
          word == "right" ||
          word == "center"
        }) {
        return None
      }
      return Some(TextBlock(kind, value))
    }
  }
  let words = trimmed
    .split(" ")
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  if words.length() >= 3 &&
    (words[0] == "left" || words[0] == "right" || words[0] == "center") &&
    (words[1] == "header" || words[1] == "footer") {
    return Some(TextBlock(words[1], words[2:].to_owned().join(" ")))
  }
  match words {
    ["!theme", theme, ..] => Some(Theme(theme))
    ["left", "to", "right", ..] => Some(Direction(LeftToRight))
    ["scale", value, ..] => Some(Scale(value))
    _ => None
  }
}

///|
/// Parse a property inside a `skinparam { ... }` block.
pub fn parse_style_property(line : String) -> StyleDirective? {
  let words = line
    .trim()
    .split(" ")
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  if words.length() >= 2 && words[0].equal_ignore_ascii_case("DefaultFontName") {
    return Some(FontFamily(words[1:].to_owned().join(" ")))
  }
  if words.length() >= 2 && words[0].to_lower().has_suffix("fontname") {
    return Some(Property(words[0], words[1:].to_owned().join(" ")))
  }
  match words {
    [key, color, ..] if key.equal_ignore_ascii_case("BackgroundColor") =>
      Some(BackgroundColor(color))
    [key, size, ..] if key.equal_ignore_ascii_case("DefaultFontSize") =>
      Some(FontSize(size))
    [key, color, ..] if key.equal_ignore_ascii_case("ArrowColor") =>
      Some(LineColor(color))
    [key, value, ..] => Some(Property(key, value))
    _ => None
  }
}

///|
/// Consume the body of a `skinparam { ... }` block, applying each property
/// directive. `next_line` yields the next stripped line or `None` at end of
/// input. Returns whether the block was closed with `}`.
pub fn consume_skinparam_body(
  next_line : () -> String?,
  apply : (StyleDirective) -> Unit,
) -> Bool {
  @parse.consume_lines_until(next_line, line => line.trim() == "}", line => {
    guard parse_style_property(line) is Some(directive) else { return }
    apply(directive)
  })
}

///|
pub fn DocumentStyle::font_family(self : DocumentStyle) -> String {
  self.font_family.unwrap_or("Arial, sans-serif")
}

///|
pub fn DocumentStyle::font_size(self : DocumentStyle) -> String {
  match self.font_size {
    Some(size) if size.has_suffix("px") || size.has_suffix("pt") => size
    Some(size) => "\{size}px"
    None => "13px"
  }
}

///|
pub fn DocumentStyle::font_size_value(
  self : DocumentStyle,
  fallback? : Int = 13,
) -> Int {
  guard self.font_size is Some(value) else { return fallback }
  parse_font_size(value, fallback~)
}

///|
fn parse_font_size(value : String, fallback~ : Int) -> Int {
  let normalized = value.to_lower()
  let raw = normalized.trim_end(chars="pxt").trim()
  let parsed = @string.parse_int(raw) catch { _ => fallback }
  if normalized.has_suffix("pt") {
    (parsed * 4 + 2) / 3
  } else {
    parsed
  }
}

///|
pub fn font_profile_for(family : String) -> @metrics.FontProfile {
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
pub fn DocumentStyle::font_profile(
  self : DocumentStyle,
) -> @metrics.FontProfile {
  font_profile_for(self.font_family())
}

///|
/// Compatibility wrapper for the original top-level style API.
pub fn font_family(style : DocumentStyle) -> String {
  style.font_family()
}

///|
/// Compatibility wrapper for the original top-level style API.
pub fn font_size(style : DocumentStyle) -> String {
  style.font_size()
}

///|
/// Compatibility wrapper for the original top-level style API.
pub fn font_size_value(style : DocumentStyle, fallback? : Int = 13) -> Int {
  style.font_size_value(fallback~)
}

///|
/// Compatibility wrapper for the original top-level style API.
pub fn font_profile(style : DocumentStyle) -> @metrics.FontProfile {
  style.font_profile()
}

///|
/// Builds metrics from the document font settings plus a concrete text role.
pub fn DocumentStyle::font_metrics(
  self : DocumentStyle,
  font_size? : Int = 0,
  font_weight? : Int = 400,
  font_style? : @metrics.FontStyle = Normal,
  line_height? : Int = 0,
) -> @metrics.FontMetrics {
  self.font_metrics_for(
    self.font_family(),
    font_size~,
    font_weight~,
    font_style~,
    line_height~,
  )
}

///|
pub fn DocumentStyle::font_metrics_for(
  self : DocumentStyle,
  family : String,
  font_size? : Int = 0,
  font_weight? : Int = 400,
  font_style? : @metrics.FontStyle = Normal,
  line_height? : Int = 0,
) -> @metrics.FontMetrics {
  let resolved_size = if font_size > 0 {
    font_size
  } else {
    self.font_size_value()
  }
  let resolved_line_height = if line_height > 0 {
    line_height
  } else {
    resolved_size + 2
  }
  @metrics.FontMetrics::from_defaults(
    profile=font_profile_for(family),
    style=font_style,
    font_size=resolved_size,
    font_weight~,
    line_height=resolved_line_height,
  )
}

///|
/// Returns whether a line is a PlantUML preprocessor directive that does not
/// directly contribute to a diagram model.
pub fn is_preprocessor_directive(line : String) -> Bool {
  line.trim().has_prefix("!")
}
