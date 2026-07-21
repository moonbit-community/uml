///|
test "class layout receives document font profile size and title weight" {
  let source = "@startuml\nclass VeryLongClassDisplayName\n@enduml"
  let regular = parse(source)
  let styled = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nclass VeryLongClassDisplayName\n@enduml",
  )
  let regular_metrics = ClassTextMetrics::new(regular.style)
  let styled_metrics = ClassTextMetrics::new(styled.style)
  @test.assert_eq(styled_metrics.regular.profile, Monospace)
  @test.assert_eq(styled_metrics.regular.font_size, 16)
  @test.assert_eq(styled_metrics.bold.font_weight, 700)
  @test.assert_eq(
    styled.entities[0].width(styled_metrics) >
    regular.entities[0].width(regular_metrics),
    true,
  )
  let layout = styled.layout(styled_metrics)
  @test.assert_eq(
    layout.width >=
    layout.node_x(0) + styled.entities[0].width(styled_metrics) + 24,
    true,
  )
}
