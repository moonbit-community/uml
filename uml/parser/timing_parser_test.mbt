///|
test "player declarations keep kind, title and registration order" {
  let diagram = parse_timing(
    "@startuml\nrobust R\nconcise C\nrectangle Rc\nbinary B\nanalog \"Voltage\" as V\nclock \"Ticker\" as Clk with period 4\n@enduml",
  )
  @test.assert_eq(diagram.players.map(player => player.kind), [
    Robust,
    Concise,
    Rectangle,
    Binary,
    Analog,
    Clock,
  ])
  @test.assert_eq(diagram.players[4].title, "Voltage")
  @test.assert_eq(diagram.players[5].title, "Ticker")
  @test.assert_eq(diagram.clock("Clk").unwrap().period, Some("4"))
  // A clock registers its period as a ruler mark...
  @test.assert_eq(diagram.time_marks.length(), 1)
  // ...and becomes the current player like any declaration.
  @test.assert_eq(diagram.last_player, Some("Clk"))
}

///|
test "clock respects the compact flag" {
  let diagram = parse_timing(
    "@startuml\nclock \"T\" as Clk with period 4\ncompact clock \"T\" as Clk2 with period 2\n@enduml",
  )
  @test.assert_eq(diagram.player("Clk").unwrap().compact, false)
  @test.assert_eq(diagram.player("Clk2").unwrap().compact, true)
}

///|
test "state changes before any time mark become the initial state" {
  let diagram = parse_timing(
    "@startuml\nrobust R\nR has \"Inactive\" as idle\nR is idle\n@3\nR is busy\n@enduml",
  )
  let player = diagram.player("R").unwrap()
  @test.assert_eq(player.initial.unwrap().states, ["Inactive"])
  @test.assert_eq(player.changes.length(), 1)
  @test.assert_eq(player.changes[0].states, ["busy"])
  @test.assert_eq(
    decimal_to_plain_string(player.changes[0].when.unwrap().time),
    "3",
  )
  @test.assert_eq(decimal_to_plain_string(diagram.now.unwrap().time), "3")
}

///|
test "binary and analog players convert their state values" {
  let diagram = parse_timing(
    "@startuml\nbinary B\nB is high\nanalog \"V\" as A\nA is 0.25\n@2\nA is 1e-1\n@enduml",
  )
  let binary = diagram.player("B").unwrap()
  @test.assert_eq(binary.initial.unwrap().states, ["1"])
  let analog = diagram.player("A").unwrap()
  @test.assert_eq(analog.initial.unwrap().states, ["0.25"])
  // A timed analog change also seeds the initial value when none exists.
  @test.assert_eq(analog.changes.length(), 1)
}

///|
test "time marks stay sorted and deduplicated" {
  let diagram = parse_timing(
    "@startuml\nrobust R\n@5\nR is a\n@3\nR is b\n@5\nR is c\n@enduml",
  )
  let values = diagram.time_marks.map(mark => decimal_to_plain_string(mark.time))
  @test.assert_eq(values, ["3", "5"])
}

///|
test "timed changes share the ascending order of the ruler including negative times" {
  for kind in ["robust", "concise", "rectangle", "binary", "analog \"A\" as"] {
    let diagram = parse_timing(
      kind + " P\n@-2\nP is 1\n@-5\nP is 0\n@3\nP is 1",
    )
    let changes = diagram.player("P").unwrap().changes
    @test.assert_eq(
      changes.map(change => change.when.unwrap()),
      diagram.time_marks,
    )
  }
}

///|
test "fractional time retains leading zeroes and relative changes cancel exactly" {
  let diagram = parse_timing(
    "binary B\n@0.05 as :a\n@+0.05 as :b\n@0.1 as :c\n@-0.1\n@+0.1 as :zero\n@-0.0 as :negativezero",
  )
  let value = code => {
    @string.parse_double(
      decimal_to_plain_string(diagram.code_value(code).unwrap().time),
    )
  }
  @test.assert_eq(value("b"), value("c"))
  @test.assert_eq(value("zero"), value("negativezero"))
  @test.assert_eq(value("a") < value("b"), true)
}

///|
test "calendar dates and relative seconds describe the same next day" {
  let diagram = parse_timing(
    "robust R\n@2020/05/12\n@+86400 as :relative\n@2020/05/13 as :calendar",
  )
  @test.assert_eq(
    diagram.code_value("relative").unwrap().time,
    diagram.code_value("calendar").unwrap().time,
  )
}

///|
test "time codes, messages, constraints, highlights and notes keep their targets" {
  let diagram = parse_timing(
    "@startuml\nrobust A\nbinary B\nA has \"Waiting\" as wait\n@5 as :start\nA is wait\nA@:start-->B\nA@:start<--->@8 : setup\nhighlight 0 to 10 : warmup\nnote top of A : single\nnote bottom of B\nmulti\nline\nend note\n@enduml",
  )
  let coded = diagram.code_value("start").unwrap()
  @test.assert_eq(diagram.messages[0].player1, "A")
  @test.assert_eq(diagram.messages[0].player2, "B")
  @test.assert_eq(diagram.messages[0].label, None)
  @test.assert_eq(diagram.messages[0].tick1, Some(coded))
  let constraint = diagram.player("A").unwrap().constraints[0]
  @test.assert_eq(constraint.message, Some("setup"))
  @test.assert_eq(diagram.highlights[0].caption, Some("warmup"))
  @test.assert_eq(diagram.player("A").unwrap().notes[0].position, "top")
  @test.assert_eq(diagram.player("B").unwrap().notes[0].text, "multi\nline")
}

///|
test "rejected forms mirror the installed plantuml behavior" {
  let rejected = [
    // The `@time is state` command is not accepted by the installed version.
    "robust R\n@5 is busy",
    // A note body must be closed.
     "robust R\nnote top of R\nopen",
    // A message between players that do not exist fails.
     "robust R\nA --> B",
  ]
  for source in rejected {
    let outcome = try {
      ignore(parse_timing("@startuml\n" + source + "\n@enduml"))
      "ok"
    } catch {
      _ => "error"
    }
    @test.assert_eq(outcome, "error")
  }
}

///|
test "initial state overwrites and duplicate changes keep the first entry" {
  let diagram = parse_timing(
    "@startuml\nrobust R\nR is a\nR is b\n@3\nR is c\n@3\nR is d\n@enduml",
  )
  let player = diagram.player("R").unwrap()
  @test.assert_eq(player.initial.unwrap().states, ["b"])
  @test.assert_eq(player.changes.length(), 1)
  @test.assert_eq(player.changes[0].states, ["c"])
}
