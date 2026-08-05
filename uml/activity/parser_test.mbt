///|
fn has_action(diagram : ActivityDiagram, label : String) -> Bool {
  diagram.nodes.any(node => {
    match node {
      Action(value) => value == label
      _ => false
    }
  })
}

///|
fn has_control(diagram : ActivityDiagram, label : String) -> Bool {
  diagram.nodes.any(node => {
    match node {
      If(value)
      | ElseIf(value)
      | Else(value)
      | While(value)
      | RepeatWhile(value)
      | Case(value)
      | Swimlane(value)
      | Partition(value)
      | Goto(value) => value == label
      _ => false
    }
  })
}

///|
test "parses nested conditional branches without losing branch commands" {
  let diagram = parse(
    "start\nif (ready?) then (yes)\n:Work;\nelseif (later?) then (wait)\n:Wait;\nelse (no)\n:Stop;\nendif\nstop",
  )
  @test.assert_eq(diagram.nodes.is_empty(), false)
  @test.assert_eq(has_control(diagram, "(ready?) then (yes)"), true)
  @test.assert_eq(has_control(diagram, "(later?) then (wait)"), true)
  @test.assert_eq(has_control(diagram, "(no)"), true)
  @test.assert_eq(has_action(diagram, "Work"), true)
  @test.assert_eq(has_action(diagram, "Wait"), true)
  @test.assert_eq(has_action(diagram, "Stop"), true)
}

///|
test "preserves all loop, fork, and switch boundaries" {
  let diagram = parse(
    "while (more?)\n:Read;\nendwhile (done)\nrepeat\n:Retry;\nrepeat while (failed?)\nfork\n:One;\nfork again\n:Two;\nend fork\nswitch (kind)\ncase (a)\n:A;\nendswitch",
  )
  @test.assert_eq(has_control(diagram, "(more?)"), true)
  @test.assert_eq(has_control(diagram, "(failed?)"), true)
  @test.assert_eq(has_control(diagram, "(a)"), true)
  @test.assert_eq(diagram.nodes.any(node => node is ForkAgain), true)
}

///|
test "parses swimlanes partitions notes and named flow targets" {
  let diagram = parse(
    "|User|\npartition Work {\n:Start;\nnote right\nHelpful text\nend note\nlabel retry\ngoto retry\n}",
  )
  @test.assert_eq(has_control(diagram, "User"), true)
  @test.assert_eq(has_control(diagram, "Work"), true)
  @test.assert_eq(has_control(diagram, "retry"), true)
  @test.assert_eq(
    diagram.nodes.any(node => {
      match node {
        Note(text) => text == "Helpful text"
        _ => false
      }
    }),
    true,
  )
}

///|
test "rejects unmatched and unclosed control-flow blocks" {
  for
    source in ["else", "endwhile", "case (unexpected)", "if (open?) then (yes)"] {
    try parse(source) catch {
      SyntaxError(_, _) => ()
    } noraise {
      _ => @test.fail("expected activity structure error")
    }
  }
}

///|
test "rejects arbitrary dash-prefixed lines as arrows" {
  @test.assert_raise(() => ignore(parse("@startuml\n- not an arrow\n@enduml")))
}
