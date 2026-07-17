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
      match m.arrow_config.body {
        Dotted => ()
        _ => fail("expected dotted arrow")
      }
    }
    _ => fail("not a message")
  }
}

///|
test "parse async arrow" {
  let result = parse("@startuml\nAlice ->> Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    Message(m) =>
      match m.arrow_config.head2 {
        Async => ()
        _ => fail("expected async arrow")
      }
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

///|
test "parse a complete sequence diagram" {
  let input : String =
    #|@startuml
    #|
    #|participant "Web Client" as client #lightblue
    #|boundary Gateway
    #|control Service
    #|database Store
    #|
    #|& {request} client -> Gateway & Service : Fetch account
    #|activate Service #lime
    #|Service ->> Store : load profile
    #|note right of Service #yellow : cache miss
    #|alt #palegreen cache hit
    #|Service --> client : cached
    #|else cache miss
    #|Service -> Store ++ : query
    #|Store --> Service -- : rows
    #|end
    #|ref over client, Service : External system
    #|
    #|== Processing ==
    #|... waiting for upstream ...
    #|return response
    #|deactivate Service
    #|[-> client : HTTP request
    #|client ->] : audit
    #|box #lightblue Infrastructure
    #|participant Logger
    #|end box
    #|autonumber 1.2 3 "(0)"
    #|autonumber inc b
    #|autoactivate on
    #|hide footbox
    #|hide unlinked
    #|url of client is https://example.com
    #|auto newpage 10
    #|ignore newpage
    #|newpage summary
    #|
    #|@enduml
    #|
  let result = parse(input)

  @test.assert_eq(result.events.length(), 28)
  @test.assert_eq(result.participants.contains("client"), true)
  @test.assert_eq(result.participants.contains("Gateway"), true)
  @test.assert_eq(result.participants.contains("Service"), true)
  @test.assert_eq(result.participants.contains("Store"), true)
  @test.assert_eq(result.participants.contains("Logger"), true)
  @test.assert_eq(result.participants["client"].display, "Web Client")
  @test.assert_eq(result.autoactivate, true)
  @test.assert_eq(result.show_footbox, false)

  match result.events[0] {
    Message(message) => {
      @test.assert_eq(message.anchor, Some("request"))
      @test.assert_eq(message.parallel, true)
      @test.assert_eq(message.multicast, ["Service"])
    }
    _ => fail("not a multicast message")
  }
  match result.events[3] {
    Note(note) => @test.assert_eq(note.color, Some("yellow"))
    _ => fail("not a note")
  }
  match result.events[4] {
    GroupingStart(group) => {
      @test.assert_eq(group.header, "cache hit")
      @test.assert_eq(group.back_color_header, Some("palegreen"))
    }
    _ => fail("not a grouping start")
  }
  match result.events[7] {
    Message(message) =>
      match message.activation_spec {
        Some(Activate) => ()
        _ => fail("message did not activate")
      }
    _ => fail("not an activating message")
  }
  match result.events[10] {
    Reference(reference) => {
      @test.assert_eq(reference.participant_codes, ["client", "Service"])
      @test.assert_eq(reference.label, Some("External system"))
    }
    _ => fail("not a reference")
  }
  match result.events[15] {
    MessageExo(message) =>
      match message.exo_type {
        FromLeft => ()
        _ => fail("wrong external message direction")
      }
    _ => fail("not a left external message")
  }
  match result.events[16] {
    MessageExo(message) =>
      match message.exo_type {
        ToRight => ()
        _ => fail("wrong external message direction")
      }
    _ => fail("not a right external message")
  }
  match result.events[17] {
    BoxStart(box) => @test.assert_eq(box.color, Some("lightblue"))
    _ => fail("not a box")
  }
  match result.events[27] {
    Newpage(page) => @test.assert_eq(page.title, Some("summary"))
    _ => fail("not a newpage")
  }
  match result.auto_number {
    Some(number) => {
      @test.assert_eq(number.start, Some("1.2"))
      @test.assert_eq(number.increment, Some(3))
      @test.assert_eq(number.format, Some("(0)"))
    }
    None => fail("missing autonumber configuration")
  }
}
