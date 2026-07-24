///|
priv struct RawIdea {
  marker : String
  level : Int
  direction : Direction?
  shape : IdeaShape
  background_color : String?
  label : String
  multiline : Bool
}

///|
fn marker_end(line : String) -> Int {
  let chars = line.to_array()
  let mut index = 0
  while index < chars.length() && (chars[index] == ' ' || chars[index] == '\t') {
    index += 1
  }
  while index < chars.length() &&
        (
          chars[index] == '*' ||
          chars[index] == '#' ||
          chars[index] == '+' ||
          chars[index] == '-'
        ) {
    index += 1
  }
  index
}

///|
fn marker_is_valid(marker : String) -> Bool {
  let chars = marker.to_array()
  let mut found = false
  for char in chars {
    if char == '*' || char == '#' || char == '+' || char == '-' {
      found = true
    } else if char != ' ' && char != '\t' {
      return false
    }
  }
  found
}

///|
fn marker_count(marker : String) -> Int {
  marker.to_array().filter(char => char == '*' || char == '#').length()
}

///|
fn parse_color_and_shape(rest : String) -> (String?, IdeaShape, String) {
  let value = rest.trim().to_owned()
  let (color, remainder) = if value.has_prefix("[") {
    match value.find("]") {
      Some(end) => {
        let candidate = value[1:end].to_owned()
        if candidate.has_prefix("#") {
          (Some(candidate), value[end + 1:].to_owned())
        } else {
          (None, value)
        }
      }
      None => (None, value)
    }
  } else {
    (None, value)
  }
  let remainder = remainder.trim().to_owned()
  if remainder.has_prefix("_") {
    (color, None, remainder[1:].trim_start().to_owned())
  } else {
    (color, Box, remainder)
  }
}

///|
fn parse_raw_idea(line : String) -> RawIdea? {
  let trimmed = line.trim().to_owned()
  if trimmed.has_prefix("0") {
    return Some({
      marker: "0",
      level: 0,
      direction: Some(Right),
      shape: Box,
      background_color: None,
      label: trimmed[1:].trim_start().to_owned(),
      multiline: false,
    })
  }
  let end = marker_end(line)
  guard end > 0 else { return None }
  let marker = line[:end].to_owned()
  guard marker_is_valid(marker) else { return None }
  let remainder = line[end:].to_owned()
  let (color, shape, label) = parse_color_and_shape(remainder)
  let chars = marker.to_array()
  let is_org = chars.any(char => char == '*' || char == '#')
  let is_plus = chars.any(char => char == '+' || char == '-')
  guard is_org != is_plus else { return None }
  if is_plus {
    let level = chars.filter(char => char == '+' || char == '-').length() - 1
    return Some({
      marker,
      level,
      direction: Some(if chars.any(char => char == '-') { Left } else { Right }),
      shape,
      background_color: color,
      label,
      multiline: false,
    })
  }
  let multiline = label.has_prefix(":")
  Some({
    marker,
    level: marker_count(marker) - 1,
    direction: None,
    shape,
    background_color: color,
    label: if multiline {
      label[1:].trim_start().to_owned()
    } else {
      label
    },
    multiline,
  })
}

///|
fn smart_level(
  marker : String,
  first : String?,
) -> (Int, String?) raise @core.ParseError {
  let initial = first.unwrap_or(marker)
  let normalized = if marker.has_suffix("**") {
    marker.replace(old="\t", new=" ").trim().to_owned()
  } else {
    marker.replace(old="\t", new=" ")
  }
  if !normalized.contains(" ") {
    return (marker_count(normalized) - 1, Some(initial))
  }
  if normalized.has_suffix(initial) || normalized.has_prefix(initial) {
    return (marker_count(normalized) - marker_count(initial), Some(initial))
  }
  if marker_count(normalized.trim().to_owned()) == 1 {
    return (marker_count(normalized) - 1, Some(initial))
  }
  raise SyntaxError(0, "unsupported org-mode indentation")
}

///|
fn ending_stereotype(label : String) -> (String, String?) {
  let value = label.trim_end().to_owned()
  guard value.has_suffix(">>") else { return (value, None) }
  match value.rev_find("<<") {
    Some(index) =>
      (value[:index].trim_end().to_owned(), Some(value[index:].to_owned()))
    None => (value, None)
  }
}

///|
fn complete_multiline_label(
  lines : Array[String],
  index : Int,
  first : String,
) -> (String, Int, String?) raise @core.ParseError {
  let values = [first]
  let mut last = index
  while !values.last().unwrap_or("").contains(";") {
    last += 1
    guard last < lines.length() else {
      raise SyntaxError(index + 1, "unclosed mindmap item")
    }
    values.push(lines[last])
  }
  let text = values.join("\n")
  let semicolon = text.rev_find(";").unwrap_or(text.length())
  let label = text[:semicolon].trim_end().to_owned()
  let suffix = text[semicolon + 1:].trim().to_owned()
  let stereotype : String? = if suffix.length() == 0 {
    None
  } else {
    Some(suffix)
  }
  (label, last, stereotype)
}

///|
fn parent_for(
  ideas : Array[Idea],
  direction : Direction,
  level : Int,
) -> Int? raise @core.ParseError {
  let mut index = ideas.length() - 1
  while index >= 0 {
    let candidate = ideas[index]
    if candidate.level == level - 1 &&
      (candidate.level == 0 || candidate.direction == direction) {
      return Some(index)
    }
    index -= 1
  }
  raise SyntaxError(0, "invalid mindmap indentation")
}

///|
fn parse_mindmap_style_block(
  lines : Array[String],
  start : Int,
  style : MindmapStyle,
) -> Int raise @core.ParseError {
  let mut index = start + 1
  let mut selector : String? = None
  while index < lines.length() {
    let line = @core.strip_line_comment(lines[index]).trim().to_owned()
    if line.equal_ignore_ascii_case("</style>") {
      return index + 1
    }
    if line.length() == 0 {
      index += 1
      continue
    }
    if line.has_suffix("{") {
      selector = Some(line[:line.length() - 1].trim().to_owned())
      index += 1
      continue
    }
    if line == "}" {
      selector = None
      index += 1
      continue
    }
    match selector {
      Some(current) => {
        let words = @core.syntax_words(line)
        if words.length() >= 2 {
          let key = words[0]
          let value = words[1:].to_owned().join(" ")
          if current.trim().equal_ignore_ascii_case("arrow") {
            style.apply_arrow_property(key, value)
          } else {
            style.apply_node_property(current, key, value)
          }
        }
      }
      None => ()
    }
    index += 1
  }
  raise SyntaxError(start + 1, "unclosed mindmap style block")
}

///|
/// Parse a PlantUML mindmap source. Both org-mode (`*`/`#`) and plus/minus
/// syntax are accepted, including colors, boxless items, stereotypes, and
/// org-mode multiline labels.
pub fn parse(input : String) -> MindmapDiagram raise @core.ParseError {
  let lines = @core.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array()
  let ideas = []
  let style = @core.DocumentStyle::empty()
  let mindmap_style = MindmapStyle::default()
  let mut index = 0
  let mut multiplier : Int? = None
  let mut org_first : String? = None
  let mut default_direction : Direction = Right
  while index < lines.length() {
    let line = @core.strip_line_comment(lines[index])
    let trimmed = line.trim().to_owned()
    if trimmed.length() == 0 ||
      trimmed.equal_ignore_ascii_case("@startmindmap") ||
      trimmed.equal_ignore_ascii_case("@endmindmap") ||
      trimmed.equal_ignore_ascii_case("@startuml") ||
      trimmed.equal_ignore_ascii_case("@enduml") ||
      @core.is_preprocessor_directive(trimmed) {
      index += 1
      continue
    }
    if trimmed.equal_ignore_ascii_case("<style>") {
      index = parse_mindmap_style_block(lines, index, mindmap_style)
      continue
    }
    match @core.parse_style_directive(trimmed) {
      Some(directive) => {
        style.apply(directive)
        mindmap_style.apply_skinparam(directive)
        index += 1
        continue
      }
      None => ()
    }
    let lower = trimmed.to_lower()
    if lower.contains("left side") || lower.contains("left direction") {
      default_direction = Left
      index += 1
      continue
    }
    if lower.contains("right side") || lower.contains("right direction") {
      default_direction = Right
      index += 1
      continue
    }
    guard parse_raw_idea(line) is Some(raw) else {
      raise SyntaxError(index + 1, "invalid mindmap item")
    }
    let (raw_level, next_org_first) = if raw.direction is Some(_) {
      (raw.level, org_first)
    } else {
      smart_level(raw.marker, org_first) catch {
        SyntaxError(_, message) => raise SyntaxError(index + 1, message)
      }
    }
    org_first = next_org_first
    let level = if ideas.is_empty() { 0 } else { raw_level }
    if level > 0 {
      match multiplier {
        None => multiplier = Some(level)
        Some(unit) if level % unit != 0 =>
          raise SyntaxError(index + 1, "bad mindmap indentation")
        _ => ()
      }
    }
    let normalized_level = match multiplier {
      Some(unit) if level > 0 => level / unit
      _ => level
    }
    let direction = raw.direction.unwrap_or(default_direction)
    let (label, last, stereotype) = if raw.multiline {
      let result = complete_multiline_label(lines, index, raw.label)
      result
    } else {
      let (text, stereotype) = ending_stereotype(raw.label)
      (text, index, stereotype)
    }
    let parent : Int? = if normalized_level == 0 {
      None
    } else {
      parent_for(ideas, direction, normalized_level) catch {
        SyntaxError(_, message) => raise SyntaxError(index + 1, message)
      }
    }
    ideas.push({
      label,
      level: normalized_level,
      direction,
      shape: raw.shape,
      background_color: raw.background_color,
      stereotype,
      parent,
    })
    index = last + 1
  }
  { ideas, style, mindmap_style }
}
