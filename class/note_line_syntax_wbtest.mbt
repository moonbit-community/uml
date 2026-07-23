///|
test "class note line grammar accepts complete annotation lines" {
  let lines = [
    "note right of User : authenticated user", "note bottom of User <<warning>> [[https://example.com/note]] #pink {",
    "note right on link #yellow : sync", "note of link", "note left of User::login() #lightblue",
    "note \"shared note\" as N1 $shared <<info>> #yellow", "note as N2 {", "constraint on links #pink : {xor}",
  ]
  for line in lines {
    guard class_annotation_line_parser().parse(@talcparsec.Input::new(line))
      is Ok(_) else {
      @test.fail("expected annotation syntax: \{line}")
    }
  }
}

///|
test "class note line grammar rejects trailing or incomplete syntax" {
  let lines = [
    "note right of", "note sideways of User", "note left of User::", "constraint on links #pink",
    "note right of User unexpected metadata",
  ]
  for line in lines {
    guard class_annotation_line_parser().parse(@talcparsec.Input::new(line))
      is Err(_) else {
      @test.fail("unexpected annotation syntax: \{line}")
    }
  }
}
