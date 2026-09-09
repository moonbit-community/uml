///|
test "tree drawing carries measured advances and contiguous creole runs" {
  let metrics = @metrics.FontMetrics::from_defaults()
  let commands = []
  let origin = metrics.font_size
  let first = "before"
  let middle = "struck"
  let last = "after"
  draw_tree_text(
    @graphics.Graphic::new(command => commands.push(command)),
    origin,
    origin,
    first + "<s>" + middle + "</s>" + last,
    metrics.line_height,
    Start,
    "black",
    metrics.font_size,
    metrics,
    "label",
  )
  let text = StringBuilder()
  let mut cursor = origin.to_double()
  for command in commands {
    guard command is Draw(Text(run), _, _, _) else {
      @test.fail("expected text")
    }
    let advance = plantuml_measure(metrics, run.text).advance_width.to_double()
    @test.assert_eq(run.position.x, cursor)
    @test.assert_eq(run.position.y, origin.to_double())
    @test.assert_eq(run.advance, Some(advance))
    @test.assert_eq(run.strike, run.text == middle)
    cursor += advance
    text.write_string(run.text)
  }
  @test.assert_eq(text.to_string(), first + middle + last)
}
