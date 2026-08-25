///|
priv struct RelationNameSyntax {
  name : String
  port_base : String?
  port_value : String?
}

///|
priv struct RelationEndpointSyntax {
  name : RelationNameSyntax
  cardinality : String?
  role : String?
  qualifier : String?
  couple : (String, String)?
}

///|
priv struct RelationLineSyntax {
  weight : String?
  left : RelationEndpointSyntax
  arrow : String
  right : RelationEndpointSyntax
  label : String?
  color : String?
  url : String?
  stereotype : String?
}

///|
priv enum RelationEndpointModifier {
  RelationCardinality(String)
  RelationRole(String)
  RelationQualifier(String)
}

///|
priv enum RelationMetadataSyntax {
  RelationColor(String)
  RelationUrl(String)
  RelationStereotype(String)
}

///|
fn starts_relation_separator(cursor : @parse.Cursor) -> Bool {
  let offset = cursor.offset()
  let matched = relation_separator(cursor) is Some(_)
  ignore(cursor.restore(offset))
  matched
}

///|
fn relation_name(
  cursor : @parse.Cursor,
  stop_at_arrow : Bool,
) -> RelationNameSyntax? {
  let start = cursor.offset()
  if cursor.consume_literal("()") {
    cursor.skip_inline_spaces()
    let name = cursor.take_while(char => {
      !char.is_whitespace() &&
      char != ':' &&
      char != '[' &&
      char != ']' &&
      char != '(' &&
      char != ')'
    })
    guard name.length() > 0 else {
      ignore(cursor.restore(start))
      return None
    }
    return Some({ name: "()" + name, port_base: None, port_value: None, })
  }
  ignore(cursor.restore(start))
  if declaration_shaped_name(cursor) is Some(name) {
    return Some({ name, port_base: None, port_value: None, })
  }
  if cursor.take_quoted_value() is Some(name) {
    return Some({ name, port_base: None, port_value: None, })
  }
  let name_character = (char : Char) => {
    !char.is_whitespace() &&
    char != ':' &&
    char != '[' &&
    char != ']' &&
    char != ',' &&
    char != '(' &&
    char != ')' &&
    (!stop_at_arrow || !starts_relation_separator(cursor))
  }
  let first_segment = cursor.take_while(name_character)
  guard first_segment.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  let segments = [first_segment]
  while true {
    let sep_start = cursor.offset()
    guard cursor.consume_literal("::") else { break }
    let segment = cursor.take_while(name_character)
    guard segment.length() > 0 else {
      ignore(cursor.restore(sep_start))
      break
    }
    segments.push(segment)
  }
  let name = segments.join("::")
  if segments.length() > 1 {
    Some({
      name,
      port_base: Some(segments[0]),
      port_value: Some(segments[1:].to_owned().join("::")),
    })
  } else {
    Some({ name, port_base: None, port_value: None, })
  }
}

///|
fn relation_couple(
  cursor : @parse.Cursor,
) -> (RelationNameSyntax, (String, String))? {
  let start = cursor.offset()
  guard cursor.consume('(') else { return None }
  cursor.skip_inline_spaces()
  guard relation_name(cursor, false) is Some(first) else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard cursor.consume(',') else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard relation_name(cursor, false) is Some(second) else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  guard cursor.consume(')') else {
    ignore(cursor.restore(start))
    return None
  }
  let left = @parse.unquote_identifier(first.name)
  let right = @parse.unquote_identifier(second.name)
  Some(({ name: left, port_base: None, port_value: None, }, (left, right)))
}

///|
fn relation_target(
  cursor : @parse.Cursor,
  stop_at_arrow : Bool,
) -> (RelationNameSyntax, (String, String)?)? {
  let start = cursor.offset()
  if relation_couple(cursor) is Some((name, couple)) {
    return Some((name, Some(couple)))
  }
  ignore(cursor.restore(start))
  relation_name(cursor, stop_at_arrow).map(name => (name, None))
}

///|
fn relation_role_value(cursor : @parse.Cursor) -> String? {
  match cursor.take_quoted_value() {
    Some(value) => Some(@parse.unquote_identifier(value))
    None => {
      let value = cursor.take_while(char => !char.is_whitespace())
      guard value.length() > 0 else { return None }
      Some(@parse.unquote_identifier(value))
    }
  }
}

///|
fn relation_modifier(cursor : @parse.Cursor) -> RelationEndpointModifier? {
  let start = cursor.offset()
  if cursor.take_quoted_value() is Some(value) {
    return Some(RelationCardinality(value))
  }
  if cursor.consume('/') {
    guard relation_role_value(cursor) is Some(value) else {
      ignore(cursor.restore(start))
      return None
    }
    return Some(RelationRole(value))
  }
  if cursor.consume('[') {
    let value = cursor.take_while(char => char != ']')
    guard value.length() > 0 else {
      ignore(cursor.restore(start))
      return None
    }
    guard cursor.consume(']') else {
      ignore(cursor.restore(start))
      return None
    }
    return Some(RelationQualifier(value.trim().to_owned()))
  }
  None
}

///|
fn relation_endpoint_from(
  name : RelationNameSyntax,
  couple : (String, String)?,
  modifiers : Array[RelationEndpointModifier],
) -> RelationEndpointSyntax {
  let mut cardinality = None
  let mut role = None
  let mut qualifier = None
  for modifier in modifiers {
    match modifier {
      RelationCardinality(value) => cardinality = Some(value)
      RelationRole(value) => role = Some(value)
      RelationQualifier(value) => qualifier = Some(value)
    }
  }
  { name, cardinality, role, qualifier, couple, }
}

///|
fn take_modifiers(cursor : @parse.Cursor) -> Array[RelationEndpointModifier] {
  collect_repeated(cursor, relation_modifier)
}

///|
fn left_relation_endpoint(cursor : @parse.Cursor) -> RelationEndpointSyntax? {
  guard relation_target(cursor, true) is Some((name, couple)) else {
    return None
  }
  let modifiers = take_modifiers(cursor)
  Some(relation_endpoint_from(name, couple, modifiers))
}

///|
fn right_relation_endpoint(cursor : @parse.Cursor) -> RelationEndpointSyntax? {
  let start = cursor.offset()
  // The arrow separator consumes the leading spaces, so modifiers sit at the
  // current position and only a trailing space is required. A bracket may be
  // either a qualifier or a component name: backtrack the whole modifier
  // prefix when it is not followed by an endpoint, and parse the endpoint
  // alone.
  let modifiers = []
  while true {
    let modifier_start = cursor.offset()
    guard relation_modifier(cursor) is Some(modifier) &&
      cursor.skip_inline_space1() else {
      ignore(cursor.restore(modifier_start))
      break
    }
    modifiers.push(modifier)
  }
  if relation_target(cursor, false) is Some((name, couple)) {
    return Some(relation_endpoint_from(name, couple, modifiers))
  }
  ignore(cursor.restore(start))
  relation_target(cursor, false).map(pair => {
    let (name, couple) = pair
    relation_endpoint_from(name, couple, [])
  })
}

///|
fn relation_separator(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  if relation_non_single_arrow(cursor) is Some(arrow) {
    cursor.skip_inline_spaces()
    return Some(arrow)
  }
  ignore(cursor.restore(start))
  if cursor.skip_inline_space1() &&
    cursor.peek() is Some(char) &&
    "-=.".contains_char(char) {
    ignore(cursor.advance())
    if cursor.skip_inline_space1() {
      return Some(char.to_string())
    }
  }
  ignore(cursor.restore(start))
  None
}

///|
fn relation_color(cursor : @parse.Cursor) -> RelationMetadataSyntax? {
  cursor.take_color_value().map(value => RelationColor(value))
}

///|
fn relation_url(cursor : @parse.Cursor) -> RelationMetadataSyntax? {
  cursor.take_url_value().map(value => RelationUrl(value))
}

///|
fn relation_stereotype(cursor : @parse.Cursor) -> RelationMetadataSyntax? {
  cursor.take_stereotype_value().map(value => RelationStereotype(value))
}

///|
fn relation_metadata(cursor : @parse.Cursor) -> RelationMetadataSyntax? {
  if relation_color(cursor) is Some(value) {
    return Some(value)
  }
  if relation_url(cursor) is Some(value) {
    return Some(value)
  }
  relation_stereotype(cursor)
}

///|
fn right_relation_syntax(
  cursor : @parse.Cursor,
) -> (RelationEndpointSyntax, Array[RelationMetadataSyntax], String?)? {
  let start = cursor.offset()
  guard right_relation_endpoint(cursor) is Some(endpoint) else { return None }
  let metadata = collect_repeated(cursor, relation_metadata)
  // Optional label: spaces, a `:` not followed by `:`, spaces, then text.
  let label_start = cursor.offset()
  cursor.skip_inline_spaces()
  let label : String? = if cursor.peek() == Some(':') {
    ignore(cursor.advance())
    if cursor.peek() == Some(':') {
      ignore(cursor.restore(start))
      return None
    }
    cursor.skip_inline_spaces()
    Some(cursor.take_while(_ => true).trim().to_owned())
  } else {
    ignore(cursor.restore(label_start))
    None
  }
  Some((endpoint, metadata, label))
}

///|
fn relation_metadata_from(
  metadata : Array[RelationMetadataSyntax],
) -> (String?, String?, String?) {
  let mut color = None
  let mut url = None
  let mut stereotype = None
  for item in metadata {
    match item {
      RelationColor(value) => color = Some(value)
      RelationUrl(value) => url = Some(value)
      RelationStereotype(value) => stereotype = Some(value)
    }
  }
  (color, url, stereotype)
}

///|
fn left_relation_syntax(
  cursor : @parse.Cursor,
) -> (String?, RelationEndpointSyntax)? {
  let weight_start = cursor.offset()
  let weight = if cursor.consume('@') {
    let token = cursor.take_while(char => !char.is_whitespace())
    if token.length() > 0 && cursor.skip_inline_space1() {
      Some(token)
    } else {
      ignore(cursor.restore(weight_start))
      None
    }
  } else {
    None
  }
  left_relation_endpoint(cursor).map(endpoint => (weight, endpoint))
}

///|
fn relation_line(cursor : @parse.Cursor) -> RelationLineSyntax? {
  let start = cursor.offset()
  guard left_relation_syntax(cursor) is Some((weight, left)) else {
    ignore(cursor.restore(start))
    return None
  }
  guard relation_separator(cursor) is Some(arrow) else {
    ignore(cursor.restore(start))
    return None
  }
  guard right_relation_syntax(cursor) is Some((right, metadata, label)) else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  let (color, url, stereotype) = relation_metadata_from(metadata)
  Some({ weight, left, arrow, right, label, color, url, stereotype, })
}

///|
test "relation line grammar accepts supported syntax" {
  let lines = [
    "U <|.. Auth : implements", "Order \"1\" *-- \"many\" Item : items", "\"Order Item\" --> \"Line Item\"",
    "A \"1\" -- \"many\" B", "\"Quoted A\" \"0..1\" -- \"*\" \"Quoted B\"", "order-item --> target [[https://host:8443/item]] <<phase:value>> : \"sync: now\"",
    "A --[dashed,#red]--> B #blue [[https://example.com]] <<critical>> : calls",
    "(A, B) -- Label : association", "A-->B", "order-item-->target-item",
  ]
  for line in lines {
    let cursor = @parse.Cursor::new(line)
    guard relation_line(cursor) is Some(_) else {
      @test.fail("relation grammar rejected: " + line)
    }
  }
}

///|
test "relation line grammar parses each typed phase" {
  let line = "U <|.. Auth : implements"
  let cursor = @parse.Cursor::new(line)
  guard relation_line(cursor) is Some(relation) else {
    @test.fail("complete relation grammar failed")
  }
  @test.assert_eq(relation.left.name.name, "U")
  @test.assert_eq(relation.right.name.name, "Auth")
  @test.assert_eq(relation.arrow, "<|..")
  @test.assert_eq(relation.label, Some("implements"))
}
