///|
test "member toggles are independent immutable and reset with source changes" {
  let initial = initial_state()
  let fields_open = toggle_member(initial, "A", "fields", false)
  let methods_closed = toggle_member(fields_open, "A", "methods", true)
  let other = toggle_member(methods_closed, "B", "all", false)
  @test.assert_eq(initial.member_states.is_empty(), true)
  @test.assert_eq(fields_open.member_states["A"].methods_expanded, true)
  @test.assert_eq(methods_closed.member_states["A"].fields_expanded, true)
  @test.assert_eq(methods_closed.member_states["A"].methods_expanded, false)
  @test.assert_eq(other.member_states["A"], methods_closed.member_states["A"])
  @test.assert_eq(
    other.member_states["B"].fields_expanded,
    other.member_states["B"].methods_expanded,
  )
  @test.assert_eq(app_state_tag(initial) == app_state_tag(fields_open), false)
  @test.assert_eq(select_source(other, "next").member_states.is_empty(), true)
  let (edited, _) = update(
    other,
    EditorChanged("new source"),
    @cmd.Emit(_ => @cmd.none),
  )
  @test.assert_eq(edited.member_states.is_empty(), true)
}
