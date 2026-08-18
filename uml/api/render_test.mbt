///|
test "explicit default theme preserves SVG output" {
  let sources = [
    "@startuml\nparticipant Alice\nAlice -> Bob : hello\n@enduml", "@startuml\nclass User {\n- secret\n}\n@enduml",
  ]
  for source in sources {
    @test.assert_eq(
      render_svg(source),
      render_svg(source, color_scheme=@style.ColorScheme::default()),
    )
  }
}

///|
test "document rendering delegates through the parsed diagram boundary" {
  let source = "@startuml\nparticipant Alice\nAlice -> Bob : hello\n@enduml"
  let document = parse(source)
  @test.assert_eq(document.render_svg(), document.diagram.render_svg())
}
