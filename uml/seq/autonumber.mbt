///|
struct NumberPart {
  value : Int32
  text : String
}

///|
pub struct DottedNumber {
  parts : Array[NumberPart]
  separators : Array[String]
}

///|
pub fn parse_autonumber_number(source : String) -> DottedNumber {
  let parts = []
  let separators = []
  let mut part = StringBuilder()
  let mut digits = true
  for char in source {
    let next_digits = char.is_ascii_digit()
    if next_digits != digits {
      let text = part.to_string()
      if digits {
        parts.push({ value: @string.parse_int(text) catch { _ => 0 }, text, })
      } else {
        separators.push(text)
      }
      part = StringBuilder()
      digits = next_digits
    }
    part.write_char(char)
  }
  let text = part.to_string()
  if digits {
    parts.push({ value: @string.parse_int(text) catch { _ => 0 }, text, })
  } else {
    separators.push(text)
  }
  { parts, separators, }
}

///|
fn DottedNumber::text(self : DottedNumber) -> String {
  let output = StringBuilder()
  for index, part in self.parts {
    output.write_string(part.text)
    if self.separators.get(index) is Some(separator) {
      output.write_string(separator)
    }
  }
  output.to_string()
}

///|
fn DottedNumber::increment(
  self : DottedNumber,
  index : Int32,
  increment : Int32,
  reset_tail~ : Bool = false,
) -> DottedNumber {
  let index = index.max(0).min(self.parts.length() - 1)
  let result = {
    ..self,
    parts: self.parts.mapi((position, part) => {
      if position == index || (reset_tail && position > index) {
        let value = if position == index { part.value + increment } else { 1 }
        { value, text: value.to_string(), }
      } else {
        part
      }
    }),
  }
  // Integer overflow historically turns the minus sign into a dotted-number
  // separator. Only that grammar-changing transition needs normalization.
  if result.parts.any(part => part.value < 0) {
    parse_autonumber_number(result.text())
  } else {
    result
  }
}

///|
pub struct AutonumberFormat {
  prefix : String
  suffix : String
  integer_zeros : Int32
  fractional_zeros : Int32
  group_size : Int32
}

///|
pub fn parse_autonumber_format(format : String) -> AutonumberFormat {
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
  {
    prefix: prefix.to_string(),
    suffix: suffix.to_string(),
    integer_zeros,
    fractional_zeros,
    group_size,
  }
}

///|
fn AutonumberFormat::render(
  self : AutonumberFormat,
  number : DottedNumber,
) -> String {
  let value = number.text()
  if !number.separators.is_empty() {
    return "<b>\{value}</b>"
  }
  let digits = "0".repeat((self.integer_zeros - value.length()).max(0)) + value
  let output = StringBuilder()
  output.write_string(self.prefix)
  for index, char in digits.to_array() {
    if self.group_size > 0 &&
      index > 0 &&
      (digits.length() - index) % self.group_size == 0 {
      output.write_char(',')
    }
    output.write_char(char)
  }
  if self.fractional_zeros > 0 {
    output.write_char('.')
    output.write_string("0".repeat(self.fractional_zeros))
  }
  output.write_string(self.suffix)
  output.to_string()
}

///|
pub(all) struct AutonumberState {
  mut enabled : Bool
  mut next : DottedNumber
  mut increment : Int32
  mut format : AutonumberFormat
}

///|
pub fn AutonumberState::new() -> AutonumberState {
  {
    enabled: false,
    next: parse_autonumber_number("1"),
    increment: 1,
    format: parse_autonumber_format("<b>0</b>"),
  }
}

///|
pub fn AutonumberState::apply(self : AutonumberState, event : Event) -> Unit {
  match event {
    Autonumber(config) => {
      self.enabled = true
      self.next = config.start.unwrap_or_else(() => parse_autonumber_number("1"))
      self.increment = config.increment.unwrap_or(1)
      self.format = config.format.unwrap_or_else(() => {
        parse_autonumber_format("<b>0</b>")
      })
    }
    AutonumberStop => self.enabled = false
    AutonumberResume(config) => {
      self.enabled = true
      self.increment = config.increment.unwrap_or(self.increment)
      if config.format is Some(format) {
        self.format = format
      }
    }
    AutonumberIncrement(position) => {
      let index = position.unwrap_or(self.next.parts.length() - 2)
      self.next = self.next.increment(index, 1, reset_tail=true)
    }
    _ => ()
  }
}

///|
pub fn AutonumberState::take(self : AutonumberState) -> String? {
  guard self.enabled else { return None }
  let value = self.next
  self.next = value.increment(value.parts.length() - 1, self.increment)
  Some(self.format.render(value))
}
