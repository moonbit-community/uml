///|
priv struct StateRichMedia {
  href : String
  width : Double
  height : Double
  sprite : StateRichSprite?
}

///|
priv struct StateRichSprite {
  width : Int
  height : Int
  levels : Int
  pixels : Array[Int]
  color : String?
}

///|
fn media_integer(
  bytes : Bytes,
  start : Int,
  length : Int,
  little? : Bool = false,
) -> Int? {
  guard start >= 0 && start + length <= bytes.length() else { return None }
  let mut value = 0
  for offset in 0..<length {
    let index = if little {
      start + length - offset - 1
    } else {
      start + offset
    }
    value = value * 256 + bytes[index].to_int()
  }
  Some(value)
}

///|
fn media_xml_attribute(text : String, name : String) -> String? {
  let cursor = @tokenizer.Cursor::new(text)
  while !cursor.is_eof() {
    if cursor.remaining().to_lower().has_prefix(name.to_lower()) {
      ignore(cursor.restore(cursor.offset() + name.length()))
      ignore(cursor.skip_while(Char::is_whitespace))
      if cursor.consume('=') {
        ignore(cursor.skip_while(Char::is_whitespace))
        if cursor.advance() is Some(quote) && (quote == '"' || quote == '\'') {
          let value = cursor.take_while(char => char != quote)
          if cursor.consume(quote) {
            return Some(value)
          }
        }
      }
    } else {
      ignore(cursor.advance())
    }
  }
  None
}

///|
fn media_svg_dimension(text : String) -> (Double, Double)? {
  if media_xml_attribute(text, "viewBox") is Some(viewbox) {
    let values = viewbox
      .replace_all(old=",", new=" ")
      .split(" ")
      .filter_map(value => {
        if value.is_empty() {
          return None
        }
        let value = @string.parse_double(value) catch { _ => return None }
        Some(value)
      })
      .to_array()
    if values.length() == 4 {
      return Some((values[2].ceil(), values[3].ceil()))
    }
  }
  let dimension = (name : String) => {
    media_xml_attribute(text, name).bind(value => {
      let cursor = @tokenizer.Cursor::new(value)
      let number = cursor.take_while(char => {
        char.is_ascii_digit() || char == '.'
      })
      let value = @string.parse_double(number) catch { _ => return None }
      Some(value)
    })
  }
  match (dimension("width"), dimension("height")) {
    (Some(width), Some(height)) => Some((width, height))
    _ => None
  }
}

///|
fn media_data_bytes(uri : String) -> (String, Bytes)? {
  guard uri.has_prefix("data:") && uri.find(",") is Some(comma) else {
    return None
  }
  let metadata = uri[5:comma].to_owned()
  let data = uri[comma + 1:]
  let bytes = if metadata.has_suffix(";base64") {
    @base64.decode(data) catch {
      _ => return None
    }
  } else {
    let cursor = @tokenizer.Cursor::new(data.to_owned())
    let bytes : Array[Byte] = []
    while cursor.advance() is Some(char) {
      if char == '%' {
        let start = cursor.offset()
        guard start + 2 <= cursor.length() else { return None }
        let digits = cursor.slice(start, start + 2)
        ignore(cursor.restore(start + 2))
        guard digits.iter().all(Char::is_ascii_hexdigit) else { return None }
        guard digits.length() == 2 else { return None }
        let value = @string.parse_int(digits, base=16) catch {
          _ => return None
        }
        bytes.push(value.to_byte())
      } else {
        bytes.append(@utf8.encode(char.to_string()[:]).to_array())
      }
    }
    Bytes::from_array(bytes)
  }
  Some((metadata, bytes))
}

///|
fn state_media(
  uri : String,
  scale : Double,
  color : String?,
) -> StateRichMedia? {
  guard media_data_bytes(uri) is Some((kind, bytes)) else { return None }
  if kind.has_prefix("application/x-plantuml-sprite") {
    let text = @utf8.decode(bytes[:]) catch { _ => return None }
    let fields = text.split(";").to_array()
    guard fields.length() == 4 else { return None }
    let width = @string.parse_int(fields[0]) catch { _ => return None }
    let height = @string.parse_int(fields[1]) catch { _ => return None }
    let levels = @string.parse_int(fields[2]) catch { _ => return None }
    let pixels = []
    for value in fields[3].split(",") {
      pixels.push(@string.parse_int(value) catch { _ => return None })
    }
    guard width > 0 && height > 0 && pixels.length() == width * height else {
      return None
    }
    return Some({
      href: uri,
      width: width.to_double() * scale,
      height: height.to_double() * scale,
      sprite: Some({ width, height, levels, pixels, color, }),
    })
  }
  let dimensions = if kind.has_prefix("image/svg+xml") {
    let text = @utf8.decode(bytes[:]) catch { _ => return None }
    media_svg_dimension(text)
  } else if bytes.has_prefix(b"\x89PNG\r\n\x1a\n") {
    match (media_integer(bytes, 16, 4), media_integer(bytes, 20, 4)) {
      (Some(width), Some(height)) =>
        Some((width.to_double(), height.to_double()))
      _ => None
    }
  } else if bytes.has_prefix(b"GIF87a") || bytes.has_prefix(b"GIF89a") {
    match
      (
        media_integer(bytes, 6, 2, little=true),
        media_integer(bytes, 8, 2, little=true),
      ) {
      (Some(width), Some(height)) =>
        Some((width.to_double(), height.to_double()))
      _ => None
    }
  } else if bytes.has_prefix(b"\xff\xd8") {
    let mut index = 2
    let mut result = None
    while index + 3 < bytes.length() {
      guard bytes[index] == b'\xff' else { break }
      index += 1
      while index < bytes.length() && bytes[index] == b'\xff' {
        index += 1
      }
      guard index < bytes.length() else { break }
      let marker = bytes[index].to_int()
      index += 1
      if marker == 0xD9 || marker == 0xDA {
        break
      }
      if marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7) {
        continue
      }
      guard media_integer(bytes, index, 2) is Some(length) && length >= 2 else {
        break
      }
      if marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC {
        if (
            media_integer(bytes, index + 3, 2),
            media_integer(bytes, index + 5, 2),
          )
          is (Some(height), Some(width)) {
          result = Some((width.to_double(), height.to_double()))
        }
        break
      }
      index += length
    }
    result
  } else {
    None
  }
  guard dimensions is Some((width, height)) && width > 0.0 && height > 0.0 else {
    return None
  }
  Some({
    href: uri,
    width: width * scale,
    height: height * scale,
    sprite: None,
  })
}

///|
fn state_rich_media_open(text : String) -> (Int, StateRichMedia?)? {
  let lower = text.to_lower()
  guard (lower.has_prefix("<img:") || lower.has_prefix("<img ")) &&
    text.find(">") is Some(end) else {
    return None
  }
  let mut source = text[5:end].trim().to_owned()
  let mut scale = 1.0
  let mut color = None
  if source.find("{") is Some(options) {
    let values = source[options + 1:].trim_end(chars="}").to_owned()
    source = source[:options].trim().to_owned()
    for option in values.split(" ") {
      if option.has_prefix("scale=") {
        scale = @string.parse_double(option[6:]) catch { _ => 1.0 }
      }
      if option.has_prefix("color=") {
        color = Some(option[6:].to_owned())
      }
    }
  }
  if source.has_prefix("src=") {
    source = source[4:].to_owned()
  }
  source = @tokenizer.unquote_identifier(source)
  Some((end + 1, state_media(source, scale, color)))
}

///|
fn sprite_rgb(color : String, fallback : String) -> (Int, Int, Int) {
  let color = @svg.svg_color(Some(color), fallback)
  let color = if color.length() == 4 && color.has_prefix("#") {
    "#" +
    color[1:2].to_owned() +
    color[1:2].to_owned() +
    color[2:3].to_owned() +
    color[2:3].to_owned() +
    color[3:4].to_owned() +
    color[3:4].to_owned()
  } else {
    color
  }
  if color.length() >= 7 && color.has_prefix("#") {
    let value = @string.parse_int(color[1:7], base=16) catch { _ => 0 }
    ((value >> 16) & 255, (value >> 8) & 255, value & 255)
  } else {
    (0, 0, 0)
  }
}

///|
fn StateRichMedia::draw(
  self : StateRichMedia,
  output : @graphics.Graphic,
  x : Double,
  y : Double,
  color : String?,
  background : String?,
  metadata : @graphics.Metadata,
) -> Unit {
  guard self.sprite is Some(sprite) else {
    output.draw(
      Image(
        origin={ x, y, },
        width=self.width,
        height=self.height,
        href=self.href,
      ),
      metadata~,
    )
    return
  }
  let foreground = sprite.color
    .map_or(color, value => Some(value))
    .unwrap_or(
      match output.style.fill {
        Color(value) => value
        _ => "black"
      },
    )
  let (fr, fg, fb) = sprite_rgb(foreground, "black")
  let (br, bg, bb) = sprite_rgb(background.unwrap_or("white"), "white")
  let maximum = sprite.pixels.fold(init=0, Int::max).max(1)
  let scale_x = self.width / sprite.width.to_double()
  let scale_y = self.height / sprite.height.to_double()
  for row in 0..<sprite.height {
    for column in 0..<sprite.width {
      let value = sprite.pixels[row * sprite.width + column]
      if value < 0 {
        continue
      }
      let (red, green, blue, opacity) = if sprite.levels == 4096 {
        ((value >> 16) & 255, (value >> 8) & 255, value & 255, 1.0)
      } else {
        if value == 0 {
          continue
        }
        let fraction = value.to_double() / (sprite.levels - 1).to_double()
        let mix = (back : Int, front : Int) => {
          (back.to_double() + (front - back).to_double() * fraction).to_int()
        }
        let alpha = (255.0 * value.to_double() * 4.0 / maximum.to_double())
          .min(255.0)
          .to_int()
        let opacity = alpha.to_double() / 255.0
        (mix(br, fr), mix(bg, fg), mix(bb, fb), opacity)
      }
      let fill = "rgba(\{red},\{green},\{blue},\{opacity})"
      output
      .with_style({ ..Default::default(), fill: Color(fill), stroke: None, })
      .draw(
        Rectangle(
          origin={
            x: x + column.to_double() * scale_x,
            y: y + row.to_double() * scale_y,
          },
          width=scale_x,
          height=scale_y,
          rx=None,
          ry=None,
        ),
        metadata~,
      )
    }
  }
}
