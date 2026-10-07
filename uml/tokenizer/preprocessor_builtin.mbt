///|
fn Preprocessor::call_builtin(
  self : Preprocessor,
  name : String,
  args : Array[PreValue],
) -> PreValue raise ParseError {
  let string = (index : Int) => pre_text(args.get(index).unwrap_or(Null))
  let integer = (index : Int) => {
    @string.parse_int(string(index)) catch {
      _ => 0
    }
  }
  let boolean = (value : Bool) => {
    if value {
      PreValue::True
    } else {
      PreValue::False
    }
  }
  match name.to_lower() {
    "%true" => True
    "%false" => False
    "%not" => boolean(!pre_truth(args.get(0).unwrap_or(Null)))
    "%and" => boolean(args.all(pre_truth))
    "%or" => boolean(args.any(pre_truth))
    "%variable_exists" => boolean(self.variables.contains(string(0)))
    "%function_exists" => boolean(self.definitions.contains(string(0)))
    "%get_variable_value" => self.variables.get(string(0)).unwrap_or(Null)
    "%set_variable_value" => {
      self.variables[string(0)] = args.get(1).unwrap_or(Null)
      Null
    }
    "%string" => String(string(0))
    "%intval" => PreValue::number(integer(0).to_double())
    "%boolval" =>
      match string(0).to_lower() {
        "true" | "1" => True
        "false" | "0" => False
        _ =>
          raise SyntaxError(
            self.line,
            "cannot convert to boolean: " + string(0),
          )
      }
    "%strlen" => PreValue::number(string(0).length().to_double())
    "%upper" => String(string(0).to_upper())
    "%lower" => String(string(0).to_lower())
    "%strpos" =>
      PreValue::number(string(0).find(string(1)[:]).unwrap_or(-1).to_double())
    "%substr" => {
      let text = string(0)
      let start = integer(1).max(0).min(text.length())
      let end = if args.length() > 2 {
        (start + integer(2)).max(start).min(text.length())
      } else {
        text.length()
      }
      String(text[start:end].to_owned())
    }
    "%splitstr" =>
      Array(
        string(0)
        .split(string(1)[:])
        .map(part => PreValue::String(part.to_owned()))
        .to_array(),
      )
    "%get_json_keys" =>
      match args.get(0) {
        Some(Object(values)) =>
          Array(values.keys().map(key => PreValue::String(key)).to_array())
        _ => Array([])
      }
    "%get_json_type" =>
      String(
        match args.get(0) {
          Some(Object(_)) => "object"
          Some(Array(_)) => "array"
          Some(String(_)) => "string"
          Some(Number(_)) => "number"
          Some(True | False) => "boolean"
          _ => "null"
        },
      )
    "%json_key_exists" =>
      boolean(
        match args.get(0) {
          Some(Object(values)) => values.contains(string(1))
          _ => false
        },
      )
    "%getenv" => String(self.resources.get("env:" + string(0)).unwrap_or(""))
    "%newline" => String("\n")
    "%tabulation" => String("\t")
    "%backslash" => String("\\")
    "%percent" => String("%")
    "%lighten" => String(pre_adjust_lightness(string(0), integer(1), self.line))
    "%darken" => String(pre_adjust_lightness(string(0), -integer(1), self.line))
    _ =>
      raise SyntaxError(self.line, "unsupported preprocessor function: " + name)
  }
}

///|
/// HColorSimple.lighten/darken multiplies HSL luminance by 1 + ratio / 100.
fn pre_adjust_lightness(
  color : String,
  ratio : Int,
  line : Int,
) -> String raise ParseError {
  let color = @svg.svg_color(Some(color), "")
  guard color.has_prefix("#") && (color.length() == 7 || color.length() == 4) else {
    raise SyntaxError(line, "expected an RGB color: " + color)
  }
  let hex = if color.length() == 4 {
    color[1:2].repeat(2) + color[2:3].repeat(2) + color[3:4].repeat(2)
  } else {
    color[1:].to_owned()
  }
  let channel = (offset : Int) => {
    (@string.parse_int(hex[offset:offset + 2], base=16) catch { _ => 0 }).to_double() /
    255.0
  }
  let r = channel(0)
  let g = channel(2)
  let b = channel(4)
  let maximum = r.max(g).max(b)
  let minimum = r.min(g).min(b)
  let original = (maximum + minimum) / 2.0
  let luminance = (original * (1.0 + ratio.to_double() / 100.0))
    .max(0.0)
    .min(1.0)
  let delta = maximum - minimum
  let saturation = if delta == 0 {
    0.0
  } else {
    delta / (1.0 - (2.0 * original - 1.0).abs())
  }
  let hue = if delta == 0 {
    0.0
  } else if maximum == r {
    ((g - b) / delta + (if g < b { 6.0 } else { 0.0 })) / 6.0
  } else if maximum == g {
    ((b - r) / delta + 2.0) / 6.0
  } else {
    ((r - g) / delta + 4.0) / 6.0
  }
  let q = if luminance < 0.5 {
    luminance * (1.0 + saturation)
  } else {
    luminance + saturation - luminance * saturation
  }
  let p = 2.0 * luminance - q
  let rgb = (offset : Double) => {
    let mut t = hue + offset
    if t < 0.0 {
      t += 1.0
    }
    if t > 1.0 {
      t -= 1.0
    }
    let result = if saturation == 0.0 {
      luminance
    } else if t < 1.0 / 6.0 {
      p + (q - p) * 6.0 * t
    } else if t < 0.5 {
      q
    } else if t < 2.0 / 3.0 {
      p + (q - p) * (2.0 / 3.0 - t) * 6.0
    } else {
      p
    }
    (result * 255.0).round().to_int().max(0).min(255)
  }
  let digits = "0123456789abcdef"
  let output = StringBuilder()
  output.write_string("#")
  for channel in [rgb(1.0 / 3.0), rgb(0.0), rgb(-1.0 / 3.0)] {
    output.write_string(digits[channel / 16:channel / 16 + 1].to_owned())
    output.write_string(digits[channel % 16:channel % 16 + 1].to_owned())
  }
  output.to_string()
}
