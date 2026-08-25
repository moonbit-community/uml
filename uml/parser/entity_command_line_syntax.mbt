///|
priv enum ClassCommandLineSyntax {
  ParsedPackage(@entity.GroupDeclaration)
  ParsedInvalidSymbolPackage
  ParsedStereotypeAssignment(code~ : String, stereotype~ : String)
  ParsedUrlAssignment(code~ : String, url~ : String)
}

///|
/// The symbols of PlantUML's `CommandPackageWithUSymbol`: a declaration
/// keyword followed by a name and `{` opens a group rendered with that
/// symbol instead of a plain package. `package` keeps its empty `{}` form
/// (handled by `package_line`), the other symbols require a literal `{`
/// (their `{}` form is rejected by PlantUML).
let symbol_package_keywords : FixedArray[String] = [
  "rectangle", "hexagon", "node", "artifact", "folder", "file", "frame", "cloud",
  "action", "process", "database", "storage", "component", "card", "queue", "stack",
]

///|
fn package_keyword(cursor : @parse.Cursor) -> Bool? {
  if consume_inline_keyword(cursor, "package") {
    Some(false)
  } else if consume_inline_keyword(cursor, "namespace") {
    Some(true)
  } else {
    None
  }
}

///|
fn symbol_package_keyword(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard take_inline_word(cursor) is Some(word) else { return None }
  let lower = word.to_lower()
  if symbol_package_keywords.contains(lower) {
    Some(lower)
  } else {
    ignore(cursor.restore(start))
    None
  }
}

///|
fn symbol_package_body(
  cursor : @parse.Cursor,
) -> (DeclarationNameSyntax, DeclarationMetadataSyntax, Bool)? {
  guard take_declaration_name_and_suffixes(cursor) is Some((name, metadata)) else {
    return None
  }
  cursor.skip_inline_spaces()
  // Only a literal `{` opens the group: PlantUML rejects the `{}` form for
  // symbol packages, unlike the empty `package X {}`.
  if cursor.consume_literal("{}") {
    return Some((name, metadata, true))
  }
  guard cursor.consume('{') else { return None }
  Some((name, metadata, false))
}

///|
fn symbol_package_line(cursor : @parse.Cursor) -> ClassCommandLineSyntax? {
  let start = cursor.offset()
  let visibility = declaration_visibility(cursor)
  guard symbol_package_keyword(cursor) is Some(symbol) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard symbol_package_body(cursor) is Some((name, metadata, empty)) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  if empty {
    return Some(ParsedInvalidSymbolPackage)
  }
  Some(
    ParsedPackage({
      code: name.code,
      display: name.display,
      is_namespace: false,
      visibility,
      stereotype: metadata.stereotype,
      url: metadata.url,
      color: metadata.color,
      empty: false,
      symbol: Some(symbol),
    }),
  )
}

///|
fn package_body(
  cursor : @parse.Cursor,
) -> (DeclarationNameSyntax, DeclarationMetadataSyntax, Bool)? {
  guard take_declaration_name_and_suffixes(cursor) is Some((name, metadata)) else {
    return None
  }
  let empty = take_brace(cursor, true)
  cursor.skip_inline_spaces()
  Some((name, metadata, empty))
}

///|
fn package_line(cursor : @parse.Cursor) -> ClassCommandLineSyntax? {
  let start = cursor.offset()
  let visibility = declaration_visibility(cursor)
  guard package_keyword(cursor) is Some(is_namespace) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard package_body(cursor) is Some((name, metadata, empty)) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(
    ParsedPackage({
      code: name.code,
      display: name.display,
      is_namespace,
      visibility,
      stereotype: metadata.stereotype,
      url: metadata.url,
      color: metadata.color,
      empty,
      symbol: None,
    }),
  )
}

///|
fn stereotype_assignment_line(
  cursor : @parse.Cursor,
) -> ClassCommandLineSyntax? {
  let start = cursor.offset()
  let code = match cursor.take_quoted_value() {
    Some(value) => @parse.unquote_identifier(value)
    None => {
      let value = cursor.take_while(char => !char.is_whitespace() && char != '<')
      guard value.length() > 0 else {
        ignore(cursor.restore(start))
        return None
      }
      @parse.unquote_identifier(value)
    }
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.take_stereotype_value() is Some(stereotype) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(ParsedStereotypeAssignment(code~, stereotype~))
}

///|
fn url_assignment_target(cursor : @parse.Cursor) -> String? {
  match cursor.take_quoted_value() {
    Some(value) => Some(@parse.unquote_identifier(value))
    None => {
      let value = cursor.take_while(char => !char.is_whitespace() && char != '[')
      guard value.length() > 0 else { return None }
      Some(@parse.unquote_identifier(value))
    }
  }
}

///|
fn url_assignment_line(cursor : @parse.Cursor) -> ClassCommandLineSyntax? {
  let start = cursor.offset()
  guard consume_inline_keyword(cursor, "url") && cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  let of_start = cursor.offset()
  if !((
      consume_inline_keyword(cursor, "of") ||
      consume_inline_keyword(cursor, "for")
    ) &&
    cursor.skip_inline_space1()) {
    ignore(cursor.restore(of_start))
  }
  guard url_assignment_target(cursor) is Some(code) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(consume_inline_keyword(cursor, "is"))
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.take_url_value() is Some(url) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(ParsedUrlAssignment(code~, url~))
}

///|
fn class_command_line(cursor : @parse.Cursor) -> ClassCommandLineSyntax? {
  if symbol_package_line(cursor) is Some(value) {
    return Some(value)
  }
  if package_line(cursor) is Some(value) {
    return Some(value)
  }
  if url_assignment_line(cursor) is Some(value) {
    return Some(value)
  }
  stereotype_assignment_line(cursor)
}

///|
fn EntityParser::apply_package_declaration(
  self : EntityParser,
  group : @entity.GroupDeclaration,
) -> Unit {
  let parent = self.current_package()
  let segments = @parse.split_unquoted(group.code, '.')
  let mut prefix = parent
  for segment_index, segment in segments {
    let qualified_name = if prefix.length() == 0 {
      segment
    } else {
      prefix + "." + segment
    }
    let is_last = segment_index == segments.length() - 1
    let display = if is_last { group.display } else { segment }
    let package_value : @entity.Package = {
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
      symbol: if is_last {
        group.symbol
      } else {
        None
      },
    }
    match
      self.packages.search_by(item => item.qualified_name == qualified_name) {
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
fn EntityParser::apply_class_command(
  self : EntityParser,
  syntax : ClassCommandLineSyntax,
) -> Unit raise @parse.ParseError {
  match syntax {
    ParsedPackage(group) => self.apply_package_declaration(group)
    ParsedInvalidSymbolPackage =>
      self.raise_parse_error("Syntax Error? (Assumed diagram type: component)")
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
