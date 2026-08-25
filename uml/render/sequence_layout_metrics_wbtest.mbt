///|
test "show unlinked reverses hide unlinked" {
  let diagram = @parser.parse_sequence(
    "@startuml\nhide unlinked\nshow unlinked\nparticipant Orphan\n@enduml",
  )
  @test.assert_eq(diagram.hides_unlinked(), false)
}

///|
test "hide unlinked accepts the official @ prefix" {
  let diagram = @parser.parse_sequence("@startuml\nhide @unlinked\n@enduml")
  @test.assert_eq(diagram.hides_unlinked(), true)
}

///|
test "sequence layout receives document font roles" {
  let regular = @parser.parse_sequence(
    "@startuml\nparticipant \"VeryLongParticipantName\" as A\nA -> Bob : message\n@enduml",
  )
  let styled = @parser.parse_sequence(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nparticipant \"VeryLongParticipantName\" as A\nA -> Bob : message\n@enduml",
  )
  let regular_layout = regular.layout()
  let styled_layout = styled.layout()
  @test.assert_eq(styled_layout.text_metrics.participant.profile, Monospace)
  @test.assert_eq(styled_layout.text_metrics.participant.font_size, 16)
  @test.assert_eq(styled_layout.text_metrics.participant.font_weight, 700)
  @test.assert_eq(styled_layout.text_metrics.body_italic.style, Italic)
  @test.assert_eq(
    styled_layout.participants[0].width > regular_layout.participants[0].width,
    true,
  )
}
