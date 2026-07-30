///|
/// Common PlantUML document-level style state.
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
  properties : Map[String, String]
} derive(Eq, Debug)

///|
/// Shared PlantUML-like paint defaults used by every SVG renderer.
pub struct RenderDefaults {
  canvas_background : String
  diagram_line : String
  diagram_text : String
  node_background : String
  sequence_participant_background : String
  note_background : String
  transparent : String
} derive(Eq, Debug)

///|
pub fn render_defaults() -> RenderDefaults {
  {
    canvas_background: "#FFFFFF",
    diagram_line: "#181818",
    diagram_text: "#181818",
    node_background: "#F1F1F1",
    sequence_participant_background: "#FEFECE",
    note_background: "#FEFFDD",
    transparent: "none",
  }
}

///|
pub(all) enum Direction {
  TopToBottom
  LeftToRight
} derive(Eq, Debug)

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
    properties: Map([]),
  }
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
  self.properties.get(key)
}

///|
pub fn DocumentStyle::canvas_color(self : DocumentStyle) -> String {
  svg_color(self.background_color, render_defaults().canvas_background)
}

///|
pub fn DocumentStyle::diagram_line_color(self : DocumentStyle) -> String {
  svg_color(self.line_color, render_defaults().diagram_line)
}

///|
pub fn DocumentStyle::class_background_color(self : DocumentStyle) -> String {
  svg_color(
    self.property("ClassBackgroundColor"),
    render_defaults().node_background,
  )
}

///|
pub fn DocumentStyle::class_border_color(self : DocumentStyle) -> String {
  svg_color(self.property("ClassBorderColor"), self.diagram_line_color())
}

///|
pub fn DocumentStyle::usecase_background_color(self : DocumentStyle) -> String {
  svg_color(
    self.property("UsecaseBackgroundColor"),
    self.class_background_color(),
  )
}

///|
pub fn DocumentStyle::usecase_border_color(self : DocumentStyle) -> String {
  svg_color(self.property("UsecaseBorderColor"), self.class_border_color())
}

///|
pub fn DocumentStyle::actor_background_color(self : DocumentStyle) -> String {
  svg_color(
    self.property("ActorBackgroundColor"),
    self.class_background_color(),
  )
}

///|
pub fn DocumentStyle::actor_border_color(self : DocumentStyle) -> String {
  svg_color(self.property("ActorBorderColor"), self.class_border_color())
}

///|
pub fn DocumentStyle::actor_style(self : DocumentStyle) -> String {
  self
  .property("ActorStyle")
  .unwrap_or(
    self
    .property("actorStyle")
    .unwrap_or(self.property("actorstyle").unwrap_or("stickman")),
  )
  .to_lower()
}

///|
pub fn DocumentStyle::diagram_text_color(self : DocumentStyle) -> String {
  svg_color(self.property("FontColor"), render_defaults().diagram_text)
}

///|
pub fn DocumentStyle::usecase_font_color(self : DocumentStyle) -> String {
  svg_color(self.property("UsecaseFontColor"), self.diagram_text_color())
}

///|
pub fn DocumentStyle::actor_font_color(self : DocumentStyle) -> String {
  svg_color(self.property("ActorFontColor"), self.diagram_text_color())
}

///|
pub fn DocumentStyle::usecase_font_size(
  self : DocumentStyle,
  fallback~ : Int,
) -> Int {
  match self.property("UsecaseFontSize") {
    Some(value) => parse_font_size(value, fallback~)
    None => fallback
  }
}

///|
pub fn DocumentStyle::actor_font_size(
  self : DocumentStyle,
  fallback~ : Int,
) -> Int {
  match self.property("ActorFontSize") {
    Some(value) => parse_font_size(value, fallback~)
    None => fallback
  }
}

///|
pub fn DocumentStyle::usecase_font_family(self : DocumentStyle) -> String {
  self.property("UsecaseFontName").unwrap_or(font_family(self))
}

///|
pub fn DocumentStyle::actor_font_family(self : DocumentStyle) -> String {
  self.property("ActorFontName").unwrap_or(font_family(self))
}

///|
pub fn DocumentStyle::arrow_font_color(self : DocumentStyle) -> String {
  svg_color(self.property("ArrowFontColor"), self.diagram_text_color())
}

///|
pub fn DocumentStyle::arrow_font_size(
  self : DocumentStyle,
  fallback~ : Int,
) -> Int {
  match self.property("ArrowFontSize") {
    Some(value) => parse_font_size(value, fallback~)
    None => fallback
  }
}

///|
pub fn DocumentStyle::arrow_font_family(self : DocumentStyle) -> String {
  self.property("ArrowFontName").unwrap_or(font_family(self))
}

///|
pub fn DocumentStyle::package_background_color(self : DocumentStyle) -> String {
  svg_color(
    self.property("PackageBackgroundColor"),
    render_defaults().transparent,
  )
}

///|
pub fn DocumentStyle::package_border_color(self : DocumentStyle) -> String {
  svg_color(self.property("PackageBorderColor"), self.class_border_color())
}

///|
pub fn DocumentStyle::note_background_color(self : DocumentStyle) -> String {
  svg_color(
    self.property("NoteBackgroundColor"),
    render_defaults().note_background,
  )
}

///|
pub fn DocumentStyle::note_border_color(self : DocumentStyle) -> String {
  svg_color(self.property("NoteBorderColor"), self.class_border_color())
}

///|
pub fn parse_style_directive(line : String) -> StyleDirective? {
  let trimmed = line.trim()
  if trimmed.to_lower().has_prefix("skinparam ") {
    return parse_style_property(trimmed[10:].trim().to_owned())
  }
  let lower = trimmed.to_lower()
  if lower == "left to right direction" {
    return Some(Direction(LeftToRight))
  }
  if lower == "top to bottom direction" {
    return Some(Direction(TopToBottom))
  }
  if lower == "hide empty description" {
    return Some(Property("hide empty description", "true"))
  }
  if lower.has_prefix("set namespace_separator ") ||
    lower.has_prefix("set namespaceseparator ") {
    return Some(
      Property(
        "namespace separator",
        syntax_words(trimmed.to_owned()).last().unwrap_or(""),
      ),
    )
  }
  if lower == "footbox" ||
    lower == "newpage" ||
    lower.has_prefix("newpage ") ||
    lower == "layout newline" {
    return Some(Property(lower.to_owned(), "true"))
  }
  if lower.has_prefix("scale ") {
    return Some(Scale(trimmed[6:].trim().to_owned()))
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
  if words.length() >= 2 &&
    (
      words[0].equal_ignore_ascii_case("UsecaseFontName") ||
      words[0].equal_ignore_ascii_case("ActorFontName")
    ) {
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
pub fn font_family(style : DocumentStyle) -> String {
  style.font_family.unwrap_or("Arial, sans-serif")
}

///|
pub fn font_size(style : DocumentStyle) -> String {
  match style.font_size {
    Some(size) if size.has_suffix("px") || size.has_suffix("pt") => size
    Some(size) => "\{size}px"
    None => "13px"
  }
}

///|
pub fn font_size_value(style : DocumentStyle) -> Int {
  parse_font_size(style.font_size.unwrap_or("13"), fallback=13)
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
pub fn font_profile(style : DocumentStyle) -> @metrics.FontProfile {
  font_profile_for(font_family(style))
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
    font_family(self),
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
    font_size_value(self)
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

///|
pub fn xml_escape(value : String) -> String {
  let output = StringBuilder()
  for char in value {
    match char {
      '&' => output.write_string("&amp;")
      '<' => output.write_string("&lt;")
      '>' => output.write_string("&gt;")
      '"' => output.write_string("&quot;")
      '\'' => output.write_string("&apos;")
      _ => output.write_char(char)
    }
  }
  output.to_string()
}

///|
fn is_hexadecimal(value : String) -> Bool {
  let value = if value.has_prefix("#") { value[1:].to_owned() } else { value }
  guard value.length() == 3 || value.length() == 6 || value.length() == 8 else {
    false
  }
  for char in value {
    guard char.is_ascii_digit() ||
      ('a' <= char && char <= 'f') ||
      ('A' <= char && char <= 'F') else {
      return false
    }
  }
  true
}

///|
/// Convert a PlantUML color token to a safe SVG paint value.
pub fn svg_color(color : String?, fallback : String) -> String {
  match color {
    None => fallback
    Some(value) => {
      let value = value.trim()
      if is_hexadecimal(value.to_owned()) {
        if value.has_prefix("#") {
          value.to_owned()
        } else {
          "#\{value}"
        }
      } else {
        xml_escape(value.to_owned())
      }
    }
  }
}
