///|
/// Consume source lines until `is_terminator` matches. The terminator is
/// consumed but is not passed to `consume_line`.
///
/// Returns `false` when the source ends before a terminator is found.
pub fn consume_lines_until(
  next_line : () -> String?,
  is_terminator : (String) -> Bool,
  consume_line : (String) -> Unit,
) -> Bool {
  while true {
    guard next_line() is Some(line) else { return false }
    guard !is_terminator(line) else { return true }
    consume_line(line)
  }
  false
}

///|
/// Collect source lines until `is_terminator` matches. The terminator is
/// consumed and excluded from the returned lines.
pub fn collect_lines_until(
  next_line : () -> String?,
  is_terminator : (String) -> Bool,
) -> Array[String]? {
  let lines = []
  guard consume_lines_until(next_line, is_terminator, line => lines.push(line)) else {
    return None
  }
  Some(lines)
}
