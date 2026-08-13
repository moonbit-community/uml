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
    "Alice -> Bob as \"B\"",
  ]
  let expected = [
    "M:Alice>Bob:a=:c=:m=", "N", "N", "M:Bob>Alice:a=:c=:m=", "M:Alice>Bob:a=:c=:m=",
    "N", "N", "N", "M:Alice>Bob:a=:c=:m=", "M:Alice>oBob:a=:c=:m=", "N", "M:Alice>Bob:a=:c=:m=",
    "M:Alice>xBob:a=:c=:m=", "N", "N", "M:Alice>Bob:a=:c=:m=", "N", "N", "N", "N",
    "N", "N", "M:Alice>Bob:a=:c=:m=", "N", "N", "M:Alice>Bob:a=:c=:m=", "M:Bob>Alice:a=:c=:m=",
    "N", "N", "N", "M:Bob>Alice:a=:c=:m=", "N", "N", "N", "N", "N", "E:R:Alice",
    "E:R:Alice", "E:R:Alice", "N", "N", "E:L:Alice", "E:L:Alice", "N", "N", "N",
    "N", "N", "N", "E:L:Alice", "E:L:Alice", "E:L:Alice", "E:L:Alice", "E:L:Alice",
    "E:L:Alice", "E:L:Alice", "E:L:Alice", "E:L:Alice", "N", "E:R:Alice", "E:R:Alice",
    "E:R:Alice", "E:R:Alice", "E:R:Alice", "N", "N", "N", "N", "N", "E:R:Alice",
    "N", "N", "E:L:Alice", "M:Alice>Bob:a=:c=:m=", "M:Alice>Bob:a=:c=:m=", "N", "N",
    "M:Alice>Bob:a=--++:c=:m=", "M:Alice>Bob:a=++--:c=:m=", "M:Alice>Bob:a=**:c=:m=",
    "M:Alice>Bob:a=!!:c=:m=", "N", "N", "N", "N", "N", "N", "N", "M:Alice>Bob:a=:c=:m=",
    "M:Alice>Bob:a=:c=:m=", "N", "M:Alice>Bob:a=:c=:m=", "M:Alice>Bob:a=:c=:m=",
    "M:Alice>Bob:a=:c=:m=hi", "N", "M:Alice>Bob:a=:c=:m=hi", "M:Bob>Alice:a=:c=:m=",
    "N", "M:Bob>Alice:a=:c=:m=", "N", "M:Bob>Alice:a=:c=:m=", "M:Bob>Alice:a=:c=:m=",
    "M:Bob>Alice:a=:c=:m=", "M:Bob>Alice:a=:c=:m=", "M:Bob>Alice:a=:c=:m=", "M:Alice>Bob:a=:c=:m=",
    "M:Alice>Bob:a=:c=:m=", "N", "N", "M:Alice>Bob:a=:c=:m=", "E:L:Alice", "E:L:oAlice",
    "E:L:Alice", "E:R:Alice", "E:R:Aliceo", "E:R:Alice", "N", "N", "M:Alice>Bob:a=:c=:m=",
    "M:Alice>Bob:a=:c=:m=", "N", "N", "M:Alice>Bob:a=:c=:m=\"\"", "M:Alice>Bob:a=:c=:m=\"x\"",
    "M:Alice>Bob:a=:c=:m=hi", "M:Alice>Bob:a=:c=:m=", "M:Alice>Bob:a=:c=:m=", "M:Alice>Bob:a=:c=:m=",
    "N", "N", "M:Alice>Bob:a=:c=#red:m=", "M:Alice>Bob:a=++:c=#red:m=hi", "M:Alice>Bob:a=++:c=#red:m=",
    "N", "N", "N", "M:Alice>Bob:a=:c=:m=", "M:Alice Smith>Bob:a=:c=:m=", "M:A>Bob:a=:c=:m=",
    "M:A>Bob:a=:c=:m=", "N", "N", "M:A>B:a=:c=:m=", "M:B>C:a=:c=:m=", "N", "N", "M:Alice>Bob:a=:c=:m=",
    "M:Alice>B:a=:c=:m=", "M:Alice>Bob:a=:c=:m=", "E:L:Alice", "N", "N", "N", "N",
    "M:Alice>Bob:a=:c=:m=",
  ]
  guard cases.length() == expected.length() else {
    fail("oracle corpus mismatch")
  }
  for index in 0..<cases.length() {
    let cursor = @parse.Cursor::new(cases[index])
    let signature = match complete_message_line_syntax(cursor) {
      Some(Message(message)) =>
        "M:\{message.from_code}>\{message.to_code}:a=\{activation_string(message)}:c=\{color_string(message)}:m=\{message.label.unwrap_or("")}"
      Some(MessageExo(message)) =>
        if message.exo_type is FromLeft || message.exo_type is ToLeft {
          "E:L:\{message.participant_code}"
        } else {
          "E:R:\{message.participant_code}"
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
  match message.life_color {
    Some(color) => "#" + color
    None => ""
  }
}
