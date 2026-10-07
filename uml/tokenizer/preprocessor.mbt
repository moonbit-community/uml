///|
/// Shared textual preprocessing. Resources are supplied by the caller so a
/// pure-string render never performs implicit filesystem or network access.
pub struct Preprocessor {
  mut variables : Map[String, PreValue]
  globals : Map[String, PreValue]
  definitions : Map[String, PreMacro]
  subparts : Map[String, Array[String]]
  resources : Map[String, String]
  included : Map[String, Unit]
  include_stack : Array[String]
  mut line : Int
}

///|
pub struct PreMacro {
  parameters : Array[(String, String?)]
  body : Array[String]
  function : Bool
  legacy : Bool
}

///|
priv struct PreConditional {
  parent : Bool
  taken : Bool
  active : Bool
}

///|
pub fn Preprocessor::new() -> Preprocessor {
  {
    variables: Map([]),
    globals: Map([]),
    definitions: Map([]),
    subparts: Map([]),
    resources: Map([]),
    included: Map([]),
    include_stack: [],
    line: 1,
  }
}

///|
pub fn preprocess_checked(
  input : String,
  resources? : Map[String, String] = Map([]),
) -> String raise ParseError {
  let preprocessor = { ..Preprocessor::new(), resources: resources.copy(), }
  let processed = preprocessor.process(
    preprocess_comments(input).split("\n").map(StringView::to_owned).to_array(),
  )
  let lines = extract_sprite_resources(processed, preprocessor.resources)
  lines
  .map(line => expand_inline_media(line, preprocessor.resources))
  .join("\n")
}

///|
/// Diagram detectors and non-throwing parser constructors retain their
/// existing signature. The public parse API uses preprocess_checked first;
/// direct parsers receive an explicit invalid directive on failure.
pub fn preprocess(input : String) -> String {
  preprocess_checked(input) catch {
    SyntaxError(line, message) =>
      "\n".repeat((line - 1).max(0)) + "@preprocessor_error " + message
  }
}

///|
fn preprocess_comments(input : String) -> String raise ParseError {
  let cursor = Cursor::new(input)
  let output = StringBuilder()
  let mut block = false
  let mut quote : Char? = None
  let mut comment = false
  let mut first = true
  let mut directive = false
  let mut line = 1
  let mut block_start = 1
  while !cursor.is_eof() {
    if block {
      if cursor.consume_literal("'/") {
        block = false
      } else if cursor.advance() == Some('\n') {
        output.write_char('\n')
        line += 1
        first = true
      }
    } else if quote is None && !comment && cursor.consume_literal("/'") {
      block = true
      block_start = line
    } else {
      let char = cursor.advance().unwrap()
      if first && !char.is_whitespace() {
        directive = char == '!'
        first = false
      }
      if quote is Some(q) {
        if char == '\\' {
          output.write_char(char)
          if cursor.advance() is Some(escaped) {
            output.write_char(escaped)
          }
          continue
        }
        if char == q {
          quote = None
        }
      } else if !comment && (char == '"' || (directive && char == '\'')) {
        quote = Some(char)
      } else if char == '\'' && !directive {
        comment = true
      }
      if char == '\n' {
        quote = None
        comment = false
        first = true
        directive = false
        line += 1
      }
      output.write_char(char)
    }
  }
  guard !block else { raise SyntaxError(block_start, "unclosed block comment") }
  output.to_string()
}

///|
fn pre_marker(line : String) -> String {
  let trimmed = line.trim().to_owned()
  for
    marker in [
      "@startuml", "@startmindmap", "@startwbs", "@startjson", "@startyaml", "@starttoml",
      "@startdot",
    ] {
    let lower = trimmed.to_lower()
    if lower == marker ||
      lower.has_prefix(marker + " ") ||
      lower.has_prefix(marker + "\t") {
      // The mbti extension stores its dispatch marker in an apostrophe comment.
      if marker == "@startuml" &&
        trimmed
        .find("'")
        .map_or(false, offset => trimmed[offset + 1:].trim() == ".mbti") {
        return "@startuml '.mbti"
      }
      return marker
    }
  }
  line
}

///|
fn Preprocessor::process(
  self : Preprocessor,
  lines : Array[String],
) -> Array[String] raise ParseError {
  let output : Array[String] = []
  let conditions : Array[PreConditional] = []
  let mut index = 0
  while index < lines.length() {
    self.line = index + 1
    let raw = lines[index]
    let line = raw.trim().to_owned()
    let lower = line.to_lower()
    let active = conditions.last().map_or(true, condition => condition.active)
    let words = syntax_words(line)
    let command = words.get(0).unwrap_or("").to_lower()
    if lower.has_prefix("sprite ") {
      output.push(if active { raw } else { "" })
      if line.has_suffix("{") {
        let start = self.line
        index += 1
        while index < lines.length() && lines[index].trim() != "}" {
          output.push(if active { lines[index] } else { "" })
          index += 1
        }
        guard index < lines.length() else {
          raise SyntaxError(start, "unclosed sprite")
        }
        output.push(if active { lines[index] } else { "" })
      }
    } else if command == "!if" || command == "!ifdef" || command == "!ifndef" {
      let expression = line[command.length():].trim().to_owned()
      let matched = if !active {
        false
      } else if command == "!if" {
        pre_truth(self.evaluate(expression))
      } else {
        let exists = self.variables.contains(expression) ||
          self.definitions.contains(expression)
        if command == "!ifndef" {
          !exists
        } else {
          exists
        }
      }
      conditions.push({
        parent: active,
        taken: matched,
        active: active && matched,
      })
      output.push("")
    } else if command == "!elseif" || command == "!else" {
      guard conditions.last() is Some(previous) else {
        raise SyntaxError(self.line, "unexpected " + command)
      }
      let matched = previous.parent &&
        !previous.taken &&
        (
          command == "!else" ||
          pre_truth(self.evaluate(line[command.length():].trim().to_owned()))
        )
      conditions[conditions.length() - 1] = {
        ..previous,
        active: matched,
        taken: previous.taken || matched,
      }
      output.push("")
    } else if command == "!endif" {
      guard !conditions.is_empty() else {
        raise SyntaxError(self.line, "unexpected !endif")
      }
      ignore(conditions.pop())
      output.push("")
    } else if command == "!define" ||
      command == "!definelong" ||
      command == "!procedure" ||
      command == "!function" ||
      command == "!unquoted" {
      let declaration = if command == "!unquoted" {
        line["!unquoted".length():].trim_start().to_owned()
      } else {
        line[1:].to_owned()
      }
      let kind = declaration.split(" ").nth(0).unwrap_or("").to_owned()
      let rest = declaration[kind.length():].trim_start().to_owned()
      let (name, parameters, suffix) = pre_macro_signature(rest)
      let body : Array[String] = []
      if kind == "define" {
        body.push(suffix)
      } else if suffix.has_prefix("!return ") {
        body.push(suffix)
      } else {
        let ending = if kind == "definelong" {
          "!enddefinelong"
        } else if kind == "function" {
          "!endfunction"
        } else {
          "!endprocedure"
        }
        let start = self.line
        index += 1
        while index < lines.length() &&
              !lines[index].trim().equal_ignore_ascii_case(ending) {
          body.push(lines[index])
          output.push("")
          index += 1
        }
        guard index < lines.length() else {
          raise SyntaxError(start, "unclosed " + kind)
        }
      }
      if active {
        self.definitions[name] = {
          parameters,
          body,
          function: kind == "function",
          legacy: kind == "define" || kind == "definelong",
        }
      }
      output.push("")
    } else if command == "!foreach" || command == "!while" {
      let ending = if command == "!foreach" { "!endfor" } else { "!endwhile" }
      let start = index
      let mut nesting = 1
      let body : Array[String] = []
      index += 1
      while index < lines.length() {
        let nested = lines[index].trim().to_lower()
        if nested.has_prefix(command + " ") {
          nesting += 1
        }
        if nested == ending {
          nesting -= 1
        }
        if nesting == 0 {
          break
        }
        body.push(lines[index])
        index += 1
      }
      guard index < lines.length() else {
        raise SyntaxError(start + 1, "unclosed " + command)
      }
      if active {
        let expression = line[command.length():].trim().to_owned()
        if command == "!foreach" {
          guard expression.find(" in ") is Some(split) else {
            raise SyntaxError(
              start + 1,
              "expected foreach variable in collection",
            )
          }
          let name = expression[:split].trim().to_owned()
          let values = self.evaluate(expression[split + 4:].trim().to_owned())
          guard values is Array(values) else {
            raise SyntaxError(start + 1, "foreach needs an array")
          }
          let saved = self.variables.get(name)
          for value in values {
            self.variables[name] = value
            output.append(self.process(body))
          }
          match saved {
            Some(value) => self.variables[name] = value
            None => self.variables.remove(name)
          }
        } else {
          while pre_truth(self.evaluate(expression)) {
            output.append(self.process(body))
          }
        }
      }
      for _ in start..<=index {
        output.push("")
      }
    } else if !active {
      output.push("")
    } else if line.has_prefix("'") {
      output.push(raw)
    } else if command == "!undef" {
      if words.get(1) is Some(name) {
        self.variables.remove(name)
        self.definitions.remove(name)
      }
      output.push("")
    } else if command == "!theme" {
      guard words.get(1) is Some(name) else {
        raise SyntaxError(self.line, "missing theme name")
      }
      let theme = if words.get(2) == Some("from") {
        let location = words[3:].join(" ")
        self.resources.get(location + "/puml-theme-" + name + ".puml")
      } else {
        builtin_theme_source(name)
      }
      guard theme is Some(theme) else {
        raise SyntaxError(self.line, "unknown or unavailable theme: " + name)
      }
      self.variables["$THEME"] = String(name)
      output.append(
        self.process(theme.split("\n").map(StringView::to_owned).to_array()),
      )
    } else if command == "!include" ||
      command == "!include_once" ||
      command == "!include_many" {
      let name = unquote_identifier(
        self.expand(line[command.length():].trim().to_owned()),
      )
      if command == "!include_once" && self.included.contains(name) {
        raise SyntaxError(self.line, "resource already included: " + name)
      }
      if command == "!include" && self.included.contains(name) {
        output.push("")
      } else {
        guard !self.include_stack.contains(name) else {
          raise SyntaxError(self.line, "recursive include: " + name)
        }
        guard self.resources.get(name) is Some(source) else {
          raise SyntaxError(
            self.line,
            "include resource was not supplied: " + name,
          )
        }
        self.included[name] = ()
        self.include_stack.push(name)
        output.append(
          self.process(
            preprocess_comments(source)
            .split("\n")
            .map(StringView::to_owned)
            .to_array(),
          ),
        )
        ignore(self.include_stack.pop())
      }
    } else if command == "!error" || command == "!assert" {
      let rest = line[command.length():].trim().to_owned()
      if command == "!error" || !pre_truth(self.evaluate(rest)) {
        raise SyntaxError(self.line, "preprocessor " + rest)
      }
      output.push("")
    } else if line.has_prefix("!") &&
      line.contains("=") &&
      !lower.has_prefix("!pragma ") {
      let split = line.find("=").unwrap()
      let name = line[1:split].trim().to_owned()
      let global = name.has_prefix("global ")
      let name = if name.has_prefix("global ") {
        name[7:].trim().to_owned()
      } else if name.has_prefix("local ") {
        name[6:].trim().to_owned()
      } else {
        name
      }
      let conditional = name.has_suffix("?")
      let name = name.trim_end(chars="?").trim().to_owned()
      let mut expression = line[split + 1:].trim().to_owned()
      let mut balance = pre_bracket_balance(expression)
      while balance > 0 && index + 1 < lines.length() {
        index += 1
        expression += " " + lines[index].trim().to_owned()
        balance = pre_bracket_balance(expression)
        output.push("")
      }
      if !conditional || !self.variables.contains(name) {
        let value = self.evaluate(expression)
        self.variables[name] = value
        if global {
          self.globals[name] = value
        }
      }
      output.push("")
    } else if command == "!return" {
      let value = self.evaluate(line[command.length():].trim().to_owned())
      self.variables["<return>"] = value
      output.push(pre_text(value))
      return output
    } else if command == "!startsub" {
      guard words.get(1) is Some(name) else {
        raise SyntaxError(self.line, "missing subpart name")
      }
      self.subparts[name] = pre_subpart(lines, name).unwrap_or([])
      output.push("")
    } else if command == "!includesub" {
      let name = self.expand(line[command.length():].trim().to_owned())
      let body = match name.find("!") {
        Some(split) =>
          self.resources
          .get(name[:split].to_owned())
          .bind(source => {
            pre_subpart(
              source.split("\n").map(StringView::to_owned).to_array(),
              name[split + 1:].to_owned(),
            )
          })
        None => self.subparts.get(name)
      }
      guard body is Some(body) else {
        raise SyntaxError(self.line, "unknown include subpart: " + name)
      }
      output.append(self.process(body))
    } else if command == "!endsub" || command == "!log" {
      output.push("")
    } else {
      let marker = pre_marker(raw)
      if marker.trim().has_prefix("@start") {
        output.push(marker)
      } else {
        output.push(self.expand(raw))
      }
    }
    index += 1
  }
  guard conditions.is_empty() else {
    raise SyntaxError(self.line, "unclosed !if")
  }
  output
}

///|
fn pre_bracket_balance(text : String) -> Int {
  let cursor = Cursor::new(text)
  let mut quote : Char? = None
  let mut balance = 0
  while cursor.advance() is Some(char) {
    if quote is Some(q) {
      if char == '\\' {
        ignore(cursor.advance())
      } else if char == q {
        quote = None
      }
    } else if char == '\'' || char == '"' {
      quote = Some(char)
    } else if char == '[' || char == '{' {
      balance += 1
    } else if char == ']' || char == '}' {
      balance -= 1
    }
  }
  balance
}

///|
fn pre_macro_signature(
  text : String,
) -> (String, Array[(String, String?)], String) {
  let cursor = Cursor::new(text)
  let name = cursor.take_while(pre_identifier)
  let parameters : Array[(String, String?)] = []
  if cursor.consume('(') {
    while !cursor.is_eof() && !cursor.consume(')') {
      cursor.skip_inline_spaces()
      let name = cursor.take_while(pre_identifier)
      cursor.skip_inline_spaces()
      let default = if cursor.consume('=') {
        Some(
          cursor
          .take_while(char => char != ',' && char != ')')
          .trim()
          .to_owned(),
        )
      } else {
        None
      }
      parameters.push((name, default))
      cursor.skip_inline_spaces()
      ignore(cursor.consume(','))
    }
  }
  (name, parameters, cursor.take_rest_trimmed())
}

///|
fn Preprocessor::expand(
  self : Preprocessor,
  line : String,
) -> String raise ParseError {
  let source = strip_line_comment_preserving_indent(line)
  let cursor = Cursor::new(source)
  let output = StringBuilder()
  while !cursor.is_eof() {
    let offset = cursor.offset()
    let name = cursor.take_while(pre_identifier)
    if !name.is_empty() {
      if self.variables.contains(name) {
        ignore(cursor.restore(offset))
        let value = PreExpression::{ cursor, preprocessor: self, }.atom()
        output.write_string(pre_text(value))
      } else if (self.definitions.contains(name) || name.has_prefix("%")) &&
        cursor.consume('(') {
        let args = PreExpression::{ cursor, preprocessor: self, }.arguments()
        output.write_string(pre_text(self.call_value(name, args)))
      } else if self.definitions.get(name) is Some(definition) &&
        definition.parameters.is_empty() {
        output.write_string(pre_text(self.call_value(name, [])))
      } else {
        output.write_string(name)
      }
    } else {
      output.write_char(cursor.advance().unwrap())
    }
  }
  output.write_string(line[source.length():].to_owned())
  output.to_string()
}

///|
fn Preprocessor::call_value(
  self : Preprocessor,
  name : String,
  args : Array[PreValue],
) -> PreValue raise ParseError {
  if self.definitions.get(name) is Some(definition) {
    let saved = self.variables.copy()
    for index, parameter in definition.parameters {
      let (parameter, default) = parameter
      self.variables[parameter] = match args.get(index) {
        Some(value) => value
        None =>
          match default {
            Some(expression) => self.evaluate(expression)
            None =>
              raise SyntaxError(self.line, "missing argument: " + parameter)
          }
      }
    }
    let result = if definition.legacy {
      definition.body.map(line => self.expand(line)).join("\n")
    } else {
      self.process(definition.body).filter(line => !line.is_empty()).join("\n")
    }
    let returned = if definition.function {
      self.variables.get("<return>").unwrap_or(Null)
    } else {
      String(result)
    }
    self.variables = saved
    for name, value in self.globals {
      self.variables[name] = value
    }
    return returned
  }
  self.call_builtin(name, args)
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

///|
fn pre_subpart(lines : Array[String], name : String) -> Array[String]? {
  let output : Array[String] = []
  let mut depth = 0
  for line in lines {
    let trimmed = line.trim().to_owned()
    if trimmed == "!startsub " + name && depth == 0 {
      depth = 1
      continue
    }
    if depth > 0 {
      if trimmed.has_prefix("!startsub ") {
        depth += 1
      }
      if trimmed == "!endsub" {
        depth -= 1
      }
      if depth == 0 {
        return Some(output)
      }
      output.push(line)
    }
  }
  None
}
