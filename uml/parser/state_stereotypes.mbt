///|
/// Stereogroup uses its first label to select a pseudo-state type; later
/// labels remain available for styling but do not change the selected shape.
/// Previously verified: stereotype groups choose the first pseudo-state kind
/// without replacing existing state kinds or explicit groups.
fn state_stereotype_kind(group : String?) -> @flow.StateKind {
  guard group is Some(group) else { return @flow.StateKind::Normal }
  let cursor = @tokenizer.Cursor::new(group)
  guard cursor.take_stereotype_value() is Some(first) else {
    return @flow.StateKind::Normal
  }
  match first[2:first.length() - 2].trim().to_lower() {
    "choice" => @flow.StateKind::Choice
    "fork" | "join" => @flow.StateKind::Synchronization
    "start" => @flow.StateKind::Initial
    "end" => @flow.StateKind::Final
    "history" => @flow.StateKind::History
    "history*" => @flow.StateKind::DeepHistory
    _ => @flow.StateKind::Normal
  }
}
