///|
test "message line grammar parses complete messages" {
  let lines = [
    "Alice -> Bob", "Bob --> Alice : response", "& {request} alice o<<-->>ox Bob ++ #red : dispatch",
    "[-> Alice : incoming", "Alice ->] : outgoing",
  ]
  for line in lines {
    guard complete_message_line_parser().parse(@talc.Input::new(line))
      is Ok(_) else {
      @test.fail("message grammar rejected: " + line)
    }
  }
}
