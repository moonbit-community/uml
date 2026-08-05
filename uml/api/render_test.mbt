///|
test "color scheme maps the text and line roles to CSS variables" {
  let svg = render_svg(
    "@startuml\nparticipant Alice\nparticipant Bob\nAlice -> Bob : hello\n@enduml",
    color_scheme=@style.ColorScheme::ColorScheme(
      "var(--uml-text)", "var(--uml-line)",
    ),
  )
  @test.assert_eq(svg.contains("var(--uml-text)"), true)
  @test.assert_eq(svg.contains("var(--uml-line)"), true)
}

///|
test "color scheme overrides colorful roles with CSS variables" {
  let svg = render_svg(
    "@startuml\nparticipant Alice\nparticipant Bob\nAlice -> Bob : hello\nnote over Alice: hi\n@enduml",
    color_scheme=@style.ColorScheme::ColorScheme(
      "var(--uml-text)",
      "var(--uml-line)",
      note="var(--uml-note)",
    ),
  )
  @test.assert_eq(svg.contains("var(--uml-note)"), true)
}

///|
test "in-text skinparam colors take precedence over the color scheme" {
  let svg = render_svg(
    "@startuml\nskinparam ArrowColor #123456\nparticipant Alice\nparticipant Bob\nAlice -> Bob : hello\n@enduml",
    color_scheme=@style.ColorScheme::ColorScheme(
      "var(--uml-text)", "var(--uml-line)",
    ),
  )
  @test.assert_eq(svg.contains("#123456"), true)
  @test.assert_eq(svg.contains("var(--uml-line)"), false)
}

///|
test "default color scheme renders identically to no scheme" {
  let source = "@startuml\nparticipant Alice\nparticipant Bob\nAlice -> Bob : hello\n@enduml"
  let plain = render_svg(source)
  let explicit = render_svg(source, color_scheme=@style.ColorScheme::default())
  @test.assert_eq(plain, explicit)
}

///|
test "endpoint and reference fills follow the canvas color" {
  let svg = render_svg(
    "@startuml\nparticipant Alice\nparticipant Bob\nAlice o-> Bob : hello\nref over Alice, Bob : stage\n@enduml",
    color_scheme=@style.ColorScheme::ColorScheme(
      "var(--uml-text)",
      "var(--uml-line)",
      canvas="var(--uml-canvas)",
    ),
  )
  @test.assert_eq(svg.contains(".endpoint{fill:var(--uml-canvas)"), true)
  @test.assert_eq(svg.contains(".reference{fill:var(--uml-canvas)"), true)
}
