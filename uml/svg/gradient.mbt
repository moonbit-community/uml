///|
pub(all) struct Gradient {
  first : String
  second : String
  policy : Char
}

///|
/// HColorSet short hex and grayscale forms, resolved before creating stops.
pub fn gradient_color(value : String) -> String? {
  let resolved = svg_color(Some(value), "").to_lower()
  let digits = if resolved.has_prefix("#") {
    resolved[1:].to_owned()
  } else {
    resolved
  }
  guard [1, 3, 6, 8].contains(digits.length()) &&
    digits
    .iter()
    .all(char => char.is_ascii_digit() || (char >= 'a' && char <= 'f')) else {
    return None
  }
  let color = match digits.length() {
    1 => digits.repeat(6)
    3 => {
      let output = StringBuilder()
      for char in digits {
        output.write_char(char)
        output.write_char(char)
      }
      output.to_string()
    }
    _ => digits
  }
  Some("#" + color)
}

///|
pub fn parse_gradient(value : String) -> Gradient? {
  for index in 0..<value.length() {
    let marker = value[index:index + 1]
    guard marker == "-" || marker == "|" || marker == "/" || marker == "\\" else {
      continue
    }
    guard gradient_color(value[:index].to_owned()) is Some(first) &&
      gradient_color(value[index + 1:].to_owned()) is Some(second) else {
      continue
    }
    return Some({ first, second, policy: marker.to_owned().to_array()[0], })
  }
  None
}

///|
pub fn Gradient::axis(self : Gradient) -> (@graphics.Point, @graphics.Point) {
  match self.policy {
    '|' => ({ x: 0.0, y: 0.5, }, { x: 1.0, y: 0.5, })
    '-' => ({ x: 0.5, y: 0.0, }, { x: 0.5, y: 1.0, })
    '\\' => ({ x: 0.0, y: 1.0, }, { x: 1.0, y: 0.0, })
    _ => ({ x: 0.0, y: 0.0, }, { x: 1.0, y: 1.0, })
  }
}

///|
fn XmlWriter::gradient_paint(
  self : XmlWriter,
  paint : @graphics.Paint,
  first_only : Bool,
) -> @graphics.Paint {
  guard paint is Color(value) && parse_gradient(value) is Some(gradient) else {
    return paint
  }
  guard !first_only else { return Color(gradient.first) }
  let direction = match gradient.policy {
    '|' => "horizontal"
    '-' => "vertical"
    '\\' => "rising"
    _ => "falling"
  }
  let id = "uml-gradient-" +
    gradient.first[1:7].to_owned() +
    "-" +
    gradient.second[1:7].to_owned() +
    "-" +
    direction
  if !self.gradients.contains(id) {
    self.gradients[id] = ()
    let (start, end) = gradient.axis()
    self.open("defs")
    self.open("linearGradient", attributes=[
      ("id", id),
      ("x1", "\{start.x * 100.0}%"),
      ("y1", "\{start.y * 100.0}%"),
      ("x2", "\{end.x * 100.0}%"),
      ("y2", "\{end.y * 100.0}%"),
    ])
    self.empty("stop", attributes=[
      ("offset", "0%"),
      ("stop-color", gradient.first[:7].to_owned()),
    ])
    self.empty("stop", attributes=[
      ("offset", "100%"),
      ("stop-color", gradient.second[:7].to_owned()),
    ])
    self.close()
    self.close()
  }
  Color("url(#" + id + ")")
}

///|
fn XmlWriter::gradient_css(self : XmlWriter, css : String) -> String {
  let output = StringBuilder()
  let mut value = StringBuilder()
  let mut in_value = false
  for char in css {
    if in_value && (char == ';' || char == '}') {
      let raw = value.to_string()
      let paint = self.gradient_paint(Color(raw.trim().to_owned()), false)
      guard paint is Color(color) else { continue }
      output.write_string(
        if parse_gradient(raw.trim().to_owned()) is Some(_) {
          color
        } else {
          raw
        },
      )
      output.write_char(char)
      value = StringBuilder()
      in_value = false
    } else if !in_value && char == ':' {
      output.write_char(char)
      in_value = true
    } else if in_value {
      value.write_char(char)
    } else {
      output.write_char(char)
    }
  }
  output.write_string(value.to_string())
  output.to_string()
}
