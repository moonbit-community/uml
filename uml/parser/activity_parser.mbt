///|
priv enum BlockKind {
  Conditional
  WhileLoop
  RepeatLoop
  ForkBlock
  SplitBlock
  SwitchBlock
  PartitionBlock
} derive(Eq)

///|
fn block_name(kind : BlockKind) -> String {
  match kind {
    Conditional => "if"
    WhileLoop => "while"
    RepeatLoop => "repeat"
    ForkBlock => "fork"
    SplitBlock => "split"
    SwitchBlock => "switch"
    PartitionBlock => "partition"
  }
}

///|
fn require_block(
  stack : Array[BlockKind],
  expected : BlockKind,
  line : Int,
  command : String,
) -> Unit raise @tokenizer.ParseError {
  guard stack.last() is Some(actual) && actual == expected else {
    raise SyntaxError(
      line,
      "\{command} without matching \{block_name(expected)}",
    )
  }
}

///|
fn pop_block(
  stack : Array[BlockKind],
  expected : BlockKind,
  line : Int,
  command : String,
) -> Unit raise @tokenizer.ParseError {
  require_block(stack, expected, line, command)
  let _ = stack.pop()
}

///|
fn command_text(line : String, prefix : String) -> String {
  let value = line[prefix.length():].trim().to_owned()
  if value.has_suffix(";") {
    value[:value.length() - 1].trim_end().to_owned()
  } else {
    value
  }
}

///|
fn parse_note(
  buffer : LineBuffer,
  start : Int,
) -> (String, Int) raise @tokenizer.ParseError {
  let mut index = start + 1
  guard @tokenizer.collect_lines_until(
      () => {
        guard index < buffer.lines.length() else { return None }
        let line = @tokenizer.strip_line_comment(buffer.lines[index])
          .trim()
          .to_owned()
        index += 1
        Some(line)
      },
      line => line.equal_ignore_ascii_case("end note"),
    )
    is Some(text) else {
    raise SyntaxError(start + 1, "unclosed note")
  }
  (text.join("\n"), index - 1)
}

///|
fn is_activity_arrow(line : String) -> Bool {
  line.has_prefix("->") ||
  (line.has_prefix("-[") && line.find("]->") is Some(_))
}

///|
/// Parse PlantUML's modern activity-diagram commands. The supported command
/// set follows `activitydiagram3.ActivityDiagramFactory3`; unsupported
/// commands are rejected rather than being silently treated as activities.
pub fn parse_activity(
  input : String,
) -> @flow.ActivityDiagram raise @tokenizer.ParseError {
  let buffer = LineBuffer::new(input)
  let nodes = []
  let stack = []
  let style = @style.DocumentStyle::empty()
  while !buffer.at_end() {
    let line_number = buffer.line_number()
    let (first, leading_color) = activity_control_color(buffer.current_clean())
    let line = activity_control_source(buffer, first)
    let lower = line.to_lower()
    let control = if lower.has_suffix(";") {
      lower[:lower.length() - 1].trim_end().to_owned()
    } else {
      lower
    }
    if line.length() == 0 ||
      lower == "@startuml" ||
      lower == "@enduml" ||
      lower == "@startactivity" ||
      lower == "@endactivity" ||
      @style.is_preprocessor_directive(line) {
      buffer.advance()
      continue
    }
    if lower == "<style>" {
      buffer.advance()
      guard @style.consume_style_body(() => buffer.take_next(), directive => {
        style.apply(directive)
      }) else {
        raise SyntaxError(line_number, "unclosed style")
      }
      continue
    }
    if consume_flow_document(buffer, style, line) {
      buffer.advance()
      continue
    }
    if state_skinparam_prefix(line) is Some(prefix) {
      buffer.consume_skinparam(style, buffer.length(), prefix~)
      continue
    }
    if @style.parse_style_directive(line) is Some(directive) {
      style.apply(directive)
      buffer.advance()
      continue
    }
    if lower.has_prefix("skinparam ") {
      buffer.advance()
      continue
    }
    if lower == "note" ||
      lower.has_prefix("note ") ||
      lower.has_prefix("note:") ||
      lower.has_prefix("floating note") {
      let (text, end) = if line.find(":") is Some(colon) {
        (line[colon + 1:].trim().to_owned(), buffer.index)
      } else {
        parse_note(buffer, buffer.index)
      }
      let header = line.split(":").nth(0).unwrap_or("").to_owned()
      let note_cursor = @tokenizer.Cursor::new(header)
      let floating = note_cursor.consume_literal("floating")
      note_cursor.skip_inline_spaces()
      ignore(note_cursor.consume_literal("note"))
      note_cursor.skip_inline_spaces()
      let side : @flow.ActivityNoteSide = if note_cursor.consume_literal(
          "right",
        ) {
        Right
      } else {
        ignore(note_cursor.consume_literal("left"))
        Left
      }
      note_cursor.skip_inline_spaces()
      let color = note_cursor.take_color_value()
      note_cursor.skip_inline_spaces()
      while note_cursor.take_tag_value() is Some(_) {
        note_cursor.skip_inline_spaces()
      }
      let stereotype = note_cursor.take_stereotype_value()
      if floating || color is Some(_) || stereotype is Some(_) {
        nodes.push(
          @flow.ActivityNode::StyledNote({
            text,
            side,
            floating,
            color,
            stereotype,
            style,
          }),
        )
      } else {
        nodes.push(@flow.ActivityNode::Note(text, side))
      }
      buffer.index = end + 1
      continue
    }
    if parse_activity_list(line, style) is Some(action) {
      nodes.push(action)
    } else if parse_activity_spot(line) is Some((text, color)) {
      nodes.push(@flow.Spot(text, color))
    } else if control == "start" ||
      lower.has_prefix("start <<") ||
      lower.has_prefix("start;") ||
      lower.has_prefix("start<<") {
      nodes.push(
        @flow.ActivityNode::Start(
          activity_command_stereotype(command_text(line, "start"), line_number),
        ),
      )
    } else if control == "stop" ||
      lower.has_prefix("stop <<") ||
      lower.has_prefix("stop;") ||
      lower.has_prefix("stop<<") {
      nodes.push(
        @flow.ActivityNode::Stop(
          activity_command_stereotype(command_text(line, "stop"), line_number),
        ),
      )
    } else if control == "end" ||
      lower.has_prefix("end <<") ||
      lower.has_prefix("end;") ||
      lower.has_prefix("end<<") {
      nodes.push(
        @flow.ActivityNode::End(
          activity_command_stereotype(command_text(line, "end"), line_number),
        ),
      )
    } else if lower == "break" || lower == "break;" {
      nodes.push(@flow.ActivityNode::Break)
    } else if control == "kill" || control == "detach" {
      nodes.push(@flow.ActivityNode::Kill)
    } else if lower.has_prefix("backward") ||
      (lower.has_prefix("(") && lower.contains("backward")) {
      guard stack.last() is Some(WhileLoop | RepeatLoop) else {
        raise SyntaxError(line_number, "backward without enclosing loop")
      }
      nodes.push(Backward(parse_activity_backward(buffer, line, style)))
    } else if line.has_prefix(":") ||
      line.has_prefix("<<") ||
      line.has_prefix("#") {
      nodes.push(parse_activity_action(buffer, style))
    } else if lower.has_prefix("if ") {
      stack.push(BlockKind::Conditional)
      nodes.push(
        If(
          parse_activity_decision(
            command_text(line, "if"),
            style,
            leading_color,
            "if",
          ),
        ),
      )
    } else if lower.has_prefix("elseif ") {
      require_block(stack, BlockKind::Conditional, line_number, "elseif")
      nodes.push(
        ElseIf(
          parse_activity_decision(
            command_text(line, "elseif"),
            style,
            leading_color,
            "elseif",
          ),
        ),
      )
    } else if lower == "else" || lower.has_prefix("else ") {
      require_block(stack, BlockKind::Conditional, line_number, "else")
      nodes.push(Else(command_text(line, "else")))
    } else if control == "endif" ||
      control == "end if" ||
      lower.has_prefix("endif ") ||
      lower.has_prefix("end if ") {
      pop_block(stack, BlockKind::Conditional, line_number, "endif")
      nodes.push(
        EndIf(
          parse_activity_decision(
            command_text(
              line,
              if lower.has_prefix("end if") {
                "end if"
              } else {
                "endif"
              },
            ),
            style,
            None,
            "endif",
          ),
        ),
      )
    } else if lower.has_prefix("while ") {
      stack.push(BlockKind::WhileLoop)
      nodes.push(
        While(
          parse_activity_decision(
            command_text(line, "while"),
            style,
            leading_color,
            "while",
          ),
        ),
      )
    } else if control == "endwhile" || lower.has_prefix("endwhile ") {
      pop_block(stack, BlockKind::WhileLoop, line_number, "endwhile")
      nodes.push(EndWhile(command_text(line, "endwhile")))
    } else if lower.has_prefix("repeat :") {
      stack.push(RepeatLoop)
      nodes.push(
        RepeatAction(
          parse_activity_single_action(
            line["repeat ".length():].to_owned(),
            style,
            line_number,
          ),
        ),
      )
    } else if control == "repeat" ||
      (lower.has_prefix("repeat ") && !lower.has_prefix("repeat while")) {
      stack.push(RepeatLoop)
      nodes.push(
        Repeat(
          parse_activity_decision(
            command_text(line, "repeat"),
            style,
            None,
            "repeat",
          ),
        ),
      )
    } else if lower.has_prefix("repeat while ") {
      pop_block(stack, RepeatLoop, line_number, "repeat while")
      nodes.push(
        RepeatWhile(
          parse_activity_decision(
            command_text(line, "repeat while"),
            style,
            leading_color,
            "repeat while",
          ),
        ),
      )
    } else if control == "split" || lower == "split;" {
      stack.push(SplitBlock)
      nodes.push(Split)
    } else if control == "split again" || lower == "split again;" {
      require_block(stack, SplitBlock, line_number, "split again")
      nodes.push(SplitAgain)
    } else if control == "end split" ||
      control == "endsplit" ||
      lower == "end split;" {
      pop_block(stack, SplitBlock, line_number, "end split")
      nodes.push(EndSplit)
    } else if control == "fork" ||
      lower.has_prefix("fork <<") ||
      lower.has_prefix("fork;") ||
      lower.has_prefix("fork<<") {
      stack.push(ForkBlock)
      nodes.push(
        Fork(
          activity_command_stereotype(command_text(line, "fork"), line_number),
        ),
      )
    } else if control == "fork again" {
      require_block(stack, ForkBlock, line_number, "fork again")
      nodes.push(ForkAgain)
    } else if parse_activity_fork_end(line) is Some((merge, label)) {
      pop_block(stack, ForkBlock, line_number, "end fork")
      nodes.push(if merge { EndMerge(None) } else { EndFork(label, None) })
    } else if lower.has_prefix("switch ") {
      stack.push(SwitchBlock)
      nodes.push(
        Switch(
          parse_activity_decision(
            command_text(line, "switch"),
            style,
            leading_color,
            "switch",
          ),
        ),
      )
    } else if lower.has_prefix("case ") {
      require_block(stack, SwitchBlock, line_number, "case")
      nodes.push(Case(command_text(line, "case")))
    } else if control == "endswitch" || lower.has_prefix("endswitch ") {
      pop_block(stack, SwitchBlock, line_number, "endswitch")
      nodes.push(
        EndSwitch(
          parse_activity_decision(
            command_text(line, "endswitch"),
            style,
            None,
            "endswitch",
          ),
        ),
      )
    } else if parse_activity_swimlane(line) is Some(lane) {
      nodes.push(Swimlane(lane))
    } else if parse_activity_group(line, style) is Some(group) {
      stack.push(PartitionBlock)
      nodes.push(Partition(group))
    } else if line == "}" ||
      ["end group", "endgroup", "group end", "groupend"].contains(control) {
      pop_block(stack, PartitionBlock, line_number, line)
      nodes.push(EndPartition)
    } else if lower.has_prefix("label ") {
      nodes.push(Label(command_text(line, "label")))
    } else if lower.has_prefix("goto ") {
      nodes.push(Goto(command_text(line, "goto")))
    } else if lower.has_prefix("link #") {
      nodes.push(Arrow("-[" + command_text(line, "link") + "]->"))
    } else if control == "nolink" {
      nodes.push(Arrow("-[hidden]->"))
    } else if is_activity_arrow(line) {
      nodes.push(Arrow(line))
    } else {
      raise SyntaxError(line_number, "unsupported activity command")
    }
    buffer.advance()
  }
  guard stack.is_empty() else {
    raise SyntaxError(
      buffer.length(),
      "unclosed \{block_name(stack.last().unwrap())}",
    )
  }
  { nodes, instructions: @flow.reduce(nodes), style, }
}

///|
fn activity_backward_link(value : String) -> @flow.ActivityEdgeLabel {
  let value = @flow.edge_label(value).text.unwrap_or("")
  if value.has_prefix("->") || value.has_prefix("-[") {
    @flow.arrow_label(value)
  } else {
    @flow.edge_label(value)
  }
}

///|
fn parse_activity_backward(
  buffer : LineBuffer,
  line : String,
  style : @style.DocumentStyle,
) -> @flow.ActivityBackward raise @tokenizer.ParseError {
  let keyword = line.to_lower().find("backward").unwrap()
  let incoming = activity_backward_link(line[:keyword].trim().to_owned())
  let first = line[keyword + "backward".length():].trim().to_owned()
  guard first.has_prefix(":") else {
    raise SyntaxError(buffer.line_number(), "backward activity needs ':'")
  }
  let lines = [first[1:].to_owned()]
  while !lines.last().unwrap().contains(";") {
    buffer.advance()
    guard !buffer.at_end() else {
      raise SyntaxError(buffer.line_number(), "unclosed backward activity")
    }
    lines.push(buffer.current_stripped())
  }
  let last = lines.length() - 1
  let ending = lines[last]
  let semicolon = ending.find(";").unwrap()
  let suffix = @tokenizer.Cursor::new(ending[semicolon + 1:].trim().to_owned())
  let stereotypes = StringBuilder()
  while suffix.take_stereotype_value() is Some(label) {
    stereotypes.write_string(label)
    suffix.skip_inline_spaces()
  }
  let outgoing = activity_backward_link(suffix.take_rest_trimmed())
  lines[last] = ending[:semicolon].to_owned()
  let stereotype = stereotypes.to_string()
  {
    action: {
      label: lines.join("\n").trim().to_owned(),
      stereotype: if stereotype.is_empty() {
        None
      } else {
        Some(stereotype)
      },
      box_style: None,
      style,
    },
    incoming,
    outgoing,
  }
}
