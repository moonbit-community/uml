///|
fn declaration_metadata_tail_parser() -> @talc.StringParser[
  DeclarationMetadataSyntax,
] {
  inline_space1()
  .then(declaration_suffix_parser())
  .attempt()
  .many()
  .map(declaration_metadata_from)
}

///|
fn json_single_declaration_parser() -> @talc.StringParser[
  JsonSingleDeclaration,
] {
  declaration_visibility_parser()
  .bind(visibility => {
    inline_keyword_parser("json")
    .then(inline_space1())
    .then(declaration_name_syntax_parser())
    .bind(name => {
      declaration_metadata_tail_parser().bind(metadata => {
        inline_space1()
        .then(
          @talc.many_chars1(@talc.satisfy("JSON data", _ => true)),
        )
        .bind(data => {
          let data = data.trim().to_owned()
          if valid_json(data) {
            @talc.pure({
              declaration: declaration_from_syntax(
                Json,
                visibility,
                false,
                name,
                metadata,
              ),
              data,
            })
          } else {
            @talc.fail("valid JSON data")
          }
        })
      })
    })
  })
  .skip(@talc.eof())
}

///|
fn multiline_element_header_parser() -> @talc.StringParser[
  MultilineElementHeader,
] {
  declaration_visibility_parser()
  .bind(visibility => {
    declaration_kind_parser().bind(kind_and_static => {
      let (kind, is_static, _) = kind_and_static
      inline_space1()
      .then(declaration_name_syntax_parser())
      .bind(name => {
        declaration_metadata_tail_parser().bind(metadata => {
          let quoted_marker = inline_space1()
            .then(inline_keyword_parser("as"))
            .then(inline_space1())
            .then(@talc.char('"'))
            .map(_ => '"')
          let bracket_marker = inline_space1()
            .then(@talc.char('['))
            .map(_ => ']')
          quoted_marker
          .attempt()
          .or(bracket_marker)
          .bind(terminator => {
            @talc.many_chars(
              @talc.satisfy("multiline description", char => {
                char != terminator
              }),
            ).map(first_line => {
              declaration: declaration_from_syntax(
                kind, visibility, is_static, name, metadata,
              ),
              first_line,
              terminator,
            })
          })
        })
      })
    })
  })
  .skip(@talc.eof())
}

///|
fn external_member_line_parser() -> @talc.StringParser[(String, Member)] {
  let separator = @talc.char(':')
  let qualified = @talc.string("::")
  let target_part = qualified
    .attempt()
    .or(
      separator
      .not_followed_by("external member separator")
      .then(@talc.satisfy("external member target", _ => true))
      .string_map(char => char.to_string()),
    )
  target_part
  .many()
  .map(parts => parts.join("").trim().to_owned())
  .skip(separator)
  .bind(target => {
    @talc.many_chars1(
      @talc.satisfy("external member body", _ => true),
    ).bind(body => {
      let target = normalize_name(target)
      let body = body.trim().to_owned()
      let invalid_target = target.length() == 0 ||
        body.length() == 0 ||
        target.to_lower().has_prefix("mix_") ||
        declaration_kind(target) is Some(_) ||
        target.contains("-") ||
        target.contains("<") ||
        target.contains("[[")
      if invalid_target {
        @talc.fail("external member")
      } else {
        @talc.pure((target, member_of(body)))
      }
    })
  })
  .skip(@talc.eof())
}

///|
fn text_block_header_parser() -> @talc.StringParser[String] {
  let alignment = inline_word_parser("text block alignment").bind(word => {
    match word.to_lower() {
      "top" | "bottom" | "left" | "right" | "center" => @talc.pure(())
      _ => @talc.fail("text block alignment")
    }
  })
  let legend = inline_keyword_parser("legend")
    .then(inline_space1().then(alignment).some().optional())
    .map(_ => "legend")
  let aligned_header = alignment
    .then(inline_space1())
    .then(
      inline_keyword_parser("header")
      .map(_ => "header")
      .attempt()
      .or(inline_keyword_parser("footer").map(_ => "footer")),
    )
  let simple = inline_word_parser("text block keyword").bind(word => {
    match word.to_lower() {
      "title" | "legend" | "header" | "footer" | "caption" =>
        @talc.pure(word.to_lower())
      _ => @talc.fail("text block keyword")
    }
  })
  legend
  .attempt()
  .or(aligned_header.attempt())
  .or(simple)
  .skip(@talc.eof())
}
