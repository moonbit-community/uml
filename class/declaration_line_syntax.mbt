///|
priv struct DeclarationNameAtom {
  value : String
  generic : String?
  quoted : Bool
}

///|
priv struct DeclarationNameSyntax {
  display : String
  code : String
  generic : String?
}

///|
priv enum DeclarationSuffixSyntax {
  DeclarationExtends(Array[String])
  DeclarationImplements(Array[String])
  DeclarationStereotype(String)
  DeclarationUrl(String)
  DeclarationTag(String)
  DeclarationColor(String)
  DeclarationLine(style~ : String?, color~ : String?)
}

///|
priv struct DeclarationMetadataSyntax {
  extends : Array[String]
  implements : Array[String]
  stereotype : String?
  url : String?
  tags : Array[String]
  color : String?
  line_color : String?
  line_style : String?
}

///|
fn declaration_spaces() -> @talcparsec.StringParser[Unit] {
  @talcparsec.satisfy("inline whitespace", char => {
    char == ' ' || char == '\t' || char == '\r'
  })
  .many()
  .map(_ => ())
}

///|
fn declaration_space1() -> @talcparsec.StringParser[Unit] {
  @talcparsec.satisfy("inline whitespace", char => {
    char == ' ' || char == '\t' || char == '\r'
  })
  .some()
  .map(_ => ())
}

///|
fn declaration_word_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.many_chars1(
    @talcparsec.satisfy("declaration word", char => {
      char.is_ascii_alphabetic() || char == '_' || char == '/'
    }),
  )
}

///|
fn declaration_keyword_parser(
  keyword : String,
) -> @talcparsec.StringParser[Unit] {
  declaration_word_parser().bind(word => {
    if word.equal_ignore_ascii_case(keyword) {
      @talcparsec.pure(())
    } else {
      @talcparsec.fail(keyword)
    }
  })
}

///|
fn declaration_visibility_parser() -> @talcparsec.StringParser[Visibility] {
  @talcparsec.one_of("+-#~")
  .map(char => {
    match char {
      '+' => Public
      '-' => Private
      '#' => Protected
      '~' => Package
      _ => Unknown
    }
  })
  .skip(declaration_spaces())
  .optional()
  .map(value => value.unwrap_or(Unknown))
}

///|
fn declaration_generic_parser() -> @talcparsec.StringParser[String] {
  @talcparsec.char('<')
  .skip(@talcparsec.char('<').not_followed_by("stereotype"))
  .then(generic_content_parser())
  .skip(@talcparsec.char('>'))
}

///|
fn declaration_shaped_name_parser() -> @talcparsec.StringParser[String] {
  let parentheses = @talcparsec.char('(')
    .then(@talcparsec.many_chars1(@talcparsec.none_of(")")))
    .skip(@talcparsec.char(')'))
    .map(value => "(" + value + ")")
  let actor = @talcparsec.char(':')
    .then(@talcparsec.many_chars1(@talcparsec.none_of(":")))
    .skip(@talcparsec.char(':'))
    .map(value => ":" + value + ":")
  let component = @talcparsec.char('[')
    .then(@talcparsec.many_chars1(@talcparsec.none_of("]")))
    .skip(@talcparsec.char(']'))
    .map(value => "[" + value + "]")
  @talcparsec.choice([parentheses, actor, component])
}

///|
fn declaration_name_atom_parser() -> @talcparsec.StringParser[
  DeclarationNameAtom,
] {
  let quoted = quoted_value_parser().map(value => (value, true))
  let shaped = declaration_shaped_name_parser().map(value => (value, false))
  let plain = @talcparsec.many_chars1(
    @talcparsec.satisfy("declaration name", char => {
      !char.is_whitespace() &&
      char != '<' &&
      char != '{' &&
      char != ',' &&
      char != '$' &&
      char != '#'
    }),
  ).map(value => (value, false))
  quoted
  .attempt()
  .or(shaped.attempt())
  .or(plain)
  .bind(pair => {
    let (value, quoted) = pair
    declaration_generic_parser()
    .attempt()
    .optional()
    .map(generic => { value: normalize_name(value), generic, quoted })
  })
}

///|
fn declaration_name_syntax_parser() -> @talcparsec.StringParser[
  DeclarationNameSyntax,
] {
  declaration_name_atom_parser().bind(first => {
    declaration_space1()
    .then(declaration_keyword_parser("as"))
    .then(declaration_space1())
    .then(declaration_name_atom_parser())
    .attempt()
    .optional()
    .map(alternate => {
      match alternate {
        Some(second) => {
          let generic = match first.generic {
            Some(value) => Some(value)
            None => second.generic
          }
          if second.quoted {
            { display: second.value, code: first.value, generic }
          } else {
            { display: first.value, code: second.value, generic }
          }
        }
        None =>
          { display: first.value, code: first.value, generic: first.generic }
      }
    })
  })
}

///|
fn declaration_target_parser() -> @talcparsec.StringParser[String] {
  quoted_value_parser()
  .attempt()
  .or(
    @talcparsec.many_chars1(
      @talcparsec.satisfy("inheritance target", char => {
        !char.is_whitespace() && char != ','
      }),
    ),
  )
  .map(normalize_name)
}

///|
fn declaration_target_list_parser() -> @talcparsec.StringParser[Array[String]] {
  let separator = declaration_spaces()
    .then(@talcparsec.char(','))
    .skip(declaration_spaces())
    .attempt()
  declaration_target_parser().sep_by1(separator)
}

///|
fn declaration_stereotype_parser() -> @talcparsec.StringParser[
  DeclarationSuffixSyntax,
] {
  @talcparsec.string("<<")
  .then(
    @talcparsec.string(">>")
    .not_followed_by("stereotype terminator")
    .then(@talcparsec.satisfy("stereotype", _ => true))
    .string_map(char => char.to_string())
    .many()
    .map(parts => parts.join("")),
  )
  .skip(@talcparsec.string(">>"))
  .map(value => DeclarationStereotype("<<" + value + ">>"))
}

///|
fn declaration_url_parser() -> @talcparsec.StringParser[DeclarationSuffixSyntax] {
  let terminator = @talcparsec.string("]]")
  let character = terminator
    .not_followed_by("URL terminator")
    .then(@talcparsec.satisfy("URL character", _ => true))
  @talcparsec.string("[[")
  .then(@talcparsec.many_chars(character))
  .skip(terminator)
  .bind(content => {
    match @core.parse_url_target("[[" + content + "]]") {
      Some(target) => @talcparsec.pure(DeclarationUrl(target.target))
      None => @talcparsec.fail("URL")
    }
  })
}

///|
fn declaration_line_style_parser() -> @talcparsec.StringParser[
  DeclarationSuffixSyntax,
] {
  @talcparsec.string("##")
  .then(
    @talcparsec.char('[')
    .then(@talcparsec.many_chars(@talcparsec.none_of("]")))
    .skip(@talcparsec.char(']'))
    .attempt()
    .optional(),
  )
  .bind(style => {
    @talcparsec.many_chars(
      @talcparsec.satisfy("line color", char => !char.is_whitespace()),
    ).map(color => {
      let color = if color.length() == 0 { None } else { Some(color) }
      DeclarationLine(style~, color~)
    })
  })
}

///|
fn declaration_suffix_parser() -> @talcparsec.StringParser[
  DeclarationSuffixSyntax,
] {
  let extends = declaration_keyword_parser("extends")
    .then(declaration_space1())
    .then(declaration_target_list_parser())
    .map(values => DeclarationExtends(values))
  let implements = declaration_keyword_parser("implements")
    .then(declaration_space1())
    .then(declaration_target_list_parser())
    .map(values => DeclarationImplements(values))
  let tag = @talcparsec.char('$')
    .then(
      @talcparsec.many_chars1(
        @talcparsec.satisfy("declaration tag", char => !char.is_whitespace()),
      ),
    )
    .map(value => DeclarationTag(value))
  let color = @talcparsec.char('#')
    .then(
      @talcparsec.many_chars1(
        @talcparsec.satisfy("declaration color", char => !char.is_whitespace()),
      ),
    )
    .map(value => DeclarationColor(value))
  @talcparsec.choice([
    extends.attempt(),
    implements.attempt(),
    declaration_stereotype_parser().attempt(),
    declaration_url_parser().attempt(),
    declaration_line_style_parser().attempt(),
    tag.attempt(),
    color,
  ])
}

///|
fn declaration_metadata_from(
  suffixes : Array[DeclarationSuffixSyntax],
) -> DeclarationMetadataSyntax {
  let extends = []
  let implements = []
  let tags = []
  let mut stereotype = None
  let mut url = None
  let mut color = None
  let mut line_color = None
  let mut line_style = None
  for suffix in suffixes {
    match suffix {
      DeclarationExtends(values) => values.each(value => extends.push(value))
      DeclarationImplements(values) =>
        values.each(value => implements.push(value))
      DeclarationStereotype(value) => stereotype = Some(value)
      DeclarationUrl(value) => url = Some(value)
      DeclarationTag(value) => tags.push(value)
      DeclarationColor(value) => color = Some(value)
      DeclarationLine(style~, color~) => {
        line_style = style
        line_color = color
      }
    }
  }
  { extends, implements, stereotype, url, tags, color, line_color, line_style }
}

///|
fn declaration_body_parser() -> @talcparsec.StringParser[
  (DeclarationNameSyntax, DeclarationMetadataSyntax),
] {
  declaration_name_syntax_parser().bind(name => {
    declaration_space1()
    .then(declaration_suffix_parser())
    .attempt()
    .many()
    .bind(suffixes => {
      declaration_spaces()
      .then(@talcparsec.string("{}").attempt().or(@talcparsec.string("{")))
      .attempt()
      .optional()
      .skip(declaration_spaces())
      .map(_ => (name, declaration_metadata_from(suffixes)))
    })
  })
}

///|
fn declaration_kind_parser() -> @talcparsec.StringParser[(EntityKind, Bool)] {
  let static_class = declaration_keyword_parser("static")
    .then(declaration_space1())
    .then(declaration_keyword_parser("class"))
    .map(_ => (Class, true))
  let abstract_class = declaration_keyword_parser("abstract")
    .then(
      declaration_space1()
      .then(declaration_keyword_parser("class"))
      .attempt()
      .optional(),
    )
    .map(_ => (AbstractClass, false))
  let regular = declaration_word_parser().bind(word => {
    let word = if word.to_lower().has_prefix("mix_") {
      word[4:].to_owned()
    } else {
      word
    }
    match declaration_kind(word) {
      Some(kind) => @talcparsec.pure((kind, false))
      None => @talcparsec.fail("declaration kind")
    }
  })
  static_class.attempt().or(abstract_class.attempt()).or(regular)
}

///|
fn declaration_from_syntax(
  kind : EntityKind,
  visibility : Visibility,
  is_static : Bool,
  name : DeclarationNameSyntax,
  metadata : DeclarationMetadataSyntax,
) -> Declaration {
  let (kind, display, code) = shaped_declaration(kind, name.display, name.code)
  {
    kind,
    code,
    display,
    visibility,
    is_static,
    generic: name.generic,
    stereotype: metadata.stereotype,
    extends: metadata.extends,
    implements: metadata.implements,
    url: metadata.url,
    color: metadata.color,
    line_color: metadata.line_color,
    line_style: metadata.line_style,
    tags: metadata.tags,
  }
}

///|
fn regular_declaration_parser(
  visibility : Visibility,
) -> @talcparsec.StringParser[Declaration] {
  declaration_kind_parser().bind(kind_and_static => {
    let (kind, is_static) = kind_and_static
    declaration_space1()
    .then(declaration_body_parser())
    .map(body => {
      let (name, metadata) = body
      declaration_from_syntax(kind, visibility, is_static, name, metadata)
    })
  })
}

///|
fn symbol_declaration_parser(
  visibility : Visibility,
) -> @talcparsec.StringParser[Declaration] {
  let diamond = @talcparsec.string("<>")
    .then(declaration_spaces())
    .then(declaration_name_syntax_parser())
    .map(name => {
      declaration_from_syntax(
        Diamond,
        visibility,
        false,
        name,
        declaration_metadata_from([]),
      )
    })
  let interface = @talcparsec.string("()")
    .then(declaration_spaces())
    .then(
      @talcparsec.char('#')
      .then(
        @talcparsec.many_chars1(
          @talcparsec.satisfy("ignored interface color", char => {
            !char.is_whitespace()
          }),
        ),
      )
      .skip(declaration_space1())
      .attempt()
      .optional(),
    )
    .then(declaration_body_parser())
    .map(body => {
      let (name, metadata) = body
      declaration_from_syntax(Interface, visibility, false, name, metadata)
    })
  diamond.attempt().or(interface)
}

///|
fn declaration_line_parser() -> @talcparsec.StringParser[Declaration] {
  declaration_visibility_parser()
  .bind(visibility => {
    symbol_declaration_parser(visibility)
    .attempt()
    .or(regular_declaration_parser(visibility))
  })
  .skip(@talcparsec.eof())
}

///|
fn parse_declaration_line(line : String) -> Declaration? {
  match declaration_line_parser().parse(@talcparsec.Input::new(line)) {
    Ok(declaration) if declaration.code.length() > 0 => Some(declaration)
    _ => None
  }
}
