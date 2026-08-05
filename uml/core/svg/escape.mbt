///|
/// Escape text for use in XML text or attribute content.
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
/// Escape XML text content while preserving quotes.
pub fn xml_escape_text(value : String) -> String {
  let output = StringBuilder()
  for char in value {
    match char {
      '&' => output.write_string("&amp;")
      '<' => output.write_string("&lt;")
      '>' => output.write_string("&gt;")
      _ => output.write_char(char)
    }
  }
  output.to_string()
}

///|
/// Escape a double-quoted XML attribute value.
pub fn xml_escape_attribute(value : String) -> String {
  let output = StringBuilder()
  for char in value {
    match char {
      '&' => output.write_string("&amp;")
      '<' => output.write_string("&lt;")
      '"' => output.write_string("&quot;")
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
