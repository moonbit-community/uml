///|
priv struct StructuredSource {
  data : String
  presentation : Array[(String, String)]
  styles : Array[@structured.StructuredStyleProperty]
  highlights : Array[@structured.StructuredHighlight]
}

///|
/// Extract the commands consumed by PlantUML's StyleExtractor before the
/// data parser sees them. Highlight paths belong to the record tree, not YAML.
fn structured_source(
  input : String,
  marker : String,
) -> StructuredSource raise @tokenizer.ParseError {
  let source = @tokenizer.splice_source_between_markers(
    @tokenizer.preprocess(input),
    "@start" + marker,
    end => end == "@end" + marker,
  )
  let data = []
  let presentation = []
  let styles : Array[@structured.StructuredStyleProperty] = []
  let highlights : Array[@structured.StructuredHighlight] = []
  let style_lines : Array[String] = []
  let mut in_style = false
  let mut in_skinparam = false
  for index, raw in source.split("\n") {
    let line = raw.trim().to_owned()
    if line == "<style>" {
      in_style = true
      continue
    }
    if in_style {
      style_lines.push(raw.to_owned())
      if line != "</style>" {
        continue
      }
      let mut style_index = 0
      let closed = @style.consume_style_body(
        () => {
          guard style_index < style_lines.length() else { return None }
          let value = style_lines[style_index]
          style_index += 1
          Some(value)
        },
        directive => {
          match directive {
            Property(key, value) if key.has_prefix("style ") => {
              let words = @tokenizer.syntax_words(key[6:].to_owned())
              guard !words.is_empty() else { return }
              styles.push({
                selector: words[:words.length() - 1].to_owned().join(" "),
                name: words[words.length() - 1],
                value,
              })
            }
            BackgroundColor(value) =>
              presentation.push(("skinparam BackgroundColor", value))
            FontFamily(value) =>
              presentation.push(("skinparam DefaultFontName", value))
            FontSize(value) =>
              presentation.push(("skinparam DefaultFontSize", value))
            Property(key, value) =>
              presentation.push(("skinparam " + key, value))
            _ => ()
          }
        },
      )
      guard closed else {
        raise @tokenizer.SyntaxError(
          index + 1,
          "unclosed structured style selector",
        )
      }
      style_lines.clear()
      in_style = false
      continue
    }
    if raw.has_prefix("#highlight ") {
      let value = line[11:].trim().to_owned()
      let (path, stereotype) = mindmap_ending_stereotype(value)
      highlights.push({
        path: path
        .split("/")
        .map(part => part.trim().trim(chars="\"").to_owned())
        .to_array(),
        stereotype,
      })
      continue
    }
    if in_skinparam {
      if line == "}" {
        in_skinparam = false
      }
      continue
    }
    if data.is_empty() && !(marker == "toml" && line.contains("=")) {
      if line.is_empty() {
        continue
      }
      if line.has_prefix("title ") &&
        (marker != "toml" || !line[6:].trim_start().has_prefix("=")) {
        presentation.push(("title", line[6:].trim().to_owned()))
        continue
      }
      if line.has_prefix("scale ") {
        presentation.push(("scale", line[6:].trim().to_owned()))
        continue
      }
      if line.has_prefix("skinparam ") {
        in_skinparam = line.contains("{")
        continue
      }
      if line.has_prefix("!assume ") ||
        line.has_prefix("!pragma ") ||
        line.has_prefix("hide ") {
        continue
      }
      if line.has_prefix("skin ") {
        presentation.push(("skin", line[5:].trim().to_owned()))
        continue
      }
    }
    if marker == "json" && line.has_prefix("#") {
      continue
    }
    data.push(raw.to_owned())
  }
  guard !in_style else {
    raise @tokenizer.SyntaxError(1, "unclosed structured style block")
  }
  { data: data.join("\n"), presentation, styles, highlights, }
}
