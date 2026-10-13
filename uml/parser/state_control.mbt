///|
fn Parser::consume_state_control(self : Parser, line : String) -> Bool {
  if line.to_lower() == "hide footbox" || line.to_lower() == "show footbox" {
    return true
  }
  let cursor = @tokenizer.Cursor::new(line)
  let command = cursor
    .take_while(char => char.is_ascii_alphabetic() || char == '-')
    .to_lower()
  if ["remove", "restore", "hide", "show", "hide-class", "show-class"].contains(
      command,
    ) {
    guard cursor.skip_inline_whitespace() > 0 else { return false }
    let value = cursor.take_rest_trimmed()
    guard !value.is_empty() &&
      value != "empty description" &&
      value != "footbox" else {
      return false
    }
    // CucaDiagram.fixWhat qualifies the rule at its declaration scope.
    let rules = if command == "remove" || command == "restore" {
      self.removals
    } else {
      self.hides
    }
    rules.push(
      (
        self.parent().map_or(value, parent => parent + "." + value),
        command == "restore" || command.has_prefix("show"),
      ),
    )
    return true
  }
  false
}

///|
fn state_pattern_matches(name : String, pattern : String) -> Bool {
  let name = name.to_array()
  let pattern = pattern.to_array()
  let mut index = 0
  let mut token = 0
  let mut star = -1
  let mut restart = 0
  while index < name.length() {
    if token < pattern.length() && pattern[token] == name[index] {
      index += 1
      token += 1
    } else if token < pattern.length() && pattern[token] == '*' {
      star = token
      token += 1
      restart = index
    } else if star >= 0 {
      restart += 1
      index = restart
      token = star + 1
    } else {
      return false
    }
  }
  while token < pattern.length() && pattern[token] == '*' {
    token += 1
  }
  token == pattern.length()
}

///|
fn Parser::state_rule_value(
  self : Parser,
  state : @flow.StateNode,
  rules : Array[(String, Bool)],
  include_unlinked~ : Bool = true,
) -> Bool {
  let mut removed = false
  for (pattern, show) in rules {
    let matches = if pattern.has_prefix("$") {
      state.tags.any(tag => state_pattern_matches(tag, pattern[1:].to_owned()))
    } else if pattern.has_prefix("<<") && pattern.has_suffix(">>") {
      let query = pattern[2:pattern.length() - 2].trim().to_owned()
      let cursor = @tokenizer.Cursor::new(state.stereotype.unwrap_or(""))
      let mut matches = false
      while cursor.take_stereotype_value() is Some(label) {
        if state_pattern_matches(
            label[2:label.length() - 2].trim().to_owned(),
            query,
          ) {
          matches = true
        }
        cursor.skip_inline_spaces()
      }
      matches
    } else if pattern.to_lower() == "@unlinked" {
      include_unlinked && self.state_is_unlinked(state)
    } else {
      state_pattern_matches(state.code, @tokenizer.unquote_identifier(pattern))
    }
    if matches {
      removed = !show
    }
  }
  removed
}

///|
fn Parser::apply_state_removals(self : Parser) -> Unit {
  for index, state in self.states {
    self.states[index] = {
      ..state,
      is_removed: self.state_rule_value(state, self.removals),
      is_hidden: self.state_rule_value(state, self.hides),
    }
  }
}

///|
/// Entity.isAloneAndUnlinked excludes invisible links and neighbors removed by
/// non-@unlinked rules; composite states delegate the question to their children.
fn Parser::state_is_unlinked(self : Parser, state : @flow.StateNode) -> Bool {
  let children = self.states.filter(child => child.parent == Some(state.code))
  if !children.is_empty() {
    return children.all(child => self.state_is_unlinked(child))
  }
  for edge in self.transitions {
    let other = if edge.source == state.code {
      Some(edge.target)
    } else if edge.target == state.code {
      Some(edge.source)
    } else {
      None
    }
    guard other is Some(code) else { continue }
    if edge.line_style.map_or(false, value => {
        value.split(",").any(token => token.trim().to_lower() == "hidden")
      }) {
      continue
    }
    if self.states.search_by(node => node.code == code) is Some(index) &&
      !self.state_rule_value(
        self.states[index],
        self.removals,
        include_unlinked=false,
      ) {
      return false
    }
  }
  !self.notes.any(note => note.target == @flow.StateNote(state.code))
}
