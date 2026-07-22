///|
fn alias_identifier_parser() -> @talcparsec.StringParser[(String, String)] {
  let separator = @talcparsec.string(" as ")
  let quoted_part = @talcparsec.string("\\\"").or(
    @talcparsec.none_of("\"").string_map(char => char.to_string()),
  )
  let quoted_identifier = @talcparsec.char('"')
    .then(quoted_part.many().map(parts => "\"" + parts.join("") + "\""))
    .skip(@talcparsec.char('"'))
  let unquoted_character = separator
    .not_followed_by("alias separator")
    .then(@talcparsec.satisfy("identifier character", _ => true))
    .string_map(char => char.to_string())
  let name = quoted_identifier
    .attempt()
    .or(unquoted_character)
    .many()
    .map(parts => parts.join(""))
  name
  .skip(separator)
  .bind(left => {
    @talcparsec.many_chars(
      @talcparsec.satisfy("identifier character", _ => true),
    ).map(right => (left, right))
  })
  .skip(@talcparsec.eof())
}

///|
fn syntax_words_parser() -> @talcparsec.StringParser[Array[String]] {
  let quoted_part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talcparsec.none_of("\"").string_map(char => char.to_string()))
  let quoted = @talcparsec.char('"').bind(_ => {
    quoted_part
    .many()
    .bind(parts => {
      @talcparsec.char('"')
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
  let unquoted = @talcparsec.satisfy("unquoted character", char => {
    !char.is_whitespace() && char != '"'
  }).string_map(char => char.to_string())
  let word = quoted.attempt().or(unquoted).some().map(parts => parts.join(""))
  @talcparsec.spaces()
  .then(word.skip(@talcparsec.spaces()).many())
  .skip(@talcparsec.eof())
}

///|
priv enum UnquotedSplitToken {
  Text(String)
  Delimiter
}

///|
fn split_unquoted_parser(
  delimiter : Char,
) -> @talcparsec.StringParser[Array[String]] {
  let quoted_part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talcparsec.none_of("\"").string_map(char => char.to_string()))
  let quoted = @talcparsec.char('"').bind(_ => {
    quoted_part
    .many()
    .bind(parts => {
      @talcparsec.char('"')
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
  let text = @talcparsec.satisfy("unquoted character", char => {
      char != delimiter && char != '"'
    })
    .string_map(char => char.to_string())
    .map(value => Text(value))
  let token = @talcparsec.char(delimiter)
    .map(_ => Delimiter)
    .or(quoted.attempt())
    .or(text)
  token
  .many()
  .skip(@talcparsec.eof())
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
fn literal_prefix_parser(needle : String) -> @talcparsec.StringParser[String] {
  let character = @talcparsec.string(needle)
    .not_followed_by("literal")
    .then(@talcparsec.satisfy("character", _ => true))
  @talcparsec.many_chars(character).skip(@talcparsec.string(needle))
}

///|
fn unquoted_literal_prefix_parser(
  needle : String,
) -> @talcparsec.StringParser[String] {
  let quoted_part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talcparsec.none_of("\"").string_map(char => char.to_string()))
  let quoted = @talcparsec.char('"').bind(_ => {
    quoted_part
    .many()
    .bind(parts => {
      @talcparsec.char('"')
      .optional()
      .map(close => {
        let suffix = if close is Some(_) { "\"" } else { "" }
        "\"" + parts.join("") + suffix
      })
    })
  })
  let unquoted_character = @talcparsec.string(needle)
    .not_followed_by("literal")
    .then(@talcparsec.satisfy("unquoted character", char => char != '"'))
    .string_map(char => char.to_string())
  quoted
  .attempt()
  .or(unquoted_character)
  .many()
  .map(parts => parts.join(""))
  .skip(@talcparsec.string(needle))
}

///|
fn quoted_syntax_text_parser() -> @talcparsec.StringParser[String] {
  let part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped quoted character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talcparsec.none_of("\"").string_map(char => char.to_string()))
  @talcparsec.char('"').bind(_ => {
    part
    .many()
    .bind(parts => {
      @talcparsec.char('"')
      .optional()
      .map(close => {
        let suffix = if close is Some(_) { "\"" } else { "" }
        "\"" + parts.join("") + suffix
      })
    })
  })
}

///|
fn url_syntax_text_parser() -> @talcparsec.StringParser[String] {
  let end = @talcparsec.string("]]")
  let character = end
    .not_followed_by("URL terminator")
    .then(@talcparsec.satisfy("URL character", _ => true))
    .string_map(char => char.to_string())
  @talcparsec.string("[[")
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
fn line_without_comment_parser() -> @talcparsec.StringParser[String] {
  let plain = @talcparsec.satisfy("line content", char => {
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
  match alias_identifier_parser().parse(@talcparsec.Input::new(value)) {
    Ok(pair) => Some(pair)
    Err(_) => None
  }
}
