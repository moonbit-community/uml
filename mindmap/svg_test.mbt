///|
test "svg renders boxes, boxless labels, links, and escaped text" {
  let svg = render_mindmap_svg(
    "@startmindmap\n* Root & <topic>\n++[#abcdef] Right\n--_ Left\n@endmindmap",
  )
  @test.assert_eq(
    svg.has_prefix("<svg xmlns=\"http://www.w3.org/2000/svg\""),
    true,
  )
  @test.assert_eq(svg.contains("class=\"mindmap-link\""), true)
  @test.assert_eq(svg.contains("fill=\"#abcdef\""), true)
  @test.assert_eq(svg.contains("mindmap-node boxless"), true)
  @test.assert_eq(svg.contains("Root &amp; &lt;topic&gt;"), true)
  @test.assert_eq(svg.has_suffix("</svg>\n"), true)
}

///|
test "svg retains document background and emits each idea once" {
  let diagram = parse(
    "skinparam BackgroundColor #102030\n* Root\n** One\n*** Leaf\n** Two",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("background:#102030"), true)
  @test.assert_eq(svg.contains("data-idea-index=\"0\""), true)
  @test.assert_eq(svg.contains("data-idea-index=\"1\""), true)
  @test.assert_eq(svg.contains("data-idea-index=\"2\""), true)
  @test.assert_eq(svg.contains("data-idea-index=\"3\""), true)
}

///|
test "svg applies resolved node and arrow styles" {
  let svg = render_mindmap_svg(
    "<style>\nNode {\n  BackgroundColor #aabbcc\n  LineColor #102030\n  LineThickness 3\n  RoundCorner 9\n  FontSize 18\n}\n.Test {\n  HorizontalAlignment Right\n  FontColor #ff0000\n}\narrow {\n  LineColor #00aa00\n  LineThickness 4\n}\n</style>\n* Root\n** Child <<Test>>",
  )
  @test.assert_eq(svg.contains("fill=\"#aabbcc\""), true)
  @test.assert_eq(svg.contains("stroke=\"#102030\" stroke-width=\"3\""), true)
  @test.assert_eq(svg.contains("rx=\"9\""), true)
  @test.assert_eq(svg.contains("text-anchor=\"end\" fill=\"#ff0000\""), true)
  @test.assert_eq(svg.contains("stroke=\"#00aa00\" stroke-width=\"4\""), true)
}
