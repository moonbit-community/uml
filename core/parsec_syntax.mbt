///|
fn alias_identifier_parser() -> @talc.StringParser[(String, String)] {
  let separator = @talc.string(" as ")
  let quoted_part = @talc.string("\\\"").or(
    @talc.none_of("\"").string_map(char => char.to_string()),
  )
  let quoted_identifier = @talc.char('"')
    .then(quoted_part.many().map(parts => "\"" + parts.join("") + "\""))
    .skip(@talc.char('"'))
  let unquoted_character = separator
    .not_followed_by("alias separator")
    .then(@talc.satisfy("identifier character", _ => true))
    .string_map(char => char.to_string())
  let name = quoted_identifier
    .attempt()
    .or(unquoted_character)
    .many()
    .map(parts => parts.join(""))
  name
  .skip(separator)
  .bind(left => {
    @talc.many_chars(
      @talc.satisfy("identifier character", _ => true),
    ).map(right => (left, right))
  })
  .skip(@talc.eof())
}

///|
fn syntax_words_parser() -> @talc.StringParser[Array[String]] {
  let quoted_part = @talc.char('\\')
    .then(@talc.satisfy("escaped character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talc.none_of("\"").string_map(char => char.to_string()))
  let quoted = @talc.char('"').bind(_ => {
    quoted_part
    .many()
    .bind(parts => {
      @talc.char('"')
      .optional()
      .map(close => {
        let suffix = match close {
          Some(_) => "\""
          None => ""
        }
        "\"" + parts.join("") + suffix
      })
    })
  })
  let unquoted = @talc.satisfy("unquoted character", char => {
    !char.is_whitespace() && char != '"'
  }).string_map(char => char.to_string())
  let word = quoted.attempt().or(unquoted).some().map(parts => parts.join(""))
  @talc.spaces()
  .then(word.skip(@talc.spaces()).many())
  .skip(@talc.eof())
}

///|
priv enum UnquotedSplitToken {
  Text(String)
  Delimiter
}

///|
fn split_unquoted_parser(
  delimiter : Char,
) -> @talc.StringParser[Array[String]] {
  let quoted_part = @talc.char('\\')
    .then(@talc.satisfy("escaped character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talc.none_of("\"").string_map(char => char.to_string()))
  let quoted = @talc.char('"').bind(_ => {
    quoted_part
    .many()
    .bind(parts => {
      @talc.char('"')
      .optional()
      .map(close => {
        let suffix = match close {
          Some(_) => "\""
          None => ""
        }
        Text("\"" + parts.join("") + suffix)
      })
    })
  })
  let text = @talc.satisfy("unquoted character", char => {
      char != delimiter && char != '"'
    })
    .string_map(char => char.to_string())
    .map(value => Text(value))
  let token = @talc.char(delimiter)
    .map(_ => Delimiter)
    .or(quoted.attempt())
    .or(text)
  token
  .many()
  .skip(@talc.eof())
  .map(tokens => {
    let parts = []
    let mut current = StringBuilder()
    for token in tokens {
      match token {
        Delimiter => {
          parts.push(current.to_string())
          current = StringBuilder()
        }
        Text(value) => current.write_string(value)
      }
    }
    parts.push(current.to_string())
    parts
  })
}

///|
fn literal_prefix_parser(needle : String) -> @talc.StringParser[String] {
  let character = @talc.string(needle)
    .not_followed_by("literal")
    .then(@talc.satisfy("character", _ => true))
  @talc.many_chars(character).skip(@talc.string(needle))
}

///|
fn unquoted_literal_prefix_parser(
  needle : String,
) -> @talc.StringParser[String] {
  let quoted_part = @talc.char('\\')
    .then(@talc.satisfy("escaped character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talc.none_of("\"").string_map(char => char.to_string()))
  let quoted = @talc.char('"').bind(_ => {
    quoted_part
    .many()
    .bind(parts => {
      @talc.char('"')
      .optional()
      .map(close => {
        let suffix = if close is Some(_) { "\"" } else { "" }
        "\"" + parts.join("") + suffix
      })
    })
  })
  let unquoted_character = @talc.string(needle)
    .not_followed_by("literal")
    .then(@talc.satisfy("unquoted character", char => char != '"'))
    .string_map(char => char.to_string())
  quoted
  .attempt()
  .or(unquoted_character)
  .many()
  .map(parts => parts.join(""))
  .skip(@talc.string(needle))
}

///|
fn quoted_syntax_text_parser() -> @talc.StringParser[String] {
  let part = @talc.char('\\')
    .then(@talc.satisfy("escaped quoted character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talc.none_of("\"").string_map(char => char.to_string()))
  @talc.char('"').bind(_ => {
    part
    .many()
    .bind(parts => {
      @talc.char('"')
      .optional()
      .map(close => {
        let suffix = if close is Some(_) { "\"" } else { "" }
        "\"" + parts.join("") + suffix
      })
    })
  })
}

///|
fn url_syntax_text_parser() -> @talc.StringParser[String] {
  let end = @talc.string("]]")
  let character = end
    .not_followed_by("URL terminator")
    .then(@talc.satisfy("URL character", _ => true))
    .string_map(char => char.to_string())
  @talc.string("[[")
  .then(character.many().map(parts => parts.join("")))
  .bind(content => {
    end
    .optional()
    .map(close => {
      let suffix = if close is Some(_) { "]]" } else { "" }
      "[[" + content + suffix
    })
  })
}

///|
fn line_without_comment_parser() -> @talc.StringParser[String] {
  let plain = @talc.satisfy("line content", char => {
    char != '\'' && char != '"'
  }).string_map(char => char.to_string())
  url_syntax_text_parser()
  .attempt()
  .or(quoted_syntax_text_parser().attempt())
  .or(plain)
  .many()
  .map(parts => parts.join(""))
}

///|
/// Split `name as alias` at the first separator outside quoted identifiers.
pub fn parse_alias_identifier(value : String) -> (String, String)? {
  match alias_identifier_parser().parse(@talc.Input::new(value)) {
    Ok(pair) => Some(pair)
    Err(_) => None
  }
}
