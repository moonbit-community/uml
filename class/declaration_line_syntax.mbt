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
priv struct DeclarationLineSyntax {
  declaration : Declaration
  opens_body : Bool
  mix_prefixed : Bool
  symbol : Bool
}

///|
fn declaration_visibility_parser() -> @talc.StringParser[Visibility] {
  @talc.one_of("+-#~")
  .map(char => {
    match char {
      '+' => Public
      '-' => Private
      '#' => Protected
      '~' => Package
      _ => Unknown
    }
  })
  .skip(inline_spaces())
  .optional()
  .map(value => value.unwrap_or(Unknown))
}

///|
fn declaration_generic_parser() -> @talc.StringParser[String] {
  @talc.char('<')
  .skip(@talc.char('<').not_followed_by("stereotype"))
  .then(generic_content_parser())
  .skip(@talc.char('>'))
}

///|
fn declaration_shaped_name_parser() -> @talc.StringParser[String] {
  let parentheses = @talc.char('(')
    .then(@talc.many_chars1(@talc.none_of(")")))
    .skip(@talc.char(')'))
    .map(value => "(" + value + ")")
  let actor = @talc.char(':')
    .then(@talc.many_chars1(@talc.none_of(":")))
    .skip(@talc.char(':'))
    .map(value => ":" + value + ":")
  let component = @talc.char('[')
    .then(@talc.many_chars1(@talc.none_of("]")))
    .skip(@talc.char(']'))
    .map(value => "[" + value + "]")
  @talc.choice([parentheses, actor, component])
}

///|
fn declaration_name_atom_parser() -> @talc.StringParser[
  DeclarationNameAtom,
] {
  let quoted = quoted_value_parser().map(value => (value, true))
  let shaped = declaration_shaped_name_parser().map(value => (value, false))
  let plain = @talc.many_chars1(
    @talc.satisfy("declaration name", char => {
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
fn declaration_name_syntax_parser() -> @talc.StringParser[
  DeclarationNameSyntax,
] {
  declaration_name_atom_parser().bind(first => {
    inline_space1()
    .then(inline_keyword_parser("as"))
    .then(inline_space1())
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
fn declaration_target_parser() -> @talc.StringParser[String] {
  quoted_value_parser()
  .attempt()
  .or(
    @talc.many_chars1(
      @talc.satisfy("inheritance target", char => {
        !char.is_whitespace() && char != ','
      }),
    ),
  )
  .map(normalize_name)
}

///|
fn declaration_target_list_parser() -> @talc.StringParser[Array[String]] {
  let separator = inline_spaces()
    .then(@talc.char(','))
    .skip(inline_spaces())
    .attempt()
  declaration_target_parser().sep_by1(separator)
}

///|
fn declaration_stereotype_parser() -> @talc.StringParser[
  DeclarationSuffixSyntax,
] {
  @talc.string("<<")
  .then(
    @talc.string(">>")
    .not_followed_by("stereotype terminator")
    .then(@talc.satisfy("stereotype", _ => true))
    .string_map(char => char.to_string())
    .many()
    .map(parts => parts.join("")),
  )
  .skip(@talc.string(">>"))
  .map(value => DeclarationStereotype("<<" + value + ">>"))
}

///|
fn declaration_url_parser() -> @talc.StringParser[DeclarationSuffixSyntax] {
  let terminator = @talc.string("]]")
  let character = terminator
    .not_followed_by("URL terminator")
    .then(@talc.satisfy("URL character", _ => true))
  @talc.string("[[")
  .then(@talc.many_chars(character))
  .skip(terminator)
  .bind(content => {
    match @core.parse_url_target("[[" + content + "]]") {
      Some(target) => @talc.pure(DeclarationUrl(target.target))
      None => @talc.fail("URL")
    }
  })
}

///|
fn declaration_line_style_parser() -> @talc.StringParser[
  DeclarationSuffixSyntax,
] {
  @talc.string("##")
  .then(
    @talc.char('[')
    .then(@talc.many_chars(@talc.none_of("]")))
    .skip(@talc.char(']'))
    .attempt()
    .optional(),
  )
  .bind(style => {
    @talc.many_chars(
      @talc.satisfy("line color", char => !char.is_whitespace()),
    ).map(color => {
      let color = if color.length() == 0 { None } else { Some(color) }
      DeclarationLine(style~, color~)
    })
  })
}

///|
fn declaration_suffix_parser() -> @talc.StringParser[
  DeclarationSuffixSyntax,
] {
  let extends = inline_keyword_parser("extends")
    .then(inline_space1())
    .then(declaration_target_list_parser())
    .map(values => DeclarationExtends(values))
  let implements = inline_keyword_parser("implements")
    .then(inline_space1())
    .then(declaration_target_list_parser())
    .map(values => DeclarationImplements(values))
  let tag = @talc.char('$')
    .then(
      @talc.many_chars1(
        @talc.satisfy("declaration tag", char => !char.is_whitespace()),
      ),
    )
    .map(value => DeclarationTag(value))
  let color = @talc.char('#')
    .then(
      @talc.many_chars1(
        @talc.satisfy("declaration color", char => !char.is_whitespace()),
      ),
    )
    .map(value => DeclarationColor(value))
  @talc.choice([
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
fn declaration_body_parser() -> @talc.StringParser[
  (DeclarationNameSyntax, DeclarationMetadataSyntax, Bool),
] {
  declaration_name_syntax_parser().bind(name => {
    inline_space1()
    .then(declaration_suffix_parser())
    .attempt()
    .many()
    .bind(suffixes => {
      inline_spaces()
      .then(
        @talc.string("{}")
        .map(_ => false)
        .attempt()
        .or(@talc.string("{").map(_ => true)),
      )
      .attempt()
      .optional()
      .skip(inline_spaces())
      .map(opens_body => {
        (name, declaration_metadata_from(suffixes), opens_body.unwrap_or(false))
      })
    })
  })
}

///|
fn declaration_kind_parser() -> @talc.StringParser[
  (EntityKind, Bool, Bool),
] {
  let static_class = inline_keyword_parser("static")
    .then(inline_space1())
    .then(inline_keyword_parser("class"))
    .map(_ => (Class, true, false))
  let abstract_class = inline_keyword_parser("abstract")
    .then(
      inline_space1().then(inline_keyword_parser("class")).attempt().optional(),
    )
    .map(_ => (AbstractClass, false, false))
  let regular = inline_word_parser("declaration word").bind(word => {
    let mix_prefixed = word.to_lower().has_prefix("mix_")
    let word = if mix_prefixed { word[4:].to_owned() } else { word }
    match declaration_kind(word) {
      Some(kind) => @talc.pure((kind, false, mix_prefixed))
      None => @talc.fail("declaration kind")
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
) -> @talc.StringParser[DeclarationLineSyntax] {
  declaration_kind_parser().bind(kind_and_static => {
    let (kind, is_static, mix_prefixed) = kind_and_static
    inline_space1()
    .then(declaration_body_parser())
    .map(body => {
      let (name, metadata, opens_body) = body
      {
        declaration: declaration_from_syntax(
          kind, visibility, is_static, name, metadata,
        ),
        opens_body,
        mix_prefixed,
        symbol: false,
      }
    })
  })
}

///|
fn symbol_declaration_parser(
  visibility : Visibility,
) -> @talc.StringParser[DeclarationLineSyntax] {
  let diamond = @talc.string("<>")
    .then(inline_spaces())
    .then(declaration_name_syntax_parser())
    .map(name => {
      declaration: declaration_from_syntax(
        Diamond,
        visibility,
        false,
        name,
        declaration_metadata_from([]),
      ),
      opens_body: false,
      mix_prefixed: false,
      symbol: true,
    })
  let interface = @talc.string("()")
    .then(inline_spaces())
    .then(
      @talc.char('#')
      .then(
        @talc.many_chars1(
          @talc.satisfy("ignored interface color", char => {
            !char.is_whitespace()
          }),
        ),
      )
      .skip(inline_space1())
      .attempt()
      .optional(),
    )
    .then(declaration_body_parser())
    .map(body => {
      let (name, metadata, opens_body) = body
      {
        declaration: declaration_from_syntax(
          Interface,
          visibility,
          false,
          name,
          metadata,
        ),
        opens_body,
        mix_prefixed: false,
        symbol: true,
      }
    })
  diamond.attempt().or(interface)
}

///|
fn declaration_line_parser() -> @talc.StringParser[DeclarationLineSyntax] {
  declaration_visibility_parser()
  .bind(visibility => {
    symbol_declaration_parser(visibility)
    .attempt()
    .or(regular_declaration_parser(visibility))
  })
  .skip(@talc.eof())
}
