///|
test "merged notes share one layout row and max height" {
  let diagram = @parser.parse_sequence(
    "@startuml\nnote across #yellow : first\n/note across : second\n@enduml",
  )
  let layout = @render.layout_sequence(diagram)
  @test.assert_eq(layout.placements.length(), 1)
}
