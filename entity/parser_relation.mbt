///|
fn Parser::resolve_relation_name(
  self : Parser,
  syntax : RelationNameSyntax,
) -> (String, String?) {
  let full = normalize_name(syntax.name)
  guard syntax.port_base is Some(base) && syntax.port_value is Some(port) else {
    return (full, None)
  }
  let base = normalize_name(base)
  let base_code = self.resolve(base)
  if self.has_entity(full) {
    (full, None)
  } else if self.has_entity(base_code) {
    (base, Some(port))
  } else {
    (full, None)
  }
}

///|
fn relation_shape(raw : String) -> (String, EntityKind)? {
  let value = raw.trim()
  if value.has_prefix("()") {
    Some((value[2:].trim().to_owned(), Interface))
  } else {
    match decode_shaped_entity(Class, raw, raw) {
      (Class, _, _) => None
      (kind, _, code) => Some((code, kind))
    }
  }
}

///|
fn Parser::ensure_relation_entity(
  self : Parser,
  raw : String,
  endpoint : RelationEnd,
) -> String {
  match relation_shape(raw) {
    Some((code, kind)) => self.ensure_entity_as(normalize_name(code), kind)
    None if endpoint is Parenthesis => self.ensure_entity_as(raw, Interface)
    None => self.ensure_entity(raw)
  }
}

///|
fn Parser::apply_relation_syntax(
  self : Parser,
  syntax : RelationLineSyntax,
) -> Unit {
  let arrow = syntax.arrow
  let left_end = left_relation_end(arrow)
  let right_end = right_relation_end(arrow)
  let (left_name, left_port) = self.resolve_relation_name(syntax.left.name)
  let (right_name, right_port) = self.resolve_relation_name(syntax.right.name)
  let left = if syntax.left.couple is Some((couple_left, _)) {
    self.ensure_entity(couple_left)
  } else {
    self.ensure_relation_entity(left_name, left_end)
  }
  let right = if syntax.right.couple is Some((_, couple_right)) {
    self.ensure_entity(couple_right)
  } else {
    self.ensure_relation_entity(right_name, right_end)
  }
  self.relations.push({
    left,
    right,
    kind: relation_kind(left_end, right_end, arrow),
    left_cardinality: syntax.left.cardinality,
    right_cardinality: syntax.right.cardinality,
    left_role: syntax.left.role,
    right_role: syntax.right.role,
    left_qualifier: syntax.left.qualifier,
    right_qualifier: syntax.right.qualifier,
    label: syntax.label,
    dotted: arrow.contains(".."),
    raw_arrow: arrow,
    left_end,
    right_end,
    direction: relation_direction(arrow),
    line_style: relation_style(arrow),
    color: syntax.color,
    url: syntax.url,
    stereotype: syntax.stereotype,
    weight: syntax.weight,
    inside: relation_inside(arrow),
    left_port,
    right_port,
    left_couple: match syntax.left.couple {
      Some((first, second)) => Some((self.resolve(first), self.resolve(second)))
      None => None
    },
    right_couple: match syntax.right.couple {
      Some((first, second)) => Some((self.resolve(first), self.resolve(second)))
      None => None
    },
  })
}

///|
