///|
fn autonumber_parts(value : String) -> (Array[String], Array[String]) {
  let numbers : Array[String] = []
  let separators : Array[String] = []
  let mut part = StringBuilder()
  let mut digits = true
  for char in value {
    let next_digits = char.is_ascii_digit()
    if next_digits != digits {
      if digits {
        numbers.push(part.to_string())
      } else {
        separators.push(part.to_string())
      }
      part = StringBuilder()
      digits = next_digits
    }
    part.write_char(char)
  }
  if digits {
    numbers.push(part.to_string())
  } else {
    separators.push(part.to_string())
  }
  (numbers, separators)
}

///|
fn join_autonumber(
  numbers : Array[String],
  separators : Array[String],
) -> String {
  let output = StringBuilder()
  for index, number in numbers {
    output.write_string(number)
    if separators.get(index) is Some(separator) {
      output.write_string(separator)
    }
  }
  output.to_string()
}

///|
pub fn increment_autonumber_at(
  value : String,
  index : Int32,
  increment : Int32,
) -> String {
  let (numbers, separators) = autonumber_parts(value)
  guard numbers.length() > 0 else { return increment.to_string() }
  let index = index.max(0).min(numbers.length() - 1)
  numbers[index] = ((@string.parse_int(numbers[index]) catch { _ => 0 }) +
  increment).to_string()
  join_autonumber(numbers, separators)
}

///|
pub fn increment_autonumber(value : String, increment : Int32) -> String {
  increment_autonumber_at(
    value,
    autonumber_parts(value).0.length() - 1,
    increment,
  )
}

///|
pub fn format_autonumber(format : String, value : String) -> String {
  // DottedNumber uses its own bold representation for multipart numbers.
  if !autonumber_parts(value).1.is_empty() {
    return "<b>\{value}</b>"
  }
  let prefix = StringBuilder()
  let suffix = StringBuilder()
  let pattern : Array[Char] = []
  let mut quoted = false
  let mut numeric = false
  let mut ended = false
  for char in format {
    if char == '\'' {
      quoted = !quoted
    } else if !quoted &&
      !ended &&
      (char == '#' || char == '0' || (numeric && (char == ',' || char == '.'))) {
      numeric = true
      pattern.push(char)
    } else {
      if !quoted && char == ';' {
        break
      }
      if numeric {
        ended = true
        suffix.write_char(char)
      } else {
        prefix.write_char(char)
      }
    }
  }
  let mut integer_zeros = 0
  let mut fractional_zeros = 0
  let mut fraction = false
  let mut group_size = 0
  let mut grouped = false
  for char in pattern {
    if char == '.' {
      fraction = true
    } else if char == ',' {
      grouped = true
      group_size = 0
    } else if fraction {
      if char == '0' {
        fractional_zeros += 1
      }
    } else {
      if char == '0' {
        integer_zeros += 1
      }
      if grouped {
        group_size += 1
      }
    }
  }
  let padding = StringBuilder()
  for _ in 0..<(integer_zeros - value.length()).max(0) {
    padding.write_char('0')
  }
  let digits = padding.to_string() + value
  let number = StringBuilder()
  for index, char in digits.to_array() {
    if group_size > 0 &&
      index > 0 &&
      (digits.length() - index) % group_size == 0 {
      number.write_char(',')
    }
    number.write_char(char)
  }
  if fractional_zeros > 0 {
    number.write_char('.')
    for _ in 0..<fractional_zeros {
      number.write_char('0')
    }
  }
  prefix.to_string() + number.to_string() + suffix.to_string()
}

///|
pub fn increment_autonumber_part(
  value : String,
  position : String?,
  _increment : Int32,
) -> String {
  let (parts, separators) = autonumber_parts(value)
  guard parts.length() > 0 else { return increment_autonumber(value, 1) }
  let index = match position {
    Some(letter) if letter.length() > 0 => {
      let chars = letter.to_lower().to_array()
      let value = chars[0].to_int() - 'a'.to_int()
      value.max(0).min(parts.length() - 1)
    }
    _ => (parts.length() - 2).max(0)
  }
  let incremented = parts.mapi((position, part) => {
    if position > index {
      "1"
    } else if position == index {
      ((@string.parse_int(part) catch { _ => 0 }) + 1).to_string()
    } else {
      part
    }
  })
  join_autonumber(incremented, separators)
}

///|
pub(all) struct AutonumberState {
  mut enabled : Bool
  mut next : String
  mut increment : Int32
  mut format : String?
}

///|
pub fn AutonumberState::new() -> AutonumberState {
  { enabled: false, next: "1", increment: 1, format: Some("<b>0</b>"), }
}

///|
pub fn AutonumberState::apply(self : AutonumberState, event : Event) -> Unit {
  match event {
    Autonumber(config) => {
      self.enabled = true
      self.next = config.start.unwrap_or("1")
      self.increment = config.increment.unwrap_or(1)
      self.format = Some(config.format.unwrap_or("<b>0</b>"))
    }
    AutonumberStop => self.enabled = false
    AutonumberResume(config) => {
      self.enabled = true
      self.increment = config.increment.unwrap_or(self.increment)
      if config.format is Some(format) {
        self.format = Some(format)
      }
    }
    AutonumberIncrement(position) =>
      self.next = increment_autonumber_part(self.next, position, self.increment)
    _ => ()
  }
}

///|
pub fn AutonumberState::take(self : AutonumberState) -> String? {
  guard self.enabled else { return None }
  let value = self.next
  self.next = increment_autonumber(self.next, self.increment)
  Some(self.format.map_or(value, format => format_autonumber(format, value)))
}
