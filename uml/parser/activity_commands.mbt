///|
/// CommandCircleSpot3: a single non-whitespace character is a flow node.
fn parse_activity_spot(line : String) -> (String, String?)? {
  let cursor = @tokenizer.Cursor::new(line)
  let color = if cursor.consume('#') {
    let value = cursor.take_while(char => char != ':' && !char.is_whitespace())
    guard !value.is_empty() && cursor.consume(':') else { return None }
    Some(value)
  } else {
    None
  }
  cursor.skip_inline_spaces()
  guard cursor.consume('(') else { return None }
  let text = cursor.take_while(char => char != ')')
  guard text.to_array().length() == 1 &&
    !text.to_array()[0].is_whitespace() &&
    cursor.consume(')') else {
    return None
  }
  ignore(cursor.consume(';'))
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else { return None }
  Some((text, color))
}

///|
fn parse_activity_swimlane(line : String) -> @flow.ActivitySwimlane? {
  let cursor = @tokenizer.Cursor::new(line)
  let bars = cursor.consume('|')
  if !bars {
    guard line.to_lower().has_prefix("swimlane ") else { return None }
    ignore(cursor.restore("swimlane ".length()))
  }
  cursor.skip_inline_spaces()
  let color = if bars && cursor.peek() == Some('#') {
    let value = cursor.take_while(char => char != '|')
    guard cursor.consume('|') else { return None }
    Some(value)
  } else {
    cursor.take_color_value()
  }
  cursor.skip_inline_spaces()
  let (name, label) = if bars {
    let name = cursor.take_while(char => char != '|').trim().to_owned()
    guard cursor.consume('|') else { return None }
    let label = cursor.take_rest_trimmed()
    guard !label.contains("|") else { return None }
    (name, label)
  } else {
    let value = cursor.take_rest_trimmed()
    match @tokenizer.find_unquoted_literal(value, " as ") {
      Some(index) =>
        (value[:index].trim().to_owned(), value[index + 4:].trim().to_owned())
      None => (value, "")
    }
  }
  guard !name.is_empty() else { return None }
  Some({
    name,
    label: if label.is_empty() {
      None
    } else {
      Some(label)
    },
    color,
  })
}

///|
/// CommandPartition3 maps each spelling to a distinct container symbol.
fn parse_activity_group(
  line : String,
  style : @style.DocumentStyle,
) -> @flow.ActivityGroup? {
  let cursor = @tokenizer.Cursor::new(line)
  let symbol = cursor.take_while(char => !char.is_whitespace()).to_lower()
  guard ["partition", "package", "rectangle", "card", "group"].contains(symbol) else {
    return None
  }
  cursor.skip_inline_spaces()
  let leading_color = cursor.take_color_value()
  cursor.skip_inline_spaces()
  let label = cursor
    .take_quoted_value()
    .unwrap_or_else(() => {
      cursor
      .take_while(char => char != '#' && char != '<' && char != '{')
      .trim()
      .to_owned()
    })
  cursor.skip_inline_spaces()
  let trailing_color = cursor.take_color_value()
  cursor.skip_inline_spaces()
  let stereotype = cursor.take_stereotype_value()
  cursor.skip_inline_spaces()
  ignore(cursor.consume('{'))
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else { return None }
  Some({
    label,
    symbol,
    color: leading_color.map_or(trailing_color, value => Some(value)),
    stereotype,
    style,
  })
}

///|
/// Normalize the command spellings before the semantic reducer splits edge
/// labels. Parenthesized conditions and labels may span source lines.
fn activity_control_source(
  buffer : LineBuffer,
  first : String,
) -> String raise @tokenizer.ParseError {
  let mut line = first
  let lower = first.to_lower()
  for spelling in ["end while", "while end", "whileend"] {
    if lower == spelling ||
      lower.has_prefix(spelling + " ") ||
      lower.has_prefix(spelling + "(") ||
      lower == spelling + ";" {
      line = "endwhile " + first[spelling.length():].trim().to_owned()
      break
    }
  }
  if lower.has_prefix("else if") {
    line = "elseif" + first[7:].to_owned()
  }
  let control = [
    "if", "elseif", "while", "repeat while", "switch", "case", "else",
  ].any(keyword => {
    lower.has_prefix(keyword + "(") || lower.has_prefix(keyword + " ")
  })
  if control {
    while @tokenizer.unquoted_delimiter_delta(line, '(', ')') > 0 {
      buffer.advance()
      guard !buffer.at_end() else {
        raise SyntaxError(buffer.line_number(), "unclosed activity condition")
      }
      line += "\n" + buffer.current_stripped()
    }
    for
      keyword in [
        "repeat while", "elseif", "while", "switch", "case", "else", "if",
      ] {
      if line.to_lower().has_prefix(keyword + "(") {
        line = keyword + " " + line[keyword.length():].to_owned()
        break
      }
    }
  }
  if is_activity_arrow(line) && !line.has_suffix(";") && !line.has_suffix(">") {
    while !line.has_suffix(";") {
      buffer.advance()
      guard !buffer.at_end() else {
        raise SyntaxError(buffer.line_number(), "unclosed activity arrow label")
      }
      line += "\n" + buffer.current_stripped()
    }
  }
  line
}

///|
fn parse_activity_list(
  line : String,
  style : @style.DocumentStyle,
) -> @flow.ActivityNode? {
  guard (line.has_prefix("-") || line.has_prefix("*")) &&
    !is_activity_arrow(line) else {
    return None
  }
  let body = line[1:].trim().to_owned()
  let (label, stereotype) = match @tokenizer.find_unquoted_literal(body, "<<") {
    Some(index) => {
      guard activity_action_tail(body[index:].to_owned()) is Some(stereotype) else {
        return None
      }
      (body[:index].trim_end().to_owned(), Some(stereotype))
    }
    None => (body, None)
  }
  if stereotype is None {
    Some(@flow.Action(label))
  } else {
    Some(
      @flow.StyledAction({ label, stereotype, style, box_style: Some("plain"), }),
    )
  }
}

///|
fn parse_activity_fork_end(line : String) -> (Bool, String?)? {
  let cursor = @tokenizer.Cursor::new(line)
  let command = cursor
    .take_while(char => char != '{' && char != ';')
    .to_lower()
    .replace_all(old=" ", new="")
    .replace_all(old="\t", new="")
  guard ["endfork", "forkend", "endmerge"].contains(command) else {
    return None
  }
  let label = if cursor.consume('{') {
    let text = cursor.take_while(char => char != '}')
    guard !text.is_empty() && cursor.consume('}') else { return None }
    Some("{" + text + "}")
  } else {
    None
  }
  ignore(cursor.consume(';'))
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else { return None }
  Some((command == "endmerge", label))
}

///|
fn activity_control_color(line : String) -> (String, String?) {
  guard line.has_prefix("#") && line.find(":") is Some(colon) else {
    return (line, None)
  }
  let rest = line[colon + 1:].trim_start().to_owned()
  guard ["if", "elseif", "while", "repeat", "switch"].any(keyword => {
    rest.has_prefix(keyword + " ") || rest.has_prefix(keyword + "(")
  }) else {
    return (line, None)
  }
  (rest, Some(line[1:colon].to_owned()))
}

///|
fn parse_activity_decision(
  value : String,
  style : @style.DocumentStyle,
  leading_color : String?,
  command : String,
) -> @flow.ActivityDecision {
  let (text, stereotype) = match @tokenizer.find_unquoted_literal(value, "<<") {
    Some(index) => {
      let text = value[:index].trim_end().to_owned()
      let text = if text.has_suffix(";") {
        text[:text.length() - 1].trim_end().to_owned()
      } else {
        text
      }
      (text, Some(value[index:].to_owned()))
    }
    None => (value, None)
  }
  // CommandIf4 applies the old leading color; CommandIf2 and CommandWhile3
  // intentionally ignore it and use the trailing stereogroup colors instead.
  let color = if command == "if" &&
    text.has_suffix(" then") &&
    (
      text.contains(" is ") ||
      text.contains(" equal ") ||
      text.contains(" equals ")
    ) {
    leading_color
  } else {
    None
  }
  { text, stereotype, color, style, }
}

///|
fn activity_command_stereotype(
  value : String,
  line : Int,
) -> String? raise @tokenizer.ParseError {
  let value = value.trim_start(chars="; ").to_owned()
  if value.is_empty() {
    return None
  }
  guard activity_action_tail(value) is Some(stereotype) else {
    raise SyntaxError(line, "invalid activity stereotype suffix")
  }
  Some(stereotype)
}
