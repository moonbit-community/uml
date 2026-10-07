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
  line[prefix.length():].trim().to_owned()
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
    let line = buffer.current_clean()
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
    if lower == "note" || lower.has_prefix("note ") || lower.has_prefix("note:") {
      let (text, end) = if line.find(":") is Some(colon) {
        (line[colon + 1:].trim().to_owned(), buffer.index)
      } else {
        parse_note(buffer, buffer.index)
      }
      let side : @flow.ActivityNoteSide = if lower.has_prefix("note right") {
        Right
      } else {
        Left
      }
      nodes.push(@flow.ActivityNode::Note(text, side))
      buffer.index = end + 1
      continue
    }
    if control == "start" {
      nodes.push(@flow.ActivityNode::Start)
    } else if control == "stop" {
      nodes.push(@flow.ActivityNode::Stop)
    } else if control == "end" {
      nodes.push(@flow.ActivityNode::End)
    } else if lower == "break" || lower == "break;" {
      nodes.push(@flow.ActivityNode::Break)
    } else if control == "kill" {
      nodes.push(@flow.ActivityNode::Kill)
    } else if lower.has_prefix("backward") ||
      (lower.has_prefix("(") && lower.contains("backward")) {
      guard stack.last() is Some(WhileLoop | RepeatLoop) else {
        raise SyntaxError(line_number, "backward without enclosing loop")
      }
      nodes.push(Backward(parse_activity_backward(buffer, line)))
    } else if line.has_prefix(":") {
      let lines = [line[1:].to_owned()]
      while !lines.last().unwrap().trim_end().has_suffix(";") {
        buffer.advance()
        guard !buffer.at_end() else {
          raise SyntaxError(line_number, "unclosed activity")
        }
        lines.push(buffer.current_stripped())
      }
      let last = lines.length() - 1
      let ending = lines[last].trim_end().to_owned()
      lines[last] = ending[:ending.length() - 1].to_owned()
      nodes.push(@flow.ActivityNode::Action(lines.join("\n").trim().to_owned()))
    } else if lower.has_prefix("if ") {
      stack.push(BlockKind::Conditional)
      nodes.push(If(command_text(line, "if")))
    } else if lower.has_prefix("elseif ") {
      require_block(stack, BlockKind::Conditional, line_number, "elseif")
      nodes.push(ElseIf(command_text(line, "elseif")))
    } else if lower == "else" || lower.has_prefix("else ") {
      require_block(stack, BlockKind::Conditional, line_number, "else")
      nodes.push(Else(command_text(line, "else")))
    } else if lower == "endif" {
      pop_block(stack, BlockKind::Conditional, line_number, "endif")
      nodes.push(EndIf)
    } else if lower.has_prefix("while ") {
      stack.push(BlockKind::WhileLoop)
      nodes.push(While(command_text(line, "while")))
    } else if lower == "endwhile" || lower.has_prefix("endwhile ") {
      pop_block(stack, BlockKind::WhileLoop, line_number, "endwhile")
      nodes.push(EndWhile(command_text(line, "endwhile")))
    } else if lower.has_prefix("repeat :") && line.has_suffix(";") {
      stack.push(RepeatLoop)
      nodes.push(
        RepeatAction(
          line["repeat :".length():line.length() - 1].trim().to_owned(),
        ),
      )
    } else if lower == "repeat" {
      stack.push(RepeatLoop)
      nodes.push(Repeat)
    } else if lower.has_prefix("repeat while ") {
      pop_block(stack, RepeatLoop, line_number, "repeat while")
      nodes.push(RepeatWhile(command_text(line, "repeat while")))
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
    } else if control == "fork" {
      stack.push(ForkBlock)
      nodes.push(Fork)
    } else if control == "fork again" {
      require_block(stack, ForkBlock, line_number, "fork again")
      nodes.push(ForkAgain)
    } else if control == "end merge" {
      pop_block(stack, ForkBlock, line_number, "end merge")
      nodes.push(EndMerge)
    } else if control == "end fork" ||
      control == "endfork" ||
      control == "fork end" {
      pop_block(stack, ForkBlock, line_number, "end fork")
      nodes.push(EndFork)
    } else if lower.has_prefix("switch ") {
      stack.push(SwitchBlock)
      nodes.push(Switch(command_text(line, "switch")))
    } else if lower.has_prefix("case ") {
      require_block(stack, SwitchBlock, line_number, "case")
      nodes.push(Case(command_text(line, "case")))
    } else if lower == "endswitch" {
      pop_block(stack, SwitchBlock, line_number, "endswitch")
      nodes.push(EndSwitch)
    } else if line.has_prefix("|") && line.has_suffix("|") {
      nodes.push(Swimlane(line[1:line.length() - 1].trim().to_owned()))
    } else if lower.has_prefix("partition ") && line.has_suffix("{") {
      stack.push(PartitionBlock)
      nodes.push(Partition(line[9:line.length() - 1].trim().to_owned()))
    } else if line == "}" {
      pop_block(stack, PartitionBlock, line_number, "}")
      nodes.push(EndPartition)
    } else if lower.has_prefix("label ") {
      nodes.push(Label(command_text(line, "label")))
    } else if lower.has_prefix("goto ") {
      nodes.push(Goto(command_text(line, "goto")))
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
  let outgoing = activity_backward_link(
    ending[semicolon + 1:].trim().to_owned(),
  )
  lines[last] = ending[:semicolon].to_owned()
  { label: lines.join("\n").trim().to_owned(), incoming, outgoing, }
}
