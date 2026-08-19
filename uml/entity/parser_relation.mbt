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
/// Lollipop arrows are the two-character paren forms `()`/`))` before the
/// dashes or `()`/`((` after them; single-paren ends stay ordinary relation
/// decorations. The returned value is `Some(half)` for a lollipop arrow.
fn lollipop_arrow(arrow : String, at_start : Bool) -> Bool? {
  if at_start {
    if arrow.has_prefix("()") {
      return Some(false)
    }
    if arrow.has_prefix("))") {
      return Some(true)
    }
  } else {
    if arrow.has_suffix("()") {
      return Some(false)
    }
    if arrow.has_suffix("((") {
      return Some(true)
    }
  }
  None
}

///|
/// The qualified name of a package referenced by a relation endpoint, so the
/// relation attaches to the group instead of creating a phantom entity
/// (PlantUML `CommandLinkElement.getDummy` returns the group for group names).
fn Parser::package_code(self : Parser, raw : String) -> String? {
  let clean = @parse.unquote_identifier(raw)
  for group in self.packages {
    if group.qualified_name == clean || group.name == clean {
      return Some(group.qualified_name)
    }
  }
  None
}

///|
fn Parser::ensure_relation_entity(
  self : Parser,
  raw : String,
  endpoint : RelationEnd,
) -> String {
  match self.package_code(raw) {
    Some(qualified_name) => qualified_name
    None =>
      match relation_shape(raw) {
        Some((code, kind)) =>
          self.ensure_entity_as(@parse.unquote_identifier(code), kind)
        None if endpoint is Parenthesis => self.ensure_entity_as(raw, Interface)
        None => self.ensure_entity(raw)
      }
  }
}

///|
/// `CommandLinkLollipop` creates the interface circle as a new leaf whose
/// display is the name written next to the `()`; the other endpoint must
/// already exist.
fn Parser::ensure_lollipop(
  self : Parser,
  base : String,
  display : String,
  half : Bool,
) -> String raise @parse.ParseError {
  let base = self.resolve(base)
  guard self.has_entity(base) else {
    self.raise_parse_error("No class " + base)
  }
  let code = base + "lol" + self.synthetic_sequence.to_string()
  self.synthetic_sequence += 1
  self.append_synthetic_entity(
    code,
    display,
    if half {
      LollipopHalf
    } else {
      LollipopFull
    },
  )
}

///|
/// The invisible association point between the two couple members.
fn Parser::ensure_couple_point(self : Parser) -> String {
  let code = "apoint" + self.synthetic_sequence.to_string()
  self.synthetic_sequence += 1
  self.append_synthetic_entity(code, "", Point)
}

///|
fn Parser::apply_relation_syntax(
  self : Parser,
  syntax : RelationLineSyntax,
) -> Unit raise @parse.ParseError {
  let arrow = syntax.arrow
  let left_end = left_relation_end(arrow)
  let right_end = right_relation_end(arrow)
  let (left_name, left_port) = self.resolve_relation_name(syntax.left.name)
  let (right_name, right_port) = self.resolve_relation_name(syntax.right.name)
  let left_lollipop = lollipop_arrow(arrow, true)
  let right_lollipop = lollipop_arrow(arrow, false)
  let mut left = ""
  match syntax.left.couple {
    Some((couple_left, couple_right)) => {
      let first = self.resolve(couple_left)
      let second = self.resolve(couple_right)
      let point = self.ensure_couple_point()
      self.relations.push(
        Relation::new(first, point, Association, "--", Plain, Plain),
      )
      self.relations.push(
        Relation::new(point, second, Association, "--", Plain, Plain),
      )
      left = point
    }
    None =>
      left = match left_lollipop {
        Some(half) => self.ensure_lollipop(right_name, left_name, half)
        None => self.ensure_relation_entity(left_name, left_end)
      }
  }
  let mut right = ""
  match syntax.right.couple {
    Some((couple_left, couple_right)) => {
      let first = self.resolve(couple_left)
      let second = self.resolve(couple_right)
      let point = self.ensure_couple_point()
      self.relations.push(
        Relation::new(first, point, Association, "--", Plain, Plain),
      )
      self.relations.push(
        Relation::new(point, second, Association, "--", Plain, Plain),
      )
      right = point
    }
    None =>
      right = match right_lollipop {
        Some(half) => self.ensure_lollipop(left_name, right_name, half)
        None => self.ensure_relation_entity(right_name, right_end)
      }
  }
  let (effective_arrow, effective_left_end, effective_right_end) = if left_lollipop
    is Some(_) {
    (arrow[2:].to_owned(), Plain, Plain)
  } else if right_lollipop is Some(_) {
    (arrow[0:arrow.length() - 2].to_owned(), Plain, Plain)
  } else {
    (arrow, left_end, right_end)
  }
  self.relations.push({
    ..Relation::new(
      left,
      right,
      relation_kind(effective_left_end, effective_right_end, effective_arrow),
      effective_arrow,
      effective_left_end,
      effective_right_end,
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
