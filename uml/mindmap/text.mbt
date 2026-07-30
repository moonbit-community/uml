///|
priv struct MindmapTextSpan {
  text : String
  strike : Bool
}

///|
fn parse_mindmap_text_line(line : String) -> Array[MindmapTextSpan] {
  let lower = line.to_lower()
  let spans = []
  let mut cursor = 0
  let mut strike = false
  while cursor < line.length() {
    let marker = if strike { "</s>" } else { "<s>" }
    let rest = lower[cursor:].to_owned()
    match rest.find(marker) {
      Some(relative_index) => {
        let index = cursor + relative_index
        if index > cursor {
          spans.push({ text: line[cursor:index].to_owned(), strike })
        }
        cursor = index + marker.length()
        strike = !strike
      }
      None => {
        spans.push({ text: line[cursor:].to_owned(), strike })
        cursor = line.length()
      }
    }
  }
  if spans.is_empty() {
    spans.push({ text: "", strike: false })
  }
  spans
}

///|
fn mindmap_visible_text(label : String) -> String {
  label
  .split("\n")
  .map(line => {
    parse_mindmap_text_line(line.to_owned()).map(span => span.text).join("")
  })
  .join("\n")
}
