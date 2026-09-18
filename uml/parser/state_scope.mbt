///|
fn Parser::existing_state_display(self : Parser, code : String) -> String? {
  self.states
  .search_by(state => state.code == code)
  .map(index => self.states[index].display)
}

///|
/// Reopening a group reuses its initial scope. It does not introduce a new
/// concurrent region; only a separator creates a later region.
fn Parser::initial_state_region(self : Parser, code : String) -> Int {
  self.regions
  .search_by(region => region.parent == code && region.separator is None)
  .map_or_else(() => self.open_region(code, None), index => {
    self.regions[index].index
  })
}

///|
fn Parser::open_state_scope(self : Parser, code : String) -> Unit {
  self.mark_state_group(code)
  let region_index = self.initial_state_region(code)
  self.stack.push({ code, region_index, })
}

///|
/// The first separator reached from the enclosing STATE sets that group's
/// orientation. Later separators are reached from CONCURRENT_STATE groups
/// and do not rotate the parent (StateDiagram.concurrentState). Reopening
/// the STATE and introducing another separator can set a new orientation.
/// Previously verified: reopened groups reuse their initial region; mixed
/// separators and later reopening retain the enclosing state orientation.
fn Parser::open_concurrent_region(
  self : Parser,
  parent : String,
  separator : @flow.StateRegionSeparator,
) -> Int {
  let orientation = self.regions
    .get(self.region_index())
    .bind(region => region.separator)
    .unwrap_or(separator)
  for index, region in self.regions {
    if region.parent == parent && region.separator is Some(_) {
      self.regions[index] = { ..region, separator: Some(orientation), }
    }
  }
  self.open_region(parent, Some(orientation))
}

///|
/// StateDiagram.concurrentState creates CONCURRENT_STATE groups after a
/// separator. The initial contents retain the containing STATE group.
fn Parser::concurrent_region_at(self : Parser, index : Int) -> Int? {
  guard self.regions.get(index) is Some(region) && region.separator is Some(_) else {
    return None
  }
  Some(region.index)
}

///|
/// StateDiagram.checkConcurrentStateOk checks the direct containers when
/// reusing a state in a declaration or transition.
fn Parser::check_state_reference(
  self : Parser,
  code : String,
) -> Unit raise @tokenizer.ParseError {
  guard self.states.search_by(state => state.code == code) is Some(index) else {
    return
  }
  let existing = self.states[index]
  guard self.concurrent_region_at(existing.region_index) ==
    self.concurrent_region_at(self.region_index()) else {
    raise SyntaxError(
      self.line_number(),
      "state belongs to another concurrent region",
    )
  }
}

///|
/// StateDiagram.getGroupParentIfItIsConcurrentState walks ancestors, so a
/// nested ordinary state still inherits the surrounding concurrent boundary.
fn Parser::state_concurrent_parent(self : Parser, code : String) -> Int? {
  let mut current = Some(code)
  while current is Some(code) {
    guard self.states.search_by(state => state.code == code) is Some(index) else {
      return None
    }
    let state = self.states[index]
    if self.concurrent_region_at(state.region_index) is Some(region) {
      return Some(region)
    }
    current = state.parent
  }
  None
}

///|
fn Parser::scope_concurrent_parent(self : Parser, scope : StateScope?) -> Int? {
  guard scope is Some(scope) else { return None }
  self
  .concurrent_region_at(scope.region_index)
  .map_or_else(() => self.state_concurrent_parent(scope.code), region => {
    Some(region)
  })
}

///|
/// Mirror StateDiagram.checkFinalError for state and entity-note links.
/// Rendering an illegal crossing by collapsing it to a container would lose
/// its endpoints and hide a source error instead of reproducing PlantUML.
/// Previously verified: declarations, transitions and notes cannot cross
/// concurrent region boundaries, including boundaries inherited from ancestors.
fn Parser::validate_state_links(
  self : Parser,
) -> Unit raise @tokenizer.ParseError {
  for transition in self.transitions {
    guard self.state_concurrent_parent(transition.source) ==
      self.state_concurrent_parent(transition.target) else {
      raise SyntaxError(
        self.line_number(),
        "transition crosses a concurrent state boundary",
      )
    }
  }
  for note in self.notes {
    let target_scope = match note.target {
      @flow.StateNote(code) => self.state_concurrent_parent(code)
      @flow.NoteNote(index) => {
        let target = self.notes[index]
        self.scope_concurrent_parent(
          target.parent.map(code => { code, region_index: target.region_index, }),
        )
      }
      @flow.TransitionNote(_) => continue
    }
    let scope = note.parent.map(code => {
      code,
      region_index: note.region_index,
    })
    guard self.scope_concurrent_parent(scope) == target_scope else {
      raise SyntaxError(
        self.line_number(),
        "note crosses a concurrent state boundary",
      )
    }
  }
}
