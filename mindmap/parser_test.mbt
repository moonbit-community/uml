///|
test "preserves mindmap hierarchy and sibling parentage" {
  let diagram = parse(
    "@startmindmap\n* Root\n** First\n*** Leaf\n** Second\n@endmindmap",
  )
  @test.assert_eq(diagram.ideas.length(), 4)
  @test.assert_eq(diagram.ideas[0].parent, None)
  @test.assert_eq(diagram.ideas[1].parent, Some(0))
  @test.assert_eq(diagram.ideas[2].parent, Some(1))
  @test.assert_eq(diagram.ideas[3].parent, Some(0))
}

///|
test "accepts PlantUML's explicit zero root syntax" {
  let diagram = parse("@startmindmap\n0 Central topic\n++ Branch\n@endmindmap")
  @test.assert_eq(diagram.ideas[0].label, "Central topic")
  @test.assert_eq(diagram.ideas[1].parent, Some(0))
}

///|
test "supports independent plus and minus branches" {
  let diagram = parse(
    "@startmindmap\n* Root\n++ Right child\n+++ Right leaf\n-- Left child\n---@red[not a color]\n@endmindmap",
  )
  @test.assert_eq(diagram.ideas[1].direction, Right)
  @test.assert_eq(diagram.ideas[2].parent, Some(1))
  @test.assert_eq(diagram.ideas[3].direction, Left)
  @test.assert_eq(diagram.ideas[3].parent, Some(0))
}

///|
test "parses item presentation without changing hierarchy" {
  let diagram = parse(
    "@startmindmap\n* Root\n**[#aabbcc]_ Boxless <<tag>>\n@endmindmap",
  )
  let idea = diagram.ideas[1]
  @test.assert_eq(idea.background_color, Some("#aabbcc"))
  @test.assert_eq(idea.shape, None)
  @test.assert_eq(idea.label, "Boxless")
  @test.assert_eq(idea.stereotype, Some("<<tag>>"))
  @test.assert_eq(idea.parent, Some(0))
}

///|
test "parses org-mode multiline labels as one item" {
  let diagram = parse(
    "@startmindmap\n* Root\n**: first line\nsecond line; <<note>>\n@endmindmap",
  )
  @test.assert_eq(diagram.ideas.length(), 2)
  @test.assert_eq(diagram.ideas[1].label, "first line\nsecond line")
  @test.assert_eq(diagram.ideas[1].stereotype, Some("<<note>>"))
}

///|
test "rejects hierarchy gaps and inconsistent indentation" {
  for source in ["* Root\n** Child\n**** Gap", "* Root\n*** Child\n**** Uneven"] {
    try parse(source) catch {
      SyntaxError(_, _) => ()
    } noraise {
      _ => @test.fail("expected mindmap indentation error")
    }
  }
}
