///|
priv enum ReductionBoundary {
  ElseIf
  Else
  EndIf
  EndWhile
  RepeatWhile
  ForkAgain
  EndFork
  Case
  EndSwitch
  EndPartition
}

///|
fn edge_label(value : String) -> ActivityEdgeLabel {
  let value = value.trim().to_owned()
  let text = {
    guard value.has_prefix("(") && value.has_suffix(")") else { value }
    value[1:value.length() - 1].trim().to_owned()
  }
  { text: if text.length() == 0 { None } else { Some(text) } }
}

///|
fn split_test_and_label(
  value : String,
  separator : String,
) -> (String, ActivityEdgeLabel) {
  let lower = value.to_lower()
  match lower.find(separator) {
    Some(index) =>
      (
        edge_label(value[:index].to_owned()).text.unwrap_or(""),
        edge_label(value[index + separator.length():].to_owned()),
      )
    None => (edge_label(value).text.unwrap_or(""), { text: None })
  }
}

///|
fn repeat_labels(
  value : String,
) -> (String, ActivityEdgeLabel, ActivityEdgeLabel) {
  let lower = value.to_lower()
  guard lower.find(" is ") is Some(is_index) else {
    return (
      edge_label(value).text.unwrap_or(""),
      { text: None },
      { text: None },
    )
  }
  let condition = edge_label(value[:is_index].to_owned()).text.unwrap_or("")
  let rest = value[is_index + 4:].trim().to_owned()
  guard rest.length() > 0 else {
    return (condition, { text: None }, { text: None })
  }
  match rest.to_lower().find(" not ") {
    Some(index) =>
      (
        condition,
        edge_label(rest[:index].to_owned()),
        edge_label(rest[index + 5:].to_owned()),
      )
    None => (condition, edge_label(rest), { text: None })
  }
}

///|
fn arrow_label(value : String) -> ActivityEdgeLabel {
  let words = @parse.syntax_words(value)
  guard words.length() > 1 else { return { text: None } }
  let text = words[1:].to_owned().join(" ").trim_end(chars=";").to_owned()
  { text: if text.length() == 0 { None } else { Some(text) } }
}

///|
fn matches_reduction_boundary(
  node : ActivityNode,
  boundary : ReductionBoundary,
) -> Bool {
  (node, boundary)
  is ((ActivityNode::ElseIf(_), ElseIf)
  | (ActivityNode::Else(_), Else)
  | (ActivityNode::EndIf, EndIf)
  | (ActivityNode::EndWhile(_), EndWhile)
  | (ActivityNode::RepeatWhile(_), RepeatWhile)
  | (ActivityNode::ForkAgain, ForkAgain)
  | (ActivityNode::EndFork, EndFork)
  | (ActivityNode::Case(_), Case)
  | (ActivityNode::EndSwitch, EndSwitch)
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
  cursor : Int,
  boundaries : Array[ReductionBoundary],
  branch : (ActivityNode, Array[ActivityInstruction]) -> B,
  continue_with : (ActivityNode) -> ActivityNode?,
  finish : (Array[B]) -> ActivityInstruction,
) -> Int? {
  let branches = []
  let mut header = header
  let mut cursor = cursor
  while cursor <= nodes.length() {
    let (body, next) = reduce_flow(nodes, cursor, boundaries)
    branches.push(branch(header, body))
    guard next < nodes.length() else { return None }
    guard continue_with(nodes[next]) is Some(next_header) else {
      instructions.push(finish(branches))
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
  index : Int,
) -> Int {
  instructions.push(instruction)
  index + 1
}

///|
fn reduce_flow(
  nodes : Array[ActivityNode],
  start : Int,
  boundaries : Array[ReductionBoundary],
) -> (Array[ActivityInstruction], Int) {
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
            fn(header, body) {
              let (condition, incoming) = match header {
                ActivityNode::If(value) | ActivityNode::ElseIf(value) => {
                  let (condition, incoming) = split_test_and_label(
                    value, " then ",
                  )
                  (Some(condition), incoming)
                }
                ActivityNode::Else(value) => (None, edge_label(value))
                _ => (None, { text: None })
              }
              { condition, incoming, instructions: body }
            },
            fn(next) {
              match next {
                ActivityNode::ElseIf(_) | ActivityNode::Else(_) => Some(next)
                _ => None
              }
            },
            branches => ActivityInstruction::IfChain({ branches, }),
          )
          is Some(next_index) else {
          break
        }
        index = next_index
      }
      ActivityNode::While(raw) => {
        let (body, end) = reduce_flow(nodes, index + 1, [EndWhile])
        guard end < nodes.length() else { break }
        let (condition, enter) = split_test_and_label(raw, " is ")
        let exit = match nodes[end] {
          ActivityNode::EndWhile(value) => edge_label(value)
          _ => { text: None }
        }
        instructions.push(
          ActivityInstruction::While({
            condition,
            enter,
            exit,
            instructions: body,
          }),
        )
        index = end + 1
      }
      ActivityNode::Repeat => {
        let (body, end) = reduce_flow(nodes, index + 1, [RepeatWhile])
        guard end < nodes.length() else { break }
        let (condition, retry, exit) = match nodes[end] {
          ActivityNode::RepeatWhile(value) => repeat_labels(value)
          _ => ("", { text: None }, { text: None })
        }
        instructions.push(
          ActivityInstruction::Repeat({
            condition,
            retry,
            exit,
            instructions: body,
          }),
        )
        index = end + 1
      }
      ActivityNode::Fork => {
        guard reduce_chain(
            instructions,
            nodes,
            node,
            index + 1,
            [ForkAgain, EndFork],
            fn(_header, body) { body },
            fn(next) {
              match next {
                ActivityNode::ForkAgain => Some(next)
                _ => None
              }
            },
            branches => ActivityInstruction::Fork({ branches, }),
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
                fn(header, body) {
                  let incoming = match header {
                    ActivityNode::Case(value) => edge_label(value)
                    _ => { text: None }
                  }
                  { condition: None, incoming, instructions: body }
                },
                fn(next) {
                  match next {
                    ActivityNode::Case(_) => Some(next)
                    _ => None
                  }
                },
                branches => {
                  ActivityInstruction::Switch({
                    condition: edge_label(raw).text.unwrap_or(""),
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
      ActivityNode::Partition(label) => {
        let (body, end) = reduce_flow(nodes, index + 1, [EndPartition])
        instructions.push(
          ActivityInstruction::Partition({ label, instructions: body }),
        )
        index = if end < nodes.length() { end + 1 } else { end }
      }
      ActivityNode::Start =>
        index = emit(instructions, ActivityInstruction::Start, index)
      ActivityNode::Stop =>
        index = emit(instructions, ActivityInstruction::Stop, index)
      ActivityNode::End =>
        index = emit(instructions, ActivityInstruction::End, index)
      ActivityNode::Kill =>
        index = emit(instructions, ActivityInstruction::Kill, index)
      ActivityNode::Action(label) =>
        index = emit(instructions, ActivityInstruction::Action(label), index)
      ActivityNode::Note(label) =>
        index = emit(instructions, ActivityInstruction::Note(label), index)
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
