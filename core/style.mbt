///|
/// Common PlantUML document-level style state.
pub struct DocumentStyle {
  mut background_color : String?
  mut theme : String?
  mut font_family : String?
  mut font_size : String?
  mut line_color : String?
} derive(Eq, Debug)

///|
pub(all) enum StyleDirective {
  BackgroundColor(String)
  Theme(String)
  FontFamily(String)
  FontSize(String)
  LineColor(String)
} derive(Eq, Debug)

///|
pub fn DocumentStyle::empty() -> DocumentStyle {
  {
    background_color: None,
    theme: None,
    font_family: None,
    font_size: None,
    line_color: None,
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
  }
}

///|
pub fn parse_style_directive(line : String) -> StyleDirective? {
  let trimmed = line.trim()
  if trimmed.to_lower().has_prefix("skinparam ") {
    return parse_style_property(trimmed[10:].trim().to_owned())
  }
  let words = trimmed
    .split(" ")
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  match words {
    ["!theme", theme, ..] => Some(Theme(theme))
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
  match words {
    [key, color, ..] if key.equal_ignore_ascii_case("BackgroundColor") =>
      Some(BackgroundColor(color))
    [key, family, ..] if key.equal_ignore_ascii_case("DefaultFontName") =>
      Some(FontFamily(family))
    [key, size, ..] if key.equal_ignore_ascii_case("DefaultFontSize") =>
      Some(FontSize(size))
    [key, color, ..] if key.equal_ignore_ascii_case("ArrowColor") =>
      Some(LineColor(color))
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
/// Returns whether a line is a PlantUML preprocessor directive that does not
/// directly contribute to a diagram model.
pub fn is_preprocessor_directive(line : String) -> Bool {
  line.trim().has_prefix("!")
}

///|

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
