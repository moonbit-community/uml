///|
test "colored notes and activations keep their fill in the svg" {
  let src =
    #|@startuml
    #|Alice -> Bob
    #|activate Bob #lightgreen
    #|hnote over Alice #lightgreen : colored hex
    #|rnote over Carol #lightcoral : colored box
    #|Bob --> Alice
    #|@enduml
  let svg = @render.render_sequence_svg(@parser.parse_sequence(src))
  @test.assert_eq(svg.contains("fill=\"#90EE90\""), true)
  @test.assert_eq(svg.contains("fill=\"#F08080\""), true)
}
