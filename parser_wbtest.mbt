///|
test "parse empty diagram" {
  let result = parse("@startuml\n@enduml")
  @test.assert_eq(result.events.length(), 0)
}

///|
test "parse simple arrow" {
  let result = parse("@startuml\nAlice -> Bob\n@enduml")
  @test.assert_eq(result.events.length(), 1)
}

///|
test "parse arrow with label" {
  let result = parse("@startuml\nAlice -> Bob : hello\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => @test.assert_eq(m.label, Some("hello"))
    _ => fail("not a message")
  }
}

///|
test "parse two messages" {
  let result = parse("@startuml\nAlice -> Bob\nBob -> Carol\n@enduml")
  @test.assert_eq(result.events.length(), 2)
}

///|
test "parse note" {
  let result = parse(
    "@startuml\nAlice -> Bob\nnote left of Alice : hello\n@enduml",
  )
  @test.assert_eq(result.events.length(), 2)
  match result.events[1] {
    Note(n) => @test.assert_eq(n.text, "hello")
    _ => fail("not a note")
  }
}

///|
test "parse grouping" {
  let result = parse(
    "@startuml\nAlice -> Bob\nopt condition\nBob -> Carol\nend\n@enduml",
  )
  @test.assert_eq(result.events.length(), 4)
  match result.events[1] {
    GroupingStart(g) => @test.assert_eq(g.header, "condition")
    _ => fail("not grouping start")
  }
  match result.events[3] {
    GroupingLeaf(gl) => @test.assert_eq(gl.is_end, true)
    _ => fail("not grouping leaf")
  }
}

///|
test "parse activate deactivate" {
  let result = parse(
    "@startuml\nAlice -> Bob\nactivate Bob\nBob -> Carol\ndeactivate Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 4)
  match result.events[1] {
    LifeEvent(le) => @test.assert_eq(le.participant_code, "Bob")
    _ => fail("not life event")
  }
  match result.events[3] {
    LifeEvent(le) => @test.assert_eq(le.participant_code, "Bob")
    _ => fail("not life event")
  }
}

///|
test "parse divider" {
  let result = parse(
    "@startuml\nAlice -> Bob\n== Test Title ==\nBob -> Carol\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[1] {
    Divider(d) => @test.assert_eq(d.title, "Test Title")
    _ => fail("not a divider")
  }
}

///|
test "parse delay" {
  let result = parse("@startuml\nAlice -> Bob\n...\nBob -> Carol\n@enduml")
  @test.assert_eq(result.events.length(), 3)
  match result.events[1] {
    Delay(d) => @test.assert_eq(d.label, None)
    _ => fail("not a delay")
  }
}

///|
test "parse participant declaration" {
  let result = parse(
    "@startuml\nparticipant Alice\nactor Bob\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 1)
}

///|
test "parse right-to-left arrow" {
  let result = parse("@startuml\nAlice <- Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => {
      @test.assert_eq(m.from_code, "Bob")
      @test.assert_eq(m.to_code, "Alice")
    }
    _ => fail("not a message")
  }
}

///|
test "parse dotted arrow" {
  let result = parse("@startuml\nAlice --> Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => {
      @test.assert_eq(m.from_code, "Alice")
      @test.assert_eq(m.to_code, "Bob")
      @test.assert_eq(m.arrow_config.body, Dotted)
    }
    _ => fail("not a message")
  }
}

///|
test "parse async arrow" {
  let result = parse("@startuml\nAlice ->> Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => @test.assert_eq(m.arrow_config.head2, Async)
    _ => fail("not a message")
  }
}

///|
test "registers implicit participants" {
  let result = parse("@startuml\nAlice -> Bob\n@enduml")
  @test.assert_eq(result.participants.length(), 2)
  @test.assert_eq(result.participants.contains("Alice"), true)
  @test.assert_eq(result.participants.contains("Bob"), true)
}

///|
test "participant declarations preserve aliases" {
  let result = parse(
    "@startuml\nactor \"Purchase Officer\" as po\npo -> po\n@enduml",
  )
  guard result.participants.contains("po") else { fail("missing participant") }
  @test.assert_eq(result.participants["po"].display, "Purchase Officer")
  match result.participants["po"].typ {
    Actor => ()
    _ => fail("wrong participant type")
  }
}

///|
test "keywords are case insensitive" {
  let result = parse("@STARTUML\nACTOR Alice\nAlice -> Bob\n@ENDUML")
  @test.assert_eq(result.events.length(), 1)
  @test.assert_eq(result.participants.length(), 2)
}

///|
test "create declares a participant" {
  let result = parse("@startuml\ncreate Bob\n@enduml")
  @test.assert_eq(result.participants.contains("Bob"), true)
  @test.assert_eq(result.events.length(), 1)
}

///|
test "trailing command text is not accepted as an arrow" {
  let result = parse("@startuml\nAlice -> Bob trailing\n@enduml")
  @test.assert_eq(result.events.length(), 0)
}

///|
test "participant aliases require an as keyword boundary" {
  let result = parse("@startuml\nAlice asBob -> Carol\n@enduml")
  @test.assert_eq(result.events.length(), 0)
}

///|
test "single activation suffix is not accepted" {
  let result = parse("@startuml\nAlice -> Bob +\n@enduml")
  @test.assert_eq(result.events.length(), 0)
}

///|
test "ordinary arrows have only an end head" {
  let result = parse("@startuml\nAlice -> Bob\n@enduml")
  match result.events[0] {
    Message(message) =>
      match message.arrow_config.head1 {
        NoneHead => ()
        _ => fail("unexpected start head")
      }
    _ => fail("not a message")
  }
}
