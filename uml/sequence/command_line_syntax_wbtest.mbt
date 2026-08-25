///|
test "command line grammar parses complete single-line commands" {
  let lines = [
    "alt #green #white accepted", "else #red rejected", "end", "box Infrastructure #lightblue",
    "box Frontend #lightyellow", "end box", "activate Service #lime", "deactivate Service",
    "deactivate", "destroy Service", "== section ==", "... waiting ...", "||20||",
    "newpage summary", "autonumber 1.2 3 \"(0)\"", "autonumber inc b", "autoactivate on",
    "autoactivate off", "hide footbox", "hide @unlinked", "url of Alice is [[https://example.com User]]",
    "return response", "ignore newpage", "autonewpage 10", "{left} <-> {right} : link",
    "footbox on", "footbox off",
  ]
  for line in lines {
    guard simple_event_line_syntax(@parse.Cursor::new(line)) is Some(_) else {
      @test.fail("command grammar rejected: " + line)
    }
  }
}

///|
test "participant declaration grammar parses complete declarations" {
  let lines = [
    "participant Alice", "actor \"Purchase Officer\" as po", "participant Last order -10",
    "participant Alice [[https://example.com]] #lightblue", "create Bob",
  ]
  for line in lines {
    guard participant_declaration_line_syntax(@parse.Cursor::new(line))
      is Some(_) else {
      @test.fail("participant grammar rejected: " + line)
    }
  }
}

///|
test "box and grouping order follows the command factory" {
  guard box_line_syntax(@parse.Cursor::new("box Frontend #lightyellow"))
    is Some(@seq.BoxStart(_)) else {
    @test.fail("box start rejected")
  }
  guard box_line_syntax(@parse.Cursor::new("end box")) is Some(@seq.BoxEnd) else {
    @test.fail("box end rejected")
  }
  match grouping_line_syntax(@parse.Cursor::new("end boxx")) {
    Some(@seq.GroupingLeaf(leaf)) => @test.assert_eq(leaf.is_end, true)
    _ => @test.fail("unrecognized text after end box must close a group")
  }
}

///|
test "bare deactivate matches before participant deactivate" {
  guard deactivate_line_syntax(@parse.Cursor::new("deactivate"))
    is Some(@seq.DeactivateLatest) else {
    @test.fail("bare deactivate rejected")
  }
  match deactivate_line_syntax(@parse.Cursor::new("deactivate Bob")) {
    Some(@seq.LifeEvent(life)) => @test.assert_eq(life.participant_code, "Bob")
    _ => @test.fail("participant deactivate rejected")
  }
}

///|
test "divider requires the closing delimiter" {
  match divider_line_syntax(@parse.Cursor::new("== section ==")) {
    Some(@seq.Divider(divider)) => @test.assert_eq(divider.title, "section")
    _ => @test.fail("divider rejected")
  }
  guard divider_line_syntax(@parse.Cursor::new("== section")) is None else {
    @test.fail("unclosed divider accepted")
  }
}

///|
test "delay and hspace delimiters" {
  match delay_line_syntax(@parse.Cursor::new("...")) {
    Some(@seq.Delay(delay)) => @test.assert_eq(delay.label, None)
    _ => @test.fail("bare delay rejected")
  }
  match delay_line_syntax(@parse.Cursor::new("... waiting ...")) {
    Some(@seq.Delay(delay)) => @test.assert_eq(delay.label, Some("waiting"))
    _ => @test.fail("labeled delay rejected")
  }
  guard delay_line_syntax(@parse.Cursor::new("... waiting")) is None else {
    @test.fail("unclosed delay accepted")
  }
  match hspace_line_syntax(@parse.Cursor::new("||20||")) {
    Some(@seq.HSpace(hspace)) => @test.assert_eq(hspace.pixels, Some(20))
    _ => @test.fail("hspace rejected")
  }
}

///|
test "autonumber branches are tried in factory order" {
  guard autonumber_line_syntax(@parse.Cursor::new("autonumber stop"))
    is Some(@seq.AutonumberStop) else {
    @test.fail("autonumber stop rejected")
  }
  match autonumber_line_syntax(@parse.Cursor::new("autonumber inc b")) {
    Some(@seq.AutonumberIncrement(value)) => @test.assert_eq(value, Some("b"))
    _ => @test.fail("autonumber inc rejected")
  }
  match autonumber_line_syntax(@parse.Cursor::new("autonumber 1.2 3 \"(0)\"")) {
    Some(@seq.Autonumber(number)) => {
      @test.assert_eq(number.start, Some("1.2"))
      @test.assert_eq(number.increment, Some(3))
      @test.assert_eq(number.format, Some("(0)"))
    }
    _ => @test.fail("autonumber start rejected")
  }
}

///|
test "autonumber branch keywords commit the whole line" {
  guard autonumber_line_syntax(@parse.Cursor::new("autonumber stop 5")) is None else {
    @test.fail("autonumber stop with trailing value accepted")
  }
  guard autonumber_line_syntax(@parse.Cursor::new("autonumber inc 5")) is None else {
    @test.fail("autonumber inc with trailing digits accepted")
  }
  match autonumber_line_syntax(@parse.Cursor::new("autonumber stopx")) {
    Some(@seq.Autonumber(number)) =>
      @test.assert_eq(number.start, Some("stopx"))
    _ => @test.fail("start value starting with stop rejected")
  }
}

///|
test "a failed box end falls through to a group end" {
  match grouping_line_syntax(@parse.Cursor::new("end box x")) {
    Some(@seq.GroupingLeaf(leaf)) => @test.assert_eq(leaf.is_end, true)
    _ => @test.fail("end box with trailing text must close a group")
  }
  guard toggle_line_syntax(@parse.Cursor::new("autoactivate on x")) is None else {
    @test.fail("toggle with trailing junk accepted")
  }
  guard url_command_line_syntax(
      @parse.Cursor::new("url of Alice is [[https://example.com]] x"),
    )
    is None else {
    @test.fail("url with trailing junk accepted")
  }
  guard miscellaneous_event_line_syntax(@parse.Cursor::new("ignore newpage x"))
    is None else {
    @test.fail("ignore newpage with trailing junk accepted")
  }
}

///|
test "life events require a whole identifier or a closed quote" {
  match
    life_event_line_syntax(
      @parse.Cursor::new("activate Bob"),
      "activate",
      @seq.Activate,
    ) {
    Some(@seq.LifeEvent(life)) => @test.assert_eq(life.participant_code, "Bob")
    _ => @test.fail("life event rejected")
  }
  match
    life_event_line_syntax(
      @parse.Cursor::new("activate \"Bob\""),
      "activate",
      @seq.Activate,
    ) {
    Some(@seq.LifeEvent(life)) => @test.assert_eq(life.participant_code, "Bob")
    _ => @test.fail("quoted life event rejected")
  }
  guard life_event_line_syntax(
      @parse.Cursor::new("activate \"Bob"),
      "activate",
      @seq.Activate,
    )
    is None else {
    @test.fail("unclosed quote accepted")
  }
}

///|
test "life event with color parses and carries the color" {
  let src =
    #|@startuml
    #|Alice -> Bob
    #|activate Bob #FF0000
    #|Bob --> Alice
    #|@enduml
  let diagram = parse(src)
  let has_colored_activation = diagram.events.exists(event => {
    match event {
      @seq.LifeEvent({ participant_code, event_type: @seq.Activate, color }) =>
        participant_code == "Bob" && color == Some("FF0000")
      _ => false
    }
  })
  @test.assert_eq(has_colored_activation, true)
}

///|
test "colored notes and activations keep their fill in the svg" {
  let src =
    #|@startuml
    #|Alice -> Bob
    #|activate Bob #lightgreen
    #|hnote over Alice #lightgreen : colored hex
    #|rnote over Carol #lightcoral : colored box
    #|Bob --> Alice
    #|@enduml
  let svg = render_sequence(src)
  @test.assert_eq(svg.contains("fill=\"#90EE90\""), true)
  @test.assert_eq(svg.contains("fill=\"#F08080\""), true)
}
