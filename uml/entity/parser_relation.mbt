///|
let left_relation_decorations : Array[(String, RelationEnd)] = [
  ("<|:", DefinedBy),
  ("<||", Redefines),
  ("}o", CircleCrowfoot),
  ("|o", CircleLine),
  ("}|", LineCrowfoot),
  ("<|", Extension),
  ("<<", TriangleArrow),
  ("0)", CircleConnect),
  ("()", Parenthesis),
  ("))", Parenthesis),
  ("||", DoubleLine),
  ("*", CompositionEnd),
  ("o", AggregationEnd),
  ("x", NotNavigable),
  ("}", Crowfoot),
  ("<_", Arrow),
  ("<", Arrow),
  ("^", Extension),
  ("0", CircleEnd),
  ("@", FilledCircle),
  (")", Parenthesis),
  ("#", Square),
  ("+", Plus),
]

///|
let right_relation_decorations : Array[(String, RelationEnd)] = [
  (":|>", DefinedBy),
  ("||>", Redefines),
  ("o{", CircleCrowfoot),
  ("o|", CircleLine),
  ("|{", LineCrowfoot),
  ("|>", Extension),
  (">>", TriangleArrow),
  ("(0", CircleConnect),
  ("()", Parenthesis),
  ("((", Parenthesis),
  ("||", DoubleLine),
  ("*", CompositionEnd),
  ("o", AggregationEnd),
  ("x", NotNavigable),
  ("{", Crowfoot),
  ("_>", Arrow),
  (">", Arrow),
  ("^", Extension),
  ("0", CircleEnd),
  ("@", FilledCircle),
  ("(", Parenthesis),
  ("#", Square),
  ("+", Plus),
  ("\\\\", HalfArrowUp),
  ("//", HalfArrowDown),
]

///|
fn left_relation_end(arrow : String) -> RelationEnd {
  for entry in left_relation_decorations {
    guard arrow.has_prefix(entry.0) else { continue }
    return entry.1
  }
  Plain
}

///|
fn right_relation_end(arrow : String) -> RelationEnd {
  for entry in right_relation_decorations {
    guard arrow.has_suffix(entry.0) else { continue }
    return entry.1
  }
  Plain
}

///|
fn relation_kind(
  left : RelationEnd,
  right : RelationEnd,
  arrow : String,
) -> RelationKind {
  if left is Extension ||
    right is Extension ||
    left is Redefines ||
    right is Redefines ||
    left is DefinedBy ||
    right is DefinedBy {
    if arrow.contains(".") {
      Realization
    } else {
      Extension
    }
  } else if left is CompositionEnd || right is CompositionEnd {
    Composition
  } else if left is AggregationEnd || right is AggregationEnd {
    Aggregation
  } else if arrow.contains(".") {
    Dependency
  } else {
    Association
  }
}

///|
fn relation_direction(arrow : String) -> RelationDirection {
  if arrow.contains("left") || arrow.contains("-le") || arrow.contains("-l") {
    Leftward
  } else if arrow.contains("right") ||
    arrow.contains("-ri") ||
    arrow.contains("-r") {
    Rightward
  } else if arrow.contains("up") || arrow.contains("-u") {
    Upward
  } else if arrow.contains("down") ||
    arrow.contains("-do") ||
    arrow.contains("-d") {
    Downward
  } else {
    Automatic
  }
}

///|
fn relation_style(arrow : String) -> String? {
  guard @parse.find_literal(arrow, "[") is Some(start) else { return None }
  guard @parse.find_literal(arrow[start + 1:].to_owned(), "]") is Some(length) else {
    return None
  }
  Some(arrow[start + 1:start + 1 + length].to_owned())
}

///|
fn relation_inside(arrow : String) -> String? {
  for inside in ["(0)", "(0", "0)"] {
    if arrow.contains(inside) {
      return Some(inside)
    }
  }
  None
}

///|
fn Parser::resolve_relation_name(
  self : Parser,
  syntax : RelationNameSyntax,
) -> (String, String?) {
  let full = @parse.unquote_identifier(syntax.name)
  guard syntax.port_base is Some(base) && syntax.port_value is Some(port) else {
    return (full, None)
  }
  let base = @parse.unquote_identifier(base)
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
    Some((code, kind)) =>
      self.ensure_entity_as(@parse.unquote_identifier(code), kind)
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
    ..Relation::new(
      left,
      right,
      relation_kind(left_end, right_end, arrow),
      arrow,
      left_end,
      right_end,
    ),
    left_cardinality: syntax.left.cardinality,
    right_cardinality: syntax.right.cardinality,
    left_role: syntax.left.role,
    right_role: syntax.right.role,
    left_qualifier: syntax.left.qualifier,
    right_qualifier: syntax.right.qualifier,
    label: syntax.label,
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
