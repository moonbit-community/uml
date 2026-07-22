///|
/// A parsed PlantUML URL target with an optional display label.
pub struct UrlTarget {
  target : String
  label : String?
} derive(Eq, Debug)

///|
/// A PlantUML URL embedded in a larger command.
pub struct UrlOccurrence {
  before : String
  target : UrlTarget
  after : String
} derive(Eq, Debug)

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
fn url_target_prefix_parser() -> @talcparsec.StringParser[UrlTarget] {
  let quoted_part = @talcparsec.string("\\\"").or(
    @talcparsec.none_of("\"").string_map(char => char.to_string()),
  )
  let quoted_target = @talcparsec.char('"')
    .then(quoted_part.many().map(parts => parts.join("")))
    .skip(@talcparsec.char('"'))
  let unquoted_target = @talcparsec.many_chars1(
    @talcparsec.satisfy("URL target", char => {
      !char.is_whitespace() && char != ']'
    }),
  )
  let target = quoted_target.attempt().or(unquoted_target)
  let terminator = @talcparsec.string("]]")
  let label_char = terminator
    .not_followed_by("URL terminator")
    .then(@talcparsec.char(']'))
    .or(@talcparsec.none_of("]"))
  let label = @talcparsec.many_chars(label_char).skip(terminator)
  let no_label = @talcparsec.spaces().then(terminator).map(_ => None)
  let with_label = @talcparsec.whitespace()
    .some()
    .then(label)
    .map(label => {
      let label = label.trim().to_owned()
      if label.length() == 0 {
        None
      } else {
        Some(label)
      }
    })
  @talcparsec.string("[[")
  .then(@talcparsec.spaces())
  .then(
    target.bind(target => {
      no_label.attempt().or(with_label).map(label => { target, label })
    }),
  )
}

///|
fn url_target_parser() -> @talcparsec.StringParser[UrlTarget] {
  @talcparsec.spaces()
  .then(url_target_prefix_parser())
  .skip(@talcparsec.spaces())
  .skip(@talcparsec.eof())
}

///|
/// Parse a URL target at the beginning of a larger PlantUML command.
pub fn parse_url_target_prefix(value : String) -> (UrlTarget, String)? {
  match url_target_prefix_parser().run(@talcparsec.Input::new(value)) {
    Ok((target, rest)) => Some((target, rest.remaining().to_owned()))
    Err(_) => None
  }
}

///|
pub fn parse_url_target(value : String) -> UrlTarget? {
  match url_target_parser().parse(@talcparsec.Input::new(value)) {
    Ok(target) if target.target.length() > 0 => Some(target)
    _ => None
  }
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
