///|
/// StateDiagram's start/end/history methods resolve their reserved Quark
/// names. Exported legacy codes are preferences, not the entity identity.
/// Previously verified: reserved pseudo-state identities remain distinct;
/// synchronization aliases share identity and history keeps its target scope.
fn Parser::pseudo_state_location(
  self : Parser,
  raw : String,
  kind : @flow.StateKind,
) -> StateNameLocation raise @tokenizer.ParseError {
  let (reserved, preferred, suffix) = match kind {
    @flow.StateKind::Initial => ("*start*", "__initial__", "[*]")
    @flow.StateKind::Final => ("*end*", "__final__", "[*]")
    @flow.StateKind::History => ("*historical*", "__history__", "[H]")
    @flow.StateKind::DeepHistory =>
      ("*deephistory*", "__deep_history__", "[H*]")
    _ => abort("non-pseudo state passed to pseudo-state resolution")
  }
  let scope = if raw != suffix {
    let container = raw[0:raw.length() - suffix.length()].to_owned()
    let name = self.resolve_state_name(container, allow_current=false)
    self.ensure_state_container(name)
    let code = self.state_names[name].code.unwrap()
    Some(StateScope::{ code, region_index: self.initial_state_region(code), })
  } else {
    self.stack.last()
  }
  let namespace_index = self.state_namespace_for_scope(scope)
  let group_name = match self.state_names[namespace_index].part {
    Root => ""
    Identifier(name) => name
    Concurrent(index) => "CONC" + index.to_string()
  }
  let name = self.resolve_state_name_from(
    namespace_index,
    reserved + group_name,
    allow_current=false,
  )
  let preferred = scope.map_or(preferred, scope => {
    let code = preferred + scope.code
    self
    .concurrent_region_at(scope.region_index)
    .map_or(code, index => code + "__region_" + index.to_string())
  })
  let location = self.state_name_location(name, preferred, create_parents=false)
  { ..location, display: suffix, }
}
