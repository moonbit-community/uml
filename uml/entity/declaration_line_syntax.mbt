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
fn declaration_visibility(cursor : @parse.Cursor) -> Visibility {
  match cursor.peek() {
    Some(char) if "+-#~".contains_char(char) => {
      ignore(cursor.advance())
      cursor.skip_inline_spaces()
      match char {
        '+' => Public
        '-' => Private
        '#' => Protected
        _ => Package
      }
    }
    _ => Unknown
  }
}

///|
fn take_shaped_parentheses(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('(') else { return None }
  let name = cursor.take_while(char => char != ')')
  guard name.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume(')') else {
    ignore(cursor.restore(start))
    return None
  }
  let suffix = if cursor.consume('/') { "/" } else { "" }
  Some("(" + name + ")" + suffix)
}

///|
fn take_shaped_actor(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume(':') else { return None }
  let name = cursor.take_while(char => char != ':')
  guard name.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume(':') else {
    ignore(cursor.restore(start))
    return None
  }
  let suffix = if cursor.consume('/') { "/" } else { "" }
  Some(":" + name + ":" + suffix)
}

///|
fn take_shaped_component(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('[') else { return None }
  let name = cursor.take_while(char => char != ']')
  guard name.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume(']') else {
    ignore(cursor.restore(start))
    return None
  }
  Some("[" + name + "]")
}

///|
fn declaration_shaped_name(cursor : @parse.Cursor) -> String? {
  match take_shaped_parentheses(cursor) {
    Some(value) => Some(value)
    None =>
      match take_shaped_actor(cursor) {
        Some(value) => Some(value)
        None => take_shaped_component(cursor)
      }
  }
}

///|
fn take_nested_generic(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('<') else { return None }
  let content = generic_content(cursor)
  guard cursor.consume('>') else {
    ignore(cursor.restore(start))
    return None
  }
  Some(content)
}

///|
fn generic_content(cursor : @parse.Cursor) -> String {
  let parts = StringBuilder()
  while true {
    let start = cursor.offset()
    match take_nested_generic(cursor) {
      Some(content) => parts.write_string("<" + content + ">")
      None => {
        ignore(cursor.restore(start))
        let plain = cursor.take_while(char => char != '<' && char != '>')
        if plain.length() == 0 {
          break
        }
        parts.write_string(plain)
      }
    }
  }
  parts.to_string()
}

///|
fn declaration_generic(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('<') else { return None }
  guard cursor.peek() != Some('<') else {
    ignore(cursor.restore(start))
    return None
  }
  let content = generic_content(cursor)
  guard cursor.consume('>') else {
    ignore(cursor.restore(start))
    return None
  }
  Some(content)
}

///|
fn declaration_name_atom(cursor : @parse.Cursor) -> DeclarationNameAtom? {
  let start = cursor.offset()
  let (value, quoted) = match cursor.take_quoted_value() {
    Some(value) => (value, true)
    None =>
      match declaration_shaped_name(cursor) {
        Some(value) => (value, false)
        None => {
          let value = cursor.take_while(char => {
            !char.is_whitespace() &&
            char != '<' &&
            char != '{' &&
            char != ',' &&
            char != '$' &&
            char != '#'
          })
          guard value.length() > 0 else {
            ignore(cursor.restore(start))
            return None
          }
          (value, false)
        }
      }
  }
  let generic = declaration_generic(cursor)
  Some({ value: @parse.unquote_identifier(value), generic, quoted })
}

///|
fn declaration_name_syntax(cursor : @parse.Cursor) -> DeclarationNameSyntax? {
  guard declaration_name_atom(cursor) is Some(first) else { return None }
  let as_start = cursor.offset()
  let alternate = if cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "as") &&
    cursor.skip_inline_space1() {
    declaration_name_atom(cursor)
  } else {
    None
  }
  if alternate is None {
    ignore(cursor.restore(as_start))
  }
  match alternate {
    Some(second) => {
      let generic = match first.generic {
        Some(value) => Some(value)
        None => second.generic
      }
      if second.quoted {
        Some({ display: second.value, code: first.value, generic })
      } else {
        Some({ display: first.value, code: second.value, generic })
      }
    }
    None =>
      Some({ display: first.value, code: first.value, generic: first.generic })
  }
}

///|
fn declaration_target(cursor : @parse.Cursor) -> String? {
  match cursor.take_quoted_value() {
    Some(value) => Some(@parse.unquote_identifier(value))
    None => {
      let value = cursor.take_while(char => !char.is_whitespace() && char != ',')
      guard value.length() > 0 else { return None }
      Some(@parse.unquote_identifier(value))
    }
  }
}

///|
fn declaration_target_list(cursor : @parse.Cursor) -> Array[String]? {
  guard declaration_target(cursor) is Some(first) else { return None }
  let values = [first]
  while true {
    let sep_start = cursor.offset()
    cursor.skip_inline_spaces()
    guard cursor.consume(',') else {
      ignore(cursor.restore(sep_start))
      break
    }
    cursor.skip_inline_spaces()
    guard declaration_target(cursor) is Some(value) else {
      ignore(cursor.restore(sep_start))
      break
    }
    values.push(value)
  }
  Some(values)
}

///|
fn declaration_stereotype(cursor : @parse.Cursor) -> DeclarationSuffixSyntax? {
  let start = cursor.offset()
  guard cursor.consume_literal("<<") else { return None }
  let parts = StringBuilder()
  while !cursor.is_eof() && !cursor.starts_with_literal(">>") {
    match cursor.advance() {
      Some(char) => parts.write_char(char)
      None => break
    }
  }
  guard cursor.consume_literal(">>") else {
    ignore(cursor.restore(start))
    return None
  }
  Some(DeclarationStereotype("<<" + parts.to_string() + ">>"))
}

///|
fn declaration_url(cursor : @parse.Cursor) -> DeclarationSuffixSyntax? {
  cursor.take_url_value().map(url => DeclarationUrl(url))
}

///|
fn declaration_line_style(cursor : @parse.Cursor) -> DeclarationSuffixSyntax? {
  let start = cursor.offset()
  guard cursor.consume_literal("##") else { return None }
  let style = if cursor.consume('[') {
    let value = cursor.take_while(char => char != ']')
    guard cursor.consume(']') else {
      ignore(cursor.restore(start))
      return None
    }
    Some(value)
  } else {
    None
  }
  guard cursor.take_color_token() is Some(token) else {
    ignore(cursor.restore(start))
    return None
  }
  let color : String? = Some(token)
  Some(DeclarationLine(style~, color~))
}

///|
fn take_suffix_target_list(
  cursor : @parse.Cursor,
  keyword : String,
) -> Array[String]? {
  let start = cursor.offset()
  guard consume_inline_keyword(cursor, keyword) && cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  match declaration_target_list(cursor) {
    Some(values) => Some(values)
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn declaration_suffix(cursor : @parse.Cursor) -> DeclarationSuffixSyntax? {
  if take_suffix_target_list(cursor, "extends") is Some(values) {
    return Some(DeclarationExtends(values))
  }
  if take_suffix_target_list(cursor, "implements") is Some(values) {
    return Some(DeclarationImplements(values))
  }
  if declaration_stereotype(cursor) is Some(value) {
    return Some(value)
  }
  if declaration_url(cursor) is Some(value) {
    return Some(value)
  }
  if declaration_line_style(cursor) is Some(value) {
    return Some(value)
  }
  if cursor.take_tag_value() is Some(value) {
    return Some(DeclarationTag(value))
  }
  cursor.take_color_value().map_or(None, color => Some(DeclarationColor(color)))
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
fn take_declaration_suffixes(
  cursor : @parse.Cursor,
) -> Array[DeclarationSuffixSyntax] {
  collect_repeated(cursor, declaration_suffix)
}

///|
fn take_declaration_name_and_suffixes(
  cursor : @parse.Cursor,
) -> (DeclarationNameSyntax, DeclarationMetadataSyntax)? {
  guard declaration_name_syntax(cursor) is Some(name) else { return None }
  let suffixes = take_declaration_suffixes(cursor)
  Some((name, declaration_metadata_from(suffixes)))
}

///|
/// The shared `NAME [suffixes...]` prefix of declarations, package groups, and
/// multiline element headers, including the mandatory space before the name.
fn declaration_name_metadata(
  cursor : @parse.Cursor,
) -> (DeclarationNameSyntax, DeclarationMetadataSyntax)? {
  guard cursor.skip_inline_space1() else { return None }
  take_declaration_name_and_suffixes(cursor)
}

///|
/// Consumes the optional `{}` or `{` body marker. `empty_opens` selects
/// whether `{}` counts as an empty body; both `{}` and no marker leave the
/// cursor after inline whitespace.
fn take_brace(cursor : @parse.Cursor, empty_opens : Bool) -> Bool {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  if cursor.consume_literal("{}") {
    empty_opens
  } else if cursor.consume('{') {
    !empty_opens
  } else {
    ignore(cursor.restore(start))
    false
  }
}

///|
fn declaration_body(
  cursor : @parse.Cursor,
) -> (DeclarationNameSyntax, DeclarationMetadataSyntax, Bool)? {
  guard take_declaration_name_and_suffixes(cursor) is Some((name, metadata)) else {
    return None
  }
  let opens_body = take_brace(cursor, false)
  cursor.skip_inline_spaces()
  Some((name, metadata, opens_body))
}

///|
fn declaration_kind_syntax(cursor : @parse.Cursor) -> (EntityKind, Bool, Bool)? {
  let start = cursor.offset()
  if consume_inline_keyword(cursor, "static") &&
    cursor.skip_inline_space1() &&
    consume_inline_keyword(cursor, "class") {
    return Some((Class, true, false))
  }
  ignore(cursor.restore(start))
  if consume_inline_keyword(cursor, "abstract") {
    let after_abstract = cursor.offset()
    if cursor.skip_inline_space1() && consume_inline_keyword(cursor, "class") {
      return Some((AbstractClass, false, false))
    }
    ignore(cursor.restore(after_abstract))
    return Some((AbstractClass, false, false))
  }
  ignore(cursor.restore(start))
  guard take_inline_word(cursor) is Some(word) else { return None }
  let mix_prefixed = word.to_lower().has_prefix("mix_")
  let word = if mix_prefixed { word[4:].to_owned() } else { word }
  match declaration_kind(word) {
    Some(kind) => Some((kind, false, mix_prefixed))
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn declaration_from_syntax(
  kind : EntityKind,
  visibility : Visibility,
  is_static : Bool,
  name : DeclarationNameSyntax,
  metadata : DeclarationMetadataSyntax,
) -> Declaration {
  let (kind, display, code) = decode_shaped_entity(
    kind,
    name.display,
    name.code,
  )
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
fn regular_declaration(
  cursor : @parse.Cursor,
  visibility : Visibility,
) -> DeclarationLineSyntax? {
  let start = cursor.offset()
  guard declaration_kind_syntax(cursor) is Some((kind, is_static, mix_prefixed)) else {
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard declaration_body(cursor) is Some((name, metadata, opens_body)) else {
    ignore(cursor.restore(start))
    return None
  }
  Some({
    declaration: declaration_from_syntax(
      kind, visibility, is_static, name, metadata,
    ),
    opens_body,
    mix_prefixed,
    symbol: false,
  })
}

///|
fn symbol_declaration(
  cursor : @parse.Cursor,
  visibility : Visibility,
) -> DeclarationLineSyntax? {
  let start = cursor.offset()
  if cursor.consume_literal("<>") {
    cursor.skip_inline_spaces()
    guard declaration_name_syntax(cursor) is Some(name) else {
      ignore(cursor.restore(start))
      return None
    }
    return Some({
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
  }
  ignore(cursor.restore(start))
  if cursor.consume_literal("()") {
    cursor.skip_inline_spaces()
    let color_start = cursor.offset()
    if cursor.peek() == Some('#') {
      ignore(cursor.advance())
      let token = cursor.take_while(char => !char.is_whitespace())
      if token.length() == 0 || !cursor.skip_inline_space1() {
        ignore(cursor.restore(color_start))
      }
    }
    guard declaration_body(cursor) is Some((name, metadata, opens_body)) else {
      ignore(cursor.restore(start))
      return None
    }
    return Some({
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
    })
  }
  ignore(cursor.restore(start))
  guard declaration_body(cursor) is Some((name, metadata, opens_body)) else {
    return None
  }
  let (kind, _, _) = decode_shaped_entity(Class, name.display, name.code)
  if kind is Usecase ||
    kind is BusinessUsecase ||
    kind is Actor ||
    kind is BusinessActor ||
    kind is Component {
    Some({
      declaration: declaration_from_syntax(
        Class,
        visibility,
        false,
        name,
        metadata,
      ),
      opens_body,
      mix_prefixed: false,
      symbol: true,
    })
  } else {
    ignore(cursor.restore(start))
    None
  }
}

///|
fn declaration_line(cursor : @parse.Cursor) -> DeclarationLineSyntax? {
  let start = cursor.offset()
  let visibility = declaration_visibility(cursor)
  let syntax = match symbol_declaration(cursor, visibility) {
    Some(value) => value
    None => {
      guard regular_declaration(cursor, visibility) is Some(value) else {
        ignore(cursor.restore(start))
        return None
      }
      value
    }
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(syntax)
}

///|
test "declaration line grammar accepts supported declarations" {
  let lines = [
    "abstract class \"User\" as U {", "interface Auth", "+ static class Repository<T> <<storage>> extends BaseRepository",
    "class RedisCache implements Cache", "() Api <<service>> [[https://example.com/api]] #lightblue",
    "class Service $backend $critical #lightblue ##[dashed]red", "usecase (Login user)",
    "actor :User:", "component [API]", "mix_actor External", "map Config {}", "json Payload {",
    "<> association",
  ]
  for line in lines {
    let cursor = @parse.Cursor::new(line)
    guard declaration_line(cursor) is Some(_) else {
      @test.fail("declaration grammar rejected: " + line)
    }
  }
}
