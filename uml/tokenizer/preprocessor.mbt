///|
/// Minimal shared PlantUML preprocessor state for object-like define macros.
pub struct Preprocessor {
  definitions : Map[String, String]
}

///|
pub fn Preprocessor::new() -> Preprocessor {
  { definitions: Map([]), }
}

///|
fn words(line : String) -> Array[String] {
  line
  .split(" ")
  .map(part => part.trim().to_owned())
  .filter(part => part.length() > 0)
  .to_array()
}

///|
fn Preprocessor::define_line(self : Preprocessor, line : String) -> Bool {
  let parts = words(line)
  guard parts.length() >= 3 && parts[0] == "!define" else { return false }
  self.definitions[parts[1]] = parts[2:].join(" ")
  true
}

///|
fn Preprocessor::expand_line(self : Preprocessor, line : String) -> String {
  line
  .split(" ")
  .map(part => {
    let token = part.to_owned()
    self.definitions.get(token).unwrap_or(token)
  })
  .to_array()
  .join(" ")
}

///|
/// Expand object-like macros while preserving the source line count.
pub fn preprocess(input : String) -> String {
  let preprocessor = Preprocessor::new()
  let output = StringBuilder()
  let lines = input.split("\n").map(StringView::to_owned).to_array()
  for index, line in lines {
    if !preprocessor.define_line(line) {
      output.write_string(preprocessor.expand_line(line))
    }
    if index < lines.length() - 1 {
      output.write_char('\n')
    }
  }
  output.to_string()
}

///|
/// Splice the source between PlantUML `@startX` and its closing marker lines.
///
/// When the start marker is absent the input is returned verbatim; otherwise
/// the marker lines and any content before the start or after the end marker
/// are dropped. `is_end` decides whether a marker line closes the block, so
/// callers can accept several end spellings (`@enduml` plus a format-specific
/// `@endX`). Shared by the structured (json/yaml/toml) and dot source
/// extractors; do not re-implement the marker scan locally.
pub fn splice_source_between_markers(
  input : String,
  start_marker : String,
  is_end : (String) -> Bool,
) -> String {
  let output = StringBuilder()
  let mut inside_markers = false
  let mut has_markers = false
  for line in input.split("\n") {
    let marker = line.trim().to_lower().to_owned()
    if marker == start_marker {
      has_markers = true
      inside_markers = true
    } else if is_end(marker) && inside_markers {
      inside_markers = false
    } else if !has_markers || inside_markers {
      output.write_string(line.to_owned())
      output.write_char('\n')
    }
  }
  guard has_markers else { input }
  output.to_string()
}
