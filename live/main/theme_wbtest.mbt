///|
test "theme toggle flips between light and dark" {
  @test.assert_eq(initial_state().theme, Light)
  @test.assert_eq(toggle_theme(initial_state()).theme, Dark)
  @test.assert_eq(toggle_theme(toggle_theme(initial_state())).theme, Light)
}

///|
test "theme toggle preserves the rest of the app state" {
  let state = { ..initial_state(), active_file: "sequence/01.uml", source: "x" }
  let toggled = toggle_theme(state)
  @test.assert_eq(toggled.theme, Dark)
  @test.assert_eq(toggled.active_file, state.active_file)
  @test.assert_eq(toggled.source, state.source)
  @test.assert_eq(toggled.load_error, state.load_error)
}

///|
test "css variable scheme is what drives the preview" {
  let source = "@startuml\nparticipant Alice\nparticipant Bob\nAlice -> Bob : hello\n@enduml"
  let themed = @api.render_svg(source, color_scheme=theme_color_scheme()) catch {
    e => @test.fail("\{e}")
  }
  let plain = @api.render_svg(source) catch { e => @test.fail("\{e}") }
  @test.assert_eq(themed.contains("var(--uml-text)"), true)
  @test.assert_eq(themed.contains("var(--uml-line)"), true)
  @test.assert_eq(themed != plain, true)
}
