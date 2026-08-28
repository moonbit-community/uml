///|
priv enum BlockKind {
  Conditional
  WhileLoop
  RepeatLoop
  ForkBlock
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
    if line.length() == 0 ||
      lower == "@startuml" ||
      lower == "@enduml" ||
      lower == "@startactivity" ||
      lower == "@endactivity" ||
      @style.is_preprocessor_directive(line) {
      buffer.advance()
      continue
    }
    if lower == "skinparam {" {
      let closed = @style.consume_skinparam_body(() => buffer.take_next(), directive => {
        style.apply(directive)
      })
      guard closed else {
        raise SyntaxError(buffer.length(), "unclosed skinparam")
      }
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
    if lower.has_prefix("note ") && !line.contains(":") {
      let (text, end) = parse_note(buffer, buffer.index)
      nodes.push(@flow.ActivityNode::Note(text))
      buffer.index = end + 1
      continue
    }
    if lower == "start" {
      nodes.push(@flow.ActivityNode::Start)
    } else if lower == "stop" {
      nodes.push(@flow.ActivityNode::Stop)
    } else if lower == "end" {
      nodes.push(@flow.ActivityNode::End)
    } else if lower == "kill" {
      nodes.push(@flow.ActivityNode::Kill)
    } else if line.has_prefix(":") && line.has_suffix(";") {
      nodes.push(
        @flow.ActivityNode::Action(line[1:line.length() - 1].trim().to_owned()),
      )
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
    } else if lower == "repeat" {
      stack.push(RepeatLoop)
      nodes.push(Repeat)
    } else if lower.has_prefix("repeat while ") {
      pop_block(stack, RepeatLoop, line_number, "repeat while")
      nodes.push(RepeatWhile(command_text(line, "repeat while")))
    } else if lower == "fork" {
      stack.push(ForkBlock)
      nodes.push(Fork)
    } else if lower == "fork again" {
      require_block(stack, ForkBlock, line_number, "fork again")
      nodes.push(ForkAgain)
    } else if lower == "end fork" || lower == "endfork" {
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
