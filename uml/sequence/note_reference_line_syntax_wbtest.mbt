///|
test "note line grammar parses supported note headers" {
  guard participant_list(@parse.Cursor::new("Bob #yellow : cached")) is Some(_) else {
    @test.fail("participant prefix failed")
  }
  guard participant_note_tail(
      @parse.Cursor::new("of Bob #yellow : cached"),
      Right,
      NodeNormal,
      true,
    )
    is Some(_) else {
    @test.fail("participant note tail failed")
  }
  let lines = [
    "note right of Bob #yellow : cached", "note left of Alice : first", "note top : above",
    "hnote over Alice, Bob #yellow : shared", "note right : attached", "note left of Alice",
  ]
  for line in lines {
    guard note_line_syntax(@parse.Cursor::new(line)) is Some(_) else {
      @test.fail("note grammar rejected: " + line)
    }
  }
}

///|
test "reference line grammar parses inline and multiline headers" {
  for line in ["ref over Alice, Bob : External", "ref over Alice, Bob"] {
    guard reference_line_syntax(@parse.Cursor::new(line)) is Some(_) else {
      @test.fail("reference grammar rejected: " + line)
    }
  }
}

///|
test "note position dispatch follows the command factory" {
  match note_line_syntax(@parse.Cursor::new("note over Alice, Bob : shared")) {
    Some(note) => @test.assert_eq(note.position is OverSeveral, true)
    _ => @test.fail("over several rejected")
  }
  match note_line_syntax(@parse.Cursor::new("note across : text")) {
    Some(note) =>
      match note.text {
        Inline(text) => @test.assert_eq(text, "text")
        Multiline => @test.fail("across inline text lost")
      }
    _ => @test.fail("across inline note rejected")
  }
  guard note_line_syntax(@parse.Cursor::new("note across #yellow : text"))
    is None else {
    @test.fail("single-space colored across note accepted")
  }
}

///|
test "participant lists tolerate trailing commas like sep_by1" {
  match participant_list(@parse.Cursor::new("Alice, Bob,")) {
    Some(codes) => @test.assert_eq(codes, ["Alice", "Bob"])
    _ => @test.fail("trailing comma rejected")
  }
  match participant_list(@parse.Cursor::new("\"Alice, Inc.\", Bob")) {
    Some(codes) => @test.assert_eq(codes, ["Alice, Inc.", "Bob"])
    _ => @test.fail("quoted list rejected")
  }
  guard participant_list(@parse.Cursor::new(", Alice")) is None else {
    @test.fail("leading comma accepted")
  }
}

///|
test "note participants are validated per position" {
  guard participant_note_tail(
      @parse.Cursor::new("of Alice, Bob : text"),
      Left,
      NodeNormal,
      true,
    )
    is None else {
    @test.fail("left note accepted two participants")
  }
  guard participant_note_tail(
      @parse.Cursor::new("of Alice, Bob, Carol : text"),
      Over,
      NodeNormal,
      false,
    )
    is None else {
    @test.fail("over note accepted three participants")
  }
}
