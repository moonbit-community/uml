///|
test "command line grammar parses complete single-line commands" {
  let lines = [
    "alt #green #white accepted", "else #red rejected", "end", "box Infrastructure #lightblue",
    "box Frontend #lightyellow", "end box", "activate Service #lime", "deactivate Service",
    "deactivate", "destroy Service", "== section ==", "... waiting ...", "||20||",
    "newpage summary", "autonumber 1.2 3 \"(0)\"", "autonumber inc b", "autoactivate on",
    "hide footbox", "hide @unlinked", "url of Alice is [[https://example.com User]]",
    "return response", "ignore newpage", "autonewpage 10", "{left} <-> {right} : link",
  ]
  for line in lines {
    guard simple_event_line_parser().parse(@talc.Input::new(line))
      is Ok(_) else {
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
    guard participant_declaration_line_parser().parse(
        @talc.Input::new(line),
      )
      is Ok(_) else {
      @test.fail("participant grammar rejected: " + line)
    }
  }
}
