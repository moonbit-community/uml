///|
test "if chains keep decision text and branch labels separate" {
  let diagram = @parser.parse_activity(
    "if (check then proceed?) then (yes)\n:Run;\nelseif (later?) then (wait)\n:Wait;\nelse (no)\n:Stop;\nendif",
  )
  match diagram.instructions {
    [IfChain(chain)] =>
      match chain.branches {
        [first, second, third] => {
          @test.assert_eq(first.condition, Some("check then proceed?"))
          @test.assert_eq(first.incoming.text, Some("yes"))
          @test.assert_eq(second.condition, Some("later?"))
          @test.assert_eq(second.incoming.text, Some("wait"))
          @test.assert_eq(third.condition, None)
          @test.assert_eq(third.incoming.text, Some("no"))
        }
        _ => @test.fail("expected conditional branches")
      }
    _ => @test.fail("expected if chain")
  }
}

///|
test "loop conditions preserve enter retry and exit edge labels" {
  let diagram = @parser.parse_activity(
    "while (input is ready?) is (yes)\n:Read;\nendwhile (no)\nrepeat\n:Retry;\nrepeat while (result is (not ready)?) is (again not yet) not (done)",
  )
  match diagram.instructions {
    [While(while_loop), Repeat(repeat_loop)] => {
      @test.assert_eq(while_loop.condition, "input is ready?")
      @test.assert_eq(while_loop.enter.text, Some("yes"))
      @test.assert_eq(while_loop.exit.text, Some("no"))
      @test.assert_eq(repeat_loop.condition, "result is (not ready)?")
      @test.assert_eq(repeat_loop.retry.text, Some("again not yet"))
      @test.assert_eq(repeat_loop.exit.text, Some("done"))
    }
    _ => @test.fail("expected while and repeat instructions")
  }
}

///|
test "switch fork partitions lanes and goto reduce to dedicated instructions" {
  let diagram = @parser.parse_activity(
    "|Worker|\npartition Work {\nfork\n:Build;\nfork again\n:Test;\nend fork\n}\nswitch (mode)\ncase (fast)\n:Ship;\nendswitch\nlabel done\ngoto done",
  )
  match diagram.instructions {
    [
      Swimlane("Worker"),
      Partition(partition),
      Switch(switch),
      Label("done"),
      Goto("done"),
    ] => {
      @test.assert_eq(partition.label, "Work")
      @test.assert_eq(partition.instructions.any(item => item is Fork(_)), true)
      @test.assert_eq(switch.condition, "mode")
      @test.assert_eq(switch.branches[0].incoming.text, Some("fast"))
    }
    _ => @test.fail("expected structured instructions")
  }
}
