///|
test "parse empty diagram" {
  let result = parse_sequence("@startuml\n@enduml")
  @test.assert_eq(result.events.length(), 0)
}

///|
test "parse multiline titles" {
  let result = parse_sequence(
    "@startuml\ntitle\nSequence title\nend title\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 1)
}

///|
test "parse simple arrow" {
  let result = parse_sequence("@startuml\nAlice -> Bob\n@enduml")
  @test.assert_eq(result.events.length(), 1)
}

///|
test "parse arrow with label" {
  let result = parse_sequence("@startuml\nAlice -> Bob : hello\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    @seq.Message(m) => @test.assert_eq(m.label, Some("hello"))
    _ => fail("not a message")
  }
}

///|
test "parse two messages" {
  let result = parse_sequence("@startuml\nAlice -> Bob\nBob -> Carol\n@enduml")
  @test.assert_eq(result.events.length(), 2)
}

///|
test "parse note" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nnote left of Alice : hello\n@enduml",
  )
  @test.assert_eq(result.events.length(), 2)
  match result.events[1] {
    @seq.Note(n) => @test.assert_eq(n.text, "hello")
    _ => fail("not a note")
  }
}

///|
test "parse multiline notes" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nnote left of Alice\nfirst line\nsecond line\nend note\nnote top\nattached\nend note\n@enduml",
  )
  match (result.events[1], result.events[2]) {
    (@seq.Note(participant_note), @seq.Note(arrow_note)) => {
      @test.assert_eq(participant_note.text, "first line\nsecond line")
      @test.assert_eq(arrow_note.text, "attached")
      @test.assert_eq(arrow_note.on_arrow, true)
    }
    _ => fail("expected notes")
  }
}

///|
test "notes and references normalize quoted participant codes" {
  let result = parse_sequence(
    "@startuml\nparticipant \"Alice Smith\"\nnote over \"Alice Smith\" : note\nref over \"Alice Smith\" : ref\n@enduml",
  )
  @test.assert_eq(result.participants.length(), 1)
  match (result.events[0], result.events[1]) {
    (@seq.Note(note), @seq.Reference(reference)) => {
      @test.assert_eq(note.participant_codes, ["Alice Smith"])
      @test.assert_eq(reference.participant_codes, ["Alice Smith"])
    }
    _ => fail("expected note and reference")
  }
}

///|
test "parsec participant lists keep commas inside quoted names" {
  let result = parse_sequence(
    "@startuml\nparticipant \"Alice, Inc.\"\nparticipant Bob\nnote over \"Alice, Inc.\", Bob : shared\n@enduml",
  )
  match result.events[0] {
    @seq.Note(note) =>
      @test.assert_eq(note.participant_codes, ["Alice, Inc.", "Bob"])
    _ => fail("expected participant note")
  }
}

///|
test "parse grouping" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nopt condition\nBob -> Carol\nend\n@enduml",
  )
  @test.assert_eq(result.events.length(), 4)
  match result.events[1] {
    @seq.GroupingStart(g) => @test.assert_eq(g.header, "condition")
    _ => fail("not grouping start")
  }
  match result.events[3] {
    @seq.GroupingLeaf(gl) => @test.assert_eq(gl.is_end, true)
    _ => fail("not grouping leaf")
  }
}

///|
test "parse multiline references" {
  let result = parse_sequence(
    "@startuml\nref over Alice, Bob\nfirst line\nsecond line\nend ref\n@enduml",
  )
  match result.events[0] {
    @seq.Reference(reference) =>
      @test.assert_eq(reference.label, Some("first line\nsecond line"))
    _ => fail("expected reference")
  }
}

///|
test "parse activate deactivate" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nactivate Bob\nBob -> Carol\ndeactivate Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 4)
  match result.events[1] {
    @seq.LifeEvent(le) => @test.assert_eq(le.participant_code, "Bob")
    _ => fail("not life event")
  }
  match result.events[3] {
    @seq.LifeEvent(le) => @test.assert_eq(le.participant_code, "Bob")
    _ => fail("not life event")
  }
}

///|
test "bare deactivate follows the latest activating message" {
  let result = parse_sequence("@startuml\nAlice -> Bob ++\ndeactivate\n@enduml")
  match result.events[1] {
    @seq.LifeEvent(life) => {
      @test.assert_eq(life.participant_code, "Bob")
      match life.event_type {
        @seq.Deactivate => ()
        _ => fail("expected deactivation")
      }
    }
    _ => fail("expected lifecycle event")
  }
}

///|
test "bare deactivate requires an activating message" {
  try parse_sequence("@startuml\ndeactivate\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "bare deactivate consumes activating messages in reverse order" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob ++\nAlice -> Carol ++\ndeactivate\ndeactivate\n@enduml",
  )
  match (result.events[2], result.events[3]) {
    (@seq.LifeEvent(first), @seq.LifeEvent(second)) => {
      @test.assert_eq(first.participant_code, "Carol")
      @test.assert_eq(second.participant_code, "Bob")
    }
    _ => fail("expected lifecycle events")
  }
}

///|
test "standalone activate can be followed by bare deactivate" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nactivate Bob\ndeactivate\n@enduml",
  )
  match result.events[2] {
    @seq.LifeEvent(life) => @test.assert_eq(life.participant_code, "Bob")
    _ => fail("expected lifecycle event")
  }
}

///|
test "parse divider" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\n== Test Title ==\nBob -> Carol\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[1] {
    @seq.Divider(d) => @test.assert_eq(d.title, "Test Title")
    _ => fail("not a divider")
  }
}

///|
test "parse delay" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\n...\nBob -> Carol\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[1] {
    @seq.Delay(d) => @test.assert_eq(d.label, None)
    _ => fail("not a delay")
  }
}

///|
test "delays require a closing ellipsis around labels" {
  let result = parse_sequence("@startuml\n... waiting ...\n@enduml")
  match result.events[0] {
    @seq.Delay(delay) => @test.assert_eq(delay.label, Some("waiting"))
    _ => fail("expected delay")
  }
  try parse_sequence("@startuml\n... waiting\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "parse participant declaration" {
  let result = parse_sequence(
    "@startuml\nparticipant Alice\nactor Bob\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 1)
}

///|
test "sequence parser accepts comments before start and inline comments" {
  let result = parse_sequence(
    "\n' header comment\n@STARTUML\nAlice -> Bob : request ' trailing comment\n@ENDUML",
  )
  match result.events[0] {
    @seq.Message(message) => @test.assert_eq(message.label, Some("request"))
    _ => @test.fail("expected message")
  }
}

///|
test "participant redeclaration updates visible metadata" {
  let result = parse_sequence(
    "@startuml\nparticipant A #red\nparticipant A #blue\nA -> B\n@enduml",
  )
  @test.assert_eq(result.participants["A"].color, Some("blue"))
}

///|
test "parse right-to-left arrow" {
  let result = parse_sequence("@startuml\nAlice <- Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    @seq.Message(m) => {
      @test.assert_eq(m.from_code, "Bob")
      @test.assert_eq(m.to_code, "Alice")
    }
    _ => fail("not a message")
  }
}

///|
test "parse dotted arrow" {
  let result = parse_sequence("@startuml\nAlice --> Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    @seq.Message(m) => {
      @test.assert_eq(m.from_code, "Alice")
      @test.assert_eq(m.to_code, "Bob")
      match m.arrow_config.body {
        @seq.Dotted => ()
        _ => fail("expected dotted arrow")
      }
    }
    _ => fail("not a message")
  }
}

///|
test "parse async arrow" {
  let result = parse_sequence("@startuml\nAlice ->> Bob\n@enduml")
  guard result.events.length() == 1 else { fail("expected 1 event") }
  match result.events[0] {
    @seq.Message(m) =>
      match m.arrow_config.head2 {
        @seq.Async => ()
        _ => fail("expected async arrow")
      }
    _ => fail("not a message")
  }
}

///|
test "partial arrows preserve PlantUML direction and part semantics" {
  let result = parse_sequence(
    "@startuml\nAlice \\-> Bob : bottom\nAlice \\--> Bob : dotted bottom\nAlice /-> Bob : top\nAlice /--> Bob : dotted top\n@enduml",
  )
  @test.assert_eq(result.events.length(), 4)
  for event in result.events {
    match event {
      @seq.Message(message) => {
        @test.assert_eq(message.from_code, "Alice")
        @test.assert_eq(message.to_code, "Bob")
      }
      _ => fail("expected message")
    }
  }
  match (result.events[0], result.events[2]) {
    (@seq.Message(bottom), @seq.Message(top)) => {
      match bottom.arrow_config.part {
        @seq.BottomPart => ()
        _ => fail("expected bottom arrow part")
      }
      match top.arrow_config.part {
        @seq.TopPart => ()
        _ => fail("expected top arrow part")
      }
    }
    _ => fail("expected partial-arrow messages")
  }
}

///|
test "parsec message grammar preserves decorated arrows and aliases" {
  let result = parse_sequence(
    "@startuml\nparticipant \"Alice Agent\" as alice\nalice o<<-->>o Bob ++ : dispatch\n@enduml",
  )
  match result.events[0] {
    @seq.Message(message) => {
      @test.assert_eq(message.from_code, "alice")
      @test.assert_eq(message.to_code, "Bob")
      @test.assert_eq(message.label, Some("dispatch"))
      match message.activation_spec {
        Some(@seq.Activate) => ()
        _ => fail("expected activation")
      }
      @test.assert_eq(message.arrow_config.circle_start, true)
      @test.assert_eq(message.arrow_config.circle_end, true)
      match (message.arrow_config.body, message.arrow_config.head1) {
        (@seq.Dotted, @seq.Async) => ()
        _ => fail("expected dotted asynchronous arrow")
      }
    }
    _ => fail("expected message")
  }
}

///|
test "registers implicit participants" {
  let result = parse_sequence("@startuml\nAlice -> Bob\n@enduml")
  @test.assert_eq(result.participants.length(), 2)
  @test.assert_eq(result.participants.contains("Alice"), true)
  @test.assert_eq(result.participants.contains("Bob"), true)
}

///|
test "participant declarations preserve aliases" {
  let result = parse_sequence(
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
  let result = parse_sequence(
    "@startuml\nparticipant Alice as Bob\nBob -> Bob\n@enduml",
  )
  guard result.participants.contains("Bob") else { fail("missing alias") }
  @test.assert_eq(result.participants["Bob"].display, "Alice")
  @test.assert_eq(result.participants.contains("Alice"), false)
}

///|
test "participant declarations support PlantUML URLs before colors" {
  let result = parse_sequence(
    "@startuml\nparticipant Alice [[https://example.com]] #lightblue\n@enduml",
  )
  @test.assert_eq(result.participants["Alice"].url, Some("https://example.com"))
  @test.assert_eq(result.participants["Alice"].color, Some("lightblue"))
}

///|
test "quoted participant URLs use the shared URL normalizer" {
  let result = parse_sequence(
    "@startuml\nparticipant Alice [[\"https://example.com\"]]\n@enduml",
  )
  @test.assert_eq(result.participants["Alice"].url, Some("https://example.com"))
}

///|
test "keywords are case insensitive" {
  let result = parse_sequence("@STARTUML\nACTOR Alice\nAlice -> Bob\n@ENDUML")
  @test.assert_eq(result.events.length(), 1)
  @test.assert_eq(result.participants.length(), 2)
}

///|
test "create is followed by a message to the new participant" {
  let result = parse_sequence("@startuml\ncreate Bob\nAlice -> Bob\n@enduml")
  @test.assert_eq(result.participants.contains("Bob"), true)
  @test.assert_eq(result.events.length(), 2)
}

///|
test "create with an unquoted code and quoted display uses the code in messages" {
  let result = parse_sequence(
    "@startuml\ncreate Bob as \"Bobby Tables\"\nAlice -> Bob\n@enduml",
  )
  guard result.participants.contains("Bob") else {
    fail("missing created participant")
  }
  @test.assert_eq(result.participants["Bob"].display, "Bobby Tables")
  @test.assert_eq(result.events.length(), 2)
}

///|
test "creating an existing participant is a no-op" {
  let result = parse_sequence(
    "@startuml\nparticipant Bob\ncreate Bob\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(result.events.length(), 1)
}

///|
test "invalid arrow suffix raises a parse error" {
  try parse_sequence("@startuml\nAlice -> Bob trailing\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "invalid participant aliases raise a parse error" {
  try parse_sequence("@startuml\nAlice asBob -> Carol\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "invalid activation suffix raises a parse error" {
  try parse_sequence("@startuml\nAlice -> Bob +\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "notes over more than two participants raise a parse error" {
  try
    parse_sequence("@startuml\nnote over Alice, Bob, Carol : invalid\n@enduml")
  catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "only over notes may span two participants" {
  try
    parse_sequence("@startuml\nnote left of Alice, Bob : invalid\n@enduml")
  catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
  try parse_sequence("@startuml\nnote across Alice : invalid\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "across notes parse color stereotype and url like the java factory" {
  let diagram = parse_sequence(
    "@startuml\nAlice -> Bob\nnote <<first>> across <<second>> #yellow [[https://example.com]] : shared\n@enduml",
  )
  match diagram.events[1] {
    @seq.Note(note) => {
      @test.assert_eq(note.position is @seq.Across, true)
      @test.assert_eq(note.color, Some("yellow"))
      @test.assert_eq(note.stereotype, Some("<<first>>"))
      @test.assert_eq(note.url, Some("https://example.com"))
      @test.assert_eq(note.text, "shared")
    }
    _ => fail("expected an across note")
  }
}

///|
test "a leading slash merges a note with the previous note" {
  let diagram = parse_sequence(
    "@startuml\nnote across #yellow : first\n/note across : second\n/note across #red : third\nnote across : standalone\n@enduml",
  )
  match diagram.events[0] {
    @seq.Notes(notes) => {
      @test.assert_eq(notes.length(), 3)
      @test.assert_eq(notes[0].text, "first")
      @test.assert_eq(notes[0].color, Some("yellow"))
      @test.assert_eq(notes[1].text, "second")
      @test.assert_eq(notes[1].color, None)
      @test.assert_eq(notes[2].text, "third")
      @test.assert_eq(notes[2].color, Some("red"))
    }
    _ => fail("expected merged notes")
  }
  match diagram.events[1] {
    @seq.Note(note) => @test.assert_eq(note.text, "standalone")
    _ => fail("expected a plain note after the merged group")
  }
}

///|
test "a leading slash after a message does not merge" {
  let diagram = parse_sequence(
    "@startuml\nAlice -> Bob\n/note across : orphan\n@enduml",
  )
  match diagram.events[1] {
    @seq.Note(note) => @test.assert_eq(note.text, "orphan")
    _ => fail("expected a plain note after a message")
  }
}

///|
test "the accross misspelling is accepted then rejected with an error" {
  try parse_sequence("@startuml\nnote accross : text\n@enduml") catch {
    SyntaxError(_, message) =>
      @test.assert_eq(message, "Use 'across' instead of 'accross'")
  } noraise {
    _ => fail("expected the accross error")
  }
}

///|
test "non-PlantUML box order raises a parse error" {
  try
    parse_sequence("@startuml\nbox #lightblue Infrastructure\n@enduml")
  catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "non-PlantUML auto newpage spelling raises a parse error" {
  try parse_sequence("@startuml\nauto newpage 10\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "autonewpage requires a message count" {
  try parse_sequence("@startuml\nautonewpage\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "single-line notes require their colon delimiter" {
  try parse_sequence("@startuml\nnote left of Alice\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "top and bottom notes attach to the preceding message" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nnote top : above\nnote bottom : below\n@enduml",
  )
  match (result.events[1], result.events[2]) {
    (@seq.Note(top), @seq.Note(bottom)) => {
      @test.assert_eq(top.on_arrow, true)
      @test.assert_eq(bottom.on_arrow, true)
      match (top.position, bottom.position) {
        (@seq.Top, @seq.Bottom) => ()
        _ => fail("wrong note positions")
      }
    }
    _ => fail("expected attached notes")
  }
}

///|
test "top notes cannot target a participant" {
  try parse_sequence("@startuml\nnote top of Alice : invalid\n@enduml") catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "URL commands use PlantUML link syntax" {
  let result = parse_sequence(
    "@startuml\nurl of Alice is [[https://example.com/users User profile]]\n@enduml",
  )
  @test.assert_eq(
    result.participants["Alice"].url,
    Some("https://example.com/users"),
  )
}

///|
test "URL commands reject bare links" {
  try
    parse_sequence("@startuml\nurl of Alice is https://example.com\n@enduml")
  catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "URL commands do not accept participant aliases" {
  try
    parse_sequence(
      "@startuml\nurl of Alice as Bob [[https://example.com]]\n@enduml",
    )
  catch {
    SyntaxError(_, _) => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "ordinary arrows have only an end head" {
  let result = parse_sequence("@startuml\nAlice -> Bob\n@enduml")
  match result.events[0] {
    @seq.Message(message) =>
      match message.arrow_config.head1 {
        @seq.NoneHead => ()
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
  let result = parse_sequence(input)

  @test.assert_eq(result.events.length(), 27)
  @test.assert_eq(result.participants.contains("client"), true)
  @test.assert_eq(result.participants.contains("Gateway"), true)
  @test.assert_eq(result.participants.contains("Service"), true)
  @test.assert_eq(result.participants.contains("Store"), true)
  @test.assert_eq(result.participants.contains("Logger"), true)
  @test.assert_eq(result.participants["client"].display, "Web Client")
  @test.assert_eq(result.autoactivate, true)
  @test.assert_eq(result.show_footbox, false)

  match result.events[0] {
    @seq.Message(message) => @test.assert_eq(message.anchor, Some("request"))
    _ => fail("not a multicast message")
  }
  match result.events[3] {
    @seq.Note(note) => @test.assert_eq(note.color, Some("yellow"))
    _ => fail("not a note")
  }
  match result.events[4] {
    @seq.GroupingStart(group) => {
      @test.assert_eq(group.header, "cache hit")
      @test.assert_eq(group.back_color_header, Some("palegreen"))
    }
    _ => fail("not a grouping start")
  }
  match result.events[7] {
    @seq.Message(message) =>
      match message.activation_spec {
        Some(@seq.Activate) => ()
        _ => fail("message did not activate")
      }
    _ => fail("not an activating message")
  }
  match result.events[10] {
    @seq.Reference(reference) => {
      @test.assert_eq(reference.participant_codes, ["client", "Service"])
      @test.assert_eq(reference.label, Some("External system"))
    }
    _ => fail("not a reference")
  }
  match result.events[15] {
    @seq.MessageExo(message) =>
      match message.exo_type {
        @seq.FromLeft => ()
        _ => fail("wrong external message direction")
      }
    _ => fail("not a left external message")
  }
  match result.events[16] {
    @seq.MessageExo(message) =>
      match message.exo_type {
        @seq.ToRight => ()
        _ => fail("wrong external message direction")
      }
    _ => fail("not a right external message")
  }
  match result.events[17] {
    @seq.BoxStart(box) => @test.assert_eq(box.color, Some("lightblue"))
    _ => fail("not a box")
  }
  let mut autonumber = None
  for event in result.events {
    if event is @seq.Autonumber(config) {
      autonumber = Some(config)
    }
  }
  match autonumber {
    Some(number) => {
      @test.assert_eq(number.start, Some("1.2"))
      @test.assert_eq(number.increment, Some(3))
      @test.assert_eq(number.format, Some("(0)"))
    }
    None => fail("missing autonumber configuration")
  }
}

///|
test "parse colored participant boxes from the advanced example" {
  let diagram = parse_sequence(
    "@startuml\n\nbox Frontend #lightyellow\nparticipant Client\nend box\n@enduml",
  )
  @test.assert_eq(
    diagram.participants["Client"].boxes[0].label,
    Some("Frontend"),
  )
  @test.assert_eq(
    diagram.participants["Client"].boxes[0].color,
    Some("lightyellow"),
  )
}

///|
test "parse note variants with shared participants and arrow attachment" {
  let result = parse_sequence(
    "@startuml\nhnote over Alice, Bob #yellow : shared\nAlice -> Bob\nnote right : attached\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[0] {
    @seq.Note(note) => {
      @test.assert_eq(note.participant_codes, ["Alice", "Bob"])
      @test.assert_eq(note.color, Some("yellow"))
      @test.assert_eq(note.on_arrow, false)
      match (note.position, note.note_style) {
        (@seq.OverSeveral, @seq.Hexagonal) => ()
        _ => fail("expected a shared hexagonal note")
      }
    }
    _ => fail("expected note")
  }
  match result.events[2] {
    @seq.Note(note) => {
      @test.assert_eq(note.text, "attached")
      @test.assert_eq(note.on_arrow, true)
    }
    _ => fail("expected arrow note")
  }
}

///|
test "on-arrow notes without a preceding carrier are dropped like java" {
  let result = parse_sequence(
    "@startuml\nnote top : orphan\nnote bottom : also orphan\n@enduml",
  )
  @test.assert_eq(result.events.length(), 0)
}

///|
test "top and bottom notes are dropped after a reference carrier" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nref over Alice, Bob : call\nnote top : gone\nnote bottom : also gone\n@enduml",
  )
  match result.events[1] {
    @seq.Reference(_) => ()
    _ => fail("expected the reference")
  }
  @test.assert_eq(result.events.length(), 2)
}

///|
test "left and right notes survive a reference carrier" {
  let result = parse_sequence(
    "@startuml\nAlice -> Bob\nref over Alice, Bob : call\nnote left : kept\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[2] {
    @seq.Note(note) => {
      @test.assert_eq(note.text, "kept")
      @test.assert_eq(note.on_arrow, true)
    }
    _ => fail("expected the left note")
  }
}

///|
test "parse grouping colors and parallel groups" {
  let result = parse_sequence(
    "@startuml\n& alt #header #body first\nelse #leaf second\nend\n@enduml",
  )
  @test.assert_eq(result.events.length(), 3)
  match result.events[0] {
    @seq.GroupingStart(group) => {
      @test.assert_eq(group.parallel, true)
      @test.assert_eq(group.back_color_header, Some("header"))
      @test.assert_eq(group.back_color_body, Some("body"))
    }
    _ => fail("expected group start")
  }
  match result.events[1] {
    @seq.GroupingLeaf(leaf) => {
      @test.assert_eq(leaf.label, Some("second"))
      @test.assert_eq(leaf.back_color, Some("leaf"))
    }
    _ => fail("expected group leaf")
  }
}

///|
test "dispatch hide commands without consuming the wrong prefix" {
  let result = parse_sequence("@startuml\nhide unlinked\nhide footbox\n@enduml")
  @test.assert_eq(result.events.length(), 2)
  match result.events[0] {
    @seq.HideUnlinked(true) => ()
    _ => fail("expected hide unlinked")
  }
  match result.events[1] {
    @seq.Footbox(false) => ()
    _ => fail("expected hidden footbox")
  }
}

///|
test "parses shared document background style" {
  let diagram = parse_sequence(
    "@startuml\nskinparam BackgroundColor #102030\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.background_color, Some("#102030"))
}

///|
test "parses shared braced skinparam background style" {
  let diagram = parse_sequence(
    "@startuml\nskinparam {\nBackgroundColor #203040\n}\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.background_color, Some("#203040"))
}

///|
test "accepts common preprocessing directives" {
  let diagram = parse_sequence(
    "@startuml\n!define USER Alice\nUSER -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.events.length(), 1)
}

///|
test "expands shared object-like preprocessor macros" {
  let diagram = parse_sequence(
    "@startuml\n!define USER Alice\nUSER -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.participants.contains("Alice"), true)
}

///|
test "parses shared default font style" {
  let diagram = parse_sequence(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.font_family, Some("Courier"))
  @test.assert_eq(diagram.style.font_size, Some("16"))
}

///|
test "parses shared arrow color style" {
  let diagram = parse_sequence(
    "@startuml\nskinparam ArrowColor #ff0000\nAlice -> Bob\n@enduml",
  )
  @test.assert_eq(diagram.style.line_color, Some("#ff0000"))
}
