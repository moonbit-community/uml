///|
test "render tasks keep their text measurers isolated across nested styles" {
  let regular = @heuristic.measurer()
  let wider = @metrics.Measurer::new((font, text) => {
    let measured = regular.measure(font, text)
    {
      ..measured,
      width: measured.width * 2,
      advance_width: measured.advance_width * 2.0,
      ink_left: measured.ink_left * 2.0,
      ink_right: measured.ink_right * 2.0,
    }
  })
  let regular_context = @style.RenderContext::new(regular, graphviz_context~)
  let wider_context = @style.RenderContext::new(wider, graphviz_context~)
  let states = @parser.parse_state(
    "@startuml\nstate Container {\nstate \"A sufficiently long state label\" as A\n}\n@enduml",
  )
  let plain = @render.layout_state(regular_context, states)
  let expanded = @render.layout_state(wider_context, states)
  @test.assert_eq(expanded.width > plain.width, true)
  @test.assert_eq(@render.layout_state(regular_context, states), plain)

  let activities = @parser.parse_activity(
    "@startuml\nif (a sufficiently long condition) then (yes)\n:A sufficiently long action label;\nelse (no)\n:Another sufficiently long action label;\nendif\n@enduml",
  )
  let plain = @render.layout_activity(regular_context, activities)
  let expanded = @render.layout_activity(wider_context, activities)
  @test.assert_eq(expanded.width > plain.width, true)
  @test.assert_eq(@render.layout_activity(regular_context, activities), plain)
}
