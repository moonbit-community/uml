///|
test "strikethrough spans preserve surrounding text" {
  let spans = parse_mindmap_text_line("a <s>b</s> c")
  @test.assert_eq(spans.length(), 3)
  @test.assert_eq(spans[0].text, "a ")
  @test.assert_eq(spans[1].text, "b")
  @test.assert_eq(spans[1].strike, true)
  @test.assert_eq(spans[2].text, " c")
}
