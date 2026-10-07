///|
fn sprite_digit(char : Char) -> Int? {
  match char {
    '0'..='9' => Some(char.to_int() - '0'.to_int())
    'A'..='Z' => Some(char.to_int() - 'A'.to_int() + 10)
    'a'..='z' => Some(char.to_int() - 'a'.to_int() + 36)
    '-' => Some(62)
    '_' => Some(63)
    _ => None
  }
}

///|
fn sprite_compressed_bytes(source : String) -> Bytes raise ParseError {
  let values = []
  for char in source {
    guard sprite_digit(char) is Some(value) else {
      raise SyntaxError(1, "invalid compressed sprite character")
    }
    values.push(value)
  }
  let bytes : Array[Byte] = []
  let mut index = 0
  while index < values.length() {
    let a = values[index]
    let b = values.get(index + 1).unwrap_or(0)
    let c = values.get(index + 2).unwrap_or(0)
    let d = values.get(index + 3).unwrap_or(0)
    bytes.push(((a << 2) | (b >> 4)).to_byte())
    bytes.push((((b & 15) << 4) | (c >> 2)).to_byte())
    bytes.push((((c & 3) << 6) | d).to_byte())
    index += 4
  }
  Bytes::from_array(bytes)
}

///|
fn sprite_resource(
  spec : String?,
  lines : Array[String],
) -> String raise ParseError {
  guard !lines.is_empty() else { raise SyntaxError(1, "empty sprite") }
  let mut width = lines[0].length()
  let mut height = lines.length()
  let mut levels = 16
  let mut compressed = false
  if spec is Some(spec) {
    let parts = spec.trim(chars="[]").split("/").to_array()
    guard parts.length() == 2 else {
      raise SyntaxError(1, "invalid sprite dimensions")
    }
    let dimensions = parts[0].split("x").to_array()
    guard dimensions.length() == 2 else {
      raise SyntaxError(1, "invalid sprite dimensions")
    }
    width = @string.parse_int(dimensions[0]) catch {
      _ => raise SyntaxError(1, "invalid sprite width")
    }
    height = @string.parse_int(dimensions[1]) catch {
      _ => raise SyntaxError(1, "invalid sprite height")
    }
    if parts[1] == "color" {
      levels = 4096
    } else {
      compressed = parts[1].has_suffix("z")
      levels = @string.parse_int(parts[1].trim_end(chars="z")) catch {
        _ => raise SyntaxError(1, "invalid sprite gray levels")
      }
      guard levels == 4 || levels == 8 || levels == 16 else {
        raise SyntaxError(1, "sprite requires 4, 8 or 16 gray levels")
      }
    }
  }
  // The reference's uncompressed 16-level and color constructors derive
  // dimensions from the matrix, even if a size was supplied in the command.
  if !compressed && levels == 16 {
    width = lines[0].length()
    height = lines.length()
  }
  if levels == 4096 {
    width = lines[0].length() / 2
    height = lines.length()
  }
  guard width > 0 && height > 0 else {
    raise SyntaxError(1, "sprite dimensions must be positive")
  }
  let pixels = Array::make(width * height, if levels == 4096 { -1 } else { 0 })
  if compressed {
    let bytes = inflate_raw(sprite_compressed_bytes(lines.join("")))
    guard bytes.length() >= pixels.length() else {
      raise SyntaxError(1, "compressed sprite is shorter than its dimensions")
    }
    for index in 0..<pixels.length() {
      let value = bytes[index].to_int()
      guard value < levels else {
        raise SyntaxError(1, "invalid compressed sprite pixel")
      }
      pixels[index] = value
    }
  } else if levels == 4096 {
    let palette = ".,$%&*+-:;<=>?@^_~GHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    for row, source in lines {
      let source = source
        .replace_all(old="!", new=".")
        .replace_all(old="#", new=",")
      for column in 0..<width {
        if column * 2 + 1 >= source.length() {
          continue
        }
        guard palette.find(source[column * 2:column * 2 + 1].to_owned())
          is Some(first) &&
          palette.find(source[column * 2 + 1:column * 2 + 2].to_owned())
          is Some(second) else {
          raise SyntaxError(1, "invalid color sprite pixel")
        }
        let color = first * 64 + second
        pixels[row * width + column] = ((color / 256 % 16 * 17) << 16) |
          ((color / 16 % 16 * 17) << 8) |
          (color % 16 * 17)
      }
    }
  } else {
    let stride = if levels == 4 { 3 } else if levels == 8 { 2 } else { 1 }
    for row, source in lines {
      for column, char in source.to_array() {
        if column >= width {
          continue
        }
        let value = if levels == 16 {
          @string.parse_int(char.to_string(), base=16) catch {
            _ => raise SyntaxError(1, "invalid sprite pixel")
          }
        } else {
          sprite_digit(char).unwrap_or_else(() => {
            raise SyntaxError(1, "invalid packed sprite pixel")
          })
        }
        for offset in 0..<stride {
          let y = row * stride + offset
          if y >= height {
            continue
          }
          let shift = (stride - offset - 1) * (if levels == 4 { 2 } else { 3 })
          pixels[y * width + column] = if levels == 16 {
            value
          } else {
            (value >> shift) & (levels - 1)
          }
        }
      }
    }
  }
  let data = "\{width};\{height};\{levels};" +
    pixels.map(value => value.to_string()).join(",")
  "data:application/x-plantuml-sprite;base64," +
  @base64.encode(@utf8.encode(data[:])[:])
}

///|
fn extract_sprite_resources(
  lines : Array[String],
  resources : Map[String, String],
) -> Array[String] raise ParseError {
  let output = []
  let mut index = 0
  while index < lines.length() {
    let line = lines[index].trim().to_owned()
    if !line.to_lower().has_prefix("sprite ") {
      output.push(lines[index])
      index += 1
      continue
    }
    let cursor = Cursor::new(line[7:].trim().to_owned())
    ignore(cursor.consume('$'))
    let name = cursor.take_while(char => {
      !char.is_whitespace() && char != '[' && char != '{'
    })
    guard !name.is_empty() else {
      raise SyntaxError(index + 1, "missing sprite name")
    }
    ignore(cursor.skip_while(Char::is_whitespace))
    let spec = if cursor.peek() is Some('[') {
      let value = cursor.take_while(char => char != ']')
      guard cursor.consume(']') else {
        raise SyntaxError(index + 1, "unclosed sprite dimensions")
      }
      Some(value + "]")
    } else {
      None
    }
    ignore(cursor.skip_while(Char::is_whitespace))
    let data = []
    if cursor.consume('{') {
      let start = index
      index += 1
      while index < lines.length() {
        let line = lines[index].trim().trim_start(chars="'").trim().to_owned()
        if line == "}" ||
          line.equal_ignore_ascii_case("endsprite") ||
          line.equal_ignore_ascii_case("end sprite") {
          break
        }
        if !line.is_empty() {
          data.push(line)
        }
        output.push("")
        index += 1
      }
      guard index < lines.length() else {
        raise SyntaxError(start + 1, "unclosed sprite")
      }
    } else {
      let value = cursor.take_rest_trimmed()
      guard !value.is_empty() else {
        raise SyntaxError(index + 1, "missing sprite data")
      }
      data.push(value)
    }
    resources["sprite:" + name] = sprite_resource(spec, data)
    output.push("")
    index += 1
  }
  output
}

///|
fn media_options(source : String) -> String {
  let source = source
    .trim(chars="{}, ")
    .replace_all(old=",", new=" ")
    .replace_all(old="*", new="scale=")
    .replace_all(old="color:", new="color=")
    .to_owned()
  if source.is_empty() {
    ""
  } else {
    "{" + source + "}"
  }
}

///|
fn expand_inline_media(
  line : String,
  resources : Map[String, String],
) -> String raise ParseError {
  let cursor = Cursor::new(line)
  let output = StringBuilder()
  while !cursor.is_eof() {
    let rest = cursor.remaining()
    if (rest.has_prefix("<$") || rest.has_prefix("<#")) &&
      rest.find(">") is Some(end) &&
      rest[:end].find("$") is Some(dollar) {
      let body = Cursor::new(rest[dollar + 1:end].to_owned())
      let name = body.take_while(char => {
        !char.is_whitespace() && char != '{' && char != ',' && char != '*'
      })
      guard resources.get("sprite:" + name) is Some(uri) else {
        raise SyntaxError(1, "sprite resource not provided: " + name)
      }
      let color = if dollar > 1 {
        " color=" + rest[1:dollar].to_owned()
      } else {
        ""
      }
      let options = media_options(body.take_rest_trimmed() + color)
      let uri = uri
        .replace_all(old="\"", new="%22")
        .replace_all(old="'", new="%27")
        .replace_all(old="<", new="%3C")
        .replace_all(old=">", new="%3E")
      output.write_string("<img:" + uri + options + ">")
      ignore(cursor.restore(cursor.offset() + end + 1))
      continue
    }
    if (
        rest.to_lower().has_prefix("<img:") ||
        rest.to_lower().has_prefix("<img ")
      ) &&
      rest.find(">") is Some(end) {
      let body = rest[5:end].trim().to_owned()
      let (raw_source, options) = match body.find("{") {
        Some(index) => (body[:index].trim().to_owned(), body[index:].to_owned())
        None => (body, "")
      }
      let source = unquote_identifier(
        if raw_source.to_lower().has_prefix("src=") {
          raw_source[4:].to_owned()
        } else {
          raw_source
        },
      )
      let uri = if source.has_prefix("data:") {
        source
      } else {
        resources
        .get(source)
        .unwrap_or_else(() => {
          raise SyntaxError(1, "image resource not provided: " + source)
        })
      }
      guard uri.has_prefix("data:") else {
        raise SyntaxError(
          1,
          "image resource must contain a data URI: " + source,
        )
      }
      let uri = uri
        .replace_all(old="\"", new="%22")
        .replace_all(old="'", new="%27")
        .replace_all(old="<", new="%3C")
        .replace_all(old=">", new="%3E")
      output.write_string("<img:" + uri + options + ">")
      ignore(cursor.restore(cursor.offset() + end + 1))
      continue
    }
    if cursor.advance() is Some(char) {
      output.write_char(char)
    }
  }
  output.to_string()
}
