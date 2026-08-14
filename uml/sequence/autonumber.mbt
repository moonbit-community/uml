///|
fn increment_autonumber_at(
  value : String,
  index : Int,
  increment : Int,
) -> String {
  let parts = value.split(".").to_array()
  guard parts.length() > 0 else { "\{increment}" }
  let index = index.max(0).min(parts.length() - 1)
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
fn increment_autonumber(value : String, increment : Int) -> String {
  let parts = value.split(".").to_array()
  increment_autonumber_at(value, parts.length() - 1, increment)
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
  increment_autonumber_at(value, index, increment)
}

///|
priv struct AutonumberState {
  mut enabled : Bool
  mut next : String
  mut increment : Int
  mut format : String?
}

///|
fn AutonumberState::new() -> AutonumberState {
  { enabled: false, next: "1", increment: 1, format: None }
}

///|
fn AutonumberState::apply(self : AutonumberState, event : Event) -> Unit {
  match event {
    Autonumber(config) => {
      self.enabled = true
      self.next = config.start.unwrap_or("1")
      self.increment = config.increment.unwrap_or(1)
      self.format = config.format
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
fn AutonumberState::take(self : AutonumberState) -> String? {
  guard self.enabled else { return None }
  let value = self.next
  self.next = increment_autonumber(self.next, self.increment)
  Some(self.format.map_or(value, format => format_autonumber(format, value)))
}
