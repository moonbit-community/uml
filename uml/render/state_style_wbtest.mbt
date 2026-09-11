///|
test "resolved state fonts keep role overrides and measured font in agreement" {
  let roles = [
    (StateFontRole::StateLabel, "State"),
    (StateFontRole::StateDescription, "StateAttribute"),
    (StateFontRole::DiamondLabel, "ActivityDiamond"),
    (StateFontRole::NoteLabel, "Note"),
  ]
  for (role, prefix) in roles {
    let style = @style.DocumentStyle::empty()
    let initial = resolve_state_font(style, role)
    let family = "Courier New"
    let size = initial.size + initial.size
    let color = "#123456"
    style.apply(@style.Property(prefix + "FontName", family))
    style.apply(@style.Property(prefix + "FontSize", size.to_string()))
    style.apply(@style.Property(prefix + "FontColor", color))
    let resolved = resolve_state_font(style, role)
    @test.assert_eq(resolved.family, family)
    @test.assert_eq(resolved.size, size)
    @test.assert_eq(resolved.color, color)
    @test.assert_eq(resolved.metrics.font_size, resolved.size)
    @test.assert_eq(
      resolved.metrics.profile,
      @style.font_profile_for(resolved.family),
    )
    for (other, other_prefix) in roles {
      if other_prefix != prefix {
        let untouched = resolve_state_font(@style.DocumentStyle::empty(), other)
        let actual = resolve_state_font(style, other)
        @test.assert_eq(actual.family, untouched.family)
        @test.assert_eq(actual.size, untouched.size)
        @test.assert_eq(actual.color, untouched.color)
      }
    }
  }
}

///|
test "state font fallbacks preserve the distinction between labels and notes" {
  let style = @style.DocumentStyle::empty()
  let original_label = resolve_state_font(style, StateLabel)
  let changed_size = original_label.size + original_label.size
  style.apply(@style.FontSize(changed_size.to_string()))
  style.apply(@style.FontFamily("Courier New"))
  let themed = style.with_color_scheme(@style.ColorScheme::dark())
  let label = resolve_state_font(themed, StateLabel)
  let note = resolve_state_font(themed, NoteLabel)
  @test.assert_eq(label.size, original_label.size)
  @test.assert_eq(note.size, changed_size)
  @test.assert_eq(label.family, themed.font_family())
  @test.assert_eq(note.family, label.family)
  @test.assert_eq(label.color, themed.diagram_text_color())
  @test.assert_eq(note.color, label.color)
}
