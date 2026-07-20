///|
/// A parsed PlantUML URL target with an optional display label.
pub struct UrlTarget {
  target : String
  label : String?
} derive(Eq, Debug)

///|

///|
pub fn normalize_url_target(value : String) -> String {
  let value = value.trim()
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value.to_owned()
  }
}

///|
pub fn parse_url_target(value : String) -> UrlTarget? {
  let value = value.trim()
  guard value.has_prefix("[[") && value.has_suffix("]]") else { return None }
  let content = value[2:value.length() - 2].trim().to_owned()
  let parts = content
    .split(" ")
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  guard parts.length() > 0 else { return None }
  let target = normalize_url_target(parts[0])
  guard target.length() > 0 else { return None }
  let label = if parts.length() > 1 { Some(parts[1:].join(" ")) } else { None }
  Some({ target, label })
}
