///|
/// Entity.isRemoved inherits the containing group's removal. Eliminate removed
/// nodes before DOT, retaining the target identities of surviving annotations.
fn @flow.StateDiagram::visible_state_diagram(
  self : @flow.StateDiagram,
) -> @flow.StateDiagram {
  let visible = (code : String) => {
    !self
    .scope_path(code)
    .any(code => self.state(code).map_or(false, state => state.is_removed))
  }
  let states = self.states.filter(state => visible(state.code))
  let transitions = []
  let transition_indices : Map[Int32, Int32] = Map([])
  for index, transition in self.transitions {
    if visible(transition.source) && visible(transition.target) {
      transition_indices[index] = transitions.length()
      transitions.push(transition)
    }
  }
  let notes = []
  let note_indices : Map[Int32, Int32] = Map([])
  for index, note in self.notes {
    guard note.parent.map_or(true, visible) else { continue }
    let target = match note.target {
      @flow.StateNote(code) =>
        if visible(code) {
          Some(note.target)
        } else {
          None
        }
      @flow.TransitionNote(index) =>
        transition_indices.get(index).map(index => @flow.TransitionNote(index))
      @flow.NoteNote(index) =>
        note_indices.get(index).map(index => @flow.NoteNote(index))
    }
    if target is Some(target) {
      note_indices[index] = notes.length()
      notes.push({ ..note, target, })
    }
  }
  {
    ..self,
    states,
    transitions,
    notes,
    regions: self.regions.filter(region => visible(region.parent)),
    concurrent_regions: self.concurrent_regions.filter(visible),
  }
}

///|
fn @flow.StateDiagram::state_is_hidden(
  self : @flow.StateDiagram,
  code : String,
) -> Bool {
  self
  .scope_path(code)
  .any(code => self.state(code).map_or(false, state => state.is_hidden))
}

///|
fn @flow.StateDiagram::note_is_hidden(
  self : @flow.StateDiagram,
  index : Int32,
) -> Bool {
  let note = self.notes[index]
  if note.parent.map_or(false, code => self.state_is_hidden(code)) {
    return true
  }
  match note.target {
    @flow.StateNote(code) => self.state_is_hidden(code)
    @flow.NoteNote(index) => self.note_is_hidden(index)
    @flow.TransitionNote(index) => {
      let edge = self.transitions[index]
      self.state_is_hidden(edge.source) || self.state_is_hidden(edge.target)
    }
  }
}
