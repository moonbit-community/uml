///|
priv enum ReductionBoundary {
  ElseIf
  Else
  EndIf
  EndWhile
  RepeatWhile
  ForkAgain
  EndFork
  SplitAgain
  EndSplit
  Case
  EndSwitch
  EndPartition
}

///|
pub fn edge_label(value : String) -> ActivityEdgeLabel {
  let value = value.trim().to_owned()
  let text = {
    guard value.has_prefix("(") && value.has_suffix(")") else { value }
    value[1:value.length() - 1].trim().to_owned()
  }
  if text.has_prefix("->") || text.has_prefix("-[") {
    return arrow_label(text)
  }
  { style: None, text: if text.length() == 0 { None } else { Some(text) }, }
}

///|
/// Branch keywords delimit labels only outside the parenthesized text.
fn activity_label_separator(value : String, separator : String) -> Int32? {
  let lower = value.to_lower()
  let mut depth = 0
  for index = 0; index < lower.length(); index = index + 1 {
    let unit = lower[index:index + 1]
    if unit == "(" {
      depth += 1
    } else if unit == ")" {
      depth -= 1
    } else if depth == 0 && lower[index:].has_prefix(separator[:]) {
      return Some(index)
    }
  }
  None
}

///|
fn split_test_and_label(
  value : String,
  separator : String,
) -> (String, ActivityEdgeLabel) {
  let value = value.trim().to_owned()
  let value = if value.has_suffix(";") {
    value[:value.length() - 1].trim_end().to_owned()
  } else {
    value
  }
  let separators = if separator == " then " {
    [" then ", " is ", " equals ", " equal "]
  } else {
    [separator, " equals ", " equal "]
  }
  for candidate in separators {
    if activity_label_separator(value, candidate) is Some(index) {
      let mut label = value[index + candidate.length():].trim().to_owned()
      if label.has_prefix("when ") {
        label = label[5:].to_owned()
      }
      if label.has_suffix(" then") {
        label = label[:label.length() - 5].trim_end().to_owned()
      }
      return (
        edge_label(value[:index].to_owned()).text.unwrap_or(""),
        edge_label(label),
      )
    }
  }
  let value = if value.has_suffix(" then") {
    value[:value.length() - 5].trim_end().to_owned()
  } else {
    value
  }
  (edge_label(value).text.unwrap_or(""), { style: None, text: None, })
}

///|
fn repeat_labels(
  value : String,
) -> (String, ActivityEdgeLabel, ActivityEdgeLabel) {
  let exit_at = activity_label_separator(value, " not ")
  let retry_source = exit_at.map_or(value, index => value[:index].to_owned())
  let (condition, retry) = split_test_and_label(retry_source, " is ")
  let exit = exit_at.map_or({ style: None, text: None, }, index => {
    edge_label(value[index + 5:].to_owned())
  })
  (condition, retry, exit)
}

///|
pub fn arrow_label(value : String) -> ActivityEdgeLabel {
  guard value.find(">") is Some(arrow_end) else {
    return { style: None, text: None, }
  }
  let text = value[arrow_end + 1:].trim().to_owned()
  let text = if text.has_suffix(";") {
    text[:text.length() - 1].to_owned()
  } else {
    text
  }
  let style = if value.has_prefix("-[") && value.find("]") is Some(end) {
    Some(value[2:end].to_owned())
  } else {
    None
  }
  { style, text: if text.length() == 0 { None } else { Some(text) }, }
}

///|
fn matches_reduction_boundary(
  node : ActivityNode,
  boundary : ReductionBoundary,
) -> Bool {
  (node, boundary)
  is ((ActivityNode::ElseIf(_), ElseIf)
  | (ActivityNode::Else(_), Else)
  | (ActivityNode::EndIf(_), EndIf)
  | (ActivityNode::EndWhile(_), EndWhile)
  | (ActivityNode::RepeatWhile(_), RepeatWhile)
  | (ActivityNode::ForkAgain, ForkAgain)
  | (ActivityNode::EndFork(_), EndFork)
  | (ActivityNode::EndMerge(_), EndFork)
  | (ActivityNode::SplitAgain, SplitAgain)
  | (ActivityNode::EndSplit, EndSplit)
  | (ActivityNode::Case(_), Case)
  | (ActivityNode::EndSwitch(_), EndSwitch)
  | (ActivityNode::EndPartition, EndPartition))
}

///|
fn at_reduction_boundary(
  node : ActivityNode,
  boundaries : Array[ReductionBoundary],
) -> Bool {
  boundaries.any(boundary => matches_reduction_boundary(node, boundary))
}

///|
/// Collect the branches of a chain construct (`if`/`fork`/`switch`) until its
/// terminal node. Each body is reduced with `boundaries`; `continue_with`
/// maps the node ending a body to the header of the next branch. The finished
/// instruction is pushed and the index after the terminal is returned, or
/// `None` when the chain is unterminated.
fn[B] reduce_chain(
  instructions : Array[ActivityInstruction],
  nodes : Array[ActivityNode],
  header : ActivityNode,
  cursor : Int32,
  boundaries : Array[ReductionBoundary],
  branch : (ActivityNode, Array[ActivityInstruction]) -> B,
  continue_with : (ActivityNode) -> ActivityNode?,
  finish : (Array[B], ActivityNode) -> ActivityInstruction,
) -> Int32? {
  let branches = []
  let mut header = header
  let mut cursor = cursor
  while cursor <= nodes.length() {
    let (body, next) = reduce_flow(nodes, cursor, boundaries)
    branches.push(branch(header, body))
    guard next < nodes.length() else { return None }
    guard continue_with(nodes[next]) is Some(next_header) else {
      instructions.push(finish(branches, nodes[next]))
      return Some(next + 1)
    }
    header = next_header
    cursor = next + 1
  }
  None
}

///|
fn emit(
  instructions : Array[ActivityInstruction],
  instruction : ActivityInstruction,
  index : Int32,
) -> Int32 {
  instructions.push(instruction)
  index + 1
}

///|
fn reduce_flow(
  nodes : Array[ActivityNode],
  start : Int32,
  boundaries : Array[ReductionBoundary],
) -> (Array[ActivityInstruction], Int32) {
  let instructions = []
  let mut index = start
  while index < nodes.length() {
    let node = nodes[index]
    guard !at_reduction_boundary(node, boundaries) else { break }
    match node {
      ActivityNode::If(_) => {
        guard reduce_chain(
            instructions,
            nodes,
            node,
            index + 1,
            [ElseIf, Else, EndIf],
            (header, body) => {
              let (condition, incoming) = match header {
                ActivityNode::If(value) | ActivityNode::ElseIf(value) => {
                  let (condition, incoming) = split_test_and_label(
                    value.text,
                    " then ",
                  )
                  (Some({ ..value, text: condition, }), incoming)
                }
                ActivityNode::Else(value) =>
                  (
                    None,
                    edge_label(
                      if value.has_prefix("when ") {
                        value[5:].to_owned()
                      } else {
                        value
                      },
                    ),
                  )
                _ => (None, { style: None, text: None, })
              }
              { condition, incoming, instructions: body, }
            },
            next => {
              match next {
                ActivityNode::ElseIf(_) | ActivityNode::Else(_) => Some(next)
                _ => None
              }
            },
            (branches, terminal) => {
              guard terminal is ActivityNode::EndIf(merge) else {
                abort("if requires endif")
              }
              ActivityInstruction::IfChain({ branches, merge, })
            },
          )
          is Some(next_index) else {
          break
        }
        index = next_index
      }
      ActivityNode::While(raw) => {
        let (body, end) = reduce_flow(nodes, index + 1, [EndWhile])
        guard end < nodes.length() else { break }
        let (condition, enter) = split_test_and_label(raw.text, " is ")
        let exit = match nodes[end] {
          ActivityNode::EndWhile(value) => edge_label(value)
          _ => { style: None, text: None, }
        }
        instructions.push(
          ActivityInstruction::While({
            condition: { ..raw, text: condition, },
            enter,
            exit,
            instructions: body,
          }),
        )
        index = end + 1
      }
      ActivityNode::Repeat(_) | ActivityNode::RepeatAction(_) => {
        let (body, end) = reduce_flow(nodes, index + 1, [RepeatWhile])
        guard end < nodes.length() else { break }
        let (condition, retry, exit) = match nodes[end] {
          ActivityNode::RepeatWhile(value) => {
            let (condition, retry, exit) = repeat_labels(value.text)
            ({ ..value, text: condition, }, retry, exit)
          }
          _ => abort("repeat reducer requires a closing condition")
        }
        instructions.push(
          ActivityInstruction::Repeat({
            entry: match node {
              ActivityNode::Repeat(entry) => entry
              ActivityNode::RepeatAction(action) =>
                {
                  text: "",
                  stereotype: action.stereotype,
                  color: None,
                  style: action.style,
                }
              _ => abort("invalid repeat entry")
            },
            start: match node {
              ActivityNode::RepeatAction(text) => Some(text)
              _ => None
            },
            condition,
            retry,
            exit,
            instructions: body,
          }),
        )
        index = end + 1
      }
      ActivityNode::Fork(_) | ActivityNode::Split => {
        guard reduce_chain(
            instructions,
            nodes,
            node,
            index + 1,
            [ForkAgain, EndFork, SplitAgain, EndSplit],
            (_header, body) => body,
            next => {
              match next {
                ActivityNode::ForkAgain | ActivityNode::SplitAgain => Some(next)
                _ => None
              }
            },
            (branches, terminal) => {
              if node is ActivityNode::Split {
                ActivityInstruction::Split({
                  branches,
                  merge: false,
                  stereotype: None,
                  label: None,
                })
              } else {
                ActivityInstruction::Fork({
                  branches,
                  merge: terminal is ActivityNode::EndMerge(_),
                  stereotype: match node {
                    ActivityNode::Fork(stereotype) => stereotype
                    _ => None
                  },
                  label: match terminal {
                    ActivityNode::EndFork(label, _) => label
                    _ => None
                  },
                })
              }
            },
          )
          is Some(next_index) else {
          break
        }
        index = next_index
      }
      ActivityNode::Switch(raw) =>
        match nodes.get(index + 1) {
          Some(node) if node is ActivityNode::Case(_) => {
            guard reduce_chain(
                instructions,
                nodes,
                node,
                index + 2,
                [Case, EndSwitch],
                (header, body) => {
                  let incoming = match header {
                    ActivityNode::Case(value) => edge_label(value)
                    _ => { style: None, text: None, }
                  }
                  { condition: None, incoming, instructions: body, }
                },
                next => {
                  match next {
                    ActivityNode::Case(_) => Some(next)
                    _ => None
                  }
                },
                (branches, terminal) => {
                  guard terminal is ActivityNode::EndSwitch(merge) else {
                    abort("switch requires endswitch")
                  }
                  ActivityInstruction::Switch({
                    merge,
                    condition: {
                      ..raw,
                      text: edge_label(raw.text).text.unwrap_or(""),
                    },
                    branches,
                  })
                },
              )
              is Some(next_index) else {
              break
            }
            index = next_index
          }
          _ => break
        }
      ActivityNode::Partition(group) => {
        let (body, end) = reduce_flow(nodes, index + 1, [EndPartition])
        instructions.push(
          ActivityInstruction::Partition({ group, instructions: body, }),
        )
        index = if end < nodes.length() { end + 1 } else { end }
      }
      ActivityNode::Spot(text, color) =>
        index = emit(
          instructions,
          ActivityInstruction::Spot(text, color),
          index,
        )
      ActivityNode::Start(stereotype) =>
        index = emit(
          instructions,
          ActivityInstruction::Start(stereotype),
          index,
        )
      ActivityNode::Stop(stereotype) =>
        index = emit(instructions, ActivityInstruction::Stop(stereotype), index)
      ActivityNode::End(stereotype) =>
        index = emit(instructions, ActivityInstruction::End(stereotype), index)
      ActivityNode::Backward(value) =>
        index = emit(instructions, ActivityInstruction::Backward(value), index)
      ActivityNode::Break =>
        index = emit(instructions, ActivityInstruction::Break, index)
      ActivityNode::Kill =>
        index = emit(instructions, ActivityInstruction::Kill, index)
      ActivityNode::Action(label) =>
        index = emit(instructions, ActivityInstruction::Action(label), index)
      ActivityNode::StyledAction(action) =>
        index = emit(
          instructions,
          ActivityInstruction::StyledAction(action),
          index,
        )
      ActivityNode::Note(label, side) =>
        index = emit(
          instructions,
          ActivityInstruction::Note(label, side),
          index,
        )
      ActivityNode::StyledNote(note) =>
        index = emit(instructions, ActivityInstruction::StyledNote(note), index)
      ActivityNode::Arrow(value) =>
        index = emit(
          instructions,
          ActivityInstruction::Edge(arrow_label(value)),
          index,
        )
      ActivityNode::Swimlane(name) =>
        index = emit(instructions, ActivityInstruction::Swimlane(name), index)
      ActivityNode::Label(name) =>
        index = emit(instructions, ActivityInstruction::Label(name), index)
      ActivityNode::Goto(name) =>
        index = emit(instructions, ActivityInstruction::Goto(name), index)
      _ => index += 1
    }
  }
  (instructions, index)
}

///|
/// Reduce parser commands to the semantic instruction layer used by activity layout.
pub fn reduce(nodes : Array[ActivityNode]) -> Array[ActivityInstruction] {
  reduce_flow(nodes, 0, []).0
}
