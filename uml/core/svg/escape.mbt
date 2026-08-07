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
/// Resolve PlantUML's built-in named colors to the canonical SVG hex value.
fn named_plantuml_color(value : String) -> String? {
  match value.to_lower() {
    "aliceblue" => Some("#F0F8FF")
    "antiquewhite" => Some("#FAEBD7")
    "aqua" | "cyan" => Some("#00FFFF")
    "aquamarine" => Some("#7FFFD4")
    "azure" => Some("#F0FFFF")
    "beige" => Some("#F5F5DC")
    "bisque" => Some("#FFE4C4")
    "black" => Some("#000000")
    "blanchedalmond" => Some("#FFEBCD")
    "blue" => Some("#0000FF")
    "blueviolet" => Some("#8A2BE2")
    "brown" => Some("#A52A2A")
    "burlywood" => Some("#DEB887")
    "cadetblue" => Some("#5F9EA0")
    "chartreuse" => Some("#7FFF00")
    "chocolate" => Some("#D2691E")
    "coral" => Some("#FF7F50")
    "cornflowerblue" => Some("#6495ED")
    "cornsilk" => Some("#FFF8DC")
    "crimson" => Some("#DC143C")
    "darkblue" => Some("#00008B")
    "darkcyan" => Some("#008B8B")
    "darkgoldenrod" => Some("#B8860B")
    "darkgray" | "darkgrey" => Some("#A9A9A9")
    "darkgreen" => Some("#006400")
    "darkkhaki" => Some("#BDB76B")
    "darkmagenta" => Some("#8B008B")
    "darkolivegreen" => Some("#556B2F")
    "darkorange" => Some("#FF8C00")
    "darkorchid" => Some("#9932CC")
    "darkred" => Some("#8B0000")
    "darksalmon" => Some("#E9967A")
    "darkseagreen" => Some("#8FBC8F")
    "darkslateblue" => Some("#483D8B")
    "darkslategray" | "darkslategrey" => Some("#2F4F4F")
    "darkturquoise" => Some("#00CED1")
    "darkviolet" => Some("#9400D3")
    "deeppink" => Some("#FF1493")
    "deepskyblue" => Some("#00BFFF")
    "dimgray" | "dimgrey" => Some("#696969")
    "dodgerblue" => Some("#1E90FF")
    "firebrick" => Some("#B22222")
    "floralwhite" => Some("#FFFAF0")
    "forestgreen" => Some("#228B22")
    "fuchsia" | "magenta" => Some("#FF00FF")
    "gainsboro" => Some("#DCDCDC")
    "ghostwhite" => Some("#F8F8FF")
    "gold" => Some("#FFD700")
    "goldenrod" => Some("#DAA520")
    "gray" | "grey" => Some("#808080")
    "green" => Some("#008000")
    "greenyellow" => Some("#ADFF2F")
    "honeydew" => Some("#F0FFF0")
    "hotpink" => Some("#FF69B4")
    "indianred" => Some("#CD5C5C")
    "indigo" => Some("#4B0082")
    "ivory" => Some("#FFFFF0")
    "khaki" => Some("#F0E68C")
    "lavender" => Some("#E6E6FA")
    "lavenderblush" => Some("#FFF0F5")
    "lawngreen" => Some("#7CFC00")
    "lemonchiffon" => Some("#FFFACD")
    "lightblue" => Some("#ADD8E6")
    "lightcoral" => Some("#F08080")
    "lightcyan" => Some("#E0FFFF")
    "lightgoldenrodyellow" => Some("#FAFAD2")
    "lightgray" | "lightgrey" => Some("#D3D3D3")
    "lightgreen" => Some("#90EE90")
    "lightpink" => Some("#FFB6C1")
    "lightsalmon" => Some("#FFA07A")
    "lightseagreen" => Some("#20B2AA")
    "lightskyblue" => Some("#87CEFA")
    "lightslategray" | "lightslategrey" => Some("#778899")
    "lightsteelblue" => Some("#B0C4DE")
    "lightyellow" => Some("#FFFFE0")
    "lime" => Some("#00FF00")
    "limegreen" => Some("#32CD32")
    "linen" => Some("#FAF0E6")
    "maroon" => Some("#800000")
    "mediumaquamarine" => Some("#66CDAA")
    "mediumblue" => Some("#0000CD")
    "mediumorchid" => Some("#BA55D3")
    "mediumpurple" => Some("#9370D8")
    "mediumseagreen" => Some("#3CB371")
    "mediumslateblue" => Some("#7B68EE")
    "mediumspringgreen" => Some("#00FA9A")
    "mediumturquoise" => Some("#48D1CC")
    "mediumvioletred" => Some("#C71585")
    "midnightblue" => Some("#191970")
    "mintcream" => Some("#F5FFFA")
    "mistyrose" => Some("#FFE4E1")
    "moccasin" => Some("#FFE4B5")
    "navajowhite" => Some("#FFDEAD")
    "navy" => Some("#000080")
    "oldlace" => Some("#FDF5E6")
    "olive" => Some("#808000")
    "olivedrab" => Some("#6B8E23")
    "orange" => Some("#FFA500")
    "orangered" => Some("#FF4500")
    "orchid" => Some("#DA70D6")
    "palegoldenrod" => Some("#EEE8AA")
    "palegreen" => Some("#98FB98")
    "paleturquoise" => Some("#AFEEEE")
    "palevioletred" => Some("#D87093")
    "papayawhip" => Some("#FFEFD5")
    "peachpuff" => Some("#FFDAB9")
    "peru" => Some("#CD853F")
    "pink" => Some("#FFC0CB")
    "plum" => Some("#DDA0DD")
    "powderblue" => Some("#B0E0E6")
    "purple" => Some("#800080")
    "red" => Some("#FF0000")
    "rosybrown" => Some("#BC8F8F")
    "royalblue" => Some("#4169E1")
    "saddlebrown" => Some("#8B4513")
    "salmon" => Some("#FA8072")
    "sandybrown" => Some("#F4A460")
    "seagreen" => Some("#2E8B57")
    "seashell" => Some("#FFF5EE")
    "sienna" => Some("#A0522D")
    "silver" => Some("#C0C0C0")
    "skyblue" => Some("#87CEEB")
    "slateblue" => Some("#6A5ACD")
    "slategray" | "slategrey" => Some("#708090")
    "snow" => Some("#FFFAFA")
    "springgreen" => Some("#00FF7F")
    "steelblue" => Some("#4682B4")
    "tan" => Some("#D2B48C")
    "teal" => Some("#008080")
    "thistle" => Some("#D8BFD8")
    "tomato" => Some("#FF6347")
    "turquoise" => Some("#40E0D0")
    "violet" => Some("#EE82EE")
    "wheat" => Some("#F5DEB3")
    "white" => Some("#FFFFFF")
    "whitesmoke" => Some("#F5F5F5")
    "yellow" => Some("#FFFF00")
    "yellowgreen" => Some("#9ACD32")
    "business" => Some("#FFFFCC")
    "application" => Some("#C2F0FF")
    "motivation" => Some("#CCCCFF")
    "strategy" => Some("#F8E7C0")
    "technology" => Some("#C9FFC9")
    "physical" => Some("#97FF97")
    "implementation" => Some("#FFE0E0")
    _ => None
  }
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
        let name = if value.has_prefix("#") {
          value[1:].to_owned()
        } else {
          value.to_owned()
        }
        match named_plantuml_color(name) {
          Some(color) => color
          None if value.equal_ignore_ascii_case("transparent") ||
            value.equal_ignore_ascii_case("background") => "none"
          None => xml_escape(value.to_owned())
        }
      }
    }
  }
}
