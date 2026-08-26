///|
test "group and reference borders follow the text role" {
  let src =
    #|@startuml
    #|participant Alice
    #|participant Bob
    #|Alice -> Bob
    #|ref over Alice, Bob : lookup
    #|alt success
    #|Bob -> Alice
    #|end
    #|@enduml
  let default_svg = @render.render_sequence_svg(@parser.parse_sequence(src))
  @test.assert_eq(
    default_svg.contains(".group-body{stroke:#000000;stroke-width:1.5}"),
    true,
  )
  @test.assert_eq(
    default_svg.contains(
      ".reference{fill:none;stroke:#000000;stroke-width:1.5}",
    ),
    true,
  )
  let theme_svg = @render.render_sequence_svg(
    @parser.parse_sequence(src),
    color_scheme=@style.ColorScheme::ColorScheme("#e2e8f0", "#94a3b8"),
  )
  @test.assert_eq(
    theme_svg.contains(".group-body{stroke:#e2e8f0;stroke-width:1.5}"),
    true,
  )
  @test.assert_eq(
    theme_svg.contains(".reference{fill:none;stroke:#e2e8f0;stroke-width:1.5}"),
    true,
  )
}

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
