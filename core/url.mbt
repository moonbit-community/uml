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
fn url_target_prefix_parser() -> @talc.StringParser[UrlTarget] {
  let quoted_part = @talc.string("\\\"").or(
    @talc.none_of("\"").string_map(char => char.to_string()),
  )
  let quoted_target = @talc.char('"')
    .then(quoted_part.many().map(parts => parts.join("")))
    .skip(@talc.char('"'))
  let unquoted_target = @talc.many_chars1(
    @talc.satisfy("URL target", char => !char.is_whitespace() && char != ']'),
  )
  let target = quoted_target.attempt().or(unquoted_target)
  let terminator = @talc.string("]]")
  let label_char = terminator
    .not_followed_by("URL terminator")
    .then(@talc.char(']'))
    .or(@talc.none_of("]"))
  let label = @talc.many_chars(label_char).skip(terminator)
  let no_label = @talc.spaces().then(terminator).map(_ => None)
  let with_label = @talc.whitespace()
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
  @talc.string("[[")
  .then(@talc.spaces())
  .then(
    target.bind(target => {
      no_label.attempt().or(with_label).map(label => { target, label })
    }),
  )
}

///|
fn url_target_parser() -> @talc.StringParser[UrlTarget] {
  @talc.spaces()
  .then(url_target_prefix_parser())
  .skip(@talc.spaces())
  .skip(@talc.eof())
}

///|
/// Parse a URL target at the beginning of a larger PlantUML command.
pub fn parse_url_target_prefix(value : String) -> (UrlTarget, String)? {
  match url_target_prefix_parser().run(@talc.Input::new(value)) {
    Ok((target, rest)) => Some((target, rest.remaining().to_owned()))
    Err(_) => None
  }
}

///|
pub fn parse_url_target(value : String) -> UrlTarget? {
  match url_target_parser().parse(@talc.Input::new(value)) {
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
