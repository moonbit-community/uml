///|
priv struct RawIdea {
  marker : String
  level : Int32
  direction : @tree.TreeDirection?
  shape : @tree.IdeaShape
  background_color : String?
  label : String
  multiline : Bool
}

///|
fn mindmap_marker_end(line : String) -> Int32 {
  let cursor = @tokenizer.Cursor::new(line)
  ignore(cursor.skip_inline_whitespace())
  ignore(
    cursor.skip_while(char => {
      char == '*' || char == '#' || char == '+' || char == '-'
    }),
  )
  cursor.offset()
}

///|
fn marker_is_valid(marker : String) -> Bool {
  let is_marker = (char : Char) => {
    char == '*' || char == '#' || char == '+' || char == '-'
  }
  marker.any(is_marker) &&
  marker.all(char => is_marker(char) || char == ' ' || char == '\t')
}

///|
fn marker_count(marker : String) -> Int32 {
  let cursor = @tokenizer.Cursor::new(marker)
  let mut count = 0
  while cursor.advance() is Some(char) {
    if char == '*' || char == '#' {
      count += 1
    }
  }
  count
}

///|
fn parse_color_and_shape(rest : String) -> (String?, @tree.IdeaShape, String) {
  let (color, remainder) = if rest.has_prefix("[") {
    match rest.find("]") {
      Some(end) => {
        let candidate = rest[1:end].to_owned()
        if candidate.has_prefix("#") {
          (Some(candidate), rest[end + 1:].to_owned())
        } else {
          (None, rest)
        }
      }
      None => (None, rest)
    }
  } else {
    (None, rest)
  }
  if remainder.has_prefix("_") {
    (color, @tree.IdeaShape::Boxless, remainder[1:].trim_start().to_owned())
  } else {
    (color, @tree.IdeaShape::Box, remainder.trim_start().to_owned())
  }
}

///|
fn parse_raw_idea(line : String) -> RawIdea? {
  let trimmed = line.trim().to_owned()
  if trimmed.has_prefix("0") {
    return Some({
      marker: "0",
      level: 0,
      direction: Some(@tree.TreeDirection::Right),
      shape: @tree.IdeaShape::Box,
      background_color: None,
      label: trimmed[1:].trim_start().to_owned(),
      multiline: false,
    })
  }
  let end = mindmap_marker_end(line)
  guard end > 0 else { return None }
  let marker = line[:end].to_owned()
  guard marker_is_valid(marker) else { return None }
  let remainder = line[end:].to_owned()
  let (color, shape, label) = parse_color_and_shape(remainder)
  let is_org = marker.contains("*") || marker.contains("#")
  let is_plus = marker.contains("+") || marker.contains("-")
  guard is_org != is_plus else { return None }
  if is_plus {
    let cursor = @tokenizer.Cursor::new(marker)
    ignore(cursor.skip_inline_whitespace())
    let level = cursor.skip_while(char => char == '+' || char == '-') - 1
    return Some({
      marker,
      level,
      direction: Some(
        if marker.contains("-") {
          @tree.TreeDirection::Left
        } else {
          @tree.TreeDirection::Right
        },
      ),
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
) -> (Int32, String?) raise @tokenizer.ParseError {
  let initial = first.unwrap_or(marker)
  let normalized = if marker.has_suffix("**") {
    marker.replace_all(old="\t", new=" ").trim().to_owned()
  } else {
    marker.replace_all(old="\t", new=" ")
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
fn mindmap_ending_stereotype(label : String) -> (String, String?) {
  let value = label.trim_end().to_owned()
  guard value.has_suffix(">>") else { return (value, None) }
  value
  .rev_find("<<")
  .map_or((value, None), index => {
    (value[:index].trim_end().to_owned(), Some(value[index:].to_owned()))
  })
}

///|
fn complete_multiline_label(
  lines : Array[String],
  index : Int32,
  first : String,
) -> (String, Int32, String?) raise @tokenizer.ParseError {
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
  ideas : Array[@tree.Idea],
  direction : @tree.TreeDirection,
  level : Int32,
) -> Int32? raise @tokenizer.ParseError {
  for index in (ideas.length() - 1)>=..0 {
    let candidate = ideas[index]
    if candidate.level == level - 1 &&
      (candidate.level == 0 || candidate.direction == direction) {
      return Some(index)
    }
  }
  raise SyntaxError(0, "invalid mindmap indentation")
}

///|
fn parse_mindmap_style_block(
  lines : Array[String],
  start : Int32,
  style : @tree.MindmapStyle,
  properties : Array[@tree.WbsStyleProperty],
  document : @style.DocumentStyle,
) -> Int32 raise @tokenizer.ParseError {
  let mut index = start + 1
  let closed = @style.consume_style_body(
    () => {
      guard index < lines.length() else { return None }
      let line = lines[index]
      index += 1
      Some(line)
    },
    directive => {
      match directive {
        Property(key, value) if key.has_prefix("style ") => {
          let words = @tokenizer.syntax_words(key[6:].to_owned())
          guard words is [.., name] else { return }
          let selector = words[:words.length() - 1].to_owned().join(" ")
          properties.push({ selector, name, value, })
          if words.length() > 1 &&
            words[words.length() - 2].equal_ignore_ascii_case("arrow") &&
            words[:words.length() - 1].all(word => {
              let word = word.to_lower()
              word == "root" ||
              word == "element" ||
              word == "mindmapdiagram" ||
              word == "arrow"
            }) {
            style.apply_arrow_property(name, value)
          }
        }
        _ => document.apply(directive)
      }
    },
  )
  guard closed else {
    raise SyntaxError(start + 1, "unclosed mindmap style block")
  }
  index
}

///|
/// Parse a PlantUML mindmap source. Both org-mode (`*`/`#`) and plus/minus
/// syntax are accepted, including colors, boxless items, stereotypes, and
/// org-mode multiline labels.
pub fn parse_mindmap(
  input : String,
) -> @tree.MindmapDiagram raise @tokenizer.ParseError {
  let lines = @tokenizer.preprocess(input)
    .split("\n")
    .map(StringView::to_owned)
    .to_array()
  let ideas = []
  let style = @style.DocumentStyle::empty()
  let mindmap_style = @tree.TreeStyle::default(@tree.TreeDiagramFamily::Mindmap)
  let style_properties = []
  let mut index = 0
  let mut multiplier : Int32? = None
  let mut org_first : String? = None
  let mut default_direction : @tree.TreeDirection = @tree.TreeDirection::Right
  while index < lines.length() {
    let line = @tokenizer.strip_line_comment(lines[index])
    let trimmed = line.trim().to_owned()
    if trimmed.length() == 0 ||
      trimmed.equal_ignore_ascii_case("@startmindmap") ||
      trimmed.equal_ignore_ascii_case("@endmindmap") ||
      trimmed.equal_ignore_ascii_case("@startuml") ||
      trimmed.equal_ignore_ascii_case("@enduml") ||
      @style.is_preprocessor_directive(trimmed) {
      index += 1
      continue
    }
    if trimmed.to_lower().has_prefix("skinparam ") && trimmed.has_suffix("{") {
      let prefix = trimmed[10:trimmed.length() - 1].trim().to_owned()
      index += 1
      let closed = @style.consume_skinparam_body(
        () => {
          guard index < lines.length() else { return None }
          let line = lines[index]
          index += 1
          Some(line)
        },
        directive => {
          style.apply(directive)
          mindmap_style.apply_skinparam(directive)
        },
        prefix~,
      )
      guard closed else {
        raise SyntaxError(lines.length(), "unclosed skinparam")
      }
      continue
    }
    if trimmed.equal_ignore_ascii_case("<style>") {
      index = parse_mindmap_style_block(
        lines, index, mindmap_style, style_properties, style,
      )
      continue
    }
    let buffer : LineBuffer = { lines, index, }
    if buffer.consume_style_block(
        trimmed,
        style,
        skinparam_error_line=lines.length(),
      ) {
      index = buffer.index
      continue
    }
    if @style.parse_style_directive(trimmed) is Some(directive) {
      style.apply(directive)
      mindmap_style.apply_skinparam(directive)
      index += 1
      continue
    }
    let lower = trimmed.to_lower()
    if lower.contains("left side") ||
      lower.contains("left direction") ||
      lower.contains("top side") ||
      lower.contains("top direction") {
      default_direction = @tree.TreeDirection::Left
      index += 1
      continue
    }
    if lower.contains("right side") ||
      lower.contains("right direction") ||
      lower.contains("bottom side") ||
      lower.contains("bottom direction") {
      default_direction = @tree.TreeDirection::Right
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
      complete_multiline_label(lines, index, raw.label)
    } else {
      let (text, stereotype) = mindmap_ending_stereotype(raw.label)
      (text, index, stereotype)
    }
    let parent : Int32? = if normalized_level == 0 {
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
  { ideas, style, mindmap_style, style_properties, }
}
