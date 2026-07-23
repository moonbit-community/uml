///|
test "note line grammar parses supported note headers" {
  guard participant_list_prefix_parser().run(
      @talc.Input::new("Bob #yellow : cached"),
    )
    is Ok(_) else {
    @test.fail("participant prefix failed")
  }
  guard participant_note_tail_parser(Right, NodeNormal, true).parse(
      @talc.Input::new("of Bob #yellow : cached"),
    )
    is Ok(_) else {
    @test.fail("participant note tail failed")
  }
  let lines = [
    "note right of Bob #yellow : cached", "note left of Alice : first", "note top : above",
    "hnote over Alice, Bob #yellow : shared", "note right : attached", "note left of Alice",
  ]
  for line in lines {
    guard note_line_parser().parse(@talc.Input::new(line)) is Ok(_) else {
      @test.fail("note grammar rejected: " + line)
    }
  }
}

///|
test "reference line grammar parses inline and multiline headers" {
  for line in ["ref over Alice, Bob : External", "ref over Alice, Bob"] {
    guard reference_line_parser().parse(@talc.Input::new(line)) is Ok(_) else {
      @test.fail("reference grammar rejected: " + line)
    }
  }
}
