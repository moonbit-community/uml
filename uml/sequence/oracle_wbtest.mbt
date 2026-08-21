///|
test "message grammar matches plantuml oracle" {
  let cases = [
    "Alice -> Bob", "Alice ox<-- Bob", "Alice <(4)-- Bob", "Alice (4)<-- Bob", "Alice ->(4) Bob",
    "Alice ->o(4) Bob", "Alice o(4)<-- Bob", "Alice (4)o<-- Bob", "Alice ->o Bob",
    "Alice ->oBob", "Alice ->ox Bob", "Alice ->x Bob", "Alice ->xBob", "Alice {x}-> Bob",
    "Alice {x} -> Bob", "Alice{x} -> Bob", "Alice{x}-> Bob", "Alice{x}->> Bob", "& {req}Alice -> Bob",
    "Alice -> Bob &alice", "Alice -> Bob&alice", "Alice -> Bob  & alice", "Alice -> Bob & alice",
    "Alice -> Bob & alice &", "Alice -> Bob & alice &x", "Alice -> Bob & alice & x",
    "Alice <_- Bob", "Alice <_ Bob", "Alice _<- Bob", "Alice <-_ Bob", "Alice <<_- Bob",
    "Alice <<_ Bob", "Alice ->_ Bob", "Alice ->_o Bob", "Alice ->_> Bob", "Alice ->>_o Bob",
    "Alice ->o] ", "Alice ->o]", "Alice ->x]", "Alice ->o?]", "Alice ->ox]", "[o-> Alice",
    "[x-> Alice", "[?o-> Alice", "[?-> Alice", "[ox-> Alice", "[o?-> Alice", "[-> \"Alice\" as A",
    "[-> Alice as B", "[-> Alice +", "[-> Alice ++", "[-> Alice +++", "[-> Alice -",
    "[-> Alice !", "[-> Alice *", "[-> Alice +-", "[-> Alice *+", "[-> Alice !!+",
    "[-> Alice ++x", "Alice ->] +", "Alice ->] ++", "Alice ->] +++", "Alice ->] *",
    "Alice ->] !!", "[-> Alice ]", "[-> Alice]", "[-> Alice extra", "Alice ->] extra",
    "[->", "Alice ->]", "[- Alice", "[>- Alice", "[<- Alice", "Alice <-> Bob", "Alice <<-->> Bob",
    "Alice -> Bob # red", "Alice -> Bob ++ --", "Alice -> Bob --++", "Alice -> Bob ++--",
    "Alice -> Bob **", "Alice -> Bob !!", "Alice -> Bob +", "Alice -> Bob -", "Alice -> Bob !",
    "Alice -> Bob *", "Alice -> Bob x", "Alice {a}{b} -> Bob", "Alice {a} {b} -> Bob",
    "{req} Alice -> Bob", "& {req} Alice -> Bob", "& {req}Alice -> Bob", "&{req} Alice -> Bob",
    "&  {req} Alice -> Bob", "Alice -> Bob{x} : hi", "Alice -> Bob {x} : hi", "Alice{x} -> Bob : hi",
    "Alice o<--Bob", "Alice xo<-->ox Bob", "Alice o<-- Bob", "Alice -(4)-> Bob",
    "Alice o<--o Bob", "Alice <--x Bob", "Alice <--o Bob", "Alice o<--x Bob", "Alice o<<-- Bob",
    "Alice ->o Bob", "Alice ->o  Bob", "Alice ->ox  Bob", "Alice o -> Bob", "Alice o-> Bob",
    "[->o Alice", "[->oAlice", "[->o Alice : hi", "Alice o->]", "Aliceo->]", "Alice x->]",
    "Alice ->]x", "Alice ->]? ", "Alice -[#red]-> Bob", "Alice -[#red]--> Bob", "Alice -[]-> Bob",
    "Alice ->[] Bob", "Alice -> Bob : \"\"", "Alice -> Bob :\"x\"", "Alice -> Bob  : hi",
    "Alice -> Bob :", "Alice -> Bob : ", "Alice ->Bob", "Alice -> Bob #", "Alice -> Bob # red",
    "Alice -> Bob #red", "Alice -> Bob ++ #red : hi", "Alice -> Bob ++#red", "Alice -> Bob & & alice",
    "Alice -> Bob & alice &&", "Alice -> Bob & &", "Alice -> Bob & alice & x & y",
    "\"Alice Smith\" -> Bob", "\"Alice Smith\" as A -> Bob", "A as \"Alice Smith\" -> Bob",
    "A as Bob -> Carl", "\"Alice\" as \"B\" -> \"C\" as \"D\"", "\"Alice\" as A -> \"Bob\" as B",
    "\"A\" as B -> C", "\"unclosed -> Bob", "Alice\" -> Bob", "\"Alice\" -> \"Bob\"",
    "Alice -> \"Bob\" as B", "\"Alice\" -> Bob as \"Bobby\"", "[-> \"Alice\" : hi",
    "[\"Alice\" -> Bob", "[\"Alice\" ->] : out", "Alice -> \"Bob\"]", "[-> \"Alice\" as A",
    "Alice -> Bob as \"B\"", "Alice -> Bob <<stereo>> : hi", "Alice -> Bob <<stereo>>",
    "Alice -> Bob <<stereo>> #red", "Alice -> Bob #red <<stereo>> : hi", "Alice -> Bob [[https://example.com]] : hi",
    "Alice -> Bob [[https://example.com]]", "Alice -> Bob <<s>> [[https://example.com]] : hi",
    "Alice -> Bob #yellow-red : hi", "Alice -> Bob #yellow-red", "Alice -> Bob #red [[https://example.com]] : hi",
    "Alice -> Bob <<s>> <<t>> : hi", "Alice -> Bob #abc.def : hi", "Alice -> Bob <<s>>",
    "[-> Alice <<s>> : hi", "[-> Alice [[https://example.com]] : hi", "Alice ->] [[https://example.com]] : hi",
    "[-> Alice [[https://example.com]]", "[-> Alice #yellow-red : hi", "Alice -> Bob <<s>> #red : hi",
    "Alice -> Bob [[url]] <<s>> : hi", "Alice -> Bob <<s>>[[url]] : hi", "Alice -> Bob #red[[url]] : hi",
    "Alice -> Bob <<s>> [[url]] <<t>> : hi", "Alice -> Bob <<s>> #yellow <<t>> : hi",
  ]
  let expected = [
    "M:Alice>Bob:a=:c=:m=:s=:u=", "N", "N", "M:Bob>Alice:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "N", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>oBob:a=:c=:m=:s=:u=", "N",
    "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>xBob:a=:c=:m=:s=:u=", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "N", "N", "N", "N", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "M:Bob>Alice:a=:c=:m=:s=:u=", "N", "N", "N", "M:Bob>Alice:a=:c=:m=:s=:u=", "N",
    "N", "N", "N", "N", "E:R:Alice:u=", "E:R:Alice:u=", "E:R:Alice:u=", "N", "N",
    "E:L:Alice:u=", "E:L:Alice:u=", "N", "N", "N", "N", "N", "N", "E:L:Alice:u=",
    "E:L:Alice:u=", "E:L:Alice:u=", "E:L:Alice:u=", "E:L:Alice:u=", "E:L:Alice:u=",
    "E:L:Alice:u=", "E:L:Alice:u=", "E:L:Alice:u=", "N", "E:R:Alice:u=", "E:R:Alice:u=",
    "E:R:Alice:u=", "E:R:Alice:u=", "E:R:Alice:u=", "N", "N", "N", "N", "N", "E:R:Alice:u=",
    "N", "N", "E:L:Alice:u=", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "N", "N", "M:Alice>Bob:a=--++:c=:m=:s=:u=", "M:Alice>Bob:a=++--:c=:m=:s=:u=",
    "M:Alice>Bob:a=**:c=:m=:s=:u=", "M:Alice>Bob:a=!!:c=:m=:s=:u=", "N", "N", "N",
    "N", "N", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=hi:s=:u=",
    "N", "M:Alice>Bob:a=:c=:m=hi:s=:u=", "M:Bob>Alice:a=:c=:m=:s=:u=", "N", "M:Bob>Alice:a=:c=:m=:s=:u=",
    "N", "M:Bob>Alice:a=:c=:m=:s=:u=", "M:Bob>Alice:a=:c=:m=:s=:u=", "M:Bob>Alice:a=:c=:m=:s=:u=",
    "M:Bob>Alice:a=:c=:m=:s=:u=", "M:Bob>Alice:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "M:Alice>Bob:a=:c=:m=:s=:u=", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "E:L:Alice:u=",
    "E:L:oAlice:u=", "E:L:Alice:u=", "E:R:Alice:u=", "E:R:Aliceo:u=", "E:R:Alice:u=",
    "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=", "N", "N",
    "M:Alice>Bob:a=:c=:m=\"\":s=:u=", "M:Alice>Bob:a=:c=:m=\"x\":s=:u=", "M:Alice>Bob:a=:c=:m=hi:s=:u=",
    "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "N", "N", "M:Alice>Bob:a=:c=#red:m=:s=:u=", "M:Alice>Bob:a=++:c=#red:m=hi:s=:u=",
    "M:Alice>Bob:a=++:c=#red:m=:s=:u=", "N", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "M:Alice Smith>Bob:a=:c=:m=:s=:u=", "M:A>Bob:a=:c=:m=:s=:u=", "M:A>Bob:a=:c=:m=:s=:u=",
    "N", "N", "M:A>B:a=:c=:m=:s=:u=", "M:B>C:a=:c=:m=:s=:u=", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=",
    "M:Alice>B:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=:s=:u=", "E:L:Alice:u=", "N",
    "N", "N", "N", "M:Alice>Bob:a=:c=:m=:s=:u=", "M:Alice>Bob:a=:c=:m=hi:s=<<stereo>>:u=",
    "M:Alice>Bob:a=:c=:m=:s=<<stereo>>:u=", "N", "M:Alice>Bob:a=:c=#red:m=hi:s=<<stereo>>:u=",
    "M:Alice>Bob:a=:c=:m=hi:s=:u=https://example.com", "M:Alice>Bob:a=:c=:m=:s=:u=https://example.com",
    "M:Alice>Bob:a=:c=:m=hi:s=<<s>>:u=https://example.com", "N", "N", "M:Alice>Bob:a=:c=#red:m=hi:s=:u=https://example.com",
    "M:Alice>Bob:a=:c=:m=hi:s=<<s>> <<t>>:u=", "N", "M:Alice>Bob:a=:c=:m=:s=<<s>>:u=",
    "N", "E:L:Alice:u=https://example.com", "E:R:Alice:u=https://example.com", "E:L:Alice:u=https://example.com",
    "N", "N", "N", "M:Alice>Bob:a=:c=:m=hi:s=<<s>>:u=url", "M:Alice>Bob:a=:c=#red:m=hi:s=:u=url",
    "M:Alice>Bob:a=:c=:m=hi:s=<<s>> [[url]] <<t>>:u=", "M:Alice>Bob:a=:c=:m=hi:s=<<s>> #yellow <<t>>:u=",
  ]
  guard cases.length() == expected.length() else {
    fail("oracle corpus mismatch")
  }
  for index in 0..<cases.length() {
    let cursor = @parse.Cursor::new(cases[index])
    let signature = match complete_message_line_syntax(cursor) {
      Some(Message(message)) =>
        "M:\{message.from_code}>\{message.to_code}:a=\{activation_string(message)}:c=\{color_string(message)}:m=\{message.label.unwrap_or("")}:s=\{message.stereotype.unwrap_or("")}:u=\{message.url.unwrap_or("")}"
      Some(MessageExo(message)) =>
        if message.exo_type is FromLeft || message.exo_type is ToLeft {
          "E:L:\{message.participant_code}:u=\{message.url.unwrap_or("")}"
        } else {
          "E:R:\{message.participant_code}:u=\{message.url.unwrap_or("")}"
        }
      _ => "N"
    }
    if signature != expected[index] {
      @test.fail(
        "line \{index} [\{cases[index]}] got \{signature} want \{expected[index]}",
      )
    }
  }
}

///|
test "note across grammar matches the plantuml across factory oracle" {
  let cases = [
    "note across : text", "note across", "note across #yellow : text", "note <<s>> across : text",
    "note across <<s>> : text", "note <<s>> across <<t>> : text", "note across [[https://example.com]] : text",
    "note across #yellow [[https://example.com]] : text", "note accross : text",
    "note across <<s>> <<t>> : text", "note <<s>> <<t>> across : text", "note across #yellow-blue : text",
    "note across #yellow blue : text", "note across <<s>> #yellow : text", "note <<s>> across #yellow : text",
    "hnote across : text", "rnote across #red : text", "note across : ", "note across <<s>>",
    "&note across : text", "note across #yellow.red : text", "note across #yellow\\red : text",
    "note across #yellow- : text", "note across <<s>> #yellow <<t>> : text", "NOTE across : text",
    "note ACCROSS : text",
  ]
  let expected = [
    "A:style=note:misspelled=false:stereo=:color=:url=:text=text", "A:style=note:misspelled=false:stereo=:color=:url=:text=<multiline>",
    "A:style=note:misspelled=false:stereo=:color=yellow:url=:text=text", "A:style=note:misspelled=false:stereo=<<s>>:color=:url=:text=text",
    "A:style=note:misspelled=false:stereo=<<s>>:color=:url=:text=text", "A:style=note:misspelled=false:stereo=<<s>>:color=:url=:text=text",
    "A:style=note:misspelled=false:stereo=:color=:url=https://example.com:text=text",
    "A:style=note:misspelled=false:stereo=:color=yellow:url=https://example.com:text=text",
    "A:style=note:misspelled=true:stereo=:color=:url=:text=text", "A:style=note:misspelled=false:stereo=<<s>> <<t>>:color=:url=:text=text",
    "A:style=note:misspelled=false:stereo=<<s>> <<t>>:color=:url=:text=text", "A:style=note:misspelled=false:stereo=:color=yellow-blue:url=:text=text",
    "N", "A:style=note:misspelled=false:stereo=<<s>>:color=yellow:url=:text=text",
    "A:style=note:misspelled=false:stereo=<<s>>:color=yellow:url=:text=text", "A:style=hnote:misspelled=false:stereo=:color=:url=:text=text",
    "A:style=rnote:misspelled=false:stereo=:color=red:url=:text=text", "A:style=note:misspelled=false:stereo=:color=:url=:text=",
    "A:style=note:misspelled=false:stereo=<<s>>:color=:url=:text=<multiline>", "N",
    "N", "A:style=note:misspelled=false:stereo=:color=yellow\\red:url=:text=text",
    "N", "A:style=note:misspelled=false:stereo=<<s>> #yellow <<t>>:color=:url=:text=text",
    "A:style=note:misspelled=false:stereo=:color=:url=:text=text", "A:style=note:misspelled=true:stereo=:color=:url=:text=text",
  ]
  guard cases.length() == expected.length() else {
    fail("across oracle corpus mismatch")
  }
  for index, line in cases {
    let signature = note_line_syntax(@parse.Cursor::new(line)).map_or(
      "N", note_across_signature,
    )
    if signature != expected[index] {
      @test.fail(
        "line \{index} [\{line}] got \{signature} want \{expected[index]}",
      )
    }
  }
}

///|
fn note_across_signature(syntax : NoteLineSyntax) -> String {
  let style = match syntax.note_style {
    NodeNormal => "note"
    Hexagonal => "hnote"
    Box => "rnote"
  }
  let text = match syntax.text {
    Inline(text) => "text=" + text
    Multiline => "text=<multiline>"
  }
  "A:style=\{style}:misspelled=\{syntax.misspelled_across}:stereo=\{syntax.stereotype.unwrap_or("")}:color=\{syntax.color.unwrap_or("")}:url=\{syntax.url.unwrap_or("")}:\{text}"
}

///|
test "participant and on-arrow note tails match the plantuml note factory oracle" {
  let cases = [
    "note left of Alice <<s>> : text", "note left of Alice <<s>> #yellow : text",
    "note left of Alice #yellow-red : text", "note left of Alice #yellow.red : text",
    "note left of Alice #yellow- : text", "note left of Alice [[url]] : text", "note top <<s>> : text",
    "note top #yellow : text", "note top [[url]] : text", "note over Alice, Bob <<s>> [[url]] : text",
    "note over Alice, Bob #yellow [[url]] : text", "note <<s>> left of Alice <<t>> : text",
    "note left of Alice <<s>> <<t>> : text", "note right : attached", "note over Alice <<s>> : text",
    "note left of Alice", "note left of Alice #yellow", "&note left : text", "&note right : attached",
    "&note left of Alice : text", "&note over Alice : text",
  ]
  let expected = [
    "A:pos=left:style=note:stereo=<<s>>:color=:url=:text=text", "A:pos=left:style=note:stereo=<<s>>:color=yellow:url=:text=text",
    "A:pos=left:style=note:stereo=:color=yellow-red:url=:text=text", "N", "N", "A:pos=left:style=note:stereo=:color=:url=url:text=text",
    "A:pos=top:style=note:stereo=<<s>>:color=:url=:text=text", "A:pos=top:style=note:stereo=:color=yellow:url=:text=text",
    "A:pos=top:style=note:stereo=:color=:url=url:text=text", "A:pos=overseveral:style=note:stereo=<<s>>:color=:url=url:text=text",
    "A:pos=overseveral:style=note:stereo=:color=yellow:url=url:text=text", "A:pos=left:style=note:stereo=<<s>>:color=:url=:text=text",
    "A:pos=left:style=note:stereo=<<s>> <<t>>:color=:url=:text=text", "A:pos=right:style=note:stereo=:color=:url=:text=attached",
    "A:pos=over:style=note:stereo=<<s>>:color=:url=:text=text", "A:pos=left:style=note:stereo=:color=:url=:text=<multiline>",
    "A:pos=left:style=note:stereo=:color=yellow:url=:text=<multiline>", "N", "N",
    "A:pos=left:style=note:stereo=:color=:url=:text=text", "A:pos=over:style=note:stereo=:color=:url=:text=text",
  ]
  guard cases.length() == expected.length() else {
    fail("note tail oracle corpus mismatch")
  }
  for index, line in cases {
    let signature = match note_line_syntax(@parse.Cursor::new(line)) {
      Some(syntax) => note_tail_signature(syntax)
      None => "N"
    }
    if signature != expected[index] {
      @test.fail(
        "line \{index} [\{line}] got \{signature} want \{expected[index]}",
      )
    }
  }
}

///|
fn note_tail_signature(syntax : NoteLineSyntax) -> String {
  let position = match syntax.position {
    Left => "left"
    Right => "right"
    Top => "top"
    Bottom => "bottom"
    Over => "over"
    OverSeveral => "overseveral"
    Across => "across"
  }
  let style = match syntax.note_style {
    NodeNormal => "note"
    Hexagonal => "hnote"
    Box => "rnote"
  }
  let text = match syntax.text {
    Inline(text) => "text=" + text
    Multiline => "text=<multiline>"
  }
  "A:pos=\{position}:style=\{style}:stereo=\{syntax.stereotype.unwrap_or("")}:color=\{syntax.color.unwrap_or("")}:url=\{syntax.url.unwrap_or("")}:\{text}"
}

///|
fn activation_string(message : Message) -> String {
  match (message.activation_spec, message.activation_spec2) {
    (Some(Activate), Some(Deactivate)) => "++--"
    (Some(Deactivate), Some(Activate)) => "--++"
    (Some(Activate), _) => "++"
    (Some(Deactivate), _) => "--"
    (Some(Destroy), _) => "!!"
    (Some(Create), _) => "**"
    (None, _) => ""
  }
}

///|
fn color_string(message : Message) -> String {
  message.life_color.map_or("", color => "#" + color)
}
