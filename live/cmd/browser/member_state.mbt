///|
fn toggle_member(
  state : AppState,
  code : String,
  section : String,
  expanded : Bool,
) -> AppState {
  let current = state.member_states
    .get(code)
    .unwrap_or(@entity.MbtiRenderOptions::default().member_state())
  let next = match section {
    "fields" => { ..current, fields_expanded: !expanded, }
    "methods" => { ..current, methods_expanded: !expanded, }
    "all" => { fields_expanded: !expanded, methods_expanded: !expanded, }
    _ => return state
  }
  let member_states = state.member_states.copy()
  member_states[code] = next
  { ..state, member_states, member_revision: state.member_revision + 1, }
}

///|
fn activate_member(event : @dom.Event, emit : @rabbita.Emit[Msg]) -> @cmd.Cmd {
  guard event.target().to_element() is Some(element) else { return @cmd.none }
  guard element.closest("[data-member-node]") is Some(control) else {
    return @cmd.none
  }
  guard control.get_attribute("data-member-node") is Some(code) else {
    return @cmd.none
  }
  guard control.get_attribute("data-member-section") is Some(section) else {
    return @cmd.none
  }
  let expanded = control.get_attribute("aria-expanded") == Some("true")
  event.prevent_default()
  event.stop_propagation()
  emit(MemberToggled(code, section, expanded))
}

///|
fn focus_member(code : String, section : String) -> @cmd.Cmd {
  @cmd.custom_cmd(kind=@cmd.after_render, _ => {
    for
      control in @dom.document()
      .query_selector_all(".preview [data-member-node]")
      .iter() {
      if control.get_attribute("data-member-node") == Some(code) &&
        control.get_attribute("data-member-section") == Some(section) {
        if control.to_svg_element() is Some(svg) {
          svg.focus()
        }
        break
      }
    }
  })
}
