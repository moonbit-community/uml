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
  @test.assert_eq(svg.has_suffix("</svg>\n"), true)
}

///|
test "participant layout reserves message label width" {
  let diagram = parse(
    "@startuml\nAlice -> Bob : this is a deliberately wide message label\n@enduml",
  )
  let result = diagram.layout()
  let distance = result.participants[1].center_x -
    result.participants[0].center_x
  @test.assert_eq(
    distance >=
    TextSize::of("this is a deliberately wide message label").width + 48,
    true,
  )
}

///|
test "labelled messages reserve space before their arrow" {
  let layout = parse(
    "@startuml\nAlice -> Bob\nAlice -> Bob : label only\nBob --> Carol : dotted arrow\n@enduml",
  ).layout()
  let first_arrow = layout.placements[0].y + 18
  let label_arrow = layout.placements[1].y + 18
  let dotted_arrow = layout.placements[2].y + 18
  @test.assert_eq(label_arrow - first_arrow >= 29, true)
  @test.assert_eq(dotted_arrow - label_arrow >= 29, true)
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
test "participant heads share a lifeline contact instead of a fixed top offset" {
  let layout = parse("@startuml\nactor Actor\nparticipant Service\n@enduml").layout()
  @test.assert_eq(layout.participant_head_y(layout.participants[0]), 5)
  @test.assert_eq(layout.participant_head_y(layout.participants[1]), 45)
  @test.assert_eq(layout.body_top, 81)
  @test.assert_eq(layout.participant_tail_y(), layout.body_bottom + 9)
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
test "note on arrow is centered over the preceding message" {
  let diagram = parse(
    "@startuml\nAlice -> Bob\nBob -> Carol\nnote right : attached\n@enduml",
  )
  let result = diagram.layout()
  match diagram.events[1] {
    Message(message) =>
      match diagram.events[2] {
        Note(note) => {
          let expected = (
              result
              .participant_at(message.from_code)
              .unwrap_or(result.participants[0]).center_x +
              result
              .participant_at(message.to_code)
              .unwrap_or(result.participants[0]).center_x
            ) /
            2
          @test.assert_eq(
            result.note_anchor_center(note, Some(message)),
            expected,
          )
        }
        _ => fail("expected note")
      }
    _ => fail("expected message")
  }
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
  @test.assert_eq(TextSize::of("WWW").width > TextSize::of("iii").width, true)
  @test.assert_eq(TextSize::of(" ").width, 4)
  @test.assert_eq(TextSize::of("A").width, 8)
}

///|
test "left notes use the current lifecycle segment and folded component" {
  let diagram = parse(
    "@startuml\nAlice -> Bob ++\nnote left of Bob : cached\n@enduml",
  )
  let layout = diagram.layout()
  let note = match diagram.events[1] {
    Note(note) => note
    _ => fail("expected note")
  }
  let geometry = layout.note_geometry(note, layout.placements[1], None)
  let segment = layout.participant_segment("Bob", layout.placements[1].y)
  @test.assert_eq(geometry.x + geometry.component.width, segment.0)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"note-fold\""), true)
}

///|
test "notes reserve an arrow clearance and a trailing component gap" {
  let layout = parse(
    "@startuml\nAlice -> Bob\nnote left of Alice : first\nnote left of Alice : second\n@enduml",
  ).layout()
  let arrow_y = layout.placements[0].y + 18
  let first_note = layout.placements[1]
  let second_note = layout.placements[2]
  @test.assert_eq(first_note.y - arrow_y >= 25, true)
  @test.assert_eq(second_note.y - first_note.y >= 35, true)
}

///|
test "notes on arrows share the preceding message tile" {
  let layout = parse(
    "@startuml\nAlice -> Bob : request\nnote right : detail\nAlice -> Bob : follow up\n@enduml",
  ).layout()
  @test.assert_eq(layout.placements[1].height, 0)
  @test.assert_eq(layout.placements[1].y, layout.placements[0].y + 4)
  @test.assert_eq(layout.placements[2].y - layout.placements[0].y >= 29, true)
}

///|
test "create arrow delays the participant head and lifeline" {
  let diagram = parse(
    "@startuml\nBob -> Alice ** : create\nnote left of Alice : ready\n@enduml",
  )
  let layout = diagram.layout()
  let alice = layout.participant_at("Alice").unwrap()
  let created_at = layout.placements[0].y
  @test.assert_eq(alice.birth_y, Some(created_at))
  @test.assert_eq(layout.participant_head_y(alice) > 5, true)
  @test.assert_eq(
    layout.activations.any(span => span.participant_code == "Alice"),
    false,
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("data-code=\"Alice\""), true)
}

///|
test "return follows the most recent active caller" {
  let diagram = parse(
    "@startuml\nClient -> Service ++ : call\nreturn result\ndeactivate Service\n@enduml",
  )
  let result = diagram.layout()
  let return_y = result.placements[1].y + 18
  let span = result.activations[0]
  @test.assert_eq(span.caller_code, Some("Client"))
  @test.assert_eq(span.start_y <= return_y && return_y <= span.end_y, true)
  @test.assert_eq(diagram.render_svg().contains("result"), true)
}

///|
test "partial arrows retain their edge side" {
  let below = render_sequence_svg("@startuml\nAlice \\-> Bob\n@enduml")
  let above = render_sequence_svg("@startuml\nAlice /-> Bob\n@enduml")
  @test.assert_eq(below.contains("y1=\"53\""), true)
  @test.assert_eq(below.contains("y2=\"53\""), true)
  @test.assert_eq(above.contains("y1=\"53\""), true)
  @test.assert_eq(above.contains("y2=\"53\""), true)
}
