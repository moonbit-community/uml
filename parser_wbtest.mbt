///|
test "parse empty diagram" {
  let result = parse("@startuml\n@enduml")
  inspect(result.events.length(), content="0")
}

///|
test "parse simple arrow" {
  let result = parse("@startuml\nAlice -> Bob\n@enduml")
  inspect(result.events.length(), content="1")
}

///|
test "parse arrow with label" {
  let result = parse("@startuml\nAlice -> Bob : hello\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => inspect(m.label, content="Some(hello)")
    _ => fail("not a message")
  }
}

///|
test "parse two messages" {
  let result = parse("@startuml\nAlice -> Bob\nBob -> Carol\n@enduml")
  inspect(result.events.length(), content="2")
}

///|
test "parse note" {
  let result = parse(
    "@startuml\nAlice -> Bob\nnote left of Alice : hello\n@enduml",
  )
  inspect(result.events.length(), content="2")
  match result.events[1] {
    Note(n) => inspect(n.text, content="hello")
    _ => fail("not a note")
  }
}

///|
test "parse grouping" {
  let result = parse(
    "@startuml\nAlice -> Bob\nopt condition\nBob -> Carol\nend\n@enduml",
  )
  inspect(result.events.length(), content="4")
  match result.events[1] {
    GroupingStart(g) => inspect(g.header, content="condition")
    _ => fail("not grouping start")
  }
  match result.events[3] {
    GroupingLeaf(gl) => inspect(gl.is_end, content="true")
    _ => fail("not grouping leaf")
  }
}

///|
test "parse activate deactivate" {
  let result = parse(
    "@startuml\nAlice -> Bob\nactivate Bob\nBob -> Carol\ndeactivate Bob\n@enduml",
  )
  inspect(result.events.length(), content="4")
  match result.events[1] {
    LifeEvent(le) => inspect(le.participant_code, content="Bob")
    _ => fail("not life event")
  }
  match result.events[3] {
    LifeEvent(le) => inspect(le.participant_code, content="Bob")
    _ => fail("not life event")
  }
}

///|
test "parse divider" {
  let result = parse(
    "@startuml\nAlice -> Bob\n== Test Title ==\nBob -> Carol\n@enduml",
  )
  inspect(result.events.length(), content="3")
  match result.events[1] {
    Divider(d) => inspect(d.title, content="Test Title")
    _ => fail("not a divider")
  }
}

///|
test "parse delay" {
  let result = parse("@startuml\nAlice -> Bob\n...\nBob -> Carol\n@enduml")
  inspect(result.events.length(), content="3")
  match result.events[1] {
    Delay(d) => inspect(d.label, content="None")
    _ => fail("not a delay")
  }
}

///|
test "parse participant declaration" {
  let result = parse(
    "@startuml\nparticipant Alice\nactor Bob\nAlice -> Bob\n@enduml",
  )
  inspect(result.events.length(), content="1")
}

///|
test "parse right-to-left arrow" {
  let result = parse("@startuml\nAlice <- Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => {
      inspect(m.from_code, content="Bob")
      inspect(m.to_code, content="Alice")
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
      inspect(m.from_code, content="Alice")
      inspect(m.to_code, content="Bob")
      // body: Solid=0, Dotted=1
      let body_int = match m.arrow_config.body {
        Solid => 0
        Dotted => 1
        Hidden => 2
      }
      inspect(body_int, content="1")
    }
    _ => fail("not a message")
  }
}

///|
test "parse async arrow" {
  let result = parse("@startuml\nAlice ->> Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) => {
      let head = m.arrow_config.head2
      let head_int = match head {
        Normal => 0
        Async => 1
        CrossX => 2
        NoneHead => 3
      }
      inspect(head_int, content="1")
    }
    _ => fail("not a message")
  }
}

///|
test "registers implicit participants" {
  let result = parse("@startuml\nAlice -> Bob\n@enduml")
  inspect(result.participants.length(), content="2")
  inspect(result.participants.contains("Alice"), content="true")
  inspect(result.participants.contains("Bob"), content="true")
}

///|
test "participant declarations preserve aliases" {
  let result = parse(
    "@startuml\nactor \"Purchase Officer\" as po\npo -> po\n@enduml",
  )
  guard result.participants.contains("po") else { fail("missing participant") }
  inspect(result.participants["po"].display, content="Purchase Officer")
  match result.participants["po"].typ {
    Actor => ()
    _ => fail("wrong participant type")
  }
}

///|
test "keywords are case insensitive" {
  let result = parse("@STARTUML\nACTOR Alice\nAlice -> Bob\n@ENDUML")
  inspect(result.events.length(), content="1")
  inspect(result.participants.length(), content="2")
}

///|
test "create declares a participant" {
  let result = parse("@startuml\ncreate Bob\n@enduml")
  inspect(result.participants.contains("Bob"), content="true")
  inspect(result.events.length(), content="1")
}

///|
test "trailing command text is not accepted as an arrow" {
  let result = parse("@startuml\nAlice -> Bob trailing\n@enduml")
  inspect(result.events.length(), content="0")
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
