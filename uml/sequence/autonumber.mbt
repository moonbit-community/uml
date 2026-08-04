///|
fn increment_autonumber(value : String, increment : Int) -> String {
  let parts = value.split(".").to_array()
  guard parts.length() > 0 else { "\{increment}" }
  let last_index = parts.length() - 1
  let last = parts[last_index].to_owned()
  let next = @string.parse_int(last) catch { _ => 0 }
  let output = StringBuilder()
  for index, part in parts {
    if index > 0 {
      output.write_char('.')
    }
    if index == last_index {
      output <+ "\{next + increment}"
    } else {
      output.write_string(part.to_owned())
    }
  }
  output.to_string()
}

///|
fn format_autonumber(format : String, value : String) -> String {
  if format.contains("#") {
    format.replace(old="#", new=value)
  } else {
    format.replace(old="0", new=value)
  }
}

///|
fn increment_autonumber_part(
  value : String,
  position : String?,
  increment : Int,
) -> String {
  let parts = value.split(".").to_array()
  guard parts.length() > 0 else {
    return increment_autonumber(value, increment)
  }
  let index = match position {
    Some(letter) if letter.length() > 0 => {
      let chars = letter.to_array()
      let value = chars[0].to_int() - 'a'.to_int()
      value.max(0).min(parts.length() - 1)
    }
    _ => parts.length() - 1
  }
  let output = StringBuilder()
  for part_index, part in parts {
    if part_index > 0 {
      output.write_char('.')
    }
    if part_index == index {
      let number = @string.parse_int(part) catch { _ => 0 }
      output <+ "\{number + increment}"
    } else {
      output.write_string(part.to_owned())
    }
  }
  output.to_string()
}

///|
