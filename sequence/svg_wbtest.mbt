///|
test "render SVG escapes labels and emits participant lifelines" {
  let svg = render_sequence_svg(
    "@startuml\nparticipant \"Web & Client\" as client\nclient -> Server : a < b & c\n@enduml",
  )
  @test.assert_eq(
    svg.has_prefix("<svg xmlns=\"http://www.w3.org/2000/svg\""),
    true,
  )
  @test.assert_eq(svg.contains("Web &amp; Client"), true)
  @test.assert_eq(svg.contains("a &lt; b &amp; c"), true)
  @test.assert_eq(svg.contains("class=\"lifeline\""), true)
  @test.assert_eq(svg.contains("marker-end=\"url(#arrow)\""), true)
  @test.assert_eq(svg.contains("<rect x=\"0\" y=\"0\""), true)
  @test.assert_eq(svg.has_suffix("</svg>\n"), true)
}

///|
test "references render a ref tab and centered body label" {
  let svg = render_sequence_svg(
    "@startuml\nAlice -> Bob : request\nref over Alice, Bob : external API call\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"reference-tab\""), true)
  @test.assert_eq(svg.contains(">ref</tspan>"), true)
  @test.assert_eq(svg.contains(">external API call</tspan>"), true)
}

///|
test "actors have a separate icon and label without a participant rectangle" {
  let svg = render_sequence_svg(
    "@startuml\nactor \"Bob Jones\" as bob\n@enduml",
  )
  @test.assert_eq(svg.contains("data-code=\"bob\">\n<circle"), true)
  @test.assert_eq(svg.contains("data-code=\"bob\">\n<rect"), false)
}

///|
test "specialized participants use their PlantUML shapes" {
  let svg = render_sequence_svg(
    "@startuml\nboundary B\ncontrol C\nentity E\ndatabase D\nqueue Q\ncollections S\n@enduml",
  )
  @test.assert_eq(svg.contains("data-code=\"B\">\n<circle"), true)
  @test.assert_eq(svg.contains("data-code=\"B\">\n<rect"), false)
  @test.assert_eq(svg.contains("data-code=\"C\">\n<circle"), true)
  @test.assert_eq(svg.contains("data-code=\"C\">\n<rect"), false)
  @test.assert_eq(svg.contains("data-code=\"E\">\n<ellipse"), true)
  @test.assert_eq(svg.contains("data-code=\"E\">\n<rect"), false)
  @test.assert_eq(svg.contains("data-code=\"D\">\n<ellipse"), true)
  @test.assert_eq(svg.contains("data-code=\"D\">\n<rect"), false)
  @test.assert_eq(svg.contains("data-code=\"Q\">\n<path"), true)
  @test.assert_eq(svg.contains("data-code=\"S\">\n<rect"), true)
}

///|
test "participant layout follows explicit PlantUML order" {
  let diagram = parse(
    "@startuml\nparticipant Last order 20\nparticipant First order -10\nparticipant Middle\nFirst -> Middle\n@enduml",
  )
  let result = diagram.layout()
  @test.assert_eq(result.participants[0].participant.code, "First")
  @test.assert_eq(result.participants[1].participant.code, "Middle")
  @test.assert_eq(result.participants[2].participant.code, "Last")
}

///|
test "render groups notes and activation as distinct layers" {
  let diagram = parse(
    "@startuml\nAlice -> Bob ++ : start\nnote right of Bob #yellow : cached\nalt #palegreen accepted\nBob --> Alice -- : reply\nelse rejected\nBob -> Alice : error\nend\ndestroy Bob\n@enduml",
  )
  let result = diagram.layout()
  let svg = diagram.render_svg()
  @test.assert_eq(result.groups.length(), 1)
  @test.assert_eq(result.groups[0].end_y > result.groups[0].start_y, true)
  @test.assert_eq(result.activations.length() >= 1, true)
  @test.assert_eq(
    result.activations[0].end_y > result.activations[0].start_y,
    true,
  )
  @test.assert_eq(result.destroys.length(), 1)
  @test.assert_eq(svg.contains("class=\"group-body\""), true)
  @test.assert_eq(svg.contains("class=\"activation\""), true)
  @test.assert_eq(svg.contains("class=\"note\""), true)
  @test.assert_eq(svg.contains("class=\"group-separator\""), true)
  @test.assert_eq(svg.contains("class=\"destroy\""), true)
}

///|
test "render preserves official hexagonal and box note styles" {
  let svg = render_sequence_svg(
    "@startuml\nhnote over Alice : hex\nrnote over Bob : box\n@enduml",
  )
  @test.assert_eq(svg.contains("class=\"note hex-note\""), true)
  @test.assert_eq(svg.contains("class=\"note box-note\""), true)
}

///|
test "render supports auto numbering and hiding unlinked participants" {
  let svg = render_sequence_svg(
    "@startuml\nparticipant Hidden\nparticipant Alice\nparticipant Bob\nautonumber 7 2 \"(0)\"\nAlice -> Bob : request\nBob -> Alice : response\nhide unlinked\n@enduml",
  )
  @test.assert_eq(svg.contains("(7) request"), true)
  @test.assert_eq(svg.contains("(9) response"), true)
  @test.assert_eq(svg.contains("data-code=\"Hidden\""), false)
}

///|
test "render preserves dotted auto numbers" {
  let svg = render_sequence_svg(
    "@startuml\nautonumber 1.2 3 \"(0)\"\nAlice -> Bob : first\nBob -> Alice : second\n@enduml",
  )
  @test.assert_eq(svg.contains("(1.2) first"), true)
  @test.assert_eq(svg.contains("(1.5) second"), true)
}

///|
test "render accepts PlantUML hash autonumber placeholders and numbers returns" {
  let svg = render_sequence_svg(
    "@startuml\nautonumber 100 5 \"(msg #)\"\nClient -> Server : request\nautonumber stop\nServer --> Client : response\nautonumber resume\nreturn result\n@enduml",
  )
  @test.assert_eq(svg.contains("(msg 100) request"), true)
  @test.assert_eq(svg.contains("(msg 105) result"), true)
}

///|
test "ignore newpage suppresses later page breaks" {
  let diagram = parse(
    "@startuml\nAlice -> Bob : request\nignore newpage\nnewpage summary\nBob -> Alice : response\n@enduml",
  )
  let layout = diagram.layout()
  match diagram.events[1] {
    IgnoreNewpage => ()
    _ => fail("ignore newpage was not parsed as a directive")
  }
  let mut newpage_index = None
  for index, event in diagram.events {
    match event {
      Newpage(_) => newpage_index = Some(index)
      _ => ()
    }
  }
  match newpage_index {
    Some(index) => @test.assert_eq(layout.placements[index].ignored, true)
    None => fail("newpage was not parsed as a page-break event")
  }
  @test.assert_eq(diagram.render_svg().contains("class=\"page-break\""), false)
}

///|
test "render the advanced sequence example semantics" {
  let source : String =
    #|@startuml
    #|
    #|box Frontend #lightyellow
    #|participant Client
    #|end box
    #|box Backend #lightblue
    #|participant Server
    #|participant Database
    #|end box
    #|
    #|Client -> Server : request
    #|Server -> Database -- : query
    #|
    #|== Transaction Log ==
    #|
    #|... processing ...
    #|
    #|hide footbox
    #|autonumber 100 5 "(msg #)"
    #|Server --> Client : response
    #|Client -> Server : next
    #|autonumber stop
    #|Server --> Client : unnumbered
    #|autonumber resume
    #|Server --> Client : renumbered
    #|
    #|ref over Client, Server : external API call
    #|
    #|return result value
    #|
    #|[-> Client : from outside
    #|Client ->] : to outside
    #|
    #|& Client -> Server : multicast message
    #|Server -> Database & Client : multicast to multiple
    #|
    #|hide unlinked
    #|participant Orphan
    #|
    #|url of Client is [[https://example.com/users]]
    #|url of Server is [[https://example.com/api]]
    #|
    #|{start} Client -> Server : anchored arrow
    #|{start} <-> {end} : linked anchors
    #|
    #|ignore newpage
    #|autonewpage 50
    #|newpage summary page
    #|
    #|@enduml
    #|
  let svg = render_sequence_svg(source)
  @test.assert_eq(svg.contains(">Frontend</tspan>"), true)
  @test.assert_eq(svg.contains(">Backend</tspan>"), true)
  @test.assert_eq(svg.contains("data-code=\"Orphan\""), false)
  @test.assert_eq(svg.contains("(msg 100) response"), true)
  @test.assert_eq(svg.contains("(msg 110) renumbered"), true)
  @test.assert_eq(svg.contains("(msg 115) result value"), true)
  @test.assert_eq(svg.contains("class=\"page-break\""), false)
  @test.assert_eq(svg.contains("id=\"start\" class=\"message-anchor\""), true)
}

///|
test "participant boxes retain parser scope and render as englobers" {
  let diagram = parse(
    "@startuml\nbox Infrastructure #lightblue\nparticipant Gateway\nparticipant Store\nend box\nparticipant Client\nGateway -> Store\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(diagram.participants["Gateway"].boxes.length(), 1)
  @test.assert_eq(
    diagram.participants["Store"].boxes[0].label,
    Some("Infrastructure"),
  )
  @test.assert_eq(diagram.participants["Client"].boxes.length(), 0)
  @test.assert_eq(svg.contains("class=\"participant-box-group\""), true)
  @test.assert_eq(svg.contains(">Infrastructure</tspan>"), true)
}

///|
test "delays split lifelines into visible event ranges" {
  let diagram = parse(
    "@startuml\nAlice -> Bob\n... waiting ...\nBob -> Alice\n@enduml",
  )
  let result = diagram.layout()
  let ranges = delay_ranges(result, diagram.events)
  @test.assert_eq(ranges.length(), 1)
  @test.assert_eq(ranges[0].0 < ranges[0].1, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"delay\""), true)
}

///|
test "text metrics distinguish narrow and wide default sans glyphs" {
  let metrics = @metrics.FontMetrics::default()
  @test.assert_eq(
    TextSize::of_with("WWW", metrics).width >
    TextSize::of_with("iii", metrics).width,
    true,
  )
  @test.assert_eq(TextSize::of_with(" ", metrics).width, 4)
  @test.assert_eq(TextSize::of_with("A", metrics).width, 9)
}
