///|
/// Normalize a PlantUML label while preserving its internal markup.
pub fn normalize_label(value : String) -> String? {
  let value = value.trim().to_owned()
  if value.length() == 0 {
    None
  } else {
    Some(value)
  }
}

///|
/// Normalize a PlantUML stereotype token.
pub fn normalize_stereotype(value : String) -> String? {
  let value = value.trim().to_owned()
  if value.has_prefix("<<") && value.has_suffix(">>") && value.length() > 4 {
    Some(value)
  } else {
    None
  }
}
