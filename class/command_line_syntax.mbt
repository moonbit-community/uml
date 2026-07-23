///|
priv enum ClassCommandLineSyntax {
  ParsedPackage(GroupDeclaration)
  ParsedStereotypeAssignment(code~ : String, stereotype~ : String)
  ParsedUrlAssignment(code~ : String, url~ : String)
}

///|
fn package_keyword_parser() -> @talcparsec.StringParser[Bool] {
  inline_keyword_parser("package")
  .map(_ => false)
  .attempt()
  .or(inline_keyword_parser("namespace").map(_ => true))
}

///|
fn package_body_parser() -> @talcparsec.StringParser[
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
        @talcparsec.string("{}")
        .map(_ => true)
        .attempt()
        .or(@talcparsec.char('{').map(_ => false)),
      )
      .attempt()
      .optional()
      .skip(inline_spaces())
      .map(brace => {
        (name, declaration_metadata_from(suffixes), brace.unwrap_or(false))
      })
    })
  })
}

///|
fn package_line_parser() -> @talcparsec.StringParser[ClassCommandLineSyntax] {
  declaration_visibility_parser()
  .bind(visibility => {
    package_keyword_parser().bind(is_namespace => {
      inline_space1()
      .then(package_body_parser())
      .map(value => {
        let (name, metadata, empty) = value
        ParsedPackage({
          code: name.code,
          display: name.display,
          is_namespace,
          visibility,
          stereotype: metadata.stereotype,
          url: metadata.url,
          color: metadata.color,
          empty,
        })
      })
    })
  })
  .skip(@talcparsec.eof())
}

///|
fn stereotype_assignment_line_parser() -> @talcparsec.StringParser[
  ClassCommandLineSyntax,
] {
  let code = quoted_value_parser()
    .attempt()
    .or(
      @talcparsec.many_chars1(
        @talcparsec.satisfy("stereotype assignment target", char => {
          !char.is_whitespace() && char != '<'
        }),
      ),
    )
    .map(normalize_name)
  code
  .bind(code => {
    inline_space1()
    .then(stereotype_value_parser())
    .map(stereotype => ParsedStereotypeAssignment(code~, stereotype~))
  })
  .skip(@talcparsec.eof())
}

///|
fn url_assignment_target_parser() -> @talcparsec.StringParser[String] {
  quoted_value_parser()
  .attempt()
  .or(
    @talcparsec.many_chars1(
      @talcparsec.satisfy("URL assignment target", char => {
        !char.is_whitespace() && char != '['
      }),
    ),
  )
  .map(normalize_name)
}

///|
fn url_assignment_line_parser() -> @talcparsec.StringParser[
  ClassCommandLineSyntax,
] {
  inline_keyword_parser("url")
  .then(inline_space1())
  .then(
    inline_keyword_parser("of")
    .attempt()
    .or(inline_keyword_parser("for"))
    .then(inline_space1())
    .attempt()
    .optional(),
  )
  .bind(_ => {
    url_assignment_target_parser().bind(code => {
      inline_space1()
      .then(inline_keyword_parser("is"))
      .attempt()
      .optional()
      .then(inline_space1())
      .then(url_value_parser())
      .map(url => ParsedUrlAssignment(code~, url~))
    })
  })
  .skip(@talcparsec.eof())
}

///|
fn class_command_line_parser() -> @talcparsec.StringParser[
  ClassCommandLineSyntax,
] {
  package_line_parser()
  .attempt()
  .or(url_assignment_line_parser().attempt())
  .or(stereotype_assignment_line_parser())
}

///|
fn Parser::apply_package_declaration(
  self : Parser,
  group : GroupDeclaration,
) -> Unit {
  let parent = self.current_package()
  let segments = @core.split_unquoted(group.code, '.')
  let mut prefix = parent
  for segment_index, segment in segments {
    let qualified_name = if prefix.length() == 0 {
      segment
    } else {
      prefix + "." + segment
    }
    let is_last = segment_index == segments.length() - 1
    let display = if is_last { group.display } else { segment }
    let package_value : Package = {
      name: segment,
      qualified_name,
      display,
      parent: prefix,
      is_namespace: group.is_namespace,
      visibility: if is_last {
        group.visibility
      } else {
        Unknown
      },
      stereotype: if is_last {
        group.stereotype
      } else {
        None
      },
      url: if is_last {
        group.url
      } else {
        None
      },
      color: if is_last {
        group.color
      } else {
        None
      },
    }
    let mut existing = None
    for index, item in self.packages {
      if item.qualified_name == qualified_name {
        existing = Some(index)
        break
      }
    }
    match existing {
      Some(index) => if is_last { self.packages[index] = package_value }
      None => self.packages.push(package_value)
    }
    prefix = qualified_name
  }
  if !group.empty {
    self.package_stack.push(group.code)
  }
}

///|
fn Parser::apply_class_command(
  self : Parser,
  syntax : ClassCommandLineSyntax,
) -> Unit raise ParseError {
  match syntax {
    ParsedPackage(group) => self.apply_package_declaration(group)
    ParsedStereotypeAssignment(code~, stereotype~) => {
      guard self.set_entity_stereotype(code, stereotype) else {
        self.raise_parse_error("no such class \{code}")
      }
    }
    ParsedUrlAssignment(code~, url~) => {
      guard self.set_entity_url(code, url) else {
        self.raise_parse_error("unknown entity \{code}")
      }
    }
  }
}
