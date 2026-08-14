///|
fn json_single_declaration(cursor : @parse.Cursor) -> JsonSingleDeclaration? {
  let start = cursor.offset()
  let visibility = declaration_visibility(cursor)
  guard consume_inline_keyword(cursor, "json") && cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard declaration_name_syntax(cursor) is Some(name) else {
    ignore(cursor.restore(start))
    return None
  }
  let suffixes = take_declaration_suffixes(cursor)
  let metadata = declaration_metadata_from(suffixes)
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  let data = cursor.take_while(_ => true).trim().to_owned()
  guard data.length() > 0 && valid_json(data) else {
    ignore(cursor.restore(start))
    return None
  }
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
}

///|
fn take_multiline_marker(cursor : @parse.Cursor) -> Char? {
  let start = cursor.offset()
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
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
  ignore(cursor.restore(start))
  None
}

///|
fn multiline_element_header(cursor : @parse.Cursor) -> MultilineElementHeader? {
  let start = cursor.offset()
  let visibility = declaration_visibility(cursor)
  guard declaration_kind_syntax(cursor) is Some((kind, is_static, _)) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard declaration_name_syntax(cursor) is Some(name) else {
    ignore(cursor.restore(start))
    return None
  }
  let suffixes = take_declaration_suffixes(cursor)
  let metadata = declaration_metadata_from(suffixes)
  guard take_multiline_marker(cursor) is Some(terminator) else {
    ignore(cursor.restore(start))
    return None
  }
  let first_line = cursor.take_while(char => char != terminator)
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some({
    declaration: declaration_from_syntax(
      kind, visibility, is_static, name, metadata,
    ),
    first_line,
    terminator,
  })
}

///|
fn external_member_line(cursor : @parse.Cursor) -> (String, Member)? {
  let start = cursor.offset()
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
  guard cursor.consume(':') else {
    ignore(cursor.restore(start))
    return None
  }
  let target = @parse.unquote_identifier(target.to_string().trim().to_owned())
  let body = cursor.take_while(_ => true).trim().to_owned()
  let invalid_target = target.length() == 0 ||
    body.length() == 0 ||
    target.to_lower().has_prefix("mix_") ||
    declaration_kind(target) is Some(_) ||
    target.contains("-") ||
    target.contains("<") ||
    target.contains("[[")
  if invalid_target {
    ignore(cursor.restore(start))
    None
  } else {
    Some((target, member_of(body)))
  }
}

///|
fn take_alignment(cursor : @parse.Cursor) -> Bool {
  let start = cursor.offset()
  guard take_inline_word(cursor) is Some(word) else { return false }
  let aligned = word.to_lower()
    is ("top" | "bottom" | "left" | "right" | "center")
  guard aligned else {
    ignore(cursor.restore(start))
    return false
  }
  aligned
}

///|
fn text_block_header(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  let legend : String? = if consume_inline_keyword(cursor, "legend") {
    while true {
      let segment_start = cursor.offset()
      guard cursor.skip_inline_space1() && take_alignment(cursor) else {
        ignore(cursor.restore(segment_start))
        break
      }
    }
    Some("legend")
  } else {
    ignore(cursor.restore(start))
    None
  }
  let aligned : String? = match legend {
    Some(value) => Some(value)
    None =>
      if take_alignment(cursor) && cursor.skip_inline_space1() {
        if consume_inline_keyword(cursor, "header") {
          Some("header")
        } else if consume_inline_keyword(cursor, "footer") {
          Some("footer")
        } else {
          ignore(cursor.restore(start))
          None
        }
      } else {
        ignore(cursor.restore(start))
        None
      }
  }
  let simple : String? = match aligned {
    Some(value) => Some(value)
    None =>
      match take_inline_word(cursor) {
        Some(word) =>
          match word.to_lower() {
            "title" | "legend" | "header" | "footer" | "caption" =>
              Some(word.to_lower())
            _ => {
              ignore(cursor.restore(start))
              None
            }
          }
        None => {
          ignore(cursor.restore(start))
          None
        }
      }
  }
  match simple {
    Some(value) if cursor.is_eof() => Some(value)
    _ => {
      ignore(cursor.restore(start))
      None
    }
  }
}
