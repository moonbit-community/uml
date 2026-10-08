///|
/// StateDiagramFactory shares CommandCreateMap/Json with entity diagrams.
/// Reuse that command implementation, retaining this parser's declaration scope.
fn Parser::consume_state_embedded(
  self : Parser,
  line : String,
) -> Bool raise @tokenizer.ParseError {
  let lower = line.to_lower()
  let named_note = lower.has_prefix("note as ") || lower.has_prefix("note \"")
  guard lower.has_prefix("map ") || lower.has_prefix("json ") || named_note else {
    return false
  }
  let start = self.buffer.index
  let parser = {
    ..EntityParser::new("", allow_mixing=true),
    buffer: self.buffer,
  }
  // Map entries may link to a state already declared in the current scope.
  for state in self.states {
    let qualified = parser.append_synthetic_entity(
      state.code,
      state.display,
      @entity.Class,
    )
    if state.parent == self.parent() {
      let short = state.code.split(".").last().unwrap().to_owned()
      parser.entity_code_indices[short] = parser
        .entity_index(qualified)
        .unwrap()
    }
  }
  if self.parent() is Some(parent) {
    parser.package_stack.push(parent)
  }
  parser.parse_line(line)
  let code = if named_note {
    parser.notes.last().unwrap().target
  } else {
    parser.last_entity.unwrap()
  }
  while parser.current_entity is Some(_) {
    self.buffer.advance()
    guard !self.buffer.at_end() else {
      raise SyntaxError(self.line_number(), "unclosed state map/JSON")
    }
    parser.parse_line(self.buffer.current())
  }
  let entity = parser.entities[parser.entity_index(code).unwrap()]
  let entity = if named_note {
    let note = parser.notes.last().unwrap()
    {
      ..entity,
      tags: note.tags,
      stereotype: note.stereotype,
      url: note.url,
      color: note.color,
    }
  } else {
    entity
  }
  let name = self.resolve_state_name(entity.code, allow_current=false)
  guard self.state_names[name].code is None else {
    raise SyntaxError(self.line_number(), "map/JSON/note already exists")
  }
  let location = self.state_name_location(
    name,
    entity.code,
    create_parents=true,
  )
  self.check_state_reference(location.code)
  let note : @flow.StateNote? = if named_note {
    let value = parser.notes.last().unwrap()
    Some({
      target: @flow.StateNote(location.code),
      parent: location.parent,
      region_index: location.region_index,
      text_mode: if lower.has_prefix("note as ") {
        @flow.BlockText
      } else {
        @flow.InlineText
      },
      text: if lower.has_prefix("note as ") {
        state_note_block_text(
          self.buffer.lines[start + 1:self.buffer.index].to_owned(),
        )
      } else {
        value.text
      },
      color: value.color,
      position: None,
    })
  } else {
    None
  }
  self.upsert_state({
    code: location.code,
    display: entity.display,
    kind: @flow.Normal,
    parent: location.parent,
    region_index: location.region_index,
    description: None,
    embedded: if note is Some(_) {
      None
    } else {
      Some({ ..entity, qualified_code: location.code, })
    },
    standalone_note: note,
    tags: entity.tags,
    is_removed: false,
    is_hidden: false,
    stereotype: entity.stereotype,
    url: entity.url,
    color: entity.color,
  })
  self.queue_state_command(Focus(location.code))
  for relation in parser.relations {
    self.queue_state_command(
      Transition({
        source: entity.code,
        target: relation.right,
        source_port: relation.left_port,
        target_port: relation.right_port,
        direction: @flow.Automatic,
        length: (relation.raw_arrow.length() - 2).max(1),
        line_style: relation.line_style,
        has_cross_start: false,
        has_circle_end: false,
        label: relation.label,
      }),
    )
  }
  true
}
