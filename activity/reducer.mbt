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
  let text = if value.has_prefix("(") && value.has_suffix(")") {
    value[1:value.length() - 1].trim().to_owned()
  } else {
    value
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
  let words = @core.syntax_words(value)
  guard words.length() > 1 else { return { text: None } }
  let text = words[1:].to_owned().join(" ").trim_end(chars=";").to_owned()
  { text: if text.length() == 0 { None } else { Some(text) } }
}

///|
fn matches_reduction_boundary(
  node : ActivityNode,
  boundary : ReductionBoundary,
) -> Bool {
  match (node, boundary) {
    (ActivityNode::ElseIf(_), ElseIf)
    | (ActivityNode::Else(_), Else)
    | (ActivityNode::EndIf, EndIf)
    | (ActivityNode::EndWhile(_), EndWhile)
    | (ActivityNode::RepeatWhile(_), RepeatWhile)
    | (ActivityNode::ForkAgain, ForkAgain)
    | (ActivityNode::EndFork, EndFork)
    | (ActivityNode::Case(_), Case)
    | (ActivityNode::EndSwitch, EndSwitch)
    | (ActivityNode::EndPartition, EndPartition) => true
    _ => false
  }
}

///|
fn at_reduction_boundary(
  node : ActivityNode,
  boundaries : Array[ReductionBoundary],
) -> Bool {
  boundaries.any(boundary => matches_reduction_boundary(node, boundary))
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
        let branches = []
        let mut branch_node = node
        let mut cursor = index + 1
        while cursor <= nodes.length() {
          let (body, next) = reduce_flow(nodes, cursor, [ElseIf, Else, EndIf])
          let (condition, incoming) = match branch_node {
            ActivityNode::If(value) | ActivityNode::ElseIf(value) => {
              let (condition, incoming) = split_test_and_label(value, " then ")
              (Some(condition), incoming)
            }
            ActivityNode::Else(value) => (None, edge_label(value))
            _ => (None, { text: None })
          }
          branches.push({ condition, incoming, instructions: body })
          guard next < nodes.length() else { break }
          match nodes[next] {
            ActivityNode::ElseIf(_) | ActivityNode::Else(_) => {
              branch_node = nodes[next]
              cursor = next + 1
            }
            ActivityNode::EndIf => {
              instructions.push(ActivityInstruction::IfChain({ branches, }))
              index = next + 1
              break
            }
            _ => ()
          }
        }
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
        let branches = []
        let mut cursor = index + 1
        while cursor <= nodes.length() {
          let (body, next) = reduce_flow(nodes, cursor, [ForkAgain, EndFork])
          branches.push(body)
          guard next < nodes.length() else { break }
          match nodes[next] {
            ActivityNode::ForkAgain => cursor = next + 1
            ActivityNode::EndFork => {
              instructions.push(ActivityInstruction::Fork({ branches, }))
              index = next + 1
              break
            }
            _ => ()
          }
        }
      }
      ActivityNode::Switch(raw) => {
        let branches = []
        let mut cursor = index + 1
        while cursor < nodes.length() {
          guard nodes[cursor] is ActivityNode::Case(case_label) else { break }
          let (body, next) = reduce_flow(nodes, cursor + 1, [Case, EndSwitch])
          branches.push({
            condition: None,
            incoming: edge_label(case_label),
            instructions: body,
          })
          guard next < nodes.length() else { break }
          match nodes[next] {
            ActivityNode::Case(_) => cursor = next
            ActivityNode::EndSwitch => {
              instructions.push(
                ActivityInstruction::Switch({
                  condition: edge_label(raw).text.unwrap_or(""),
                  branches,
                }),
              )
              index = next + 1
              break
            }
            _ => ()
          }
        }
      }
      ActivityNode::Partition(label) => {
        let (body, end) = reduce_flow(nodes, index + 1, [EndPartition])
        instructions.push(
          ActivityInstruction::Partition({ label, instructions: body }),
        )
        index = if end < nodes.length() { end + 1 } else { end }
      }
      ActivityNode::Start => {
        instructions.push(ActivityInstruction::Start)
        index += 1
      }
      ActivityNode::Stop => {
        instructions.push(ActivityInstruction::Stop)
        index += 1
      }
      ActivityNode::End => {
        instructions.push(ActivityInstruction::End)
        index += 1
      }
      ActivityNode::Kill => {
        instructions.push(ActivityInstruction::Kill)
        index += 1
      }
      ActivityNode::Action(label) => {
        instructions.push(ActivityInstruction::Action(label))
        index += 1
      }
      ActivityNode::Note(label) => {
        instructions.push(ActivityInstruction::Note(label))
        index += 1
      }
      ActivityNode::Arrow(value) => {
        instructions.push(ActivityInstruction::Edge(arrow_label(value)))
        index += 1
      }
      ActivityNode::Swimlane(name) => {
        instructions.push(ActivityInstruction::Swimlane(name))
        index += 1
      }
      ActivityNode::Label(name) => {
        instructions.push(ActivityInstruction::Label(name))
        index += 1
      }
      ActivityNode::Goto(name) => {
        instructions.push(ActivityInstruction::Goto(name))
        index += 1
      }
      _ => index += 1
    }
  }
  (instructions, index)
}

///|
/// Reduce parser commands to the semantic instruction layer used by activity layout.
pub fn reduce(nodes : Array[ActivityNode]) -> Array[ActivityInstruction] {
  let (instructions, _) = reduce_flow(nodes, 0, [])
  instructions
}
