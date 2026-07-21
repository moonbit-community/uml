///|
test "parse empty diagram" {
  let result = parse("@startuml\n@enduml")
  @test.assert_eq(result.events.length(), 0)
}

///|
test "parse multiline titles" {
  let result = parse(
    "@startuml\ntitle\nSequence title\nend title\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 1)
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
test "parse multiline notes" {
  let result = parse(
    "@startuml\nAlice -> Bob\nnote left of Alice\nfirst line\nsecond line\nend note\nnote top\nattached\nend note\n@enduml",
  )
  match (result.events[1], result.events[2]) {
    (Note(participant_note), Note(arrow_note)) => {
      @test.assert_eq(participant_note.text, "first line\nsecond line")
      @test.assert_eq(arrow_note.text, "attached")
      @test.assert_eq(arrow_note.on_arrow, true)
    }
    _ => fail("expected notes")
  }
}

///|
test "notes and references normalize quoted participant codes" {
  let result = parse(
    "@startuml\nparticipant \"Alice Smith\"\nnote over \"Alice Smith\" : note\nref over \"Alice Smith\" : ref\n@enduml",
  )
  @test.assert_eq(result.participants.length(), 1)
  match (result.events[0], result.events[1]) {
    (Note(note), Reference(reference)) => {
      @test.assert_eq(note.participant_codes, ["Alice Smith"])
      @test.assert_eq(reference.participant_codes, ["Alice Smith"])
    }
    _ => fail("expected note and reference")
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
test "parse multiline references" {
  let result = parse(
    "@startuml\nref over Alice, Bob\nfirst line\nsecond line\nend ref\n@enduml",
  )
  match result.events[0] {
    Reference(reference) =>
      @test.assert_eq(reference.label, Some("first line\nsecond line"))
    _ => fail("expected reference")
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
test "bare deactivate follows the latest activating message" {
  let result = parse("@startuml\nAlice -> Bob ++\ndeactivate\n@enduml")
  match result.events[1] {
    LifeEvent(life) => {
      @test.assert_eq(life.participant_code, "Bob")
      match life.event_type {
        Deactivate => ()
        _ => fail("expected deactivation")
      }
    }
    _ => fail("expected lifecycle event")
  }
}

///|
test "bare deactivate requires an activating message" {
  try parse("@startuml\ndeactivate\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "bare deactivate consumes activating messages in reverse order" {
  let result = parse(
    "@startuml\nAlice -> Bob ++\nAlice -> Carol ++\ndeactivate\ndeactivate\n@enduml",
  )
  match (result.events[2], result.events[3]) {
    (LifeEvent(first), LifeEvent(second)) => {
      @test.assert_eq(first.participant_code, "Carol")
      @test.assert_eq(second.participant_code, "Bob")
    }
    _ => fail("expected lifecycle events")
  }
}

///|
test "standalone activate can be followed by bare deactivate" {
  let result = parse(
    "@startuml\nAlice -> Bob\nactivate Bob\ndeactivate\n@enduml",
  )
  match result.events[2] {
    LifeEvent(life) => @test.assert_eq(life.participant_code, "Bob")
    _ => fail("expected lifecycle event")
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
test "delays require a closing ellipsis around labels" {
  let result = parse("@startuml\n... waiting ...\n@enduml")
  match result.events[0] {
    Delay(delay) => @test.assert_eq(delay.label, Some("waiting"))
    _ => fail("expected delay")
  }
  try parse("@startuml\n... waiting\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
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
test "unquoted participant aliases use the alias as the code" {
  let result = parse("@startuml\nparticipant Alice as Bob\nBob -> Bob\n@enduml")
  guard result.participants.contains("Bob") else { fail("missing alias") }
  @test.assert_eq(result.participants["Bob"].display, "Alice")
  @test.assert_eq(result.participants.contains("Alice"), false)
}

///|
test "participant declarations support PlantUML URLs before colors" {
  let result = parse(
    "@startuml\nparticipant Alice [[https://example.com]] #lightblue\n@enduml",
  )
  @test.assert_eq(result.participants["Alice"].url, Some("https://example.com"))
  @test.assert_eq(result.participants["Alice"].color, Some("lightblue"))
}

///|
test "quoted participant URLs use the shared URL normalizer" {
  let result = parse(
    "@startuml\nparticipant Alice [[\"https://example.com\"]]\n@enduml",
  )
  @test.assert_eq(result.participants["Alice"].url, Some("https://example.com"))
}

///|
test "keywords are case insensitive" {
  let result = parse("@STARTUML\nACTOR Alice\nAlice -> Bob\n@ENDUML")
  @test.assert_eq(result.events.length(), 1)
  @test.assert_eq(result.participants.length(), 2)
}

///|
test "create is followed by a message to the new participant" {
  let result = parse("@startuml\ncreate Bob\nAlice -> Bob\n@enduml")
  @test.assert_eq(result.participants.contains("Bob"), true)
  @test.assert_eq(result.events.length(), 2)
}

///|
test "creating an existing participant is a no-op" {
  let result = parse(
    "@startuml\nparticipant Bob\ncreate Bob\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 1)
}

///|
test "invalid arrow suffix raises a parse error" {
  try parse("@startuml\nAlice -> Bob trailing\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "invalid participant aliases raise a parse error" {
  try parse("@startuml\nAlice asBob -> Carol\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "invalid activation suffix raises a parse error" {
  try parse("@startuml\nAlice -> Bob +\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "notes over more than two participants raise a parse error" {
  try parse("@startuml\nnote over Alice, Bob, Carol : invalid\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "only over notes may span two participants" {
  try parse("@startuml\nnote left of Alice, Bob : invalid\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
  try parse("@startuml\nnote across Alice : invalid\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "non-PlantUML box order raises a parse error" {
  try parse("@startuml\nbox #lightblue Infrastructure\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "non-PlantUML auto newpage spelling raises a parse error" {
  try parse("@startuml\nauto newpage 10\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "autonewpage requires a message count" {
  try parse("@startuml\nautonewpage\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "single-line notes require their colon delimiter" {
  try parse("@startuml\nnote left of Alice\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "top and bottom notes attach to the preceding message" {
  let result = parse(
    "@startuml\nAlice -> Bob\nnote top : above\nnote bottom : below\n@enduml",
  )
  match (result.events[1], result.events[2]) {
    (Note(top), Note(bottom)) => {
      @test.assert_eq(top.on_arrow, true)
      @test.assert_eq(bottom.on_arrow, true)
      match (top.position, bottom.position) {
        (Top, Bottom) => ()
        _ => fail("wrong note positions")
      }
    }
    _ => fail("expected attached notes")
  }
}

///|
test "top notes cannot target a participant" {
  try parse("@startuml\nnote top of Alice : invalid\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "URL commands use PlantUML link syntax" {
  let result = parse(
    "@startuml\nurl of Alice is [[https://example.com/users User profile]]\n@enduml",
  )
  @test.assert_eq(
    result.participants["Alice"].url,
    Some("https://example.com/users"),
  )
}

///|
test "URL commands reject bare links" {
  try parse("@startuml\nurl of Alice is https://example.com\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "URL commands do not accept participant aliases" {
  try
    parse("@startuml\nurl of Alice as Bob [[https://example.com]]\n@enduml")
  catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
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
    #|box Infrastructure #lightblue
    #|participant Logger
    #|end box
    #|autonumber 1.2 3 "(0)"
    #|autonumber inc b
    #|autoactivate on
    #|hide footbox
    #|hide unlinked
    #|autonewpage 10
    #|ignore newpage
    #|newpage summary
    #|
    #|@enduml
    #|
  let result = parse(input)

  @test.assert_eq(result.events.length(), 26)
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
  match result.auto_number {
    Some(number) => {
      @test.assert_eq(number.start, Some("1.2"))
      @test.assert_eq(number.increment, Some(3))
      @test.assert_eq(number.format, Some("(0)"))
    }
    None => fail("missing autonumber configuration")
  }
}

///|
test "parse note variants with shared participants and arrow attachment" {
  let result = parse(
    "@startuml\nhnote over Alice, Bob #yellow : shared\nnote right : attached\n@enduml",
  )
  @test.assert_eq(result.events.length(), 2)
  match result.events[0] {
    Note(note) => {
      @test.assert_eq(note.participant_codes, ["Alice", "Bob"])
      @test.assert_eq(note.color, Some("yellow"))
      @test.assert_eq(note.on_arrow, false)
      match (note.position, note.note_style) {
        (OverSeveral, Hexagonal) => ()
        _ => fail("expected a shared hexagonal note")
      }
    }
    _ => fail("expected note")
  }
  match result.events[1] {
    Note(note) => {
      @test.assert_eq(note.text, "attached")
      @test.assert_eq(note.on_arrow, true)
    }
    _ => fail("expected arrow note")
  }
}

///|
test "parse grouping colors and parallel groups" {
  let result = parse(
    "@startuml\n& alt #header #body first\nelse #leaf second\nend\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[0] {
    GroupingStart(group) => {
      @test.assert_eq(group.parallel, true)
      @test.assert_eq(group.back_color_header, Some("header"))
      @test.assert_eq(group.back_color_body, Some("body"))
    }
    _ => fail("expected group start")
  }
  match result.events[1] {
    GroupingLeaf(leaf) => {
      @test.assert_eq(leaf.label, Some("second"))
      @test.assert_eq(leaf.back_color, Some("leaf"))
    }
    _ => fail("expected group leaf")
  }
}

///|
test "dispatch hide commands without consuming the wrong prefix" {
  let result = parse("@startuml\nhide unlinked\nhide footbox\n@enduml")
  @test.assert_eq(result.events.length(), 2)
  match result.events[0] {
    HideUnlinked(true) => ()
    _ => fail("expected hide unlinked")
  }
  match result.events[1] {
    Footbox(false) => ()
    _ => fail("expected hidden footbox")
  }
}

///|
test "show unlinked reverses hide unlinked" {
  let diagram = parse(
    "@startuml\nhide unlinked\nshow unlinked\nparticipant Orphan\n@enduml",
  )
  @test.assert_eq(diagram.hides_unlinked(), false)
}

///|
test "hide unlinked accepts the official @ prefix" {
  let diagram = parse("@startuml\nhide @unlinked\n@enduml")
  @test.assert_eq(diagram.hides_unlinked(), true)
}

///|
test "parses shared document background style" {
  let diagram = parse(
    "@startuml\nskinparam BackgroundColor #102030\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.background_color, Some("#102030"))
  @test.assert_eq(diagram.render_svg().contains("background:#102030"), true)
}

///|
test "parses shared braced skinparam background style" {
  let diagram = parse(
    "@startuml\nskinparam {\nBackgroundColor #203040\n}\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.background_color, Some("#203040"))
}

///|
test "accepts common preprocessing directives" {
  let diagram = parse("@startuml\n!define USER Alice\nUSER -> Bob\n@enduml")
  @test.assert_eq(diagram.events.length(), 1)
}

///|
test "expands shared object-like preprocessor macros" {
  let diagram = parse("@startuml\n!define USER Alice\nUSER -> Bob\n@enduml")
  @test.assert_eq(diagram.participants.contains("Alice"), true)
}

///|
test "parses shared default font style" {
  let diagram = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.font_family, Some("Courier"))
  @test.assert_eq(diagram.style.font_size, Some("16"))
  @test.assert_eq(
    diagram.render_svg().contains("font-family:Courier;font-size:16px"),
    true,
  )
}

///|
test "sequence layout and SVG receive document font roles" {
  let regular = parse(
    "@startuml\nparticipant \"VeryLongParticipantName\" as A\nA -> Bob : message\n@enduml",
  )
  let styled = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nparticipant \"VeryLongParticipantName\" as A\nA -> Bob : message\n@enduml",
  )
  let regular_layout = regular.layout()
  let styled_layout = styled.layout()
  @test.assert_eq(styled_layout.text_metrics.participant.profile, Monospace)
  @test.assert_eq(styled_layout.text_metrics.participant.font_size, 16)
  @test.assert_eq(styled_layout.text_metrics.participant.font_weight, 700)
  @test.assert_eq(styled_layout.text_metrics.body_italic.style, Italic)
  @test.assert_eq(
    styled_layout.participants[0].width > regular_layout.participants[0].width,
    true,
  )
  let svg = styled.render_svg()
  @test.assert_eq(svg.contains(".participant-label{font-size:16px"), true)
  @test.assert_eq(
    svg.contains(
      ".message-label,.reference-label,.delay-label{fill:#181818;font-size:15px",
    ),
    true,
  )
  @test.assert_eq(svg.contains(".participant-box-label{font-size:14px"), true)
}

///|
test "parses shared arrow color style" {
  let diagram = parse(
    "@startuml\nskinparam ArrowColor #ff0000\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.line_color, Some("#ff0000"))
  @test.assert_eq(diagram.render_svg().contains("stroke:#ff0000"), true)
}
