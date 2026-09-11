///|
fn json_single_declaration(
  cursor : @tokenizer.Cursor,
) -> JsonSingleDeclaration? {
  cursor.attempt(cursor => {
    let visibility = declaration_visibility(cursor)
    guard consume_inline_keyword(cursor, "json") && cursor.skip_inline_space1() else {
      return None
    }
    guard declaration_name_syntax(cursor) is Some(name) else { return None }
    let suffixes = take_declaration_suffixes(cursor)
    let metadata = declaration_metadata_from(suffixes)
    guard cursor.skip_inline_space1() else { return None }
    let data = cursor.take_rest_trimmed()
    guard data.length() > 0 && valid_json(data) else { return None }
    Some({
      declaration: declaration_from_syntax(
        Json,
        visibility,
        false,
        name,
        metadata,
      ),
      data,
    })
  })
}

///|
fn take_multiline_marker(cursor : @tokenizer.Cursor) -> Char? {
  cursor.attempt(cursor => {
    guard cursor.skip_inline_space1() else { return None }
    let after_space = cursor.offset()
    if consume_inline_keyword(cursor, "as") &&
      cursor.skip_inline_space1() &&
      cursor.consume('"') {
      return Some('"')
    }
    ignore(cursor.restore(after_space))
    if cursor.consume('[') {
      return Some(']')
    }
    None
  })
}

///|
fn multiline_element_header(
  cursor : @tokenizer.Cursor,
) -> MultilineElementHeader? {
  cursor.attempt(cursor => {
    let visibility = declaration_visibility(cursor)
    guard declaration_kind_syntax(cursor) is Some((kind, is_static, _)) else {
      return None
    }
    guard declaration_name_metadata(cursor) is Some((name, metadata)) else {
      return None
    }
    guard take_multiline_marker(cursor) is Some(terminator) else { return None }
    let first_line = cursor.take_while(char => char != terminator)
    guard cursor.is_eof() else { return None }
    Some({
      declaration: declaration_from_syntax(
        kind, visibility, is_static, name, metadata,
      ),
      first_line,
      terminator,
    })
  })
}

///|
fn external_member_line(
  cursor : @tokenizer.Cursor,
) -> (String, @entity.Member)? {
  cursor.attempt(cursor => {
    let target = StringBuilder()
    while true {
      if cursor.consume_literal("::") {
        target.write_string("::")
      } else if cursor.peek() is Some(char) && char != ':' {
        ignore(cursor.advance())
        target.write_char(char)
      } else {
        break
      }
    }
    guard cursor.consume(':') else { return None }
    let target = @tokenizer.unquote_identifier(
      target.to_string().trim().to_owned(),
    )
    let body = cursor.take_rest_trimmed()
    let invalid_target = target.length() == 0 ||
      body.length() == 0 ||
      target.to_lower().has_prefix("mix_") ||
      declaration_kind(target) is Some(_) ||
      target.contains("-") ||
      target.contains("<") ||
      target.contains("[[")
    if invalid_target {
      None
    } else {
      Some((target, member_of(body)))
    }
  })
}

///|
fn take_alignment(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    guard take_inline_word(cursor) is Some(word) else { return None }
    let aligned = word.to_lower()
    guard aligned is ("top" | "bottom" | "left" | "right" | "center") else {
      return None
    }
    Some(aligned)
  })
}

///|
fn aligned_text_block_kind(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    guard take_alignment(cursor) is Some(_) && cursor.skip_inline_space1() else {
      return None
    }
    guard take_inline_word(cursor) is Some(word) else { return None }
    let kind = word.to_lower()
    guard kind is ("header" | "footer") else { return None }
    Some(kind)
  })
}

///|
fn text_block_header(cursor : @tokenizer.Cursor) -> String? {
  cursor.attempt(cursor => {
    let kind = if consume_inline_keyword(cursor, "legend") {
      ignore(collect_repeated(cursor, take_alignment))
      "legend"
    } else if aligned_text_block_kind(cursor) is Some(kind) {
      kind
    } else {
      guard take_inline_word(cursor) is Some(word) else { return None }
      let kind = word.to_lower()
      guard kind is ("title" | "legend" | "header" | "footer" | "caption") else {
        return None
      }
      kind
    }
    guard cursor.is_eof() else { return None }
    Some(kind)
  })
}
