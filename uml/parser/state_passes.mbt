///|
priv enum PendingStateCommand {
  Focus(String)
  Transition(StateTransitionSyntax)
  EntityNote(StateEntityNoteSyntax)
  LinkNote(StateLinkNoteSyntax)
}

///|
priv struct ScopedStateCommand {
  command : PendingStateCommand
  scope : StateScope?
  line_index : Int
}

///|
/// The scan builds declarations and captures each later command's scope.
/// Multiline note bodies are consumed once, before scanning resumes, so their
/// contents cannot be mistaken for declarations or group terminators.
fn Parser::queue_state_command(
  self : Parser,
  command : PendingStateCommand,
) -> Unit raise @tokenizer.ParseError {
  let scope = self.stack.last()
  let line_index = self.buffer.index
  let command = match command {
    Transition(_) | Focus(_) => command
    EntityNote(note) => {
      let (text, mode) = self.consume_note_body(note.body)
      EntityNote({ ..note, body: Resolved(text, mode), })
    }
    LinkNote(note) => {
      let (text, mode) = self.consume_note_body(
        note.body,
        allow_empty_block=false,
      )
      LinkNote({ ..note, body: Resolved(text, mode), })
    }
  }
  self.pending_commands.push({ command, scope, line_index, })
}

///|
/// Captured scopes point to the regions created by the declaration pass.
/// Resolution needs only the current scope; ancestry lives on StateNode.
fn Parser::enter_command_scope(
  self : Parser,
  command : ScopedStateCommand,
) -> Unit {
  self.stack.clear()
  if command.scope is Some(scope) {
    self.stack.push(scope)
  }
  self.buffer.index = command.line_index
}

///|
fn Parser::resolve_state_transition(
  self : Parser,
  syntax : StateTransitionSyntax,
) -> Unit raise @tokenizer.ParseError {
  let source = self.ensure_endpoint(syntax.source, TransitionSource)
  let target = self.ensure_endpoint(syntax.target, TransitionTarget)
  self.transitions.push({
    source,
    target,
    label: syntax.label,
    direction: syntax.direction,
    length: syntax.length,
    line_style: syntax.line_style,
    has_cross_start: syntax.has_cross_start,
    has_circle_end: syntax.has_circle_end,
  })
}

///|
/// StateDiagramFactory resolves declarations first, transitions and link
/// notes on pass two, and entity notes on pass three. In particular, a link
/// note binds to the last preceding transition, never to an entity-note edge.
/// The public notes array retains source order after those targets resolve.
/// Previously verified: declaration order, forward references, concurrent
/// scopes, note targets, single field application and original error locations.
fn Parser::resolve_state_commands(
  self : Parser,
) -> Unit raise @tokenizer.ParseError {
  let end_index = self.buffer.index
  let link_targets : Map[Int, Int] = Map([])
  for index, scoped in self.pending_commands {
    self.enter_command_scope(scoped)
    match scoped.command {
      Transition(syntax) => self.resolve_state_transition(syntax)
      LinkNote(_) => {
        guard !self.transitions.is_empty() else {
          raise SyntaxError(self.line_number(), "link note without transition")
        }
        link_targets[index] = self.transitions.length() - 1
      }
      EntityNote(_) | Focus(_) => ()
    }
  }
  for index, scoped in self.pending_commands {
    self.enter_command_scope(scoped)
    match scoped.command {
      EntityNote(note) => self.consume_entity_note(note)
      Focus(code) => self.last_entity = Some(@flow.StateNote(code))
      LinkNote(note) => {
        let (text, text_mode) = self.consume_note_body(note.body)
        self.notes.push({
          target: @flow.StateNoteTarget::TransitionNote(link_targets[index]),
          text,
          text_mode,
          parent: self.parent(),
          region_index: self.region_index(),
          color: note.color,
          position: note.position,
        })
      }
      Transition(_) => ()
    }
  }
  self.stack.clear()
  self.buffer.index = end_index
}
