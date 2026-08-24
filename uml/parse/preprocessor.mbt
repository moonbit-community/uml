///|
/// Minimal shared PlantUML preprocessor state for object-like define macros.
pub struct Preprocessor {
  definitions : Map[String, String]
}

///|
pub fn Preprocessor::new() -> Preprocessor {
  { definitions: Map([]) }
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
