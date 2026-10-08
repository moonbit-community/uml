///|
fn stereotype_labels(source : String) -> Array[String] {
  let cursor = @tokenizer.Cursor::new(source)
  let labels = []
  while !cursor.is_eof() {
    cursor.skip_inline_spaces()
    guard cursor.take_stereotype_value() is Some(label) else { break }
    labels.push(label[2:label.length() - 2].trim().to_lower().to_owned())
  }
  labels
}

///|
/// Resolve each property independently. PlantUML StyleSignatures preserves
/// the first stereotype defining a property; later labels fill missing keys.
pub fn DocumentStyle::with_stereotypes(
  self : DocumentStyle,
  stereotypes : String?,
) -> DocumentStyle {
  guard stereotypes is Some(source) else { return self }
  let labels = stereotype_labels(source)
  guard !labels.is_empty() else { return self }
  let properties = self.properties.copy()
  let priorities : Map[String, Int] = Map([])
  for key, value in self.properties {
    guard key.find("<<") is Some(start) && key.has_suffix(">>") else {
      continue
    }
    let required = stereotype_labels(key[start:].to_owned())
    guard !required.is_empty() && required.all(label => labels.contains(label)) else {
      continue
    }
    let rank = labels.search_by(label => label == required[0]).unwrap()
    let name = key[:start].to_owned()
    let canonical = name.to_lower()
    guard priorities.get(canonical).map_or(true, previous => rank < previous) else {
      continue
    }
    priorities[canonical] = rank
    for existing, _ in self.properties {
      if existing.equal_ignore_ascii_case(name) {
        properties[existing] = value
      }
    }
    properties[name] = value
  }
  { ..self, properties, }
}
