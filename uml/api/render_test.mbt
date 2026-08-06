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
test "one theme exposes family-owned sequence and entity roles" {
  let scheme = @style.ColorScheme::ColorScheme(
    "theme-text",
    "theme-line",
    participant="theme-participant",
    lifeline="theme-lifeline",
    node="theme-node",
    visibility_private_stroke="theme-private-stroke",
  )
  let sequence = render_svg(
    "@startuml\nparticipant Alice\nAlice -> Bob : hello\n@enduml",
    color_scheme=scheme,
  )
  let entity = render_svg(
    "@startuml\nclass User {\n- secret\n}\n@enduml",
    color_scheme=scheme,
  )
  @test.assert_eq(sequence.contains("theme-participant"), true)
  @test.assert_eq(sequence.contains("theme-lifeline"), true)
  @test.assert_eq(entity.contains("theme-node"), true)
  @test.assert_eq(entity.contains("theme-private-stroke"), true)
}

///|
test "document skinparams take precedence over theme fallbacks" {
  let svg = render_svg(
    "@startuml\nskinparam ClassBackgroundColor document-node\nclass User\n@enduml",
    color_scheme=@style.ColorScheme::ColorScheme(
      "theme-text",
      "theme-line",
      node="theme-node",
    ),
  )
  @test.assert_eq(svg.contains("document-node"), true)
  @test.assert_eq(svg.contains("theme-node"), false)
}
