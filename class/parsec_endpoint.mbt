///|
priv enum EndpointToken {
  EndpointText(String)
  EndpointQuoted(raw~ : String, content~ : String)
}

///|
fn endpoint_quoted_parser() -> @talcparsec.StringParser[EndpointToken] {
  let part = @talcparsec.char('\\')
    .then(@talcparsec.satisfy("escaped endpoint character", _ => true))
    .map(char => "\\" + char.to_string())
    .or(@talcparsec.none_of("\"").string_map(char => char.to_string()))
  @talcparsec.char('"').bind(_ => {
    part
    .many()
    .bind(parts => {
      @talcparsec.char('"').map(_ => {
        let content = parts.join("")
        EndpointQuoted(raw="\"" + content + "\"", content~)
      })
    })
  })
}

///|
fn endpoint_tokens_parser() -> @talcparsec.StringParser[Array[EndpointToken]] {
  let text = @talcparsec.satisfy("endpoint text", _ => true).string_map(char => {
    EndpointText(char.to_string())
  })
  endpoint_quoted_parser().attempt().or(text).many().skip(@talcparsec.eof())
}

///|
fn EndpointToken::source(self : EndpointToken) -> String {
  match self {
    EndpointText(value) => value
    EndpointQuoted(raw~, ..) => raw
  }
}

///|
fn endpoint_token_source(tokens : ArrayView[EndpointToken]) -> String {
  tokens.map(EndpointToken::source).join("")
}

///|
fn named_note_text_parser() -> @talcparsec.StringParser[(String, String)] {
  endpoint_quoted_parser()
  .bind(token => {
    guard token is EndpointQuoted(content~, ..) else {
      return @talcparsec.fail("quoted note text")
    }
    @talcparsec.whitespace()
    .some()
    .then(
      @talcparsec.many_chars1(
        @talcparsec.satisfy("note alias keyword", Char::is_ascii_alphabetic),
      ),
    )
    .bind(keyword => {
      guard keyword.equal_ignore_ascii_case("as") else {
        return @talcparsec.fail("note alias keyword")
      }
      @talcparsec.whitespace()
      .some()
      .then(
        @talcparsec.many_chars1(
          @talcparsec.satisfy("named note metadata", _ => true),
        ),
      )
      .map(metadata => (content, metadata))
    })
  })
  .skip(@talcparsec.eof())
}

///|
fn parse_named_note_text(value : String) -> (String, String)? {
  match named_note_text_parser().parse(@talcparsec.Input::new(value)) {
    Ok(result) => Some(result)
    Err(_) => None
  }
}

///|
fn parse_endpoint_parts(
  raw : String,
  cardinality_before : Bool,
) -> (String, String?)? {
  let whole_quoted = @talcparsec.spaces()
    .then(endpoint_quoted_parser())
    .skip(@talcparsec.spaces())
    .skip(@talcparsec.eof())
  if whole_quoted.parse(@talcparsec.Input::new(raw)) is Ok(_) {
    return Some((raw.trim().to_owned(), None))
  }
  guard endpoint_tokens_parser().parse(@talcparsec.Input::new(raw))
    is Ok(tokens) else {
    return None
  }
  let mut selected = None
  for index, token in tokens {
    if token is EndpointQuoted(..) && (cardinality_before || selected is None) {
      selected = Some(index)
    }
  }
  guard selected is Some(index) else { return None }
  guard tokens[index] is EndpointQuoted(content~, ..) else { return None }
  let code = if cardinality_before {
    endpoint_token_source(tokens[0:index]).trim().to_owned()
  } else {
    endpoint_token_source(tokens[index + 1:]).trim().to_owned()
  }
  guard code.length() > 0 else { return None }
  Some((code, Some(content)))
}

///|
fn text_before_parser(separator : String) -> @talcparsec.StringParser[String] {
  let quoted = endpoint_quoted_parser().map(EndpointToken::source)
  let text = @talcparsec.string(separator)
    .not_followed_by("separator")
    .then(@talcparsec.satisfy("text", char => char != '"'))
    .string_map(char => char.to_string())
  quoted
  .attempt()
  .or(text)
  .many()
  .map(parts => parts.join(""))
  .skip(@talcparsec.string(separator))
}

///|
fn left_role_parser() -> @talcparsec.StringParser[(String, String)] {
  text_before_parser(" /")
  .bind(entity => {
    @talcparsec.many_chars1(@talcparsec.satisfy("relation role", _ => true)).map(role => {
        (entity.trim().to_owned(), role.trim().to_owned())
      },
    )
  })
  .skip(@talcparsec.eof())
}

///|
fn right_role_parser() -> @talcparsec.StringParser[(String, String)] {
  let role = endpoint_quoted_parser()
    .bind(token => {
      match token {
        EndpointQuoted(content~, ..) => @talcparsec.pure(content)
        _ => @talcparsec.fail("quoted relation role")
      }
    })
    .attempt()
    .or(
      @talcparsec.many_chars1(
        @talcparsec.satisfy("relation role", char => !char.is_whitespace()),
      ),
    )
  @talcparsec.spaces()
  .then(@talcparsec.char('/'))
  .then(role)
  .bind(role => {
    @talcparsec.whitespace()
    .some()
    .then(
      @talcparsec.many_chars1(
        @talcparsec.satisfy("relation endpoint", _ => true),
      ),
    )
    .map(entity => (entity.trim().to_owned(), role))
  })
  .skip(@talcparsec.eof())
}

///|
fn qualifier_parser(
  qualifier_after_entity : Bool,
) -> @talcparsec.StringParser[(String, String)] {
  let qualifier = @talcparsec.char('[')
    .then(@talcparsec.many_chars1(@talcparsec.none_of("]")))
    .skip(@talcparsec.char(']'))
  if qualifier_after_entity {
    text_before_parser("[")
    .bind(entity => {
      @talcparsec.many_chars1(@talcparsec.none_of("]"))
      .skip(@talcparsec.char(']'))
      .bind(value => {
        @talcparsec.satisfy("trailing qualifier text", _ => true)
        .many()
        .map(_ => (entity.trim().to_owned(), value.trim().to_owned()))
      })
    })
    .skip(@talcparsec.eof())
  } else {
    @talcparsec.spaces()
    .then(qualifier)
    .bind(value => {
      @talcparsec.many_chars1(
        @talcparsec.satisfy("qualified endpoint", _ => true),
      ).map(entity => (entity.trim().to_owned(), value.trim().to_owned()))
    })
    .skip(@talcparsec.eof())
  }
}

///|
fn port_parser() -> @talcparsec.StringParser[(String, String)] {
  text_before_parser("::")
  .bind(base => {
    @talcparsec.many_chars1(@talcparsec.satisfy("relation port", _ => true)).map(port => {
        (base.trim().to_owned(), port.trim().to_owned())
      },
    )
  })
  .skip(@talcparsec.eof())
}
