///|
fn parse_message_line(line : String) -> @seq.Event? {
  let cursor = @parse.Cursor::new(line)
  complete_message_line_syntax(cursor)
}

///|
test "message line grammar parses complete messages" {
  let lines = [
    "Alice -> Bob", "Bob --> Alice : response", "& {request} alice o<<-->>o Bob ++ #red : dispatch",
    "[-> Alice : incoming", "Alice ->] : outgoing",
  ]
  for line in lines {
    guard parse_message_line(line) is Some(_) else {
      @test.fail("message grammar rejected: " + line)
    }
  }
}

///|
test "message line grammar rejects malformed messages" {
  let lines = [
    "Alice ->", "- Bob", "Alice Bob", "Alice -> Bob extra", "[->] Alice", "-> Alice",
    "Alice -> Bob ++ x", "Alice -- Bob", "Alice -> Bob &", "Alice -> Bob & alice &",
  ]
  for line in lines {
    guard parse_message_line(line) is None else {
      @test.fail("message grammar accepted: " + line)
    }
  }
}

///|
test "message line grammar preserves activation, color and label" {
  match parse_message_line("Alice -> Bob ++ #red : dispatch") {
    Some(@seq.Message(message)) => {
      guard message.activation_spec is Some(@seq.Activate) else {
        @test.fail("expected Activate activation spec")
      }
      @test.assert_eq(message.life_color, Some("red"))
      @test.assert_eq(message.label, Some("dispatch"))
      @test.assert_eq(message.from_code, "Alice")
      @test.assert_eq(message.to_code, "Bob")
    }
    _ => fail("expected a message event")
  }
}

///|
test "message line grammar maps arrow direction" {
  match parse_message_line("Alice <- Bob") {
    Some(@seq.Message(message)) => {
      @test.assert_eq(message.from_code, "Bob")
      @test.assert_eq(message.to_code, "Alice")
    }
    _ => fail("expected a message event")
  }
}

///|
test "message line grammar matches exo arrows" {
  match parse_message_line("[-> Alice : incoming") {
    Some(@seq.MessageExo(message)) => {
      guard message.exo_type is @seq.FromLeft else {
        @test.fail("expected a FromLeft exo message")
      }
      @test.assert_eq(message.label, Some("incoming"))
    }
    _ => fail("expected a left exo event")
  }
  match parse_message_line("Alice ->] : outgoing") {
    Some(@seq.MessageExo(message)) => {
      guard message.exo_type is @seq.ToRight else {
        @test.fail("expected a ToRight exo message")
      }
      @test.assert_eq(message.label, Some("outgoing"))
    }
    _ => fail("expected a right exo event")
  }
}

///|
test "message line grammar matches multicast participants" {
  match parse_message_line("Alice -> Bob & alice & bobby") {
    Some(@seq.Message(_)) => ()
    _ => fail("expected a message event")
  }
}

///|
test "message line grammar supports anchors and parallels" {
  let lines = [
    "& {request} client -> Gateway & Service : Fetch account", "client{part1} -> Gateway{part2} : with anchors",
  ]
  for line in lines {
    guard parse_message_line(line) is Some(_) else {
      @test.fail("message grammar rejected: " + line)
    }
  }
}
