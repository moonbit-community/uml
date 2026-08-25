///|
/// A parsed PlantUML URL target with an optional display label.
pub struct UrlTarget {
  target : String
  label : String?
} derive(Eq, Debug)

///|
pub extend UrlTarget with Eq::{not_equal, equal}

///|
pub extend UrlTarget with Debug::{to_repr}

///|
/// A PlantUML URL embedded in a larger command.
pub struct UrlOccurrence {
  before : String
  target : UrlTarget
  after : String
} derive(Eq, Debug)

///|
pub extend UrlOccurrence with Eq::{not_equal, equal}

///|
pub extend UrlOccurrence with Debug::{to_repr}

///|
pub fn normalize_url_target(value : String) -> String {
  let value = value.trim()
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value.to_owned()
  }
}

///|
fn skip_url_spaces(cursor : Cursor) -> Unit {
  ignore(cursor.skip_while(Char::is_whitespace))
}

///|
fn skip_url_space1(cursor : Cursor) -> Bool {
  cursor.skip_while(Char::is_whitespace) > 0
}

///|
/// Consumes the `]]` terminator directly after optional whitespace.
fn take_url_terminator(cursor : Cursor) -> Bool {
  skip_url_spaces(cursor)
  cursor.consume_literal("]]")
}

///|
/// Consumes the label of a URL target up to its `]]` terminator.
fn take_url_label(cursor : Cursor) -> String? {
  let start = cursor.offset()
  while !cursor.is_eof() && !cursor.starts_with_literal("]]") {
    ignore(cursor.advance())
  }
  guard cursor.consume_literal("]]") else {
    ignore(cursor.restore(start))
    return None
  }
  Some(cursor.slice(start, cursor.offset() - 2))
}

///|
/// Parses a `[[target label]]` prefix, leaving the cursor after the
/// terminator. On failure the cursor is restored to its original position.
fn url_target_prefix(cursor : Cursor) -> UrlTarget? {
  let start = cursor.offset()
  guard cursor.consume_literal("[[") else { return None }
  skip_url_spaces(cursor)
  let target = match cursor.take_quoted_value() {
    Some(value) => value
    None => {
      let value = cursor.take_while(char => !char.is_whitespace() && char != ']')
      guard value.length() > 0 else {
        ignore(cursor.restore(start))
        return None
      }
      value
    }
  }
  let label_start = cursor.offset()
  let label : String? = if take_url_terminator(cursor) {
    None
  } else {
    ignore(cursor.restore(label_start))
    guard skip_url_space1(cursor) else {
      ignore(cursor.restore(start))
      return None
    }
    guard take_url_label(cursor) is Some(raw) else {
      ignore(cursor.restore(start))
      return None
    }
    let label = raw.trim().to_owned()
    if label.length() == 0 {
      None
    } else {
      Some(label)
    }
  }
  Some({ target, label, })
}

///|
fn url_target_parser(cursor : Cursor) -> UrlTarget? {
  let start = cursor.offset()
  skip_url_spaces(cursor)
  guard url_target_prefix(cursor) is Some(target) else {
    ignore(cursor.restore(start))
    return None
  }
  skip_url_spaces(cursor)
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(target)
}

///|
/// Parse a URL target at the beginning of a larger PlantUML command.
pub fn parse_url_target_prefix(value : String) -> (UrlTarget, String)? {
  let cursor = Cursor::new(value)
  url_target_prefix(cursor).map(target => (target, cursor.remaining()))
}

///|
pub fn parse_url_target(value : String) -> UrlTarget? {
  let cursor = Cursor::new(value)
  url_target_parser(cursor).filter(target => target.target.length() > 0)
}

///|
/// Extract the first `[[...]]` URL while preserving command text around it.
pub fn extract_url(value : String) -> UrlOccurrence? {
  guard find_unquoted_literal(value, "[[") is Some(start) else { return None }
  let tail = value[start + 2:].to_owned()
  guard find_literal(tail, "]]") is Some(length) else { return None }
  let end = start + 2 + length + 2
  guard parse_url_target(value[start:end].to_owned()) is Some(target) else {
    return None
  }
  Some({
    before: value[0:start].to_owned(),
    target,
    after: value[end:].to_owned(),
  })
}
