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
