///|
test "common blocks preserve adjacent commands and presentation in both grammars" {
  let blocks = [
    ("title", "title"),
    ("caption", "caption"),
    ("header", "header"),
    ("footer", "footer"),
    ("legend left", "legend"),
  ]
  for separator in [" ", ""] {
    let source = StringBuilder()
    let expected = @style.DocumentStyle::empty()
    for (header, kind) in blocks {
      let body = kind + " text"
      source.write_string("\{header}\n\{body}\nend\{separator}\{kind}\n")
      expected.apply(@style.TextBlock(kind, body))
    }
    let family = "Courier New"
    source.write_string("skinparam {\nFontName \{family}\n}\n")
    expected.apply(@style.Property("FontName", family))
    let wbs = parse_wbs("* Before\n" + source.to_string() + "** After")
    let timing = parse_timing(
      "robust Before\n" + source.to_string() + "binary After",
    )
    @test.assert_eq(wbs.nodes.map(node => node.label), ["Before", "After"])
    @test.assert_eq(timing.players.map(player => player.code), [
      "Before", "After",
    ])
    @test.assert_eq(wbs.style, expected)
    @test.assert_eq(timing.style, expected)
  }
}

///|
test "unclosed common text blocks retain their opening source line" {
  let prefixes = [[], ["' preceding comment", ""]]
  for prefix in prefixes {
    let source = [..prefix, "title", "unfinished body"].join("\n")
    let opening_line = prefix.length() + 1
    let errors = [
      @test.expect_error(() => parse_timing(source)),
      @test.expect_error(() => parse_wbs(source)),
    ]
    for error in errors {
      let @tokenizer.SyntaxError(line, _) = error
      @test.assert_eq(line, opening_line)
    }
  }
}

///|
test "common block support remains diagram specific" {
  let timing = parse_timing(
    "mainframe\nframe text\nend mainframe\nbinary After",
  )
  @test.assert_eq(timing.players.map(player => player.code), ["After"])
  @test.assert_raise(() => {
    parse_wbs("mainframe\nframe text\nend mainframe\n* Root")
  })
  for source in ["skinparam {\nFontName Courier", "legend\nunfinished"] {
    @test.assert_raise(() => parse_timing(source))
    @test.assert_raise(() => parse_wbs(source))
  }
}

///|
test "skinparam consumption preserves following activity and state commands" {
  let property = "BackgroundColor"
  let value = "#123456"
  let block = "skinparam {\n\{property} \{value}\n}\n"
  let activity = parse_activity("start\n" + block + ":After;\nstop")
  let baseline = parse_activity("start\n:After;\nstop")
  @test.assert_eq(activity.nodes, baseline.nodes)
  let state = parse_state(
    "state Before\n" + block + "state After\nBefore --> After",
  )
  let baseline = parse_state("state Before\nstate After\nBefore --> After")
  @test.assert_eq(state.states, baseline.states)
  @test.assert_eq(state.transitions, baseline.transitions)
  @test.assert_eq(activity.style.canvas_color(), value)
  @test.assert_eq(state.style.canvas_color(), value)
}
